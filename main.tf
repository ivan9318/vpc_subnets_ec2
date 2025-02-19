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
    cidr_blocks = ["0.0.0.0/0"]
  }
}
#Ceamos una ec2 que este a mi subnets
resource "aws_instance" "ec2_public" {
  ami = "ami-053a45fff0a704a47"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.ec2_security.id]
  subnet_id = aws_subnet.subnet_public.id
   associate_public_ip_address = true
   iam_instance_profile = aws_iam_instance_profile.ec2_s3_profile.name
}
resource "aws_instance" "ec2_private" {
  ami = "ami-053a45fff0a704a47"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.ec2_security.id]
  subnet_id = aws_subnet.subnet_privada.id
iam_instance_profile = aws_iam_instance_profile.ec2_s3_profile.name
}
#Creamos un bucket
resource "aws_s3_bucket" "bucket_app" {
  bucket = "bucket-ivan-app"  # El nombre del bucket debe ser único en AWS.
  acl    = "private"  # Puedes cambiar los permisos si lo necesitas.
}
#Creamos una iam policy para nuestro s3
resource "aws_iam_policy" "iam_s3" {
  name        = "s3_bucket_policy"
  description = "Permite acceso a S3 para las EC2"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "s3:*"
        Resource = [
          "arn:aws:s3:::bucket-ivan-app",
          "arn:aws:s3:::bucket-ivan-app/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "ec2_s3" {
  name = "ec2_s3_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_s3_policy" {
  role       = aws_iam_role.ec2_s3.name
  policy_arn = aws_iam_policy.iam_s3.arn
}

resource "aws_iam_instance_profile" "ec2_s3_profile" {
  name = "ec2_s3_instance_profile"
  role = aws_iam_role.ec2_s3.name  # Este es el rol de IAM que ya creaste
}
