+++
date = "2017-04-29T12:55:04+02:00"
title = "Portainer para monitorizar tus contenedores en Docker"
tags = ["raspberry pi", "docker", "portainer"]
draft = false
thumbnail = "images/docker.png"
categories = ["ops"]

+++

[Portainer](http://portainer.io/) es una herramienta ligera y _open-source_ de gestión de contenedores sobre Docker (o Docker Swarm). Portainer ofrece una interfaz gráfica para gestionar el _host_ Docker desde cualquier navegador, tiene soporte para Raspberry Pi y se puede desplegar como un simple contenedor.

Espero que este artículo ayude a todos aquellos que tengan ganas de probar Portainer y evitarles los problemas que me he encontrado yo.

<!--more-->

He estado buscando algún tipo de solución gráfica para monitorizar las Raspberry Pi ya que, por algún motivo, los nodos _worker_ del clúster de Kubernetes se _cuelgan_.

Buscando alguna solución de monitorizado he encontrado Portainer referenciado en el blog de Hypriot: [Visualize your Raspberry Pi containers with Portainer or UI for Docker](https://blog.hypriot.com/post/new-docker-ui-portainer/).	 

Portainer no es una herramienta de monitorizado (a nivel de _host_), sino que está enfocada a la _visualización_ básicamente del estado de los contenedores de uno (o varios) _endpoints_ Docker (o Docker Swarm). Sin embargo, ofreciendo soporte para ARM y estando disponible en forma de contenedor, no había motivo para no probarlo ;)

# Soporte para ARM

En el apartado para obtener Portainer de la web, sólo se indica el comando:

```shell
docker run -d -p 9000:9000 portainer/portainer
```

Por muy minimalista que quiera ser la página, la verdad es que no les hubiera costado nada indicar que existen diferentes versiones disponibles de la imagen (como por ejemplo, la que proporciona soporte para ARM).

Además, lanzando el comando _tal cual_, si quieres configurar Portainer para monitorizar el nodo _local_, **no funcionará** (requiere montar `/var/run/docker.sock` en el contenedor).

El artículo de Hypriot apunta a una imagen llamada `portainer/portainer:arm`, que ya no existe en DockerHub. Revisando las [etiquetas disponibles para las imágenes de Portainer](https://hub.docker.com/r/portainer/portainer/tags/), encontramos:

```shell
TagName				Compressed Size 	Last Updated 
ppc64le				4 MB			16 days ago
demo				4 MB			23 days ago
latest				0 B 			23 days ago
1.12.4				0 B 			23 days ago
windows-amd64 			337 MB			23 days ago
windows-amd64-1.12.4	 	337 MB			23 days ago
linux-arm64 			4 MB			23 days ago
linux-arm64-1.12.4 		4 MB			23 days ago
linux-arm 			4 MB			23 days ago
linux-arm-1.12.4 		4 MB			23 days ago
linux-amd64 			4 MB			23 days ago
linux-amd64-1.12.4 		4 MB			23 days ago
```

Seleccionamos la versión adecuada para nuestra Raspberry Pi y la descargamos mediante:

```shell
$ docker pull portainer/portainer:linux-arm-1.12.4
linux-arm-1.12.4: Pulling from portainer/portainer
a3ed95caeb02: Pull complete
802d894958a2: Pull complete
30fb5c96d238: Pull complete
Digest: sha256:5269fd824014fac1dee29e2cf74aa5c337cf5c0ceb7cae2634c1e054f5e2763f
Status: Downloaded newer image for portainer/portainer:linux-arm-1.12.4
$
```

A continuación he lanzado la creación del contenedor usando:

```shell
$ docker run -d -p 9000:9000 --name portainer portainer/portainer:linux-arm-1.12.4
d5ad5764788a932cd19942dcb0e70471101173c8d14801b0ce7c172ef9ac72ff
$
```

## Acceso a Portainer

Abre un navegador y accede a `http://IP-nodo:9000/`.

La primera vez que accedes a la URL de Portainer debes introducir el password del usuario `admin`.

{{% img src="images/portainer-1-define-admin-password.png" %}}

Una vez introducido, puedes acceder a la UI de gestión de Portainer.

{{% img src="images/portainer-2-first-login.png" %}}

Para mostrar información sobre los contendores (imágenes, volúmenes, etc) en Docker, Portainer necesita conectarse -vía API- al _host_ en el que corre Docker. Tenemos dos opciones, un _endpoint remoto_ (opción por defecto) o conectar con el _host_ donde corre Portainer:

{{% img src="images/portainer-3-remote_endpoint_by_default.png" %}}

El problema es que, como vemos, al seleccionar un _endpoint_ local, se indica que hay que lanzar el contenedor de Portainer dando acceso al contenedor sobre `/var/run/docker.sock`:

{{% img src="images/portainer-4-local_endpoint_require_docker.sock.png" %}}

Como este _detalle_ no se indica en ningún sitio hasta que estás intentando configurar Portainer, lo más probable es que no hayas lanzado el contenedor con el volumen necesario.

Así que es necesario detener el contenedor -y eliminarlo, si quieres reusar el nombre- y volver a lanzar el proceso de configuración.

No son más que unos pocos comandos en Linux (o en tu Mac), pero sin duda es una molestia que podría evitarse dando algo más de información. Mucho más grave es si el sistema operativo de tu _host_ es Windows, ya que **esta opción no está disponible**.

```shell
$ docker stop portainer
portainer
$ docker rm portainer
portainer
```

## Acceso a Portainer (segundo intento)

Lanzamos el contenedor de Portainer montando `docker.sock` y pasamos por los mismos pasos que en intento anterior:

```shell
$ docker run -d -p 9000:9000 --name portainer -v "/var/run/docker.sock:/var/run/docker.sock" portainer/portainer:linux-arm-1.12.4
3f0ad98393ed5c67cda864737d83fe098a13d1317e1f6c299419ab1a3c1d153c
$
```

Después de validarnos, podemos conectar con el _docker-engine_ local y visualizar el _dashboard_:

{{% img src="images/portainer-5-dashboard.png" %}}

Desde la interfaz web podemos gestionar los contenedores, imágenes y volúmenes existentes:

{{% img src="images/portainer-6-containers.png" caption="Contenedores." %}}

{{% img src="images/portainer-7-images.png" caption="Imágenes." %}}

{{% img src="images/portainer-8-volumes.png" caption="Volúmenes." %}}

En el próximo artículo me concentraré en usar [Portainer](/tags/portainer/) para realizar la gestión de Docker. 