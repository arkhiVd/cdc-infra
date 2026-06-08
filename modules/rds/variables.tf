variable "project_name" {
  type = string
}

variable "subnet_ids" {
  description = "Subnets for the DB subnet group"
  type        = list(string)
}

variable "security_group_id" {
  description = "Lab security group"
  type        = string
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "engine_version" {
  type    = string
  default = "18.3"
}

variable "parameter_group_family" {
  type    = string
  default = "postgres18"
}

variable "instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "publicly_accessible" {
  description = "Lab convenience - direct psql from laptop"
  type        = bool
  default     = true
}
