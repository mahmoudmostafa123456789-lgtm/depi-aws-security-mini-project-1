# ==========================================
# ALB Security Group
# ==========================================

resource "aws_security_group" "alb" {
  name        = "depi-sec-alb-sg"
  description = "Security group for the Application Load Balancer"
  vpc_id      = aws_vpc.app.id

  tags = {
    Name = "depi-sec-alb-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"

  description = "Allow HTTP from the internet"
}

resource "aws_vpc_security_group_egress_rule" "alb_all_outbound" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  description = "Allow outbound traffic"
}


# ==========================================
# Application Security Group
# ==========================================

resource "aws_security_group" "app" {
  name        = "depi-sec-app-sg"
  description = "Security group for application servers"
  vpc_id      = aws_vpc.app.id

  tags = {
    Name = "depi-sec-app-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "app_http_from_alb" {
  security_group_id = aws_security_group.app.id

  referenced_security_group_id = aws_security_group.alb.id

  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"

  description = "Allow HTTP only from ALB"
}

resource "aws_vpc_security_group_egress_rule" "app_all_outbound" {
  security_group_id = aws_security_group.app.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  description = "Allow outbound traffic"
}


# ==========================================
# Database Security Group
# ==========================================

resource "aws_security_group" "db" {
  name        = "depi-sec-db-sg"
  description = "Security group for database"
  vpc_id      = aws_vpc.app.id

  tags = {
    Name = "depi-sec-db-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "db_mysql_from_app" {
  security_group_id = aws_security_group.db.id

  referenced_security_group_id = aws_security_group.app.id

  from_port   = 3306
  to_port     = 3306
  ip_protocol = "tcp"

  description = "Allow MySQL only from application servers"
}

resource "aws_vpc_security_group_egress_rule" "db_all_outbound" {
  security_group_id = aws_security_group.db.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  description = "Allow outbound traffic"
}


# ==========================================
# EFS Security Group
# ==========================================

resource "aws_security_group" "efs" {
  name        = "depi-sec-efs-sg"
  description = "Security group for EFS"
  vpc_id      = aws_vpc.app.id

  tags = {
    Name = "depi-sec-efs-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "efs_nfs_from_app" {
  security_group_id = aws_security_group.efs.id

  referenced_security_group_id = aws_security_group.app.id

  from_port   = 2049
  to_port     = 2049
  ip_protocol = "tcp"

  description = "Allow NFS only from application servers"
}

resource "aws_vpc_security_group_egress_rule" "efs_all_outbound" {
  security_group_id = aws_security_group.efs.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  description = "Allow outbound traffic"
}




# ==========================================
# Private Subnet Network ACL
# ==========================================

resource "aws_network_acl" "private" {
  vpc_id = aws_vpc.app.id

  tags = {
    Name = "depi-sec-private-nacl"
  }
}

# ==========================================
# Inbound Rules
# ==========================================

resource "aws_network_acl_rule" "private_inbound_http" {
  network_acl_id = aws_network_acl.private.id

  rule_number = 100
  egress      = false

  protocol   = "tcp"
  rule_action = "allow"

  cidr_block = "10.0.0.0/16"

  from_port = 80
  to_port   = 80
}

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

# ==========================================
# Outbound Rules
# ==========================================

resource "aws_network_acl_rule" "private_outbound_internal" {
  network_acl_id = aws_network_acl.private.id

  rule_number = 100
  egress      = true

  protocol    = "-1"
  rule_action = "allow"

  cidr_block = "10.0.0.0/16"

  from_port = 0
  to_port   = 0
}

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

# ==========================================
# Associate NACL with Private Subnets
# ==========================================

resource "aws_network_acl_association" "private_1" {
  network_acl_id = aws_network_acl.private.id
  subnet_id      = aws_subnet.private_1.id
}

resource "aws_network_acl_association" "private_2" {
  network_acl_id = aws_network_acl.private.id
  subnet_id      = aws_subnet.private_2.id
}



