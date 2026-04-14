data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = var.subnet_id != "" ? var.subnet_id : data.aws_subnets.default.ids[0]

  vpc_security_group_ids = [var.security_group_id]

  root_block_device {
    volume_size = var.volume_size
    volume_type = "gp3"
  }

  user_data = file("${path.module}/../../scripts/userdata-${var.environment}.sh")

  tags = {
    Name        = "${var.name_prefix}-server"
    Environment = var.environment
  }
}

resource "aws_eip" "server" {
  instance = aws_instance.server.id
  domain   = "vpc"
}
