variable "region" {
  default = "ap-southeast-1"
  type=string
}
variable "instance_type" {
  default = "t3a.micro"
  type=string
}
variable "key_name" {
  default = "key_name"
  type=string
}
variable "workspace_volume_id" {
  default = "vol-xxxxxxxxxx"
  type=string
}

variable "availability_zone" {
  default = "ap-southeast-1a" 
  type=string
}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.55.0"
    }
  }

  required_version = ">= 1.2.0, < 2.0.0"
}

provider "aws" {
  region = var.region
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "dev_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  availability_zone = var.availability_zone
  vpc_security_group_ids = [ aws_security_group.dev_server_sg.id ]
  key_name = var.key_name

  tags = {
    Name = "dev-server"
  }

  # Attach a new GP3 volume with 10GB to the instance
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    delete_on_termination = true
  }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = var.workspace_volume_id
  instance_id = aws_instance.dev_server.id

  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = file("${var.key_name}.pem")
    host = aws_instance.dev_server.public_ip
  }

  provisioner "remote-exec" {
    script = "setup_ubuntu.sh"
  }
}

output "ec2ip" {
  value = aws_instance.dev_server.public_ip
}

resource "aws_security_group" "dev_server_sg" {
  name        = "dev_server_sg"

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dev_server"
  }
}
