# =========================================================
# SSH/RDP Auto-Remediation - IAM Role
# =========================================================

resource "aws_iam_role" "ssh_remediation" {
  name = "depi-sec-ssh-remediation-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "ssh_remediation" {
  name = "depi-sec-ssh-remediation-policy"
  role = aws_iam_role.ssh_remediation.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DescribeSecurityGroups"
        Effect   = "Allow"
        Action   = ["ec2:DescribeSecurityGroups"]
        Resource = "*"
      },
      {
        Sid      = "RevokeOnlyApplicationSecurityGroupIngress"
        Effect   = "Allow"
        Action   = ["ec2:RevokeSecurityGroupIngress"]
        Resource = aws_security_group.app.arn
      },
      {
        Sid      = "PublishRemediationAlerts"
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = aws_sns_topic.alerts.arn
      },
      {
        Sid      = "CreateLambdaLogGroup"
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup"]
        Resource = "*"
      },
      {
        Sid    = "WriteLambdaLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.ssh_remediation.arn}:*"
      }
    ]
  })
}

# =========================================================
# Lambda CloudWatch Log Group
# =========================================================

resource "aws_cloudwatch_log_group" "ssh_remediation" {
  name              = "/aws/lambda/depi-sec-ssh-remediation"
  retention_in_days = 14
}

# =========================================================
# Package Python Function
# =========================================================

data "archive_file" "ssh_remediation" {
  type        = "zip"
  source_file = "${path.module}/lambda_src/security_group_remediation.py"
  output_path = "${path.module}/.terraform/depi-sec-ssh-remediation.zip"
}

# =========================================================
# Lambda Function
# =========================================================

resource "aws_lambda_function" "ssh_remediation" {
  function_name = "depi-sec-ssh-remediation"
  description   = "Automatically revoke public SSH and RDP ingress rules"
  role          = aws_iam_role.ssh_remediation.arn
  handler       = "security_group_remediation.lambda_handler"
  runtime       = "python3.12"

  filename         = data.archive_file.ssh_remediation.output_path
  source_code_hash = data.archive_file.ssh_remediation.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      SNS_TOPIC_ARN    = aws_sns_topic.alerts.arn
      ALLOWED_GROUP_ID = aws_security_group.app.id
    }
  }

  depends_on = [
    aws_iam_role_policy.ssh_remediation,
    aws_cloudwatch_log_group.ssh_remediation
  ]
}

# =========================================================
# EventBridge Rule - CloudTrail API Event
# =========================================================

resource "aws_cloudwatch_event_rule" "ssh_remediation" {
  name        = "depi-sec-ssh-remediation-trigger"
  description = "Detect ingress authorization attempts on the application security group"

  event_pattern = jsonencode({
    source        = ["aws.ec2"]
    "detail-type" = ["AWS API Call via CloudTrail"]

    detail = {
      eventSource = ["ec2.amazonaws.com"]
      eventName   = ["AuthorizeSecurityGroupIngress"]

      requestParameters = {
        groupId = [aws_security_group.app.id]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "ssh_remediation" {
  rule      = aws_cloudwatch_event_rule.ssh_remediation.name
  target_id = "depi-sec-ssh-remediation"
  arn       = aws_lambda_function.ssh_remediation.arn
}

resource "aws_lambda_permission" "allow_eventbridge_remediation" {
  statement_id  = "AllowEventBridgeInvokeSSHRemediation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ssh_remediation.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ssh_remediation.arn
}
