variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "Main domain name for the application (e.g., storiva.com)"
  type        = string
}

variable "key_name" {
  description = "Name of the SSH key pair in AWS to access the EC2 instance"
  type        = string
}

variable "allowed_ips" {
  description = "List of IPs allowed to access SSH, Dev, and Staging ports"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Change this to restrict access
}

variable "db_password" {
  description = "Password for the RDS PostgreSQL database"
  type        = string
  sensitive   = true
}
