variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "domain_name" {
  description = "Main domain name (e.g., storivainc.com)"
  type        = string
  default     = "storivainc.com"
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
  default     = "storiva-key"
}

variable "allowed_ips" {
  description = "List of IPs allowed for SSH and app ports"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "staging_instance_type" {
  description = "Staging EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "staging_volume_size" {
  description = "Staging root volume size in GB"
  type        = number
  default     = 30
}

variable "prod_instance_type" {
  description = "Production EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "prod_volume_size" {
  description = "Production root volume size in GB"
  type        = number
  default     = 50
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "RDS maximum allocated storage in GB"
  type        = number
  default     = 100
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "storiva_prod"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}
