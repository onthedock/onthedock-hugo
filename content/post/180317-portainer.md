+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "debian", "docker", "portainer"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/portainer.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" %}}

title=  "Portainer: gestión de servidores Docker"
date = "2018-03-17T21:44:47+01:00"
+++

En una entrada anterior expliqué mi primera toma de contacto con Portainer y cómo usar [Portainer para gestionar tus contenedores en Docker]({{<ref "170429-portainer-para-gestionar-tus-contenedores-en-docker.md" >}}). 

La herramienta -y la [documentación](https://portainer.readthedocs.io/en/stable/)- ha mejorado durante este tiempo, por lo que ahora el proceso es todavía más sencillo y Portainer más potente.
<!--more-->

Portainer es una herramienta gráfica ligera y de código abierto para gestionar servidores Docker. Portainer corre dentro de un contenedor, por lo que puede gestionar el servidor Docker local o conectar con otros servidores Docker (vía el API http).

## Gestión de un servidor local

Tal y como -ahora sí- [se indica en la documentación](https://portainer.readthedocs.io/en/latest/deployment.html#manage-a-new-docker-environment), se puede gestionar el servidor local de Docker desde donde corre Portainer _montando_ el _sock_ UNIX de Docker.

Para que Portainer pueda gestionar el servidor local de Docker, hay que incluir `-v /var/run/docker.sock:/var/run/docker.sock` en el comando `docker run`con el que lanzamos el contenedor de Portainer.

El resto de opciones del comando `docker run` son las habituales:

* `-d` para ejecutar el contenedor en segundo plano
* `--name portainer` para dar un nombre al contenedor
* `-p 9090:9000` para conectar el puerto 9090 del _host_ con el puerto 9000 expuesto en el contenedor. (No uso el 9000 porque hay otra aplicación usando el puerto)
* `-v portainer-data:/data` para persistir la configuración de Portainer fuera del contenedor, en un volumen.
* `-v /var/run/docker.sock:/var/run/docker.sock` monta el _sock_ UNIX en el contenedor.

Con lo que el comando para lanzar Portainer queda:

```shell
docker run -d --name portainer -v portainer-data:/data -v /var/run/docker.sock:/var/run/docker.sock -p 9090:9000 portainer/portainer:1.16.4
```

## Gestión de un servidor remoto

Para configurar el acceso remoto a través del API de Docker, hay que modificar cómo arranca el demonio de Docker. Habililtar el acceso remoto a través del API de Docker puede suponer un riesgo de seguridad **muy importante** si no se realiza correctamente, por lo que es **revisa la documentación** sobre cómo [Protect the Docker daemon socket](https://docs.docker.com/engine/security/https/).

Por convención, se usa el [puerto 2375](https://docs.docker.com/engine/reference/commandline/dockerd/#examples) para la comunicación no encriptada, mientras que para la encriptada se usa el puerto 2376.

> En este artículo se indica cómo usar la comunicación sin encriptar porque se trata de un entorno de laboratorio controlado.

La mejor manera de modificar las opciones de inicio de un fichero _system unit_ es usando un fichero de _override_. 

### Habilita el acceso remoto vía API para Docker

1. Crea el fichero `/etc/systemd/system/docker.service.d/startup_options.conf` con el siguiente contenido tal y como se indica en [How do I enable the remote API for dockerd](https://success.docker.com/article/how-do-i-enable-the-remote-api-for-dockerd):
```shell
# /etc/systemd/system/docker.service.d/override.conf
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:2375
```

1. Recarga los fichero de configuración
  ```shell
   sudo systemctl daemon-reload
  ```

1. Reiniciar el demonio del servicio:
```shell
$ sudo systemctl restart docker-service
```

1. Asegúrate que cualquiera con acceso al _socket_ TCP es un usuario de confianza, ya que el _demonio_ de Docker tiene permisos equivalentes al usuario _root_.

## Configuración del servidor remoto de Docker en Portainer

En el panel lateral de Portainer, selecciona _Endpoints_ e introduce el nombre y la ip:puerto del servidor remoto de Docker:

{{% img src="images/180317/portainer-remote-endpoint.png" %}}

Pulsa sobre el botón _+ Add endpoint_ y Portainer conectará con el servidor remoto de Docker a través de la API.

### Configurando el servidor remoto por defecto

Si sólo vas a gestinar servidores remotos de Docker, puedes especificar en el comando `docker run` los datos de la conexión del servidor:

```shell
docker run -d --name portainer -v portainer-data:/data -p 9090:9000 portainer/portainer:1.16.4 -H tcp://192.168.1.24:2375
```

## Resumen

En esta entrada he explicado cómo configurar Portainer para gestionar servidores Docker locales y remotos. El contenedor se ha lanzado montando un volumen de datos local para persistir la configuración de Portainer.

Para poder gestionar servidores remotos de Docker, se ha explicado cómo habilitar el API de acceso remoto y se han facilitado los enlaces para realizar estas modificaciones de manera segura.