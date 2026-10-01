resource "aws_vpc" "myvpc" {
  cidr_block           = var.vpc_cidr
  tags = merge(var.tags, {
    Name = "${var.name}-vpc"
  })
}


# ------------------
# Internet Gateway
# Required for the public subnets and NAT Gateway
# ------------------

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id

  tags = merge(var.tags, {
    Name = "${var.name}-igw"
  })
}


# 'count' creates one subnet for each CIDR entry.
# The 'index' associates each subnet with a matching availability zone.
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.name}-public-${count.index + 1}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name = "${var.name}-private-${count.index + 1}"
    Tier = "application"
  })
}

resource "aws_subnet" "database" {
  count = length(var.db_subnet_cidrs)

  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = var.db_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name = "${var.name}-db-${count.index + 1}"
    Tier = "database"
  })
}


# ------------------
# Elastic IP for NAT Gateway
# ------------------

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name}-nat-eip"
  })
}


# ------------------
# NAT Gateway
# Must be placed in a PUBLIC subnet
# ------------------

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  depends_on = [
    aws_internet_gateway.igw
  ]

  tags = merge(var.tags, {
    Name = "${var.name}-nat"
  })
}


# ------------------
# Public Route Table
# Public subnets -> Internet Gateway
# ------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(var.tags, {
    Name = "${var.name}-public-rt"
  })
}


# ------------------
# Public Route Table Associations
# ------------------

resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}


# ------------------
# Private Route Table
# Private application subnets -> NAT Gateway
# ------------------

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = merge(var.tags, {
    Name = "${var.name}-private-rt"
  })
}


# ------------------
# Private Route Table Associations
# ------------------

resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidrs)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}


# ------------------
# Database Route Table
# Database subnets do NOT need a NAT Gateway.
# They only need local VPC connectivity.
# ------------------

resource "aws_route_table" "database" {
  vpc_id = aws_vpc.myvpc.id

  tags = merge(var.tags, {
    Name = "${var.name}-db-rt"
  })
}


# ------------------
# Database Route Table Associations
# ------------------

resource "aws_route_table_association" "database" {
  count = length(var.db_subnet_cidrs)

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}