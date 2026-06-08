# Trust policy - lets MSK Connect (kafkaconnect) assume this role
data "aws_iam_policy_document" "trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["kafkaconnect.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "msk_connect" {
  name               = "${var.project_name}-MSKConnectRole"
  assume_role_policy = data.aws_iam_policy_document.trust.json

  tags = {
    Name = "${var.project_name}-MSKConnectRole"
  }
}

# Scoped permissions: read plugin from S3 + write CloudWatch logs.
# (PLAINTEXT/no-auth MSK does not need MSK IAM perms - cluster access is via VPC/SG.)
data "aws_iam_policy_document" "permissions" {
  statement {
    sid     = "ReadPluginFromS3"
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:ListBucket"]
    resources = var.plugin_bucket_arn == "*" ? ["*"] : [
      var.plugin_bucket_arn,
      "${var.plugin_bucket_arn}/*",
    ]
  }

  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "permissions" {
  name   = "${var.project_name}-msk-connect-permissions"
  role   = aws_iam_role.msk_connect.id
  policy = data.aws_iam_policy_document.permissions.json
}
