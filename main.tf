provider "aws" {
  region = "us-east-1"
  secret_key = var.password["secret_key"]
  access_key = var.password["acces_key"]
}
resource "aws_vpc" "vpc_app" {
  cidr_block = var.cidr[0]
  enable_dns_hostnames = true
  enable_dns_support = true
}
resource "aws_subnet" "subnet_public" {
vpc_id = aws_vpc.vpc_app.id
cidr_block = var.cidr[1]
map_public_ip_on_launch = true
}
resource "aws_subnet" "subnet_privada" {
  vpc_id = aws_vpc.vpc_app.id
  cidr_block = var.cidr[2]
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc_app.id

}

resource "aws_route_table" "vpc_gw" {
  vpc_id = aws_vpc.vpc_app.id

  route  {
    gateway_id = aws_internet_gateway.gw.id
    cidr_block = "0.0.0.0/0"
  }
}

resource "aws_route_table_association" "subnet_public" {
  subnet_id      = aws_subnet.subnet_public.id
  route_table_id = aws_route_table.vpc_gw.id
}

#security group
resource "aws_security_group" "ec2_security" {
  # ... other configuration ...
vpc_id = aws_vpc.vpc_app.id
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.cidr[0]]
  }
}
#Ceamos una ec2 que este a mi subnets
resource "aws_instance" "ec2_public" {
  ami = "ami-053a45fff0a704a47"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.ec2_security.id]
  subnet_id = aws_subnet.subnet_public.id
}
resource "aws_instance" "ec2_private" {
  ami = "ami-053a45fff0a704a47"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.ec2_security.id]
  subnet_id = aws_subnet.subnet_privada.id
}