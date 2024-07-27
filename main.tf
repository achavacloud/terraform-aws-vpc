provider "aws" {
  region = var.region
}

resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames
  tags                 = var.tags
}

#Internet Gateway allows communication between the VPC and the internet. It enables instances in public subnets to access the internet and allows internet users to reach instances with public IP addresses.
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = var.tags
}

#Public subnets are subnets with a route to the internet. Instances in these subnets can be accessed from the internet and can also communicate with the internet if assigned a public IP address. Public subnets are typically used for resources that need to be accessible from the internet, such as web servers.
resource "aws_subnet" "public_subnet" {
  count                   = var.public_subnet_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.public_subnet_cidrs, count.index)
  map_public_ip_on_launch = true
  availability_zone       = element(var.availability_zones, count.index % length(var.availability_zones))
  tags                    = merge(var.tags, { "Name" = format("%s-public-%d", var.name, count.index) })
}

#Private subnets do not have a direct route to the internet, making them secure and suitable for resources that should not be exposed directly to the internet, such as databases or application servers. These subnets can access the internet via a NAT Gateway if needed for tasks like downloading updates.
resource "aws_subnet" "private_subnet" {
  count                   = var.private_subnet_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.private_subnet_cidrs, count.index)
  map_public_ip_on_launch = false
  availability_zone       = element(var.availability_zones, count.index % length(var.availability_zones))
  tags                    = merge(var.tags, { "Name" = format("%s-private-%d", var.name, count.index) })
}

#NAT Gateway allows instances in a private subnet to initiate outbound traffic to the internet (for example, to download updates) while preventing the internet from initiating inbound connections to those instances. This is crucial for maintaining security while allowing necessary outbound communication.
resource "aws_nat_gateway" "nat" {
  count         = var.private_subnet_count > 0 ? 1 : 0
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = element(aws_subnet.public_subnet[*].id, 0)
  tags          = merge(var.tags, { "Name" = "${var.name}-nat" })
}

#Elastic IP (EIP) is a static, public IP address allocated for your AWS account. It is required for the NAT Gateway to communicate with the internet. The NAT Gateway uses this IP to route traffic to and from the internet.
resource "aws_eip" "nat_eip" {
  count = var.private_subnet_count > 0 ? 1 : 0
}

#route table contains a set of rules (routes) that determine how traffic should be directed. The public route table includes a route that directs internet-bound traffic (0.0.0.0/0) to the Internet Gateway, enabling internet access for instances in public subnets.
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = merge(var.tags, { "Name" = "${var.name}-public-rt" })
}

#private route table directs traffic destined for the internet (0.0.0.0/0) to the NAT Gateway, allowing instances in private subnets to access the internet for outbound requests, while keeping them secure from direct inbound internet traffic.
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[0].id
  }
  tags = merge(var.tags, { "Name" = "${var.name}-private-rt" })
}

#Association ensures that instances in the public subnets use the public route table, which directs traffic to the Internet Gateway.
resource "aws_route_table_association" "public_subnet_rta" {
  count          = var.public_subnet_count
  subnet_id      = element(aws_subnet.public_subnet[*].id, count.index)
  route_table_id = aws_route_table.public_rt.id
}

#Association ensures that instances in the private subnets use the private route table, which directs traffic to the NAT Gateway for outbound internet access.
resource "aws_route_table_association" "private_subnet_rta" {
  count          = var.private_subnet_count
  subnet_id      = element(aws_subnet.private_subnet[*].id, count.index)
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_security_group" "public_sg" {
  name        = "${var.name}-public-sg"
  description = "Security group for public subnets"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { "Name" = "${var.name}-public-sg" })
}

resource "aws_security_group" "private_sg" {
  name        = "${var.name}-private-sg"
  description = "Security group for private subnets"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { "Name" = "${var.name}-private-sg" })
}

resource "aws_network_acl" "public_nacl" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.tags, { "Name" = "${var.name}-public-nacl" })

  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  egress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }
}

resource "aws_network_acl" "private_nacl" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.tags, { "Name" = "${var.name}-private-nacl" })

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.0.0.0/32"
    from_port  = 22
    to_port    = 22
  }

  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}