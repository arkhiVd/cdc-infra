output "vpc_id" {
  description = "Default VPC ID"
  value       = module.networking.vpc_id
}

output "subnet_ids" {
  description = "Subnet IDs in default VPC"
  value       = module.networking.subnet_ids
}

output "lab_security_group_id" {
  description = "Lab security group (self-referencing)"
  value       = module.networking.lab_security_group_id
}

output "s3_endpoint_id" {
  description = "S3 gateway endpoint ID"
  value       = module.networking.s3_endpoint_id
}

output "msk_connect_role_arn" {
  description = "MSK Connect service execution role ARN"
  value       = module.iam.msk_connect_role_arn
}

output "rds_endpoint" {
  description = "RDS endpoint hostname"
  value       = module.rds.endpoint
}

output "msk_bootstrap_brokers" {
  description = "MSK plaintext bootstrap brokers (port 9092)"
  value       = module.msk.bootstrap_brokers_plaintext
}

output "msk_cluster_arn" {
  value = module.msk.cluster_arn
}

output "plugin_bucket" {
  description = "S3 bucket holding the Debezium plugin ZIP"
  value       = module.msk_connect.plugin_bucket
}

output "connector_name" {
  value = module.msk_connect.connector_name
}

output "connector_arn" {
  value = module.msk_connect.connector_arn
}
