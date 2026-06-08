# cdc-infra

Terraform for a **Change Data Capture (CDC) pipeline** on AWS: stream every
INSERT / UPDATE / DELETE from RDS PostgreSQL into Amazon MSK (Kafka) using a
Debezium connector running on MSK Connect.

```
┌─────────────┐    WAL     ┌──────────────┐   Kafka topic   ┌─────────────┐
│  RDS        │──────────▶│  Debezium    │────────────────▶│  Consumer   │
│  PostgreSQL │  (stream)  │  (MSK        │  rds.public.*   │  (any app)  │
│             │            │   Connect)   │                 │             │
└─────────────┘            └──────────────┘                 └─────────────┘
```

Built as a cheap, teardown-friendly lab (~$0.20/hr while running). Uses the
account's **default VPC** + a public EC2 bastion (SSM) instead of a VPN/NAT
Gateway to keep cost minimal.

## Why CDC?

- Sync DB changes to a search index, cache, or data warehouse in real time
- Audit log of every change ever made
- Event-driven microservices that react to DB changes
- Zero-downtime database migrations

## Status

Built module by module, applied + verified one at a time.

| Module        | Purpose                                           | Status |
|---------------|---------------------------------------------------|--------|
| `networking`  | Default VPC data source, lab SG, S3 gw endpoint   | ✅ done |
| `iam`         | `MSKConnectRole` (scoped S3 read + CW logs)       | ✅ done |
| `rds`         | Param group (logical replication) + PostgreSQL 18 | 🚧 next |
| `msk`         | `kafka.t3.small` cluster, 2 brokers, PLAINTEXT    | ⬜ todo |
| `msk_connect` | Debezium custom plugin + connector                | ⬜ todo |
| `bastion`     | t2.micro test client via SSM                      | ⬜ todo |

## Layout

```
cdc-infra/
├── providers.tf            # AWS provider, default tags
├── variables.tf            # region, project_name, db_password
├── main.tf                 # module wiring
├── outputs.tf              # top-level outputs
├── terraform.tfvars        # secrets (gitignored)
├── terraform.tfvars.example
└── modules/
    ├── networking/         # SG (self-referencing) + S3 gateway endpoint
    ├── iam/                # MSK Connect service execution role
    └── rds/                # parameter group + Postgres instance
```

## Design notes

- **Default VPC via data source** — Terraform never creates or destroys the
  VPC / subnets / route tables / IGW. `terraform destroy` only removes
  lab-created resources.
- **Self-referencing security group** — MSK, RDS, EC2, MSK Connect all share
  one SG; intra-SG traffic is fully allowed, so they reach each other without
  per-port rules.
- **S3 gateway endpoint** — free; lets MSK Connect pull the Debezium plugin ZIP
  from S3 without a NAT Gateway or internet egress.
- **Logical replication** — RDS parameter group sets
  `rds.logical_replication = 1` (→ `wal_level = logical`), required for
  Debezium to read the write-ahead log.
- **`kafka.t3.small`** — cheapest MSK broker; the console blocks it, so it must
  be provisioned via API / Terraform.

## Usage

```bash
# One-time
cp terraform.tfvars.example terraform.tfvars   # set db_password
terraform init

# Build / inspect
terraform plan
terraform apply

# Tear down (default VPC infra is untouched)
terraform destroy
```

### Variables

| Name           | Default       | Notes                               |
|----------------|---------------|-------------------------------------|
| `region`       | `us-east-1`   | -                                   |
| `project_name` | `lab`         | prefix for all resource names       |
| `db_password`  | *(required)*  | RDS master password; set in tfvars  |

## Cost (while running)

| Resource                     | Approx.        |
|------------------------------|----------------|
| MSK `kafka.t3.small` × 2     | ~$0.08/hr      |
| MSK Connect 1 MCU × 1 worker | ~$0.11/hr      |
| RDS `db.t4g.micro`           | ~$0.016/hr     |
| EC2 `t2.micro`               | free tier      |
| **Total**                    | **~$0.20/hr**  |

> ⚠️ Lab resources cost money. Run `terraform destroy` when done.

## Roadmap

- [ ] Finish `rds`, `msk`, `msk_connect`, `bastion` modules
- [ ] Remote state: S3 backend + DynamoDB lock table
- [ ] GitHub Actions: `plan.yml` (PR), `apply.yml` (merge), `destroy.yml` (manual)
- [ ] OIDC auth for GitHub Actions (no static keys)
