# CloudCart Hardened Target-State Architecture

## 1. Purpose

This document defines the target-state security architecture for CloudCart after implementation of the prioritized remediation plan.

The hardened design is intended to:

* Reduce Internet-facing exposure
* Limit the blast radius of application compromise
* Enforce least-privilege workload identity
* Protect secrets and sensitive data
* Improve network segmentation
* Strengthen logging and detection
* Break attack path AP-01 at multiple independent control points

The design follows a defense-in-depth approach.

---

# 2. Target-State Architecture

```text
                           Internet
                              │
                              ▼
                       Amazon CloudFront
                              │
                              ▼
                          AWS WAF
                              │
                              ▼
                  Application Load Balancer
                  Restricted Origin Access
                              │
                    ┌─────────┴─────────┐
                    │                   │
                    ▼                   ▼
               ECS Application     ECS Application
                  Task A               Task B
                    │                   │
                    └─────────┬─────────┘
                              │
                    Scoped ECS Task Role
                              │
            ┌─────────────────┼──────────────────┐
            │                 │                  │
            ▼                 ▼                  ▼
       Approved S3       Secrets Manager       RDS PostgreSQL
         Prefixes          Required Secrets       Private
            │                 │                  Subnets
            │                 │
            ▼                 ▼
      Encryption /       KMS Encryption
       Versioning

────────────────────────────────────────────────────────────

                 Security Monitoring Plane

     WAF Logs ───────────────┐
     Application Logs ───────┤
     ECS / CloudWatch ───────┤
     CloudTrail ─────────────┼──► Security Monitoring
     GuardDuty ──────────────┤
     Security Hub ───────────┤
     RDS Audit Logs ─────────┘

────────────────────────────────────────────────────────────

                 Administrative Plane

          Authorized Administrators
                    │
                    ▼
               IAM / SSO
                    │
             MFA + Least Privilege
                    │
                    ▼
           AWS Management Plane
```

---

# 3. Major Security Improvements

## 3.1 Edge Security

The intended public path is:

```text
Internet
   ↓
CloudFront
   ↓
AWS WAF
   ↓
ALB
   ↓
ECS
```

The Application Load Balancer should not serve as an unintended alternative public entry point that bypasses the expected edge controls.

Controls include:

* CloudFront
* AWS WAF
* Rate-based protections
* Restrictive ALB security configuration
* TLS
* Centralized edge logging

This addresses:

* T01 — Malicious request manipulation
* D01 — Application-layer DoS
* T02 — WAF evasion
* I01 — Direct ALB exposure

---

# 4. Workload Isolation

The ECS application remains a critical trust boundary.

The workload should operate with only the access required for normal business functions.

Controls include:

* Hardened container images
* Dependency scanning
* Container image scanning
* Minimal runtime privileges
* Restricted outbound connectivity where feasible
* Application security testing
* Runtime monitoring
* Controlled deployment processes

Application compromise should not automatically result in broad AWS access.

---

# 5. Least-Privilege Workload Identity

The ECS task role is redesigned using least privilege.

Instead of broad permissions:

```text
s3:*
secretsmanager:*
Resource: *
```

the target state uses:

```text
Required API action
        +
Required resource
        +
Required workload
```

Example conceptual permission model:

```text
ECS Application
      │
      ├── s3:GetObject
      │      └── cloudcart-product-assets/*
      │
      └── secretsmanager:GetSecretValue
             └── cloudcart/application/database
```

The task role should not have:

* IAM administration permissions
* Broad S3 access
* Broad Secrets Manager access
* Security-service administration
* Permissions unrelated to application functionality

This directly reduces the impact of E02 — Excessive IAM Permissions.

---

# 6. S3 Security

S3 resources should use explicit access boundaries.

Controls include:

* S3 Block Public Access
* Restrictive bucket policies
* Resource-scoped IAM
* Encryption at rest
* Versioning where appropriate
* CloudTrail data events for sensitive buckets
* Access Analyzer
* Logging and alerting

Application permissions should be scoped to required:

```text
Bucket
+
Prefix
+
Operation
```

Example:

```text
Product application
   ↓
GetObject
   ↓
cloudcart-product-assets/products/*
```

rather than:

```text
Application
   ↓
s3:*
   ↓
All buckets
```

---

# 7. Secrets Management

Application secrets remain in Secrets Manager.

The target-state design requires:

* Secret-specific IAM authorization
* KMS encryption
* Secret rotation
* Access logging
* Separation between workloads
* Prevention of secrets appearing in logs

Example access model:

```text
ECS Application Role
        │
        ▼
GetSecretValue
        │
        ▼
CloudCart Application DB Secret
```

The workload should not be able to enumerate or retrieve unrelated secrets.

---

# 8. Database Security

Amazon RDS is deployed as a private data service.

The target state requires:

* No public database exposure
* Private subnet placement
* Security-group restrictions
* Access only from approved application security groups
* Encryption at rest
* TLS where supported
* Least-privilege database credentials
* Secrets Manager integration
* Database auditing
* Backup and recovery controls

Network path:

```text
Internet
   X
   │
   │ No direct path
   ▼

ECS Security Group
        │
        ▼
RDS Security Group
        │
        ▼
PostgreSQL
```

Only approved application traffic should reach the database listener.

---

# 9. Network Segmentation

Security groups should enforce service-to-service trust.

Conceptual model:

```text
CloudFront / Edge
       │
       ▼
      ALB
       │
       ▼
      ECS
       │
       ├────────► RDS
       │
       └────────► Approved AWS services
```

Each layer should accept only required traffic.

The design avoids unnecessary lateral connectivity.

---

# 10. Outbound Connectivity Controls

Outbound workload access should be treated as part of the attack surface.

Where operationally feasible, CloudCart should restrict outbound connectivity to required destinations and services.

This helps reduce risks associated with:

* SSRF
* Malware callbacks
* Data exfiltration
* Unapproved service access
* Unexpected external communication

Outbound filtering should not break legitimate application dependencies.

Required destinations must first be documented and baselined.

---

# 11. Logging Architecture

The hardened design centralizes security-relevant telemetry.

```text
AWS WAF
   │
   ├──────────────┐
   │              │
Application       │
Logs              │
   │              │
CloudWatch        │
   │              │
CloudTrail        ├────► Security Monitoring
   │              │
GuardDuty         │
   │              │
Security Hub      │
   │              │
RDS Audit Logs ───┘
```

Logs should be:

* Centralized
* Access-controlled
* Retained according to policy
* Protected against unauthorized modification
* Searchable during investigations

---

# 12. CloudTrail

CloudTrail provides visibility into AWS API and account activity.

The target architecture should provide sufficient coverage for investigation of:

* IAM changes
* Workload-role activity
* Secrets Manager access
* S3 configuration changes
* Security-service modifications
* Administrative actions

Sensitive S3 resources should also receive appropriate object-level data-event coverage where required by the monitoring strategy.

---

# 13. GuardDuty

GuardDuty provides AWS-native threat detection.

Where supported and enabled, Runtime Monitoring should add visibility into ECS workload behavior.

GuardDuty findings should be incorporated into analyst workflows and correlated with:

* CloudTrail
* WAF
* Application logs
* CloudWatch
* Security Hub

---

# 14. Security Hub

Security Hub provides a centralized view of relevant security findings and security-control status.

The target-state workflow is:

```text
Security Services
       │
       ▼
   Security Hub
       │
       ▼
Cloud Security Analyst
       │
       ├── Triage
       ├── Correlation
       ├── Investigation
       └── Remediation
```

Security Hub is a consolidation and prioritization layer, not a substitute for reviewing source telemetry.

---

# 15. Administrative Access

Human administrative access should be separated from workload identities.

Administrators should use:

* Centralized identity
* MFA
* Short-lived credentials where possible
* Role-based authorization
* Least privilege
* Logging
* Periodic access review

Long-lived administrator credentials should be minimized.

Workload identities and human identities should not share permissions unnecessarily.

---

# 16. Security Control Mapping

| Threat                        | Target-State Control                                    |
| ----------------------------- | ------------------------------------------------------- |
| S01 Account compromise        | MFA, authentication monitoring, rate limiting           |
| T01 Request manipulation      | Input validation, WAF, secure coding                    |
| D01 Application DoS           | CloudFront, WAF rate limits, autoscaling                |
| T02 WAF evasion               | Managed/custom rules, tuning, application controls      |
| I01 Direct ALB exposure       | Restricted origin path and security groups              |
| E01 Application compromise    | Secure SDLC, scanning, segmentation, runtime monitoring |
| E02 Excessive IAM permissions | Least-privilege task role                               |
| I02 Unauthorized DB access    | Private RDS, SG controls, DB least privilege            |
| T03 DB manipulation           | DB authorization, auditing, backups                     |
| I03 Unauthorized S3 access    | Resource-scoped IAM and bucket policies                 |
| T04 S3 manipulation           | Scoped writes, versioning, monitoring                   |
| I04 Public S3 exposure        | Block Public Access, policy controls                    |
| I05 Secrets disclosure        | Secret-specific IAM, rotation, KMS                      |
| I06 Sensitive logs            | Redaction and controlled log access                     |
| R01 Insufficient auditability | CloudTrail and centralized logging                      |

---

# 17. AP-01 Before Remediation

Original risk path:

```text
Internet
   ↓
Application Vulnerability
   ↓
ECS Workload Compromise
   ↓
Broad Workload Role
   ↓
Secrets / S3 / RDS
   ↓
Sensitive Data
```

The critical weakness is that compromise of one application component can provide access to additional AWS resources.

---

# 18. AP-01 After Remediation

Target-state path:

```text
Internet
   ↓
CloudFront
   ↓
WAF
   ↓
Application
   │
   ├── Secure coding controls
   ├── Input validation
   ├── Hardened workload
   └── Runtime monitoring
          ↓
     ECS Task Role
          │
          ├── Least privilege
          ├── Resource-scoped access
          └── CloudTrail monitoring
                 ↓
         Approved AWS Resources Only
```

If application compromise still occurs:

```text
Compromised Application
        ↓
Restricted Task Role
        ↓
Limited Resource Scope
        ↓
Monitored API Activity
        ↓
Detection / Containment
```

The architecture therefore assumes compromise is possible but limits what a compromised workload can reach.

---

# 19. Defense-in-Depth Model

CloudCart uses multiple independent security layers:

```text
Layer 1
Edge protection

Layer 2
Application security

Layer 3
Workload isolation

Layer 4
IAM least privilege

Layer 5
Network segmentation

Layer 6
Data and secrets protection

Layer 7
Logging and detection

Layer 8
Incident response
```

No single layer is considered sufficient.

---

# 20. Security Design Principles

The hardened architecture follows these principles:

### Least Privilege

Grant only the permissions required for legitimate operations.

### Explicit Trust Boundaries

Clearly define communication between:

* Internet and edge
* Edge and application
* Application and AWS APIs
* Application and data stores
* Human identities and AWS administration

### Minimize Blast Radius

A compromised workload should not gain broad access to the environment.

### Assume Compromise

Security design should account for the possibility that individual components may fail.

### Centralized Visibility

Security events should be visible and attributable.

### Defense in Depth

Preventive and detective controls should overlap across the attack path.

---

# 21. Target-State Security Outcome

The hardened design changes the security model from:

```text
Application compromise
        =
Potential broad cloud compromise
```

to:

```text
Application compromise
        ≠
Automatic cloud compromise
```

A successful attack must overcome multiple independent security boundaries.

Even where prevention fails, the environment should provide sufficient telemetry for timely detection, investigation, and containment.
