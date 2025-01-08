
# 准备工作
- vSphere Environment version >= 8.0
- DCHP configured for vCenter (required by Packer)
- jq version >= 1.6
- make version >= 4.2.1
- docker version >= 20.10.21
- 跳板机 - 需要可以访问vCenter （环境中IP地址192.168.100.247）

## 检查vSphere 环境
## 检查jq版本
```
sudo apt install -y jq

[admin@rocky9 ~]$ rpm -qa | grep jq
jq-1.6-17.el9.x86_64
```

## 检查make版本
```
sudo apt install make

[admin@rocky9 ~]$ rpm -qa | grep make
make-4.3-8.el9.x86_64
```

## 检查docker版本
```
[admin@rocky9 ~]$ docker version
Client: Docker Engine - Community
 Version:           27.3.1
 API version:       1.47
 Go version:        go1.22.7
 Git commit:        ce12230
 Built:             Fri Sep 20 11:42:48 2024
 OS/Arch:           linux/amd64
 Context:           default
```

## 克隆Github仓库到本地
```
git clone https://github.com/vmware-tanzu/vsphere-tanzu-kubernetes-grid-image-builder.git
```

# 操作步骤

## 修改vSphere配置文件 

- 用于Packer访问vCenter
```
[admin@rocky9 packer-variables]$ pwd
/data/images/vsphere-tanzu-kubernetes-grid-image-builder/packer-variables

[admin@rocky9 packer-variables]$ cat vsphere.j2
{
    {# vCenter server IP or FQDN #}
    "vcenter_server":"192.168.100.6",
    {# vCenter username #}
    "username":"administrator@vsphere.local",
    {# vCenter user password #}
    "password":"VMware1!",
    {# Datacenter name where packer creates the VM for customization #}
    "datacenter":"Datacenter",
    {# Datastore name for the VM #}
    "datastore":"11-Datastore-NUC-1-NVME",
    {# [Optional] Folder name #}
    "folder":"",
    {# Cluster name where packer creates the VM for customization #}
    "cluster": "11-NUC-Cluster",
    {# Packer VM network #}
    "network": "VM Network",
    {# To use insecure connection with vCenter  #}
    "insecure_connection": "true",
    {# TO create a clone of the Packer VM after customization#}
    "linked_clone": "true",
    {# To create a snapshot of the Packer VM after customization #}
    "create_snapshot": "true",
    {# To destroy Packer VM after Image Build is completed #}
    "destroy": "true"
}
```

## 列出支持版本

- 当前支持的最新版本是1.31.1，最老版本是1.26.5
```
[admin@rocky9 vsphere-tanzu-kubernetes-grid-image-builder]$ make list-versions
            Kubernetes Version  |  Supported OS
       v1.26.5+vmware.2-fips.1  |  [photon-3,ubuntu-2004-efi]
      v1.27.11+vmware.1-fips.1  |  [photon-3,ubuntu-2204-efi]
       v1.28.8+vmware.1-fips.1  |  [photon-5,ubuntu-2204-efi]
       v1.29.4+vmware.3-fips.1  |  [photon-5,ubuntu-2204-efi]
         v1.30.1+vmware.1-fips  |  [photon-5,ubuntu-2204-efi]
         v1.31.1+vmware.2-fips  |  [photon-5,ubuntu-2204-efi,windows-2022-efi]
```

## 自定义配置

### 自定义#1  第三方软件仓库

- 用于创建镜像时从非官方镜像下载相关的软件
- 在ansible/files路径下创建repos目录

#### 【Photon系统】

- 在repos目录下创建photon.repo文件

```
[admin@rocky9 files]$ pwd
/data/images/vsphere-tanzu-kubernetes-grid-image-builder/ansible/files

[admin@rocky9 files]$ tree repos/
repos/
└── photon.repo
```

- 修改photon.repo文件，添加第三方软件仓库
```
[admin@rocky9 repos]$ cat photon.repo
[photon-local]
name=VMware Photon Linux $releasever ($basearch)
baseurl=https://mirrors.changw.xyz/repository/photon/$releasever/photon_release_$releasever_$basearch
enabled=1

[photon-updates-local]
name=VMware Photon Linux $releasever ($basearch) Updates
baseurl=https://mirrors.changw.xyz/repository/photon/$releasever/photon_updates_$releasever_$basearch
enabled=1

[photon-extras-local]
name=VMware Photon Extras $releasever ($basearch)
baseurl=https://mirrors.changw.xyz/repository/photon/$releasever/photon_extras_$releasever_$basearch
```



#### 【Ubuntu系统】

- 创建ubuntu.list文件
```
deb <internal_source_url> jammy main restricted universe
deb <internal_source_url> jammy-security main restricted
deb <internal_source_url> jammy-updates main restricted
```

- 例如
```
# Create by Chang WANG , for ubuntu 2204
deb https://mirrors.changw.xyz/repository/ubuntu-2204/ jammy main restricted
deb https://mirrors.changw.xyz/repository/ubuntu-2204/ jammy-updates main restricted
deb https://mirrors.changw.xyz/repository/ubuntu-2204/ jammy universe
deb https://mirrors.changw.xyz/repository/ubuntu-2204/ jammy-updates universe
deb https://mirrors.changw.xyz/repository/ubuntu-2204/ jammy multiverse
deb https://mirrors.changw.xyz/repository/ubuntu-2204/ jammy-updates multiverse
deb https://mirrors.changw.xyz/repository/ubuntu-2204/ jammy-backports main restricted universe multiverse
deb https://mirrors.changw.xyz/repository/ubuntu-2204/ jammy-security main restricted
deb https://mirrors.changw.xyz/repository/ubuntu-2204/ jammy-security universe
deb https://mirrors.changw.xyz/repository/ubuntu-2204/ jammy-security multiverse
```

- 创建repos.j2文件：我的环境中只修改了photon的配置
```
[admin@rocky9 packer-variables]$ pwd
/data/images/vsphere-tanzu-kubernetes-grid-image-builder/packer-variables

[admin@rocky9 packer-variables]$ cat repos.j2
{
    {% if os_type == "photon-5" %}
    "extra_repos": "/image-builder/images/capi/image/ansible/files/repos/photon.repo"
    {% endif %}
}
```

- 如果需要移除第三方的镜像仓库，或者禁用默认的仓库，需要添加额外的参数，例如：
```
{
    "disable_public_repos": true, #<------------------
    "remove_extra_repos": true  #<------------------
    {% if os_type == "photon-5" %}
    "extra_repos": "/image-builder/images/capi/image/ansible/files/repos/photon.repo"
    {% elif os_type == "ubuntu-2204-efi" %}
    "extra_repos": "/image-builder/images/capi/image/ansible/files/repos/ubuntu.list"
    {% endif %}
}
```

### 自定义#2 修改CRI Containerd的下载源

- 方法1：修改mirrors方法 （本案例中采用此方法）
- 方法2:  修改config_path方法

参考文档
- [https://github.com/containerd/containerd/blob/main/docs/hosts.md](https://github.com/containerd/containerd/blob/main/docs/hosts.md
- [https://github.com/kubernetes-sigs/kubespray/issues/8199](https://github.com/kubernetes-sigs/kubespray/issues/8199)


#### 方法#1 修改mirrors配置

- 修改/data/images/vsphere-tanzu-kubernetes-grid-image-builder/ansible/templates/etc/containerd/config_v2.toml文件
```
[plugins."io.containerd.grpc.v1.cri".registry]
      [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
          endpoint = ["https://docker-group.changw.xyz"] <---------
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:5000"]
          endpoint = ["http://localhost:5000"]
```

#### 方法#2 修改config_path方法

```
略
```


### 自定义#3 安装额外的软件包

- [https://github.com/vmware-tanzu/vsphere-tanzu-kubernetes-grid-image-builder/blob/main/docs/examples/customizations/adding_os_pkg_repos.md](https://github.com/vmware-tanzu/vsphere-tanzu-kubernetes-grid-image-builder/blob/main/docs/examples/customizations/adding_os_pkg_repos.md)


# 制作镜像
## 选定目标版本
```
[admin@rocky9 vsphere-tanzu-kubernetes-grid-image-builder]$ make list-versions
            Kubernetes Version  |  Supported OS
       v1.26.5+vmware.2-fips.1  |  [photon-3,ubuntu-2004-efi]
      v1.27.11+vmware.1-fips.1  |  [photon-3,ubuntu-2204-efi]
       v1.28.8+vmware.1-fips.1  |  [photon-5,ubuntu-2204-efi]
       v1.29.4+vmware.3-fips.1  |  [photon-5,ubuntu-2204-efi]
         v1.30.1+vmware.1-fips  |  [photon-5,ubuntu-2204-efi]
         v1.31.1+vmware.2-fips  |  [photon-5,ubuntu-2204-efi,windows-2022-efi]
```


## 创建 Artifacts Server Container

- 下载镜像：例如 v1.29.4+vmware.3-fips.1
```
make run-artifacts-container KUBERNETES_VERSION=v1.29.4+vmware.3-fips.1 ARTIFACTS_CONTAINER_PORT=9093 
默认端口是8080
```

```
[admin@rocky9 vsphere-tanzu-kubernetes-grid-image-builder]$ make run-artifacts-container KUBERNETES_VERSION=v1.29.4+vmware.3-fips.1 ARTIFACTS_CONTAINER_PORT=9093
Error response from daemon: No such container: v1.29.4---vmware.3-fips.1-artifacts-server
Unable to find image 'projects.packages.broadcom.com/tkg/tkg-vsphere-linux-resource-bundle:v1.29.4_vmware.3-fips.1-tkg.1' locally
v1.29.4_vmware.3-fips.1-tkg.1: Pulling from tkg/tkg-vsphere-linux-resource-bundle
9bd46a46756c: Pull complete
b0be2c25e784: Pull complete
ce77e92c7f9b: Pull complete
eac7c73a326d: Pull complete
59433bbe3bb8: Pull complete
4ad71874757e: Pull complete
74b5e811915e: Pull complete
974eae22447d: Pull complete
4a99c9f6d82f: Pull complete
2299bd6d7ddc: Pull complete
433cfe893674: Pull complete
Digest: sha256:264e16ab696892a966684d728b940d6cc53f362610b0d8263b76b5e980912b9b
Status: Downloaded newer image for projects.packages.broadcom.com/tkg/tkg-vsphere-linux-resource-bundle:v1.29.4_vmware.3-fips.1-tkg.1
450e10a4407d6d0feddbcf7c1d603bd0a7e7b32dde9ca46a556f94f1181eb4e3
 Hint: Use "make build-node-image OS_TARGET=<os_target> KUBERNETES_VERSION=v1.29.4+vmware.3-fips.1 TKR_SUFFIX=<tkr_suffix> HOST_IP=<host_ip> IMAGE_ARTIFACTS_PATH=<image_artifacts_path> ARTIFACTS_CONTAINER_PORT=9093 PACKER_HTTP_PORT=8082" to build node image
 Hint: Change PACKER_HTTP_PORT if the 8082 port is already in use or not opened
```

- 下载完成会启动对应的容器
```
[admin@rocky9 vsphere-tanzu-kubernetes-grid-image-builder]$ docker ps |grep v1.29.4
450e10a4407d   projects.packages.broadcom.com/tkg/tkg-vsphere-linux-resource-bundle:v1.29.4_vmware.3-fips.1-tkg.1    "nginx -g 'daemon of…"   About a minute ago   Up About a minute   0.0.0.0:9093->80/tcp, [::]:9093->80/tcp     v1.29.4---vmware.3-fips.1-artifacts-server
```

## 创建自定义镜像
- 创建镜像
```
make build-node-image OS_TARGET=photon-5 KUBERNETES_VERSION=v1.29.4+vmware.3-fips.1 TKR_SUFFIX=testboi HOST_IP=192.168.100.247 IMAGE_ARTIFACTS_PATH=/home/admin/image ARTIFACTS_CONTAINER_PORT=9093 PACKER_HTTP_PORT=8082


OS_TARGET - 可以选择支持的操作系统类型
TKR_SUFFIX - 自定义的标签
HOST_IP - 跳板机的IP地址
IMAGE_ARTIFACTS_PATH - 跳板机上保存的路径
```

- 日志输出
```
admin@rocky9 vsphere-tanzu-kubernetes-grid-image-builder]$ make build-node-image OS_TARGET=photon-5 KUBERNETES_VERSION=v1.29.4+vmware.3-fips.1 TKR_SUFFIX=testboi HOST_IP=192.168.100.247 IMAGE_ARTIFACTS_PATH=/home/admin/image ARTIFACTS_CONTAINER_PORT=9093 PACKER_HTTP_PORT=8082
Using default image builder base image library/photon:5.0
sha256:0228e14ae786f3c491965f3b3377aed01d79e9770404fa3957e6f31668572225
Error response from daemon: No such container: v1.29.4---vmware.3-fips.1-photon-5-image-builder
f624175b789bce5eb1f902a080faf962223837cc3255f06700549f074af9c68e

 Hint: Use "docker logs -f v1.29.4---vmware.3-fips.1-photon-5-image-builder" to see logs and status
 Hint: Node Image OVA can be found at /home/admin/image/ovas/

执行"docker logs -f v1.29.4---vmware.3-fips.1-photon-5-image-builder" 可以看到创建时候的日志信息
```

- 创建完成后会在 /home/admin/images下生成日志和ova文件
```
[admin@rocky9 vsphere-tanzu-kubernetes-grid-image-builder]$ cd /home/admin/
.
[admin@rocky9 ~]$ tree -L 2 image/
image/
├── logs
│   ├── packer-20241229144304-20185.log
│   ├── packer-20241230072258-12151.log
│   ├── packer-20241230123312-20836.log
│   ├── packer-20241230124133-5612.log
│   ├── packer-20241230132415-17658.log
│   ├── packer-20241230133506-14000.log
│   ├── packer-20241230143056-10015.log
│   ├── packer-20241230143317-7568.log
│   ├── packer-20241231122936-24847.log
│   ├── packer-20250102111532-11072.log
│   ├── packer-20250102112540-23419.log
│   └── packer-20250102135839-3466.log
└── ovas
    ├── photon-5-amd64-v1.28.8---vmware.1-fips.1-changwbyoi.ova
    ├── photon-5-amd64-v1.31.1---vmware.2-fips-byoi.ova
    └── ubuntu-2204-amd64-v1.27.11---vmware.1-fips.1-ubuntubyoi.ova
```


## Ubuntu22.04 已知问题

### 问题描述

[https://github.com/vmware-tanzu/vsphere-tanzu-kubernetes-grid-image-builder/issues/90](https://github.com/vmware-tanzu/vsphere-tanzu-kubernetes-grid-image-builder/issues/90)

### 修复方法
- 创建ubuntu.json文件
```
[admin@rocky9 vsphere-tanzu-kubernetes-grid-image-builder]$ pwd
/data/images/vsphere-tanzu-kubernetes-grid-image-builder

[admin@rocky9 vsphere-tanzu-kubernetes-grid-image-builder]$ cat ubuntu2204.json
{
    "iso_url": "https://old-releases.ubuntu.com/releases/jammy/ubuntu-22.04.4-live-server-amd64.iso",
    "iso_checksum": "45f873de9f8cb637345d6e66a583762730bbea30277ef7b32c9c3bd6700a32b2"
}
```


- 创建镜像
```
ADDITIONAL_PACKER_VARIABLE_FILES=./ubuntu2204.json make build-node-image OS_TARGET=ubuntu-2204-efi KUBERNETES_VERSION=v1.27.11+vmware.1-fips.1 TKR_SUFFIX=ubuntubyoi HOST_IP=192.168.100.247 IMAGE_ARTIFACTS_PATH=/home/admin/image ARTIFACTS_CONTAINER_PORT=9091 PACKER_HTTP_PORT=8082
```

- 创建完成后生成OVA文件
```
[admin@rocky9 ovas]$ pwd
/home/admin/image/ovas
[admin@rocky9 ovas]$ ls -al
total 16158172
drwxr-xr-x. 2 root root        191 Jan  2 19:50 .
drwxr-xr-x. 4 root root         30 Dec 29 22:43 ..
-rw-r--r--. 1 root root 5153257984 Dec 30 22:52 photon-5-amd64-v1.28.8---vmware.1-fips.1-changwbyoi.ova
-rw-r--r--. 1 root root 5191020032 Dec 30 21:58 photon-5-amd64-v1.31.1---vmware.2-fips-byoi.ova
-rw-r--r--. 1 root root 6201687552 Jan  2 19:51 ubuntu-2204-amd64-v1.27.11---vmware.1-fips.1-ubuntubyoi.ova <-----------------------
```

# 后续操作

## 创建本地的Content Library 



## 修改vSphere With Tanzu配置

- 使用本地 Content Library 

## 上传OVA到Content Library 

## 检查TKR

- 登录到Supervisor集群，列出支持的TKR
```
[admin@bootstrap ~]$ kubectl get tkr
NAME                                    VERSION                               READY   COMPATIBLE   CREATED
v1.27.11---vmware.1-fips.1-ubuntubyoi   v1.27.11+vmware.1-fips.1-ubuntubyoi   True    True         108m    <--------------
v1.28.8---vmware.1-fips.1-changwbyoi    v1.28.8+vmware.1-fips.1-changwbyoi    True    True         2d9h    
v1.31.1---vmware.2-fips-byoi            v1.31.1+vmware.2-fips-byoi            False   False        2d9h
```

## 创建TKC集群
```
[admin@bootstrap ~]$ cat tkc-4.yaml
# v1alpha2
apiVersion: run.tanzu.vmware.com/v1alpha2
kind: TanzuKubernetesCluster
metadata:
  name: tkc-4
  namespace: ns-2
  annotations:
    run.tanzu.vmware.com/resolve-os-image: os-name=ubuntu
spec:
  topology:
    controlPlane:
      replicas: 1
      vmClass: best-effort-xsmall
      storageClass: wcp-storage-prolicy-1
      tkr:
        reference:
          #name: v1.26.13---vmware.1-fips.1-etkg.3
          name: v1.27.11---vmware.1-fips.1-ubuntubyoi
          #name: v1.23.8---vmware.3-tkg.1
    nodePools:
    - name: worker-nodepool-a1
      replicas: 1
      vmClass: best-effort-xsmall
      storageClass: wcp-storage-prolicy-1
      tkr:
        reference:
          #name: v1.23.8---vmware.3-tkg.1
          #name:  v1.26.13---vmware.1-fips.1-tkg.3
          name: v1.27.11---vmware.1-fips.1-ubuntubyoi
          #name: v1.28.8---vmware.1-fips.1-changwbyoi
```

# 常用命令
```
# Make targets
# Retrieves information from supported-versions.json file.
make list-versions   

# Clean
## make clean-containers is used to stop/remove the artifacts or image builder or both.
make clean-containers                            # To clean all the artifacts and image-builder containers
make clean-containers LABEL=byoi_artifacts       # To remove artifact containers
   
## make clean-image-artifacts is used to remove the image artifacts like OVA's and packer log files
make clean-image-artifacts IMAGE_ARTIFACTS_PATH=/root/artifacts/  # To clean the image artifacts in a folder

## make clean is a combination of clean-containers and clean-image-artifacts that cleans both containers and image artifacts
make clean IMAGE_ARTIFACTS_PATH=/root/artifacts/                          # To clean image artifacts and containers
make clean IMAGE_ARTIFACTS_PATH=/root/artifacts/ LABEL=byoi_image_builder # To clean image artifacts and image builder containers 
	         
# Image Building
################################
run-artifacts-container
################################
## make run-artifacts-container is used to run the artifacts container for a Kubernetes version at a particular port
make run-artifacts-container KUBERNETES_VERSION=v1.27.11+vmware.1-fips.1 ARTIFACTS_CONTAINER_PORT=9091    # To run 1.27.11 Kubernetes artifacts container on port 9091

################################
build-image-builder-container
################################
## make build-image-builder-container is used to build the image builder container locally with all the dependencies like Packer, Ansible, and OVF Tool.
make build-image-builder-container KUBERNETES_VERSION=v1.27.11+vmware.1-fips.1

################################
build-node-image
################################
## make build-node-image is used to build the vSphere Tanzu compatible node image for a Kubernetes version.
make build-node-image OS_TARGET=photon-3 KUBERNETES_VERSION=v1.27.11+vmware.1-fips.1 TKR_SUFFIX=byoi HOST_IP=1.2.3.4 IMAGE_ARTIFACTS_PATH=/Users/image ARTIFACTS_CONTAINER_PORT=9090   # Create photon-3 1.23.15 Kubernetes node image
```
  
```
############################################
v1.27.11+vmware.1-fips.1
############################################
make run-artifacts-container KUBERNETES_VERSION=v1.27.11+vmware.1-fips.1 ARTIFACTS_CONTAINER_PORT=9091 

ADDITIONAL_PACKER_VARIABLE_FILES=./ubuntu2204.json make build-node-image OS_TARGET=ubuntu-2204-efi KUBERNETES_VERSION=v1.27.11+vmware.1-fips.1 TKR_SUFFIX=ubuntubyoi HOST_IP=192.168.100.247 IMAGE_ARTIFACTS_PATH=/home/admin/image ARTIFACTS_CONTAINER_PORT=9091 PACKER_HTTP_PORT=8082


############################################
v1.28.8+vmware.1-fips.1
############################################
make run-artifacts-container KUBERNETES_VERSION=v1.28.8+vmware.1-fips.1 ARTIFACTS_CONTAINER_PORT=9090 

make build-node-image OS_TARGET=photon-5 KUBERNETES_VERSION=v1.28.8+vmware.1-fips.1 TKR_SUFFIX=changwbyoi HOST_IP=192.168.100.247 IMAGE_ARTIFACTS_PATH=/home/admin/image ARTIFACTS_CONTAINER_PORT=9090 PACKER_HTTP_PORT=8082

############################################
v1.29.4+vmware.3-fips.1
############################################
make run-artifacts-container KUBERNETES_VERSION=v1.29.4+vmware.3-fips.1 ARTIFACTS_CONTAINER_PORT=9093

make build-node-image OS_TARGET=photon-5 KUBERNETES_VERSION=v1.29.4+vmware.3-fips.1 TKR_SUFFIX=testboi HOST_IP=192.168.100.247 IMAGE_ARTIFACTS_PATH=/home/admin/image ARTIFACTS_CONTAINER_PORT=9093 PACKER_HTTP_PORT=8082

############################################
v1.31.1+vmware.2-fips
############################################
make run-artifacts-container KUBERNETES_VERSION=v1.31.1+vmware.2-fips

make build-node-image OS_TARGET=photon-5 KUBERNETES_VERSION=v1.31.1+vmware.2-fips TKR_SUFFIX=byoi HOST_IP=192.168.100.247  IMAGE_ARTIFACTS_PATH=/home/admin/image ARTIFACTS_CONTAINER_PORT=8081 PACKER_HTTP_PORT=8082
```

# 参考文档
- [https://github.com/vmware-tanzu/vsphere-tanzu-kubernetes-grid-image-builder](https://github.com/vmware-tanzu/vsphere-tanzu-kubernetes-grid-image-builder)
- [https://github.com/kubernetes-sigs/image-builder](https://github.com/kubernetes-sigs/image-builder)