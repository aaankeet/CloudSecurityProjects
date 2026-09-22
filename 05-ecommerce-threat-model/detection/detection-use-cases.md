# CloudCart Detection Engineering & Monitoring

## 1. Purpose

This document defines security monitoring and detection use cases for the CloudCart AWS environment.

The detection strategy is designed to identify suspicious activity associated with the threat model, particularly attack path AP-01:

```text
Internet
   ↓
Application Exploitation
   ↓
ECS Workload Compromise
   ↓
Workload Identity Abuse
   ↓
AWS API Activity
   ↓
Sensitive Resource Access
   ├── S3
   ├── Secrets Manager
   └── RDS
```

Detection engineering complements preventive controls.

The objective is to identify attacker behavior early enough to investigate, contain, and prevent progression through the attack path.

---

# 2. Primary Telemetry Sources

| Source                       | Security Value                                                        |
| ---------------------------- | --------------------------------------------------------------------- |
| AWS WAF logs                 | Visibility into suspicious web requests and blocked traffic           |
| Application logs             | Authentication events, errors, security-relevant application activity |
| CloudWatch                   | Application, container, and operational telemetry                     |
| CloudTrail                   | AWS API and control-plane activity                                    |
| CloudTrail S3 data events    | Object-level activity for monitored S3 resources                      |
| GuardDuty                    | AWS-native threat detections                                          |
| GuardDuty Runtime Monitoring | Runtime visibility for supported ECS workloads                        |
| Security Hub                 | Consolidation and prioritization of security findings                 |
| RDS / database audit logs    | Database authentication and query/activity evidence                   |

AWS WAF logging can be sent to supported destinations including CloudWatch Logs, Amazon S3, and Firehose. Sensitive fields should be redacted where appropriate.

---

# 3. Detection Architecture

```text
                    Internet
                       │
                       ▼
                 CloudFront / WAF
                       │
                       ├──── WAF Logs
                       │
                       ▼
                      ALB
                       │
                       ▼
                  ECS Workload
                    │      │
           App Logs │      │ Runtime Events
                    ▼      ▼
              CloudWatch   GuardDuty
                    │          │
                    └────┬─────┘
                         │
                         ▼
                    Security Hub

AWS API Activity
      │
      ▼
  CloudTrail
      │
      ├── IAM activity
      ├── Secrets access
      ├── S3 activity*
      └── Security control changes

* Relevant S3 object operations require appropriate
  CloudTrail data-event configuration.
```

---

# 4. Detection Use-Case Summary

| ID     | Detection                             | AP-01 Stage              | Primary Source            | Severity |
| ------ | ------------------------------------- | ------------------------ | ------------------------- | -------- |
| DET-01 | Suspicious WAF activity               | Initial exploitation     | WAF                       | Medium   |
| DET-02 | Application exploitation indicators   | Application compromise   | App / CloudWatch          | High     |
| DET-03 | Suspicious ECS runtime behavior       | Workload compromise      | GuardDuty Runtime         | Critical |
| DET-04 | Unexpected workload-role API activity | Identity abuse           | CloudTrail                | Critical |
| DET-05 | Unusual Secrets Manager access        | Credential access        | CloudTrail                | Critical |
| DET-06 | Unusual S3 object access              | Collection / data access | CloudTrail data events    | High     |
| DET-07 | IAM privilege modification            | Privilege escalation     | CloudTrail                | Critical |
| DET-08 | Security logging disabled or modified | Defense evasion          | CloudTrail                | Critical |
| DET-09 | Public S3 configuration change        | Data exposure            | CloudTrail / Security Hub | Critical |
| DET-10 | Authentication abuse                  | Account compromise       | App / WAF                 | High     |

---

# 5. DET-01 — Suspicious WAF Activity

**Severity:** Medium
**Threat Mapping:** T01, T02, E01
**Attack Stage:** Initial exploitation
**Telemetry:** AWS WAF logs

## Detection Objective

Identify repeated or anomalous web requests that may indicate attempts to exploit the CloudCart application.

## Indicators

Potential signals include:

* Large numbers of blocked requests from one source
* Repeated access to unusual application paths
* High rates of malformed requests
* Repeated WAF rule matches
* Sudden increases in requests to sensitive API endpoints
* Abnormally high request rates

## Detection Logic

Conceptually:

```text
IF
    blocked_requests_from_source > baseline
OR
    repeated_high-risk_rule_matches
OR
    abnormal_request_rate
THEN
    generate investigation signal
```

## Analyst Investigation

Review:

1. Source address
2. Target URI
3. HTTP method
4. WAF rule triggered
5. Request frequency
6. Whether requests subsequently reached the application
7. Related application errors

## Response

* Investigate correlated application activity
* Apply temporary blocking or rate limiting where justified
* Tune WAF rules if a repeatable malicious pattern exists
* Escalate if application exploitation may have succeeded

---

# 6. DET-02 — Application Exploitation Indicators

**Severity:** High
**Threat Mapping:** E01
**Attack Stage:** Application compromise
**Telemetry:** Application logs / CloudWatch

## Detection Objective

Identify application behavior that may indicate exploitation or abnormal execution.

## Indicators

Examples include:

* Unexpected outbound connection errors
* Unusual requests to internal destinations
* Repeated authorization failures
* Unexpected application exceptions
* Sudden increases in server errors
* Suspicious input-validation failures
* Access to unusual endpoints
* Unexpected process or workload behavior

## Correlation

High-confidence investigation may require correlation between:

```text
WAF event
   +
Application error
   +
Unexpected outbound activity
```

A single error should not automatically be treated as compromise.

---

# 7. DET-03 — Suspicious ECS Runtime Behavior

**Severity:** Critical
**Threat Mapping:** E01, E02
**Attack Stage:** Workload compromise
**Telemetry:** GuardDuty Runtime Monitoring

## Detection Objective

Identify suspicious runtime activity inside the ECS environment after potential application compromise.

## Monitoring Focus

Relevant behaviors may include:

* Unexpected process execution
* Unexpected network connections
* Abnormal file activity
* Suspicious workload behavior
* Runtime activity inconsistent with the normal application profile

## Analyst Investigation

Determine:

* Which ECS task generated the finding?
* Which container was involved?
* What process or connection triggered the detection?
* Did suspicious web activity precede the event?
* Which IAM role was associated with the task?
* What AWS API activity followed?

## Response

Depending on confidence and impact:

* Isolate the affected workload
* Preserve relevant telemetry
* Replace or terminate compromised tasks
* Review workload identity activity
* Rotate exposed credentials or secrets where necessary
* Investigate downstream AWS API calls

---

# 8. DET-04 — Unexpected ECS Workload-Role API Activity

**Severity:** Critical
**Threat Mapping:** E02
**Attack Stage:** Workload identity abuse
**Telemetry:** CloudTrail

## Detection Objective

Identify AWS API activity performed by the CloudCart workload role that is inconsistent with normal workload behavior.

## Establish a Baseline

The legitimate ECS workload may normally require operations such as:

```text
s3:GetObject
secretsmanager:GetSecretValue
```

The exact baseline must be derived from application requirements.

Potentially suspicious behavior includes:

```text
iam:*
organizations:*
sts:AssumeRole
kms administrative operations
security-control changes
unexpected S3 buckets
unexpected Secrets Manager resources
```

## Detection Logic

Conceptually:

```text
IF
    principal = CloudCart ECS workload role
AND
    api_action NOT IN approved_workload_actions
THEN
    alert
```

A second detection layer should validate resource scope:

```text
IF
    workload_role accesses resource
    outside approved_resource_set
THEN
    alert
```

## Investigation

Review CloudTrail fields including:

* Event time
* Event source
* Event name
* Principal / role identity
* Source network information where applicable
* Resource
* Request parameters
* Response or error information

Then correlate with:

* ECS task activity
* GuardDuty findings
* WAF logs
* Application logs

---

# 9. DET-05 — Unusual Secrets Manager Access

**Severity:** Critical
**Threat Mapping:** I05
**Attack Stage:** Credential access
**Telemetry:** CloudTrail

## Detection Objective

Detect abnormal access to application secrets.

## Suspicious Patterns

* A workload retrieves a secret it does not normally use
* A workload suddenly retrieves many secrets
* Secret access occurs shortly after suspicious application activity
* Administrative secret operations occur from an application role
* Access patterns deviate significantly from the workload baseline

## Conceptual Logic

```text
IF
    principal = CloudCart workload role
AND
    requested_secret NOT IN approved_secret_list
THEN
    Critical Alert
```

## Investigation Questions

* Which role retrieved the secret?
* Which secret was accessed?
* Was access expected for that workload?
* Was the secret subsequently used?
* Did the same role access S3 or other sensitive resources?
* Was GuardDuty activity present around the same time?

---

# 10. DET-06 — Unusual S3 Object Access

**Severity:** High
**Threat Mapping:** I03, T04
**Attack Stage:** Collection / data access
**Telemetry:** CloudTrail S3 data events

## Detection Objective

Detect unauthorized or anomalous object-level access to sensitive S3 resources.

## Monitoring Focus

Potential signals include:

* Unusual bursts of object reads
* Access from an unexpected principal
* Access to an unexpected bucket or prefix
* Large-scale object enumeration or retrieval
* Unexpected write/delete activity
* Access outside expected workload behavior

## Important Logging Requirement

Object-level S3 activity should be explicitly included in the applicable CloudTrail data-event configuration.

Without the required data-event telemetry, object-level investigation may be incomplete.

## Investigation

Determine:

* Principal
* Bucket
* Object or prefix
* API operation
* Time
* Request volume
* Whether activity matches normal application behavior

---

# 11. DET-07 — IAM Privilege Modification

**Severity:** Critical
**Threat Mapping:** E02
**Attack Stage:** Privilege escalation
**Telemetry:** CloudTrail

## Detection Objective

Identify security-sensitive IAM changes that could increase attacker privileges.

## Monitor for Activities Such As

* Role policy attachment
* Inline policy modification
* Role creation
* Access policy changes
* Trust-policy modification
* Unexpected role assumption
* Permission-boundary changes

## Investigation

Determine:

* Who made the change?
* Which role or policy changed?
* What permissions were introduced?
* Was the change part of approved administration?
* Did suspicious API activity occur before or afterward?

Unexpected privilege modification should receive high investigation priority.

---

# 12. DET-08 — Security Logging Modification

**Severity:** Critical
**Threat Mapping:** R01
**Attack Stage:** Defense evasion
**Telemetry:** CloudTrail

## Detection Objective

Detect attempts to reduce security visibility.

## Monitor for Changes Affecting

* CloudTrail
* GuardDuty
* Security Hub
* WAF logging
* Security monitoring infrastructure

Potentially suspicious events include:

* Stopping or deleting logging configuration
* Modifying trails
* Disabling security services
* Altering monitoring destinations
* Removing logging permissions

## Analyst Response

Any unexpected reduction in telemetry should trigger investigation because attackers may attempt to suppress evidence after obtaining access.

---

# 13. DET-09 — Public S3 Configuration Change

**Severity:** Critical
**Threat Mapping:** I04
**Attack Stage:** Data exposure
**Telemetry:** CloudTrail / Security Hub

## Detection Objective

Identify configuration changes that could expose S3 resources publicly.

## Monitor

* Block Public Access changes
* Bucket-policy changes
* ACL changes
* Unexpected cross-account access
* Security Hub findings associated with S3 exposure

## Response

1. Determine whether public exposure is intended.
2. Identify affected data.
3. Restore secure configuration if unauthorized.
4. Review object-access telemetry.
5. Determine duration of potential exposure.
6. Escalate possible data exposure for further investigation.

---

# 14. DET-10 — Authentication Abuse

**Severity:** High
**Threat Mapping:** S01
**Attack Stage:** Account compromise
**Telemetry:** Application authentication logs / WAF

## Detection Objective

Identify attempts to compromise CloudCart customer accounts.

## Indicators

* High login failure rates
* Repeated failures across multiple accounts
* Many account attempts from one source
* Sudden authentication bursts
* Successful login following excessive failures
* Unusual account behavior after authentication

## Response

Possible actions include:

* Rate limiting
* Account protection mechanisms
* Session invalidation where appropriate
* User verification
* Investigation of affected accounts

---

# 15. AP-01 Detection Chain

The most important monitoring objective is not an isolated alert.

It is the correlation of multiple events.

Example:

```text
T0
WAF records suspicious request pattern
        ↓
T1
Application produces abnormal request/error telemetry
        ↓
T2
GuardDuty detects suspicious ECS runtime behavior
        ↓
T3
CloudTrail records unusual activity by ECS workload role
        ↓
T4
Secrets Manager access occurs
        ↓
T5
Unusual S3 data access occurs
```

This sequence provides substantially stronger evidence than any single signal.

---

# 16. Example Analyst Correlation Rule

A conceptual high-confidence use case:

```text
IF
    suspicious_application_activity = TRUE
AND
    principal = CloudCart ECS workload role
AND
    sensitive_AWS_API_activity = TRUE
WITHIN
    short investigation window

THEN
    Priority = Critical
    Investigate possible workload compromise
```

The time window should be tuned using observed application behavior rather than selected arbitrarily.

---

# 17. Security Hub Role

Security Hub provides a consolidated location for relevant security findings.

The CloudCart monitoring strategy uses Security Hub to centralize and prioritize findings produced by AWS security services and security checks.

Security Hub should complement, not replace, analysis of underlying telemetry.

Analysts may still need to review:

* CloudTrail records
* GuardDuty finding details
* WAF events
* Application logs
* CloudWatch telemetry
* Database audit evidence

---

# 18. Detection Validation

A detection should not be considered complete simply because a rule exists.

Each detection use case should be validated.

Validation questions include:

1. Is the required telemetry enabled?
2. Does the event contain sufficient investigation context?
3. Does the detection trigger during an authorized test?
4. Can analysts distinguish expected from suspicious behavior?
5. Does the alert contain the relevant principal and resource?
6. Is severity appropriate?
7. Is the response procedure clear?
8. Can the detection be correlated with other AP-01 stages?

---

# 19. Detection Coverage Matrix

| Threat                    | Preventive Control      | Detection              |
| ------------------------- | ----------------------- | ---------------------- |
| Account compromise        | Authentication controls | DET-10                 |
| Request manipulation      | Validation / WAF        | DET-01, DET-02         |
| Application compromise    | Secure SDLC / WAF       | DET-01, DET-02, DET-03 |
| Excessive IAM permissions | Least privilege         | DET-04, DET-07         |
| Unauthorized DB access    | SG / DB permissions     | DB audit monitoring    |
| S3 unauthorized access    | IAM / bucket policies   | DET-06                 |
| Public S3 exposure        | Block Public Access     | DET-09                 |
| Secrets disclosure        | Secret-specific IAM     | DET-05                 |
| Sensitive logging         | Redaction               | Log review / scanning  |
| Insufficient auditability | CloudTrail              | DET-08                 |

---

# 20. Key Detection Engineering Principle

CloudCart should monitor **identity behavior**, not only network traffic.

In a cloud environment, an attacker who compromises a workload may begin interacting with AWS resources using an otherwise valid workload identity.

The individual API request may therefore be authenticated successfully while still being malicious.

High-value detection should evaluate:

```text
Who performed the action?
+
What action was performed?
+
Which resource was accessed?
+
Is that behavior normal for this workload?
+
What activity occurred immediately before and after?
```

This identity-centric monitoring approach is especially important for detecting AP-01.

---

# 21. Detection Success Criteria

The monitoring strategy is successful when:

1. Suspicious web activity is observable.
2. Application exploitation indicators can be investigated.
3. ECS runtime compromise can generate actionable telemetry.
4. AWS API activity can be attributed to workload identities.
5. Unexpected workload-role actions are detectable.
6. Sensitive secret access is auditable.
7. Object-level access to sensitive S3 resources is observable where configured.
8. IAM privilege changes trigger investigation.
9. Security logging changes are detectable.
10. Analysts can correlate multiple stages of AP-01 into a single investigation timeline.
