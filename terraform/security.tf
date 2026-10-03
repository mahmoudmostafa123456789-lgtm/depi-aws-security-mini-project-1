resource "aws_security_group" "alb" {
  name        = "depi-sec-alb-sg"
  description = "Security group for the Application Load Balancer"
  vpc_id      = aws_vpc.app.id

  tags = {
    Name = "depi-sec-alb-sg"
  }
}

resource "aws_security_group" "app" {
  name        = "depi-sec-app-sg"
  description = "Security group for application servers"
  vpc_id      = aws_vpc.app.id

  tags = {
    Name = "depi-sec-app-sg"
  }
}

resource "aws_security_group" "db" {
  name        = "depi-sec-db-sg"
  description = "Security group for the database"
  vpc_id      = aws_vpc.app.id

  tags = {
    Name = "depi-sec-db-sg"
  }
}

resource "aws_security_group" "efs" {
  name        = "depi-sec-efs-sg"
  description = "Security group for EFS"
  vpc_id      = aws_vpc.app.id

  tags = {
    Name = "depi-sec-efs-sg"
  }
}


resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id

  description = "Allow HTTP from the internet"

  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"

  cidr_ipv4 = "0.0.0.0/0"
}



resource "aws_vpc_security_group_ingress_rule" "app_http_from_alb" {
  security_group_id = aws_security_group.app.id

  description = "Allow HTTP only from the ALB security group"

  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"

  referenced_security_group_id = aws_security_group.alb.id
}


resource "aws_vpc_security_group_ingress_rule" "db_mysql_from_app" {
  security_group_id = aws_security_group.db.id

  description = "Allow MySQL only from the application security group"

  from_port   = 3306
  to_port     = 3306
  ip_protocol = "tcp"

  referenced_security_group_id = aws_security_group.app.id
}



resource "aws_vpc_security_group_ingress_rule" "efs_nfs_from_app" {
  security_group_id = aws_security_group.efs.id

  description = "Allow NFS only from the application security group"

  from_port   = 2049
  to_port     = 2049
  ip_protocol = "tcp"

  referenced_security_group_id = aws_security_group.app.id
}


resource "aws_network_acl" "private" {
  vpc_id = aws_vpc.app.id

  tags = {
    Name = "depi-sec-private-nacl"
  }
}


# =========================
# Inbound Rules
# =========================

# Allow TCP 80 from inside the VPC
resource "aws_network_acl_rule" "private_inbound_http" {
  network_acl_id = aws_network_acl.private.id

  rule_number = 100
  egress      = false

  protocol    = "tcp"
  rule_action = "allow"

  cidr_block = "10.0.0.0/16"

  from_port = 80
  to_port   = 80
}

# Allow TCP 443 from inside the VPC
resource "aws_network_acl_rule" "private_inbound_https" {
  network_acl_id = aws_network_acl.private.id

  rule_number = 110
  egress      = false

  protocol    = "tcp"
  rule_action = "allow"

  cidr_block = "10.0.0.0/16"

  from_port = 443
  to_port   = 443
}

# Allow ephemeral ports for return traffic
resource "aws_network_acl_rule" "private_inbound_ephemeral" {
  network_acl_id = aws_network_acl.private.id

  rule_number = 120
  egress      = false

  protocol    = "tcp"
  rule_action = "allow"

  cidr_block = "10.0.0.0/16"

  from_port = 1024
  to_port   = 65535
}

# Explicitly deny SSH
resource "aws_network_acl_rule" "private_inbound_ssh_deny" {
  network_acl_id = aws_network_acl.private.id

  rule_number = 200
  egress      = false

  protocol    = "tcp"
  rule_action = "deny"

  cidr_block = "0.0.0.0/0"

  from_port = 22
  to_port   = 22
}


# =========================
# Outbound Rules
# =========================

# Allow all traffic inside the VPC
resource "aws_network_acl_rule" "private_outbound_vpc" {
  network_acl_id = aws_network_acl.private.id

  rule_number = 100
  egress      = true

  protocol    = "-1"
  rule_action = "allow"

  cidr_block = "10.0.0.0/16"
}

# Allow HTTPS to the Internet
resource "aws_network_acl_rule" "private_outbound_https" {
  network_acl_id = aws_network_acl.private.id

  rule_number = 110
  egress      = true

  protocol    = "tcp"
  rule_action = "allow"

  cidr_block = "0.0.0.0/0"

  from_port = 443
  to_port   = 443
}


# =========================
# Associate with Private Subnets
# =========================

resource "aws_network_acl_association" "private_az1" {
  network_acl_id = aws_network_acl.private.id
  subnet_id      = aws_subnet.private_az1.id
}

resource "aws_network_acl_association" "private_az2" {
  network_acl_id = aws_network_acl.private.id
  subnet_id      = aws_subnet.private_az2.id
}












# =========================
# Outbound Rules
# =========================

resource "aws_vpc_security_group_egress_rule" "alb_all_outbound" {
  security_group_id = aws_security_group.alb.id

  description = "Allow outbound traffic"
  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "app_all_outbound" {
  security_group_id = aws_security_group.app.id

  description = "Allow outbound traffic"
  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "db_all_outbound" {
  security_group_id = aws_security_group.db.id

  description = "Allow outbound traffic"
  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "efs_all_outbound" {
  security_group_id = aws_security_group.efs.id

  description = "Allow outbound traffic"
  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "endpoint_all_outbound" {
  security_group_id = aws_security_group.endpoint.id

  description = "Allow outbound traffic"
  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}


