terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# --- Networking (new VPC) ---
resource "aws_vpc" "rc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpc"
  })
}

resource "aws_internet_gateway" "rc" {
  vpc_id = aws_vpc.rc.id
  tags = merge(var.tags, { Name = "${var.name_prefix}-igw" })
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.rc.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.aws_az

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-subnet"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.rc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.rc.id
  }
  tags = merge(var.tags, { Name = "${var.name_prefix}-public-rt" })
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# --- Security group ---
resource "aws_security_group" "rc" {
  name        = "${var.name_prefix}-sg"
  description = "RC test environment SG"
  vpc_id      = aws_vpc.rc.id

  # Inbound: requested open to 0.0.0.0/0 for listed ports
  # Inbound: requested open to 0.0.0.0/0 for listed ports, with an internal-only default for JMX.
  dynamic "ingress" {
    for_each = var.allowed_tcp_ports
    content {
      description = "TCP ${ingress.value}"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      # Special-case JMX (7199): restrict to VPC CIDR by default since you indicated JMX access is inside the VPC.
      cidr_blocks = ingress.value == 7199 ? [var.vpc_cidr] : [var.ssh_allowed_cidr]
    }
  }

  # Outbound: all traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-sg" })
}

# --- SSH key pair ---
resource "aws_key_pair" "rc" {
  key_name   = var.ssh_key_name
  public_key = file(var.ssh_public_key_path)
  tags       = var.tags
}

# --- AMI ---
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# --- Instances ---
locals {
  cassandra_names = [for i in range(var.cassandra_node_count) : "${var.name_prefix}-cassandra-${i + 1}"]
}

resource "aws_instance" "cassandra" {
  count                       = var.cassandra_node_count
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.rc.id]
  key_name                    = aws_key_pair.rc.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp3"
    volume_size = var.root_volume_gb
  }

  tags = merge(var.tags, {
    Name = local.cassandra_names[count.index]
    Role = "cassandra"
  })
}

resource "aws_instance" "client" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.rc.id]
  key_name                    = aws_key_pair.rc.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp3"
    volume_size = var.client_root_volume_gb
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-test-client"
    Role = "test-client"
  })
}
