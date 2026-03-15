# Create S3 ENDPOINT (GATEWAY ENDPOINT)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = concat(
    aws_route_table.private_rt[*].id,
    [aws_route_table.data_rt.id]
  )
  tags = {
    Name = "s3-gateway-endpoint"
  }
}

# Create CLOUDWATCH ENDPOINT (INTERFACE ENDPOINT)
resource "aws_vpc_endpoint" "cloudwatch_logs" {
  vpc_id       = aws_vpc.this.id
  service_name = "com.amazonaws.${var.aws_region}.logs"

  vpc_endpoint_type = "Interface"

  subnet_ids = aws_subnet.private[*].id
  security_group_ids = [
    aws_security_group.endpoint.id
  ]

  private_dns_enabled = true

  tags = {
    Name = "cloudwatch-logs-endpoint"
  }

}
