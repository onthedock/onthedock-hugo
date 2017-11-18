+++
draft = false

categories = ["dev", "ops"]
tags = ["raspberry pi", "linux", "kubernetes"]

thumbnail = "images/kubernetes.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# YouTube
# {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Imagenes
# {{% img src="images/image.jpg" w="600" h="400" %}}
# {{% img src="images/image.jpg" w="600" h="400" class="right" %}}
# {{% img src="images/image.jpg" w="600" h="400" class="left" %}}
# {{% img src="images/image.jpg" w="600" h="400" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# Clear (floats)
# {{% clear %}}
# Twitter
# {{% twitter tweetid="780599416621297xxx" %}}

title=  "Single node cluster en la RPi3"
date = "2017-11-11T12:08:36+01:00"
+++

En la entrada anterior [API server detenido: The connection to the server was refused]({{<ref "171104-apiserver-detenido.md">}}) encontré problemas con la tarjeta microSD que sirve de almacenamiento para el nodo master del clúster de Kubernetes.

La solución al problema pasaba por realizar un análisis de la tarjeta para repararla. Sin embargo, al intentarlo, no ha habido manera de formatear y reinstalar HypriotOS sobre la tarjeta.

El fallo de la tarjeta de memoria ha sido la gota final que me ha hecho abandonar el clúster multinodo en las Raspberry Pi (de momento). Así que he decidido instalar un clúster de un solo nodo en una de las Raspberri Pi 3.

En este artículo sigo las instrucciones oficiales para construir un clúster de Kubernetes usando _kubeadm_: [Using kubeadm to Create a Cluster](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/)

<!--more-->

Las instrucciones en la página oficial de Kubernetes son precisas y no hace falta realizar ninguna adaptación o modificación para instalar Kubernetes en una Raspberry Pi con Hypriot OS.

Para poder instalar Kubernetes usando _kubeadm_, el primer requerimiento es tener instalado _kubeadm_. Las instrucciones para instalarlo se encuentran en [Installing kubeadm](https://kubernetes.io/docs/setup/independent/install-kubeadm/).

Los requerimientos para poder instalar _kubeadm_ y Kubernetes ya se dan en Hypriot OS (por ejemplo, tener desactivada la _swap_).

HypriotOS también viene equipado de serie con Docker:

```shell
$ docker version
Client:
 Version:      17.05.0-ce
 API version:  1.29
 Go version:   go1.7.5
 Git commit:   89658be
 Built:        Thu May  4 22:30:54 2017
 OS/Arch:      linux/arm

Server:
 Version:      17.05.0-ce
 API version:  1.29 (minimum version 1.12)
 Go version:   go1.7.5
 Git commit:   89658be
 Built:        Thu May  4 22:30:54 2017
 OS/Arch:      linux/arm
 Experimental: false
```

El  siguiente paso es instalar _kubeadm_, _kubelet_ y _kubectl_. Para ello, primero nos convertimos en el usuario `root` mediante:

```shell
sudo -i
```

Actualizamos el índice de paquetes e instalamos `apt-transport-https` (aunque HypriotOS también los trae de fábrica):

```shell
$ apt-get update && apt-get install -y apt-transport-https
Get:1 http://mirrordirector.raspbian.org jessie InRelease [14.9 kB]
Get:2 http://archive.raspberrypi.org jessie InRelease [22.9 kB]
...
Reading state information... Done
apt-transport-https is already the newest version.
0 upgraded, 0 newly installed, 0 to remove and 41 not upgraded.
```

Instalamos la clave pública del repositorio de Google, añadimos el repositorio de Kubernetes, actualiazamos e instalamos.

```shell
$ curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
OK
$ cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
> deb http://apt.kubernetes.io/ kubernetes-xenial main
> EOF
$ apt-get update
Hit http://mirrordirector.raspbian.org jessie InRelease
Hit https://apt.dockerproject.org raspbian-jessie InRelease
...
Fetched 15.1 kB in 14s (1056 B/s)
Reading package lists... Done
```

Lanzamos la instalación:

```shell
$ apt-get install -y kubelet kubeadm kubectl
Reading package lists... Done
Building dependency tree
Reading state information... Done
The following extra packages will be installed:
  ebtables kubernetes-cni socat
The following NEW packages will be installed:
  ebtables kubeadm kubectl kubelet kubernetes-cni socat
0 upgraded, 6 newly installed, 0 to remove and 41 not upgraded.
Need to get 46.7 MB of archives.
After this operation, 321 MB of additional disk space will be used.
Get:1 http://mirrordirector.raspbian.org/raspbian/ jessie/main ebtables armhf 2.0.10.4-3 [97.1 kB]
...
Fetched 46.7 MB in 22s (2077 kB/s)
...
Selecting previously unselected package ebtables.
(Reading database ... 20831 files and directories currently installed.)
Preparing to unpack .../ebtables_2.0.10.4-3_armhf.deb ...
Unpacking ebtables (2.0.10.4-3) ...
Selecting previously unselected package kubernetes-cni.
Preparing to unpack .../kubernetes-cni_0.5.1-00_armhf.deb ...
Unpacking kubernetes-cni (0.5.1-00) ...
Selecting previously unselected package socat.
Preparing to unpack .../socat_1.7.2.4-2_armhf.deb ...
Unpacking socat (1.7.2.4-2) ...
Selecting previously unselected package kubelet.
Preparing to unpack .../kubelet_1.8.2-00_armhf.deb ...
Unpacking kubelet (1.8.2-00) ...
Selecting previously unselected package kubectl.
Preparing to unpack .../kubectl_1.8.2-00_armhf.deb ...
Unpacking kubectl (1.8.2-00) ...
Selecting previously unselected package kubeadm.
Preparing to unpack .../kubeadm_1.8.2-00_armhf.deb ...
Unpacking kubeadm (1.8.2-00) ...
Processing triggers for systemd (215-17+deb8u7) ...
Processing triggers for man-db (2.7.0.2-5) ...
Setting up ebtables (2.0.10.4-3) ...
update-rc.d: warning: start and stop actions are no longer supported; falling back to defaults
Setting up kubernetes-cni (0.5.1-00) ...
Setting up socat (1.7.2.4-2) ...
Setting up kubelet (1.8.2-00) ...
Setting up kubectl (1.8.2-00) ...
Setting up kubeadm (1.8.2-00) ...
Processing triggers for systemd (215-17+deb8u7) ...
```

## Inicializando el clúster

Tras el paso previo de la instalación de _kubeadm_, lanzamos `kubeadm init`, que inicializa el clúster.

En primer lugar, _kubeadm_ realiza comprobaciones antes de lanzar la descargar de las diferentes imágenes de los elementos del _control plane_ (lo que puede llevar más o menos tiempo, en función de la velocidad de tu conexión). Finalmente, _kubeadm_ muestra instrucciones sobre los siguientes pasos a seguir tras la inicialización del clúster:

```shell
$ kubeadm init
[kubeadm] WARNING: kubeadm is in beta, please do not use it for production clusters.
[init] Using Kubernetes version: v1.8.2
[init] Using Authorization modes: [Node RBAC]
[preflight] Running pre-flight checks
[preflight] WARNING: docker version is greater than the most recently validated version. Docker version: 17.05.0-ce. Max validated version: 17.03
[kubeadm] WARNING: starting in 1.8, tokens expire after 24 hours by default (if you require a non-expiring token use --token-ttl 0)
[certificates] Generated ca certificate and key.
[certificates] Generated apiserver certificate and key.
[certificates] apiserver serving cert is signed for DNS names [snc kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.96.0.1 192.168.1.12]
[certificates] Generated apiserver-kubelet-client certificate and key.
[certificates] Generated sa key and public key.
[certificates] Generated front-proxy-ca certificate and key.
[certificates] Generated front-proxy-client certificate and key.
[certificates] Valid certificates and keys now exist in "/etc/kubernetes/pki"
[kubeconfig] Wrote KubeConfig file to disk: "admin.conf"
[kubeconfig] Wrote KubeConfig file to disk: "kubelet.conf"
[kubeconfig] Wrote KubeConfig file to disk: "controller-manager.conf"
[kubeconfig] Wrote KubeConfig file to disk: "scheduler.conf"
[controlplane] Wrote Static Pod manifest for component kube-apiserver to "/etc/kubernetes/manifests/kube-apiserver.yaml"
[controlplane] Wrote Static Pod manifest for component kube-controller-manager to "/etc/kubernetes/manifests/kube-controller-manager.yaml"
[controlplane] Wrote Static Pod manifest for component kube-scheduler to "/etc/kubernetes/manifests/kube-scheduler.yaml"
[etcd] Wrote Static Pod manifest for a local etcd instance to "/etc/kubernetes/manifests/etcd.yaml"
[init] Waiting for the kubelet to boot up the control plane as Static Pods from directory "/etc/kubernetes/manifests"
[init] This often takes around a minute; or longer if the control plane images have to be pulled.
[apiclient] All control plane components are healthy after 1075.017001 seconds
[uploadconfig] Storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[markmaster] Will mark node snc as master by adding a label and a taint
[markmaster] Master snc tainted and labelled with key/value: node-role.kubernetes.io/master=""
[bootstraptoken] Using token: fac7e9.cb99bb58fed9ad44
[bootstraptoken] Configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstraptoken] Configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstraptoken] Configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[bootstraptoken] Creating the "cluster-info" ConfigMap in the "kube-public" namespace
[addons] Applied essential addon: kube-dns
[addons] Applied essential addon: kube-proxy

Your Kubernetes master has initialized successfully!

To start using your cluster, you need to run (as a regular user):

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  http://kubernetes.io/docs/admin/addons/

You can now join any number of machines by running the following on each node
as root:

  kubeadm join --token fac7e9.cb99bb58fed9ad44 192.168.1.12:6443 --discovery-token-ca-cert-hash sha256:03052b3455bba2e4d9713f55831807c5d6ad69525398620d889586ba2ab663b1
```

Como puedes ver en la salida del comando `kubeadm init`, para poder utilizar _kubectl_ como un usuario sin privilegios, debes copiar (como usuario, no como `root`) la configuración de Kubernetes a tu carpeta `$HOME`.

Realizaremos estas acciones una vez hayamos finalizado la instalación de la red para los _pods_. La red **debe desplegarse antes que cualquier aplicación en el nodo**.

Si queremos unir nodos adicionales al clúster, podemos apuntar el _token_ generado para ello. En este caso nuestro clúster sólo va a tener un nodo, por lo que no será necesario usar el token.

En cualquier caso, puedes recuperar el _token_ para usarlo en cualquier otro momento como explicaba en la entrada [Cómo agregar un nodo a un cluster Kubernetes]({{<ref "170417-como-agregar-un-nodo-a-un-cluster-kubernetes.md">}})

> El descubrimiento basado en _tokens_ es el método por defecto en Kubernetes 1.8; el parámetro `--discovery-token-ca-cert-hash` no era requerido en versiones anteriores. Puedes leer más en [kubeadm Setup Tool Reference Guide](https://kubernetes.io/docs/admin/kubeadm/)


## Instalación de la red de _pods_

Después de los problemas que tuve en el pasado con _Flannel_, siempre instalado Weave como red para los _pods_ en mis clústers.

La instalación de la red de _pods_ de Weave Net puedes encontrarla en el enlace [Integrating Kubernetes via the Addon](https://www.weave.works/docs/net/latest/kubernetes/kube-addon/) de la lista de [Add-Ons](https://kubernetes.io/docs/concepts/cluster-administration/addons/) de Kubernetes.

> El comando de instalación de Weave Net requiere Kubernetes 1.4 o superior

```shell
$ kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
serviceaccount "weave-net" created
clusterrole "weave-net" created
clusterrolebinding "weave-net" created
daemonset "weave-net" created
```

## Habilita _kubectl_ para usuarios sin privilegios

Una vez hemos finalizado la instalación e inicialización del nodo master, nos deshacemos de los privilegios de `root` y realizamos la copia del fichero de configuración de _kubectl_ para poder usarlo como un usuario "normal":

```shell
$ mkdir -p $HOME/.kube
$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
$ sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Verificamos que funciona lanzando, por ejemplo:

```shell
$ kubectl get pods --all-namespaces
NAMESPACE     NAME                          READY     STATUS              RESTARTS   AGE
kube-system   etcd-snc                      1/1       Running             0          26m
kube-system   kube-apiserver-snc            1/1       Running             0          26m
kube-system   kube-controller-manager-snc   1/1       Running             0          18m
kube-system   kube-dns-66ffd5c588-xrb6m     0/3       Pending             0          18m
kube-system   kube-proxy-ppwxd              1/1       Running             0          18m
kube-system   kube-scheduler-snc            1/1       Running             0          26m
kube-system   weave-net-mq5pz               0/2       ContainerCreating   0          46s
```

> En la salida del comando vemos que el DNS interno todavía está pendiente de la creación de los contenedores de la red de _pods_ de Weave Net.

## Habilitar el despliegue de _pods_ en el nodo master

Por defecto, el planificador (_scheduler_) de Kubernetes sólo asigna _pods_ en los nodos _worker_.

Para cambiar el comportamiento por defecto y poder usar la Raspberry Pi como un clúster de un solo nodo (con roles Master y Worker), usamos:

```shell
$ kubectl taint nodes --all node-role.kubernetes.io/master-
node "snc" untainted
```

## Resumen

En esta entrada hemos instalado y configurado el nodo master de una instalación de Kubernetes usando _kubeadm_. Una vez finalizada la inicialización del clúster, hemos eliminado el _taint_ en el nodo para que puedan desplegarse _pods_ en este nodo, convirtiendo la Raspberry Pi en un clúster de Kubernetes de un solo nodo.
