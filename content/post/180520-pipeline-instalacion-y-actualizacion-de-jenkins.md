+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev", "ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "docker", "integracion continua", "devops", "jenkins"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/jenkins.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})


# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}

title=  "Pipeline - Instalacion y actualizacion de Jenkins"
date = "2018-05-20T07:43:06+02:00"
+++
[Jenkins](https://jenkins.io/) es un servidor de _automatización_ de código abierto escrito en Java. Es una herramienta clave en el proceso de integración continua y un facilitador de cara a realizar despliegues continuos.
<!--more-->

Jenkins almacena la información de configuración, plugins, etc [en ficheros XML](https://wiki.jenkins.io/display/JENKINS/Administering+Jenkins), por lo que no necesita una base de datos.

La estructura de ficheros dentro de `JENKINS_HOME` es la siguiente:

```shell
JENKINS_HOME
 +- config.xml     (jenkins root configuration)
 +- *.xml          (other site-wide configuration files)
 +- userContent    (files in this directory will be served under your http://server/userContent/)
 +- fingerprints   (stores fingerprint records)
 +- plugins        (stores plugins)
 +- workspace (working directory for the version control system)
     +- [JOBNAME] (sub directory for each job)
 +- jobs
     +- [JOBNAME]      (sub directory for each job)
         +- config.xml     (job configuration file)
         +- latest         (symbolic link to the last successful build)
         +- builds
             +- [BUILD_ID]     (for each build)
                 +- build.xml      (build result summary)
                 +- log            (log file)
                 +- changelog.xml  (change log)
```

# Volumen de datos para Jenkins

En primer lugar, creamos el volumen dedicado para Jenkins:

```shell
$ sudo docker volume create data-jenkins
data-jenkins
```

# Contenedor de Jenkins

A continuación, descargamos la imagen de Docker Hub (`jenkins/jenkins`):

```shell
$ sudo docker pull jenkins/jenkins:2.118-alpine
2.118-alpine: Pulling from jenkins/jenkins
ff3a5c916c92: Already exists
5de5f69f42d7: Already exists
fd869c8b9b59: Already exists
e24f7a96a1b9: Pull complete
17e8eb77316c: Pull complete
44b258447c76: Pull complete
be18251f7aa1: Pull complete
84d1c8652b93: Pull complete
043c42490351: Pull complete
177281aeade6: Pull complete
d8969a5d448f: Pull complete
8f9977d60f1b: Pull complete
bedf3297f5cd: Pull complete
9af22c3bd2ad: Pull complete
Digest: sha256:276b32f777b9fcf2019f62c9d1b99f053a4dfd4cc6d29e739ab88c68b58bdf5a
Status: Downloaded newer image for jenkins/jenkins:2.118-alpine
$
```

Creamos el contedor montando el volumen recién creado:

```shell
$ sudo docker run -d --name jenkins -p 8080:8080 -p 50000:50000 \
   --mount source=data-jenkins,target=/var/jenkins_home \
   jenkins/jenkins:2.118-alpine
538872e49dc5eaa7a45222c5378b14e77542acb9b622b19251ea93026aa6a5de
```

El puerto 8080 es el de la interfaz web, mientras que el 50000 se usa para conectar con los _jenkins esclavos_.

Esperamos unos segundos hasta que Jenkins arranca completamente. Puedes seguir el proceso de arranque de Jenkins mediante `sudo docker logs -f jenkins`.

Revisando los logs, observamos el password inicial del administrador:

```shell
$ sudo docker logs jenkins
...
Apr 27, 2018 4:06:45 PM jenkins.install.SetupWizard init
INFO:

*************************************************************
*************************************************************
*************************************************************

Jenkins initial setup is required. An admin user has been created and a password generated.
Please use the following password to proceed to installation:

a6d3c33cdc854c7b8691f3a2cade7167

This may also be found at: /var/jenkins_home/secrets/initialAdminPassword

*************************************************************
*************************************************************
*************************************************************

Apr 27, 2018 4:06:49 PM hudson.model.UpdateSite updateData
INFO: Obtained the latest update center data file for UpdateSource default
Apr 27, 2018 4:06:50 PM hudson.model.DownloadService$Downloadable load
INFO: Obtained the updated data file for hudson.tasks.Maven.MavenInstaller
Apr 27, 2018 4:06:50 PM hudson.model.AsyncPeriodicWork$1 run
INFO: Finished Download metadata. 8,182 ms
Apr 27, 2018 4:06:50 PM hudson.model.UpdateSite updateData
INFO: Obtained the latest update center data file for UpdateSource default
Apr 27, 2018 4:06:50 PM jenkins.InitReactorRunner$1 onAttained
INFO: Completed initialization
Apr 27, 2018 4:06:50 PM hudson.WebAppMain$3 run
INFO: Jenkins is fully up and running
--> setting agent port for jnlp
--> setting agent port for jnlp... done
$
```

## Acceso inicial a Jenkins

Copiamos el password inicial para acceder a Jenkins a través del navegador:

{{< figure src="/images/180520/jenkins-unlock.png" w="1112" h="542" caption="Jenkins - Acceso con password autogenerado" >}}

Tras acceder, Jenkins nos proporciona la oportunidad de instalar un conjunto de _plugins_ sugeridos o de seleccionar los que queremos instalar.

De momento, seleccionamos la opción  de _Install suggested plugins_:

{{< figure src="/images/180520/jenkins-suggested-plugins.png" w="1000" h="492" caption="Jenkins - Suggested plugins" >}}

Jenkins descarga los plugins:

{{< figure src="/images/180520/jenkins-installing-plugins.png" w="1007" h="814" caption="Jenkins - Downloading and Installing plugins" >}}

 Tras la descarga, se lanza la opción de crear un nuevo usuario administrador (o continuar con el usuario `admin`):

{{< figure src="/images/180520/jenkins-create-admin.png" w="999" h="808" caption="Jenkins - Create new admin" >}}

He creado el usuario `operador` (`operador@jenkins.dev`) como usuario administrador de Jenkins.

Tras la creación del nuevo administrador, el proceso de configuración inicial finaliza:

{{< figure src="/images/180520/jenkins-setup-complete.png" w="1008" h="274" caption="Jenkins - Setup Complete!" >}}

Al pulsar el botón _Start using Jenkins_ accedemos a la pantalla principal de Jenkins:

{{< figure src="/images/180520/jenkins-homepage.png" w="1111" h="576" caption="Jenkins - Homepage" >}}

## Configuración del servidor de correo

En el menú lateral, seleccionamos _Manage Jenkins_ y después _Configure System_.

En la parte inferior de la página, en la sección _E-mail Notification_ establecemos la configuración del servidor de correo.

Introduce la dirección IP del _host_ de Docker, donde se ejecuta el contenedor `maildev`.

Como nuestro "servidor de correo" usa un puerto diferente al estándar, debemos especificarlo. Para ello, pulsa en el botón _Advanced…_ e introduce el puerto 10025 en el campo _SMTP Port_:

{{< figure src="/images/180520/jenkins-mailserver-configuration.png" w="771" h="420" caption="Jenkins - Mailserver configuration" >}}

Después de aplicar (_Apply_) la configuración, podemos probar la configuración enviando un email de prueba:

{{< figure src="/images/180520/jenkins-test-mail-configuration.png" w="745" h="125" caption="Jenkins - Test mail" >}}

Y en `maildev`:

{{< figure src="/images/180520/jenkins-received-test-mail.png" w="955" h="275" caption="Jenkins - Mail received" >}}

## Actualización de Jenkins

Jenkins tienen un ciclo de actualizaciones muy rápido (una nueva versión cada semana, [aproximadamente](https://wiki.jenkins.io/display/JENKINS/Release+Process)), por lo que si quieres mantener tu instalación al día, debes estar familiarizado con el proceso de actualización.

También existen versiones LTS (_long term support_) con un ciclo de vida más largo, con actualizaciones cada [6-9 semanas](https://jenkins.io/download/lts/).

En cualquier caso, al estar usando Jenkins en forma de contenedor, el proceso de actualización es muy sencillo:

- Descargamos la imagen actualizada de Jenkins desde DockerHub: [jenkins/jenkins](https://hub.docker.com/r/jenkins/jenkins/tags/)

```shell
$ sudo docker pull jenkins/jenkins:2.119-alpine
2.119-alpine: Pulling from jenkins/jenkins
ff3a5c916c92: Already exists
5de5f69f42d7: Already exists
fd869c8b9b59: Already exists
04bc670ac45e: Pull complete
cbaf38a34561: Pull complete
e6de9a6833f3: Pull complete
66f75611221e: Pull complete
931884bf2019: Pull complete
1ca32325f13e: Pull complete
22836225663b: Pull complete
c15389c3dc4c: Pull complete
c693c993d00f: Pull complete
337a5789d7db: Pull complete
23f606ec4fea: Pull complete
Digest: sha256:090fda0c0bb829f55235cfcee48b1875a30455868513e5dd2074ea7dd554c5a7
Status: Downloaded newer image for jenkins/jenkins:2.119-alpine
$
```

- Verificamos que tenemos la nueva imagen en el registro local:

```shell
$ sudo docker images
REPOSITORY            TAG                 IMAGE ID            CREATED             SIZE
jenkins/jenkins       2.119-alpine        a66359bc8e58        5 days ago          223MB
jenkins/jenkins       2.118-alpine        756b4704e481        13 days ago         223MB
...
```

- Detenemos el contenedor `jenkins`: `sudo docker stop jenkins`
- Eliminamos el contenedor `jenkins`: `sudo docker rm jenkins`
- Lanzamos un nuevo contenedor a partir de la imagen actualizada:

```shell
$ sudo docker run -d --name jenkins -p 8080:8080 -p 50000:50000 \
   --mount source=data-jenkins,target=/var/jenkins_home \
   jenkins/jenkins:2.119-alpine
f5d9c8d36a4e424f5ae03e086a3b92e00c73667079ff235062c588d2554a7ac3
```

Al tener todos los ficheros de configuración y _plugins_ almacenados en el volumen `data-jenkins` mantenemos toda la configuración realizada en el aplicación.