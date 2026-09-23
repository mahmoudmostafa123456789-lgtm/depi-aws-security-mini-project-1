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



# Developer group
resource "aws_iam_group" "developers" {
  name = "depi-sec-developers"
}

resource "aws_iam_group_policy_attachment" "developers_readonly" {
  group      = aws_iam_group.developers.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Developer IAM user
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
  user                    = aws_iam_user.developer.name
  password_length         = 20
  password_reset_required = true
}


# Custom S3 read-only policy
resource "aws_iam_policy" "s3_app_read" {
  name        = "depi-sec-s3-app-read"
  description = "Allow reading objects only from the specified application bucket"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "arn:aws:s3:::${var.app_bucket_name}/*"
      }
    ]
  })
}

# EC2 role trust relationship
resource "aws_iam_role" "ec2_role" {
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

# Attach AWS Systems Manager permissions
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach custom S3 read policy
resource "aws_iam_role_policy_attachment" "ec2_s3_read" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_app_read.arn
}

# Instance profile for EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "depi-sec-ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}