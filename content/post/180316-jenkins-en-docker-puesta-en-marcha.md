+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["docker", "jenkins", "integracion continua"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/jenkins.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}

title=  "Jenkins en Docker: puesta en marcha"
date = "2018-03-16T21:39:10+01:00"
+++

Uno de los casos de uso más frecuentes de Docker es formando parte de una cadena de integración y despliegue continuo (CI/CD) gestionada por Jenkins.

En esta serie de artículos vamos a levantar un contenedor con Jenkins sobre Docker y vamos a configur Jenkins paso a paso.

<!--more-->

# Descarga y ejecución de Jenkins en un contenedor

La instalación de Jenkins usando Docker no podía ser más sencilla:

1. Buscamos la imagen oficial de Jenkins en Docker Hub: `https://hub.docker.com/r/jenkins/jenkins/`
1. Revisamos las etiquetas disponibles y seleccionamos la última versión disponible (al escribir este artículo) basada en Alpine Linux: `jenkins/jenkins:2.107.1-alpine`.
1. Descargamos la imagen a nuestro repositorio local: `docker pull jenkins/jenkins:2.107.1-alpine`.
1. Creamos un volumen local donde almacenar la configuración de Jenkins: `docker volume create jenkins_home`
1. Lanzamos el contenedor para Jenkins, montando el volumen de datos creado en el punto anterior: `docker run --name jenkins -p 8080:8000 -p 50000:50000 -v jenkins_home:/var/jenkins_home jenkins/jenkins:2.107.1-alpine`

## El comando `docker run` paso a paso

El comando anterior lanza un contenedor llamado `jenkins` (especificado mediante `--name jenkins`) basado en la imagen `jenkins/jenkins:2.107.1-alpine`.

El contenedor monta el volumen `jenkins_home` en el contenedor (si no se ha creado en el punto 4, se crea el volumen al lanzar el contenedor). El volumen contiene toda la configuración de Jenkins, lo que permitirá actualizar la aplicación a otras versiones sin perder la configuración. La opción de guardar la configuración en un contenedor es preferible a la de montar un volumen local del _host_.

Si decides montar un volumen local del _host_ en el contenedor, debes tener en cuenta que Jenkins corre dentro del contenedor con el usuario `jenkins`, con `uid 1000`; deberás dar permisos en la carpeta local a este usuario para no tener problemas de acceso desde el contenedor. Otra opción es ejecutar Jenkins con un usuario "local" del _host_ mediante el parámetro `-u nombre_de_usuario` al ejecutar `docker run`.

### Puertos

El acceso web a la aplicación se realiza a través del puerto 8080 , mientras que el puerto 50000 es necesario para conectar con otros servidores Jenkins _esclavos_ a través de JNLP (Java Web Start). Si solo vas a utilizar _esclavos_ vía SSH, no necesitas abrir el puerto 50000.

### Otras configuraciones

Puedes realizar configuraciones adicionales a través de parámetros al ejecutar el contenedor, como ajustar el nivel de detalle en los _logs_, configurar el número de _ejecutores_, etc.

### Preinstalación de plugins

Para preinstalar _plugins_ en Jenkins, debes crear una imagen personalizada. En la imagen, puedes usar el script `install-plugins.sh` para descargar los plugins indicados. Puedes pasar una lista de plugins a instalar al script mediante:

```shell
...
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt
```

Cuando el contenedor de Jenkins arranca, comprueba si los _plugins_ indicados existen en `JENKINS_HOME` y los copia si es necesario. **No sobrescribirá los ficheros**, por lo que si has actualizado los _plugins_ desde la interfaz web, no los modificará.

Es posible **sobrescribir** los _plugins_ si lo necesitas; para ello debes añadir `.override` al nombre del _plugin_ que quieras sobrescribir.

## Primer acceso a Jenkins

Abre un navegador y accede a http://IP-del-host-docker:8080. Después de unos segundos en los que Jenkins debe acabar de arrancar, se muestra el siguiente mensaje:

{{< figure src="/images/180316/jenkins-unlock.png" >}}

Jenkins genera una contraseña segura en `/var/jenkins_home/secrets/initialAdminPassword`. Puedes obtener esta contraseña inicial de diferentes maneras, pero la más sencilla es revisando los logs de arranque de Jenkins:

```shell
$ docker logs jenkins
...

Jenkins initial setup is required. An admin user has been created and a password generated.
Please use the following password to proceed to installation:

cb6e558c91e946ab8f06cf085c9cf88b

This may also be found at: /var/jenkins_home/secrets/initialAdminPassword

*************************************************************
*************************************************************
*************************************************************

Mar 17, 2018 5:42:29 AM hudson.model.UpdateSite updateData
INFO: Obtained the latest update center data file for UpdateSource default
Mar 17, 2018 5:42:29 AM hudson.model.DownloadService$Downloadable load
INFO: Obtained the updated data file for hudson.tasks.Maven.MavenInstaller
Mar 17, 2018 5:42:31 AM hudson.model.DownloadService$Downloadable load
INFO: Obtained the updated data file for hudson.tools.JDKInstaller
Mar 17, 2018 5:42:31 AM hudson.model.AsyncPeriodicWork$1 run
INFO: Finished Download metadata. 8,990 ms
Mar 17, 2018 5:42:31 AM hudson.model.UpdateSite updateData
INFO: Obtained the latest update center data file for UpdateSource default
Mar 17, 2018 5:42:31 AM hudson.WebAppMain$3 run
INFO: Jenkins is fully up and running
--> setting agent port for jnlp
--> setting agent port for jnlp... done
```

Personalmente considero más útil aprovechar que el password inicial se encuentra en el fichero `/var/jenkins_home/secrets/initialAdminPassword` y obtenerlo usando `cat /var/jenkins_home/secrets/initialAdminPassword` mediante `docker exec`.

```shell
$ docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
cb6e558c91e946ab8f06cf085c9cf88b
```

De esta forma puedes guardar el password en una variable de entorno y usarlo en un script, para acceder desde otra aplicación usando la API, etc.

```shell
$ JENKINS_InitialPassword=$(docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword)

$ echo $JENKINS_InitialPassword
cb6e558c91e946ab8f06cf085c9cf88b
```

Copia el password e introdúcelo para acceder a Jenkins.

## Instalación de plugins

Jenkins ofrece la posibilidad de instalar los _plugins_ sugeridos por la comunidad o realizar nosotros la selección de forma manual. Podemos instalar o desinstalar _plugins_ después, por lo que pulsamos en la opción _Install suggested plugins_:

{{< figure src="/images/180316/jenkins_suggested_plugins.png" >}}

El sistema descarga los _plugins_:

{{< figure src="/images/180316/jenkins_suggested_plugins_installation.png" >}}

## Creación de un usuario administrador

Tras la instalación, se muestra el formulario para crear un usuario administrador:

{{< figure src="/images/180316/jenkins_first-admin-user.png" >}}

Jenkins ofrece la posibilidad de seguir usando el usuario _admin_, sin crear usuarios adicionales.

Tras la creación del usuario, podemos empezar a usar Jenkins:

{{< figure src="/images/180316/jenkins_is_ready.png" >}}

Si hemos creado un nuevo usuario administrador, accedemos a Jenkins con el usuario recién creado:

{{< figure src="/images/180316/jenkins_landingpage.png" >}}

## Resumen

Hemos descargado la imagen de Jenkins y hemos arrancado un contenedor a partir de ella. Hemos indicado cómo acceder usando el password generado durante el primer arranque, cómo configurar los _plugins_ sugeridos y crear el primer usuario.

En los siguientes artículos crearemos los primeros _jobs_ de prueba en Jenkins.