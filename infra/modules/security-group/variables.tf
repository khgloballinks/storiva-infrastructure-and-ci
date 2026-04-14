variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name (staging, production)"
  type        = string
}

variable "description" {
  description = "Description for security group"
  type        = string
  default     = ""
}

variable "allowed_ips" {
  description = "List of IPs allowed for SSH and app ports"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_ports" {
  description = "List of ports to allow (80 and 443 always open to all)"
  type        = list(number)
  default     = [22, 80, 443, 8080, 8081]
}
