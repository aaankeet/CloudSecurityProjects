# -------------------------------------------------------
# Console Login Passwords
# Retrieve with: terraform output -raw auditor1_password
# -------------------------------------------------------

output "security_auditor1_password" {
  description = "Initial console password for SecurityAuditor1 (reset required on first login)"
  value       = aws_iam_user_login_profile.security_auditor1_login.password
  sensitive   = true
}

output "incident_responder1_password" {
  description = "Initial console password for IncidentResponder1 (reset required on first login)"
  value       = aws_iam_user_login_profile.incident_responder1_login.password
  sensitive   = true
}

# -------------------------------------------------------
# CLI Access Keys
# Retrieve secret with: terraform output -raw auditor1_secret_access_key
# -------------------------------------------------------

output "security_auditor1_access_key_id" {
  description = "Access key ID for SecurityAuditor1"
  value       = aws_iam_access_key.security_auditor1_key.id
}

output "security_auditor1_secret_access_key" {
  description = "Secret access key for SecurityAuditor1"
  value       = aws_iam_access_key.security_auditor1_key.secret
  sensitive   = true
}

output "incident_responder1_access_key_id" {
  description = "Access key ID for IncidentResponder1"
  value       = aws_iam_access_key.incident_responder1_key.id
}

output "incident_responder1_secret_access_key" {
  description = "Secret access key for IncidentResponder1"
  value       = aws_iam_access_key.incident_responder1_key.secret
  sensitive   = true
}
