# Create Public NACL
resource "aws_network_acl" "public" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "public-nacl"
  }
}

# Public NACL Inbound Rule (HTTPS/443)
resource "aws_network_acl_rule" "public_in_https" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

# Public Inbound to Ephemeral
resource "aws_network_acl_rule" "public_in_ephemeral" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 120
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  from_port      = 1024
  to_port        = 65535
  cidr_block     = "0.0.0.0/0"
}

# Public NACL Outbound Rule HTTP
resource "aws_network_acl_rule" "public_out_http" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

# Public NACL Outbound HTTPS
resource "aws_network_acl_rule" "public_out_https" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 110
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

# Public NACL Outbound Rule EPHEMERAL
resource "aws_network_acl_rule" "public_out_ephemeral" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 120
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# Associate Public NACL
resource "aws_network_acl_association" "public" {
  count          = length(aws_subnet.public)
  network_acl_id = aws_network_acl.public.id
  subnet_id      = aws_subnet.public[count.index].id

}

# Create Private NACL
resource "aws_network_acl" "private" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "private-app-nacl"

  }
}

# Private Inbound Rule From ALB
resource "aws_network_acl_rule" "private_in_app_az1" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.public_subnets[0]
  from_port      = 8080
  to_port        = 8080
}
# Private Inbound traffic Rule From Public Subnet B
resource "aws_network_acl_rule" "private_in_app_az2" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 105
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.public_subnets[1] # second public subnet
  from_port      = 8080
  to_port        = 8080
}

# Private Inbound to ephemeral from within VPC
resource "aws_network_acl_rule" "private_in_ephemeral" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  from_port      = 1024
  to_port        = 65535
}

# Private Outbound Rules (NAT + DB)
resource "aws_network_acl_rule" "private_out_all" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "10.0.0.0/16"
}

# Associate Private App NACL
resource "aws_network_acl_association" "private" {
  count          = length(aws_subnet.private)
  network_acl_id = aws_network_acl.private.id
  subnet_id      = aws_subnet.private[count.index].id
}


# Create DATA NACL
resource "aws_network_acl" "data_tier" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "data-nacl"
  }
}

# DATA-TIER Inbound NACL Rule
resource "aws_network_acl_rule" "data_in_db_az1" {
  network_acl_id = aws_network_acl.data_tier.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.private_subnets[0]
  from_port      = 5432
  to_port        = 5432
}

# DATA-TIER NACL RULE (HA)
resource "aws_network_acl_rule" "data_in_db_az2" {
  network_acl_id = aws_network_acl.data_tier.id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.private_subnets[1]
  from_port      = 5432
  to_port        = 5432
}

# DATA-TIER Inbound RULE FOR EPHEMERAL
resource "aws_network_acl_rule" "data_in_ephemeral" {
  network_acl_id = aws_network_acl.data_tier.id
  rule_number    = 120
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  from_port      = 1024
  to_port        = 65535
}

# DB return traffic to app subnet AZ1
resource "aws_network_acl_rule" "data_out_app_az1" {
  network_acl_id = aws_network_acl.data_tier.id
  rule_number    = 100
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.private_subnets[0]
  from_port      = 1024
  to_port        = 65535
}

# DB return traffic to app subnet AZ2
resource "aws_network_acl_rule" "data_out_app_az2" {
  network_acl_id = aws_network_acl.data_tier.id
  rule_number    = 110
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.private_subnets[1]
  from_port      = 1024
  to_port        = 65535
}

# DATA-TIER NACL Association
resource "aws_network_acl_association" "data_tier" {
  count          = length(aws_subnet.data)
  network_acl_id = aws_network_acl.data_tier.id
  subnet_id      = aws_subnet.data[count.index].id
}
