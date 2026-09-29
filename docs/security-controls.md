# Security Controls

## Tiered Security Group Architecture

The application uses four Security Groups to enforce tier-to-tier network access.

```text
Internet
   |
   | TCP 80
   v
depi-sec-alb-sg
   |
   | TCP 80
   | Source: ALB Security Group
   v
depi-sec-app-sg
   |
   +------------------+
   |                  |
   | TCP 3306         | TCP 2049
   |                  |
   v                  v
depi-sec-db-sg    depi-sec-efs-sg
```

## Security Group Rules

| Security Group    | Protocol / Port | Allowed Source     | Purpose                                               |
| ----------------- | --------------- | ------------------ | ----------------------------------------------------- |
| `depi-sec-alb-sg` | TCP 80          | `0.0.0.0/0`        | Allow public HTTP traffic to the load balancer        |
| `depi-sec-app-sg` | TCP 80          | ALB Security Group | Allow application traffic only from the load balancer |
| `depi-sec-db-sg`  | TCP 3306        | App Security Group | Allow database traffic only from application servers  |
| `depi-sec-efs-sg` | TCP 2049        | App Security Group | Allow NFS traffic only from application servers       |

## Least Privilege

The ALB Security Group is the only group that accepts inbound traffic from the internet. Application, database, and EFS access is restricted using Security Group references instead of broad CIDR ranges.

No Security Group allows inbound TCP port 22. EC2 administration will use AWS Systems Manager Session Manager instead of exposing SSH to the network.

Security Group rules are defined using `aws_vpc_security_group_ingress_rule`, with one Terraform resource per inbound rule.
