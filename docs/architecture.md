# AWS VPC Architecture

## VPC

| Component          | Configuration              |
| ------------------ | -------------------------- |
| VPC Name           | `depi-sec-app-vpc`         |
| CIDR               | `10.0.0.0/16`              |
| DNS Support        | Enabled                    |
| DNS Hostnames      | Enabled                    |
| Availability Zones | `us-east-1a`, `us-east-1b` |

## Subnet Design

| Subnet               | CIDR           | Availability Zone | Type    | Public IP |
| -------------------- | -------------- | ----------------- | ------- | --------- |
| `depi-sec-public-1`  | `10.0.1.0/24`  | `us-east-1a`      | Public  | Enabled   |
| `depi-sec-public-2`  | `10.0.2.0/24`  | `us-east-1b`      | Public  | Enabled   |
| `depi-sec-private-1` | `10.0.11.0/24` | `us-east-1a`      | Private | Disabled  |
| `depi-sec-private-2` | `10.0.12.0/24` | `us-east-1b`      | Private | Disabled  |

## Routing

### Public Route Table

The public route table is associated with both public subnets.

```text
10.0.0.0/16 → local
0.0.0.0/0   → Internet Gateway
```

### Private Route Table

The private route table is associated with both private subnets.

```text
10.0.0.0/16 → local
```

The private route table has no route to the Internet Gateway.

## Security Design

A subnet is considered public because its route table contains a route to an Internet Gateway. The private subnets do not have an Internet Gateway route, so they are isolated from direct Internet access.

The network is distributed across two Availability Zones to improve availability and provide separation between the two zones.

