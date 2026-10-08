# ============================================================
# VPC Flow Logs
# ============================================================

resource "aws_cloudwatch_log_group" "vpc_flowlogs" {
  name              = "/depi-sec/vpc/flowlogs"
  retention_in_days = 14

  tags = {
    Name = "depi-sec-vpc-flowlogs"
  }
}

resource "aws_iam_role" "vpc_flowlogs" {
  name = "depi-sec-vpc-flowlogs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "depi-sec-vpc-flowlogs-role"
  }
}

resource "aws_iam_role_policy" "vpc_flowlogs" {
  name = "depi-sec-vpc-flowlogs-policy"
  role = aws_iam_role.vpc_flowlogs.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]

        Resource = "*"
      }
    ]
  })
}

resource "aws_flow_log" "vpc" {
  vpc_id = aws_vpc.app.id

  traffic_type = "ALL"

  iam_role_arn         = aws_iam_role.vpc_flowlogs.arn
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.vpc_flowlogs.arn

  tags = {
    Name = "depi-sec-vpc-flowlogs"
  }
}