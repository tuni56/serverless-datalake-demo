output "quicksight_role_arn" {
  value = aws_iam_role.quicksight.arn
}

output "data_source_arn" {
  value = aws_quicksight_data_source.athena.arn
}
