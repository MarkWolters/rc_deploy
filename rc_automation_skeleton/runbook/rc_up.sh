#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${ROOT_DIR}/infra/terraform"
ANS_DIR="${ROOT_DIR}/config/ansible"

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <ssh_public_key_path> <ssh_private_key_path> <cassandra_branch> [ssh_allowed_cidr]"
  exit 1
fi

PUBKEY="$1"
PRIVKEY="$2"
CASS_BRANCH="$3"
SSH_CIDR="${4:-0.0.0.0/0}"

cd "${TF_DIR}"
terraform init
terraform apply -auto-approve   -var="ssh_public_key_path=${PUBKEY}"   -var="ssh_allowed_cidr=${SSH_CIDR}"

CASS_PUB="$(terraform output -json cassandra_public_ips)"
CASS_PRIV="$(terraform output -json cassandra_private_ips)"
CLIENT_PUB="$(terraform output -raw client_public_ip)"
CLIENT_PRIV="$(terraform output -raw client_private_ip)"

python3 - "$ANS_DIR" "$CASS_PUB" "$CASS_PRIV" "$CLIENT_PUB" "$CLIENT_PRIV" <<'PY'
import json, sys, os
ans_dir, cass_pub, cass_priv, client_pub, client_priv = sys.argv[1:]
pub = json.loads(cass_pub)
priv = json.loads(cass_priv)
lines = []
lines.append("[cassandra]")
for idx, (a, b) in enumerate(zip(pub, priv), start=1):
    lines.append(f"cass{idx} ansible_host={a} private_ip={b}")
lines.append("")
lines.append("[test_client]")
lines.append(f"client ansible_host={client_pub} private_ip={client_priv}")
lines.append("")
lines.append("[all:vars]")
lines.append("ansible_user=ubuntu")
with open(os.path.join(ans_dir, "inventory.ini"), "w") as f:
    f.write("\n".join(lines) + "\n")
print("Wrote inventory.ini")
PY

python3 - "$ANS_DIR" "$CASS_BRANCH" <<'PY'
import sys, os
try:
    import yaml
except Exception:
    raise SystemExit("PyYAML is required on the control host: pip3 install pyyaml")
ans_dir, branch = sys.argv[1:]
path = os.path.join(ans_dir, "group_vars", "all.yml")
with open(path) as f:
    data = yaml.safe_load(f)
data["cassandra_branch"] = branch
with open(path, "w") as f:
    yaml.safe_dump(data, f, sort_keys=False)
print("Updated cassandra_branch:", branch)
PY

cd "${ANS_DIR}"
ansible-playbook -i inventory.ini playbooks/site.yml --private-key "${PRIVKEY}"

echo
echo "========================================"
echo " Cassandra cluster ready"
echo " Test client ready"
echo ""
echo "Cassandra nodes:"
python3 - "$CASS_PUB" <<'PY'
import json, sys
for idx, ip in enumerate(json.loads(sys.argv[1]), start=1):
    print(f"  cass{idx}: {ip}")
PY
echo "Test client:"
echo "  client: ${CLIENT_PUB}"
echo ""
echo "Next step:"
echo "  ssh -i ${PRIVKEY} ubuntu@${CLIENT_PUB}"
echo "  source /etc/profile.d/java.sh"
echo "  cd /opt/rc-tools/nosqlbench"
echo "  ./nb --version"
echo "  /opt/rc-tools/check_rc_suite.sh s1"
echo "========================================"
