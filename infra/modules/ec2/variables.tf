variable "env"              { type = string }
variable "vpc_id"           { type = string }
variable "subnet_id"        { type = string }
variable "instance_type"    { type = string; default = "t3.small" }
variable "key_name"         { type = string }
variable "ssh_allowed_cidr" { type = string; default = "0.0.0.0/0" }