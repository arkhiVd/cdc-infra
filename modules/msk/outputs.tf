output "cluster_arn" {
  value = aws_msk_cluster.this.arn
}

output "bootstrap_brokers_plaintext" {
  description = "Plaintext bootstrap broker string (port 9092)"
  value       = aws_msk_cluster.this.bootstrap_brokers
}

output "zookeeper_connect" {
  value = aws_msk_cluster.this.zookeeper_connect_string
}
