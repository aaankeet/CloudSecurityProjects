# CloudCart STRIDE Threat Analysis

## Methodology

The CloudCart threat model uses the STRIDE methodology to identify
security threats affecting application processes, data stores,
external entities, and data flows.

Threats are analyzed in the context of:

- Spoofing
- Tampering
- Repudiation
- Information Disclosure
- Denial of Service
- Elevation of Privilege

Cloud-specific risks involving IAM, workload identities, AWS APIs,
storage, secrets, and cloud logging are also considered.

Risk is evaluated using:

Risk Score = Likelihood × Impact

Both likelihood and impact use a 1–5 scale.


| ID  | Data Flow | STRIDE         | Threat                         | Risk        |
| --- | --------- | -------------- | ------------------------------ | ----------- |
| S01 | DF01      | Spoofing       | Customer account compromise    | Critical    |
| T01 | DF01      | Tampering      | Malicious request manipulation | High        |
| D01 | DF01      | DoS            | Application-layer DoS          | High        |
| T02 | DF02      | Tampering/DoS  | WAF evasion                    | Medium      |
| I01 | DF03      | Info/DoS       | Direct ALB exposure            | High        |
| E01 | DF04      | Elevation      | Application compromise         | High        |
| E02 | DF05      | Elevation      | Excessive IAM permissions      | Critical    |
| I02 | DF06      | Information    | Unauthorized DB access         | Critical    |
| T03 | DF06      | Tampering      | Database manipulation          | Critical    |
| I03 | DF07      | Information    | Unauthorized S3 access         | High        |
| T04 | DF07      | Tampering      | S3 object manipulation         | High        |
| I04 | DF07      | Information    | Public S3 exposure             | Critical    |
| I05 | DF08      | Info/Elevation | Secrets disclosure             | Critical    |
| I06 | DF09      | Information    | Sensitive data in logs         | Medium–High |
| R01 | DF10      | Repudiation    | Insufficient auditability      | High        |
