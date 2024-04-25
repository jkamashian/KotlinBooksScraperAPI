# Fetching existing VPC
data "aws_vpc" "main" {
  id = var.vpc_id
}

resource "aws_subnet" "public" {
  vpc_id     = data.aws_vpc.main.id
  cidr_block = var.aws_subnet_public_cidr
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_1" {
  vpc_id     = data.aws_vpc.main.id
  cidr_block = var.aws_subnet_private_1_cidr
}
resource "aws_subnet" "private_2" {
  vpc_id            = data.aws_vpc.main.id
  cidr_block        = var.aws_subnet_private_2_cidr
  map_public_ip_on_launch = false
}


# Data source to fetch the existing internet gateway
data "aws_internet_gateway" "gw" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.main.id]
  }
}


resource "aws_eip" "nat" {}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  depends_on    = [data.aws_internet_gateway.gw]
}

resource "aws_route_table" "public" {
  vpc_id = data.aws_vpc.main.id

  route {
    cidr_block = var.aws_route_table_public_cidr
    gateway_id = data.aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = data.aws_vpc.main.id

  route {
    cidr_block = var.aws_route_table_private_cidr
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}