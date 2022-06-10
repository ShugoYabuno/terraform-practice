variable "instance_type" {}


resource "aws_vpc" "default" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  assign_generated_ipv6_cidr_block = true
  enable_dns_hostnames = true

  tags = {
    Name = "default"
  }
}

resource "aws_subnet" "default" {
  vpc_id     = aws_vpc.default.id
  cidr_block = "10.0.0.0/20"
  map_public_ip_on_launch = true

  tags = {
    Name = "default"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id

  tags = {
    Name = "default"
  }
}

resource "aws_route_table" "default" {
  vpc_id = aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default.id
  }

  # route {
  #   ipv6_cidr_block        = "::/0"
  #   egress_only_gateway_id = aws_egress_only_internet_gateway.default.id
  # }

  tags = {
    Name = "default"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id = aws_subnet.default.id
  route_table_id = aws_route_table.default.id
}

resource "aws_security_group" "default" {
  name = "default-ec2"
  vpc_id = aws_vpc.default.id

  ingress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "default" {
  ami = "ami-0c3fd0f5d33134a76"
  instance_type = var.instance_type
  subnet_id = aws_subnet.default.id
  vpc_security_group_ids = [aws_security_group.default.id]

  user_data = <<EOF
  #! /bin/bash
  yum install -y httpd
  systemctl start httpd.service
  EOF

  tags = {
    Name = "default"
  }
}

output "public_dns" {
  value = aws_instance.default.public_dns
}
