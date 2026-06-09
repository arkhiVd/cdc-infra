variable "project_name" {
  type = string
}

variable "region" {
  type = string
}

variable "my_ip_cidr" {
  description = "Your home IP in CIDR (e.g. 1.2.3.4/32) for direct psql/kafka access from laptop. Empty = no laptop access."
  type        = string
  default     = ""
}
