data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "server" {
  name        = "${var.name_prefix}-server-sg"
  description = "Allow inbound traffic for Storiva environments"
  vpc_id      = data.aws_vpc.default.id

  dynamic "ingress" {
    for_each = var.allowed_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ingress.value == 80 || ingress.value == 443 ? ["0.0.0.0/0"] : var.allowed_ips
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.name_prefix}-server-sg"
    Environment = var.environment
  }
}

resource "aws_security_group" "rds" {
  name        = "${var.name_prefix}-rds-sg"
  description = "Allow inbound PostgreSQL traffic from EC2"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.server.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.name_prefix}-rds-sg"
    Environment = var.environment
  }
}
