provider "aws" {
  region = "eu-north-1"

}

# Use existing VPC
data "aws_vpc" "existing" {
  id = "vpc-061d9b91dafe6dc32"
}

# Create Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = data.aws_vpc.existing.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-north-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-Subnet"
  }
}

# Internet Gateway (only one!)
resource "aws_internet_gateway" "igw" {
  vpc_id = data.aws_vpc.existing.id

  tags = {
    Name = "VPC-IGW"
  }
}

# Route Table (only one!)
resource "aws_route_table" "public_rt" {
  vpc_id = data.aws_vpc.existing.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public-RT"
  }
}

# Associate Route Table with Subnet (only one!)
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Security Group
resource "aws_security_group" "app_sg" {
  vpc_id = data.aws_vpc.existing.id
  name   = "app-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "App-SG"
  }
}

# EC2 Instance
resource "aws_instance" "ec2" {
  ami           = "ami-0a716d3f3b16d290c" # Amazon Linux 2 (eu-north-1)
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public_subnet.id

  vpc_security_group_ids = [aws_security_group.app_sg.id]
  key_name               = "key" # Ensure this key exists in AWS

  associate_public_ip_address = true

  tags = {
    Name = "terraform-EC2"
  }
}

