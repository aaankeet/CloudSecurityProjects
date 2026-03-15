# Create Elastic IP for each NAT in each Public Subnet
resource "aws_eip" "nat" {
  count  = length(aws_subnet.public)
  domain = "vpc"

  tags = {
    Name = "nat-eip-${count.index + 1}"
  }
}

# Create NAT Gateway for Each Public Subnet
resource "aws_nat_gateway" "this" {
  count         = length(aws_subnet.public)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  depends_on = [aws_internet_gateway.this]

  tags = {
    Name = "nat-gateway-${count.index + 1}"
  }
}
