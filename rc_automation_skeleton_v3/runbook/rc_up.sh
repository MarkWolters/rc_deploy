#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${ROOT_DIR}/infra/terraform"
ANS_DIR="${ROOT_DIR}/config/ansible"

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <ssh_public_key_path> <ssh_private_key_path> [cassandra_branch]"
  exit 1
fi

PUBKEY="$1"
PRIVKEY="$2"
CASS_BRANCH="${3:-main}"

cd "$TF_DIR"
terraform init
terraform apply -auto-approve \
  -var="ssh_public_key_path=${PUBKEY}" \
  -var="ssh_allowed_cidr=0.0.0.0/0"

# Render a simple inventory.ini from terraform output
CASS_IPS=$(terraform output -json cassandra_public_ips)
CASS_PRIV=$(terraform output -json cassandra_private_ips)
CLIENT_IP=$(terraform output -raw client_public_ip)
CLIENT_PRIV=$(terraform output -raw client_private_ip)

python3 - <<'PY'
import json, os, sys
cass_ips = json.loads(os.environ["CASS_IPS"])
cass_priv = json.loads(os.environ["CASS_PRIV"])
client_ip = os.environ["CLIENT_IP"]
client_priv = os.environ["CLIENT_PRIV"]
ans_dir = os.environ["ANS_DIR"]
lines = []
lines.append("[cassandra]")
for i,(ip,pip) in enumerate(zip(cass_ips,cass_priv), start=1):
    lines.append(f"cass{i} ansible_host={ip} private_ip={pip}")
lines.append("")
lines.append("[test_client]")
lines.append(f"client ansible_host={client_ip} private_ip={client_priv}")
lines.append("")
lines.append("[all:vars]")
lines.append("ansible_user=ubuntu")
with open(os.path.join(ans_dir, "inventory.ini"), "w") as f:
    f.write("\n".join(lines) + "\n")
print("Wrote inventory.ini")
PY
export CASS_IPS
export CASS_PRIV
export CLIENT_IP
export CLIENT_PRIV
export ANS_DIR
# Set cassandra_branch in group_vars
python3 - <<'PY'
import os, yaml
path = os.path.join(os.environ["ANS_DIR"], "group_vars", "all.yml")
with open(path) as f:
    data = yaml.safe_load(f)
data["cassandra_branch"] = os.environ.get("CASS_BRANCH","main")
with open(path, "w") as f:
    yaml.safe_dump(data, f, sort_keys=False)
print("Updated cassandra_branch in group_vars/all.yml")
PY
cd "$ANS_DIR"
ansible-playbook -i inventory.ini playbooks/site.yml --private-key "$PRIVKEY"

echo ""
echo "Environment is up. SSH to client:"
echo "  ssh -i \"$PRIVKEY\" ubuntu@${CLIENT_IP}"
