# Custom parameter group - enables logical replication (required for CDC/Debezium).
# rds.logical_replication=1 sets wal_level=logical. Needs a reboot to apply.
resource "aws_db_parameter_group" "this" {
  name        = "${var.project_name}-postgres18"
  family      = var.parameter_group_family
  description = "CDC lab - logical replication enabled"

  parameter {
    name         = "rds.logical_replication"
    value        = "1"
    apply_method = "pending-reboot"
  }

  tags = {
    Name = "${var.project_name}-postgres18"
  }
}

# DB subnet group from the default VPC subnets
resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-db-subnets"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.project_name}-db-subnets"
  }
}

resource "aws_db_instance" "this" {
  identifier     = "${var.project_name}-database-1"
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage = 20
  storage_type      = "gp2"
  storage_encrypted = true

  db_name  = "postgres"
  username = "postgres"
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.security_group_id]
  publicly_accessible    = var.publicly_accessible
  parameter_group_name   = aws_db_parameter_group.this.name

  # Lab settings - skip the slow/expensive bits
  multi_az                = false
  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false
  apply_immediately       = true

  tags = {
    Name = "${var.project_name}-database-1"
  }
}
