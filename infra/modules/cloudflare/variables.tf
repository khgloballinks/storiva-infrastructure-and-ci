variable "env"         { type = string }
variable "zone_id"     { type = string; sensitive = true }
variable "record_name" { type = string }
variable "ip_address"  { type = string }
variable "ttl"         { type = number; default = 1 }        # 1 = auto when proxied
variable "proxied"     { type = bool;   default = false }    # true = Cloudflare proxy (orange cloud)