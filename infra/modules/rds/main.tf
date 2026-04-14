data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.name_prefix}-db-subnet-group"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name        = "Storiva DB Subnet Group"
    Environment = var.environment
  }
}

resource "aws_db_instance" "main" {
  identifier             = "storiva-prod-db"
  allocated_storage      = var.allocated_storage
  max_allocated_storage  = var.max_allocated_storage
  storage_type           = "gp3"
  engine                 = "postgres"
  engine_version         = var.engine_version
  instance_class         = var.instance_class
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = "default.postgres${split(".", var.engine_version)[0]}"
  skip_final_snapshot    = true
  publicly_accessible    = false
  vpc_security_group_ids = [var.security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  tags = {
    Name        = "Storiva Production DB"
    Environment = var.environment
  }
}
