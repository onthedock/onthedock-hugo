+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev", "ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "docker", "sonarqube", "mysql", "integracion continua", "troubleshooting"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/sonarqube.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}

title=  "Pipeline - Troubleshooting del arranque del contenedor con Sonarqube"
date = "2018-05-21T12:37:10+02:00"
+++
En las guías y tutoriales en internet siempre funciona todo sin ningún fallo. Sin embargo, lo más habitual es que encontremos problemas en los primeros intentos de poner en marcha una aplicación.

Personalmente, creo que el aprendizaje es un proceso de ensayo y error, por lo que se aprende solucionando los errores que nos encontramos.

Con esa idea en mente, también intento documentar los fallos que cometo. A continuación tienes el registro de las acciones que realicé para solucionar los problemas encontrados en el arranque de SonarQube.
<!--more-->

# Lanzando el contenedor

Lanzamos el contenedor con SonarQube conectándolo a la base de datos:

```shell
$ sudo docker run -d --name sonarqube -p 9000:9000 -p 9092:9092 \
-e SONARQUBE_JDBC_USERNAME=sonar \
-e SONARQUBE_JDBC_PASSWORD=cF68nTVgP8Nq \
-e SONARQUBE_JDBC_URL=jdbc:mysql://localhost/sonar sonarqube:7.1-alpine
9726b2c018d6151745a382ea22cc53f1a96ada557ae21b2a176313b46fb4a010
$
```

El contenedor **se detiene después de ser lanzado**.

# Troubleshooting

Mientras observo los logs, lo primero que me viene a la cabeza es que no hemos definido una base de datos en MySQL para SonarQube ni en el comando para lanzar SonarQube.

Eliminamos el contenedor actual de MySQL para SonarQube:

```shell
$ sudo docker stop mysql-sonarqube && sudo docker rm mysql-sonarqube
mysql-sonarqube
mysql-sonarqube
$
```

# Creando una base de datos para SonarQube en MySQL

Creamos la base de datos siguiendo las instrucciones de la [página en Docker Hub para MySQL](https://hub.docker.com/_/mysql/):

```shell
$ sudo docker run -d --name mysql-sonarqube --network backend-sonarqube \
--mount source=data-mysql-sonarqube,target=/var/lib/mysql \
-e MYSQL_ROOT_PASSWORD=J8wqnvJicbpv \
-e MYSQL_DATABASE=sonar \
-e MYSQL_USER=sonar -e MYSQL_PASSWORD=cF68nTVgP8Nq \
mysql:5.7
c12b24cbe07b4026ae7deda7e9085775fa3f794ca28778b665d36cfdf1bd9fa4
$
```

Al lanzar de nuevo el contenedor, seguimos obteniendo el mismo error.

## Modificando la cadena de conexión 

Revisando [docker image of sonarqube is not running with mysql db configuration](https://github.com/SonarSource/docker-sonarqube/issues/61), observo dos cosas: primero, cómo añadir la propiedad `useUnicode=true` y segundo, que en la cadena de conexión se hace referencia a `localhost` y la base de datos no se encuentra en el contenedor de SonarQube.

En los logs aparece la excepción:

```shell
$ sudo docker logs sonarqube
Exception in thread "main" org.sonar.process.MessageException: JDBC URL must have the property 'useUnicode=true'
$
```

Corrijo la cadena de conexión indicando el nombre del contendor con MySQL (SonarQube) y la propiedad indicada en los logs:

```shell
$ sudo docker run -d --name sonarqube -p 9000:9000 -p 9092:9092 \
-e SONARQUBE_JDBC_USERNAME=sonar \
-e SONARQUBE_JDBC_PASSWORD=cF68nTVgP8Nq \
-e SONARQUBE_JDBC_URL='jdbc:mysql://mysql-sonarqube:3306/sonar?useUnicode=true&characterEncoding=utf8' \
sonarqube:7.1-alpine
2887a8817afe286966712ad202a5ed50f4b7a67eba2409c185dc70deaec7ceb9
[2]+  Exit 1 sudo docker run -d --name sonarqube -p 9000:9000 -p 9092:9092 -e SONARQUBE_JDBC_USERNAME=sonar -e SONARQUBE_JDBC_PASSWORD=cF68nTVgP8Nq -e SONARQUBE_JDBC_URL=jdbc:mysql://mysql-sonarqube:3306/sonar?useUnicode=true
$
```

## Problemas de conexión

Revisando los logs de nuevo, destaca el mensaje `java.lang.IllegalStateException: Can not connect to database. Please check connectivity and settings (see the properties prefixed by 'sonar.jdbc.')`.

La cadena de conexión en el comando _docker run_ parece correcta, así que el problema debe estar en otro lugar. Analizando el problema veo que el contenedor `sonarqube` no está conectado a la red `backend-sonarqube`, por lo que no encuentra la base de datos especificada en `SONARQUBE_JDBC_URL='jdbc:mysql://mysql-sonarqube:3306/...`

Volvemos a intentarlo con:

```shell
$ sudo docker run -d --name sonarqube -p 9000:9000 -p 9092:9092 \
-e SONARQUBE_JDBC_USERNAME=sonar \
-e SONARQUBE_JDBC_PASSWORD=cF68nTVgP8Nq \
-e SONARQUBE_JDBC_URL='jdbc:mysql://mysql-sonarqube:3306/sonar?useUnicode=true&characterEncoding=utf8' \
--network backend-sonarqube \
sonarqube:7.1-alpine
2866c2e4c4540157da2040b03083010ce8563e8f07e3bb1ffdcf953b0ecbf849
$
```

El contenedor sigue sin arrancar.

## _Warnings_ en la conexión

Revisando de nuevo los logs, vemos que tenemos un par de avisos sobre propiedades que deberían usarse en la cadena de conexión y fallos en la conexión usando SSL (que no está configurado):

```shell
$ sudo docker logs sonarqube
20:00:15.435 [main] WARN org.sonar.application.config.JdbcSettings - JDBC URL is recommended to have the property 'rewriteBatchedStatements=true'
20:00:15.441 [main] WARN org.sonar.application.config.JdbcSettings - JDBC URL is recommended to have the property 'useConfigs=maxPerformance'
...
2018.04.26 20:00:32 INFO  web[][o.sonar.db.Database] Create JDBC data source for jdbc:mysql://mysql-sonarqube:3306/sonar?useUnicode=true&characterEncoding=utf8
Thu Apr 26 20:00:32 GMT 2018 WARN: Establishing SSL connection without server's identity verification is not recommended. According to MySQL 5.5.45+, 5.6.26+ and 5.7.6+ requirements SSL connection must be established by default if explicit option isn't set. For compliance with existing applications not using SSL the verifyServerCertificate property is set to 'false'. You need either to explicitly disable SSL by setting useSSL=false, or set useSSL=true and provide truststore for server certificate verification.
2018.04.26 20:00:33 ERROR web[][o.s.s.p.Platform] Web server startup failed
java.lang.IllegalStateException: Can not connect to database. Please check connectivity and settings (see the properties prefixed by 'sonar.jdbc.').
...
```

Añadiremos las dos propiedades recomendadas a la cadena de conexión e indicamos `useSSL=false` para deshacernos del error de verificación del certificado SSL (que no estamos usando):

```shell
$ sudo docker run -d --name sonarqube -p 9000:9000 -p 9092:9092 \
-e SONARQUBE_JDBC_USERNAME=sonar \
-e SONARQUBE_JDBC_PASSWORD=cF68nTVgP8Nq \
-e SONARQUBE_JDBC_URL='jdbc:mysql://mysql-sonarqube:3306/sonar?useUnicode=true&characterEncoding=utf8&rewriteBatchedStatements=true&useConfigs=maxPerformance&useSSL=false' \
--network backend-sonarqube \
sonarqube:7.1-alpine
```

El contenedor sigue sin arrancar.

## Acceso denegado

Revisando los logs, seguimos sin poder conectar con la base de datos, pero ahora es un problema de acceso denegado:

```shell
$ sudo docker logs sonarqube
...
Caused by: org.apache.commons.dbcp.SQLNestedException: Cannot create PoolableConnectionFactory (Access denied for user 'sonar'@'172.18.0.3' (using password: YES))
...
Caused by: java.sql.SQLException: Access denied for user 'sonar'@'172.18.0.3' (using password: YES)
...
```

Es decir, parece que el contenedor con SonarQube sí que establece conexión con el servidor de MySQL-SonarQube, pero el usuario `sonar` no tiene acceso para conectarse.

## Borrado del volumen de datos para MySQL

Al arrancar MySQL pasando las variables `MYSQL_USER` y `MYSQL_PASSWORD`, debería haberse asignado permisos sobre la base de datos especificada en `MYSQL_DATABASE`. Como en nuestro caso habíamos arrancado la base de datos MySQL usando el volumen `data-mysql-sonarqube`, mi hipótesis es que ya existía una base de datos y por tanto no se han dado permisos al nuevo usuario.

> Podríamos haber dado permisos manualmente al usuario sobre la base de datos, pero corríamos el riesgo de que el proceso de creación del _schema_ en la base de datos no se lanzara (porque la base de datos ya exitía). Al no tener datos en la base de datos, lo más sencillo es eliminar el volumen de datos y el contenedor de MySQL.

Para comprobar mi hipótesis, detengo y elimino el contenedor con base de datos `mysql-sonarqube`, así como el volumen `data-mysql-sonarqube`:

```shell
$ sudo docker stop mysql-sonarqube
mysql-sonarqube
$ sudo docker rm mysql-sonarqube
mysql-sonarqube
$ sudo docker volume rm data-mysql-sonarqube
data-mysql-sonarqube
$
```

Lo creamos todo de nuevo:

```shell
$ sudo docker volume create data-mysql-sonarqube
data-mysql-sonarqube

$ sudo docker run -d --name mysql-sonarqube --network backend-sonarqube \
--mount source=data-mysql-sonarqube,target=/var/lib/mysql \
-e MYSQL_ROOT_PASSWORD=J8wqnvJicbpv \
-e MYSQL_DATABASE=sonar \
-e MYSQL_USER=sonar -e MYSQL_PASSWORD=cF68nTVgP8Nq mysql:5.7
6966a54978df35eaafe6bf10dea7f3f4fcfdb3c5340e0e3ea5cddffd9bd02d06

$ sudo docker run -d --name sonarqube -p 9000:9000 -p 9092:9092 \
  -e SONARQUBE_JDBC_USERNAME=sonar \
  -e SONARQUBE_JDBC_PASSWORD=cF68nTVgP8Nq \
  -e SONARQUBE_JDBC_URL='jdbc:mysql://mysql-sonarqube:3306/sonar?useUnicode=true&characterEncoding=utf8&rewriteBatchedStatements=true&useConfigs=maxPerformance&useSSL=false' \
  --network backend-sonarqube \
  sonarqube:7.1-alpine
4fc7eea457db05e7ad9837ca5f4407d5023e227cb94b188c5f021eca65e39332
```

Después de unos segundos, al revisar los logs, vemos que esta vez sí que se está creando el _schema_ de la base de datos para SonarQube:

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

Y accediendo desde el navegador a _http://$IPHOST:9000/_:

{{< figure src="/images/180521/sonarqube-home.png" w="1111" h="523"  caption="SonarQube home" >}}

### Volumen data-sonarqube no montado en sonarqube

Con todos los problemas relacionados con la base de datos de SonarQube, no me dado cuenta de que no he montado el volumen `data-sonarqube`  en el contenedor de `sonarqube`.

Docker ha creado un volumen automáticamente y lo ha montado en el contenedor; podemos ver el contenedor "sin nombre" lanzando:

```shell
$ sudo docker volume ls
DRIVER              VOLUME NAME
local               caf392a6189a23dce515817e2e02c5bc2bc05d89cd1b97da4739f0203c59192b
local               data-gogs
local               data-jenkins
local               data-mysql-gogs
local               data-mysql-sonarqube
local               data-nexus
local               data-portainer
```

Aunque a nivel funcional no supone ninguna diferencia; disponer de nombres identificativos para los volúmenes de datos nos ayuda a simplificar la gestión del entorno.

Vamos a lanzar un contenedor efímero que monte tanto el volumen actual `caf392a6189...` como el volumen `data-sonarqube` y copiaremos el contenido de uno a otro. A continuación, lanzaremos de nuevo el contenedor `sonarqube` y una vez que hayamos comprobado que funciona correctamente, eliminaremos el volumen `caf392a6189...`.

Creamos el volumen de datos:

```shell
$ sudo docker volume create data-sonarqube
data-sonarqube
```

Detenemos el contenedor de SonarQube y lo eliminamos (para reutilizar el nombre):

```shell
$ sudo docker stop sonarqube && sudo docker rm sonarqube
sonarqube
sonarqube
```

Creamos el contenedor efímero y montamos los volúmenes:

```shell
$ sudo docker run --rm -it --mount source=caf392a6189a23dce515817e2e02c5bc2bc05d89cd1b97da4739f0203c59192b,target=/in --mount source=data-sonarqube,target=/out sonarqube:7.1-alpine /bin/sh
/opt/sonarqube # ls /in
README.txt  es5         web
/opt/sonarqube # ls /out
/opt/sonarqube # cd /in/
/in # cp -a . /out
/in # ls /out/
README.txt  es5         web
/in #
```

Una vez copiados los datos, salimos del contenedor usando `exit`.

> En la versión actual de Docker (18.03.1-ce) no hay ningún comando para renombrar un volumen o para copiar su contenido a otro volumen.

Finalmente, lanzamos un nuevo contenedor para SonarQube, montando el volumen `data-sonarqube`:

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

Después de verificar que SonarQube arranca con normalidad, podemos eliminar el volumen "sin nombre":

```shell
$ sudo docker volume ls
DRIVER              VOLUME NAME
local               caf392a6189a23dce515817e2e02c5bc2bc05d89cd1b97da4739f0203c59192b
local               data-gogs
local               data-jenkins
local               data-mysql-gogs
local               data-mysql-sonarqube
local               data-nexus
local               data-portainer
local               data-sonarqube
$ sudo docker volume rm caf392a6189a23dce515817e2e02c5bc2bc05d89cd1b97da4739f0203c59192b
caf392a6189a23dce515817e2e02c5bc2bc05d89cd1b97da4739f0203c59192b
$
```

## Volumen para _plugins_

Examinando el [fichero `Dockerfile` en GitHub](https://github.com/SonarSource/docker-sonarqube/blob/442f950dae232fca8e1e919e017270971cee46f6/4.5.6/Dockerfile#L37%20Sonarqube%20Dockerfile) podemos ver que SonarQube expone otro volumen para las [extensiones (o _plugins_)](https://docs.sonarqube.org/display/DEV/Extension+Guide):

```shell
VOLUME ["$SONARQUBE_HOME/data", "$SONARQUBE_HOME/extensions"]
```

Si es necesario, podemos crear un nuevo volumen `data-sonarqube-extensions` y montarlo en un nuevo contenedor para SonarQube repitiendo los pasos descritos en esta sección.

## Puerto 9092

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
$
```

# Resumen

Después de depurar los diferentes errores surgidos en la creación del contenedor SonarQube, la aplicación está en marcha y funcionando.
