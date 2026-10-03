resource "aws_s3_bucket" "app" {
  bucket = var.app_bucket_name

  tags = {
    Name = "depi-sec-app"
  }
}


resource "aws_efs_file_system" "shared" {
  creation_token = "depi-sec-shared-efs"

  encrypted = true

  tags = {
    Name = "depi-sec-shared-efs"
  }
}




resource "aws_efs_mount_target" "private_az1" {
  file_system_id  = aws_efs_file_system.shared.id
  subnet_id       = aws_subnet.private_az1.id
  security_groups = [aws_security_group.efs.id]
}




resource "aws_efs_mount_target" "private_az2" {
  file_system_id  = aws_efs_file_system.shared.id
  subnet_id       = aws_subnet.private_az2.id
  security_groups = [aws_security_group.efs.id]
}


resource "aws_efs_access_point" "app" {
  file_system_id = aws_efs_file_system.shared.id

  posix_user {
    uid = 1000
    gid = 1000
  }

  root_directory {
    path = "/app-data"

    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = "0755"
    }
  }

  tags = {
    Name = "depi-sec-app-access-point"
  }
}
