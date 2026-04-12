resource "aws_vpc" "gp-jfrog-vpc" {
    for_each = var.vpc_cidr
    cidr_block = each.value
    tags = {
        Name = "gp-jfrog-vpc"
    }
}

resource "aws_subnet" "gp-jfrog-public-subnet" {
    count = length(var.public_subnet_cidr)
    vpc_id = aws_vpc.gp-jfrog-vpc[0].id
    cidr_block = var.public_subnet_cidr[count.index]
    availability_zone = "${var.region}a"
    tags = {
        Name = "gp-jfrog-public-subnet-${count.index}"
    }
}

resource "aws_subnet" "gp-jfrog-private-subnet" {
    count = length(var.private_subnet_cidr)
    vpc_id = aws_vpc.gp-jfrog-vpc[0].id
    cidr_block = var.private_subnet_cidr[count.index]
    availability_zone = "${var.region}b"
    tags = {
        Name = "gp-jfrog-private-subnet-${count.index}"
    }
}

### Create Internet Gateway and attach to VPC ####
resource "aws_internet_gateway" "gp-jfrog-igw" {
    vpc_id = aws_vpc.gp-jfrog-vpc[0].id
    tags = {
        Name = "gp-jfrog-igw"
    }
}

### Create Route Table for public subnet ######
resource "aws_route_table" "gp-jfrog-public-rt" {
  vpc_id = aws_vpc.gp-jfrog-vpc[0].id
  tags = {
    Name = "gp-jfrog-public-rt"
  }
}

### Create Route Table for private subnet ######
resource "aws_route_table" "gp-jfrog-private-rt" {
  vpc_id = aws_vpc.gp-jfrog-vpc[0].id
  tags = {
    Name = "gp-jfrog-private-rt"
  }
}

