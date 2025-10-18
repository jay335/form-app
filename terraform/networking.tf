# --- VPC ---
resource "aws_vpc" "app_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true        # Fixed typo: was enable_dns_hostname
  enable_dns_support   = true
  tags = {
    Name = "form-app-vpc"
  }
}

# --- Availability zones (Data Source) ---
data "aws_availability_zones" "available" {
  state = "available"
}

# --- Public Subnets ---
resource "aws_subnet" "public" {
  count                   = 2
  cidr_block              = "10.0.${count.index + 8}.0/24"
  vpc_id                  = aws_vpc.app_vpc.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]  # Use count.index instead of count
  map_public_ip_on_launch = true

  tags = {
    Name = "form-app-public-subnet-${count.index + 1}"  # Use count.index
  }
}

# --- Private Subnets ---
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = "10.0.${count.index + 10}.0/24"  # Use count.index
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "form-app-private-subnet-${count.index + 1}"  # Use count.index
  }
}

# --- Internet Gateway ---
resource "aws_internet_gateway" "app_igw" {
  vpc_id = aws_vpc.app_vpc.id
  tags = {
    Name = "form-app-igw"   # Fixed typo: twsiags -> tags
  }
}

# --- Elastic IP for NAT Gateway ---
resource "aws_eip" "nat_gateway_eip" {
  domain = "vpc"                # Changed from domain = "vpc", either works; domain is preferred now
  depends_on = [aws_internet_gateway.app_igw]  # Fixed typo: aws_intiernet_gateway.app -> aws_internet_gateway.app_igw
  tags = {
    Name = "form-app-nat-eip"
  }
}

# --- NAT Gateway ---
resource "aws_nat_gateway" "app_nat_gateway" {
  allocation_id = aws_eip.nat_gateway_eip.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "form-app-nat-gateway"
  }
}

# --- Public Route Table ---
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"   # Fixed typo: cidr_bock -> cidr_block
    gateway_id = aws_internet_gateway.app_igw.id
  }

  tags = {
    Name = "form-app-public-rt"
  }
}

# --- Private Route Table ---
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.app_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.app_nat_gateway.id
  }

  tags = {
    Name = "form-app-private-rt"
  }
}

# --- Route Table Associations ---
resource "aws_route_table_association" "public_association" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_association" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}

# --- Security Group for ALB ---
resource "aws_security_group" "alb_sg" {
  name   = "form-app-alb-sg"
  vpc_id = aws_vpc.app_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Security Group for Frontend Fargate Task ---
resource "aws_security_group" "frontend_sg" {
  name   = "form-app-frontend-sg"
  vpc_id = aws_vpc.app_vpc.id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

# --- Security Group for Backend Fargate Task ---
resource "aws_security_group" "backend_sg" {
  name   = "form-app-backend-sg"
  vpc_id = aws_vpc.app_vpc.id

  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

# Allow ALB to access backend container port (5000)
resource "aws_security_group_rule" "backend_inbound_from_alb" {
  type                     = "ingress"
  from_port                = 5000
  to_port                  = 5000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.backend_sg.id
  source_security_group_id = aws_security_group.alb_sg.id
}

