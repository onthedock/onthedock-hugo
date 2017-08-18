+++
title = "Troubleshooting Kubernetes (II)"
thumbnail = "images/kubernetes.png"
categories = ["ops"]
tags = ["raspberry pi", "hypriot os", "kubernetes", "troubleshooting"]
draft = false
date = "2017-05-06T05:21:09+02:00"

+++

Sigo con el _troubleshooting_ del _cuelgue_ de los nodos sobre Raspberry Pi 3 del clúster.

Ayer estuve _haciendo limpieza_ siguiendo _vagamente_ la recomendación de [esta respuesta](https://github.com/kubernetes/kubernetes/issues/43593#issuecomment-288899231) en el hilo [Kubernetes memory consumption explosion](https://github.com/kubernetes/kubernetes/issues/43593#issuecomment-288899231).

<!--more-->

La solución de `RenaudWasTaken` al problema de consumo excesivo de memoria (32GB) fue la realizar limpieza de las carpetas:

* `/var/run/kubernetes`
* `/var/lib/kubelet`
* `/var/lib/etcd`

Antes de empezar a borrar _a lo loco_, revisé el contenido de estas carpetas.

# `/var/run/kubernetes`

En `/var/run/kubernetes`:

```sh
$ ls -la /var/run/kubernetes/
total 8
drwxr-xr-x  2 root root   80 May  5 18:43 .
drwxr-xr-x 18 root root  600 May  5 18:43 ..
-rw-r--r--  1 root root 1082 May  5 18:43 kubelet.crt
-rw-------  1 root root 1679 May  5 18:43 kubelet.key
```

Estos ficheros son certificados, por lo que no parecen implicados en el problema y decido no borrarlos.

# `/var/lib/kubelet`

## Nodo **k2**

Al intentar listar el contenido de la carpeta `/var/lib/kubelet/pods`, la Raspberry Pi 3 ha tardado una eternidad (en los primeros intentos he creído que había dejado de responder).

Finalmente, el resultado del comando ha mostrado una gran cantidad de carpetas dentro de esta carpeta:

```sh
$ ls -la /var/lib/kubelet/pods
...
drwx------    2 root root    4096 May  4 23:11 wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_flannel-cfg.deleting~443381808.deleting~108562981.deleting~938554959.deleting~743974077.deleting~207819844.deleting~559419937.deleting~142152710.deleting~494766199.deleting~952339001
drwx------    2 root root    4096 May  5 18:02 wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_flannel-cfg.deleting~443381808.deleting~108562981.deleting~938554959.deleting~743974077.deleting~274346355.deleting~274250693.deleting~987962315.deleting~680794233.deleting~917929467
drwx------    2 root root    4096 May  4 23:37 wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_flannel-cfg.deleting~443381808.deleting~108562981.deleting~938554959.deleting~743974077.deleting~274346355.deleting~292131322.deleting~049606881.deleting~105942520.deleting~463246644
drwx------    2 root root    4096 May  4 22:46 wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_flannel-cfg.deleting~443381808.deleting~119491600.deleting~962328406.deleting~220005477.deleting~309794961.deleting~392355244.deleting~378832104.deleting~159122214.deleting~324365539
drwx------    2 root root    4096 Apr 15 20:39 wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_flannel-cfg.deleting~443381808.deleting~162549394.deleting~296869341.deleting~353223099.deleting~018715754.deleting~526835026.deleting~320404022.deleting~453576282.deleting~001809150
...
```

Parece como si algo no hubiera funcionado correctamente y hubiera entrado en un bucle, creando carpetas y más carpetas. Además, en el nombre de alguna de estas carpetas aparece `..._flannel-cfg...`. Esta ha sido la pista que me ha convencido; al intentar instalar el _dashboard_ de Kubernetes, tuve problemas precisamente porque no tengo instalado Flannel. Eliminé el _pod_ y no le di más vueltas.

Sin embargo, la existencia de estas carpetas parece indicar que la eliminación no fue tan limpia como pensaba y que _algo_ se quedó atrapado en un bucle.

He lanzado `rm -rf /var/lib/kubelet/pods/` y el comando ha fallado indicando que uno de los _pods_ estaba en uso. Así que he eliminado poco a poco los _pods_ hasta que al final:

```sh
$ ls /var/lib/kubelet/pods/ -la
total 24
drwxr-x--- 4 root root 12288 May  5 18:40 .
drwxr-x--- 4 root root  4096 Apr 15 09:08 ..
drwxr-x--- 5 root root  4096 May  5 18:43 c0323b0f-31bd-11e7-a0ed-b827eb650fdb
drwxr-x--- 5 root root  4096 May  5 18:43 f2da9dfb-31bd-11e7-a0ed-b827eb650fdb
```

Estos _pods_, sean los que sean, están en uso (no tengo nada desplegado en el clúster, así que deben ser _de sistema_).

Tras la limpieza, he reiniciado el nodo.

## Nodo **k3**

El nodo **k3** no presentaba estas _carpetas sospechosas_, pero también he realizado limpieza:

```sh
$ rm -rf /var/lib/kubelet/pods/
rm: cannot remove ‘/var/lib/kubelet/pods/3a5e2819-21e5-11e7-bcfd-b827eb650fdb/volumes/kubernetes.io~configmap’: Directory not empty
rm: cannot remove ‘/var/lib/kubelet/pods/71290201-31bb-11e7-a0ed-b827eb650fdb/volumes/kubernetes.io~secret/kube-proxy-token-7zk2k’: Device or resource busy
rm: cannot remove ‘/var/lib/kubelet/pods/ef887c6a-31ba-11e7-a0ed-b827eb650fdb/volumes/kubernetes.io~secret/weave-net-token-61scv’: Device or resource busy
$
```

Igual que en el nodo **k2**, he reiniciado.

# Resultados

Los nodos **k2** y **k3** siguen en estado `Ready` tras unas siete y ocho horas, que es bastante más de lo que _aguantaban_ antes.

He comprobado que en la carpeta `/var/lib/kubelet/pods` sólo aparecen dos _pods_ (en el nodo **k2**):

```sh
$ ls -la /var/lib/kubelet/pods/
total 24
drwxr-x--- 4 root root 12288 May  5 18:40 .
drwxr-x--- 4 root root  4096 Apr 15 09:08 ..
drwxr-x--- 5 root root  4096 May  5 18:43 c0323b0f-31bd-11e7-a0ed-b827eb650fdb
drwxr-x--- 5 root root  4096 May  5 18:43 f2da9dfb-31bd-11e7-a0ed-b827eb650fdb
$
```

En el nodo **k3**:

```sh
$ ls -la /var/lib/kubelet/pods/
total 28
drwxr-x--- 5 root root 12288 May  5 19:44 .
drwxr-x--- 4 root root  4096 Apr 15 14:10 ..
drwxr-x--- 3 root root  4096 May  5 19:33 3a5e2819-21e5-11e7-bcfd-b827eb650fdb
drwxr-x--- 5 root root  4096 May  5 19:37 514d4c93-31c9-11e7-a0ed-b827eb650fdb
drwxr-x--- 5 root root  4096 May  5 19:37 c0b9753a-31c9-11e7-a0ed-b827eb650fdb
$
```

Más adelante actualizaré el artículo para verificar si los nodos siguen activos y sin problemas.
