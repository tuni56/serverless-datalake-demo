output "workgroup_name" {
  description = "Nombre del Athena Workgroup"
  value       = aws_athena_workgroup.main.name
}

output "workgroup_id" {
  description = "ID del Athena Workgroup"
  value       = aws_athena_workgroup.main.id
}
