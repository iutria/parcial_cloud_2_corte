terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version : "~>3.0"
    }
  }
}

provider "aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

//creando la vpc con nombre vpc_parcial
resource "aws_vpc" "vpc_parcial" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "vpc_parcial"
  }
}

//creando las subredes
resource "aws_subnet" "public_1" {
  vpc_id            = aws_vpc.vpc_parcial.id
  availability_zone = "us-east-2a"
  cidr_block        = "10.0.1.0/24"
  tags = {
    Name = "subnet_public_1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id            = aws_vpc.vpc_parcial.id
  availability_zone = "us-east-2b"
  cidr_block        = "10.0.2.0/24"
  tags = {
    Name = "subnet_public_2"
  }
}

//creando el internet gateway
resource "aws_internet_gateway" "gw_parcial" {
  vpc_id = aws_vpc.vpc_parcial.id

  tags = {
    Name = "gw_parcial"
  }
}

//creando tabla de rutas
resource "aws_route_table" "rt_parcial" {
  vpc_id = aws_vpc.vpc_parcial.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw_parcial.id
  }

  tags = {
    Name = "rt_parcial"
  }
}

//creando asociacion de la subred a la tabla de rutas
resource "aws_route_table_association" "rta_test_subnet_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.rt_parcial.id
}

resource "aws_route_table_association" "rta_test_subnet_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.rt_parcial.id
}

//creando grupo de seguridad
resource "aws_security_group" "sg_parcial" {
  name        = "sg_parcial"
  description = "Grupo de seguridad"
  vpc_id      = aws_vpc.vpc_parcial.id

  tags = {
    Name = "sg_parcial"
  }
}

//regla de seguridad
resource "aws_security_group_rule" "rsg_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.sg_parcial.id
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_security_group_rule" "rsg_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.sg_parcial.id
  cidr_blocks       = ["0.0.0.0/0"]
}

//instancias
resource "aws_instance" "ec2_instance_1" {
  ami                         = "ami-09b90e09742640522"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_1.id
  vpc_security_group_ids      = [aws_security_group.sg_parcial.id]
  associate_public_ip_address = true
}

resource "aws_instance" "ec2_instance_2" {
  ami                         = "ami-09b90e09742640522"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_2.id
  vpc_security_group_ids      = [aws_security_group.sg_parcial.id]
  associate_public_ip_address = true
}