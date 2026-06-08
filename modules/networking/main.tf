# Use the account's default VPC instead of creating one
data "aws_vpc" "default" {
  default = true
}

# All subnets in the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Main route table of the default VPC (needed for S3 gateway endpoint)
data "aws_route_tables" "default" {
  vpc_id = data.aws_vpc.default.id
}

# Dedicated lab security group with a self-referencing rule.
# Lets MSK, RDS, EC2, and MSK Connect all talk to each other freely
# as long as they share this SG.
resource "aws_security_group" "lab" {
  name        = "${var.project_name}-cdc-sg"
  description = "CDC lab - self referencing, all intra-SG traffic"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "${var.project_name}-cdc-sg"
  }
}

# Allow all traffic between members of this SG
resource "aws_security_group_rule" "self_ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.lab.id
  description       = "Intra-SG all traffic"
}

# Allow all outbound
resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lab.id
  description       = "All outbound"
}

# S3 Gateway Endpoint - free, routes S3 traffic internally.
# MSK Connect uses this to pull the Debezium plugin without NAT/internet.
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = data.aws_vpc.default.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = data.aws_route_tables.default.ids

  tags = {
    Name = "${var.project_name}-s3-gw"
  }
}
