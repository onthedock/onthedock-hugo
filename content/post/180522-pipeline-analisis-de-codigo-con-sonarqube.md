+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev", "ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "integracion continua", "sonarqube", "jenkins"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/jenkins.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}

title=  "Pipeline - Análisis de código con Sonarqube"
date = "2018-05-23T12:12:06+02:00"
+++

En entradas anteriores hemos [subido el código de la aplicación al repositorio en Gogs]({{< ref "180521-subiendo-el-codigo-a-gogs.md" >}}) y hemos [instalado SonarQube]({{< ref "180521-pipeline-instalacion-de-sonarqube.md" >}}) y [Jenkins]({{< ref "180520-pipeline-instalacion-y-actualizacion-de-jenkins.md" >}}). Ahora, vamos a configurar Jenkins para que analice el código de la aplicación y detectar fallos incluso antes de compilar la aplicación.

<!--more-->

Usamos como referencia [Analyzing with SonarQube Scanner for Jenkins](https://docs.sonarqube.org/display/SCAN/Analyzing+with+SonarQube+Scanner+for+Jenkins).

El análisis de código por Sonarqube usando Jenkins se realiza mediante la instalación del _plugin_ **SonarQube Scanner for Jenkins**.

# Creación de un usuario en SonarQube

Para que Jenkins pueda invocar el análisis de código en SonarQube, es necesario proporcionar las credenciales o un _token de acceso_ a Jenkins.

[Referencia: User Token en SonarQube](https://docs.sonarqube.org/display/SONAR/User+Token)

Creamos un usuario específico en SonarQube.

1. _Administration_
1. _Security_, _Users_
1. Pulsamos el botón _Create User_

- _Login_ `autosonar`
- _Name_ `SonarQube User for Jenkins`
- _Email_ `autosonar@local.dev`
- _Password_ `**************`

Pulsamos _Create User_.

Para el usuario _autosonar_, en la columna _Tokens_, pulsamos en _Update Tokens_ para mostrar el cuadro de diálogo de creación de un nuevo token:

{{< figure src="/images/180523/sonarqube-tokens-0.png" w="991" h="98" caption="SonarQube - Update tokens" >}}

En el cuadro de diálogo, introducimos un nombre para el token y pulsamos el botón _Generate_:

{{< figure src="/images/180523/sonarqube-token-generated.png" w="541" h="367" caption="SonarQube - Token generated" >}}

Debemos copiar el token generado, ya que al cerra el cuadro de diálogo queda almacenado en SonarQube pero no puede consultarse.

# Instalación del plugin de SonarQube en Jenkins

Instalamos el plugin en Jenkins.

1. _Manage Jenkins_
1. _Manage Plugins_
1. En la pestaña _Available_, usamos la caja de búsqueda para encontrar _SonarQube Scanner_.
1. Marcamos y seleccionamos _Install without restart_.

## Configuración del plugin

Una vez instalado, configuramos:

1. _Manage Jenkins_
1. _Configure System_

En el apartado _SonarQube servers_, pulsamos el botón _Add SonarQube_ e indicamos los valores:

- _Name_: `SonarQube`
- _Server URL_: `http://192.168.1.209:9000/`
- _Server authentication token_: `02ad2efb4226051bbebdd4888cb0986f4534954c`

# Descarga del sonar-scanner

Para poder analizar el código, es necesario descargar la versión adecuada del _sonar-scanner_.

Como en el contenedor de Jenkins tenemos instalado Java, usaremos la versión _Any_ de SonarQube Scanner: [Analyzing with SonarQube Scanner](https://docs.sonarqube.org/display/SCAN/Analyzing+with+SonarQube+Scanner).

Para instalar SonarQube Scanner, entramos en el contenedor mediante `docker exec`, lo descargamos y descomprimimos en la carpeta ´/var/jenkins_home/tools/sonar-scanner/` que hemos creado en el volumen:

```shell
$ sudo docker exec -it jenkins /bin/sh
# cd /var/jenkins_home/
# mkdir tools
# cd tools
# wget https://sonarsource.bintray.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-3.1.0.1141.zip
# unzip sonar-scanner-cli-3.1.0.1141.zip
# mv sonar-scaner--cli-3.1.0.1141 sonar-scanner
# exit
$
```

## Configuración de SonarQube Scanner

1. _Manage Jenkins_
1. _Global Tool Configuration_
1. En la sección _SonarQube Scanner_, especificamos:
   - _Name_ : `SonarQube Scanner`
   - `_SONAR_RUNNER_HOME_` : `/var/jenkins_home/tools/sonar-scanner/`

## Creación del fichero `sonar-project.properties`

Creamos el fichero `sonar-project.properties` en la raíz del repositorio:

```shell
sonar.host.url=http://192.168.1.209:9000
sonar.projectKey=mvn:tutorial
sonar.projectName=GS Maven
sonar.projectVersion=1.0
sonar.sources=.
sonar.java.binaries=.
```

Este fichero especica una serie de _metadatos_ de configuración del análisis de código, como la clave y nombre del proyecto, la versión, etc.

> La propiedad `sonar.java.binaries=.` debe incluirse desde SonarQube 4.12; si no se obtiene el error _Please provide compiled classes of your project with sonar.java.binaries property_.

# Análisis con SonarQube Scanner

Cuando lanzamos el job de análisis, falla con el mensaje de error:

Error: _"No quality profiles have been found, you probably don't have any language plugin installed."_

Verificamos que no hay "Quality Profiles" definidos en SonarQube. Esto significa que no tenemos ningún analizador de código configurado en SonarQube.

Revisando el [documento de instalación de SonarQube]({{< ref "180521-pipeline-instalacion-de-sonarqube.md" >}}), no creamos el volumen de datos para alojar las _extensions_ (los _plugins_); por tanto, no tenemos ningún _plugin_ instalado en SonarQube.

## Volumen de datos para las extensiones de SonarQube

Creamos el volumen para las extensiones:

```shell
$ sudo docker volume create data-sonarqube-plugins
data-sonarqube-plugins
```

Paramos el contenedor de SonarQube y lo lanzamos de nuevo, montando ahora también el volumen para los _plugins_:

```shell
sudo docker run -d --name sonarqube -p 9000:9000 \
  --mount source=data-sonarqube,target=/opt/sonarqube/data \
  --mount source=data-sonarqube-plugins,target=/opt/sonarqube/extensions \
  -e SONARQUBE_JDBC_USERNAME=sonar \
  -e SONARQUBE_JDBC_PASSWORD=cF68nTVgP8Nq \
  -e SONARQUBE_JDBC_URL='jdbc:mysql://mysql-sonarqube:3306/sonar?useUnicode=true&characterEncoding=utf8&rewriteBatchedStatements=true&useConfigs=maxPerformance&useSSL=false' \
  --network backend-sonarqube \
  sonarqube:7.1-alpine
```

Como tarda un poco en arrancar, revisamos los logs mediante `sudo docker logs sonarqube -f` hasta que vemos el mensaje _SonarQube is up_.

## Instalación del plugin de análisis de código de Java

En _Administration_, _Marketplace_, buscamos _SonarJava_ y pulsamos el botón _Install_.

Una vez instalado, es necesario reiniciar SonarQube.

Tras el reinicio, accedemos a Jenkins para relanzar el job.

```shell
...
INFO: Task total time: 9.372 s
INFO: ------------------------------------------------------------------------
INFO: EXECUTION SUCCESS
INFO: ------------------------------------------------------------------------
INFO: Total time: 12.367s
INFO: Final Memory: 12M/137M
INFO: ------------------------------------------------------------------------
...
```

El _pipeline_ se muestra en verde, indicando que todos los pasos se han ejecutado con éxito:

{{< figure src="/images/180523/jenkins-pipeline-all-green.png" w="779" h="241" caption="Jenkins - Pipeline ok." >}}

También podemos revisar el detalle del análisis en SonarQube:

{{< figure src="/images/180523/sonarqube-analisis-ok.png" w="1211" h="989" caption="SonarQube - Quelity Gate: Passed." >}}