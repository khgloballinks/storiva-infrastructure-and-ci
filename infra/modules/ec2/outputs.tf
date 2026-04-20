output "instance_id" {
  value = aws_instance.this.id
}

output "public_ip" {
  description = "Elastic IP attached to the EC2 instance"
  value       = aws_eip.this.public_ip
}

output "security_group_id" {
  description = "EC2 security group ID"
  value       = aws_security_group.ec2.id   
}