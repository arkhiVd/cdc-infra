output "msk_connect_role_arn" {
  value = aws_iam_role.msk_connect.arn
}

output "msk_connect_role_name" {
  value = aws_iam_role.msk_connect.name
}
