# =========================================================
# CloudFront Origin Secret
# =========================================================

resource "random_password" "cloudfront_origin_secret" {
  length  = 32
  special = false
}

# =========================================================
# CloudFront Distribution
# =========================================================

resource "aws_cloudfront_distribution" "app" {
  enabled = true

  comment = "DEPI Secure CloudFront Distribution"

  origin {
    domain_name = aws_lb.app.dns_name
    origin_id   = "depi-sec-alb-origin"

    custom_header {
      name  = "X-Origin-Verify"
      value = random_password.cloudfront_origin_secret.result
    }

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"

      origin_ssl_protocols = [
        "TLSv1.2"
      ]
    }
  }

  default_cache_behavior {
    target_origin_id = "depi-sec-alb-origin"

    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = [
      "GET",
      "HEAD",
      "OPTIONS"
    ]

    cached_methods = [
      "GET",
      "HEAD",
      "OPTIONS"
    ]

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }

    compress = true

    min_ttl     = 0
    default_ttl = 300
    max_ttl     = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  price_class = "PriceClass_100"

  tags = {
    Name = "depi-sec-cloudfront"
  }
}

# =========================================================
# CloudFront DNS Output
# =========================================================

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.app.domain_name
}