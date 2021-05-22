+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev", "ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["docker"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/docker.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}

title=  "Crea un registro local para tus imágenes"
date = "2017-12-02T13:48:17+01:00"
+++

El registro por defecto donde almacenar y compartir las imágenes Docker es [Docker Hub](https://hub.docker.com). Desde un punto de vista empresarial, descargar imágenes desde un registro público supone un riesgo de seguridad.

En esta entrada indico cómo lanzar el registro oficial de Docker en nuestra infraestructura. Una vez en marcha, veremos cómo almacenar las imágenes en el registro local y cómo lanzar contenedores usando las imágenes desde nuestro registro.

<!--more-->

El [registro oficial de Docker](https://docs.docker.com/registry/) es _open source_ bajo [licencia Apache](http://en.wikipedia.org/wiki/Apache_License) y se distribuye como una imagen que puedes obtener desde Docker Hub.

## Arranca tu registro local

Para arrancar una copia local del registro, descarga la imagen [registry](https://hub.docker.com/r/library/registry/) desde Docker Hub y lanza un contenedor mediante:

```shell
docker run -d --name registry -p 5000:5000 registry:2.6
```

En la [página del registro oficial de Docker](https://docs.docker.com/registry/) se usa la imagen con la etiqueta `registry:2`, aunque en mi caso he preferido _afinar_ un poco más y elegir la versión 2.6.

## Usa tu registro local

Para _almacenar_ una imagen en tu registro local, únicamente tienes que etiquetar la imagen de forma habitual, pero con el nombre de la imagen precedido por la url y puerto de acceso al registro.

Obtengo una lista de las imágenes descargadas; observa que tenemos la imagen oficial de `alpine` descargada.

```shell
$ docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
registry            2.6                 177391bcf802        19 hours ago        33.3MB
gogs/gogs           0.11.33             279915be8b49        12 days ago         139MB
gogs/gogs           latest              279915be8b49        12 days ago         139MB
openjdk             7-jdk-alpine        b6bec13008bd        4 weeks ago         142MB
alpine              3.6                 053cde6e8953        4 weeks ago         3.97MB
```

Vamos a almacenarla en la copia local del registro; para ello, primero la etiquetamos indicando la url del registro:

```shell
$ docker tag alpine:3.6 localhost:5000/alpine:3.6
$ docker images
REPOSITORY              TAG                 IMAGE ID            CREATED             SIZE
...
alpine                  3.6                 053cde6e8953        4 weeks ago         3.97MB
localhost:5000/alpine   3.6                 053cde6e8953        4 weeks ago         3.97MB
```

Una vez etiquetada, la _subimos_ al registro:

```shell
$ docker push localhost:5000/alpine:3.6
The push refers to a repository [localhost:5000/alpine]
2aebd096e0e2: Pushed
3.6: digest: sha256:4b8ffaaa896d40622ac10dc6662204f429f1c8c5714be62a6493a7895f664098 size: 528
```

De esta forma tenemos un registro local, aunque únicamente es accesible desde `localhost`. Para poder acceder al registro desde otros equipos corriendo Docker, debemos configurar TLS o deshabilitar la seguridad (cosa que **siempre** es una **mala idea**).

Al intentar subir una imagen desde otro equipo (por ejemplo, desde la RPi), obtenemos un mensaje indicando que debemos usar HTTPS:

```shell
$ docker tag arm32v6/alpine:3.6 192.168.1.10:5000/arm32v6/alpine:3.6
$ docker push 192.168.1.10:5000/arm32v6/alpine:3.6
The push refers to a repository [192.168.1.10:5000/arm32v6/alpine]
Get https://192.168.1.10:5000/v1/_ping: http: server gave HTTP response to HTTPS client
```

En función de las políticas en la empresa el acceso _directo_ al registro local puede estar limitado a un determinado grupo de usuarios. En un entorno de este estilo lo más habitual es usar LDAP para la autenticación (acceso) y autorización (permisos). Si estás interesado en un escenario de este tipo, revisa las "recetas" [Authenticate proxy with apache](https://docs.docker.com/registry/recipes/apache/) o [Authenticate proxy with nginx](https://docs.docker.com/registry/recipes/nginx/).

Para entornos de desarrollo o en escenarios en los que el registro es accesible únicamente a personas de confianza, revisa [Test an insecure registry](https://docs.docker.com/registry/insecure/).

## Usando el registro local de forma insegura

Modificamos la configuración del _daemon_ de Docker en la Raspberry Pi para poder acceder al registro local en la máquina 192.168.1.10.

1. Comprobamos que el fichero `/etc/docker/daemon.json` no existe:
  ```shell
  $ sudo ls /etc/docker
  key.json
  ```

1. Creamos el fichero como se indica en [Test an insecure registry](https://docs.docker.com/registry/insecure/):
  ```shell
  sudo nano /etc/docker/daemon.json
  ```

1. Añadimos la URL y puerto del registro (inseguro):
  ```json
  {
      "insecure-registries" : ["192.168.1.10.com:5000"]
  }
  ```
1. Reiniciamos el _daemon_ de Docker para que los cambios surtan efecto:
  ```shell
  sudo systemctl restart docker
  ```
1. Reintentamos la _subida_ de la imagen al registro:
  ```shell
  $ docker push 192.168.1.10:5000/arm32v6/alpine:3.6
  The push refers to a repository [192.168.1.10:5000/arm32v6/alpine]
  e3dc37acd2b3: Pushed
  35ba648445df: Pushed
  3.6: digest: sha256:a3345a99c99c28312732ae697dbe8b27884f88f0f982e2fab53c99992b411c4a size: 736
  ```

Y en el equipo 192.168.1.10, si revisamos las imágenes almacenadas en el registro usando la API:

```shell
$ wget -qO - localhost:5000/v2/_catalog
{"repositories":["alpine","arm32v6/alpine"]}
```

Como vemos, tenemos la imagen `alpine` subida desde el equipo local y la que hemos subido desde la RPi (llamada `arm32v6/alpine`).

De la misma forma podemos obtener la lista de tags existente para cualquier imagen; por ejemplo, para `arm32v6/alpine`:

```shell
$ wget -qO - http://192.168.1.10:5000/v2/arm32v6/alpine/tags/list
{"name":"arm32v6/alpine","tags":["3.6"]}
```

La lista completa de operaciones soportadas por la API de Docker las puedes encontrar en [Docker Registry HTTP API V2](https://docs.docker.com/registry/spec/api/).

Gestionar tu registro privado desde la línea de comando usando la API no es un escenario común. Afortunadamente, la buena gente de SUSE ha desarrollado [Portus](http://port.us.org), un interfaz web _open source_ para registros privados al que quizás quieras echarle un vistazo.

# Resumen

En esta entrada he creado un registro local y he mencionado algunas de las opciones para _securizar_ el acceso (vía TLS o usando Apache o Nginx como _proxy_). He lanzado un contenedor a partir de la imagen oficial para el **Regystry** de Docker y he "subido" y "descargado" imágenes desde el equipo al registro local.

Por defecto, el registro sólo es accesible usando TLS. Para poder demostrar cómo usar el registro desde otro equipo, he deshabilitado la seguridad y he lanzado `docker push` contra el registro privado.

Finalmente, he comprobado cómo usar la API del registro para validar que se han almacenado las imágenes en el registro local y he apuntado a Portus, para gestionar el registro local a través de un interfaz web.