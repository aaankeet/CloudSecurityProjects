# Create CloudWatch Logs Group
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/vpc/flow-logs"
  retention_in_days = 30
  # kms_key_id = ******** (CAN USE KMS TO ENCRYPT LOG DATA)
  tags = {
    Name = "vpc-flow-logs"
  }
}

/* Create IAM Role for Flow Logs */
/* Flow logs needs permission to write to CloudWatch */
resource "aws_iam_role" "flow_logs_role" {
  name = "vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
    }]
  })
}

/* ATTACH POLICY */
resource "aws_iam_role_policy" "flow_role_policy" {
  name = "vpc-flow-logs-policy"
  role = aws_iam_role.flow_logs_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Resource = [
        "${aws_cloudwatch_log_group.vpc_flow_logs.arn}",
        "${aws_cloudwatch_log_group.vpc_flow_logs.arn}:*"
      ]
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    }]
  })
}

/* Enable VPC Flow Logs */
resource "aws_flow_log" "vpc_flow" {
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs.arn
  log_destination_type = "cloud-watch-logs"
  iam_role_arn         = aws_iam_role.flow_logs_role.arn
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.this.id

  log_format = "$${version} $${account-id} $${vpc-id} $${subnet-id} $${instance-id} $${interface-id} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${action} $${log-status}"
}
