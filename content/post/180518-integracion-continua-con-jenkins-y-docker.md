+++
draft = false
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "jenkins", "docker", "integracion continua", "devops"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/jenkins.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}

title=  "Integración continua con Jenkins y Docker"
date = "2018-05-18T06:42:34+02:00"
+++

En esta serie de artículos quiero construir una _pipeline_ de integración continua basada en Jenkins sobre Docker.

<!--more-->

El objetivo es desplegar el máximo número de aplicaciones sobre Docker relacionadas con un proceso de integración continua para tener un _pipeline_ funcional. Durante el proceso surgirán problemas de integración entre las diferentes aplicaciones que será interesante resolver y que me ayudarán a conocer mejor las aplicaciones y su uso sobre Docker.

He elegido construir una aplicación en [Java](https://java.com/) usando [Maven](https://maven.apache.org) por ser uno de los escenarios más representativos.

En cuanto a las herramientas, a continuación explico porqué las he seleccionado.

Algunos de los factores que tenido en cuenta a la hora de seleccionarlas:

- Gratuita (preferiblemente, de código abierto)
- Desplegable usando Docker
- Representativa (uso generalizado y no específico)

# Gogs

[Gogs](https://gogs.io) es un sistema de control de versiones basado en Git de código abierto. Está escrito en Go y es muy ligero ([puedes ejecutarlo en una Rapsberry Pi]({{< ref "171106-gogs-como-crear-tu-propio-servicio-de-hospedaje-de-repos-git.md" >}})).

A nivel de funcionalidades, Gogs es prácticamente equivalente a GitHub, que se ha convertido en el estándar para almacenar código.

{{< figure src="/images/180518/gogs.png" w="1257" h="499" >}}

Otra opción interesante es [BitBucket](https://bitbucket.org) que permite repositorios privados en la versión gratuita (a diferencia de GitHub).

Sin embargo, es probable que tu organización quiera tener el código fuente de las aplicaciones desarrolladas bajo su control, por lo que he preferido una opción que instalable _on premises_.

Otra alternativa _todo en uno_ es [GitLab](https://about.gitlab.com), pero creo que lo más habitual es que en la organización es trabajar con varias herramientas independientes orquestadas por Jenkins.

# SonarQube

[SonarQube](https://www.sonarqube.org) es una herramienta de _inspección contínua de la calidad del código_. Aunque recientemente ha cambiado el modelo de licenciamiento, sigue ofreciendo una versión _free_ limitando el número de _analizadores de código_ soportados.

# Jenkins

[Jenkins](https://jenkins.io) es el orquestador que se encarga de gestionar el resto de herramientas, el anillo único que los domina a todos ;)

Aunque existen otras herramientas de integración contínua Jenkins es sin duda la _estándar_, tanto por veteranía, documentación y cantidad de plugins.

# Nexus

[Nexus Repository OSS](https://www.sonatype.com/nexus-repository-oss) es un repositorio de los artefactos generados por el _pipeline_. Nexus proporciona otras funcionalidades, pero en este estenario será el punto final del _pipeli

## Otras herramientas

Aunque no son esenciales para el _pipeline_, usaremos [MailDev](http://danfarrelly.nyc/MailDev/) como sustituto del servidor de correo y [Portainer](https://portainer.io), para simplificar en la gestión de los contenedores.

MailDev simula un servidor de correo, por lo que podemos configurarlo en todas las herramientas que necesiten enviar notificaciones durante la fase de desarrollo. MailDev también proporciona un acceso web con diferentes herramientas para poder visualizar los mails recibidos de diferentes formas (HTML, sólo texto, simulando un dispositivo móvil con diferentes tamaños de pantalla, etc).

[Portainer]({{< ref "180317-portainer.md" >}}) permite gestionar Docker de manera gráfica a través del navegador. Aunque en el tutorial siempre usaremos la línea de comandos, Portainer ofrece una alternativa sencilla y cómoda para conectar con un contenedor, borrar volúmenes no usados por ningún contenedor, etc...

# Contenedores

Todas las herramientas se pueden desplegar como contenedores, por lo que usaremos Docker como gestor de contenedores.

# Resumen

En lo siguientes artículos de esta serie, nos adentraremos en los diferentes aspectos de despliegue y configuración de las herramientas del _pipeline_.