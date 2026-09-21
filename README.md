# DEPI AWS Security Mini Project 1

Terraform project for building and securing AWS cloud infrastructure.

## Project Goals

- AWS Cloud Architecture
- Cloud Networking
- Cloud Security
- Infrastructure as Code using Terraform

## Technology Stack

- AWS
- Terraform
- Git
- GitHub







## Task 2 — Cost Governance as a Security Control

This task implements AWS cost governance as a security control using AWS Budgets and IAM.

### Configuration

* Monthly AWS Budget: `$10`
* 80% of budget (`$8`) → Actual cost email notification
* 90% of budget (`$9`) → Automatic IAM security action
* 100% of budget → Forecasted cost email notification
* Budget Action: `APPLY_IAM_POLICY`
* Approval Model: `AUTOMATIC`

### IAM Security Control

The budget action uses the IAM policy:

`depi-sec-deny-expensive`

The policy denies:

* `ec2:RunInstances`
* `rds:CreateDBInstance`

The policy is applied to the IAM group:

`depi-sec-users`

The AWS Budgets service uses the IAM role:

`depi-sec-budgets-action-role`

### Why This Is a Security Control

The budget is not used only for financial monitoring. It also provides an automated defensive response to unexpected resource creation.

If compromised AWS credentials are used to create expensive EC2 or RDS resources, the budget action can automatically apply an IAM Deny policy when actual spending reaches 90% of the monthly budget. This helps limit unauthorized resource creation and reduces the potential impact of unexpected cloud spending.

### Evidence

| Screenshot               | Description                                                          |
| ------------------------ | -------------------------------------------------------------------- |
| `02-budget-overview.png` | AWS Budget, 80% actual notification and 100% forecasted notification |
| `02-budget-action.png`   | Automatic 90% Budget Action and IAM policy configuration             |
