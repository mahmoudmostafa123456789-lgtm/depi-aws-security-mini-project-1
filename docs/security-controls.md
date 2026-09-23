## Task 5 — Security Groups

The application network uses a tiered Security Group design based on least privilege.

### Security Group Chain

```text
Internet
   |
   | HTTP 80
   v
ALB Security Group
   |
   | HTTP 80
   v
Application Security Group
   |
   +---- MySQL 3306 ----> Database Security Group
   |
   +---- NFS 2049 ------> EFS Security Group
```

### Security Group Rules

| Security Group    | Inbound Traffic | Source            | Purpose                                             |
| ----------------- | --------------- | ----------------- | --------------------------------------------------- |
| `depi-sec-alb-sg` | TCP 80          | `0.0.0.0/0`       | Public HTTP access to the ALB                       |
| `depi-sec-app-sg` | TCP 80          | `depi-sec-alb-sg` | Allow application traffic only from the ALB         |
| `depi-sec-db-sg`  | TCP 3306        | `depi-sec-app-sg` | Allow database access only from application servers |
| `depi-sec-efs-sg` | TCP 2049        | `depi-sec-app-sg` | Allow NFS access only from application servers      |

### Security Controls

* Only the ALB Security Group accepts HTTP traffic from the Internet.
* Application servers accept HTTP only from the ALB Security Group.
* Database access is restricted to the Application Security Group.
* EFS access is restricted to the Application Security Group.
* No Security Group allows inbound SSH traffic on port 22.
* Security Group references are used instead of subnet CIDR ranges for tier-to-tier access.
* Each inbound rule is defined using `aws_vpc_security_group_ingress_rule` as a separate Terraform resource.
