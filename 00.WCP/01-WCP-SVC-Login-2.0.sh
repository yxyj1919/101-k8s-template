#!/bin/bash

# 默认值
VSPHERE_SERVER="10.0.19.15"
VSPHERE_USERNAME="administrator@vsphere.local"

# 显示帮助信息
show_help() {
  echo "用法: $0 [--server <vcenter-ip>] [--username <vsphere-username>]"
  echo
  echo "说明:"
  echo "  默认 vCenter 地址: $VSPHERE_SERVER"
  echo "  默认用户名:         $VSPHERE_USERNAME"
  echo
  echo "示例:"
  echo "  使用默认登录:"
  echo "    $0"
  echo
  echo "  指定服务器地址和用户名:"
  echo "    $0 --server 10.0.19.99 --username admin@yourdomain.com"
  echo
  echo "  显示此帮助信息:"
  echo "    $0 -h"
}

# 解析参数
while [[ $# -gt 0 ]]; do
  case $1 in
    --server)
      VSPHERE_SERVER="$2"
      shift 2
      ;;
    --username)
      VSPHERE_USERNAME="$2"
      shift 2
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "未知参数: $1"
      show_help
      exit 1
      ;;
  esac
done

# 显示将要使用的地址和用户名
echo "Logging into vSphere with the following parameters:"
echo "  Server:   $VSPHERE_SERVER"
echo "  Username: $VSPHERE_USERNAME"
echo

# 执行登录命令
kubectl vsphere login \
  --server="$VSPHERE_SERVER" \
  --insecure-skip-tls-verify \
  --vsphere-username="$VSPHERE_USERNAME"
