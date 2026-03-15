# Create Internet Gatewat
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "secure_igw"
  }
}

# Create Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Associate Public Subnets
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Create Private Route Table
resource "aws_route_table" "private_rt" {
  count  = length(aws_subnet.private)
  vpc_id = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[count.index].id
  }
  tags = {
    Name = "private-app-rt-${count.index + 1}"
  }
}

# Associate Private App Subnets
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_rt[count.index].id
}

# Create DATA Route Table
resource "aws_route_table" "data_rt" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "data-tier-rt"
  }
}

# Associate Data Subnets
resource "aws_route_table_association" "data" {
  count          = length(aws_subnet.data)
  subnet_id      = aws_subnet.data[count.index].id
  route_table_id = aws_route_table.data_rt.id
}
