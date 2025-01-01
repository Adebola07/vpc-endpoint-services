variable "vpc-cidr" {}
variable "vpc-tag" {}
variable "priv-sub-tag" {}
variable "pub-sub-tag" {}
variable "lb-sub-tag" {}

# Create a VPC
resource "aws_vpc" "my-vpc" {
  cidr_block           = var.vpc-cidr
  enable_dns_hostnames = true
  tags = {
    Name = var.vpc-tag
  }
}

# Create 1 public subnets
resource "aws_subnet" "public-subnets" {
  count                   = 2
  vpc_id                  = aws_vpc.my-vpc.id
  map_public_ip_on_launch = true
  cidr_block              = cidrsubnet(aws_vpc.my-vpc.cidr_block, 8, count.index)
  availability_zone       = element(data.aws_availability_zones.az.names, count.index)

  tags = {
    Name = var.pub-sub-tag
  }

}

# Create 2 private subnets
resource "aws_subnet" "private-subnets" {
  count             = 2
  vpc_id            = aws_vpc.my-vpc.id
  cidr_block        = cidrsubnet(aws_vpc.my-vpc.cidr_block, 8, count.index + 3)
  availability_zone = element(data.aws_availability_zones.az.names, count.index)

  tags = {
    Name = var.priv-sub-tag
  }

}

# Create 2 private subnets
resource "aws_subnet" "lb-subnets" {
  count             = 2
  vpc_id            = aws_vpc.my-vpc.id
  cidr_block        = cidrsubnet(aws_vpc.my-vpc.cidr_block, 8, count.index + 6)
  availability_zone = element(data.aws_availability_zones.az.names, count.index)

  tags = {
    Name = var.lb-sub-tag
  }

}


# Create public subnets route table
resource "aws_route_table" "my-public-rtb" {
  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rtb"
  }
}


# Create public subnets route table association
resource "aws_route_table_association" "public-sub" {
  count          = 2
  subnet_id      = element(aws_subnet.public-subnets[*].id, count.index)
  route_table_id = aws_route_table.my-public-rtb.id
}


# Create internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "demo-igw"
  }
}


resource "aws_eip" "my-eip" {
  domain   = "vpc"

  tags = {
    Name = "staging"
  }
}

resource "aws_nat_gateway" "my-nat" {
  allocation_id = aws_eip.my-eip.id
  subnet_id     = aws_subnet.public-subnets[1].id

  tags = {
    Name = "staging"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "main-rtb" {
  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.my-nat.id
  }

  tags = {
    Name = "staging"
  }
}

resource "aws_route_table_association" "private-sub" {
  count          = 2
  subnet_id      = element(aws_subnet.private-subnets[*].id, count.index)
  route_table_id = aws_route_table.main-rtb.id
}

data "aws_availability_zones" "az" {
  state = "available"
}