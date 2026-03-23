# Security Design Documentation

## AWS Cross-Account IAM Role Chaining — Architecture Decisions, Scaling, and Threat Model

---

## Table of Contents

1. [Why Role Assumption Over Long-Lived Credentials](#1-why-role-assumption-over-long-lived-credentials)
2. [Design Decisions](#2-design-decisions)
3. [Scaling to 20 or 100 Accounts](#3-scaling-to-20-or-100-accounts)
4. [Risks of Over-Privileged Roles](#4-risks-of-over-privileged-roles)
5. [Detecting Misuse](#5-detecting-misuse)
6. [What Happens if the Security Account is Compromised](#6-what-happens-if-the-security-account-is-compromised)
7. [Monitoring and Alerting Recommendations](#7-monitoring-and-alerting-recommendations)

---

## 1. Why Role Assumption Over Long-Lived Credentials

### The Problem with Long-Lived Credentials

Long-lived IAM access keys (the `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` pair) are one of the most common sources of AWS breaches. They:

- **Never expire automatically** — a leaked key from a developer's laptop stays valid until manually rotated
- **Are frequently over-shared** — keys get copied into `.env` files, CI/CD pipelines, Slack messages, and git history
- **Are hard to audit** — it's difficult to know who is actually using a key at any given time
- **Violate least privilege by nature** — a key's permissions are fixed at creation time and tend to creep upward over time

### Why Role Assumption is Better

This project uses **temporary credentials via STS role assumption** instead. Here's the comparison:

| Property | Long-Lived Keys | Role Assumption (This Project) |
|---|---|---|
| Credential lifetime | Permanent until rotated | 1 hour maximum |
| Blast radius if leaked | Full account compromise | 1-hour window only |
| Audit trail | Key ID only | Session name + principal chain |
| MFA enforcement | Optional, often skipped | Enforced at assumption time |
| Cross-account access | Requires key per account | Single hop via trust policy |
| Rotation | Manual, error-prone | Automatic — new creds every session |

### The Role Chain Advantage

Instead of giving `IncidentResponder1` a key with workload permissions baked in, this project enforces a **two-hop chain**:

```
User authenticates with MFA
    → Gets 1-hour token for Security Account role
        → Uses that token to get 1-hour token for Workload role
            → Performs remediation
```

At every step, AWS issues new temporary credentials scoped to exactly what that step needs. If any credential is leaked, it expires in at most one hour and only works within its scope.

---

## 2. Design Decisions

### Decision 1 — Hub-and-Spoke Identity Model

The Security Account acts as the **single source of truth** for all human identities. No IAM users exist in the Workload Account. This means:

- Onboarding a new engineer = one change in the Security Account
- Offboarding = one change disables access everywhere
- Audit logs are centralized — CloudTrail in the Security Account captures all assumption events

### Decision 2 — ExternalId on Cross-Account Roles

Both workload roles require an `ExternalId` condition:

```hcl
Condition = {
  StringEquals = {
    "sts:ExternalId" = var.audit_external_id
  }
}
```

This defends against the **confused deputy problem** — a scenario where a third-party service that has assumed your role is tricked into performing actions on behalf of an attacker. Without ExternalId, any entity that can assume the Security Account roles could potentially pivot into your workload. With ExternalId, the caller must know a shared secret that is never transmitted over the public internet.

### Decision 3 — MFA Enforced at First Hop Only

MFA is enforced when `IncidentResponder1` assumes `IncidentResponderRole`:

```hcl
Condition = {
  Bool = {
    "aws:MultiFactorAuthPresent" = "true"
  }
}
```

AWS does not forward `aws:MultiFactorAuthPresent` across role-to-role hops. This is an AWS platform limitation — once a role assumes another role, the MFA context is dropped. The design compensates by enforcing MFA at the user-to-role boundary, which is the only point where a human is present. The subsequent role-to-role hop is machine-to-machine and carries an ExternalId for integrity.

### Decision 4 — Tag-Based Resource Scoping for Incident Response

The `IncidentResponseRole` can only perform write actions (stop, start, reboot, isolate) on EC2 instances tagged with `SecurityManaged=true`:

```hcl
Condition = {
  StringEquals = {
    "aws:ResourceTag/SecurityManaged" = "true"
  }
}
```

This prevents a compromised responder from affecting production workloads that haven't been explicitly opted into security management. Operators tag instances at provisioning time, creating a clear blast boundary.

### Decision 5 — Separate Roles per Persona

Rather than one `SecurityRole` with broad permissions, this project creates two purpose-built roles:

- `SecurityAuditRole` — read-only, no time pressure, no MFA
- `IncidentResponseRole` — write actions, MFA required, tag-scoped

This follows the **principle of least privilege** at the role level. An auditor who is compromised cannot perform remediation. A responder who is compromised cannot exfiltrate data via IAM enumeration beyond what the `IAMReadOnly` SID allows.

---

## 3. Scaling to 20 or 100 Accounts

### Current Architecture (2 Accounts)

The current setup works well for two accounts but requires manual Terraform changes to add each new workload account. At 20+ accounts this becomes unmanageable.

### Scaling Path: AWS Organizations + Service Control Policies

The correct scaling approach uses **AWS Organizations** with this structure:

```
Management Account (Root)
├── Security OU
│   └── Security Account (identity hub — unchanged)
├── Production OU
│   ├── Workload Account A
│   ├── Workload Account B
│   └── Workload Account C
└── Development OU
    ├── Dev Account A
    └── Dev Account B
```

#### Step 1 — Parameterize the Workload Module

Convert `workload-iam.tf` into a reusable Terraform module:

```hcl
module "workload_iam" {
  source = "./modules/workload-iam"

  for_each = toset(var.workload_account_ids)

  providers = {
    aws.workload = aws.workload_accounts[each.key]
  }

  security_account_id  = var.security_account_id
  workload_account_id  = each.key
  audit_external_id    = var.audit_external_id
  incident_external_id = var.incident_external_id
}
```

#### Step 2 — Use AWS Organizations for Trust

Replace per-account trust policies with an Organizations-level condition:

```hcl
Principal = {
  AWS = "*"
}
Condition = {
  StringEquals = {
    "aws:PrincipalOrgID" = "o-xxxxxxxxxxxx"
  }
  ArnLike = {
    "aws:PrincipalArn" = "arn:aws:iam::${security_account_id}:role/SecurityAuditorRole"
  }
}
```

This allows roles to be added to new accounts without touching the trust policy each time.

#### Step 3 — Use Service Control Policies for Guardrails

Apply Organization-wide SCPs to prevent any workload account from creating IAM users or disabling CloudTrail:

```json
{
  "Effect": "Deny",
  "Action": [
    "iam:CreateUser",
    "cloudtrail:DeleteTrail",
    "cloudtrail:StopLogging"
  ],
  "Resource": "*"
}
```

#### Step 4 — AWS IAM Identity Center (SSO)

At 50+ accounts, replace IAM users entirely with **AWS IAM Identity Center**. Engineers log in once via SSO and receive temporary credentials for any account they have permission sets for. This eliminates the need for `SecurityAuditor1` and `IncidentResponder1` as IAM users entirely.

### Scale Comparison

| Scale | Recommended Approach |
|---|---|
| 2–5 accounts | This project's approach — Terraform per account |
| 5–20 accounts | Terraform module with `for_each` over account list |
| 20–100 accounts | AWS Organizations + SCPs + parameterized modules |
| 100+ accounts | AWS IAM Identity Center (SSO) + Organizations |

---

## 4. Risks of Over-Privileged Roles

Over-privileged roles are the most common finding in AWS security reviews. Here are the concrete risks in the context of this project:

### Risk 1 — Privilege Escalation

If `IncidentResponseRole` had `iam:CreateRole` or `iam:AttachRolePolicy`, a compromised responder could create a new role with `AdministratorAccess` and assume it — turning a limited incident response session into full account takeover.

**Mitigation in this project:** The `IncidentResponseRole` only has `iam:Get*` and `iam:List*` — read-only IAM access. No write permissions on IAM resources.

### Risk 2 — Data Exfiltration

A `ReadOnlyAccess` policy sounds safe but includes `s3:GetObject`, `secretsmanager:GetSecretValue`, and `ssm:GetParameter`. An over-privileged auditor role could exfiltrate every secret and S3 object in the workload account.

**Mitigation:** For production, replace `ReadOnlyAccess` with a custom policy that explicitly excludes data-plane read actions (GetObject, GetSecretValue) and only includes control-plane describe/list actions.

### Risk 3 — Lateral Movement

If `IncidentResponseRole` could assume other roles within the workload account (`sts:AssumeRole`), it could pivot into any role — including deployment roles with full write access.

**Mitigation in this project:** No `sts:AssumeRole` permission is granted to `IncidentResponseRole`. Role assumption stops at the workload boundary.

### Risk 4 — Denial of Service via Tag Manipulation

Since `IncidentResponseRole` actions are scoped to `SecurityManaged=true` tags, a user with `ec2:CreateTags` could tag every instance and give the responder access to all of them.

**Mitigation:** Add an explicit `Deny` on `ec2:CreateTags` and `ec2:DeleteTags` to the `IncidentResponsePolicy`, or enforce tag immutability via SCPs.

---

## 5. Detecting Misuse

### CloudTrail — The Foundation

Every `AssumeRole`, API call, and policy change generates a CloudTrail event. Enable CloudTrail in every account and aggregate logs to an S3 bucket in a **dedicated logging account** that workload and security accounts cannot write to or delete from.

### Key Events to Alert On

| Event | What it Signals |
|---|---|
| `AssumeRole` with `IncidentResponderRole` outside business hours | Possible credential theft |
| `AssumeRole` from unexpected IP geolocation | Credential theft or VPN misconfiguration |
| `StopInstances` or `ModifyInstanceAttribute` by IncidentResponseRole | Legitimate or malicious isolation — always warrants review |
| `iam:CreateUser` or `iam:AttachUserPolicy` in any account | Policy violation — no users should be created in workload accounts |
| `ConsoleLogin` without MFA for IncidentResponder1 | MFA policy bypass attempt |
| `DeleteTrail` or `StopLogging` anywhere | Active attacker covering tracks |

### AWS Services for Detection

**AWS CloudTrail + CloudWatch Logs + Metric Filters:**

Create a metric filter and alarm for suspicious AssumeRole patterns:

```hcl
resource "aws_cloudwatch_metric_alarm" "after_hours_assume_role" {
  alarm_name = "IncidentResponder-AfterHoursAccess"
  # Trigger if AssumeRole for IncidentResponderRole happens between 10PM-6AM UTC
}
```

**AWS GuardDuty:**

Enable GuardDuty in all accounts. It automatically detects:
- `UnauthorizedAccess:IAMUser/InstanceCredentialExfiltration`
- `PrivilegeEscalation:IAMUser/AdministrativePermissions`
- `Stealth:IAMUser/CloudTrailLoggingDisabled`

**AWS Security Hub:**

Aggregate GuardDuty findings, Config compliance results, and IAM Access Analyzer findings into a single Security Hub dashboard in the Security Account.

**IAM Access Analyzer:**

Enable Access Analyzer in the workload account to detect any roles that have been made externally accessible — catching trust policy misconfigurations before they are exploited.

---

## 6. What Happens if the Security Account is Compromised?

This is the most critical threat to the hub-and-spoke model. If the Security Account is compromised, an attacker gains the ability to assume any role in any workload account.

### Blast Radius

An attacker with access to the Security Account can:
- Assume `SecurityAuditorRole` → read all workload resources
- Assume `IncidentResponderRole` → stop/modify EC2 instances tagged `SecurityManaged=true`
- Potentially enumerate all accounts in the Organization

### Mitigations

**1. Treat the Security Account as Crown Jewels**

- No workloads run in the Security Account — it is identity-only
- Enforce SCPs that prevent the Security Account from being used for anything except IAM and STS
- Require hardware MFA (YubiKey) for all Security Account console access

**2. Break-Glass Procedure**

Maintain a documented break-glass procedure:

```
IF Security Account is suspected compromised:
1. Immediately revoke all IAM user access keys in Security Account
2. Rotate all ExternalId values (triggers role recreation in Terraform)
3. Update all workload trust policies to remove Security Account principal
4. Activate break-glass IAM roles in each workload account
   (pre-created roles with direct workload account user principals)
5. Investigate Security Account CloudTrail logs from the logging account
   (attacker cannot delete these — logging account is isolated)
```

**3. Rotating ExternalId Values**

Because ExternalId values are stored as Terraform variables, rotating them is a one-command operation:

```bash
# Update terraform.tfvars with new ExternalId values
terraform apply  # Updates all workload trust policies atomically
```

Any in-flight sessions using old credentials immediately lose the ability to assume workload roles because the ExternalId no longer matches.

**4. Separate Logging Account**

CloudTrail logs from both accounts are written to an S3 bucket in a third, isolated **Logging Account**. The Security Account and Workload Account have `s3:PutObject` access to this bucket but not `s3:DeleteObject`. An attacker who compromises either account cannot destroy the audit trail.

**5. Detect Security Account Compromise Early**

Configure alerts specifically for the Security Account:
- Any `CreateAccessKey` event for `SecurityAuditor1` or `IncidentResponder1` outside Terraform runs
- Any new IAM user creation
- Any changes to `IncidentResponderRole` or `SecurityAuditorRole` trust policies
- Console logins from unexpected IPs

---

## 7. Monitoring and Alerting Recommendations

### Immediate (Deploy with This Project)

- [ ] Enable CloudTrail in both accounts, deliver to S3
- [ ] Enable GuardDuty in both accounts
- [ ] Create CloudWatch alarm for `AssumeRole` events by `IncidentResponderRole`
- [ ] Enable IAM Access Analyzer in workload account

### Short Term (Next 30 Days)

- [ ] Add a dedicated Logging Account — S3 bucket with `s3:PutObject` only from Security and Workload accounts
- [ ] Enable AWS Config in workload account — detect drift from expected IAM configuration
- [ ] Create AWS Config rule: "No IAM users in workload account"
- [ ] Create AWS Config rule: "All roles must have MaxSessionDuration <= 3600"
- [ ] Set up Security Hub to aggregate all findings

### Long Term (Scaling Phase)

- [ ] Migrate to AWS IAM Identity Center for all human access
- [ ] Implement AWS Organizations with SCPs
- [ ] Automate ExternalId rotation on a 90-day schedule
- [ ] Integrate findings with a SIEM (Splunk, Datadog Security, or AWS native via EventBridge)
- [ ] Run quarterly IAM Access Analyzer reviews and remediate any external access findings
