# =========================================================
# CloudTrail CloudWatch Log Group
# =========================================================

resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/depi-sec-trail"
  retention_in_days = 30

  tags = {
    Name = "depi-sec-cloudtrail"
  }
}

# =========================================================
# CloudTrail IAM Role
# =========================================================

resource "aws_iam_role" "cloudtrail" {
  name = "depi-sec-cloudtrail-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

# =========================================================
# CloudTrail CloudWatch Logs Policy
# =========================================================

resource "aws_iam_role_policy" "cloudtrail_cloudwatch" {
  name = "depi-sec-cloudtrail-cloudwatch"
  role = aws_iam_role.cloudtrail.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]

        Resource = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
      }
    ]
  })
}

# =========================================================
# Combined Logs Bucket Policy
# =========================================================

data "aws_iam_policy_document" "logs_bucket_combined" {

  # -------------------------------------------------------
  # Deny insecure transport
  # -------------------------------------------------------

  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:*"
    ]

    resources = [
      aws_s3_bucket.logs.arn,
      "${aws_s3_bucket.logs.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"

      values = [
        "false"
      ]
    }
  }

  # -------------------------------------------------------
  # Allow CloudTrail to check bucket ACL
  # -------------------------------------------------------

  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type = "Service"

      identifiers = [
        "cloudtrail.amazonaws.com"
      ]
    }

    actions = [
      "s3:GetBucketAcl"
    ]

    resources = [
      aws_s3_bucket.logs.arn
    ]
  }

  # -------------------------------------------------------
  # Allow CloudTrail to write logs
  # -------------------------------------------------------

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type = "Service"

      identifiers = [
        "cloudtrail.amazonaws.com"
      ]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.logs.arn}/AWSLogs/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"

      values = [
        "bucket-owner-full-control"
      ]
    }
  }
}

# =========================================================
# CloudTrail
# =========================================================

resource "aws_cloudtrail" "main" {
  name = "depi-sec-trail"

  s3_bucket_name = aws_s3_bucket.logs.id

  is_multi_region_trail = true

  enable_log_file_validation = true

  include_global_service_events = true

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"

  cloud_watch_logs_role_arn = aws_iam_role.cloudtrail.arn

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type = "AWS::S3::Object"

      values = [
        "${aws_s3_bucket.app.arn}/"
      ]
    }
  }

  tags = {
    Name = "depi-sec-trail"
  }

  depends_on = [
    aws_s3_bucket_policy.logs
  ]
}