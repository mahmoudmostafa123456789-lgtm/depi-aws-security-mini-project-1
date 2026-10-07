# =========================================================
# RDS MySQL
# =========================================================

resource "aws_db_subnet_group" "mysql" {
  name = "depi-sec-db-subnet-group"

  subnet_ids = [
    aws_subnet.private_az1.id,
    aws_subnet.private_az2.id
  ]

  tags = {
    Name = "depi-sec-db-subnet-group"
  }
}

# =========================================================
# Database Password
# =========================================================

resource "random_password" "rds" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}?"
}

# =========================================================
# Secrets Manager
# =========================================================

resource "aws_secretsmanager_secret" "rds" {
  name = "depi-sec/rds/mysql"

  description = "Credentials for the DEPI security project RDS MySQL database"

  tags = {
    Name = "depi-sec-rds-secret"
  }
}

resource "aws_secretsmanager_secret_version" "rds" {
  secret_id = aws_secretsmanager_secret.rds.id

  secret_string = jsonencode({
    username = "depiadmin"
    password = random_password.rds.result
  })
}

# =========================================================
# RDS MySQL
# =========================================================

resource "aws_db_instance" "mysql" {
  identifier = "depi-sec-mysql"

  engine         = "mysql"
  engine_version = "8.0"

  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = "depidb"
  username = "depiadmin"
  password = random_password.rds.result

  db_subnet_group_name = aws_db_subnet_group.mysql.name

  vpc_security_group_ids = [
    aws_security_group.db.id
  ]

  publicly_accessible     = false
  multi_az                = false
  deletion_protection     = false
  skip_final_snapshot     = true
  backup_retention_period = 0

  port = 3306

  tags = {
    Name = "depi-sec-mysql"
  }

  depends_on = [
    aws_secretsmanager_secret_version.rds
  ]
}