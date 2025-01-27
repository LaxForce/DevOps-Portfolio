# modules/vpc/main.tf
# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true # Required for EKS
  enable_dns_support   = true # Required for EKS

  tags = {
    Name = "${var.project_name}-vpc"
    "kubernetes.io/cluster/${var.project_name}-cluster" = "shared"
  }
}

# Public Subnets - where NAT Gateway and other public resources will live
resource "aws_subnet" "public" {
  count             = length(var.azs) # Creates one subnet per AZ
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)  # Calculates subnet CIDR automatically
  availability_zone = var.azs[count.index]
  
  map_public_ip_on_launch = true # Auto-assign public IPs

  tags = {
    Name = "${var.project_name}-public-${count.index + 1}"
    "kubernetes.io/cluster/${var.project_name}-cluster" = "shared"
    "kubernetes.io/role/elb"                           = "1"  # For EKS public load balancers
  }
}

# Private Subnets - where EKS nodes will run
resource "aws_subnet" "private" {
  count             = length(var.azs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + length(var.azs))
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${var.project_name}-private-${count.index + 1}"
    "kubernetes.io/cluster/${var.project_name}-cluster" = "shared"
    "kubernetes.io/role/internal-elb"                   = "1"  # For EKS internal load balancers
  }
}

# Internet Gateway - allows public subnets to access internet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# NAT Gateway - allows private subnets to access internet through public subnet
resource "aws_eip" "nat" {
  domain = "vpc" # Required for NAT Gateway

  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id # Place NAT Gateway in first public subnet

  tags = {
    Name = "${var.project_name}-nat"
  }

  depends_on = [aws_internet_gateway.main] # IGW must exist first
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id # Route public traffic through IGW
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Add private route table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id # Route traffic through NAT Gateway
  }

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

# Associate route tables with subnets
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
