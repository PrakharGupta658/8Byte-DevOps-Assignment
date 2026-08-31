output "db_endpoint" {
  description = "RDS endpoint hostname (without port)"
  value       = aws_db_instance.postgres.address
}

output "db_instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.postgres.identifier
}

output "security_group_id" {
  description = "RDS security group ID"
  value       = aws_security_group.rds.id
}
