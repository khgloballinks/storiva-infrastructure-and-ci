output "server_ip" {
  description = "Public IP of the production server"
  value       = module.ec2.public_ip
}

output "ssh_command" {
  description = "Command to SSH into the production server"
  value       = module.ec2.ssh_command
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = module.rds.endpoint
}

output "dns_records" {
  description = "Production DNS records"
  value = {
    root = "${var.domain_name} -> ${module.ec2.public_ip}"
    www  = "www.${var.domain_name} -> ${module.ec2.public_ip}"
    api  = "api.${var.domain_name} -> ${module.ec2.public_ip}"
  }
}

output "route53_nameservers" {
  description = "Nameservers to set at your registrar"
  value       = module.route53.name_servers
}
