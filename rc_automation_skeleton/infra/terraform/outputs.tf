output "vpc_id" {
  value = aws_vpc.rc.id
}

output "security_group_id" {
  value = aws_security_group.rc.id
}

output "cassandra_public_ips" {
  value = [for i in aws_instance.cassandra : i.public_ip]
}

output "cassandra_private_ips" {
  value = [for i in aws_instance.cassandra : i.private_ip]
}

output "client_public_ip" {
  value = aws_instance.client.public_ip
}

output "client_private_ip" {
  value = aws_instance.client.private_ip
}
