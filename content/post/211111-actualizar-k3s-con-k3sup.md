+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "kubernetes", "k3s", "k3sup"]

# Optional, referenced at `$HUGO_ROOT/static/images/k3s.jpg`
thumbnail = "images/k3s.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}

title=  "Actualizar k3s con k3sup"
date = "2021-11-11T21:32:41+01:00"
+++
[k3sup](https://github.com/alexellis/k3sup) es una herramienta que permite instalar clústers de Kubernetes basados en [K3s](https://k3s.io/) [en menos de un minuto](https://github.com/alexellis/k3sup#demo-). Pero acabo de descubrir que además, también permite actualizar el clúster.
<!--more-->

A través de las respuestas al *issue* [[Documentation] Upgrading k3s master and workers to newer versions of k3s](https://github.com/alexellis/k3sup/issues/161) he descubierto que relanzando el *script* sobre un clúster existente, se actualiza la versión de k3s (sólo las actualizaciones de *patch*). En mi caso, he pasado de 1.19.4 a 1.19.16.

> La actualización se realiza porque no se especifica una versión concreta con el parámetro `--k3s-version`.

Para actualizar a una versión *minor*, debe especificarse en la versión como parámetro de k3sup (tanto el de instalación como el de *join*) de los nodos del clúster. He modificado el *script* que uso (del que ya hablé en [Provisionar Kubernetes con Vagrant y k3sup]({{< ref "210919-provisionar-kubernetes-con-vagrant-y-k3sup-1.md" >}})) para crear el clúster sobre máquinas Vagrant añadiendo la última versión de k3s:

> El *script* se encuentra en el repositorio `onthedock/vagrant`: [k3s-cluster-install.sh](https://github.com/onthedock/vagrant/blob/main/k3s-ubuntu-cluster/k3s-cluster-install.sh)

```bash
#!/usr/bin/env bash

IPControlPlaneNode=192.168.1.101
IPWorkerNode1=192.168.1.102
IPWorkerNode2=192.168.1.103
REMOTE_USER=operador
K3S_VERSION="v1.22.3+k3s1"

# Install the ControlPlane
k3sup install --ip $IPControlPlaneNode \
              --user $REMOTE_USER \
              --k3s-extra-args='--flannel-iface enp0s8' \
              --k3s-version $K3S_VERSION
              
# Install the agents/worker nodes
k3sup join --ip $IPWorkerNode1 \
           --server-ip $IPControlPlaneNode\
           --user $REMOTE_USER\
           --k3s-extra-args='--flannel-iface enp0s8' \
           --k3s-version $K3S_VERSION

k3sup join --ip $IPWorkerNode2 \
           --server-ip $IPControlPlaneNode \
           --user $REMOTE_USER \
           --k3s-extra-args='--flannel-iface enp0s8' \
           --k3s-version $K3S_VERSION
```

> Sí, todavía sigo sin resolver el *issue #1* : [El nombre de la tarjeta de red "bridged" está fijado en el Vagrantfile](https://github.com/onthedock/vagrant/issues/1).

He probado la actualización en un clúster prácticamente vacío; sólo había desplegado [Longhorn](https://longhorn.io/). La actualización ha vuelto a configurar la *storageClass* `local-path` como *storageClass* por defecto del clúster:

```bash
$ kubectl get storageclass
NAME                   PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
longhorn (default)     driver.longhorn.io      Delete          Immediate              true                   3h38m
local-path (default)   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  46d
```

Como se indica en la documentación de Kubernetes [Change the default StorageClass](https://kubernetes.io/docs/tasks/administer-cluster/change-default-storage-class/#changing-the-default-storageclass):

> If two or more of them are marked as default, a `PersistentVolumeClaim` without `storageClassName` explicitly specified cannot be created.

Por tanto, como siempre, antes de realizar una actualización de este tipo asegúrate de tener un *backup* del clúster.

## Dejando sólo una *storageClass* por defecto

En mi caso, solucionar el problema de múltiples *storageClass* por defecto es sencillo; sólo una *storageClass* en el clúster debe incluir la anotación `storageclass.kubernetes.io/is-defult-class=true`; el resto deben tener el valor a `false`.

Modificamos el valor para la *storageClass* `local-path`:

```bash
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
```

Y validamos que sólo tenemos una *storageClass* por defecto:

```bash
$ kubectl get storageclass
NAME                 PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
longhorn (default)   driver.longhorn.io      Delete          Immediate              true                   3h43m
local-path           rancher.io/local-path   Delete          WaitForFirstConsumer   false                  46d
```

Tengo pendiente probar las actualizaciones mediante el *System Upgrade Controller* propio de Rancher: [Upgrade a K3s Kubernetes Cluster with System Upgrade Controller](https://www.suse.com/c/rancher_blog/upgrade-a-k3s-kubernetes-cluster-with-system-upgrade-controller/).

## Actualizando `kubectl`

Al haber instalado Kubernetes 1.22, las versiones de `kubectl` [soportadas](https://kubernetes.io/releases/version-skew-policy/#kubectl) son 1.21, 1.22 y 1.23... Así que toca actualizar:

```bash
$ kubectl version --short
Client Version: v1.19.4
Server Version: v1.22.3+k3s1
```

Seguimos las instrucciones de la documentación oficial para [Instalar y Configurar kubectl](https://kubernetes.io/es/docs/tasks/tools/install-kubectl/) (la última versión disponible, 1.22):

```bash
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
```

Instalamos:

```bash
sudo install kubectl /usr/local/bin
```

Y validamos que se ha actualizado a la última versión:

```bash
$ kubectl version --short
Client Version: v1.22.3
Server Version: v1.22.3+k3s1
```
