+++
date = "2017-04-10T21:30:31+02:00"
title = "Docker-engine vs Docker.io"
thumbnail = "images/docker.png"
categories = ["linux" , hypriot os", "docker"]
tags = ["dev", "ops"]
draft = false

+++

En función de la distribución que uses, verás que el paquete de instalación de Docker es `docker-engine` o `docker.io`.

¿Cuál es la diferencia entre uno y otro?

<!--more-->

En la guía de instalación de Kubernetes [Installing Kubernetes on Linux with kubeadm](https://kubernetes.io/docs/getting-started-guides/kubeadm/) se indica que para instalar Docker, el comando a usar en Ubuntu o HypriotOS es mediante:

```shell
# apt-get install -y docker.io
```

Sin embargo, cuando he lanzado el comando en HypriotOS me ha llamado la atención el aviso `The following packages will be REMOVED: docker-engine`:

```shell
$ apt-get install -y docker.io
Reading package lists... Done
Building dependency tree
Reading state information... Done
The following package was automatically installed and is no longer required:
  libltdl7
Use 'apt-get autoremove' to remove it.
Suggested packages:
  btrfs-tools debootstrap lxc rinse
The following packages will be REMOVED:
  docker-engine
The following NEW packages will be installed:
  docker.iol
0 upgraded, 1 newy installed, 1 to remove and 0 not upgraded.
Need to get 3,082 kB of archives.
...
```

Así que me ha surgido la duda: ¿qué diferencia hay entre `docker-engine` y `docker.io`?

La respuesta, de la mano de [Quora](https://www.quora.com/What-is-the-difference-between-docker-engine-and-docker-io-packages):

* `docker.io` es mantenido por Ubuntu
* `docker-engine` es mantenido por Docker

`docker.io` era el antiguo dominio para el Proyecto Docker (ahora `docker.com`). Como ya existía un paquete llamado `docker` en los repositorios, desde Ubuntu decidieron usar el nombre `docker.io` como nombre del paquete del Proyecto Docker.

Por su parte, el equipo de Docker mantiene una versión propia de su producto para Ubuntu, a la que llaman `docker-engine`.

Es decir, tanto `docker.io` como `docker-engine` son **el mismo software**, pero gestionado por dos entes diferentes: Ubuntu o Docker Inc.

En mi caso uso HypriotOS, una distribución creada específicamente para Raspberry Pi (plataforma ARM). Los creadores de esta distribución han optado por la versión mantenida por Docker, así que seguiré usando `docker-engine`.

A la práctica, la única diferencia que observarás es al comprobar la versión del paquete, que será `1.12.5` en un caso y `17.04.0-ce` en otro.