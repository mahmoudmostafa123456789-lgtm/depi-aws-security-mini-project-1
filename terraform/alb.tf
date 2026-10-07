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

  port     = 80
  protocol = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Forbidden"
      status_code  = "403"
    }
  }
}
# =========================================================
# ALB DNS
# =========================================================

output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer"
  value       = aws_lb.app.dns_name
}




resource "aws_lb_listener_rule" "cloudfront_origin" {
  listener_arn = aws_lb_listener.http.arn

  priority = 100

  condition {
    http_header {
      http_header_name = "X-Origin-Verify"

      values = [
        random_password.cloudfront_origin_secret.result
      ]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}