resource "aws_msk_cluster" "this" {
  cluster_name           = "${var.project_name}-kafka"
  kafka_version          = var.kafka_version
  number_of_broker_nodes = var.broker_count

  broker_node_group_info {
    instance_type   = var.instance_type
    client_subnets  = slice(var.subnet_ids, 0, var.broker_count)
    security_groups = [var.security_group_id]

    storage_info {
      ebs_storage_info {
        volume_size = var.broker_volume_size
      }
    }
  }

  # PLAINTEXT (port 9092) - lab simplicity, no TLS/IAM auth.
  encryption_info {
    encryption_in_transit {
      client_broker = "PLAINTEXT"
      in_cluster    = false
    }
  }

  tags = {
    Name = "${var.project_name}-kafka"
  }
}
