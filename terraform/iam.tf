
# the user group 


resource "aws_iam_group" "budget_protected" {
  name = "depi-sec-users"
}

resource "aws_iam_policy" "deny_expensive" {
  name        = "depi-sec-deny-expensive"
  description = "Deny creation of expensive EC2 and RDS resources when the budget threshold is reached."

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "DenyExpensiveResources"
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
  name = "depi-sec-budgets-action-policy"
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

        Resource = aws_iam_group.budget_protected.arn
      },

      {
        Effect = "Allow"

        Action = [
          "iam:GetPolicy",
          "iam:GetPolicyVersion"
        ]

        Resource = aws_iam_policy.deny_expensive.arn
      }
    ]
  })
}