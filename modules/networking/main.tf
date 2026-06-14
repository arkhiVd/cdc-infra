# Dedicated VPC for the CDC lab (no longer the account default VPC).
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Two AZs - MSK and the RDS subnet group both need a multi-AZ subnet set.
data "aws_availability_zones" "available" {
  state = "available"
}

# Public subnets, one per AZ. Public so the laptop can reach RDS directly
# and so MSK Connect can pull the plugin via the S3 gateway endpoint.
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-${count.index}"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Single public route table - default route to the IGW.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Dedicated lab security group with a self-referencing rule.
# Lets MSK, RDS, EC2, and MSK Connect all talk to each other freely
# as long as they share this SG.
resource "aws_security_group" "lab" {
  name        = "${var.project_name}-cdc-sg"
  description = "CDC lab - self referencing, all intra-SG traffic"
  vpc_id      = aws_vpc.main.id

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

# Optional laptop access - psql (5432) + kafka (9092) from your home IP.
# Only created when my_ip_cidr is set.
resource "aws_security_group_rule" "laptop_postgres" {
  count             = var.my_ip_cidr == "" ? 0 : 1
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = [var.my_ip_cidr]
  security_group_id = aws_security_group.lab.id
  description       = "psql from laptop"
}

resource "aws_security_group_rule" "laptop_kafka" {
  count             = var.my_ip_cidr == "" ? 0 : 1
  type              = "ingress"
  from_port         = 9092
  to_port           = 9092
  protocol          = "tcp"
  cidr_blocks       = [var.my_ip_cidr]
  security_group_id = aws_security_group.lab.id
  description       = "kafka plaintext from laptop"
}

# S3 Gateway Endpoint - free, routes S3 traffic internally.
# MSK Connect uses this to pull the Debezium plugin without NAT/internet.
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.public.id]

  tags = {
    Name = "${var.project_name}-s3-gw"
  }
}
