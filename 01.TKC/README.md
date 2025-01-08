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
## 

##