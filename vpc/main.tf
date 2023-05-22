# --- vpc/main.tf


resource "random_integer" "random" {
    min=1
    max=100
}
resource "random_shuffle" "az" {
  input        = data.aws_availability_zones.available.names
  result_count = var.max_subnets
}  

data "aws_availability_zones" "available" {}

resource "aws_vpc" "ps_vpc" {
    cidr_block = var.vpc_cidr
    enable_dns_hostnames = true
    enable_dns_support = true

    tags = {
        Name = "ps_vpc-${random_integer.random.id}"
    }
}
resource "aws_subnet" "ps_public_subnet" {
  count = var.public_sn_count
  vpc_id = aws_vpc.ps_vpc.id
  availability_zone = random_shuffle.az.result[count.index]
  cidr_block = var.public_cidrs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "ps_public_${count.index + 1}"
  }
}
resource "aws_route_table_association" "ps_public_association" {
  count = var.public_sn_count
  subnet_id = aws_subnet.ps_public_subnet.*.id[count.index]
  route_table_id = aws_route_table.ps_public_rt.id
}
resource "aws_subnet" "ps_private_subnet" {
  count = var.private_sn_count
  vpc_id = aws_vpc.ps_vpc.id
  availability_zone = random_shuffle.az.result[count.index]
  cidr_block = var.private_cidrs[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "ps_private_${count.index + 1}"
  }
}
resource "aws_internet_gateway" "ps_gw" {
  vpc_id = aws_vpc.ps_vpc.id

  tags = {
    Name = "ps_internet__gateway"
  }
}
  resource "aws_route_table" "ps_public_rt" {
    vpc_id = aws_vpc.ps_vpc.id

    tags = {
      Name = "ps_public_rt"
  }
  }
  resource "aws_route" "default_route" {
    route_table_id = aws_route_table.ps_public_rt.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ps_gw.id
  }
  resource "aws_default_route_table" "ps_private_rt" {
    default_route_table_id = aws_vpc.ps_vpc.default_route_table_id

    tags = {
      Name = "ps_private_rt"
    }
  }

resource "aws_eip" "ps_eip" {
  vpc      = true
}

resource "aws_nat_gateway" "ps_nat_gateway" {
  allocation_id = aws_eip.ps_eip.id
  subnet_id     = aws_subnet.ps_public_subnet.0.id
}

resource "aws_route" "nat_gateway_route" {
  route_table_id         = aws_default_route_table.ps_private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.ps_nat_gateway.id
}

resource "aws_route_table_association" "ps_route_table_association" {
  subnet_id      = aws_subnet.ps_private_subnet.0.id
  route_table_id = aws_default_route_table.ps_private_rt.id
}

  resource "aws_security_group" "public_sg" {
  for_each = var.security_groups
  name        = each.value.name
  description = each.value.description
  vpc_id      = aws_vpc.ps_vpc.id

  dynamic "ingress" {
    for_each = each.value.ingress
  content {
    from_port        = ingress.value.from
    to_port          = ingress.value.to
    protocol         = ingress.value.protocol
    cidr_blocks      = ingress.value.cidr_blocks
  }
    
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Public SSH and HTTP access"
  }
}
resource "aws_security_group" "private_sg" {
  name        = "private_sg"
  description = "SG of private subnet"
  vpc_id      = aws_vpc.ps_vpc.id

  
  ingress {
     
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    security_groups = [aws_security_group.public_sg["public"].id]
  }
    
  

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "HTTP access from LB to instances"
  }
}
