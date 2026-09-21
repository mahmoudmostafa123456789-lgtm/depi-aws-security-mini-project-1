resource "aws_iam_policy" "deny_expensive" {
  name        = "depi-sec-deny-expensive"
  description = "Deny creation of expensive EC2 and RDS resources"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Deny"

        Action = [
          "ec2:RunInstances",
          "rds:CreateDBInstance"
        ]

        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "budgets_action" {
  name = "depi-sec-budgets-action-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "budgets.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "budgets_action" {
  name = "depi-sec-budgets-action-permissions"
  role = aws_iam_role.budgets_action.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "iam:AttachGroupPolicy",
          "iam:DetachGroupPolicy"
        ]

        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_group" "security_users" {
  name = "depi-sec-users"
}