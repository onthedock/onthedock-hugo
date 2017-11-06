+++
draft = false

# TAGS
# HW->OS->PRODUCT->specific tag
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "docker", "git", "gogs"]

# CATEGORIES = "dev" / "ops"
categories = ["dev", "ops"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/gogs.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# YouTube
# {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Imagenes
# {{% img src="images/image.jpg" w="600" h="400" %}}
# {{% img src="images/image.jpg" w="600" h="400" class="right" %}}
# {{% img src="images/image.jpg" w="600" h="400" class="left" %}}
# {{% img src="images/image.jpg" w="600" h="400" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# Clear (floats)
# {{% clear %}}
# Twitter
# {{% twitter tweetid="780599416621297xxx" %}}

title=  "Gogs - Cómo crear tu propio servicio de hospedaje de repositorios Git"
date = "2017-11-06T22:11:26+01:00"
+++

[Gogs](https://gogs.io/) es la manera más sencilla, rápida y menos dolorosa de poner en marcha tu propio servicio de Git en tu infraestructura, tu propio _Github_, para entendernos. Gogs proporciona un entorno web que permite gestionar los respositorios Git desde el navegador, el acceso que tienen los usuarios, gestionar _issues_ y _pull requests_ e incluso crear un wiki para documentar el proyecto.

Es 100% código abierto, está escrito en Go y es _muy ligero_ (incluso puede correr en una Raspberry Pi).

En este artículo te indico cómo confirgurarlo lanzándolo desde un contenedor sobre Docker.

<!--more-->

> En esta guía utilizaré la imagen para x64 y no la de RPi.

## Descarga de la imagen de Gogs

Como vamos a usar Docker, lo primero es descargar la imagen desde DockerHub.

```shell
$ docker pull gogs/gogs
Using default tag: latest
latest: Pulling from gogs/gogs
019300c8a437: Pull complete
8edf460df1da: Pull complete
4cdb11e400b1: Pull complete
2abafafcef20: Pull complete
52a4ea9d51b9: Pull complete
3eb6c35b5c28: Pull complete
46cba49c5f17: Pull complete
f5fe70c1c1a5: Pull complete
cb38918703dc: Pull complete
d852f1ecd939: Pull complete
30743851cc84: Pull complete
Digest: sha256:c27c926b796c8ff96a4b1194414ab9a897ab200bc50ac6ec5cabf48657c1545b
Status: Downloaded newer image for gogs/gogs:latest
```

Como no hemos especificado una etiqueta concreta, Docker descarga la imagen etiquetada como `latest`.

Una vez descargada, comprobamos que se ha añadido al repositorio local:

```shell
$ docker images
REPOSITORY                   TAG                 IMAGE ID            CREATED             SIZE
gogs/gogs                    latest              10b32ede02df        6 days ago          138MB
...
```

Gogs guarda la configuración propia en una base de datos. Para un proyecto personal podemos usar SQLite, lo que simplificará la configuración inicial.

## Configuración/seguridad de los datos

Tanto la base de datos SQLite como los repositorios los guardaremos _fuera_ del contenedor. En este caso usaremos una volumen montado directamente desde el _host_. Creamos la carpeta de datos como:

```shell
mkdir gogsdata
```

El acceso a Gogs se realiza a través de dos puertos expuestos en el contenedor: el puerto 22, para el acceso vía SSH y el 3000, donde se publica el servidor web.

En el comando para lanzar Gogs _mapeamos_ los puertos 22 y 3000 a puertos libres disponibles en el host. En mi caso, usaré 8022 y 8383.

```shell
$ docker run -d --name gogsdemo -p 8022:22 -p 8383:3000 -v $PWD/gogsdata:/data gogs/gogs
62732f9bb46c50057e5181b1e555ea2c4e998faacaa45f0346b260046b20b614
```

Una vez lanzado el contenedor, debemos realizar la primera configuración de Gogs. Para ello, accedermos a través de un navegador web a la IP del _host_ donde corre el contenedor a través del puerto web especificado (en nuestro ejemplo, el 8383).

Al nevagar a `http://192.168.1.20:8383` se nos redirige automáticamente a `http://192.168.1.20:8383/install`.

Aquí realizamos las siguientes configuraciones (los campos que no indico es porque dejo el valor ofrecido por defecto):

- Database Type: **SQLite3** _# Por simplificar_
- Domain: **192.168.1.20**  _# IP del host donde se ejecuta Docker_
- SSH Port: **8022** _# Puerto de acceso SSH_
- HTTP Port: **8383** _# Puerto de acceso web_
- Application URL: **http://192.168.1.20:8383** _# URL de acceso_

Finalmente, pulsamos el botón _Install Gogs_.

## Primer acceso a la aplicación - Creación del primer  usuario

Si todo funciona correctamente, se muestra la pantalla de login. Como todavía no hemos definido un usuario, pulsamos en la parte superior derecha sobre _Register_.

Especificamos el nombre de usuario. La primera cuenta creada se convierte automáticamente en administrador del sitio, por lo que creamos un usuario llamado `gogsadmin`.

Después de registrarnos con éxito, se muestra la pantalla de login.

Accedemos con las credenciales del usuario que hemos creado.

## Creación del primer repositorio

Pulsamos sobre el `+` en la esquina superior derecha y seleccionamos _New Repository_.

Damos un nombre al repositorio (por ejemplo, `gogsdemo`) y pulsamos el botón _Create Repository_.

La creación del repositorio muestra una página con información sobre cómo añadir el repositorio a un repositorio Git local, por ejemplo:

```txt
Clone this repository

Create a new repository on the command line

touch README.md
git init
git add README.md
git commit -m "first commit"
git remote add origin http://192.168.1.20:8383/gogsadmin/gogsdemo.git
git push -u origin master
Push an existing repository from the command line

git remote add origin http://192.168.1.20:8383/gogsadmin/gogsdemo.git
git push -u origin master
```

En nuestro equipo local, añadimos el _remoto_ a un repositorio existente. Si no tenemos un respositorio, creamos uno:

```shell
$ mkdir dev
$ cd dev
$ git init dev
Initialized empty Git repository in /home/operador/gogsdemo/dev/.git/
```

Creamos el primer fichero `nano README.md` y añadimos la información relativa al repositorio.

A continuación, _git add REAME.md_ y _git commit_

Añadimos el _remote_ correspondiente al servicio de GIT que hemos montado con Gogs.

Finalmente, _subimos_ los cambios al respositorio remoto:

```shell
$ git push origin master
Counting objects: 3, done.
Writing objects: 100% (3/3), 239 bytes | 0 bytes/s, done.
Total 3 (delta 0), reused 0 (delta 0)
Username for 'http://192.168.1.20:8383': gogsadmin
Password for 'http://gogsadmin@192.168.1.20:8383':
To http://192.168.1.20:8383/gogsadmin/gogsdemo.git
 * [new branch]      master -> master
$
```

Accedemos al respositorio a través del navegador y comprobamos que se ha subido el código de nuestro repositorio local:

{{% img src="images/171106/gogsdemo.png" %}}

## Resumen

Como has visto, poner en marcha un servicio de hospedaje de repositorios Git con Gogs es extremadamente sencillo: descargar la imagen, lanzar el contenedor y realizar la primera configuración.