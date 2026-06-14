data "aws_caller_identity" "current" {}

locals {
  bucket_name = "${var.project_name}-msk-plugins-${data.aws_caller_identity.current.account_id}"
  plugin_key  = "debezium-postgres-${var.plugin_version}.zip"
}

# ----------------------------------------------------------------------------
# S3 bucket - holds the Debezium plugin ZIP that MSK Connect downloads.
# (Pulled via the S3 gateway endpoint, no NAT / internet needed.)
# ----------------------------------------------------------------------------
resource "aws_s3_bucket" "plugins" {
  bucket        = local.bucket_name
  force_destroy = true

  tags = {
    Name = local.bucket_name
  }
}

# Build the Debezium plugin ZIP locally and upload it.
# Debezium ships a tar.gz of JARs; MSK Connect wants a flat ZIP of that folder.
resource "null_resource" "plugin" {
  triggers = {
    version = var.plugin_version
    bucket  = aws_s3_bucket.plugins.id
    key     = local.plugin_key
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      set -euo pipefail
      BUILD="${path.module}/.build"
      rm -rf "$BUILD"; mkdir -p "$BUILD"
      cd "$BUILD"
      URL="https://repo1.maven.org/maven2/io/debezium/debezium-connector-postgres/${var.plugin_version}/debezium-connector-postgres-${var.plugin_version}-plugin.tar.gz"
      echo "Downloading $URL"
      curl -fsSL -o plugin.tar.gz "$URL"
      tar xzf plugin.tar.gz
      zip -r -q "${local.plugin_key}" debezium-connector-postgres
      aws s3 cp "${local.plugin_key}" "s3://${aws_s3_bucket.plugins.id}/${local.plugin_key}"
      echo "Uploaded s3://${aws_s3_bucket.plugins.id}/${local.plugin_key}"
    EOT
  }
}

# ----------------------------------------------------------------------------
# Custom plugin - registers the uploaded ZIP with MSK Connect.
# ----------------------------------------------------------------------------
resource "aws_mskconnect_custom_plugin" "debezium" {
  name         = "${var.project_name}-debezium-postgres"
  content_type = "ZIP"

  location {
    s3 {
      bucket_arn = aws_s3_bucket.plugins.arn
      file_key   = local.plugin_key
    }
  }

  depends_on = [null_resource.plugin]
}

# ----------------------------------------------------------------------------
# Log group - connector worker logs.
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "connector" {
  name              = "/msk-connect/${var.project_name}-debezium"
  retention_in_days = 1
}

# ----------------------------------------------------------------------------
# Connector - the running Debezium CDC engine.
# ----------------------------------------------------------------------------
resource "aws_mskconnect_connector" "debezium" {
  name                 = "${var.project_name}-debezium-postgres-cdc"
  kafkaconnect_version = var.kafkaconnect_version

  capacity {
    provisioned_capacity {
      mcu_count    = 1
      worker_count = 1
    }
  }

  connector_configuration = {
    "connector.class"                = "io.debezium.connector.postgresql.PostgresConnector"
    "tasks.max"                      = "1"
    "database.hostname"              = var.db_host
    "database.port"                  = tostring(var.db_port)
    "database.user"                  = var.db_user
    "database.password"              = var.db_password
    "database.dbname"                = var.db_name
    "topic.prefix"                   = var.topic_prefix
    "plugin.name"                    = "pgoutput"
    "table.include.list"             = var.table_include_list
    "slot.name"                      = "debezium"
    "publication.autocreate.mode"    = "filtered"
    "key.converter"                  = "org.apache.kafka.connect.json.JsonConverter"
    "value.converter"                = "org.apache.kafka.connect.json.JsonConverter"
    "key.converter.schemas.enable"   = "false"
    "value.converter.schemas.enable" = "false"

    # Debezium self-creates topics (KIP-158). MSK broker has
    # auto.create.topics.enable=false, so without this the producer hits
    # UNKNOWN_TOPIC_OR_PARTITION. Replication factor must be <= broker count.
    "topic.creation.enable"                     = "true"
    "topic.creation.default.replication.factor" = "2"
    "topic.creation.default.partitions"         = "1"
    "topic.creation.default.cleanup.policy"     = "delete"
  }

  kafka_cluster {
    apache_kafka_cluster {
      bootstrap_servers = var.bootstrap_brokers

      vpc {
        security_groups = [var.security_group_id]
        subnets         = slice(var.subnet_ids, 0, 2)
      }
    }
  }

  kafka_cluster_client_authentication {
    authentication_type = "NONE"
  }

  kafka_cluster_encryption_in_transit {
    encryption_type = "PLAINTEXT"
  }

  plugin {
    custom_plugin {
      arn      = aws_mskconnect_custom_plugin.debezium.arn
      revision = aws_mskconnect_custom_plugin.debezium.latest_revision
    }
  }

  service_execution_role_arn = var.service_execution_role_arn

  log_delivery {
    worker_log_delivery {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.connector.name
      }
    }
  }
}
