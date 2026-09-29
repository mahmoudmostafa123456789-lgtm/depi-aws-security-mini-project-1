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


