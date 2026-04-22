output "vpc_id" {
  value = aws_vpc.main.id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "private_subnet_azs" {
  value = aws_subnet.private[*].availability_zone
}

output "vpc_endpoints_security_group_id" {
  value = aws_security_group.vpc_endpoints.id
}

output "glue_endpoint_id" {
  value = aws_vpc_endpoint.glue.id
}

output "s3_endpoint_id" {
  value = aws_vpc_endpoint.s3.id
}
