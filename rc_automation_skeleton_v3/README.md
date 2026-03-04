# RC Automation Skeleton (Terraform + Ansible)

Generated: 2026-03-02

## Quick start
1. Ensure AWS credentials are configured (env vars, profile, or SSO).
2. Run:
   ```bash
   ./runbook/rc_up.sh ~/.ssh/id_ed25519.pub ~/.ssh/id_ed25519 <cassandra_branch>
   ```
3. SSH to the test client and run workloads.

## Security note
This skeleton follows your requested inbound rules and defaults SSH CIDR to 0.0.0.0/0.
**Strongly recommended**: restrict `ssh_allowed_cidr` to your public IP (/32) or use SSM-only access.
