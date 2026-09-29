# DEPI AWS Security Mini Project 1

## Secure AWS Cloud Infrastructure with Terraform

This project focuses on designing and deploying a secure AWS cloud infrastructure using Terraform.

The project covers:

* AWS Cloud Architecture
* IAM and access control
* VPC and network security
* Security Groups and NACLs
* VPC Endpoints
* EC2
* S3
* RDS
* Application Load Balancer
* CloudFront
* Logging and monitoring
* Backup and security controls

The infrastructure is managed as Infrastructure as Code using Terraform.





## Cost Governance as a Security Control

The monthly AWS budget is implemented as a security control, not only as a financial monitoring mechanism. A budget notification can alert the team when spending increases, but the budget action provides an automatic preventive response. When the monthly cost reaches 90% of the $10 threshold, AWS Budgets automatically applies the `depi-sec-deny-expensive` IAM policy to the protected IAM group. This policy denies the creation of new EC2 instances and RDS database instances. This helps limit the impact of compromised credentials or unauthorized activity that could create additional AWS resources and increase costs.


## IAM Identity and Least Privilege

| Identity               | What it can do                                               | Why                                                                                                                |
| ---------------------- | ------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------ |
| `depi-dev-1`           | Read-only access through the `depi-sec-developers` group     | Developers receive only the permissions required for their role without direct user policies                       |
| `depi-sec-developers`  | AWS `ReadOnlyAccess`                                         | Provides read-only visibility without allowing resource modification                                               |
| `depi-sec-ec2-role`    | SSM management and `s3:GetObject` for the application bucket | Allows EC2 to be managed securely through SSM and read required application objects without long-lived access keys |
| `depi-sec-s3-app-read` | `s3:GetObject` only on the application bucket objects        | Limits S3 access to the specific operation and resource required by the application                                |


