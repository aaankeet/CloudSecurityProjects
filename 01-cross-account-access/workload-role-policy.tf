# Attach Permission to Security Audit Role - ViewOnlyAccess
resource "aws_iam_role_policy_attachment" "viewonly" {
  provider   = aws.workload
  role       = aws_iam_role.security_audit_role.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Create a custom policy allowing limited remediation actions.
resource "aws_iam_policy" "incident_response_policy" {
  provider = aws.workload
  name     = "IncidentResponsePolicy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [

      {
        Sid    = "EC2ReadOnly"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeVolumes",
          "ec2:DescribeImages",
          "ec2:DescribeTags"
        ]
        Resource = "*"
      },
      # -----------------------------
      # 2. VPC Read-Only (via EC2 API)
      # -----------------------------
      {
        Sid    = "VPCReadOnly"
        Effect = "Allow"
        Action = [
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeNetworkInterfaces"
        ]
        Resource = "*"
      },
      # -----------------------------
      # 3. IAM Read-Only
      # -----------------------------
      {
        Sid    = "IAMReadOnly"
        Effect = "Allow"
        Action = [
          "iam:Get*",
          "iam:List*"
        ]
        Resource = "*"
      },
      # -----------------------------
      # 4. EC2 Limited Incident Actions
      # -----------------------------
      {
        Sid    = "EC2IncidentActions"
        Effect = "Allow"
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:RebootInstances"
        ]
        Resource = "arn:aws:ec2:${var.region}:${var.workload_account_id}:instance/*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/SecurityManaged" = "true"
          }
        }
      },
      # -----------------------------
      # 5. Isolation Actions (Network / IAM)
      # -----------------------------
      {
        Sid    = "IsolationActions"
        Effect = "Allow"
        Action = [
          "ec2:ModifyInstanceAttribute",
          "ec2:ModifyNetworkInterfaceAttribute",
          "ec2:AssociateIamInstanceProfile",
          "ec2:DisassociateIamInstanceProfile"
        ]
        Resource = "arn:aws:ec2:${var.region}:${var.workload_account_id}:instance/*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/SecurityManaged" = "true"
          }
        }
      }
    ]
  })
}

# Attach Permission to Incident Response Role
resource "aws_iam_role_policy_attachment" "incident_response_attach" {
  provider   = aws.workload
  role       = aws_iam_role.incident_response_role.name
  policy_arn = aws_iam_policy.incident_response_policy.arn
}
