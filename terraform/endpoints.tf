# =========================
# VPC Endpoint Security Group
# =========================

resource "aws_security_group" "endpoint" {
  name        = "depi-sec-endpoint-sg"
  description = "Allow HTTPS access to VPC interface endpoints"
  vpc_id      = aws_vpc.app.id

  tags = {
    Name = "depi-sec-endpoint-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "endpoint_https" {
  security_group_id = aws_security_group.endpoint.id

  description = "Allow HTTPS from the VPC"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  cidr_ipv4 = "10.0.0.0/16"
}


# =========================
# S3 Gateway Endpoint
# =========================

resource "aws_vpc_endpoint" "s3" {
  vpc_id = aws_vpc.app.id

  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private.id
  ]

  tags = {
    Name = "depi-sec-s3-endpoint"
  }
}


# =========================
# SSM Interface Endpoint
# =========================

resource "aws_vpc_endpoint" "ssm" {
  vpc_id = aws_vpc.app.id

  service_name      = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type = "Interface"

  subnet_ids = [
    aws_subnet.private_az1.id,
    aws_subnet.private_az2.id
  ]

  security_group_ids = [
    aws_security_group.endpoint.id
  ]

  private_dns_enabled = true

  tags = {
    Name = "depi-sec-ssm-endpoint"
  }
}


# =========================
# SSM Messages Interface Endpoint
# =========================

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id = aws_vpc.app.id

  service_name      = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type = "Interface"

  subnet_ids = [
    aws_subnet.private_az1.id,
    aws_subnet.private_az2.id
  ]

  security_group_ids = [
    aws_security_group.endpoint.id
  ]

  private_dns_enabled = true

  tags = {
    Name = "depi-sec-ssmmessages-endpoint"
  }
}


# =========================
# EC2 Messages Interface Endpoint
# =========================

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id = aws_vpc.app.id

  service_name      = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type = "Interface"

  subnet_ids = [
    aws_subnet.private_az1.id,
    aws_subnet.private_az2.id
  ]

  security_group_ids = [
    aws_security_group.endpoint.id
  ]

  private_dns_enabled = true

  tags = {
    Name = "depi-sec-ec2messages-endpoint"
  }
}