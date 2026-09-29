# Network Architecture

## VPC

The application cloud network uses an Amazon VPC named `depi-sec-app-vpc` with CIDR `10.0.0.0/16`.

DNS support and DNS hostnames are enabled to support AWS service discovery and internal DNS resolution.

## Subnet Design

| Subnet                 | CIDR          | Availability Zone | Type    | Internet Route                 |
| ---------------------- | ------------- | ----------------- | ------- | ------------------------------ |
| `depi-sec-public-az1`  | `10.0.1.0/24` | `us-east-1a`      | Public  | `0.0.0.0/0 → Internet Gateway` |
| `depi-sec-private-az1` | `10.0.2.0/24` | `us-east-1a`      | Private | Local VPC route only           |
| `depi-sec-public-az2`  | `10.0.3.0/24` | `us-east-1b`      | Public  | `0.0.0.0/0 → Internet Gateway` |
| `depi-sec-private-az2` | `10.0.4.0/24` | `us-east-1b`      | Private | Local VPC route only           |

## Routing

Both public subnets are associated with the public route table. The public route table contains the local VPC route and a default route to the Internet Gateway.

Both private subnets are associated with the private route table. The private route table contains only the local VPC route (`10.0.0.0/16 → local`) and has no direct route to an Internet Gateway.

A subnet is considered public based on its routing configuration, not its name or tag.

## Availability Zones

The VPC spans two Availability Zones in `us-east-1` to provide separation across AZs and support a highly available architecture.
