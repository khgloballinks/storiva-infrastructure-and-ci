variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name (staging, production)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for the EC2 instance"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID (empty = auto-detect)"
  type        = string
  default     = ""
}

variable "volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 30
}
