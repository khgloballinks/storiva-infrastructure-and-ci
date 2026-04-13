provider "aws" {
  region = var.aws_region
}

# Data source for the default VPC
data "aws_vpc" "default" {
  default = true
}

# Data source for the subnets in the default VPC (needed for RDS)
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Data source for the latest Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# Security Group for the EC2 Instance
resource "aws_security_group" "storiva_sg" {
  name        = "storiva-server-sg"
  description = "Allow inbound traffic for Storiva environments"
  vpc_id      = data.aws_vpc.default.id

  # SSH - Restricted by variable
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  # Production Nginx (HTTP/HTTPS) - Open to world
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Dev Environment - Restricted by variable
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  # Staging Environment - Restricted by variable
  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for the RDS Instance
resource "aws_security_group" "rds_sg" {
  name        = "storiva-rds-sg"
  description = "Allow inbound PostgreSQL traffic from EC2"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.storiva_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create Staging EC2 Instance
resource "aws_instance" "staging_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.medium" # Staging doesn't need as much power
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.storiva_sg.id]

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  user_data = <<-EOT
              #!/bin/bash
              apt-get update
              apt-get install -y ca-certificates curl gnupg lsb-release git nginx certbot python3-certbot-nginx
              mkdir -p /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
              apt-get update
              apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
              usermod -aG docker ubuntu
              mkdir -p /srv/myapp
              chown -R ubuntu:ubuntu /srv/myapp
              
              cat << 'EOF_NGINX' > /etc/nginx/sites-available/api
              server {
                  listen 80;
                  server_name staging.${var.domain_name};
                  
                  location / {
                      proxy_pass http://localhost:8080;
                      proxy_set_header Host $host;
                      proxy_set_header X-Real-IP $remote_addr;
                      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                      proxy_set_header X-Forwarded-Proto $scheme;
                  }
              }
              EOF_NGINX
              
              ln -s /etc/nginx/sites-available/api /etc/nginx/sites-enabled/
              rm -f /etc/nginx/sites-enabled/default
              systemctl restart nginx
              EOT

  tags = {
    Name = "Storiva-Staging-Server"
  }
}

# Elastic IP for Staging
resource "aws_eip" "staging_eip" {
  instance = aws_instance.staging_server.id
  domain   = "vpc"
}

# Create Production EC2 Instance
resource "aws_instance" "prod_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.large"
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.storiva_sg.id]

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
  }

  user_data = <<-EOT
              #!/bin/bash
              apt-get update
              apt-get install -y ca-certificates curl gnupg lsb-release git nginx certbot python3-certbot-nginx
              mkdir -p /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
              apt-get update
              apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
              usermod -aG docker ubuntu
              mkdir -p /srv/myapp
              chown -R ubuntu:ubuntu /srv/myapp

              cat << 'EOF_NGINX' > /etc/nginx/sites-available/api
              server {
                  listen 80;
                  server_name api.${var.domain_name};
                  
                  location / {
                      proxy_pass http://localhost:8080;
                      proxy_set_header Host $host;
                      proxy_set_header X-Real-IP $remote_addr;
                      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                      proxy_set_header X-Forwarded-Proto $scheme;
                  }
              }
              EOF_NGINX
              
              ln -s /etc/nginx/sites-available/api /etc/nginx/sites-enabled/
              rm -f /etc/nginx/sites-enabled/default
              systemctl restart nginx
              EOT

  tags = {
    Name = "Storiva-Prod-Server"
  }
}

# Elastic IP for Prod
resource "aws_eip" "prod_eip" {
  instance = aws_instance.prod_server.id
  domain   = "vpc"
}

# DB Subnet Group for RDS
resource "aws_db_subnet_group" "storiva" {
  name       = "storiva-db-subnet-group"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name = "Storiva DB Subnet Group"
  }
}

# Provision RDS PostgreSQL Database (Production)
resource "aws_db_instance" "storiva_db" {
  identifier             = "storiva-prod-db"
  allocated_storage      = 20
  max_allocated_storage  = 100
  storage_type           = "gp3"
  engine                 = "postgres"
  engine_version         = "16"
  instance_class         = "db.t3.micro"
  db_name                = "storiva_prod"
  username               = "postgres"
  password               = var.db_password
  parameter_group_name   = "default.postgres16"
  skip_final_snapshot    = true
  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.storiva.name

  tags = {
    Name = "Storiva Production DB"
  }
}

# Route53 Zone Data Source
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

# DNS Records
resource "aws_route53_record" "prod" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = "300"
  records = [aws_eip.prod_eip.public_ip]
}

resource "aws_route53_record" "prod_www" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"
  ttl     = "300"
  records = [aws_eip.prod_eip.public_ip]
}

resource "aws_route53_record" "prod_api" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "api.${var.domain_name}"
  type    = "A"
  ttl     = "300"
  records = [aws_eip.prod_eip.public_ip]
}

resource "aws_route53_record" "staging" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "staging.${var.domain_name}"
  type    = "A"
  ttl     = "300"
  records = [aws_eip.staging_eip.public_ip]
}
