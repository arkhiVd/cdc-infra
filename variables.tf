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

variable "vpc_cidr" {
  description = "CIDR block for the dedicated CDC VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "db_password" {
  description = "RDS master password (set in terraform.tfvars)"
  type        = string
  sensitive   = true
}

variable "my_ip_cidr" {
  description = "Home IP CIDR for laptop access to RDS/Kafka (set in terraform.tfvars)"
  type        = string
  default     = ""
}
