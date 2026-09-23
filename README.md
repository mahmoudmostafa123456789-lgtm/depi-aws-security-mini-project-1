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




## Task 3 — IAM Identities and Least Privilege

This task implements IAM identities using the principle of least privilege. Each identity receives only the permissions required for its intended purpose.

| Identity               | What it can do                                                                                       | Why                                                                                                   |
| ---------------------- | ---------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| `depi-sec-developers`  | Read-only access to AWS resources through `ReadOnlyAccess`                                           | Allows developers to inspect AWS resources without modifying infrastructure                           |
| `depi-dev-1`           | Console access through the `depi-sec-developers` group                                               | Provides a developer identity without attaching direct permissions to the user                        |
| `depi-sec-ec2-role`    | EC2 can assume the role; access to AWS Systems Manager and `s3:GetObject` for the application bucket | Allows EC2 to access only the services required by the workload without storing permanent access keys |
| `depi-sec-s3-app-read` | `s3:GetObject` only on `arn:aws:s3:::depi-sec-app-mahmoud-2026/*`                                    | Provides application-level read access to objects in the specific S3 bucket and nothing else          |

### Security Principle

The EC2 workload uses an IAM role instead of an IAM user and permanent access keys. The role provides temporary credentials that can be rotated automatically, reducing the risk associated with long-lived credentials stored in `user_data` or source code.

### Evidence

| Screenshot                | Description                 |
| ------------------------- | --------------------------- |
| `03-ec2-role-trust.png`   | EC2 role trust relationship |
| `03-s3-custom-policy.png` | Custom S3 policy JSON       |




## Security Group vs Network ACL

Security Groups and Network ACLs provide different layers of network security in AWS. A Security Group is stateful and is associated with network interfaces, so return traffic is automatically allowed when the corresponding outbound or inbound connection is permitted. A Network ACL is stateless and operates at the subnet level, so both inbound and outbound traffic must be explicitly allowed. In this project, Security Groups provide application-tier access control between the ALB, application, database, and EFS tiers, while the custom Network ACL provides an additional subnet-level security layer for the private subnets, including an explicit deny rule for inbound SSH traffic on port 22 and explicit ephemeral port rules for return traffic.


