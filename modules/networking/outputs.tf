output "vpc_id" {
  value = data.aws_vpc.default.id
}

output "subnet_ids" {
  value = data.aws_subnets.default.ids
}

output "lab_security_group_id" {
  value = aws_security_group.lab.id
}

output "s3_endpoint_id" {
  value = aws_vpc_endpoint.s3.id
}

output "route_table_ids" {
  value = data.aws_route_tables.default.ids
}
