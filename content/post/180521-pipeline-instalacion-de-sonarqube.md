+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev", "ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "docker", "sonarqube", "integracion continua"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/sonarqube.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" %}}

title=  "Pipeline - Instalación de Sonarqube"
date = "2018-05-21T12:19:43+02:00"
+++
[SonarQube](https://www.sonarqube.org/) es una herramienta de análisis continuo de código.

La versión _open source_ ofrece soporte para 20 lenguajes de programación, mientras que la versión comercial amplía el número de _analizadores_. También hay _analizadores_ creados por la comunidad.

<!--more-->

SonarQube [requiere una base de datos](https://docs.sonarqube.org/display/SONAR/Requirements), por lo que vamos a usar una instancia de MySQL conectada al contenedor de SonarQube mediante la red `backend-sonarqube`.

# Red `bridge` para conectar SonarQube y MySQL

Creamos la red _bridge_:

```shell
$ sudo docker network create backend-sonarqube
abd566a43dd75befb6d2233b3377f8aa4c80ba0371efa56b4e681b37734e8650
```

# Volumen de datos para MySQL

Creamos un volumen para almacenar la base de datos:

```shell
$ sudo docker volume create data-mysql-sonarqube
data-mysql-sonarqube
```

# Contenedor con MySQL

A continuación, creamos un contenedor para MySQL y lo conectamos a la red `backend-sonarqube` montando el volumen `data-mysql-sonarqube`.

```shell
$ sudo docker run -d --name mysql-sonarqube --network backend-sonarqube \
--mount source=data-mysql-sonarqube,target=/var/lib/mysql \
-e MYSQL_ROOT_PASSWORD=J8wqnvJicbpv \
-e MYSQL_DATABASE=sonar \
-e MYSQL_USER=sonar -e MYSQL_PASSWORD=cF68nTVgP8Nq mysql:5.7
6966a54978df35eaafe6bf10dea7f3f4fcfdb3c5340e0e3ea5cddffd9bd02d06
```

# Instalación de SonarQube

## Volumen de datos para SonarQube

Creamos un volumen para almacenar datos de SonarQube:

```shell
$ sudo docker volume create data-sonarqube
data-sonarqube
```

## Contenedor con SonarQube

Empezamos descargando la imagen desde Docker Hub:

```shell
$ sudo docker pull sonarqube:7.1-alpine
7.1-alpine: Pulling from library/sonarqube
ff3a5c916c92: Pull complete
5de5f69f42d7: Pull complete
fd869c8b9b59: Pull complete
70c099ba8bd1: Pull complete
a17c64d63dca: Pull complete
7773f7c061ed: Pull complete
Digest: sha256:f7f581a4de517d23f96aa3d6612a892a9741138c60e99933d24d5d2ee26a5332
Status: Downloaded newer image for sonarqube:7.1-alpine
$
```

Una vez descargada la imagen, lanzamos el contenedor:

```shell
$ sudo docker run -d --name sonarqube -p 9000:9000 -p 9092:9092 \
  --mount source=data-sonarqube,target=/opt/sonarqube/data \
  -e SONARQUBE_JDBC_USERNAME=sonar \
  -e SONARQUBE_JDBC_PASSWORD=cF68nTVgP8Nq \
  -e SONARQUBE_JDBC_URL='jdbc:mysql://mysql-sonarqube:3306/sonar?useUnicode=true&characterEncoding=utf8&rewriteBatchedStatements=true&useConfigs=maxPerformance&useSSL=false' \
  --network backend-sonarqube \
  sonarqube:7.1-alpine
443cb80ef5bdc7168c654b0bea0883cfc8e665e465f3d12fa8bb06bdb1856f14
$
```

El comando para lanzar la imagen de SonarQube publica dos puertos, el 9000, acceso al interfaz web y el 9092, de conexión a la base de datos incrustada H2.

Montamos el volumen creado para SonarQube en el contenedor.

Mediante variables de entorno, especificamos el usuario y password de conexión a la base de datos. En la cadena de conexión, especificamos las variables necesarias para evitar _Warnings_ en los logs.

Finalmente, especificamos que el contenedor de SonarQube debe estar conectado a la red _backend-sonarqube_.

Después de unos segundos, al revisar los logs, vemos que se está creando el _schema_ de la base de datos para SonarQube:

```shell
$ sudo docker logs sonarqube
...
2018.04.26 20:19:04 INFO  web[][o.s.s.p.d.m.AutoDbMigration] Automatically perform DB migration on fresh install
2018.04.26 20:19:04 INFO  web[][DbMigrations] Executing DB migrations...
2018.04.26 20:19:04 INFO  web[][DbMigrations] #1 'Create initial schema'...
2018.04.26 20:19:14 INFO  web[][DbMigrations] #1 'Create initial schema': success | time=10068ms
2018.04.26 20:19:14 INFO  web[][DbMigrations] #2 'Populate initial schema'...
2018.04.26 20:19:14 INFO  web[][DbMigrations] #2 'Populate initial schema': success | time=430ms
...
```

Cuando finaliza el proceso:

```shell
$ sudo docker logs sonarqube
...
2018.04.26 20:20:37 INFO  ce[][o.s.ce.app.CeServer] Compute Engine is operational
2018.04.26 20:20:37 INFO  app[][o.s.a.SchedulerImpl] Process[ce] is up
2018.04.26 20:20:37 INFO  app[][o.s.a.SchedulerImpl] SonarQube is up
$
```

Y accediendo desde el navegador a _[http://$IPHOST:9000/](http://$IPHOST:9000/)_:

{{% img src="images/180521/sonarqube-home.png" w="1111" h="523" caption="SonarQube home" %}}

### Puerto 9092

Revisando la documentación de SonarQube, en el fichero de configuración [`sonar.properties`](https://github.com/SonarSource/sonarqube/blob/master/sonar-application/src/main/assembly/conf/sonar.properties ) el puerto 9092 se usa para conectar con la base de datos _incrustada_ (_embedded_) H2:

```shell
...
#----- Embedded Database (default)
# H2 embedded database server listening port, defaults to 9092
#sonar.embeddedDatabase.port=9092
...
```

Dado que nosotros usamos MySQL, podemos relanzar el contenedor sin publicar el puerto 9092:

```shell
$ sudo docker stop sonarqube
sonarqube
$ sudo docker rm sonarqube
sonarqube
$ sudo docker run -d --name sonarqube -p 9000:9000 \
  --mount source=data-sonarqube,target=/opt/sonarqube/data \
  -e SONARQUBE_JDBC_USERNAME=sonar \
  -e SONARQUBE_JDBC_PASSWORD=cF68nTVgP8Nq \
  -e SONARQUBE_JDBC_URL='jdbc:mysql://mysql-sonarqube:3306/sonar?useUnicode=true&characterEncoding=utf8&rewriteBatchedStatements=true&useConfigs=maxPerformance&useSSL=false' \
  --network backend-sonarqube \
  sonarqube:7.1-alpine
443cb80ef5bdc7168c654b0bea0883cfc8e665e465f3d12fa8bb06bdb1856f14
```

## Volumen para plugins de SonarQube

Examinando el [fichero `Dockerfile` en GitHub](https://github.com/SonarSource/docker-sonarqube/blob/442f950dae232fca8e1e919e017270971cee46f6/4.5.6/Dockerfile#L37%20Sonarqube%20Dockerfile) podemos ver que SonarQube expone otro volumen para las [extensiones (o _plugins_)](https://docs.sonarqube.org/display/DEV/Extension+Guide):

```shell
...
VOLUME ["$SONARQUBE_HOME/data", "$SONARQUBE_HOME/extensions"]
...
```

Si es necesario, podemos crear un nuevo volumen `data-sonarqube-extensions` y montarlo en un nuevo contenedor para SonarQube.

## Acceso a SonarQube y cambio del password por defecto

Pulsando sobre _Log in_ accedemos a la página de acceso a Sonarqube.

Las credenciales de acceso por defecto, tal y como se detalla en [Default Admin Credentials](https://docs.sonarqube.org/display/SONAR/Authentication#Authentication-AdminCredentialsDefaultAdminCredentials)  son `admin` y `admin`.

Después de acceder a Sonarqube con las credenciales por defecto, pulsamos _Skip this tutorial_ en la parte superior derecha de la pantalla _"Welcome to SonarQube"_.

Para cambiar el password:

1. Pulsamos sobre la letra "A" que actúa como _avatar_ para el usuario `admin`.
2. En el menú desplegable, seleccionamos _My Account_
3. Pulsamos sobre _Security_
4. En la parte inferior de la pantalla, podemos realizar el cambio de password, introduciendo el password actual y repitiendo el nuevo password dos veces.

### Configuración del servidor de correo

1. Accedemos a SonarQube como administrador
1. En la barra superior, pulsamos _Administration_
1. En la página de _Administration_, pulsamos en _Configuration_. En el desplegable, seleccionamos _General Settings_
1. Hacemos _scroll_ hasta el apartado _Email_

En esta sección podemos indicar:

- Prefijo de los correos enviados: `[SONARQUBE]` (por defecto)
- Dirección del remitente (_From address_): `sonarqube-notify@local.dev`
- Nombre del remitente (_From Name_): `SonarQube Notification`
- _Secure connection_: Lo dejamos en blanco para deshabilitar conexiones seguras
- Servidor de correo (_SMTP host_): `$(IPHOST)`
- Contraseña (_SMTP password_): Lo dejamos en blanco (MailDev no requiere autenticación)
- Puerto SMTP (_SMTP port_): 10025 (el configurado para MailDev)
- Usuario con permisos para enviar correo (_SMTP username_): Lo dejamos en blanco (MailDev no requiere autenticación)

Finalmente, podemos comprobar si el envío de correos funciona usando la opción _Test configuration_.