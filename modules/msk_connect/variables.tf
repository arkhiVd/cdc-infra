variable "project_name" {
  type = string
}

variable "plugin_version" {
  description = "Debezium PostgreSQL connector version"
  type        = string
  default     = "2.7.4.Final"
}

variable "bootstrap_brokers" {
  description = "MSK plaintext bootstrap brokers (port 9092)"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets for the connector (must match the cluster's client subnets / AZs)"
  type        = list(string)
}

variable "security_group_id" {
  type = string
}

variable "service_execution_role_arn" {
  description = "IAM role the connector assumes (MSK Connect role)"
  type        = string
}

variable "db_host" {
  description = "RDS endpoint hostname (no port)"
  type        = string
}

variable "db_port" {
  type    = number
  default = 5432
}

variable "db_user" {
  type    = string
  default = "postgres"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_name" {
  type    = string
  default = "postgres"
}

variable "topic_prefix" {
  description = "Debezium topic prefix -> topics named {prefix}.{schema}.{table}"
  type        = string
  default     = "rds"
}

variable "table_include_list" {
  description = "Comma-separated schema.table list Debezium captures"
  type        = string
  default     = "public.users"
}

variable "kafkaconnect_version" {
  type    = string
  default = "2.7.1"
}
