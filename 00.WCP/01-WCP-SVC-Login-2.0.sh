#!/bin/bash
# vsphere-login.sh  — 交互式登录 vSphere

# ────────── 默认值 ──────────
DEFAULT_SERVER="10.0.19.15"
DEFAULT_USERNAME="administrator@vsphere.local"

# 当前值（默认）
VSPHERE_SERVER="$DEFAULT_SERVER"
VSPHERE_USERNAME="$DEFAULT_USERNAME"

# ────────── 帮助信息 ──────────
show_help() {
  cat <<EOF
用法: $0 [--server <vcenter-ip>] [--username <vsphere-username>] [-h]

说明:
  默认 vCenter 地址:   $DEFAULT_SERVER
  默认 vSphere 用户名: $DEFAULT_USERNAME

示例:
  全交互（一路回车使用默认值）:
    $0

  指定参数（非交互）:
    $0 --server 10.0.19.20 --username admin@corp.com

  显示帮助:
    $0 -h
EOF
}

# ────────── 解析参数 ──────────
while [[ $# -gt 0 ]]; do
  case $1 in
    --server)   VSPHERE_SERVER="$2"; shift 2 ;;
    --username) VSPHERE_USERNAME="$2"; shift 2 ;;
    -h|--help)  show_help; exit 0 ;;
    *)
      echo "未知参数: $1"; show_help; exit 1 ;;
  esac
done

# ────────── 交互输入（为空则使用当前值） ──────────
read -p "请输入 vCenter Server 地址   [默认: $VSPHERE_SERVER] : " INPUT
[[ -n "$INPUT" ]] && VSPHERE_SERVER="$INPUT"

read -p "请输入 vSphere 用户名        [默认: $VSPHERE_USERNAME] : " INPUT
[[ -n "$INPUT" ]] && VSPHERE_USERNAME="$INPUT"

# ────────── 显示最终参数 ──────────
cat <<EOF

即将执行登录，参数如下：
  Server   : $VSPHERE_SERVER
  Username : $VSPHERE_USERNAME

EOF

# ────────── 执行登录命令 ──────────
kubectl vsphere login \
  --server="$VSPHERE_SERVER" \
  --insecure-skip-tls-verify \
  --vsphere-username="$VSPHERE_USERNAME"
