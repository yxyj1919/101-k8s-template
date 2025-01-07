#!/bin/bash

# 设置环境变量
SVC_VIP=10.0.75.14
SVC_USERNAME=administrator@vsphere.local

# 删除现有 kubeconfig 文件
rm -rf ~/.kube/config

# 登录 vSphere Tanzu
kubectl vsphere login \
        --server=$SVC_VIP \
        --vsphere-username $SVC_USERNAME \
        --insecure-skip-tls-verify

# 打印空行
echo ""
echo ""
echo ""

# 显示当前 kubectl 上下文
kubectl config get-contexts

# 打印空行
echo ""
echo ""
echo ""

# 提供 Kubernetes 集群管理员权限（可选，已注释）
# kubectl create clusterrolebinding default-tkg-admin-privileged-binding \
#   --clusterrole=psp:vmware-system-privileged \
#   --group=system:authenticated
