# CloudCart Attack Path Analysis

## AP-01 — Application Compromise → AWS Resource Access

### Objective

Obtain unauthorized access to AWS resources through compromise
of the CloudCart application and abuse of its workload identity.

### Attack Path

Internet
↓
CloudCart API
↓
Application vulnerability
↓
SSRF
↓
ECS workload
↓
AWS workload identity
↓
IAM permissions
↓
AWS resources

### Relevant Threats

- T06 — SSRF → AWS credentials
- T07 — Excessive ECS IAM permissions
- T10 — Secrets theft
- T08 — Database compromise

### Assets at Risk

- IAM task role
- Secrets Manager
- S3
- RDS
- Customer PII

### Potential Impact

Unauthorized access to sensitive AWS resources and
potential exposure or manipulation of customer data.

### Risk

Likelihood: 4/5
Impact: 5/5
Risk Score: 20/25
Rating: Critical

### Preventive Controls

- SSRF protections
- IAM least privilege
- Workload identity hardening
- Network egress controls
- Secrets Manager
- Encryption
- Security groups

### Detective Controls

- CloudTrail
- GuardDuty
- CloudWatch
- WAF logging
- Security Hub

### Recommended Remediation

1. Remove unnecessary IAM permissions.
2. Restrict access to specific S3 resources.
3. Restrict Secrets Manager access to required secrets.
4. Implement SSRF protections.
5. Restrict unnecessary outbound network access.
6. Monitor AWS API activity from ECS workloads.
7. Alert on anomalous access to sensitive resources.
