output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.server.id
}

output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_eip.server.public_ip
}

output "private_ip" {
  description = "Private IP of the EC2 instance"
  value       = aws_instance.server.private_ip
}

output "ssh_command" {
  description = "Command to SSH into the server"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${aws_eip.server.public_ip}"
}
