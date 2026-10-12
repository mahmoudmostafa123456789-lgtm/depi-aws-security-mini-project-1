
# AWS Backup Vault
resource "aws_backup_vault" "depi" {
  name = "depi-sec-vault"

  tags = {
    Name = "depi-sec-vault"
  }
}

# Governance-mode Vault Lock
resource "aws_backup_vault_lock_configuration" "depi" {
  backup_vault_name  = aws_backup_vault.depi.name
  min_retention_days = 7
  max_retention_days = 365

  # Do not set changeable_for_days here:
  # omitting it creates Governance mode.
}

# AWS Backup IAM Role
data "aws_iam_policy_document" "backup_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "backup" {
  name               = "depi-sec-backup-role"
  assume_role_policy = data.aws_iam_policy_document.backup_assume_role.json
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "restores" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

# Daily backup plan at 05:00 UTC; retain recovery points for 30 days
resource "aws_backup_plan" "depi" {
  name = "depi-sec-daily-backup-plan"

  rule {
    rule_name         = "depi-sec-daily-rule"
    target_vault_name = aws_backup_vault.depi.name
    schedule          = "cron(0 5 * * ? *)"
    start_window      = 60

    lifecycle {
      delete_after = 30
    }
  }
}

# Back up resources matching the exact Project tag
resource "aws_backup_selection" "depi" {
  name         = "depi-sec-project-resources"
  plan_id      = aws_backup_plan.depi.id
  iam_role_arn = aws_iam_role.backup.arn

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Project"
    value = "depi-mini-project-1"
  }

  depends_on = [
    aws_iam_role_policy_attachment.backup,
    aws_iam_role_policy_attachment.restores
  ]
}

output "backup_vault_name" {
  value = aws_backup_vault.depi.name
}

output "backup_plan_id" {
  value = aws_backup_plan.depi.id
}

output "backup_role_arn" {
  value = aws_iam_role.backup.arn
}
