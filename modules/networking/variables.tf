variable "project_name" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_cidr" {
  description = "CIDR block for the dedicated CDC VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "my_ip_cidr" {
  description = "Your home IP in CIDR (e.g. 1.2.3.4/32) for direct psql/kafka access from laptop. Empty = no laptop access."
  type        = string
  default     = ""
}
