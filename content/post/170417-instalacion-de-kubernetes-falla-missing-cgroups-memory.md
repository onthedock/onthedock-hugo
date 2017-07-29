+++
tags = ["ops"]
draft = false
date = "2017-04-17T19:38:11+02:00"
title = "La instalación de Kubernetes falla en Debian Jessie (Missing cgroups: memory)"
thumbnail = "images/kubernetes.png"
categories = ["linux", "debian", "docker", "kubernetes"]

+++

La instalación de Kubernetes se realiza de forma casi automática gracias al _script_ `kubeadm`. Sólo hay que seguir las instrucciones de [Installing Kubernetes on Linux with kubeadm](https://kubernetes.io/docs/getting-started-guides/kubeadm/) y la salida por pantalla del propio _script_.

<!--more-->

Para no _deshacer_ la instalación de Kubernetes sobre Raspberry Pi, he creado una máquina virtual con Debian 3 (_Jessie_):

```sh
# uname -a
Linux k8s 3.16.0-4-amd64 #1 SMP Debian 3.16.39-1+deb8u2 (2017-03-07) x86_64 GNU/Linux
```

En primer lugar, me he convertido en `root` mediante `su -`.

Uno de los requisitos para instalar Kubernetes es tener Docker instalado. En mi caso, tengo instalado `docker-engine`, el paquete de Docker mantenido por Docker Inc. Este paquete y `docker.io` (el mantenido por Ubuntu) son equivalentes, aunque tienen numeración de versión diferente.

Verifico que Docker está instalado:

```sh
# docker version
Client:
 Version:      17.04.0-ce
 API version:  1.28
 Go version:   go1.7.5
 Git commit:   4845c56
 Built:        Mon Apr  3 17:45:49 2017
 OS/Arch:      linux/amd64

Server:
 Version:      17.04.0-ce
 API version:  1.28 (minimum version 1.12)
 Go version:   go1.7.5
 Git commit:   4845c56
 Built:        Mon Apr  3 17:45:49 2017
 OS/Arch:      linux/amd64
 Experimental: false
#
```

Antes de empezar la instalación, he actualizado el sistema mediante:

```sh
# apt-get update && apt-get upgrade
...
```

A partir de aquí, sigo las instrucciones de la guía oficial.

```sh
# apt-get update && apt-get install -y apt-transport-https
...
Reading state information... Done
apt-transport-https is already the newest version.
0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded.
#
```

Obtenemos la clave GPG de los paquetes de Kubernetes:

```sh
# curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
OK
```

Añadimos el repositorio de Kubernetes:

```sh
apt-get update && apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
```

Y ya sólo nos queda actualizar la información e instalar los componentes de Kubernetes:

```sh
# apt-get update
...
Fetched 22.1 kB in 3s (6,784 B/s)
Reading package lists... Done
#
# apt-get install -y kubelet kubeadm kubectl kubernetes-cni
...
Setting up ebtables (2.0.10.4-3) ...
update-rc.d: warning: start and stop actions are no longer supported; falling back to defaults
Setting up ethtool (1:3.16-1) ...
Setting up kubernetes-cni (0.5.1-00) ...
Setting up socat (1.7.2.4-2) ...
Setting up kubelet (1.6.1-00) ...
Setting up kubectl (1.6.1-00) ...
Setting up kubeadm (1.6.1-00) ...
Processing triggers for systemd (215-17+deb8u6) ...
#
```

Ya tenemos instalado Kubernetes en nuestro sistema.

El siguiente paso es inicializar el clúster con `kubeadm init`.

```sh
# kubeadm init
[kubeadm] WARNING: kubeadm is in beta, please do not use it for production clusters.
[init] Using Kubernetes version: v1.6.0
[init] Using Authorization mode: RBAC
[preflight] Running pre-flight checks
[preflight] The system verification failed. Printing the output from the verification:
OS: Linux
KERNEL_VERSION: 3.16.0-4-amd64
CONFIG_NAMESPACES: enabled
CONFIG_NET_NS: enabled
CONFIG_PID_NS: enabled
CONFIG_IPC_NS: enabled
CONFIG_UTS_NS: enabled
CONFIG_CGROUPS: enabled
CONFIG_CGROUP_CPUACCT: enabled
CONFIG_CGROUP_DEVICE: enabled
CONFIG_CGROUP_FREEZER: enabled
CONFIG_CGROUP_SCHED: enabled
CONFIG_CPUSETS: enabled
CONFIG_MEMCG: enabled
CONFIG_INET: enabled
CONFIG_EXT4_FS: enabled (as module)
CONFIG_PROC_FS: enabled
CONFIG_NETFILTER_XT_TARGET_REDIRECT: enabled (as module)
CONFIG_NETFILTER_XT_MATCH_COMMENT: enabled (as module)
CONFIG_OVERLAYFS_FS: not set - Required for overlayfs.
CONFIG_AUFS_FS: enabled (as module)
CONFIG_BLK_DEV_DM: enabled (as module)
CGROUPS_CPU: enabled
CGROUPS_CPUACCT: enabled
CGROUPS_CPUSET: enabled
CGROUPS_DEVICES: enabled
CGROUPS_FREEZER: enabled
CGROUPS_MEMORY: missing
DOCKER_VERSION: 17.04.0-ce
[preflight] WARNING: docker version is greater than the most recently validated version. Docker version: 17.04.0-ce. Max validated version: 1.12
[preflight] WARNING: hostname "k8s" could not be reached
[preflight] WARNING: hostname "k8s" lookup k8s on 80.58.61.254:53: no such host
[preflight] Some fatal errors occurred:
   missing cgroups: memory
[preflight] If you know what you are doing, you can skip pre-flight checks with `--skip-preflight-checks`
#
```

La instalación de Kubernetes falla porque no están habilitados los _cgroups_ para la memoria. :(
