
# Tools VPC
resource "aws_vpc" "tools" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "depi-sec-tools-vpc"
  }
}

resource "aws_subnet" "tools_private" {
  vpc_id                  = aws_vpc.tools.id
  cidr_block              = "10.1.1.0/24"
  availability_zone       = aws_subnet.private_az1.availability_zone
  map_public_ip_on_launch = false

  tags = {
    Name = "depi-sec-tools-private-subnet"
  }
}

resource "aws_route_table" "tools_private" {
  vpc_id = aws_vpc.tools.id

  tags = {
    Name = "depi-sec-tools-private-rt"
  }
}

resource "aws_route_table_association" "tools_private" {
  subnet_id      = aws_subnet.tools_private.id
  route_table_id = aws_route_table.tools_private.id
}

# VPC Peering
resource "aws_vpc_peering_connection" "app_tools" {
  vpc_id      = aws_vpc.app.id
  peer_vpc_id = aws_vpc.tools.id
  auto_accept = true

  tags = {
    Name = "depi-sec-app-tools-peering"
  }
}

# Routes in both directions
resource "aws_route" "app_to_tools" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = "10.1.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.app_tools.id
}

resource "aws_route" "tools_to_app" {
  route_table_id            = aws_route_table.tools_private.id
  destination_cidr_block    = "10.0.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.app_tools.id
}

# Monitoring instance security group
resource "aws_security_group" "tools_monitoring" {
  name        = "depi-sec-tools-monitoring-sg"
  description = "Allow monitoring traffic to the app VPC and HTTPS to SSM endpoints"
  vpc_id      = aws_vpc.tools.id

  egress {
    description = "HTTP to application VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    description = "HTTPS to SSM interface endpoints"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.1.1.0/24"]
  }

  tags = {
    Name = "depi-sec-tools-monitoring-sg"
  }
}

# Allow HTTP and ICMP from the tools subnet to app instances
resource "aws_vpc_security_group_ingress_rule" "app_http_from_tools" {
  security_group_id = aws_security_group.app.id
  description       = "HTTP from tools monitoring subnet"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "10.1.1.0/24"
}

resource "aws_vpc_security_group_ingress_rule" "app_icmp_from_tools" {
  security_group_id = aws_security_group.app.id
  description       = "ICMP from tools monitoring subnet"
  ip_protocol       = "icmp"
  from_port         = -1
  to_port           = -1
  cidr_ipv4         = "10.1.1.0/24"
}

# SSM endpoints security group
resource "aws_security_group" "tools_ssm_endpoints" {
  name        = "depi-sec-tools-ssm-endpoints-sg"
  description = "Allow HTTPS from monitoring subnet to SSM endpoints"
  vpc_id      = aws_vpc.tools.id

  ingress {
    description = "HTTPS from monitoring subnet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.1.1.0/24"]
  }

  tags = {
    Name = "depi-sec-tools-ssm-endpoints-sg"
  }
}

# Private Systems Manager connectivity
resource "aws_vpc_endpoint" "tools_ssm" {
  vpc_id              = aws_vpc.tools.id
  service_name        = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.tools_private.id]
  security_group_ids  = [aws_security_group.tools_ssm_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "depi-sec-tools-ssm"
  }
}

resource "aws_vpc_endpoint" "tools_ssmmessages" {
  vpc_id              = aws_vpc.tools.id
  service_name        = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.tools_private.id]
  security_group_ids  = [aws_security_group.tools_ssm_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "depi-sec-tools-ssmmessages"
  }
}

resource "aws_vpc_endpoint" "tools_ec2messages" {
  vpc_id              = aws_vpc.tools.id
  service_name        = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.tools_private.id]
  security_group_ids  = [aws_security_group.tools_ssm_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "depi-sec-tools-ec2messages"
  }
}

# Latest Amazon Linux 2023 AMI
data "aws_ami" "tools_amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Private monitoring instance
resource "aws_instance" "tools_monitoring" {
  ami                         = data.aws_ami.tools_amazon_linux_2023.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.tools_private.id
  vpc_security_group_ids      = [aws_security_group.tools_monitoring.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  associate_public_ip_address = false

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = 8
  }

  tags = {
    Name = "depi-sec-tools-monitoring"
  }
}

output "tools_vpc_id" {
  value = aws_vpc.tools.id
}

output "tools_monitoring_private_ip" {
  value = aws_instance.tools_monitoring.private_ip
}

output "app_tools_peering_status" {
  value = aws_vpc_peering_connection.app_tools.accept_status
}
