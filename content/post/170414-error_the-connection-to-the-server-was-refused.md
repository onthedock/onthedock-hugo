+++
thumbnail = "images/kubernetes.png"
date = "2017-04-14T18:10:34+02:00"
title = "Error: The connection to the server localhost:8080 was refused"
categories = ["ops"]
tags = ["kubernetes", "errores conocidos"]
draft = false

+++

Después de [conseguir arrancar Kubernetes tras la instalación]({{< ref "170410-k8s-en-rpi-teaser.md" >}}), al intentar ejecutar comandos vía `kubectl` obtengo el mensaje de error `The connection to the server localhost:8080 was refused - did you specify the right host or port?`

A continuación explico cómo solucionar el error y evitar que vuelva a mostrarse.

<!--more-->

En la guía oficial para instalar Kubernetes en Linux con `kubeadm` [Installing Kubernetes on Linux with kubeadm](https://kubernetes.io/docs/getting-started-guides/kubeadm/), en la salida del comando `kubeadm init` en el punto _(2/4) - Initializing your master_, se muestra:


```
Your Kubernetes master has initialized successfully!

To start using your cluster, you need to run (as a regular >user):

 sudo cp /etc/kubernetes/admin.conf $HOME/
 sudo chown $(id -u):$(id -g) $HOME/admin.conf
 export KUBECONFIG=$HOME/admin.conf
```

El problema es que la _exportación_ de la variable de entorno realizada mediante `export KUBECONFIG=$HOME/admin.conf` **se pierde en cuanto se cierra la sesión**. 
Por tanto, cuando reconectamos más tarde, la variable `KUBECONFIG` está vacía y el comando `kubectl` intenta conectar con `localhost:8080`. Como el API server no está escuchando en esta IP y puerto, lo que obtenemos el mensaje de error:

```
The connection to the server localhost:8080 was refused - did you specify the right host or port?
```

Si miramos el contenido del fichero `$HOME/admin.conf` mediante `cat $HOME/admin.conf` encontramos una línea que identifica el servidor: `server: https://192.168.1.11:6443`

Parece que lo único que tenemos que hacer es especificar el servidor como parámetro para `kubectl`, pero...

```shell
$ kubectl get nodes --server=https://192.168.1.11:6443
Please enter Username: pirate
Please enter Password: ********
  Unable to connect to the server: x509: certificate signed by unknown authority
```

> Si usamos el usuario `root`, el resultado es el mismo.

Observando el contenido del fichero `admin.conf` vemos que para el parámetro `user` se especifican certificados (mediante `client-certificate-data` y `client-key-data`):

```
...
users:
- name: kubernetes-admin
  user:
    client-certificate-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUM4akNDQ...
    client-key-data:   LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLQVdLN3JjWDIKY2DIKY2t1c...
$
```

Así que no podemos autenticarnos en el API Server con los usuarios del sistema y tenemos que usar los certificados en el fichero `admin.conf`.

Esto nos lleva de nuevo a la variable `KUBECONFIG`. Si lanzamos el comando `export KUBECONFIG...`, los comandos funcionarán durante la sesión en curso, pero tendremos que lanzar el comando `export` en cada nueva sesión:

```shell
$ export KUBECONFIG=$HOME/admin.conf
```

La solución para que la variable se establezca automáticamente en cada inicio de sesión es añadiéndo el valor en el fichero `$HOME/.bashrc`.

```shell
$ nano $HOME/.bashrc
export KUBECONFIG=$HOME/admin.conf
```

Para verificar que funciona como debe, cierra sesión y vuelve a iniciarla.

Comprueba que puedes lanzar comandos sin problemas:

```shell
$ kubectl get nodes
NAME      STATUS    AGE       VERSION
k1        Ready     3d        v1.6.1
$
```

¡Problema solucionado!

Otra solución alternativa, si no quieres modificar el fichero `$HOME/admin.conf` es pasar la ubicación del fichero como parámetro a `kubectl`: 

```shell
$ kubectl get nodes
The connection to the server localhost:8080 was refused - did you specify the right host or port?
$ kubectl --kubeconfig ./admin.conf get nodes
NAME      STATUS    AGE       VERSION
k1        Ready     3d        v1.6.1
$
```

Puedes usar también este método para conectar, por ejemplo, desde otro equipo al nodo master del clúster (debes copiar primero el fichero `admin.conf` a tu equipo, desde su ubicación original `/etc/kubernetes/admin.conf` o desde la carpeta `$HOME` del usuario, si lo has copiado):

```shell
$ scp pirate@k1.local:/home/pirate/admin.conf .
kubectl --kubeconfig ./admin.conf get nodes
```
