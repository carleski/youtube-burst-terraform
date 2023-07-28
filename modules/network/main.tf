resource "aws_vpc" "default" {
  cidr_block = "172.16.0.0/16"
  enable_dns_hostnames = true
  
  tags = {
    Name = "youtube-burst"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id

  tags = {
    Name = "youtube-burst"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = "172.16.10.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true
  enable_resource_name_dns_a_record_on_launch = true

  tags = {
    Name = "public"
  }
}

resource "aws_route_table" "internet" {
  vpc_id  = aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id = aws_internet_gateway.default.id
  }

  tags = {
    Name = "youtube-burst"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.internet.id
}

output "public_subnet_id" {
  value   = aws_subnet.public.id
}

output "vpc_id" {
  value   = aws_vpc.default.id
}