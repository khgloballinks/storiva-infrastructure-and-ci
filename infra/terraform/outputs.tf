output "staging_server_ip" {
  description = "The public Elastic IP of the Staging EC2 server"
  value       = module.ec2_staging.public_ip
}

output "prod_server_ip" {
  description = "The public Elastic IP of the Production EC2 server"
  value       = module.ec2_production.public_ip
}

output "ssh_command_staging" {
  description = "Command to SSH into the staging server"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${module.ec2_staging.public_ip}"
}

output "ssh_command_prod" {
  description = "Command to SSH into the production server"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${module.ec2_production.public_ip}"
}

output "rds_endpoint" {
  description = "The endpoint of the RDS PostgreSQL instance"
  value       = module.rds.endpoint
}

output "route53_nameservers" {
  description = "Nameservers for the hosted zone"
  value       = module.route53.name_servers
}

output "dns_records" {
  description = "DNS records summary"
  value = {
    root    = var.domain_name
    www     = "www.${var.domain_name}"
    api     = "api.${var.domain_name}"
    staging = "staging.${var.domain_name}"
  }
}
