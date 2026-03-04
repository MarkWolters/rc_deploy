# Terraform: RC test environment (AWS)

## What it creates
- New VPC + public subnet + IGW + route table
- One security group with requested inbound ports
- 3 Cassandra nodes (i4i.4xlarge)
- 1 test client node (i4i.4xlarge)
- Key pair imported from your provided public key

## Usage
```bash
cd infra/terraform
terraform init
terraform apply -var="ssh_public_key_path=/path/to/id_ed25519.pub"
```

## Notes on SSH access
This skeleton defaults `ssh_allowed_cidr` to `0.0.0.0/0` because you requested it.
Strongly recommended:
- set `-var="ssh_allowed_cidr=<YOUR_PUBLIC_IP>/32"`
- or remove SSH ingress entirely and use AWS SSM Session Manager.


## JMX (7199)
By default, port 7199 is restricted to the VPC CIDR since JMX access is intended to be from inside the VPC.
