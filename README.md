# cdc-infra

Terraform for a **Change Data Capture (CDC) pipeline** on AWS: stream every
INSERT / UPDATE / DELETE from RDS PostgreSQL into Amazon MSK (Kafka) using a
Debezium connector running on MSK Connect.

```
┌─────────────┐    WAL     ┌──────────────┐   Kafka topic   ┌─────────────┐
│  RDS        │──────────▶ │  Debezium    │────────────────▶│  Consumer   │
│  PostgreSQL │  (stream)  │  (MSK        │  rds.public.*   │  (any app)  │
│             │            │   Connect)   │                 │             │
└─────────────┘            └──────────────┘                 └─────────────┘
```

## What is CDC?

Change Data Capture turns a database into a stream of events. Instead of polling
a table for "what changed", CDC reads the database's own transaction log (the
PostgreSQL write-ahead log / WAL) and emits one event per row change — with the
operation type (`c` create, `u` update, `d` delete) and the before/after values.

Debezium does the log reading; Kafka (MSK) carries the events; any consumer can
subscribe. The source database does no extra work beyond what it already writes
to its WAL.

### Why it's useful

- Sync DB changes to a search index, cache, or data warehouse in real time
- Audit log of every change ever made
- Event-driven microservices that react to DB changes
- Zero-downtime database migrations

## Architecture

A dedicated VPC holds everything. RDS, MSK, and MSK Connect share a single
self-referencing security group, so they reach each other without per-port
rules. An S3 gateway endpoint lets MSK Connect pull the Debezium plugin without
a NAT Gateway.

| Module        | Purpose                                                  |
|---------------|----------------------------------------------------------|
| `networking`  | Dedicated VPC, 2 public subnets (2 AZs), IGW, lab SG, S3 gateway endpoint |
| `iam`         | MSK Connect service execution role (scoped S3 read + CW logs) |
| `rds`         | Parameter group (logical replication) + PostgreSQL instance |
| `msk`         | `kafka.t3.small` cluster, 2 brokers, PLAINTEXT           |
| `msk_connect` | Debezium custom plugin (from S3) + connector             |

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
    ├── networking/         # VPC, subnets, IGW, SG, S3 gateway endpoint
    ├── iam/                # MSK Connect service execution role
    ├── rds/                # parameter group + Postgres instance
    ├── msk/                # Kafka cluster
    └── msk_connect/        # Debezium plugin + connector
```

## Design notes

- **Dedicated VPC** — a `10.20.0.0/16` VPC with two public subnets across two
  AZs (MSK and the RDS subnet group both need multi-AZ). `terraform destroy`
  removes everything cleanly; nothing touches the account default VPC.
- **Self-referencing security group** — MSK, RDS, and MSK Connect all share one
  SG; intra-SG traffic is fully allowed, so they reach each other without
  per-port rules. Optional home-IP rules expose psql (5432) and Kafka (9092).
- **S3 gateway endpoint** — free; lets MSK Connect pull the Debezium plugin ZIP
  from S3 without a NAT Gateway or internet egress.
- **Logical replication** — the RDS parameter group sets
  `rds.logical_replication = 1` (→ `wal_level = logical`), required for Debezium
  to read the write-ahead log.
- **`kafka.t3.small`** — smallest MSK broker; the console blocks it, so it must
  be provisioned via API / Terraform.
- **Self-creating topics** — MSK has `auto.create.topics.enable = false`, so the
  connector creates its topics via Kafka Connect's `topic.creation.*` config.

## Usage

```bash
# One-time
cp terraform.tfvars.example terraform.tfvars   # set db_password
terraform init

# Build / inspect
terraform plan
terraform apply

# Tear down
terraform destroy
```

### Variables

| Name           | Default         | Notes                              |
|----------------|-----------------|------------------------------------|
| `region`       | `us-east-1`     | -                                  |
| `project_name` | `lab`           | prefix for all resource names      |
| `vpc_cidr`     | `10.20.0.0/16`  | CIDR for the dedicated VPC         |
| `my_ip_cidr`   | `""`            | home IP /32 for psql/kafka access  |
| `db_password`  | *(required)*    | RDS master password; set in tfvars |

## Roadmap

- [ ] Remote state: S3 backend + native locking
- [ ] GitHub Actions: `plan.yml` (PR), `apply.yml` (merge), `destroy.yml` (manual)
- [ ] OIDC auth for GitHub Actions (no static keys)
```
