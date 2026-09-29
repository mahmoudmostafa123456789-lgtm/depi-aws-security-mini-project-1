
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



resource "aws_iam_account_password_policy" "main" {
  minimum_password_length        = 14
  require_uppercase_characters   = true
  require_lowercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  password_reuse_prevention      = 5
  max_password_age               = 90
  allow_users_to_change_password = true
}

resource "aws_iam_group" "developers" {
  name = "depi-sec-developers"
}

resource "aws_iam_group_policy_attachment" "developers_readonly" {
  group      = aws_iam_group.developers.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_user" "developer" {
  name = "depi-dev-1"
}

resource "aws_iam_user_group_membership" "developer" {
  user = aws_iam_user.developer.name

  groups = [
    aws_iam_group.developers.name
  ]
}

resource "aws_iam_user_login_profile" "developer" {
  user = aws_iam_user.developer.name

  password_reset_required = true
}

resource "aws_iam_policy" "s3_app_read" {
  name        = "depi-sec-s3-app-read"
  description = "Allow read-only access to objects in the application S3 bucket."

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "AllowReadApplicationObjects"
        Effect = "Allow"

        Action = [
          "s3:GetObject"
        ]

        Resource = "${aws_s3_bucket.app.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role" "ec2" {
  name = "depi-sec-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2_s3_read" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.s3_app_read.arn
}

resource "aws_iam_instance_profile" "ec2" {
  name = "depi-sec-ec2-profile"
  role = aws_iam_role.ec2.name
}