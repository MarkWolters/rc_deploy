variable "aws_region" {
  type        = string
  description = "AWS region to deploy into"
  default     = "us-east-1"
}

variable "aws_az" {
  type        = string
  description = "Availability zone for the public subnet"
  default     = "us-east-1a"
}

variable "name_prefix" {
  type        = string
  description = "Prefix for naming AWS resources"
  default     = "jvector-rc"
}

variable "tags" {
  type        = map(string)
  description = "Common tags"
  default = {
    Project = "jvector-rc-testing"
  }
}

variable "vpc_cidr" {
  type        = string
  default     = "10.50.0.0/16"
}

variable "public_subnet_cidr" {
  type        = string
  default     = "10.50.1.0/24"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for all nodes"
  default     = "i4i.4xlarge"
}

variable "cassandra_node_count" {
  type        = number
  default     = 3
}

variable "root_volume_gb" {
  type        = number
  default     = 50
}

variable "client_root_volume_gb" {
  type        = number
  default     = 100
}

# Security group ports requested
variable "allowed_tcp_ports" {
  type        = list(number)
  default     = [22, 80, 443, 9042, 7000, 7001, 9043, 7199]
}

# NOTE: you requested 0.0.0.0/0. This is a security risk.
# Strongly recommended: set to your office/home IP CIDR, or use SSM-only access.
variable "ssh_allowed_cidr" {
  type        = string
  default     = "0.0.0.0/0"
}

variable "ssh_key_name" {
  type        = string
  description = "Name for the AWS EC2 key pair"
  default     = "jvector-rc-key"
}

variable "ssh_public_key_path" {
  type        = string
  description = "Path to your public key file (e.g., ~/.ssh/id_rsa.pub)"
}
