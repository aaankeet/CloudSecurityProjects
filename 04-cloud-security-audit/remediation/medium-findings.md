# Medium Severity Findings

---

┌─────────────────────────────────────────────────────────────────────────────────┐
│                    FINDING ANALYSIS TEMPLATE                                    │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  FINDING: Missing CloudWatch Security Monitoring and Alerting                   │
│  ═════════════════════════════════════════════════════════════                  │
│                                                                                 │
│  ┌────────────────────────────────────────────────────────────────────────┐    │
│  │  Raw Finding Details:                                                  │    │
│  │  • Service: CloudWatch / CloudTrail                                    │    │
│  │  • Severity: Medium                                                    │    │
│  │  • Region: us-east-1                                                   │    │
│  │  • Log Groups: Not Configured                                          │    │
│  │                                                                        │    │
│  │  Missing Metric Filters & Alarms:                                      │    │
│  │  • KMS CMK Disablement / Scheduled Deletion                            │    │
│  │  • Authentication Failures                                             │    │
│  │  • Root Account Usage                                                  │    │
│  │  • VPC Route Table Changes                                             │    │
│  │  • VPC Changes                                                         │    │
│  │  • Console Sign-in Without MFA                                         │    │
│  │  • Network ACL Changes                                                 │    │
│  │  • S3 Bucket Policy Changes                                            │    │
│  │  • AWS Config Configuration Changes                                    │    │
│  └────────────────────────────────────────────────────────────────────────┘    │
│                                                                                 │
│  ┌────────────────────────────────────────────────────────────────────────┐    │
│  │  Context Questions:                                                    │    │
│  │  • Is CloudTrail enabled?                        PARTIAL               │    │
│  │  • Are CloudWatch alarms configured?            NO                    │    │
│  │  • Is centralized monitoring implemented?       NO                    │    │
│  │  • Are sensitive AWS changes monitored?         NO                    │    │
│  │  • Is incident detection automated?             NO                    │    │
│  └────────────────────────────────────────────────────────────────────────┘    │
│                                                                                 │
│  ┌────────────────────────────────────────────────────────────────────────┐    │
│  │  Risk Assessment:                                                      │    │
│  │  • Exploitability: MEDIUM                                              │    │
│  │  • Impact: MEDIUM                                                      │    │
│  │  • Overall: MEDIUM                                                     │    │
│  │                                                                        │    │
│  │  Lack of monitoring and alerting reduces visibility into               │    │
│  │  suspicious activity, unauthorized changes, and potential              │    │
│  │  account compromise.                                                   │    │
│  └────────────────────────────────────────────────────────────────────────┘    │
│                                                                                 │
│  ┌────────────────────────────────────────────────────────────────────────┐    │
│  │  Remediation Plan:                                                     │    │
│  │  1. Enable AWS CloudTrail across all regions                           │    │
│  │  2. Configure centralized CloudWatch Log Groups                        │    │
│  │  3. Create metric filters for security-relevant events                 │    │
│  │  4. Configure SNS notifications for CloudWatch alarms                  │    │
│  │  5. Monitor IAM, networking, S3, and root account activity            │    │
│  │  6. Integrate logging with AWS Security Hub or SIEM solutions          │    │
│  └────────────────────────────────────────────────────────────────────────┘    │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘

---

# Affected Checks

| Check ID | Description |
|---|---|
| cloudwatch_log_metric_filter_disable_or_scheduled_deletion_of_kms_cmk | Missing alerts for KMS CMK disablement or deletion |
| cloudwatch_log_metric_filter_authentication_failures | Missing alerts for authentication failures |
| cloudwatch_log_metric_filter_root_usage | Missing monitoring for root account activity |
| cloudwatch_changes_to_network_route_tables_alarm_configured | Missing route table change monitoring |
| cloudwatch_changes_to_vpcs_alarm_configured | Missing VPC change monitoring |
| cloudwatch_log_metric_filter_sign_in_without_mfa | Missing alerts for console sign-ins without MFA |
| cloudwatch_changes_to_network_acls_alarm_configured | Missing NACL change monitoring |
| cloudwatch_log_metric_filter_for_s3_bucket_policy_changes | Missing alerts for S3 bucket policy changes |
| cloudwatch_log_metric_filter_and_alarm_for_aws_config_configuration_changes_enabled | Missing monitoring for AWS Config changes |

---

# Security Impact Summary

The AWS account currently lacks centralized monitoring and automated alerting for several critical security events. This reduces visibility into unauthorized access attempts, infrastructure modifications, and sensitive configuration changes.

While these findings do not directly expose resources, they significantly weaken the organization’s detection and incident response capabilities.
