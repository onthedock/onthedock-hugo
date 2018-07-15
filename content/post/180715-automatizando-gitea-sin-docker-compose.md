+++
draft = false
categories = ["dev"]
tags = ["docker", "gitea", "automatizacion"]
thumbnail = "images/automation.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" %}}

title=  "Automatizando la instalación de Gitea (sin Docker Compose)"
date = "2018-07-15T07:24:54+02:00"
+++

Después de [descubrir Gitea]({{<ref "180713-gitea-la-version-mejorada-de-gogs.md">}}) en la entrada anterior me puse a probarlo... Como desde el principio vi que Gitea sustituiría a Gogs como mi "repositorio local" por defecto, quería tener documentados todos los pasos necesarios para ponerlo en marcha.

Esto significa crear los volúmenes tanto para Gitea como para la base de datos, la red interna para comunicar la base de datos y Gitea y la puesta en marcha de todo ello en los comandos `docker run`. En el caso de la base de datos, los passwords de `root` y del usuario de conexión se pasan como variables de entorno...

Lo más sencillo, decidí, sería crear un script que hiciera el trabajo por mí.

En esta entrada comento el script y algunas de las mejoras que he ido introduciendo.
<!--more-->

El script se encuentra disponible en el repositorio [onthedock/gitea-automation](https://github.com/onthedock/gitea-automation) de GitHub.

# Usando variables

El nombre del usuario para conectar Gitea con la base de datos, el password de este usuario y el de `root` se pasan como variables de entorno en la creación del contenedor MySQL/MariaDB, por lo que tiene sentido ir más allá y usar variables de entorno también para otros parámetros que puedan variar de una instalación a otra.

# Adaptando la configuración de Gitea para usar las variables de entorno

Inicialmente el script únicamente creaba los contenedores de base de datos y de Gitea, pero tras ponerlos en marcha, había que realizar la configuración de Gitea de forma manual.

## Enfoque multi-tenant

Como siempre, intento usar un punto de vista empresarial con respecto a las pruebas que realizo. En esta situación queremos que cada equipo de desarrollo o cada departamento pueda disponer de su propia instancia de Gitea. Este mismo modelo es aplicable a una empresa de servicios que ofrezca "Gitea as a service", con una instalación exclusiva para cada cliente.

En este modelo la configuración y administración de Gitea la realiza el equipo de Operaciones/Sistemas, mientras que el equipo de desarrollo/cliente consume el servicio.

Con esta idea en mente adapté el fichero de configuración de Gitea `app.ini` para usar las variables definidas en el script de instalación. De esta forma, el usuario recibe una instancia de Gitea con la configuración realizada y lo único que tiene que hacer es darse de alta en la aplicación y crear repositorios.

Una modificación interesante sería deshabilitar el auto-registro en Gitea y crear un usuario "administrador", cuyo password se facilitaría al solicitante. De esta manera el cliente puede controlar quién accede a su instancia de Gitea, con qué permisos, etc, en un modelo de _gestión parcial delegada_, por llamarla de algún modo.

## El fichero tpl.app.ini

Para conseguir automatizar la creación de múltiples instancias con una configuración que sea, a la vez, homogénea pero exclusiva, creamos el fichero `tpl.app.ini`.

Este fichero es una copia del fichero `app.ini` de configuración de Gitea al arrancar la aplicación por primera vez (tras la configuración manual).

En el fichero de configuración sustituyo los valores de aquellos parámetros que serán específicos/personalizables para cada usuario por un marcador de posición (_placeholder_).

Usando `sed` en el script de instalación se reemplaza el valor de estos _placeholders_ con el valor definido en las variables del script. Para evitar modificar el fichero "plantilla", tras las modificaciones se crea el fichero `app.ini` que se copiará al contenedor de Gitea.

Usando este método se puden ajustar tantos parámetros como se desee y usar variables en el script para diferenciar una instalación de otra.

En [Configuration Cheat Sheet](https://docs.gitea.io/en-us/config-cheat-sheet/) tienes la lista completa de variables que puedes configurar en el fichero `app.ini`.

# Descargando las imágenes desde DockerHub

En primer lugar se descargan las imágenes de Gitea y de la base de datos que se quiera usar. El valor de la variable `DB` puede ser cualquiera de las bases de datos soportadas por Gitea: MySQL/MariaDB o Postgres (excepto MS SQL Server for Linux). El caso de SQLite no está contemplado porque no requiere un contenedor específico.

# Creando los volúmenes de datos

Tanto la base de datos como Gitea requieren un volumen para persistir datos.

El script los crea usando el valor definido en las variable `GITEA_DB_VOLUME` y `GITEA_DATA_VOLUME`.

```shell
sudo docker volume create $GITEA_DB_VOLUME
```

# Creando la red interna entre Gitea y la base de datos

Las recomendación de Docker es usar una _user defined bridge network_ para comunicar dos contenedores relacionados.

Siguiendo este recomendación, el script crea la red `gitea-net`:

```shell
sudo docker network create gitea-net
```

# Copiando la configuración de Gitea al volumen $GITEA_DATA_VOLUME

En las primeras pruebas, arrancaba el contenedor de Gitea, copiaba el fichero `app.ini` y reiniciaba el contenedor para que los cambios fuera efectivos.

Esto significa tener Gitea se tiene que arrancar dos veces, lo que aumenta el tiempo de espera.

Para optimizar el tiempo de creación de una nueva instancia de Gitea, la versión actual del script usa un contenedor temporal para copiar el fichero de configuración al volumen de datos de Gitea:

```shell
sudo docker run --rm -d --name gitea --mount source=$GITEA_DATA_VOLUME,target=/data gitea/gitea:$GITEA_VERSION sleep 60
sudo docker cp $PWD/app.ini gitea:/data/gitea/conf
sudo docker stop gitea
```

En vez de arrancar Gitea, uso el comando `sleep` para crear un contenedor que monte el volumen de datos de Gitea y a continuación, copio el fichero de configuración "pre-cocinado" usando `docker cp`.

Tras la copia del fichero, detengo el contenedor, que se elimina (gracias a la opción `--rm` en `docker run`).

# Arrancando los contenedores

Una vez tenemos todo preparado, arrancamos el contenedor de la base de datos y el de Gitea.

Al arrancar Gitea encuentra el fichero de configuración en el volumen de datos, por lo que no es necesario realizar ninguna configuración adicional.

En la [siguiente entrada]({{<ref "20180715-automatizando-gitea-con-docker-compose.md">}}) uso [Docker Compose](https://docs.docker.com/compose/) para automatizar la instalación y analizaré similitudes y diferencias con el método _manual_ (Docker y scripts).

> El robot de la cabecera proviene de Wikimedia Commons: [Robotics is fun!](https://commons.wikimedia.org/wiki/File:Robot-clip-art-book-covers-feJCV3-clipart.png) creado por Deepa Avudiappan.