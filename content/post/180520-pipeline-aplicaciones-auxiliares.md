+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev", "ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "docker", "integracion continua", "devops", "maildev", "portainer"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/jenkins.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" %}}

title=  "Pipeline: Aplicaciones auxiliares"
date = "2018-05-20T07:08:04+02:00"
+++

Como indicaba en el entrada [que abría esta serie]({{< ref  "180518-integracion-continua-con-jenkins-y-docker.md" >}}), además de las aplicaciones que forman parte del _pipeline_, uso algunas aplicaciones auxiliares.

Estas aplicaciones son _MailDev_ y _Portainer_.

<!--more-->

# MailDev

Muchas aplicaciones requieren disponer de un servidor de correo para poder enviar notificaciones. Para disponer de la posibilidad de las notificaciones de correo en un entorno aislado, usamos [MailDev](http://danfarrelly.nyc/MailDev/) de Dan Ferrelly.

Descargamos la imagen de DockerHub:

```shell
$ $ sudo docker pull djfarrelly/maildev
Using default tag: latest
latest: Pulling from djfarrelly/maildev
ab7e51e37a18: Pull complete
e5b0c488c86b: Pull complete
84b7d2a67805: Pull complete
d24af6c23037: Pull complete
262a00925cb5: Pull complete
8411e046dcb9: Pull complete
0b1384cf6fae: Pull complete
Digest: sha256:624e0ec781e11c3531da83d9448f5861f258ee008c1b2da63b3248bfd680acfa
Status: Downloaded newer image for djfarrelly/maildev:latest
$
```

A continuación lanzamos el contenedor. _MailDev_ expone el puerto 25 (SMTP) y una interfaz web en el puerto 80 (HTTP). Estos puertos locales del contenedor los publicamos en el puerto 10025 y el 8000 respectivamente:

```she
$ sudo docker run -d --name maildev -p 10025:25 -p 18000:80 djfarrelly/maildev
04a10ec5a231b4eb9ec3ed44a09b6c378ebd3374a5c2a624c9d64341aff3ac5b
```

De esta forma, cualquier aplicación que requiera enviar correo puede hacerlo usando el servidor `maildev`a través del puerto 10025.

Podemos consultar los emails enviados a través del interfaz web de MailDev a través del puerto 8000.

{{% img src="images/180520/maildev.png" w="1112" h="483" caption="Bandeja de entrada - MailDev" %}}

# Portainer

A medida que aumenta el número de contenedores, volúmenes, etc, una herramienta gráfica como [Portainer](https://portainer.io)  puede simplificar la gestión de nuestro entorno.

Portainer requiere un volumen para guardar configuración y, dado que permite gestionar Docker, también debe montar `/var/run/docker.sock`.

En primer lugar, creamos el volumen donde almacenar los datos de Portainer:

```shell
sudo docker volume create data-portainer
```

A continuación, lanzamos el contenedor:

```shell
$ sudo docker run -d --name portainer -p 19000:9000 \
--mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.soc \
--mount source=data-portainer,target=/data portainer/portainer
98c6137e09ae9ca74d7a148e38c6f2980685b023a89119547d5f10aed51a46fb
```

Por defecto, Portainer expone el puerto local 9000, pero en el _host_ este puerto lo usaremos para SonarQube más adelante, de manera que usaremos el 19000.

Podemos comprobar que funciona desde la línea de comando usando _curl_:

```shell
$ curl localhost:19000
<!DOCTYPE html>
<html lang="en" ng-app="portainer">
<head>
  <meta charset="utf-8">
  <title>Portainer</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="description" content="">
  <meta name="author" content="Portainer.io">
  ...
```

Accediendo a través del navegador, en el primer acceso podemos definir el nombre de usuario y las credenciales del usuario administrador:

{{% img src="images/180520/portainer-admin-first-login.png" w="626" h="474" caption="Portainer - Login" %}}

He cambiado el nombre del usuario adminstrador por `operador` y le he asignado un password.

A continuación, Portainer nos pregunta si vamos a gestionar un Docker local o un servidor Docker remoto. En nuestro caso, se trata del servidor Docker local (por eso hemos montado `/var/run/docker.sock`).

Seleccionamos la opción _Local_ y pulsamos el botón _Connect_:

{{% img src="images/180520/portainer-local.png" w="613" h="447" caption="Portainer - Local Docker" %}}

Al conectar, vemos un _Dashboard_ con el estado de nuestro entorno local.

{{% img src="images/180520/portainer-homepage.png" w="1001" h="552" caption="Portainer - Dashboard" %}}

Usando Portainer es sencillo relacionar un volumen con el contenedor en el que está montado, por ejemplo. También se puede obtener información del uso de CPU, memoria y red de un contenedor y conectar desde la aplicación web al contenedor para ejecutar comandos.