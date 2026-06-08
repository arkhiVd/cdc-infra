output "endpoint" {
  description = "RDS endpoint hostname (no port)"
  value       = aws_db_instance.this.address
}

output "endpoint_with_port" {
  value = aws_db_instance.this.endpoint
}

output "db_name" {
  value = aws_db_instance.this.db_name
}

output "username" {
  value = aws_db_instance.this.username
}
