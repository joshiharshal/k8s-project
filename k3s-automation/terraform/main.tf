terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "ap-south-1"
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

resource "aws_instance" "app_server" {
  ami           = "ami-0f918f7e67a3323f0"
  instance_type = "t3.large"
  vpc_security_group_ids = [aws_security_group.TF_SG.id]
  key_name = "devops"

  root_block_device {
    volume_type = "gp3"
    volume_size = 50
  }

  tags = {
    Name = "Harshal-server"
  }
}

resource "aws_security_group" "TF_SG" {
  name        = "new-security-group-ec2"
  description = "Allow web and SSH access"
  vpc_id      = "vpc-06472eb98932e554e"

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

   ingress {
    description = "Kubernetes API Server"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0


    
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "EC2-SG"
  }
}

resource "cloudflare_record" "root_domain" {
  zone_id = var.cloudflare_zone_id
  name    = "@"
  value   = aws_instance.app_server.public_ip
  type    = "A"
  ttl     = 1
  proxied = true
}

resource "local_file" "inventory" {
  filename = "/home/harshal/Tasks/k3s/k3s-automation/ansible/inventory.ini"
  content  = <<-EOT
    [server]
    ${aws_instance.app_server.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=/home/harshal/Downloads/devops.pem
  EOT
}

output "instance_public_ip" {
  value = aws_instance.app_server.public_ip
}  

output "portfolio_url" {
  value = "http://joshiharshal.cloud"
}
