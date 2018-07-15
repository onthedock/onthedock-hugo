+++
draft = false
categories = ["dev"]
tags = ["docker", "docker-compose", "automation", "gitea"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/docker-compose.jpg"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" %}}

title=  "Automatizando la instalación de Gitea (con Docker Compose)"
date = "2018-07-15T11:35:54+02:00"
+++

En la [entrada anterior]({{<ref "180715-automatizando-gitea-sin-docker-compose">}}) explicaba cómo automatizar la instalación de Gitea usando un script y Docker.

Todos los pasos necesarios para crear los volúmenes de datos, la _red interna_ entre Gitea y la base de datos, etc usan Docker.

En esta entrada usaremos [Docker Compose](https://docs.docker.com/compose/) para obtener el mismo resultado y analizar las diferencias entre los dos métodos de instalación.
<!--more-->

# Instalación de Docker Compose

Docker Compose es un producto separado, por lo que es necesario instalarlo en el sistema en primer lugar.

En mi caso, que uso Debian, la instalación es simplemente:

```shell
sudo docker apt install docker-compose
```

En la [página oficial de instalación de Docker Compose](https://docs.docker.com/compose/install/) puedes encontrar el método de instalación más apropiado para tu caso.

# El fichero docker-compose.yml

La principal funcionalidad de Docker Compose es gestionar aplicaciones compuestas por diferentes "piezas". En el caso de Gitea, se trata de dos contenedores, uno con la base de datos y otro con la aplicación Gitea. Como vimos en la entrada anterior, también necesitamos definir un volumen para cada aplicación y una red para que los contenedores se comuniquen entre sí. En la nomenclatura de Docker Compose (similar a la de Kubernetes), cada una de estas _subaplicaciones_ se denomina **service**.

El fichero `docker-compose.yml` contiene toda la configuración necesaria para poner en marcha una aplicación "compleja" formada por diferentes elementos. En el fichero `docker-compose.yml` se define todo lo necesario: imagen base para crear los diferentes contenedores, puertos, volúmenes, variables de entorno, etc...

En DockerHub, [Gitea proporciona una versión de ejemplo](https://hub.docker.com/r/gitea/gitea/) del fichero `docker-compose.yml`. Sin embargo, esta versión usa volumenes de tipo _bind_ (montando una carpeta del _host_), cuando la [recomendación de Docker](https://docs.docker.com/storage/volumes/) es usar volúmenes _named_ (que son portables).

El fichero _corregido_ es el siguiente (también lo puedes consultar en [onthedock/gitea-automation](https://github.com/onthedock/gitea-automation/blob/master/docker-compose.yml):

```yaml
version: "2"
services:
  ui:
    image: gitea/gitea:1.3.2
    volumes:
      - data:/data
    ports:
      - "3000:3000"
      - "2200:22"
    depends_on:
      - db
    networks:
      - net
  db:
    image: mysql:5.7
    environment:
      - MYSQL_ROOT_PASSWORD=WMH3QT6l3Qhkl1XdFGlPEIOGRBOUGxcg
      - MYSQL_DATABASE=gitea
      - MYSQL_USER=gitea
      - MYSQL_PASSWORD=tnaAEFCREGwnn6lzrKh8PQFhzJsDsFHz
    volumes:
      - db-data:/var/lib/mysql
    networks:
      - net
volumes:
  db-data: {}
  data: {}
networks:
net: {}
```

Como puedes ver, el fichero `docker-compose.yml` contiene dos servicios, uno llamado `ui` y otro `db`.

- El servicio `ui` contiene la definición del contenedor para Gitea (imagen, puertos y red a la que está conectado).
- El servicio `db` contiene los detalles del contenedor de base de datos, que en este caso es MySQL.

Un detalle interesante que aporta Docker Compose es la opción `depends_on`, que hace que el contenedor indicado (en este caso, `db`) arranque siempre antes que el contenedor `ui`.

Con respecto a los volúmenes, en vez de especificar una carpeta local del host, usamos el nombre del volumen de datos que usamos para almacenar los datos. La lista de volúmenes se define en la sección `volumes:` del fichero `docker-compose.yml`.

Además de crear los volúmenes de datos especificados en el fichero `docker-compose.yml`, Docker Compose también crea la _user defined bridge network_ necesaria para comunicar los dos contenedores. He especificado la red, definiéndola en la sección `networks:` para obtener el mismo nombre que en la entrada anterior.

Docker Compose precede el nombre de los contenedores creados con el nombre de la carpeta desde la que se lanza el comando `docker-compose up`. En mi caso, la carpeta se llama `gitea`, así que he adaptado los nombres para no tener `gitea_gitea-db`, por ejemplo. En el caso del contenedor de `gitea`, lo he llamado `ui`.

# Verificar la configuración

Una vez creado el fichero `docker-compose.yml`, es conveniente comprobar si es correcto. Para ello, usamos:

```shell
sudo docker-compose config
```

Si al analizar el fichero no se detecta ningún fallo, se muestra el contenido de `docker-compose.yml`.

# Arrancar la aplicación

Docker Compose analiza el contenido del fichero `docker-compose.yml` y realiza todas las acciones necesarias para ejecutar todos los servicios contenidos: crea los volúmnes y las redes definidos, descarga las imágenes base y ejecuta el contenedor publicando los puertos indicados. Y todo con un único comando:

```shell
sudo docker-compose up -d
```

El parámetro `-d` tiene el mismo significado que en Docker: ejecutar los contenedores en modo _detach_, en segundo plano.

```shell
$ sudo docker-compose up -d
Creating network "gitea_net" with the default driver
Creating volume "gitea_db-data" with default driver
Creating volume "gitea_data" with default driver
Creating gitea_db_1
Creating gitea_ui_1
```

En la salida del comando observamos que primero se crea la red, después del volumen para la base de datos, el volumen para Gitea y finalmente el contenedor de base de datos y el contenedor para Gitea.

Del mismo modo, usando `docker-compose stop` podemos parar todos los contenedores implicados de forma ordenada. Y en caso de querer deshacernos de todos los componentes, en vez de crear un _helper script_ como [clean-all.sh](https://github.com/onthedock/gitea-automation/blob/master/clean-all.sh), podemos lanzar `docker-compose down -v`:

```shell
$ sudo docker-compose down -v
Stopping gitea_ui_1 ... done
Stopping gitea_db_1 ... done
Removing gitea_ui_1 ... done
Removing gitea_db_1 ... done
Removing network gitea_net
Removing volume gitea_db-data
Removing volume gitea_data
```

# Comparativa

Por tanto, vemos que en lo que a funcionalidad se refiere, Docker Compose proporciona más funcionalidad -y de forma más sencilla- que un script que realice las mismas tareas.

Además de la facilidad a la hora de poner en marcha aplicaciones con varios componentes, también homogeniza el "lenguaje" usado para interactuar con las tareas de administración: `up` para crear el entorno, `down` para eliminarlo, `start` y `stop` para iniciar o deterner contenedores existentes... Esto simplifica el trabajo del equipo de operaciones/sistemas y ayuda a reducir el coste económico del servicio, por lo que es, sin duda, el camino a tomar en cualquier departamento IT en el que se use Docker.

Desde un punto de vista estratégico, Docker Compose puede también verse como un paso intermedio hacia orquestadores multinodo como Docker Swarm o Kubernetes. Docker Compose _orquesta_ contenedores en un sólo host, pero introduce el concepto de "servicios", que también aparece en Swarm o Kubernetes de forma parecida.

# Personalización

Docker Compose automatiza la creación de los contenedores, pero para poder ofrecer un entorno completamente funcional (sin necesidad de realizar una configuración final), todavía necesitamos un script que realice la modificación del fichero `app.ini` de configuración de Gitea.

El fichero `docker-compose.yml` permite usar sustitución de variables, por lo podríamos definir:

```shell
...
    image: gitea/gitea:$GITEA_VERSION
...
```

Desgraciadamente, aunque en la versión actual de Docker Compose se pueden usar [_secrets_](https://docs.docker.com/compose/compose-file/#secrets), [no se pueden crear _secrets_](https://serverfault.com/questions/871090/how-to-use-docker-secrets-without-a-swarm-cluster) si el nodo en el que se ejecutan los contenedores no forma parte de un _swarm_ (el orquestador multi-nodo de Docker).

# Conclusión

Docker Compose simplifica la gestión de aplicaciones multi-servicio (o multi-contenedor). Las modificaciones o personalizaciones de otros ficheros ajenos a Docker -como ficheros de configuración de las aplicaciones componentes- se realizan usanto scripts. Al reducir la complejidad de los scripts, también deben producirse menos errores en el desarrollo y ejecución de los mismos.