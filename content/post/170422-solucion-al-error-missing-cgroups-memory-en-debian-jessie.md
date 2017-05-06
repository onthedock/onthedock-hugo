+++
title = "Solución al error de instalación de Kubernetes en Debian Jessie (Missing cgroups: memory)"
thumbnail = "images/kubernetes.png"
categories = ["ops"]
tags = ["linux", "debian", "docker", "kubernetes", "errores conocidos"]
draft = false
date = "2017-04-22T07:57:14+02:00"

+++

Al lanzar la inicialización del clúster con `kubeadm init` en Debian Jessie, las comprobaciones inciales indican que no se encuentran los _cgroups_ para la memoria (échale un vistazo al artículo [La instalación de Kubernetes falla en Debian Jessie (missing cgroups: memory)]({{< relref "post/170417-instalacion-de-kubernetes-falla-missing-cgroups-memory.md" >}})). Los _cgroups_ son una de las piezas fundamentales en las que se basa Docker para _aislar_ los procesos de los contenedores, por lo que la inicialización del clúster de Kubernetes se detiene.

La solución es tan sencilla como habilitar los _cgroups_ durante el arranque.

<!--more-->

En primer lugar, verificamos la versión del _kernel_ que tenemos instalada:

```shell
# uname -a
Linux k8s 3.16.0-4-amd64 #1 SMP Debian 3.16.39-1+deb8u2 (2017-03-07) x86_64 GNU/Linux
```

Al lanzar `kubeadm init` obtenemos el error:

```shell
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
[preflight] Some fatal errors occurred:
	missing cgroups: memory
[preflight] If you know what you are doing, you can skip pre-flight checks with `--skip-preflight-checks`
#
```

## Solución

La solución la he encontrado en [Enable memory cgroups for default Jessie image](https://phabricator.wikimedia.org/T122734).

1. Nos convertimos en _root_: `sudo su -`
1. Editamos el fichero `/etc/default/grup`
1. En los parámetros para el arranque de linux (`GRUB_CMDLINE_LINUX`) añadimos `cgroup_enable=memory`. En mi caso, la línea queda: `GRUB_CMDLINE_LINUX_DEFAULT="quiet cgroup_enable=memory"`
1. Actualizamos _grub_: `update-grub2`
1. Reiniciamos la máquina: `reboot`

```shell
...
[preflight] WARNING: docker version is greater than the most recently validated version. Docker version: 17.04.0-ce. Max validated version: 1.12
[preflight] Some fatal errors occurred:
	missing cgroups: memory
[preflight] If you know what you are doing, you can skip pre-flight checks with `--skip-preflight-checks`
root@k8s:~# nano /etc/default/grub
root@k8s:~# update-grub2
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-3.16.0-4-amd64
Found initrd image: /boot/initrd.img-3.16.0-4-amd64
done
root@k8s:~# reboot
```
Al lanzar `kubeadm init` de nuevo, el clúster arranca con normalidad:

```shell
root@k8s:~# kubeadm init
[kubeadm] WARNING: kubeadm is in beta, please do not use it for production clusters.
[init] Using Kubernetes version: v1.6.0
[init] Using Authorization mode: RBAC
[preflight] Running pre-flight checks
[preflight] WARNING: docker version is greater than the most recently validated version. Docker version: 17.04.0-ce. Max validated version: 1.12
[certificates] Generated CA certificate and key.
[certificates] Generated API server certificate and key.
[certificates] API Server serving cert is signed for DNS names [k8s kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.96.0.1 192.168.1.99]
[certificates] Generated API server kubelet client certificate and key.
[certificates] Generated service account token signing key and public key.
[certificates] Generated front-proxy CA certificate and key.
[certificates] Generated front-proxy client certificate and key.
[certificates] Valid certificates and keys now exist in "/etc/kubernetes/pki"
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/scheduler.conf"
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/admin.conf"
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/kubelet.conf"
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/controller-manager.conf"
[apiclient] Created API client, waiting for the control plane to become ready
[apiclient] All control plane components are healthy after 39.363656 seconds
[apiclient] Waiting for at least one node to register
[apiclient] First node has registered after 1.518215 seconds
[token] Using token: fe9e91.7142118e712eb019
[apiconfig] Created RBAC rules
[addons] Created essential addon: kube-proxy
[addons] Created essential addon: kube-dns

Your Kubernetes master has initialized successfully!

To start using your cluster, you need to run (as a regular user):

  sudo cp /etc/kubernetes/admin.conf $HOME/
  sudo chown $(id -u):$(id -g) $HOME/admin.conf
  export KUBECONFIG=$HOME/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  http://kubernetes.io/docs/admin/addons/

You can now join any number of machines by running the following on each node
as root:

  kubeadm join --token fe9e91.7142118e712eb019 192.168.1.99:6443

root@k8s:~#
```