variable "env" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "key_name" {
  type = string
}
variable "ssh_allowed_cidr" {
  type        = string
  description = "CIDR for SSH access — must be your IP e.g. 1.2.3.4/32"
  # ✅ NO default — forces caller to always set it

  validation {
    condition     = can(cidrhost(var.ssh_allowed_cidr, 0))
    error_message = "Must be a valid CIDR e.g. 1.2.3.4/32"
  }
}
variable "volume_size" {
  type    = number
  default = 20
}

variable "internet_gateway_id" {
  description = "IGW ID — ensures EIP is allocated after gateway exists"
  type        = string
}