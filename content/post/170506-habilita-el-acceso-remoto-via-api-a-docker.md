+++
date = "2017-05-06T15:23:36+02:00"
title = "Habilita el acceso remoto vía API a Docker"
categories = ["dev", "ops"]
tags = ["linux", "debian", "docker"]
draft = false
thumbnail = "images/docker.png"

+++

Portainer permite gestionar _endpoints_ remotos para Docker (y Docker Swarm) mediante el API REST de Docker Engine. El problema es que el API está desactivado por defecto.

A continuación indico cómo activar y verificar el acceso remoto al API de Docker Engine.

<!--more-->

Buscando en Google cómo habilitar el API remoto de Docker Engine probablemente encuentres el artículo 
[Enabling Docker Remote API on Ubuntu 16.04](https://www.ivankrizsan.se/2016/05/18/enabling-docker-remote-api-on-ubuntu-16-04/). Como bien dice en el párrafo inicial, no es fácil encontrar unas instrucciones claras sobre cómo configurar el API de principio a fin.


Lanzando `docker man`, vemos que la opción que buscamos es:

```
-H, --host=[unix:///var/run/docker.sock]: tcp://[host]:[port][path] to bind or
       unix://[/path/to/socket] to use.
         The socket(s) to bind to in daemon mode specified using one or more
         tcp://host:port/path, unix:///path/to/socket, fd://* or fd://socketfd.
         If the tcp port is not specified, then it will default to either 2375 when
         --tls is off, or 2376 when --tls is on, or --tlsverify is specified.
```

Esta opción debe pasarse en el arranque del _daemon_ de Docker. Para configurar esta opción durante el arranque de Docker Engine tenemos dos opciones:

* modificar el arranque del _daemon_ modificando la configuración de `/lib/systemd/system/docker.service`
* añadiendo las opciones en el fichero de configuración de Docker Engine. Para sistemas Linux con _systemd_, la [configuración del _daemon_ de Docker](https://docs.docker.com/engine/admin/systemd/#start-automatically-at-system-boot) se realiza a través del fichero `daemon.json` ubicado en `/etc/docker/`.

> He intentado configurar Docker Engine mediante el segundo método _daemon.json_ pero no he sido capaz de activar el API.

Primero, hacemos una copia de seguridad del fichero `/lib/systemd/system/docker.service`:

```sh
# cp /lib/systemd/system/docker.service /lib/systemd/system/docker.service.original
#
```

Editamos el fichero `/lib/systemd/system/docker.service`

```sh
# nano /lib/systemd/system/docker.service
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target docker.socket firewalld.service
Wants=network-online.target
Requires=docker.socket

[Service]
Type=notify
# the default is not to use systemd for cgroups because the delegate issues still
# exists and systemd currently does not support the cgroup feature set required
# for containers run by docker
ExecStart=/usr/bin/dockerd -H fd:// 
ExecReload=/bin/kill -s HUP $MAINPID
LimitNOFILE=1048576
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity
# Uncomment TasksMax if your systemd version supports it.
# Only systemd 226 and above support this version.
#TasksMax=infinity
TimeoutStartSec=0
# set delegate yes so that systemd does not reset the cgroups of docker containers
Delegate=yes
# kill only the docker process, not all processes in the cgroup
KillMode=process
# restart the docker process if it exits prematurely
Restart=on-failure
StartLimitBurst=3
StartLimitInterval=60s

[Install]
WantedBy=multi-user.target
```

Modificamos la línea `ExecStart=/usr/bin/dockerd -H fd://` y añadimos: `-H tcp://0.0.0.0:2375` de manera que quede:

```txt
ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:2375
```

> Esto hace que _dockerd_ escuche en todas las interfaces disponibles. En el caso de la máquina virtual en la que estoy probando, sólo tengo una, pero lo correcto sería especificar la dirección IP donde quieres que escuche _dockerd_.

Guardamos los cambios.

Recargamos la configuración y reiniciamos el servicio.

Para comprobar que hemos el API funciona, lanzamos una consulta usando _curl_:

```sh
# systemctl daemon-reload
# systemctl restart docker
# curl http://localhost:2375/version
{"Version":"17.05.0-ce","ApiVersion":"1.29","MinAPIVersion":"1.12","GitCommit":"89658be","GoVersion":"go1.7.5","Os":"linux","Arch":"amd64","KernelVersion":"3.16.0-4-amd64","BuildTime":"2017-05-04T22:04:27.257991431+00:00"}
#
```

> Debes tener en cuenta que esta configuración **supone un riesgo de seguridad** al permitir el acceso al API de Docker Engine sin ningún tipo de control.