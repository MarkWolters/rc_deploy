# RC Automation Skeleton v8

This is the official MVP automation bundle for the demo.

Included:
- AWS Terraform for a 3-node Cassandra cluster plus 1 test client
- Security groups split correctly between operator access and cluster-internal traffic
- NVMe detect / format / mount on Cassandra nodes
- Cassandra clone, build, config patch, and systemd service
- Seed-first serial Cassandra startup for reliable ring formation
- Cassandra health gate requiring 3 x UN before proceeding
- Test client provisioning with Java 25
- NoSQLBench cloned from main and built with Maven
- desktop-file-utils installed for the NoSQLBench AppImage-related build step
- rc_deploy cloned from main
- test suite discovery and helper scripts
- clean rc_up.sh summary for demo presentation

## Prereqs on the control host
- terraform
- ansible
- python3 + pyyaml
- AWS credentials configured
- SSH keypair available

## Deploy
./runbook/rc_up.sh ~/.ssh/id_ed25519.pub ~/.ssh/id_ed25519 <cassandra_branch> <your_ip>/32

## Destroy
./runbook/rc_down.sh
