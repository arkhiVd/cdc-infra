variable "project_name" {
  type = string
}

variable "subnet_ids" {
  description = "Subnets for brokers - one per broker, must match number_of_broker_nodes"
  type        = list(string)
}

variable "security_group_id" {
  type = string
}

variable "kafka_version" {
  type    = string
  default = "3.7.x"
}

variable "instance_type" {
  description = "Cheapest broker - console blocks t3.small, API/TF allows it"
  type        = string
  default     = "kafka.t3.small"
}

variable "broker_count" {
  type    = number
  default = 2
}

variable "broker_volume_size" {
  description = "EBS GiB per broker"
  type        = number
  default     = 1
}
