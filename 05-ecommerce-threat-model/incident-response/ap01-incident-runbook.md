# CloudCart AP-01 Incident Investigation Runbook

## 1. Purpose

This runbook defines the investigation and response process for suspected compromise of the CloudCart ECS application followed by abuse of its AWS workload identity.

The runbook corresponds to attack path **AP-01**:

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
   ├── Secrets Manager
   ├── S3
   └── RDS
```

The runbook is intended for Cloud Security and SOC analysts responsible for triage, investigation, containment, eradication, and recovery.

---

# 2. Incident Scenario

A CloudCart security analyst receives a high-severity alert indicating unusual AWS API activity associated with the ECS application workload role.

The activity occurs shortly after suspicious requests are observed against the public CloudCart application.

Additional telemetry may indicate:

* Suspicious WAF activity
* Application errors
* Abnormal ECS runtime behavior
* Unexpected AWS API calls
* Secrets Manager access
* Unusual S3 access
* Database access

The analyst must determine whether the ECS workload has been compromised and whether the attacker has accessed additional AWS resources.

---

# 3. Initial Alert

Example alert:

```text
Alert ID: CC-IR-001
Severity: Critical
Detection: DET-04 — Unexpected Workload-Role API Activity

Principal:
CloudCart ECS Application Role

Observed behavior:
Unexpected access to sensitive AWS resources

Related telemetry:
Suspicious web requests observed shortly before AWS API activity
```

The alert represents an investigation starting point, not proof of compromise.

---

# 4. Incident Severity

Initial classification:

**Severity: Critical**

Rationale:

* Internet-facing workload may be compromised
* AWS workload identity may be abused
* Sensitive resources are potentially accessible
* Customer data may be at risk
* The event matches the primary AP-01 attack path

Severity may be adjusted as additional evidence becomes available.

---

# 5. Investigation Objectives

The investigation must answer:

1. Was the CloudCart application compromised?
2. Which ECS task or container was affected?
3. Which IAM workload identity was used?
4. What AWS API operations were performed?
5. Which resources were accessed?
6. Were application secrets retrieved?
7. Were S3 objects accessed or modified?
8. Was the RDS database accessed?
9. Were IAM permissions or security controls modified?
10. Is the attacker still active?
11. What data may have been exposed or altered?
12. What containment actions are required?

---

# 6. Phase 1 — Triage

## Objective

Determine whether the alert represents expected workload behavior, a false positive, or potentially malicious activity.

## Step 1 — Validate the Alert

Record:

* Alert timestamp
* Detection source
* Severity
* AWS account
* AWS Region
* Resource identifiers
* IAM role
* ECS cluster
* ECS service
* ECS task
* Relevant IP/network information
* API operation
* Target resource

Do not immediately assume the event is malicious.

---

## Step 2 — Identify the Workload Identity

Determine the AWS identity responsible for the suspicious API activity.

Establish:

```text
ECS Task
   ↓
Task Role
   ↓
Temporary Role Session
   ↓
AWS API Event
```

Validate that the role session is associated with the CloudCart workload.

Review:

* Role ARN
* Session identity
* ECS task
* Cluster
* Service
* Account
* Region

---

## Step 3 — Determine Whether the API Call Was Expected

Compare the observed operation with the approved workload baseline.

Example expected behavior:

```text
s3:GetObject
secretsmanager:GetSecretValue
```

Only against approved CloudCart resources.

Potentially suspicious behavior includes:

```text
Access to unrelated S3 buckets
Access to unrelated secrets
IAM administration
Unexpected role assumption
Security-control modification
Large-scale enumeration
Unusual write/delete activity
```

The determination must consider both:

```text
Action
+
Resource
```

A normally legitimate API operation can still be suspicious when performed against an unexpected resource.

---

# 7. Phase 2 — Build the Incident Timeline

## Objective

Reconstruct activity before and after the suspicious AWS API event.

Start with the alert time:

```text
T0 = Initial suspicious AWS API activity
```

Investigate backward and forward from T0.

Example timeline:

```text
T-15m  Repeated suspicious requests observed by WAF
T-12m  Application produces unusual server errors
T-10m  Unexpected workload runtime activity begins
T0     ECS workload identity makes unusual AWS API call
T+2m   Secrets Manager accessed
T+4m   Sensitive S3 objects accessed
T+8m   Additional AWS resource enumeration occurs
```

Exact timestamps should come from the available telemetry.

---

# 8. Phase 3 — Investigate Initial Access

## AWS WAF

Review WAF telemetry preceding the suspected compromise.

Investigate:

* Source
* URI
* Request method
* Rule matches
* Request frequency
* Repeated request patterns
* Whether traffic was allowed or blocked

Questions:

* Was there a spike in suspicious requests?
* Did requests target a specific application endpoint?
* Did successful requests occur after multiple blocked attempts?
* Were multiple sources involved?

---

## Application Logs

Review application telemetry for the same period.

Look for:

* Unexpected exceptions
* Authorization failures
* Input validation failures
* Unusual outbound-request errors
* Internal service access attempts
* Abnormal application endpoints
* Unexpected application behavior

Correlate application events with WAF activity.

---

# 9. Phase 4 — Investigate ECS Workload Compromise

Determine which ECS task was active during the suspicious period.

Collect:

* Cluster identifier
* Service identifier
* Task identifier
* Task definition revision
* Container image
* Image digest if available
* Task role
* Execution role
* Deployment time
* Relevant logs
* Runtime security findings

If GuardDuty Runtime Monitoring is deployed, review relevant runtime findings and activity.

Investigate:

* Unexpected processes
* Unexpected child processes
* Abnormal file activity
* Unexpected outbound connections
* Runtime behavior inconsistent with the application

Do not modify or terminate the suspected workload until required evidence has been identified and containment implications have been considered.

---

# 10. Phase 5 — Investigate IAM Activity

## Objective

Determine how the workload identity was used after suspected compromise.

Review AWS API activity associated with:

* The ECS task role
* Relevant role sessions
* Resources accessed by that identity

Build an API timeline.

Example:

```text
Time      Event                     Resource
-------------------------------------------------------------
10:01     GetSecretValue            cloudcart/db-password
10:03     ListBucket                cloudcart-data
10:04     GetObject                 customer-export
10:07     AssumeRole                unexpected-role
```

The example is illustrative. Actual investigation should rely on observed telemetry.

---

## High-Risk IAM Activity

Escalate immediately if evidence indicates:

* IAM policy creation or modification
* Role trust-policy changes
* New roles
* New access credentials
* Permission changes
* Unexpected role assumption
* Security-control modification

These events may indicate expansion beyond the original workload permissions.

---

# 11. Phase 6 — Investigate Secrets Manager

Determine whether secrets were accessed.

For each event record:

* Principal
* Secret
* Timestamp
* Expected or unexpected access
* Associated workload
* Subsequent activity

Questions:

* Was the secret required by the application?
* Was access frequency unusual?
* Were unrelated secrets requested?
* Could the retrieved credential be used outside the ECS workload?
* Was the secret used after retrieval?

Any potentially exposed secret should be considered for rotation during containment.

---

# 12. Phase 7 — Investigate S3

Review object-level telemetry where appropriate data-event logging is available.

Determine:

* Bucket
* Object or prefix
* Principal
* Operation
* Timestamp
* Request volume
* Write/delete activity

Look for:

* Unexpected object reads
* Bulk retrieval
* Enumeration
* Unexpected writes
* Deletes
* Access outside normal prefixes
* Access to customer information

Differentiate between:

```text
Control-plane configuration activity
```

and:

```text
Object-level data activity
```

Ensure the correct telemetry source is used for each.

---

# 13. Phase 8 — Investigate RDS

Determine whether database access occurred during the incident window.

Review available:

* Database audit logs
* Authentication events
* Application database logs
* Network telemetry
* Relevant application activity

Look for:

* Unexpected authentication
* Unusual query patterns
* Bulk reads
* Data modification
* Account or privilege changes
* Abnormal connection behavior

Establish whether customer or order data may have been exposed or altered.

---

# 14. Phase 9 — Determine Scope

Create a scope table.

| Resource     | Evidence                    | Compromised?          | Action          |
| ------------ | --------------------------- | --------------------- | --------------- |
| ECS task     | Suspicious runtime activity | Suspected             | Isolate/replace |
| ECS IAM role | Unexpected API activity     | Abused                | Restrict        |
| Secret A     | Unexpected retrieval        | Potentially exposed   | Rotate          |
| S3 bucket    | Unexpected object reads     | Potential data access | Investigate     |
| RDS          | No abnormal evidence        | Unknown / monitor     | Continue review |

Update the table as new evidence becomes available.

---

# 15. Indicators of Broader Compromise

Expand the investigation if any of the following are observed:

* Multiple IAM principals involved
* Unexpected role assumptions
* IAM modifications
* New credentials
* Security-control changes
* Activity across multiple Regions
* Activity against unrelated workloads
* Access to unrelated secrets
* Access to unrelated S3 buckets
* Persistent activity after ECS task replacement

These indicators suggest that the incident may extend beyond a single workload.

---

# 16. Phase 10 — Containment

Containment should prioritize stopping attacker activity while preserving sufficient evidence for investigation.

## ECS Workload

Potential actions:

* Remove affected task from service
* Replace affected tasks with known-good deployments
* Restrict outbound connectivity where appropriate
* Block malicious sources where justified
* Prevent redeployment of vulnerable images

---

## IAM

Potential actions:

* Immediately reduce excessive workload permissions
* Remove unauthorized policies
* Remove unauthorized trust relationships
* Disable or revoke newly created credentials
* Restrict affected roles

Avoid blindly deleting IAM identities before understanding dependencies and evidence requirements.

---

## Secrets

For secrets potentially exposed:

* Rotate affected credentials
* Update dependent applications
* Invalidate previous credentials where supported
* Monitor use of superseded credentials

---

## S3

If unauthorized access is occurring:

* Correct bucket policies
* Reinforce Block Public Access
* Remove unauthorized permissions
* Preserve relevant object-access evidence
* Assess affected data

---

## RDS

If database credentials may be compromised:

* Rotate credentials
* Terminate unauthorized sessions where appropriate
* Review database permissions
* Restrict network access
* Preserve database audit evidence

---

# 17. Phase 11 — Eradication

After containment, remove the underlying cause.

Potential eradication tasks include:

* Patch the application vulnerability
* Rebuild affected container images
* Redeploy ECS tasks
* Remove vulnerable dependencies
* Correct IAM policies
* Remove unauthorized access
* Fix S3 configuration
* Correct database permissions
* Rotate secrets
* Correct network controls
* Update WAF rules where applicable

Do not return the environment to normal operation until the initial attack vector has been addressed.

---

# 18. Phase 12 — Recovery

Recovery should restore normal CloudCart operations using trusted components.

Validate:

* Clean container image deployed
* Vulnerability remediated
* IAM permissions reduced
* Required secrets rotated
* RDS access controlled
* S3 access controlled
* Logging functioning
* GuardDuty functioning
* Security Hub receiving relevant findings
* WAF functioning
* CloudWatch telemetry functioning

Increase monitoring during the recovery period.

---

# 19. Recovery Validation

Before incident closure, confirm that the AP-01 attack path has been disrupted.

```text
Application exploit
        ↓
       FIXED
        X

Compromised ECS workload
        ↓
Least-privilege IAM
        X

Workload identity
        ↓
Restricted secrets / S3 / RDS access
        X
```

Multiple independent controls should prevent recurrence.

---

# 20. Evidence Preservation

Preserve relevant evidence before routine logs or ephemeral resources disappear.

Evidence may include:

* WAF logs
* Application logs
* CloudWatch logs
* CloudTrail events
* GuardDuty findings
* Security Hub findings
* ECS task metadata
* Task definitions
* Container image identifiers/digests
* IAM policies
* Bucket policies
* Relevant S3 data events
* Database audit logs
* Relevant configuration snapshots

Record timestamps consistently, preferably using UTC during the investigation.

---

# 21. Incident Documentation

Maintain an investigation record containing:

| Field              | Value |
| ------------------ | ----- |
| Incident ID        |       |
| Detection time     |       |
| Analyst            |       |
| Severity           |       |
| AWS account        |       |
| Region             |       |
| ECS cluster        |       |
| ECS task           |       |
| IAM role           |       |
| Initial indicator  |       |
| Affected resources |       |
| Data affected      |       |
| Containment time   |       |
| Root cause         |       |
| Recovery time      |       |
| Final status       |       |

Every significant analyst action should be timestamped.

---

# 22. Example Incident Timeline

Example final timeline:

```text
09:40 UTC
WAF records repeated suspicious requests.

09:44 UTC
Application logs record unusual internal request behavior.

09:47 UTC
Runtime security telemetry identifies anomalous ECS activity.

09:49 UTC
CloudTrail records unexpected API activity from the ECS task role.

09:51 UTC
Application secret is retrieved.

09:54 UTC
Unexpected S3 object access occurs.

10:02 UTC
SOC escalates incident to Critical.

10:08 UTC
Affected ECS workload isolated.

10:12 UTC
IAM workload permissions restricted.

10:18 UTC
Potentially exposed secret rotated.

10:30 UTC
Clean ECS deployment initiated.

11:10 UTC
Environment validated and enhanced monitoring begins.
```

This timeline is illustrative and should not be represented as actual CloudCart telemetry.

---

# 23. Root-Cause Analysis

The post-incident analysis should distinguish between the:

### Initial Cause

Example:

```text
Application vulnerability enabled workload compromise.
```

### Security Control Failure

Example:

```text
Application security controls failed to prevent exploitation.
```

### Impact Amplifier

Example:

```text
Excessive ECS IAM permissions increased the blast radius.
```

### Detection Gap

Example:

```text
Object-level S3 telemetry was not enabled for the affected bucket.
```

This distinction prevents the organization from treating the incident as a single-control failure.

---

# 24. Lessons Learned

After recovery, conduct a review covering:

* What allowed initial access?
* Which controls failed?
* Which controls worked?
* How quickly was the activity detected?
* Was sufficient evidence available?
* Were IAM permissions broader than necessary?
* Were secrets adequately segmented?
* Did logging provide sufficient coverage?
* Were alerts actionable?
* Were containment procedures effective?

Create remediation actions for identified gaps.

---

# 25. Detection Feedback Loop

Incident findings should improve the detection program.

```text
Incident
   ↓
Investigation
   ↓
New attacker behavior identified
   ↓
Detection created or improved
   ↓
Control validated
   ↓
Future detection improves
```

For example, if the investigation identifies an AWS API operation that the CloudCart ECS workload should never perform, add that behavior to **DET-04**.

---

# 26. Incident Closure Criteria

The AP-01 incident can be closed when:

1. The initial attack vector is understood.
2. Affected resources have been identified.
3. Attacker access has been contained.
4. Compromised workloads have been replaced.
5. Relevant credentials and secrets have been rotated.
6. Unauthorized IAM changes have been removed.
7. Data exposure has been assessed.
8. Required security controls have been restored.
9. Detection coverage has been validated.
10. Root cause and lessons learned have been documented.
11. Follow-up remediation actions have owners and deadlines.

---

# 27. Analyst Decision Model

The analyst should continuously evaluate:

```text
What happened?
      ↓
Which identity performed it?
      ↓
Which resource was affected?
      ↓
Is the behavior expected?
      ↓
What happened immediately before it?
      ↓
What happened immediately after it?
      ↓
How far did the attacker progress through AP-01?
```

The objective is not simply to investigate individual alerts.

The objective is to reconstruct the attack chain and determine the full scope and business impact of the incident.
