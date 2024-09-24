resource "aws_vpc" "project_vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "${var.tags}_vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.project_vpc.id

  tags = {
    Name = "${var.tags}_igw"
  }
}

resource "aws_subnet" "public_subnets" {
  count = var.public_subnet_count  
  vpc_id     = aws_vpc.project_vpc.id
  cidr_block = element(var.public_subnet_cidr, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet_${element(data.aws_availability_zones.available.names, count.index)}"
  }
}

resource "aws_subnet" "private_subnets" {
  count = var.private_subnet_count  
  vpc_id     = aws_vpc.project_vpc.id
  cidr_block = element(var.private_subnet_cidr, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name = "private_subnet_${element(data.aws_availability_zones.available.names, count.index)}"
  }
}

resource "aws_nat_gateway" "ng" {
  allocation_id = aws_eip.eip.id
  subnet_id     = element(aws_subnet.public_subnets, 1).id

  tags = {
    Name = "${var.tags}_ng"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_eip" "eip" {
  domain   = "vpc"
}


resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.project_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${var.tags}_public_rt"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.project_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ng.id
  }
  tags = {
    Name = "${var.tags}_private_rt"
  }
}

resource "aws_route_table_association" "pub_subnet_a" {
  count = var.public_subnet_count
  subnet_id      = element(aws_subnet.public_subnets, count.index).id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table_association" "pri_subnet_a" {
  count = var.private_subnet_count
  subnet_id      = element(aws_subnet.private_subnets, count.index).id
  route_table_id = aws_route_table.private_rt.id
}










