# CloudCart Security Remediation Roadmap

## 1. Purpose

This roadmap translates the CloudCart threat-model findings into prioritized remediation activities.

The remediation strategy is designed to:

* Reduce the likelihood of initial compromise
* Reduce the blast radius of a compromised workload
* Protect sensitive data and secrets
* Improve detection and investigation capabilities
* Break the AP-01 attack path at multiple stages
* Establish measurable remediation verification criteria

Remediation is organized into a 30/60/90-day plan.

---

# 2. Remediation Strategy

CloudCart's primary systemic attack path is:

```text
Internet
   ↓
Application Compromise
   ↓
ECS Workload Compromise
   ↓
Workload Identity Abuse
   ↓
Excessive IAM Permissions
   ↓
AWS Resource Access
   ├── S3
   ├── Secrets Manager
   └── RDS
```

The remediation strategy therefore follows a defense-in-depth model.

Controls should prevent or detect compromise at multiple stages rather than depending on a single security boundary.

The highest remediation priority is reducing the permissions and resource access available to a compromised ECS workload.

---

# 3. Remediation Priority

| Priority | Definition                                     | Target     |
| -------- | ---------------------------------------------- | ---------- |
| P1       | Critical exposure or major attack-path enabler | 0–30 days  |
| P2       | Significant security weakness                  | 31–60 days |
| P3       | Security hardening and maturity improvement    | 61–90 days |

---

# 4. 0–30 Days — Critical Risk Reduction

The first 30 days focus on reducing immediate exposure and breaking the highest-risk portions of AP-01.

## R01 — Reduce ECS IAM Permissions

**Related Finding:** E02
**Risk:** 25/25 — Critical
**Owner:** Cloud / Platform Engineering
**Target:** 0–30 days

### Problem

The ECS workload identity has permissions beyond those required for normal application operation.

A compromised workload could therefore use its AWS identity to access additional resources.

### Remediation

* Inventory AWS API actions required by the application
* Remove unused IAM permissions
* Eliminate unnecessary wildcard actions
* Scope policies to required resources
* Separate permissions by workload function where appropriate
* Review policies using IAM Access Analyzer
* Review CloudTrail activity before removing permissions where operational dependencies are uncertain

### Example

Avoid broad authorization such as:

```json
{
  "Effect": "Allow",
  "Action": "s3:*",
  "Resource": "*"
}
```

Prefer narrowly scoped authorization such as:

```json
{
  "Effect": "Allow",
  "Action": [
    "s3:GetObject"
  ],
  "Resource": "arn:aws:s3:::cloudcart-product-assets/*"
}
```

The exact production policy should be derived from legitimate workload requirements.

### Verification

Confirm that:

* The workload can perform required application functions
* Unnecessary AWS API actions are denied
* Access is restricted to expected resources
* IAM Access Analyzer does not identify unintended access paths
* CloudTrail records workload API activity

### Expected Risk Reduction

Reduces the blast radius of ECS compromise and directly disrupts AP-01.

---

## R02 — Eliminate Public S3 Exposure

**Related Finding:** I04
**Risk:** 20/25 — Critical
**Owner:** Cloud / Platform Engineering
**Target:** 0–30 days

### Remediation

* Enable S3 Block Public Access
* Review bucket policies
* Review legacy ACL usage
* Remove unintended anonymous access
* Apply least-privilege IAM
* Review findings from S3 Access Analyzer
* Enable appropriate logging for sensitive buckets

### Verification

Attempt unauthenticated access to objects that should remain private.

Expected result:

```text
Access Denied
```

Review S3 configuration to confirm no unintended public access remains.

---

## R03 — Restrict Secrets Manager Access

**Related Finding:** I05
**Risk:** 20/25 — Critical
**Owner:** Cloud / Platform Engineering
**Target:** 0–30 days

### Remediation

* Identify secrets required by each workload
* Remove broad `secretsmanager:*` permissions
* Restrict `GetSecretValue` to explicitly required secrets
* Separate secrets by workload
* Enable appropriate rotation
* Review KMS permissions
* Monitor secret-access API activity

### Verification

Confirm that the ECS role:

* Can retrieve required application secrets
* Cannot retrieve unrelated secrets
* Cannot administer Secrets Manager unless explicitly required

Review CloudTrail for expected secret-access events.

---

## R04 — Harden RDS Access

**Related Finding:** I02
**Risk:** 20/25 — Critical
**Owner:** Cloud / Database Engineering
**Target:** 0–30 days

### Remediation

* Ensure RDS is not publicly accessible
* Restrict inbound connectivity to approved application security groups
* Use least-privilege database accounts
* Store credentials in Secrets Manager
* Require encrypted connections where supported
* Maintain encryption at rest
* Review database permissions
* Enable appropriate database auditing

### Verification

Confirm:

* Direct Internet connectivity to the database is unavailable
* Only approved application paths can establish connections
* Application credentials have only required database privileges
* Unauthorized database actions are rejected

---

## R05 — Address Application Compromise Paths

**Related Finding:** E01
**Risk:** 20/25 — Critical
**Owner:** Application Security / Development
**Target:** 0–30 days

### Remediation

Prioritize security testing for:

* SSRF
* Injection vulnerabilities
* Authentication flaws
* Authorization flaws
* Vulnerable dependencies
* Insecure file processing
* Unsafe outbound requests

Implement:

* Input validation
* Secure coding controls
* Dependency scanning
* Container image scanning
* Application security testing
* Restricted outbound connectivity where operationally feasible

### Verification

Perform authorized application-security testing and confirm identified weaknesses are no longer reproducible.

---

# 5. 31–60 Days — High-Risk Remediation

The second phase addresses high-risk findings and strengthens preventive controls.

## R06 — Restrict Direct ALB Access

**Related Finding:** I01
**Owner:** Cloud / Network Engineering

Ensure clients cannot unintentionally bypass the intended CloudFront and WAF security path.

### Verification

Confirm that direct-origin requests outside the approved architecture are rejected.

---

## R07 — Strengthen Authentication Controls

**Related Finding:** S01
**Owner:** Application / Identity Team

Implement or review:

* Strong authentication policies
* MFA where appropriate
* Login rate limiting
* Credential-abuse detection
* Authentication logging
* Account protection mechanisms

---

## R08 — Improve Request Validation

**Related Finding:** T01
**Owner:** Application Engineering

Implement:

* Server-side validation
* Parameterized queries
* API schema validation
* Authorization validation
* Secure error handling

Security controls should exist within the application rather than relying solely on WAF filtering.

---

## R09 — Strengthen S3 Authorization and Integrity

**Related Findings:** I03, T04
**Owner:** Cloud / Platform Engineering

Implement:

* Resource-scoped IAM
* Restrictive bucket policies
* Separation of read and write privileges
* S3 versioning where appropriate
* CloudTrail data events for sensitive buckets
* Recovery procedures

---

## R10 — Improve Database Integrity Controls

**Related Finding:** T03
**Owner:** Database / Application Engineering

Implement:

* Least-privilege database authorization
* Parameterized queries
* Database auditing
* Backup and recovery procedures
* Change monitoring for sensitive records

---

## R11 — Improve Availability Protections

**Related Finding:** D01
**Owner:** Cloud / Platform Engineering

Review:

* WAF rate-based rules
* CloudFront configuration
* AWS Shield protections
* ECS autoscaling
* Application throttling
* CloudWatch alarms

---

## R12 — Strengthen Audit Logging

**Related Finding:** R01
**Owner:** Cloud Security

Ensure security-relevant AWS activity can be reconstructed during an investigation.

Implement:

* Appropriate CloudTrail coverage
* Centralized security logging
* Protected log storage
* Defined retention periods
* Monitoring for security-sensitive AWS API activity
* GuardDuty and Security Hub integration where appropriate

---

# 6. 61–90 Days — Security Hardening

The final phase focuses on security maturity and detection improvements.

## R13 — Tune AWS WAF

**Related Finding:** T02
**Owner:** Cloud Security / Application Security

Review:

* Managed rule groups
* Custom rules
* Rate-based rules
* False positives
* Repeated suspicious request patterns
* WAF logs

WAF tuning should be an ongoing process rather than a one-time configuration activity.

---

## R14 — Implement Log Sanitization

**Related Finding:** I06
**Owner:** Application Engineering

Prevent logs from containing:

* Passwords
* API keys
* Session tokens
* Authorization headers
* Application secrets
* Unnecessary customer PII

Implement structured logging and sensitive-field redaction.

---

## R15 — Improve Detection Engineering

**Owner:** Cloud Security

Develop detections for events relevant to AP-01, including:

* Unexpected API calls from the ECS workload role
* Unusual secret retrieval
* Unusual S3 object access
* IAM policy changes
* Security-control modification
* Suspicious authentication activity

Use available telemetry from:

* CloudTrail
* CloudWatch
* GuardDuty
* Security Hub
* AWS WAF

---

# 7. Remediation Tracking Matrix

| ID  | Finding                    | Risk      | Owner                   | Target     | Verification                           |
| --- | -------------------------- | --------- | ----------------------- | ---------- | -------------------------------------- |
| R01 | Excessive IAM permissions  | Critical  | Cloud / Platform        | 0–30 days  | Unauthorized API actions denied        |
| R02 | Public S3 exposure         | Critical  | Cloud / Platform        | 0–30 days  | Anonymous access denied                |
| R03 | Secrets disclosure         | Critical  | Cloud / Platform        | 0–30 days  | ECS limited to required secrets        |
| R04 | Unauthorized RDS access    | Critical  | Cloud / DB              | 0–30 days  | Only approved application path allowed |
| R05 | Application compromise     | Critical  | AppSec / Development    | 0–30 days  | Security testing validates fixes       |
| R06 | Direct ALB exposure        | High      | Cloud / Network         | 31–60 days | Direct-origin bypass rejected          |
| R07 | Account compromise         | High      | Application / Identity  | 31–60 days | Authentication controls validated      |
| R08 | Request manipulation       | High      | Application             | 31–60 days | Invalid requests rejected              |
| R09 | S3 authorization/integrity | High      | Cloud / Platform        | 31–60 days | Unauthorized operations denied         |
| R10 | Database manipulation      | High      | DB / Application        | 31–60 days | Unauthorized writes denied             |
| R11 | Application DoS            | High      | Cloud / Platform        | 31–60 days | Rate limits and alarms validated       |
| R12 | Auditability               | High      | Cloud Security          | 31–60 days | Security events traceable              |
| R13 | WAF evasion                | Medium    | Cloud Security / AppSec | 61–90 days | WAF rules reviewed and tested          |
| R14 | Sensitive logging          | Medium    | Application             | 61–90 days | Sensitive values absent from logs      |
| R15 | Detection coverage         | Hardening | Cloud Security          | 61–90 days | Detection tests generate alerts        |

---

# 8. AP-01 Control Mapping

The remediation plan breaks AP-01 at multiple points.

| Attack Stage             | Preventive Control                            | Detective Control                   |
| ------------------------ | --------------------------------------------- | ----------------------------------- |
| Internet → Application   | WAF, validation, rate limiting                | WAF logs                            |
| Application exploitation | Secure coding, testing, dependency management | Application / CloudWatch telemetry  |
| ECS compromise           | Container hardening, segmentation             | Runtime and application telemetry   |
| Workload identity abuse  | IAM least privilege                           | CloudTrail, GuardDuty               |
| Secrets access           | Secret-specific IAM, KMS                      | CloudTrail                          |
| S3 access                | Bucket policy, IAM, Block Public Access       | CloudTrail data events              |
| Database access          | Security groups, DB least privilege           | DB audit logs                       |
| AWS control-plane abuse  | IAM restrictions                              | CloudTrail, GuardDuty, Security Hub |

This approach ensures failure of one security control does not automatically result in complete compromise.

---

# 9. Residual Risk

Remediation reduces risk but does not eliminate it.

For example, even after IAM permissions are reduced, the ECS workload still requires legitimate access to certain AWS resources.

A sufficiently compromised workload may therefore abuse permissions that are operationally necessary.

Residual risk should be managed through:

* Least privilege
* Network segmentation
* Continuous monitoring
* Detection engineering
* Periodic access reviews
* Vulnerability management
* Incident-response readiness

---

# 10. Success Criteria

The remediation program is considered successful when:

1. No unintended S3 resources are publicly accessible.
2. ECS workload permissions are limited to documented business requirements.
3. Workloads can retrieve only explicitly authorized secrets.
4. RDS is accessible only through approved application paths.
5. Critical application vulnerabilities have been remediated.
6. Direct bypass of intended edge protections is prevented.
7. Sensitive information is excluded from application logs.
8. Security-sensitive AWS API activity is auditable.
9. High-risk activity generates actionable security alerts.
10. AP-01 cannot progress through its documented stages without encountering multiple independent preventive or detective controls.
