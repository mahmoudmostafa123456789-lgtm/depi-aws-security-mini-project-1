resource "aws_vpc" "app" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "depi-sec-app-vpc"
  }
}

# -------------------------
# Public Subnets
# -------------------------

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.app.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "depi-sec-public-1"
    Tier = "Public"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.app.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "depi-sec-public-2"
    Tier = "Public"
  }
}

# -------------------------
# Private Subnets
# -------------------------

resource "aws_subnet" "private_1" {
  vpc_id                  = aws_vpc.app.id
  cidr_block              = "10.0.11.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "depi-sec-private-1"
    Tier = "Private"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id                  = aws_vpc.app.id
  cidr_block              = "10.0.12.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "depi-sec-private-2"
    Tier = "Private"
  }
}

# -------------------------
# Internet Gateway
# -------------------------

resource "aws_internet_gateway" "app" {
  vpc_id = aws_vpc.app.id

  tags = {
    Name = "depi-sec-app-igw"
  }
}

# -------------------------
# Public Route Table
# -------------------------

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

# Public subnet associations

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# -------------------------
# Private Route Table
# -------------------------

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.app.id

  tags = {
    Name = "depi-sec-private-rt"
  }
}

# Private subnet associations

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}