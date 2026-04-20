resource "aws_vpc" "gp-jfrog-vpc" {
    cidr_block = var.vpc_cidr[0]
    tags = {
        Name = "gp-jfrog-vpc"
    }
}

resource "aws_subnet" "gp-jfrog-public-subnet" {
    count = length(var.public_subnet_cidr)
    vpc_id = aws_vpc.gp-jfrog-vpc.id
    cidr_block = var.public_subnet_cidr[count.index]
    availability_zone = var.az[count.index]
    tags = {
        Name = "gp-jfrog-public-subnet-${count.index}"
    }
}

resource "aws_subnet" "gp-jfrog-private-subnet" {
    count = length(var.private_subnet_cidr)
    vpc_id = aws_vpc.gp-jfrog-vpc.id
    cidr_block = var.private_subnet_cidr[count.index]
    availability_zone = var.az[count.index]
    tags = {
        Name = "gp-jfrog-private-subnet-${count.index}"
    }
}

resource "aws_subnet" "gp-jfrog-pgsql-subnet" {
    count = length(var.db_subnet_cidr)
    vpc_id = aws_vpc.gp-jfrog-vpc.id
    cidr_block = var.db_subnet_cidr[count.index]
    availability_zone = var.az[count.index]
    tags = {
        Name = "gp-jfrog-pgsql-subnet-${count.index}"
    }
}
### Create Internet Gateway and attach to VPC ####
resource "aws_internet_gateway" "gp-jfrog-igw" {
    vpc_id = aws_vpc.gp-jfrog-vpc.id
    tags = {
        Name = "gp-jfrog-igw"
    }
}

### Create Route Table for public subnet ######
resource "aws_route_table" "gp-jfrog-public-rt" {
  vpc_id = aws_vpc.gp-jfrog-vpc.id
  tags = {
    Name = "gp-jfrog-public-rt"
  }
}

### Create Route Table for private subnet ######
resource "aws_route_table" "gp-jfrog-private-rt" {
  vpc_id = aws_vpc.gp-jfrog-vpc.id
  tags = {
    Name = "gp-jfrog-private-rt"
  }
}

### Create Route for public subnet to Internet Gateway ######
resource "aws_route" "gp-jfrog-public-route" {
  route_table_id = aws_route_table.gp-jfrog-public-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.gp-jfrog-igw.id
}

resource "aws_route_table_association" "gp-public-rt-assn" {
  count = length(var.public_subnet_cidr)
  subnet_id = aws_subnet.gp-jfrog-public-subnet[count.index].id
  route_table_id = aws_route_table.gp-jfrog-public-rt.id
}

resource "aws_route_table_association" "gp-private-rt-assn" {
  count = length(var.private_subnet_cidr)
  subnet_id = aws_subnet.gp-jfrog-private-subnet[count.index].id
  route_table_id = aws_route_table.gp-jfrog-private-rt.id
}

### Create NAT Gateway for private subnet to access Internet ######
resource "aws_eip" "gp-jfrog-nat-eip" {
  domain = "vpc"
  tags = {
    Name = "gp-jfrog-nat-eip"
  }
}

resource "aws_nat_gateway" "gp-jfrog-nat" {
  allocation_id = aws_eip.gp-jfrog-nat-eip.id
  subnet_id = aws_subnet.gp-jfrog-public-subnet[0].id
  tags = {
    Name = "gp-jfrog-nat"
  }
  depends_on = [aws_internet_gateway.gp-jfrog-igw]
}

resource "aws_route" "gp-jfrog-private-route" {
  route_table_id = aws_route_table.gp-jfrog-private-rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.gp-jfrog-nat.id
}


## Security Group for Bastion

resource "aws_security_group" "gp-jfrog-bastion-sg" {
  name = "gp-jfrog-bastion-sg"
  description = "Security Group for Bastion host"
  vpc_id = aws_vpc.gp-jfrog-vpc.id

  tags = {
    Name = "gp-jfrog-bastion-sg"
  }
}

resource "aws_security_group_rule" "jfrog_bastion_ingress_private" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "TCP"
  cidr_blocks       = ["27.6.92.85/32"]
  security_group_id = aws_security_group.gp-jfrog-bastion-sg.id
}

# Allow egress everywhere (for RDS to reach S3, KMS, etc.)
resource "aws_security_group_rule" "jfrog_bastion_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.gp-jfrog-bastion-sg.id
}