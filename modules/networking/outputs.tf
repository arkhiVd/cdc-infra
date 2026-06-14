output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_ids" {
  value = aws_subnet.public[*].id
}

output "lab_security_group_id" {
  value = aws_security_group.lab.id
}

output "s3_endpoint_id" {
  value = aws_vpc_endpoint.s3.id
}

output "route_table_ids" {
  value = [aws_route_table.public.id]
}
