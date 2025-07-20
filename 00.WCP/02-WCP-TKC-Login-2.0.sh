#!/bin/bash
# vsphere-login-tkc.sh  —  交互式 vSphere / Tanzu 登录脚本

# ────────── 默认值 ──────────
DEFAULT_SERVER="10.0.19.15"
DEFAULT_USERNAME="administrator@vsphere.local"
DEFAULT_NAMESPACE="ns-1"
DEFAULT_CLUSTER_NAME="cluster-1"

# 当前值（先用默认，占位，后续可能被参数或交互覆盖）
VSPHERE_SERVER="$DEFAULT_SERVER"
VSPHERE_USERNAME="$DEFAULT_USERNAME"
TKC_NAMESPACE="$DEFAULT_NAMESPACE"
TKC_NAME="$DEFAULT_CLUSTER_NAME"

# ────────── 帮助函数 ──────────
show_help() {
  cat <<EOF
用法: $0 [--server <vcenter-ip>] [--username <vsphere-username>]
          [--namespace <tkc-namespace>] [--cluster-name <tkc-name>] [-h]

说明:
  缺省值:
    vCenter Server        : $DEFAULT_SERVER
    vSphere Username      : $DEFAULT_USERNAME
    Tanzu Namespace       : $DEFAULT_NAMESPACE
    Tanzu Cluster Name    : $DEFAULT_CLUSTER_NAME

示例:
  全交互 (直接回车 = 用默认值):
    $0

  非交互（传参）:
    $0 --server 10.0.19.20 --username admin@corp.com \\
       --namespace dev-ns --cluster-name dev-cluster

  显示帮助:
    $0 -h
EOF
}

# ────────── 解析命令行参数 ──────────
while [[ $# -gt 0 ]]; do
  case $1 in
    --server)        VSPHERE_SERVER="$2"; shift 2 ;;
    --username)      VSPHERE_USERNAME="$2"; shift 2 ;;
    --namespace)     TKC_NAMESPACE="$2"; shift 2 ;;
    --cluster-name)  TKC_NAME="$2"; shift 2 ;;
    -h|--help)       show_help; exit 0 ;;
    *)
      echo "未知参数: $1"; show_help; exit 1 ;;
  esac
done

# ────────── 交互式输入（回车 = 保持当前值） ──────────
read -p "请输入 vCenter Server 地址        [默认: $VSPHERE_SERVER] : "  INPUT
[[ -n "$INPUT" ]] && VSPHERE_SERVER="$INPUT"

read -p "请输入 vSphere Username          [默认: $VSPHERE_USERNAME] : "  INPUT
[[ -n "$INPUT" ]] && VSPHERE_USERNAME="$INPUT"

read -p "请输入 Tanzu Namespace            [默认: $TKC_NAMESPACE]    : "  INPUT
[[ -n "$INPUT" ]] && TKC_NAMESPACE="$INPUT"

read -p "请输入 Tanzu Cluster 名称         [默认: $TKC_NAME]        : "  INPUT
[[ -n "$INPUT" ]] && TKC_NAME="$INPUT"

# ────────── 显示最终参数 ──────────
cat <<EOF

即将执行登录，参数如下：
  Server       : $VSPHERE_SERVER
  Username     : $VSPHERE_USERNAME
  Namespace    : $TKC_NAMESPACE
  Cluster Name : $TKC_NAME

EOF

# ────────── 执行登录命令 ──────────
kubectl vsphere login \
  --server="$VSPHERE_SERVER" \
  --vsphere-username="$VSPHERE_USERNAME" \
  --tanzu-kubernetes-cluster-namespace="$TKC_NAMESPACE" \
  --tanzu-kubernetes-cluster-name="$TKC_NAME" \
  --insecure-skip-tls-verify
