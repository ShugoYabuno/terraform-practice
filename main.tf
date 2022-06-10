provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_vpc" "example" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  assign_generated_ipv6_cidr_block = true
  enable_dns_hostnames = true

  tags = {
    Name = "example"
  }
}

resource "aws_subnet" "example" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.0.0/20"
  map_public_ip_on_launch = true

  tags = {
    Name = "example"
  }
}

resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name = "example"
  }
}

resource "aws_route_table" "example" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example.id
  }

  # route {
  #   ipv6_cidr_block        = "::/0"
  #   egress_only_gateway_id = aws_egress_only_internet_gateway.example.id
  # }

  tags = {
    Name = "example"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id = aws_subnet.example.id
  route_table_id = aws_route_table.example.id
}

resource "aws_security_group" "example_ec2" {
  name = "example-ec2"
  vpc_id = aws_vpc.example.id

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

data "aws_ami" "recent_amazon_linux_2" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name = "name"
    values = ["amzn2-ami-hvm-2.0.????????-x86_64-gp2"]
  }

  filter {
    name = "state"
    values = ["available"]
  }
}

resource "aws_instance" "example" {
  ami = data.aws_ami.recent_amazon_linux_2.image_id
  instance_type = "t3.micro"
  subnet_id = aws_subnet.example.id
  vpc_security_group_ids = [aws_security_group.example_ec2.id]

  user_data = file("./user_data.sh")

  tags = {
    Name = "example"
  }
}

output "example_instance_id" {
  value = aws_instance.example.id
}

output "security_group_id" {
  value = aws_security_group.example_ec2.id
}

output "example_public_dns" {
  value = aws_instance.example.public_dns
}
