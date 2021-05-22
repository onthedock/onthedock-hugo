+++
draft = true

categories = ["dev", "ops"]

tags = ["linux", "docker", "docker-compose"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/docker-compose.jpg"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}

title=  "¿Usar Docker Compose o Docker?"
date = "2018-07-26T18:23:35+02:00"
+++

En las entradas anteriores automatizaba el despliegue de Gitea usando sólo Docker y usando Docker Compose. El objetivo de Docker Compose es gestionar aplicaciones multicontenedor por lo que si no hay ningún motivo de peso en contra, usaremos siempre Compose.

¿Merece la pena usar también Docker Compose para aplicaciones de un solo contendor?

<!--more-->

En mi opinión, **sí**.

# Aplicación de un sólo contenedor

## Usando Docker

En general, incluso las aplicaciones más simples exponen puertos y montan algún tipo de volumen. Aunque la opción más común es montar una carpeta local del _host_ (_bind mount_), esta opción no es portable (depende de que en otros _hosts_ se hayan creado las mismas carpetas). La solución [recomendada por Docker](https://docs.docker.com/storage/volumes/) es usar _volumes_, gestionados por Docker.

En este caso, primero hay que crear el volumen con `docker volume create {nombre-volumen}`. A continuación, decidir qué puerto del _host_ exponer y a finalmente lanzar el contenedor pasando todos los parámetros desde la línea de comandos:

```shell
docker volume create miapp-data
docker run -d --name miapp -p 8080:80 --mount source=miapp-data,target=/data xaviaznar/app:1.1
```

La gestión del ciclo de vida del contenedor se realiza mediante los comandos: `docker start miapp`, `docker stop miapp`. Si queremos eliminar todo rastro del contenedor usamos `docker rm miapp`. Esto elimina el contenedor, pero deja _huérfano_ el volumen de datos; si queremos eliminarlo también, debemos encargarnos manualmente con `docker volume rm miapp-data`.

Si en vez de eliminarlo, queremos usar una nueva versión de la imagen base, tenemos que:

1. Parar el contenedor `docker stop miapp`
1. Eliminar el contenedor `docker rm miapp` (para poder reusar el nombre `miapp`)
1. Lanzar un nuevo contenedor `docker run -d --name miapp -p 8080:80 --mount source=miapp-data,target=/data xaviaznar/app:2.0`

Como el contenedor se lanzó desde la línea de comandos, no queda "documentado" qué parámetros se han usado para lanzarlo. Por supuesto, podemos usar el comando `history` o _reconstruir_ el comando inspeccionando el contenedor mediante `docker inspect miapp`. En cualquier caso, se trata de un proceso manual propenso a errores.

Otra opción es usar siempre un script "lanzador", del estilo `launch-miapp.sh` (o [`gitea-install.sh`](https://github.com/onthedock/gitea-automation/blob/master/gitea-install.sh)). Estas soluciones _ad-hoc_ no son homogéneas entre los diferentes equipos (o incluso a lo largo del tiempo).

## Usando Compose

El mismo escenario pero usando Docker Compose implica tener que crear un fichero `docker-compose.yml`:

```yaml
version: "2"
services:
  miapp:
   image: xaviaznar/app:1.1
  ports:
    - "8080:80"
  volumes:
    - miapp-data:/data
volumes:
  - miapp-data: {}
```

Para lanzar la aplicación, usaremos `docker-compose up -d`. Además de descargar la imagen base indicada en el fichero `docker-compose.yml` y lanzar el contenedor publicando el puerto especificado, también crea y monta el volumen de datos en el contenedor. También crea una red nridge dedicada.

En este caso, el ciclo de vida de la aplicación es parecido: `docker-compose start` y `docker-compose stop` para arrancar/parar la aplicación. Para eliminarla, podemos elegir borrar sólo el contenedor (conservando el volumen) `docker-compose down` o deshacernos de todo mediante `docker-compose down -v`, lo que también elimina el volumen de datos (y la red _bridge_).

Para actualizar a una nueva versión de la imagen, modificamos el fichero `docker-compose.yml`:

```yaml
...
   image: xaviaznar/app:2.0
...
```

Al tratarse de un fichero, es lógico incluirlo en un sistema de control de versiones como Git y tener controlado cualquier cambio que se realice (facilitando un posible _rollback_ en caso de fallo). Al estar recogidos todos los parámetros en el fichero, lanzamos una nueva versión de la aplicación mediante `docker-compose up -d`.

Docker Compose se encarga de crear (y eliminar, llegado el caso) los volúmenes de datos, la(s) rede(s) creadas, etc, por lo que reduce la complejidad de lanzar las aplicaciones (incluso cuando se trata de un solo contenedor).

Otra ventaja de usar Docker Compose es que homogeniza la gestión de las aplicaciones creadas mediante Compose: un operador no necesita conocer los detalles de puertos, volúmenes, etc que componen la aplicación, ya que están recogidos en el fichero `docker-compose.yml`.  


# Aplicación multicontedor

El objetivo de Docker Compose es la gestión de aplicaciones multicontenedor, por lo que en este caso siempre usaremos Docker Compose.



Con Docker, el trabajo de crear toda la _infraestructura_ adicional al contenedor recae en tus hombros: volúmenes, redes, puertos, etc. Al lanzar el comando `docker run` debes proporcionar todos los parámetros desde la línea de comandos.

Al usar Compose, Docker crea automáticamente los volúmenes necesarios, la red, etc, definidos en el fichero de configuración `docker-compose.yml`; para arrancar todos los contenedores definidos en el fichero `docker-compose.yml`, el comando es siempre `docker-compose up -d`.


