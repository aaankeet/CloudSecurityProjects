# CloudCart Threat Register

## Overview

This threat register consolidates the security threats identified during the CloudCart AWS threat modeling assessment.

Threats were identified using STRIDE and evaluated using the following risk model:

**Risk Score = Likelihood × Impact**

Likelihood and impact are scored from 1–5.

| Risk Score | Rating   |
| ---------: | -------- |
|        1–4 | Low      |
|        5–9 | Medium   |
|      10–16 | High     |
|      17–25 | Critical |

The ratings represent scenario-based security risk assessments rather than statistical probabilities.

---

## Threat Register

| ID  | Data Flow | STRIDE                             | Threat                              | Primary Asset         |  L |  I | Score | Rating   | Priority |
| --- | --------- | ---------------------------------- | ----------------------------------- | --------------------- | -: | -: | ----: | -------- | -------- |
| S01 | DF01      | Spoofing                           | Customer account compromise         | Customer credentials  |  4 |  4 |    16 | High     | P2       |
| T01 | DF01      | Tampering                          | Malicious request manipulation      | ECS application       |  4 |  4 |    16 | High     | P2       |
| D01 | DF01      | DoS                                | Application-layer denial of service | ECS application       |  3 |  4 |    12 | High     | P2       |
| T02 | DF02      | Tampering / DoS                    | WAF evasion                         | ECS application       |  3 |  3 |     9 | Medium   | P3       |
| I01 | DF03      | Information Disclosure / DoS       | Direct ALB exposure                 | ALB / application     |  3 |  4 |    12 | High     | P2       |
| E01 | DF04      | Elevation of Privilege             | Application compromise              | ECS workload          |  4 |  5 |    20 | Critical | P1       |
| E02 | DF05      | Elevation of Privilege             | Excessive IAM permissions           | IAM workload role     |  5 |  5 |    25 | Critical | P1       |
| I02 | DF06      | Information Disclosure             | Unauthorized database access        | RDS / customer data   |  4 |  5 |    20 | Critical | P1       |
| T03 | DF06      | Tampering                          | Database manipulation               | RDS / order data      |  3 |  5 |    15 | High     | P2       |
| I03 | DF07      | Information Disclosure             | Unauthorized S3 access              | S3 objects            |  4 |  4 |    16 | High     | P2       |
| T04 | DF07      | Tampering                          | S3 object manipulation              | S3 objects            |  3 |  4 |    12 | High     | P2       |
| I04 | DF07      | Information Disclosure             | Public S3 exposure                  | S3 objects            |  4 |  5 |    20 | Critical | P1       |
| I05 | DF08      | Information Disclosure / Elevation | Secrets disclosure                  | Application secrets   |  4 |  5 |    20 | Critical | P1       |
| I06 | DF09      | Information Disclosure             | Sensitive information in logs       | Logs / sensitive data |  3 |  3 |     9 | Medium   | P3       |
| R01 | DF10      | Repudiation                        | Insufficient auditability           | CloudTrail logs       |  3 |  4 |    12 | High     | P2       |

---

# Detailed Findings

## S01 — Customer Account Compromise

**Data Flow:** DF01 — Customer → CloudFront
**STRIDE Category:** Spoofing
**Primary Asset:** Customer credentials
**Risk:** 16/25 — High
**Priority:** P2

### Threat

An attacker may obtain or reuse valid customer credentials and impersonate a legitimate CloudCart customer.

Potential contributing factors include weak passwords, credential reuse, automated credential attacks, and insufficient authentication monitoring.

### Security Impact

Successful account compromise could result in:

* Unauthorized access to customer information
* Unauthorized order activity
* Exposure of account-specific data
* Abuse of authenticated application functionality

### Recommended Controls

* Strong authentication controls
* MFA where appropriate
* Rate limiting
* Credential-stuffing detection
* AWS WAF protections
* Authentication-event monitoring
* Account lockout or adaptive protections

---

## T01 — Malicious Request Manipulation

**Data Flow:** DF01 — Customer → CloudFront
**STRIDE Category:** Tampering
**Primary Asset:** ECS application
**Risk:** 16/25 — High
**Priority:** P2

### Threat

An attacker may manipulate HTTP requests, parameters, headers, or application input to trigger unintended application behavior.

### Recommended Controls

* Server-side input validation
* Parameterized database queries
* Secure coding practices
* API schema validation
* AWS WAF
* Application security testing
* Dependency and vulnerability scanning

---

## D01 — Application-Layer Denial of Service

**Data Flow:** DF01 — Customer → CloudFront
**STRIDE Category:** Denial of Service
**Primary Asset:** ECS application
**Risk:** 12/25 — High
**Priority:** P2

### Threat

An attacker may generate excessive or computationally expensive requests to degrade CloudCart availability.

### Recommended Controls

* CloudFront
* AWS WAF rate-based rules
* AWS Shield protections
* ECS autoscaling
* Resource limits
* CloudWatch monitoring and alarms
* Application-level throttling

---

## T02 — WAF Evasion

**Data Flow:** DF02 — CloudFront → WAF
**STRIDE Category:** Tampering / Denial of Service
**Primary Asset:** ECS application
**Risk:** 9/25 — Medium
**Priority:** P3

### Threat

Malicious requests may bypass incomplete, outdated, or improperly tuned WAF rules and reach the application.

### Recommended Controls

* AWS managed WAF rule groups
* Application-specific custom rules
* Rate-based rules
* WAF logging
* Regular rule tuning
* Monitoring of blocked and permitted suspicious requests

---

## I01 — Direct ALB Exposure

**Data Flow:** DF03 — WAF → ALB
**STRIDE Category:** Information Disclosure / Denial of Service
**Primary Asset:** Application entry point
**Risk:** 12/25 — High
**Priority:** P2

### Threat

If the Application Load Balancer is directly reachable outside the intended CloudFront/WAF path, an attacker may bypass edge security controls.

### Recommended Controls

* Restrict ALB ingress
* Use restrictive security groups
* Prevent unintended direct-origin access
* Maintain CloudFront/WAF as the intended public path
* Monitor direct-origin access attempts

---

## E01 — Application Compromise

**Data Flow:** DF04 — ALB → ECS
**STRIDE Category:** Elevation of Privilege
**Primary Asset:** ECS workload
**Risk:** 20/25 — Critical
**Priority:** P1

### Threat

A vulnerability in the CloudCart application may allow an attacker to compromise the ECS workload.

Relevant vulnerability classes include:

* SSRF
* Injection
* Authentication bypass
* Authorization flaws
* Vulnerable dependencies
* Insecure file processing
* Application configuration weaknesses

### Security Impact

Workload compromise could provide a foothold from which an attacker attempts to access AWS services available to the application.

This finding forms an important stage of attack path **AP-01**.

### Recommended Controls

* Secure SDLC
* Input validation
* Dependency scanning
* Container image scanning
* WAF protections
* Runtime monitoring
* Network segmentation
* Least-privilege workload identity
* Controlled outbound connectivity

---

## E02 — Excessive IAM Permissions

**Data Flow:** DF05 — ECS → IAM
**STRIDE Category:** Elevation of Privilege
**Primary Asset:** IAM workload role
**Risk:** 25/25 — Critical
**Priority:** P1

### Threat

The ECS workload identity has permissions beyond those required for normal CloudCart operation.

If the workload is compromised, an attacker may inherit these permissions and use them to access additional AWS resources.

### Security Impact

Potential impact includes:

* Unauthorized S3 access
* Secrets Manager access
* Access to sensitive application resources
* Increased blast radius following workload compromise

This finding is a major enabling condition for **AP-01**.

### Recommended Controls

* Apply least-privilege IAM
* Remove wildcard actions
* Restrict policies to required AWS resources
* Separate roles by workload function
* Review policies with IAM Access Analyzer
* Monitor workload API activity through CloudTrail
* Periodically review unused permissions

---

## I02 — Unauthorized Database Access

**Data Flow:** DF06 — ECS → RDS
**STRIDE Category:** Information Disclosure
**Primary Asset:** RDS / customer data
**Risk:** 20/25 — Critical
**Priority:** P1

### Threat

A compromised application, credential, or workload identity could enable unauthorized access to the CloudCart database.

### Security Impact

Potential consequences include exposure of:

* Customer PII
* Order information
* Application data
* Internal business information

### Recommended Controls

* Private database networking
* Restrictive security groups
* Least-privilege database accounts
* Secrets Manager
* TLS for database connections
* Encryption at rest
* Database auditing
* Credential rotation

---

## T03 — Database Manipulation

**Data Flow:** DF06 — ECS → RDS
**STRIDE Category:** Tampering
**Primary Asset:** RDS / order data
**Risk:** 15/25 — High
**Priority:** P2

### Threat

Unauthorized database access may allow an attacker to modify or delete application records.

### Recommended Controls

* Parameterized queries
* Database authorization
* Least-privilege database accounts
* Database auditing
* Backup and recovery procedures
* Data-integrity monitoring

---

## I03 — Unauthorized S3 Access

**Data Flow:** DF07 — ECS → S3
**STRIDE Category:** Information Disclosure
**Primary Asset:** S3 objects
**Risk:** 16/25 — High
**Priority:** P2

### Threat

An attacker who gains access to an authorized identity may retrieve S3 objects beyond the intended application requirements.

### Recommended Controls

* Least-privilege IAM
* Resource-scoped permissions
* Restrictive bucket policies
* S3 Access Analyzer
* CloudTrail data events for sensitive buckets
* Encryption at rest

---

## T04 — S3 Object Manipulation

**Data Flow:** DF07 — ECS → S3
**STRIDE Category:** Tampering
**Primary Asset:** S3 objects
**Risk:** 12/25 — High
**Priority:** P2

### Threat

Excessive write or delete permissions may allow unauthorized modification or destruction of S3 objects.

### Recommended Controls

* Separate read and write permissions
* Resource-level IAM restrictions
* S3 versioning
* Logging and monitoring
* Backup and recovery strategy
* Restrictive bucket policies

---

## I04 — Public S3 Exposure

**Data Flow:** DF07 — ECS → S3
**STRIDE Category:** Information Disclosure
**Primary Asset:** S3 objects
**Risk:** 20/25 — Critical
**Priority:** P1

### Threat

Incorrect bucket policies, ACLs, or public-access settings may expose S3 objects to unauthorized users.

### Recommended Controls

* S3 Block Public Access
* Restrictive bucket policies
* Disable unnecessary ACL-based access
* IAM least privilege
* S3 Access Analyzer
* Encryption
* Continuous configuration monitoring

---

## I05 — Secrets Disclosure

**Data Flow:** DF08 — ECS → Secrets Manager
**STRIDE Category:** Information Disclosure / Elevation of Privilege
**Primary Asset:** Application secrets
**Risk:** 20/25 — Critical
**Priority:** P1

### Threat

A compromised workload with broad Secrets Manager permissions may retrieve sensitive credentials or application secrets.

### Security Impact

Exposed secrets may enable further compromise of databases, APIs, or other services.

This threat is part of **AP-01**.

### Recommended Controls

* Secret-specific IAM permissions
* KMS encryption
* Secret rotation
* Access monitoring
* Separation of secrets by workload
* Prevent secrets from being written to logs

---

## I06 — Sensitive Information in Logs

**Data Flow:** DF09 — ECS → CloudWatch
**STRIDE Category:** Information Disclosure
**Primary Asset:** Logs / sensitive data
**Risk:** 9/25 — Medium
**Priority:** P3

### Threat

Application logs may unintentionally contain sensitive information such as:

* Authentication headers
* Session tokens
* API keys
* Customer PII
* Database errors
* Application secrets

### Recommended Controls

* Structured logging
* Sensitive-field redaction
* Log sanitization
* Least-privilege log access
* Appropriate retention policies
* Detection for sensitive data appearing in logs

---

## R01 — Insufficient Auditability

**Data Flow:** DF10 — AWS Services → CloudTrail
**STRIDE Category:** Repudiation
**Primary Asset:** Audit logs
**Risk:** 12/25 — High
**Priority:** P2

### Threat

Insufficient AWS API logging or poorly protected audit records may prevent reliable investigation of malicious activity.

### Security Impact

Security analysts may be unable to establish:

* Which identity performed an action
* Which AWS API was invoked
* When an action occurred
* Which resource was affected
* Whether activity was expected

### Recommended Controls

* Enable appropriate CloudTrail coverage
* Centralize security logs
* Protect log storage from modification
* Configure appropriate retention
* Alert on security-sensitive API activity
* Integrate relevant findings with Security Hub and GuardDuty

---

# Prioritization Summary

## P1 — Immediate Remediation

* E02 — Excessive IAM permissions
* E01 — Application compromise
* I02 — Unauthorized database access
* I04 — Public S3 exposure
* I05 — Secrets disclosure

## P2 — Near-Term Remediation

* S01 — Customer account compromise
* T01 — Malicious request manipulation
* D01 — Application-layer denial of service
* I01 — Direct ALB exposure
* T03 — Database manipulation
* I03 — Unauthorized S3 access
* T04 — S3 object manipulation
* R01 — Insufficient auditability

## P3 — Security Hardening

* T02 — WAF evasion
* I06 — Sensitive information in logs

---

# Key Observation

The findings demonstrate that CloudCart's risk is not driven solely by individual vulnerabilities.

The primary systemic risk is the interaction between:

**Internet-facing application compromise → ECS workload compromise → workload identity abuse → excessive IAM permissions → sensitive AWS resource access**

This compound risk is documented as **AP-01** in `attack-paths.md`.

The remediation strategy should therefore prioritize controls that break this attack path at multiple stages and reduce the blast radius of any single compromised component.
