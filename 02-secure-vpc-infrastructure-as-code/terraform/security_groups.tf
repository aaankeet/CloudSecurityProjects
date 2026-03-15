# Create ALB Security Group
resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "Allow HTTP/HTTPS from the Internet"
  vpc_id      = aws_vpc.this.id


  ingress {
    description = "Allow HTTPS from the Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.private_subnets
  }

  tags = {
    Name = "alb-sg"
    Tier = "public"
  }
}

# Create App Security Group
resource "aws_security_group" "app" {
  name        = "app-sg"
  description = "Allow Inbound traffic from ALB"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "Allow Inbound from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  egress {
    description = "Allow Outbound to DB"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.data_subnets
  }
  tags = {
    Name = "app-sg"
    Tier = "private"
  }

}

# Create DB Security Group (Data Tier)
resource "aws_security_group" "db" {
  name        = "db-sg"
  description = "Allow DB access from app tier only"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "Allow PostgreSQL from App Tier"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    description = "Allow Outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  tags = {
    Name = "db-sg"
    Tier = "data"
  }
}


# Create Security Group for CLOUDWATCH LOGS ENDPOINT(INTERFACE ENDPOINTS / PRIVATE-LINK)
resource "aws_security_group" "endpoint" {
  name        = "endpoint-sg"
  description = "Security group for vpc endpoint Cloudwatch logs "
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "Allow HTTPS from VPC"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow HTTPS responses with in VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  tags = {
    Name = "cloudwatch-endpoint-sg"
  }
}
