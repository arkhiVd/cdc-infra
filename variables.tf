variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix for resource names"
  type        = string
  default     = "lab"
}

variable "db_password" {
  description = "RDS master password (set in terraform.tfvars)"
  type        = string
  sensitive   = true
}
