output "server_security_group_id" {
  description = "ID of the server security group"
  value       = aws_security_group.server.id
}

output "rds_security_group_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.rds.id
}
