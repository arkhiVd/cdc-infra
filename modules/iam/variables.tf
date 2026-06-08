variable "project_name" {
  type = string
}

variable "plugin_bucket_arn" {
  description = "ARN of the S3 bucket holding the Debezium plugin (scopes S3 access)"
  type        = string
  default     = "*"
}
