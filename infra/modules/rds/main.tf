resource "aws_security_group" "rds" {
  name   = "storiva-${var.env}-rds-sg"
  vpc_id = var.vpc_id

  ingress {
    description     = "Postgres from EC2"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.allowed_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "storiva-${var.env}-rds-sg" }
}

resource "aws_db_subnet_group" "this" {
  name       = "storiva-${var.env}-db-subnet-group"
  subnet_ids = var.private_subnet_ids
  tags       = { Name = "storiva-${var.env}-db-subnet-group" }
}

resource "aws_db_instance" "this" {
  identifier              = "storiva-${var.env}-postgres"
  engine                  = "postgres"
  engine_version          = "15.5"
  instance_class          = var.instance_class
  allocated_storage       = var.allocated_storage
  storage_type            = "gp3"
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  multi_az                = false
  publicly_accessible     = false
  skip_final_snapshot     = false
  final_snapshot_identifier = "storiva-${var.env}-final-snapshot"
  deletion_protection     = true
  backup_retention_period = 7

  tags = { Name = "storiva-${var.env}-rds" }
}