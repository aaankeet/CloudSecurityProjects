# Create Security Audit Role
resource "aws_iam_role" "security_audit_role" {
  provider = aws.workload
  name     = var.security_audit_role

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          # Only Users with SecurityAuditorRole in security account can assume this role.
          AWS = "arn:aws:iam::${var.security_account_id}:role/${var.security_auditor}"
        }
        # ExternalId added as defense-in-depth against confused deputy attacks.
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.audit_external_id
          }
        }
      }
    ]
  })
}

# Create Incident Response Role
resource "aws_iam_role" "incident_response_role" {
  provider = aws.workload
  name     = var.incident_response_role

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          # Only Users with IncidentResponderRole in security account can assume this role.
          # # NOTE: The caller must have authenticated with MFA *before* assuming IncidentResponderRole
          # in the security account. That MFA context is forwarded here, satisfying the condition below.
          AWS = "arn:aws:iam::${var.security_account_id}:role/${var.incident_responder}"
        }
        Condition = {
          Bool = {
            "aws:MultiFactorAuthPresent" = "true"
          },
          # ExternalId added as defense-in-depth against confused deputy attacks.
          StringEquals = {
            "sts:ExternalId" = var.incident_external_id
          }

        }
      }
    ]
  })
}
