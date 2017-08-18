+++
categories = ["ops"]
tags = ["linux", "debian", "kubernetes", "weave net"]
date = "2017-05-05T22:14:36+02:00"
title = "Instala Weave Net en Kubernetes 1.6"
draft = false
thumbnail = "images/kubernetes.png"

+++

Una de las cosas que más me sorprenden de Kubernetes es que es necesario instalar una _capa de red_ sobre el clúster.

En el caso concreto del que he obtenido las _capturas de pantalla_, el clúster corre sobre máquinas virtuales con Debian Jessie.
<!--more-->

La instalación de Weave Net en Kubernetes consiste únicamente en una línea, como explica el artículo: [Run Weave Net with Kubernetes in Just One Line](https://www.weave.works/weave-net-kubernetes-integration/).

Antes de instalar la _red_ en el clúster (de momento, de un solo nodo), _kubectl_ indica que el estado del nodo es `NotReady`:

```sh
$ kubectl get nodes
NAME      STATUS     AGE       VERSION
k8s       NotReady   5h        v1.6.1
$
```

En la salida del comando tenemos que la versión de Kubernetes es la 1.6.1. Este dato será importante más adelante a la hora de escoger el comando de instalación de Weave Net.

Si obtenemos la lista de _pods_, comprobamos que no tenemos ningún _pod de red_:

```sh
$ kubectl get pods --all-namespaces
NAMESPACE     NAME                          READY     STATUS    RESTARTS   AGE
kube-system   etcd-k8s                      1/1       Running   0          5h
kube-system   kube-apiserver-k8s            1/1       Running   0          5h
kube-system   kube-controller-manager-k8s   1/1       Running   0          5h
kube-system   kube-dns-3913472980-4nlg9     0/3       Pending   0          5h
kube-system   kube-proxy-l02zn              1/1       Running   0          5h
kube-system   kube-scheduler-k8s            1/1       Running   0          5h
$
```

Además, los _pods_ de _DNS_ `kube-dns-*` están en estado `Pending`.

Siguiendo las instrucciones del artículo de Weave Net, lanzamos el comando de instalación para versiones 1.6 (o superior):

```sh
$ kubectl apply -f https://git.io/weave-kube-1.6
clusterrole "weave-net" created
serviceaccount "weave-net" created
clusterrolebinding "weave-net" created
daemonset "weave-net" created
$
```

Obtenemos la lista de _pods_ de nuevo y observamos que se están creando dos nuevos contenedores:

```shell
operador@k8s:~$ kubectl get pods --all-namespaces
NAMESPACE     NAME                          READY     STATUS              RESTARTS   AGE
kube-system   etcd-k8s                      1/1       Running             0          5h
kube-system   kube-apiserver-k8s            1/1       Running             0          5h
kube-system   kube-controller-manager-k8s   1/1       Running             0          5h
kube-system   kube-dns-3913472980-4nlg9     0/3       Pending             0          5h
kube-system   kube-proxy-l02zn              1/1       Running             0          5h
kube-system   kube-scheduler-k8s            1/1       Running             0          5h
kube-system   weave-net-32ptg               0/2       ContainerCreating   0          12s
operador@k8s:~$
```

De hecho, se creado el _daemonset_ "weave-net". Un _daemonset_ es un _pod_ que se crea en cada uno de los nodos del clúster automáticamente. Kubernetes se encarga de descargar la imagen desde DockerHub y arrancar un contenedor. Los nodos en la red creada por Weave Net forman una red _mesh_ que se configura automáticamente, de manera que es posible agregar nodos adicionales sin necesidad de cambiar ninguna configuración.

Pasados unos segundos la creación de los nodos se ha completado:

```sh
$  kubectl get pods --all-namespaces
NAMESPACE     NAME                          READY     STATUS         RESTARTS   AGE
kube-system   etcd-k8s                      1/1       Running        0          5h
kube-system   kube-apiserver-k8s            1/1       Running        0          5h
kube-system   kube-controller-manager-k8s   1/1       Running        0          5h
kube-system   kube-dns-3913472980-4nlg9     0/3       ErrImagePull   0          5h
kube-system   kube-proxy-l02zn              1/1       Running        0          5h
kube-system   kube-scheduler-k8s            1/1       Running        0          5h
kube-system   weave-net-32ptg               2/2       Running        0          1m
$
```

Finalmente, verificamos que el primer nodo del clúster ya es operativo:

```sh
$ kubectl get nodes
NAME      STATUS    AGE       VERSION
k8s       Ready     5h        v1.6.1
$
```

Además, una vez que tenemos la red instalada en el clúster, el _pod_ `kube-dns` comienza la creación de los contenedores (quizás tengas que reiniciar):

```sh
$ kubectl get pods --all-namespaces
NAMESPACE     NAME                          READY     STATUS              RESTARTS   AGE
kube-system   etcd-k8s                      1/1       Running             1          11d
kube-system   kube-apiserver-k8s            1/1       Running             1          11d
kube-system   kube-controller-manager-k8s   1/1       Running             1          11d
kube-system   kube-dns-3913472980-4nlg9     0/3       ContainerCreating   0          11d
kube-system   kube-proxy-l02zn              1/1       Running             1          11d
kube-system   kube-scheduler-k8s            1/1       Running             1          11d
kube-system   weave-net-32ptg               2/2       Running             3          10d
```

Tras unos segundos, tenemos todos los _pods_ del clúster funcionales:

```sh
$ kubectl get pods --all-namespaces
NAMESPACE     NAME                          READY     STATUS    RESTARTS   AGE
kube-system   etcd-k8s                      1/1       Running   1          11d
kube-system   kube-apiserver-k8s            1/1       Running   1          11d
kube-system   kube-controller-manager-k8s   1/1       Running   1          11d
kube-system   kube-dns-3913472980-4nlg9     3/3       Running   0          11d
kube-system   kube-proxy-l02zn              1/1       Running   1          11d
kube-system   kube-scheduler-k8s            1/1       Running   1          11d
kube-system   weave-net-32ptg               2/2       Running   3          10d
$
```

Ahora sólo tenemos que añadir nodos _worker_ y hacer crecer el clúster.