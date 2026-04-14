output "server_ip" {
  description = "Public IP of the staging server"
  value       = module.ec2.public_ip
}

output "ssh_command" {
  description = "Command to SSH into the staging server"
  value       = module.ec2.ssh_command
}

output "dns_record" {
  description = "Staging DNS record"
  value       = "staging.${var.domain_name} -> ${module.ec2.public_ip}"
}
