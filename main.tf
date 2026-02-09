terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# AWS Provider for Mumbai Region
provider "aws" {
  region = var.aws_region
}

# Security Group
resource "aws_security_group" "instance_sg" {
  name        = "${var.instance_name}-sg"
  description = "Security group for EC2 instance in ap-south-1"
  vpc_id      = var.vpc_id

  # SSH Access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }

  # HTTP Access
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS Access
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound traffic
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.instance_name}-sg"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Region      = "ap-south-1"
  }
}

# EC2 Instance
resource "aws_instance" "app_server" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = var.subnet_id

  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  root_block_device {
    volume_size           = var.volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  user_data = <<-EOF
              #!/bin/bash
              # Update system
              sudo apt update -y
              sudo apt upgrade -y
              
              # Install Nginx
              sudo apt install -y nginx
              
              # Create custom homepage
              echo "<h1>Instance deployed in Mumbai (ap-south-1) via Jenkins & Terraform</h1>" > /var/www/html/index.html
              echo "<p>Region: ap-south-1</p>" >> /var/www/html/index.html
              echo "<p>Managed by: Terraform + Jenkins</p>" >> /var/www/html/index.html
              
              # Start and enable Nginx
              sudo systemctl start nginx
              sudo systemctl enable nginx
              EOF

  tags = {
    Name        = var.instance_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    DeployedBy  = "Jenkins"
    Region      = "ap-south-1"
  }
}
