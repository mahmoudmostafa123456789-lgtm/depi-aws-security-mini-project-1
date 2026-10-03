# =========================
# Latest Amazon Linux 2023 AMI
# =========================

data "aws_ami" "amazon_linux_2023" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


# =========================
# Web Server - AZ1
# =========================

resource "aws_instance" "web_az1" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"

  subnet_id = aws_subnet.private_az1.id

  vpc_security_group_ids = [
    aws_security_group.app.id
  ]

  iam_instance_profile = aws_iam_instance_profile.ec2.name

  associate_public_ip_address = false

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
  }

  user_data = <<-EOF
              #!/bin/bash

              dnf update -y
              dnf install -y nginx

              systemctl enable nginx
              systemctl start nginx

              AZ=$(TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" \
                -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"); \
                curl -sH "X-aws-ec2-metadata-token: $TOKEN" \
                http://169.254.169.254/latest/meta-data/placement/availability-zone)

              echo "<html><body><h1>DEPI Web Server</h1><p>Availability Zone: $AZ</p></body></html>" > /usr/share/nginx/html/index.html
              EOF

  tags = {
    Name = "depi-sec-web-az1"
  }
}


# =========================
# Web Server - AZ2
# =========================

resource "aws_instance" "web_az2" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"

  subnet_id = aws_subnet.private_az2.id

  vpc_security_group_ids = [
    aws_security_group.app.id
  ]

  iam_instance_profile = aws_iam_instance_profile.ec2.name

  associate_public_ip_address = false


  root_block_device {
    encrypted   = true
    volume_type = "gp3"
  }

  user_data = <<-EOF
              #!/bin/bash

              dnf update -y
              dnf install -y nginx

              systemctl enable nginx
              systemctl start nginx

              AZ=$(TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" \
                -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"); \
                curl -sH "X-aws-ec2-metadata-token: $TOKEN" \
                http://169.254.169.254/latest/meta-data/placement/availability-zone)

              echo "<html><body><h1>DEPI Web Server</h1><p>Availability Zone: $AZ</p></body></html>" > /usr/share/nginx/html/index.html
              EOF

  tags = {
    Name = "depi-sec-web-az2"
  }
}