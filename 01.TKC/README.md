# API
## Cluster v1beta1 API
https://docs.vmware.com/en/VMware-vSphere/8.0/vsphere-with-tanzu-tkg/GUID-69E52B31-6DEC-412D-B60E-FE733156F708.html#GUID-69E52B31-6DEC-412D-B60E-FE733156F708

## TanzuKubernetesCluster v1alpha3 API
https://docs.vmware.com/en/VMware-vSphere/8.0/vsphere-with-tanzu-tkg/GUID-940A4989-B723-48A0-B907-9B484D82AC72.html#GUID-940A4989-B723-48A0-B907-9B484D82AC72

# Release Notes
https://docs.vmware.com/en/VMware-vSphere/8.0/vsphere-with-tanzu-tkg/GUID-0DF355EF-AA36-4C0B-B0EF-35BF5F5FD5D4.html

## Compatibility with vSphere 8.x and 7.x
There are two types of TKr formats: non-legacy TKrs and legacy TKRs.
- Non-legacy TKrs are purpose-built for vSphere 8.x and are only compatible with vSphere 8.x
- Legacy TKRs use a legacy format and are compatible with vSphere 7.x, and also with vSphere 8.x but for upgrade purposes only.

## How to verify TKr compatibility with vSphere
- To verify TKr compatibility with vSphere, run the command kubectl get tkr TKR_NAME --show-labels (or kubectl get tkr TKR-NAME -o yaml). 
- To list only the TKrs that do not contain the legacy label, run the command kubectl get tkr -l '!run.tanzu.vmware.com/legacy-tkr'. 
  - If the release includes the label annotation run.tanzu.vmware.com/legacy-tkr, the image is based on the vSphere 7.x format. 
  - You can run a legacy TKr on vSphere 8.x, but you will not be able to take advantage of vSphere 8.x features such as class-based clusters and Carvel packaging until you upgrade to a non-legacy TKr.
  - The output of the command kubectl get tkr -l '!run.tanzu.vmware.com/legacy-tkr' returns all non-legacy TKrs. These are the TKrs purpose-built for vSphere 8.x and only compatible with vSphere 8.x. (Current as of April 11, 2024).

# Compatibility Matrix
- https://interopmatrix.broadcom.com/Interoperability?col=820,&row=2,&isHidePatch=false&isHideGenSupported=false&isHideTechSupported=false&isHideCompatible=false&isHideNTCompatible=false&isHideIncompatible=false&isHideNotSupported=true&isCollection=false
- https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-releases/services/rn/vmware-tanzu-kubernetes-releases-release-notes/index.html#Release-Note-Section-13664 



# 安全配置
## For TKG release v1.24 and earlier
https://docs.vmware.com/en/VMware-vSphere/8.0/vsphere-with-tanzu-tkg/GUID-0AEC33DE-DCE2-4FBE-A33F-73C4EDCCAB88.html
```
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: psp:privileged
rules:
- apiGroups: ['policy']
  resources: ['podsecuritypolicies']
  verbs:     ['use']
  resourceNames:
  - vmware-system-privileged
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: all:psp:privileged
roleRef:
  kind: ClusterRole
  name: psp:privileged
  apiGroup: rbac.authorization.k8s.io
subjects:
- kind: Group
  name: system:serviceaccounts
  apiGroup: rbac.authorization.k8s.io
```

## Configure PSA for TKR 1.25 and Later
https://docs.vmware.com/en/VMware-vSphere/8.0/vsphere-with-tanzu-tkg/GUID-B57DA879-89FD-4C34-8ADB-B21CB3AE67F6.html

### For TKG release v1.25
- Use the following example command to change the security levels for a given namespace so that PSA warnings and audit notifications are not generated.
```
kubectl label --overwrite ns NAMESPACE pod-security.kubernetes.io/audit=privileged 
kubectl label --overwrite ns NAMESPACE pod-security.kubernetes.io/warn=privileged
```



### For TKG releases v1.26 and later
- 在 Kubernetes 中，Pod 安全性准入（PSA，Pod Security Admission） 是一种机制，用于在集群级别或命名空间级别实施 Pod 的安全性标准（如 Pod Security Standards）。如果你想降低 PSA 到最低（即允许最宽松的配置），你需要将策略设置为 privileged。
- Use the following example command to downgrade the PSA standard from restricted to baseline
```
kubectl label --overwrite ns NAMESPACE pod-security.kubernetes.io/enforce=baseline
```
- Use the following example command to downgrade the PSA standard from restricted to privileged
```
kubectl label --overwrite ns NAMESPACE pod-security.kubernetes.io/enforce=privileged
```
- Use the following example commands to relax PSA across all non-system namespaces
```
kubectl label --overwrite ns --all pod-security.kubernetes.io/enforce=privileged
```

```
参数说明：
	•	enforce: 强制执行的策略（将拒绝不符合条件的 Pod）。
	•	audit: 审计策略（记录不符合条件的 Pod，但不拒绝）。
	•	warn: 警告策略（给出警告，但不拒绝 Pod）。
```

```
kubectl label namespace default \
    pod-security.kubernetes.io/enforce=privileged \
    pod-security.kubernetes.io/audit=privileged \
    pod-security.kubernetes.io/warn=privileged --overwrite
```
- How to verify the PSA configuration
```
kubectl get namespaces --show-labels

NAME        STATUS   AGE   LABELS
default     Active   10d   pod-security.kubernetes.io/enforce=privileged,...
```