# =========================================================
# Application Load Balancer
# =========================================================

resource "aws_lb" "app" {
  name               = "depi-sec-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb.id
  ]

  subnets = [
    aws_subnet.public_az1.id,
    aws_subnet.public_az2.id
  ]

  tags = {
    Name = "depi-sec-alb"
  }
}

# =========================================================
# Target Group
# =========================================================

resource "aws_lb_target_group" "app" {
  name     = "depi-sec-app-tg"
  port     = 80
  protocol = "HTTP"

  vpc_id = aws_vpc.app.id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    port                = "traffic-port"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "depi-sec-app-tg"
  }
}

# =========================================================
# Register EC2 AZ1
# =========================================================

resource "aws_lb_target_group_attachment" "web_az1" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.web_az1.id
  port             = 80
}

# =========================================================
# Register EC2 AZ2
# =========================================================

resource "aws_lb_target_group_attachment" "web_az2" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.web_az2.id
  port             = 80
}

# =========================================================
# HTTP Listener
# =========================================================

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# =========================================================
# ALB DNS
# =========================================================

output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer"
  value       = aws_lb.app.dns_name
}