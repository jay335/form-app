resource "aws_vpc" "app_vpc" {
   cidr_block = "10.0.0.0/16"
   enable_dns_hostname = true
   enable_dns_support = true
   tags = { Name = "form-app-vpc" }
}

#---Availability zones (Data Source)
data "aws_availability_zones" "available" {
	state = "available"
}

#---subnets
#public subnets in two different availability zones

resource "aws_subnet" "public" {
	count  = 2 
	vpc_id = aws_vpc.app_vpc.id
        availability_zone = data.availability_zones.available.names[count]
        map_public_ip_launch = true

       tags = {
        Name = "form-app-public-subnet-${count + 1}"
   }
}

# Private subnets in two different availability zones
resource "aws_subnet" "private" {
      count = 2
      vpc_id = aws_vpc.app_vpc.id
      cidr_block = "10.0.${count+10}.0/24"
      availability_zone = data.availability_zones.names[count]

      tags = {
	 Name = "form-app-private-subnet-${count + 1}"
	}

}

# --- Internet Gateway (IGW)

resource "aws_internet_gateway" "app_igw" {
	vpc_id = aws_vpc.app_vpc.id
       twsiags = {
         Name = "form-app-igw"
   }
}

#---Elastic Ip for Nat Gateway
resource "aws_eip" "nat_gateway_eip" {
   vpc = true
   depends_on = [aws_internet_gateway.app.igw]
   tags = {
    Name = "form-app-nat-eip"
 }

#Nat Gateway

resource "aws_nat_gateway" "app_nat_gateway" {

  allocation_id = aws_eip.nat_gateway_eip.id
  subnet_id = aws_subnet.public[0].id

  tags = {
    Name = "form-app-nat-gateway"
 }
}


#route tables 
resource "aws_route_tables" "public_route_table" {

    vpc_id = aws_vpc.app_vpc.id
    route {
      cidr_bock = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.app_igw.id
   }

   tags = {

    Name = "form-app-public-rt"
  }
}

#private route table for NAT Gateway
 
resource "aws_route_tables" "private_route_table" {

   vpc_id = aws_vpc.app_vpc.id
   route {
     cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.app_nat_gateway.id
  }

   tags = {
    Name = "form-app-private-rt"
  }

}


# --- Route Table Associations
# Associate public subnets with the public route table.
resource "aws_route_table_association" "public_association" {
  count          = 2
  subnet_id      = aws_subnet.public[count].id
  route_table_id = aws_route_table.public_route_table.id
}

# Associate private subnets with the private route table.
resource "aws_route_table_association" "private_association" {
  count          = 2
  subnet_id      = aws_subnet.private[count].id
  route_table_id = aws_route_table.private_route_table.id
}

# Security group for the ALB, allowing internet access
resource "aws_security_group" "alb_sg" {
  name        = "form-app-alb-sg"
  vpc_id      = aws_vpc.app_vpc.id

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

# Security group for the Frontend Fargate task
resource "aws_security_group" "frontend_sg" {
  name        = "form-app-frontend-sg"
  vpc_id      = aws_vpc.app_vpc.id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
}

# Security group for the Backend Fargate task
resource "aws_security_group" "backend_sg" {
  name        = "form-app-backend-sg"
  vpc_id      = aws_vpc.app_vpc.id

  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_sg.id]
  }
}

