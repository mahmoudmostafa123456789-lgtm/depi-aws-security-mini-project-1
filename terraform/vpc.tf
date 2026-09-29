resource "aws_vpc" "app" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "depi-sec-app-vpc"
  }
}

resource "aws_subnet" "public_az1" {
  vpc_id                  = aws_vpc.app.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "depi-sec-public-az1"
    Tier = "Public"
  }
}

resource "aws_subnet" "private_az1" {
  vpc_id                  = aws_vpc.app.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "depi-sec-private-az1"
    Tier = "Private"
  }
}

resource "aws_subnet" "public_az2" {
  vpc_id                  = aws_vpc.app.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "depi-sec-public-az2"
    Tier = "Public"
  }
}

resource "aws_subnet" "private_az2" {
  vpc_id                  = aws_vpc.app.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "depi-sec-private-az2"
    Tier = "Private"
  }
}

resource "aws_internet_gateway" "app" {
  vpc_id = aws_vpc.app.id

  tags = {
    Name = "depi-sec-app-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.app.id

  tags = {
    Name = "depi-sec-public-rt"
  }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.app.id
}

resource "aws_route_table_association" "public_az1" {
  subnet_id      = aws_subnet.public_az1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_az2" {
  subnet_id      = aws_subnet.public_az2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.app.id

  tags = {
    Name = "depi-sec-private-rt"
  }
}

resource "aws_route_table_association" "private_az1" {
  subnet_id      = aws_subnet.private_az1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_az2" {
  subnet_id      = aws_subnet.private_az2.id
  route_table_id = aws_route_table.private.id
}