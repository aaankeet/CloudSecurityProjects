# AWS Cross-Account IAM Access — Security Architecture

> **Production-grade cross-account IAM role chaining** with MFA enforcement, ExternalId protection, and least-privilege permissions — built with Terraform.

---

## Overview

This project implements a secure **hub-and-spoke** IAM architecture where a central **Security Account** acts as the identity hub, and a **Workload Account** grants scoped access only via trusted role chains — never through long-lived credentials or direct user access.

Two personas are modeled end-to-end:

| Persona | Access Pattern | MFA Required |
|---|---|---|
| `SecurityAuditor1` | Read-only view of workload resources | No |
| `IncidentResponder1` | Limited EC2/IAM remediation actions | Yes |

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           SECURITY ACCOUNT (111111111111)                        │
│                                                                                  │
│   ┌─────────────────────┐          ┌──────────────────────────┐                 │
│   │   SecurityAuditor1  │─assumes─▶│    SecurityAuditorRole    │                │
│   │      (IAM User)     │          │  + AssumeRole permission  │                │
│   └─────────────────────┘          └────────────┬─────────────┘                │
│                                                  │                               │
│   ┌─────────────────────┐          ┌─────────────▼────────────┐                 │
│   │  IncidentResponder1 │─MFA──── ▶│   IncidentResponderRole   │                │
│   │      (IAM User)     │          │  + AssumeRole permission  │                │
│   └─────────────────────┘          └────────────┬─────────────┘                │
│                                                  │                               │
└──────────────────────────────────────────────────┼──────────────────────────────┘
                                                   │ Cross-Account STS AssumeRole
                                                   │ + ExternalId validation
┌──────────────────────────────────────────────────┼──────────────────────────────┐
│                           WORKLOAD ACCOUNT (222222222222)                        │
│                                                  │                               │
│                             ┌────────────────────▼──────────────────────┐       │
│                             │           SecurityAuditRole                │       │
│                             │        AWS Managed: ReadOnlyAccess         │       │
│                             └───────────────────────────────────────────┘       │
│                                                                                  │
│                             ┌───────────────────────────────────────────┐       │
│                             │          IncidentResponseRole              │       │
│                             │    Custom: EC2/IAM read + scoped writes    │       │
│                             │    (only on SecurityManaged=true tags)     │       │
│                             └───────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## File Structure

```
.
├── provider.tf          # AWS provider config for both accounts
├── variables.tf         # All input variables
├── terraform.tfvars     # Account IDs and ExternalId values
├── security-iam.tf      # Users, roles, and policies in Security Account
├── workload-iam.tf      # Roles and trust policies in Workload Account
├── role-policy.tf       # Permission policies attached to workload roles
└── outputs.tf           # Credentials output (sensitive)
```

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) v2
- Two AWS accounts with admin access
- Named AWS CLI profiles: `security-account` and `workload-account`

---

## Deployment

```bash
# 1. Configure AWS CLI profiles
aws configure --profile security-account   # Admin user in Security Account
aws configure --profile workload-account   # Admin user in Workload Account

# 2. Initialize Terraform
terraform init

# 3. Preview changes
terraform plan

# 4. Deploy
terraform apply

# 5. Retrieve credentials
terraform output -raw security_auditor1_secret_access_key
terraform output -raw incident_responder1_secret_access_key
```

---

## Testing the Role Chain

### SecurityAuditor1 → Read-Only Access

```bash
# Step 1: Assume SecurityAuditorRole in Security Account
$creds = aws sts assume-role `
  --profile auditor1 `
  --role-arn "arn:aws:iam::SECURITY_ACCOUNT_ID:role/SecurityAuditorRole" `
  --role-session-name "AuditSession1" | ConvertFrom-Json

$env:AWS_ACCESS_KEY_ID=$creds.Credentials.AccessKeyId
$env:AWS_SECRET_ACCESS_KEY=$creds.Credentials.SecretAccessKey
$env:AWS_SESSION_TOKEN=$creds.Credentials.SessionToken

# Step 2: Assume SecurityAuditRole in Workload Account
$creds2 = aws sts assume-role `
  --role-arn "arn:aws:iam::WORKLOAD_ACCOUNT_ID:role/SecurityAuditRole" `
  --role-session-name "WorkloadAuditSession" `
  --external-id "YOUR_EXTERNAL_ID" | ConvertFrom-Json
```

### IncidentResponder1 → Scoped Remediation (MFA Required)

```bash
# Step 1: Assume IncidentResponderRole WITH MFA
$creds = aws sts assume-role `
  --profile responder1 `
  --role-arn "arn:aws:iam::SECURITY_ACCOUNT_ID:role/IncidentResponderRole" `
  --role-session-name "IncidentSession1" `
  --serial-number "arn:aws:iam::SECURITY_ACCOUNT_ID:mfa/IncidentResponder1" `
  --token-code "123456" | ConvertFrom-Json

$env:AWS_ACCESS_KEY_ID=$creds.Credentials.AccessKeyId
$env:AWS_SECRET_ACCESS_KEY=$creds.Credentials.SecretAccessKey
$env:AWS_SESSION_TOKEN=$creds.Credentials.SessionToken

# Step 2: Assume IncidentResponseRole in Workload Account
$creds2 = aws sts assume-role `
  --role-arn "arn:aws:iam::WORKLOAD_ACCOUNT_ID:role/IncidentResponseRole" `
  --role-session-name "WorkloadIncidentSession" `
  --external-id "YOUR_EXTERNAL_ID" | ConvertFrom-Json
```

---

## Security Design Decisions

See [SECURITY.md](./SECURITY.md) for full write-up covering:
- Why role chaining over long-lived credentials
- ExternalId and confused deputy protection
- MFA enforcement design
- Scaling to 20–100 accounts
- Monitoring and alerting recommendations
- Blast radius analysis

---

## Cleanup

```bash
terraform destroy
```

---

## License

MIT
