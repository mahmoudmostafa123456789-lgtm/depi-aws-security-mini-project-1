resource "aws_s3_bucket" "app" {
  bucket = var.app_bucket_name

  tags = {
    Name = "depi-sec-app"
  }
}