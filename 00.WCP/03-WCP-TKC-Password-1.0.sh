#get-ssh-password.sh
#!/bin/bash

# 交互式输入 namespace，默认是 ns-1
read -p "请输入 namespace（默认: ns-1）: " NAMESPACE
NAMESPACE=${NAMESPACE:-ns-1}

# 交互式输入 TKC 名称，默认是 cluster-4
read -p "请输入 TKC 名称（默认: cluster-4）: " TKC_NAME
TKC_NAME=${TKC_NAME:-cluster-4}

# Secret 名称规则：<TKC名称>-ssh-password
SECRET_NAME="${TKC_NAME}-ssh-password"
KEY_NAME="ssh-passwordkey"

# 获取 Secret 中的 base64 编码密码
ENCODED_PASSWORD=$(kubectl get secret -n "$NAMESPACE" "$SECRET_NAME" -o jsonpath="{.data.$KEY_NAME}" 2>/dev/null)

# 检查是否成功获取
if [ -z "$ENCODED_PASSWORD" ]; then
  echo "❌ 无法找到 Secret 或 Key：$SECRET_NAME / $KEY_NAME 在命名空间 $NAMESPACE 中"
  exit 1
fi

# 解码并输出
echo "✅ 成功找到 Secret，解码后的 SSH 密码为："
echo "$ENCODED_PASSWORD" | base64 -d
echo
