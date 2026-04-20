resource "aws_security_group" "rds" {
  name   = "storiva-${var.env}-rds-sg"
  vpc_id = var.vpc_id

  # Only allow traffic from EC2 security group(s)
  ingress {
    description     = "Postgres from EC2"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.allowed_sg_ids
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "storiva-${var.env}-rds-sg"
  }
}

resource "aws_db_subnet_group" "this" {
  name       = "storiva-${var.env}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "storiva-${var.env}-db-subnet-group"
  }
}

resource "aws_db_instance" "this" {
  identifier = "storiva-${var.env}-postgres"

  engine         = "postgres"
  engine_version = var.engine_version

  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage
  storage_type      = "gp3"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible = false

  multi_az = var.multi_az

  backup_retention_period   = var.backup_retention_period
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = "storiva-${var.env}-final-snapshot"

  storage_encrypted = true

  tags = {
    Name = "storiva-${var.env}-rds"
    Env  = var.env
  }
}