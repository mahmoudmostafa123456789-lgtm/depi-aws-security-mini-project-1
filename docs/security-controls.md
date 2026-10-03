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




## Task 10 — S3 Buckets That Cannot Leak

Two Amazon S3 buckets are deployed:

* `depi-sec-app-<random-suffix>`
* `depi-sec-logs-<random-suffix>`

Both buckets implement the following security controls:

### Public Access Protection

S3 Block Public Access is enabled with all four controls:

* `BlockPublicAcls = true`
* `BlockPublicPolicy = true`
* `IgnorePublicAcls = true`
* `RestrictPublicBuckets = true`

This prevents the buckets from being exposed through public ACLs or public bucket policies.

### Versioning

Bucket Versioning is enabled on both buckets to preserve previous object versions.

### Encryption

Both buckets use server-side encryption with SSE-S3 (`AES256`) by default.

### Secure Transport

Each bucket has a bucket policy that explicitly denies all S3 actions when `aws:SecureTransport` is `false`.

This ensures that requests using insecure transport are denied.

### Lifecycle Protection

Noncurrent object versions are configured to:

* Transition to Glacier after 30 days.
* Expire after 365 days.

### Validation

A public-access operation was attempted from the S3 Console and was refused because S3 Block Public Access is enabled.

The bucket policy was also verified to contain the `DenyInsecureTransport` statement.

### Security Principle

S3 Block Public Access protects against unintended public exposure, but it does not replace IAM authorization.

An authenticated IAM identity can still access objects when its IAM permissions allow actions such as `s3:GetObject`.
