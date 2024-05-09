module "base_label" {
  source    = "cloudposse/label/null"
  version   = "0.25.0"
  namespace = "ll"
}



# main.tf

# Define input variables
variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  default     = "10.0.0.0/16" # Default value, feel free to change
}

variable "aws_region" {
  description = "The AWS region"
  default     = "us-east-1" # Default value, feel free to change
}

# Provider configuration
provider "aws" {
  region = var.aws_region
}

# VPC resource
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = var.vpc_name
  }
}

# Public and Private Subnets
module "subnets" {
  source = "hashicorp/subnets/cidr"
  version = "1.0.0"

  availability_zones = ["${var.aws_region}a"]
  vpc_cidr_block     = var.vpc_cidr_block
  number_of_subnets  = 2
  newbits            = 8
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = module.subnets.cidr_blocks[0]
  availability_zone = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.vpc_name}-public"
  }
}

# Private Subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = module.subnets.cidr_blocks[1]
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "${var.vpc_name}-private"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}-igw"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "${var.vpc_name}-public-rt"
  }
}

# Associate Public Subnet with Public Route Table
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Output
output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "private_subnet_id" {
  value = aws_subnet.private.id
}
hcl
Copy code
# variables.tf

variable "vpc_name" {
  description = "Name of the VPC"
  default     = "my-vpc" # Default value, feel free to change
}
hcl
Copy code
# outputs.tf

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = aws_subnet.private.id
}
