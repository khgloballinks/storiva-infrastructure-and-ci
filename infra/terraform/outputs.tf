output "staging_server_ip" {
  description = "The public Elastic IP of the Staging EC2 server"
  value       = aws_eip.staging_eip.public_ip
}

output "prod_server_ip" {
  description = "The public Elastic IP of the Prod EC2 server"
  value       = aws_eip.prod_eip.public_ip
}

output "ssh_command_staging" {
  description = "Command to SSH into the staging server locally"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${aws_eip.staging_eip.public_ip}"
}

output "ssh_command_prod" {
  description = "Command to SSH into the prod server locally"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${aws_eip.prod_eip.public_ip}"
}

output "rds_endpoint" {
  description = "The endpoint of the RDS PostgreSQL instance (Use this for PROD_DB_HOST secret)"
  value       = aws_db_instance.storiva_db.endpoint
}
output "route53_nameservers" {
  description = "Point your domain registrar to these nameservers"
  value       = aws_route53_zone.main.name_servers
}
