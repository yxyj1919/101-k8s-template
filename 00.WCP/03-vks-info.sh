#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  vks-info.sh [VKS_NAME] [NAMESPACE]

Description:
  1) Decode VKS SSH password from secret:
       <VKS_NAME>-ssh-password
     key:
       ssh-passwordkey

  2) List VM NAME + PRIMARY-IP4 that belong to the VKS.

Arguments:
  VKS_NAME     VKS cluster name
               default: cluster-1

  NAMESPACE    Namespace where the VKS is deployed
               default: ns-1

Examples:
  vks-info.sh
  vks-info.sh cluster-1
  vks-info.sh cluster-1 ns-1
EOF
}

# -------------------------
# Help flag
# -------------------------
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

# -------------------------
# Parameters (defaults)
# -------------------------
VKS_NAME="${1:-cluster-1}"
NAMESPACE="${2:-ns-1}"

SECRET_NAME="${VKS_NAME}-ssh-password"
DATA_KEY="ssh-passwordkey"

# -------------------------
# Required commands
# -------------------------
need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ERROR: missing required command: $1" >&2
    exit 127
  }
}

need_cmd kubectl
need_cmd base64
need_cmd awk
need_cmd grep

# -------------------------
# kubectl base command
# -------------------------
kubectl_cmd=(kubectl -n "${NAMESPACE}")

# -------------------------
# Verify secret exists
# -------------------------
if ! "${kubectl_cmd[@]}" get secret "${SECRET_NAME}" >/dev/null 2>&1; then
  echo "ERROR: Secret not found: ${SECRET_NAME} in namespace ${NAMESPACE}" >&2
  echo "HINT: kubectl get secret -A | grep \"${VKS_NAME}-ssh-password\"" >&2
  exit 1
fi

# -------------------------
# Extract & decode password
# -------------------------
b64="$("${kubectl_cmd[@]}" get secret "${SECRET_NAME}" -o "jsonpath={.data.${DATA_KEY}}" 2>/dev/null || true)"

if [[ -z "${b64}" ]]; then
  echo "ERROR: Key '${DATA_KEY}' not found in secret '${SECRET_NAME}'." >&2
  "${kubectl_cmd[@]}" get secret "${SECRET_NAME}" -o jsonpath='{.data}' && echo
  exit 1
fi

# Linux vs macOS base64 decode
if base64 --help 2>&1 | grep -q -- ' -d'; then
  decoded="$(printf '%s' "${b64}" | base64 -d)"
else
  decoded="$(printf '%s' "${b64}" | base64 -D)"
fi

# -------------------------
# Print password info
# -------------------------
echo "VKS: ${VKS_NAME}"
echo "Namespace: ${NAMESPACE}"
echo "Secret: ${SECRET_NAME}"
echo "Key: ${DATA_KEY}"
echo "Password: ${decoded}"
echo

# -------------------------
# Get VM table
# -------------------------
vm_out="$("${kubectl_cmd[@]}" get vm -o wide 2>/dev/null || true)"

if [[ -z "${vm_out}" ]]; then
  echo "WARN: No VM output found in namespace ${NAMESPACE}." >&2
  exit 0
fi

# -------------------------
# Detect PRIMARY-IP4 column
# -------------------------
ip_col="$(
  awk 'NR==1{
    for(i=1;i<=NF;i++){
      h=toupper($i)
      if(h=="PRIMARY-IP4"){ print i; exit }
    }
    for(i=1;i<=NF;i++){
      h=toupper($i)
      if(h=="PRIMARY-IP" || h=="IP" || h=="ADDRESS" || h=="ADDRESSES"){
        print i; exit
      }
    }
    print 0
  }' <<<"${vm_out}"
)"

# -------------------------
# Print VM name + IP
# -------------------------
echo "VMs matching '${VKS_NAME}' (NAME\tPRIMARY-IP4):"

awk -v vks="${VKS_NAME}" -v ipcol="${ip_col}" '
  NR==1 { next }
  index($0, vks) > 0 {
    name=$1
    ip="N/A"
    if (ipcol > 0 && ipcol <= NF) ip=$(ipcol)
    if (ip=="") ip="N/A"
    print name "\t" ip
  }
' <<<"${vm_out}"
