variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_az" {
  type    = string
  default = "us-east-1a"
}

variable "name_prefix" {
  type    = string
  default = "jvector-rc"
}

variable "tags" {
  type = map(string)
  default = {
    Project = "jvector-rc-testing"
  }
}

variable "vpc_cidr" {
  type    = string
  default = "10.50.0.0/16"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.50.1.0/24"
}

variable "instance_type" {
  type    = string
  default = "i4i.4xlarge"
}

variable "cassandra_node_count" {
  type    = number
  default = 3
}

variable "root_volume_gb" {
  type    = number
  default = 50
}

variable "client_root_volume_gb" {
  type    = number
  default = 100
}

variable "ssh_allowed_cidr" {
  type    = string
  default = "0.0.0.0/0"
}

variable "ssh_key_name" {
  type    = string
  default = "jvector-rc-key"
}

variable "ssh_public_key_path" {
  type = string
}
