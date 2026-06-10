output "plugin_bucket" {
  description = "S3 bucket holding the Debezium plugin ZIP"
  value       = aws_s3_bucket.plugins.id
}

output "plugin_bucket_arn" {
  value = aws_s3_bucket.plugins.arn
}

output "custom_plugin_arn" {
  value = aws_mskconnect_custom_plugin.debezium.arn
}

output "connector_arn" {
  value = aws_mskconnect_connector.debezium.arn
}

output "connector_name" {
  value = aws_mskconnect_connector.debezium.name
}
