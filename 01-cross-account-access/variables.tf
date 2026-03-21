variable "region" {
  default = "us-east-1"
}
variable "security_account_id" {
  description = "Security Account ID"
  type        = string
}
variable "workload_account_id" {
  description = "Workload Account ID"
  type        = string
}
# SECURITY ACCOUNT VARIABLES
variable "security_auditor" {
  description = "Name of the Security Auditor Role in the Security Account"
  default     = "SecurityAuditorRole"
  type        = string
}
variable "incident_responder" {
  description = "Name of the Incident Responder Role in the Security Account"
  default     = "IncidentResponderRole"
}
variable "security_auditor_user" {
  description = "IAM username for the Security Auditor in the Security Account"
  default     = "SecurityAuditor1"
  type        = string
}
variable "incident_responder_user" {
  description = "IAM username for the Incident Responder in the Security Account"
  default     = "IncidentResponder1"
  type        = string
}

# Workload Account Variables
variable "security_audit_role" {
  default = "SecurityAuditRole"
  type    = string
}
variable "incident_response_role" {
  default = "IncidentResponseRole"
  type    = string
}

# ExternalId values for cross-account role assumption (treat as secrets)
variable "audit_external_id" {
  type      = string
  sensitive = true
}
variable "incident_external_id" {
  type      = string
  sensitive = true
}
