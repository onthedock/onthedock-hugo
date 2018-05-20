+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev", "ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "docker", "integracion continua", "devops", "gogs"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/gogs.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" %}}

title=  "Pipeline: Gogs - El repositorio de código"
date = "2018-05-20T07:30:49+02:00"
+++

[Gogs](https://gogs.io) es un servidor de Git escrito en Go. Proporciona un interfaz web similar a GitHub.

En esta entrada se describe cómo lanzar los contenedores necesarios para tener una instalación funcional de Gogs.

<!--more-->

Gogs requiere el uso de una base de datos para almacenar parte de la información. Gogs puede usar una base de datos incrustada como SQLite, aunque lo recomendable es unar algo como MySQL o PostgresSQL.

En nuestro caso usaremos MySQL.

La instalación de Gogs consta de tres bloques:

1. Creación de la red brigde para conectar MySQL y Gogs
1. Instalación de MySQL
   1. Creación del volumen para la base de datos
   1. Creación del contenedor con el motor de base de datos MySQL
1. Instalación de Gogs
   1. Creación del volumen para los repositorios y configuración de Gogs
   1. Creación del contenedor con Gogs

# Creación de la red bridge para conectar MySQL y Gogs

Como comentaba en la entrada [Consideraciones generales]({{< ref "180519-pipeline-consideraciones-generales.md" >}}), en internet se pueden encontrar muchos ejemplos en los que se usan el parámetro `—link`  para conectar dos contenedores entre sí. Sin embargo este parámetro está considerado [_legacy_](https://docs.docker.com/network/links/) y puede ser eliminado en cualquier versión de Docker, por lo que no es conveniente usarlo.

La alternativa es usar una _red puente definida por el usuario (user-defined bridge network_). Esta es la forma recomendada en la documentación de MySQL para desplegar MySQL en Linux con Docker: [Connect to MySQL from an Application in Another Docker Container](https://dev.mysql.com/doc/mysql-installation-excerpt/5.7/en/docker-mysql-more-topics.html#docker-app-in-another-container).

Creamos la red _bridge_ a la que llamamos `backend-gogs`:

```shell
$ sudo docker network create backend-gogs
3e38ebb671bf595201f0d3cb37e6a6138d0f05025c1f581e3bd8cc84c844c79f
$
```

Comprobamos que además de las redes creadas por defecto por Docker, ahora tenemos una red _bridge_ adicional:

```shell
$ sudo docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
f53cd8a2520d        bridge              bridge              local
3cb879caa2f8        host                host                local
3e38ebb671bf        backend-gogs        bridge              local
30f938dfeaa1        none                null                local
$
```

# Instalación de MySQL

## Creación del volumen para la base de datos

Para almacenar los datos de la base de datos, creamos un volumen llamado `data-mysql-gogs`:

```shell
$ sudo docker volume create data-mysql-gogs
data-mysql
```

## Creación del contenedor con el motor de base de datos MySQL

Descargamos la imagen de MySQL

```shell
$ sudo docker pull mysql:5.7
5.7: Pulling from library/mysql
2a72cbf407d6: Pull complete
38680a9b47a8: Pull complete
4c732aa0eb1b: Pull complete
c5317a34eddd: Pull complete
f92be680366c: Pull complete
e8ecd8bec5ab: Pull complete
2a650284a6a8: Pull complete
5b5108d08c6d: Pull complete
beaff1261757: Pull complete
c1a55c6375b5: Pull complete
8181cde51c65: Pull complete
Digest: sha256:691c55aabb3c4e3b89b953dd2f022f7ea845e5443954767d321d5f5fa394e28c
Status: Downloaded newer image for mysql:5.7
$
```

Lanzamos el contenedor con _MySQL_ usando el volumen que hemos creado anteriormente:

> Siguiendo la [recomendación de Docker](https://docs.docker.com/storage/volumes/#choose-the--v-or---mount-flag), usamos `--mount` en vez de `-v` o `—volume` para montar el volumen en el contenedor.

```shell
$ sudo docker run -d --name mysql-gogs \
   --mount source=data-mysql-gogs,target=/var/lib/mysql \
   -e MYSQL_ROOT_PASSWORD=ESmCg2g7dnNQeOY \
   -e MYSQL_DATABASE=gogs \
   -e MYSQL_USER=usrgogs -e MYSQL_PASSWORD=Zskkd6jygnK7 \
   mysql:5.7
4426d99884ae84ec4814dbfc8e5cc357fa2616a31b2104ec8b259e9f61c7e98d
```

> No hemos conectado el contenedor a la red `backend-gogs` para mostrar más adelante cómo hacerlo con el contenedor en marcha.

Podemos comprobar que se ha creado una base de datos llamada `gogs` en MySQL  y que el usuario `usrgogs` puede conectarse. Para ello, conectamos al contenedor y revisamos las bases de datos existentes:

```shell
$ sudo docker exec -it  mysql-gogs mysql -u usrgogs -p
Enter password:
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 2
Server version: 5.7.21 MySQL Community Server (GPL)

Copyright (c) 2000, 2018, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| gogs               |
+--------------------+
2 rows in set (0.01 sec)

mysql>
```

También podemos comprobar que el usuario `usrgogs` tiene permisos completos sobre la base de datos recién creada:

```shell
mysql> show grants for usrgogs;
+---------------------------------------------------+
| Grants for usrgogs@%                              |
+---------------------------------------------------+
| GRANT USAGE ON *.* TO 'usrgogs'@'%'               |
| GRANT ALL PRIVILEGES ON `gogs`.* TO 'usrgogs'@'%' |
+---------------------------------------------------+
2 rows in set (0.01 sec)
```

Salimos de la consola de MySQL con `exit`.

### Conexión del contenedor `mysql-gogs` a la red `backend-gogs``

Aunque lo correcto sería conectar el contenedor a la red al crearlo, podemos [conectar un contenedor en marcha](https://docs.docker.com/network/bridge/#connect-a-container-to-the-default-bridge-network) a una red mediante:

```shell
$ sudo docker network connect backend-gogs mysql-gogs
$
```

Mediante `docker inspect` podemos revisar la configuración de red del contenedor y comprobar que está conectado a la red `bridge` y a la red `backend-gogs`:

```shell
...
"Networks": {
                "bridge": {
                    ...
                    "Links": null,
                    "Aliases": null,
                    ...
                    "Gateway": "172.17.0.1",
                    "IPAddress": "172.17.0.2",
                    "IPPrefixLen": 16,
                    ...
                },
                "backend-gogs": {
                    ...
                    "Links": null,
                    "Aliases": [
                        "5621d1b86dd2"
                    ],
                    ...
                    "Gateway": "172.18.0.1",
                    "IPAddress": "172.18.0.2",
                    "IPPrefixLen": 16,
                    ...
                }
            }
...
```

# Instalación de Gogs

## Creación del volumen para los repositorios y configuración de Gogs

Para almacenar los datos usados por Gogs, creamos un volumen `data-gogs`:

```shell
$ sudo docker volume create data-gogs
data-gogs
```

Verificamos que se ha creado correctamente:

```shell
$ sudo docker volume ls
DRIVER              VOLUME NAME
local               data-gogs
local               data-mysql-gogs
$
```

## Creación del contenedor con Gogs

Descargamos la imagen:

```shell
$ sudo docker pull gogs/gogs:0.11.43
0.11.43: Pulling from gogs/gogs
550fe1bea624: Pull complete
d4768cab464c: Pull complete
a09a9b9a1b84: Pull complete
e96e27ca5c6f: Pull complete
610b4353a17a: Pull complete
e1d24556ad31: Pull complete
a8aa7b0b6f56: Pull complete
8dec4c0e4bba: Pull complete
7b83320ea32c: Pull complete
6a575b348264: Pull complete
1c038aa19116: Pull complete
Digest: sha256:1180a8381b40d2c64c09898058dba477483c581096cdce68284b30c91ec1f2a9
Status: Downloaded newer image for gogs/gogs:0.11.43
$
```

Ahora lanzamos el contenedor para GoGS (conectándolo a la red `backend-gogs` para que pueda usar MySQL):

> Siguendo la [recomendación de Docker](https://docs.docker.com/storage/volumes/#choose-the--v-or---mount-flag), usamos `--mount` en vez de `-v` o `—volume` para montar el volumen en el contenedor.

```shell
$ sudo docker run -d --name gogs \
   --mount source=data-gogs,target=/data \
   -p 10022:22 -p 10080:3000 \
   --network backend-gogs \
   gogs/gogs:0.11.43
787565af362b2e7f1cd4fe2355720cd64e5a7dffee3d23cddec97fcd69ab6f0b
```

> Hemos conectado el contenedor a la red `backend-gogs` usando `--network backend-gogs` como parámetro en el comando `docker run`.

Validamos que el contenedor sigue corriendo:

```shell
$ sudo docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                                            NAMES
787565af362b        gogs/gogs:0.11.43   "/app/gogs/docker/st…"   56 seconds ago      Up 55 seconds       0.0.0.0:10022->22/tcp, 0.0.0.0:10080->3000/tcp   gogs
5621d1b86dd2        mysql:5.7           "docker-entrypoint.s…"   About an hour ago   Up About an hour    3306/tcp                                         mysql
$
```

Si todo ha funcionado correctamente, podemos acceder a la interfaz web de GoGS a través del puerto 10080 (el puerto 10022 es para las conexiones vía SSH).

Desde la línea de comandos verificamos que al acceder a GoGS (por primera vez) se ejecuta el asistente de configuración:

```shell
$ curl localhost:10080
<a href="/install">Found</a>.
```

> Puedes obtener la IP del _host_ con Docker vía `ip address show` y revisar la IP asignada al interfaz de red (habitualmente, el `eth0`).

Así que usamos un navegador y apuntamos a `http://{$IPHOSTDOCKER}:10080`:

{{% img src="images/180520/gogs-install.png" w="810" h="616" caption="Gogs install" %}}

### Conexión con la base de datos

Como hemos lanzado un contenedor con MySQL, seleccionamos el tipo de base de datos _MySQL_ en _Database Type_.

En el campo _host_, debemos indicar el nombre del contenedor donde corre MySQL. El contenedor _gogs_  y el _mysql_, al estar conectados a la misma red _bridge_, comparten todos los puertos y pueden encontrarse a través del nombre. En este caso, en _host_, indicamos `mysql-gogs:3306`.

Usaremos un usuario sin privilegios globales en el servidor de base de datos; en nuestro caso, hemos definido el usuario `usrgogs`.

Dejamos `gogs` como nombre de la base de datos usada por GoGS.

### Configuración general de la aplicación

- _Application Name_ : `Gogs`
- _Repository Root Path_: `/data/git/gogs-repositories`
- _Run User_: `git`
- _Domain_: `$(IPHOSTDOCKER)`
- _SSH Port_: `10022` (recuerda que hemos mapeado el puerto local 22 al 10022 al crear el contenedor)
- _HTTP Port_: `3000`
- _Application URL_: `http://$(IPHOSTDOCKER):10080` (recuerda que hemos mapeado el puerto local 3000 al 10080 al crear el contenedor)
- _Log Path_: `/app/gogs/log`

> El puerto en el que la aplicación _escucha_ dentro del contenedor (`HTTP_PORT`) es el 3000, pero el acceso desde _fuera_ del contenedor se realiza a través del puerto 10080.

### Configuración adicional: Cuenta de administrador

De la configuración adicional, algunas personalizaciones:

- Deshabilito la opción de auto-registro (_Disable Self-registration_)
- Habilito el modo _offline_ (_Enable Offline Mode_); esto marca automáticamente la casilla _Disable Gravatar Service_.

Finalmente, creo una cuenta para el administrador:

- _Username_: `operador`
- _Password_: `**********` ;)
- _Confirm Password_: `**********`
- _Admin email_: `operador@local.dev`

La configuración de correo implica introducir el servidor de correo y la dirección que se mostrará como remitente del correo:

- Mailserver: `$(IPHOSTDOCKER)`
- Port: 10025
- `gogs-notify@local.dev`

Después de comprobar que todos los parámetros son correctos, pulsamos _Install Gogs_.

Si todo va como debe, se nos presenta el _Dashboard_ del usuario `operador`:

{{% img src="images/180520/gogs-dashboard.png" w="1018" h="449" caption="Gogs Dashboard" %}}

### Validación del envío de correo

1. Accedemos a GoGS
2. Pulsamos sobre el avatar en la parte superior derecha de la ventana.
3. En el menú desplegable, seleccionamos _Admin Panel_.
4. En el panel lateral de la izquierda, seleccionamos _Configuration_.
5. Buscamos la sección _Mailer Configuration_:

{{% img src="images/180520/gogs-test-mail.png" w="459" h="273" caption="Gogs Mail test" %}}

Podemos introducir una dirección de correo para validar que hemos configurado correctamente el servidor de correo.

### Configuración del envío de correo en Gogs

La prueba de envío de correo fallará con el mensaje de error:

{{% img src="images/180520/gogs-mail-error.png" w="748" h="108" caption="Gogs Mail Error" %}}

La causa está en que no se está usando un certificado válido (de hecho, no se ha configurado ningún certificado).

Para solucionarlo, debemos editar la configuración de Gogs y reiniciar el contenedor.

> En la documentación de Gogs se recomienda crear un fichero `custom/conf/app.ini` pero después de varios intentos en diferentes ubicaciones, he decidido modificar el fichero original en `/data/gogs/conf/app.ini`.

Conectamos al contenedor y editamos el fichero (después de hacer una copia de seguridad):

```shell
$ sudo docker exec -it gogs /bin/sh
/app/gogs/build # cp /data/gogs/conf/app.ini /data/gogs/conf/app.ini.bkp
/app/gogs/build # vi /data/gogs/conf/app.ini
```

Editamos la sección `[mailer]` de la configuración añadiendo el parámetro `SKIP_VERIFY = true`:

```shell
[mailer]
ENABLED = true
HOST    = 192.168.1.209:10025
FROM    = gogs-notify@local.dev
USER    = gogs-notify@local.dev
PASSWD  =
SKIP_VERIFY = true
```

Guardamos y salimos del contenedor. Para que los efectos surtan efecto, reiniciamos el servidor:

```shell
$ sudo docker restart gogs
gogs
```

Tras el reinicio, al enviar una prueba de correo:

{{% img src="images/180520/gogs-mail-sent.png" w="761" h="171" caption="Gogs Mail sent" %}}

Si revisamos la bandeja de entrada de MailDev, comprobamos la recepción del correo de prueba:

{{% img src="images/180520/gogs-maildev-inbox.png" w="613" h="182" caption="Gogs Inbox" %}}

Si seleccionamos _Mail, Source_, podemos ver todos los detalles del correo enviado (como la dirección _From_, configurada en el fichero `app.ini`):

{{% img src="images/180520/gogs-maildev-inbox-details.png" w="741" h="258" caption="Gogs Mail details" %}}

> En la página [Configuration Cheat Sheet](https://gogs.io/docs/advanced/configuration_cheat_sheet) tienes todas las variables de configuración definidas en Gogs. Por ejemplo, si quieres que al acceder a Gogs se muestre la página _Explore_ (con el listado de repositorios) en vez de _Home_ (con el logo de Gogs), puedes cambiar el comportamiento usando la variable `LANDING_PAGE`.