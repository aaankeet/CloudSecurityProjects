# Create SecurityAuditor1 IAM user
resource "aws_iam_user" "security_auditor_iam_user" {
  provider = aws.security
  name     = var.security_auditor_user
}
resource "aws_iam_user" "incident_responder_iam_user" {
  provider = aws.security
  name     = var.incident_responder_user
}
# Create a login profile for each user
resource "aws_iam_user_login_profile" "security_auditor1_login" {
  provider                = aws.security
  user                    = aws_iam_user.security_auditor_iam_user.name
  password_reset_required = false
}
resource "aws_iam_user_login_profile" "incident_responder1_login" {
  provider                = aws.security
  user                    = aws_iam_user.incident_responder_iam_user.name
  password_reset_required = false
}
# CLI Access Keys
resource "aws_iam_access_key" "security_auditor1_key" {
  provider = aws.security
  user     = aws_iam_user.security_auditor_iam_user.name
}

resource "aws_iam_access_key" "incident_responder1_key" {
  provider = aws.security
  user     = aws_iam_user.incident_responder_iam_user.name
}

# -------------------------------------------------------
# Permission policies allowing each user to assume their
# corresponding role in the Security Account.
#--------------------------------------------------------
resource "aws_iam_user_policy" "auditor1_assume_policy" {
  provider = aws.security
  user     = aws_iam_user.security_auditor_iam_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sts:AssumeRole"
      Resource = "arn:aws:iam::${var.security_account_id}:role/${var.security_auditor}"
    }]
  })
}

# Allow IncidentResponder1 (USER) to assume IncidentResponderRole in SECURITY ACCOUNT.
resource "aws_iam_user_policy" "incident_responder1_assume_policy" {
  provider = aws.security
  name     = "AllowAssumeIncidentResponderRole"
  user     = aws_iam_user.incident_responder_iam_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sts:AssumeRole"
      Resource = "arn:aws:iam::${var.security_account_id}:role/${var.incident_responder}"
    }]
  })
}
# Create Security Auditor Role in Security Account
resource "aws_iam_role" "security_auditor_role" {
  provider = aws.security
  name     = var.security_auditor

  # Allows Role Assumption for SecurityAuditor1 in Security Account
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          AWS = "arn:aws:iam::${var.security_account_id}:user/${var.security_auditor_user}"
        }
      }
    ]
  })
}
# Attach policy to Security Auditor role, Allowing role assumption in workload account
resource "aws_iam_role_policy" "auditor_assume_policy" {
  provider = aws.security
  role     = aws_iam_role.security_auditor_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow",
        Action   = "sts:AssumeRole"
        Resource = "arn:aws:iam::${var.workload_account_id}:role/${var.security_audit_role}"
      }
    ]
  })
}

# Create Incident Responder Role in Security Account
resource "aws_iam_role" "incident_responder_role" {
  provider = aws.security
  name     = var.incident_responder

  # Allows Role Assumption for IncidentResponder1 in Security Account
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Principal = {
          AWS = "arn:aws:iam::${var.security_account_id}:user/${var.incident_responder_user}"
        }
        Condition = {
          Bool = {
            "aws:MultiFactorAuthPresent" = "true"   # ← MFA enforced
          }
        }
      }
    ]
  })
}

# Attach policy to Incident Responder role, Allowing role assumption in workload account
resource "aws_iam_role_policy" "incident_assume_policy" {
  provider = aws.security
  role     = aws_iam_role.incident_responder_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Resource = "arn:aws:iam::${var.workload_account_id}:role/${var.incident_response_role}"
      }
    ]
  })
}
