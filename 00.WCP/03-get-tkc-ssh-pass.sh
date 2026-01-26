#!/usr/bin/env bash
set -euo pipefail

# Default TKC name
TKC_NAME="${1:-cluster-1}"

# Optional: namespace (if not set, use current context namespace)
NAMESPACE="${2:-}"

SECRET_NAME="${TKC_NAME}-ssh-password"
DATA_KEY="ssh-passwordkey"

kubectl_cmd=(kubectl)
if [[ -n "${NAMESPACE}" ]]; then
  kubectl_cmd+=( -n "${NAMESPACE}" )
fi

# 1) Verify secret exists
if ! "${kubectl_cmd[@]}" get secret "${SECRET_NAME}" >/dev/null 2>&1; then
  echo "ERROR: Secret not found: ${SECRET_NAME}"
  echo "HINT: Try: kubectl get secret -A | grep \"${TKC_NAME}-ssh-password\""
  exit 1
fi

# 2) Extract base64 value using jsonpath (more robust than grep/awk)
# kubectl supports JSONPath output via -o jsonpath=...  [oai_citation:1‡Kubernetes](https://kubernetes.io/docs/reference/kubectl/jsonpath/?utm_source=chatgpt.com)
b64="$("${kubectl_cmd[@]}" get secret "${SECRET_NAME}" -o "jsonpath={.data.${DATA_KEY}}" 2>/dev/null || true)"

if [[ -z "${b64}" ]]; then
  echo "ERROR: Key '${DATA_KEY}' not found in secret '${SECRET_NAME}'."
  echo "HINT: Check available keys:"
  "${kubectl_cmd[@]}" get secret "${SECRET_NAME}" -o jsonpath='{.data}' && echo
  exit 1
fi

# 3) Decode base64
# Linux: base64 -d ; macOS: base64 -D (auto-detect)
if base64 --help 2>&1 | grep -q -- ' -d'; then
  decoded="$(printf '%s' "${b64}" | base64 -d)"
else
  decoded="$(printf '%s' "${b64}" | base64 -D)"
fi

echo "TKC: ${TKC_NAME}"
if [[ -n "${NAMESPACE}" ]]; then
  echo "Namespace: ${NAMESPACE}"
fi
echo "Secret: ${SECRET_NAME}"
echo "Key: ${DATA_KEY}"
echo "Password: ${decoded}"
