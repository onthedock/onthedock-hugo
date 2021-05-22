+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["docker"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/docker.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}

title=  "Usando contenedores como herramienta de desarrollo"
date = "2017-11-26T13:06:48+01:00"
+++

Una de las soluciones para el problema de proporcionar entornos de desarrollo a proveedores externos (colaborando en el desarrollo de aplicaciones) es proporcionar una máquina virtual pre-configurada con las herramientas aprobadas por la empresa.

Al usar contenedores se pueden solventar algunos de los problemas que presenta la solución basada en máquinas virtuales.

En esta entrada se tratan algunas de las ventajas que se derivan del uso de contenedores como parte del _toolchain_ del desarrollo de aplicaciones. Las problemáticas que resuelve el uso de contenedores son comunes a la mayoría de lenguajes de programación (tanto interpretados como compilados).

<!--more-->

En el mundo real, un desarrollador habitualmente trabaja simultáneamente en el mantenimineto de varias aplicaciones, que generalmente fueron desarrolladas por otros programadores en diferentes momentos del pasado y que usan versiones diferentes de librerías y frameworks.

En general, suele ser un problema tener instaladas diferentes versiones de las librerías o frameworks de desarrollo. Al _empaquetar_ las diferentes versiones en un contenedor, solucionamos las incompatibilidades entre diferentes versiones. Como el espacio y recursos requeridos por un contenedor es **muy** inferior al de una máquina virtual, el desarrollador dispone de un mayor abanico de opciones de cara al desarrollo.

Como ejemplo, el tamaño del contenedor de la versión del JDK versión 7 para Java -basado en Alpine Linux- ocupa sólo 142MB, frente a las decenas de _gigas_ que ocuparía una máquina virtual:

```shell
$ docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
openjdk             7-jdk-alpine        b6bec13008bd        3 weeks ago         142MB
```

A diferencia de lo que ocurre en una máquina virtual, usando el contenedor con las herramientas de compilación el desarrollador puede seguir usando su IDE preferido, en vez de tener que usar el que haya proporcionado la empresa en la máquina virtual.

Y cuando la empresa apruebe el uso de una nueva versión como base de los desarrollos, la actualización resulta tan sencilla como ejecutar `docker pull` usando la etiqueta correspondiente y dejar que Docker descargue la nueva versión.

## Ejemplo: compilar un programa java

En la máquina de desarrollo verificamos que java no está instalado:

```shell
$ javac
The program 'javac' can be found in the following packages:
 * default-jdk
 * ecj
 * gcj-5-jdk
 * openjdk-8-jdk-headless
 * gcj-4.8-jdk
 * gcj-4.9-jdk
 * openjdk-9-jdk-headless
Try: sudo apt install <selected package>
```

Descargamos la imagen oficial (en este caso, directamente desde DockerHub) de la versión 7 de OpenJDK:

```shell
$ docker pull library/openjdk:7-jdk-alpine
7-jdk-alpine: Pulling from library/openjdk
b56ae66c2937: Already exists
81cebc5bcaf8: Pull complete
1b523c1c6444: Pull complete
Digest: sha256:7ca2b9b21961b1a71e0271c10471d3c8ec6c683c926e7644e636922d123ee276
Status: Downloaded newer image for openjdk:7-jdk-alpine
```

Vamos a compilar el código de una aplicación de prueba, una versión de [HelloWorld.java](https://www.cs.utexas.edu/~scottm/cs307/javacode/codeSamples/HelloWorld.java) obtenida de la Universidad de Texas. Compilamos el código local usando:

```shell
docker run --rm -v "$PWD":/usr/src/helloworld -w /usr/src/helloworld openjdk:7-jdk-alpine javac HelloWorld.java
```

El comando ejecuta un contenedor que se eliminará cuando finalice la ejecución (`--rm`), montando la carpeta local (`$PWD`, _print working directory_) en el contenedor. Mediante la opción `-w` cambia la carpeta de trabajo dentro del contenedor al volumen montado y ejecuta la compilación usando `javac HelloWorld.java`.

Después de compilar, en la carpeta local obtenemos el fichero compilado `HelloWorld.class`.

Verificamos que el programa compilado funciona -usando de nuevo el contenedor- mediante:

```shell
$ docker run --rm -v "$PWD":/usr/src/helloworld -w /usr/src/helloworld openjdk:7-jdk-alpine java HelloWorld
Hello World!
```

## Resumen

Usando contenedores la empresa puede mantener una base de desarrollo homogénea, fijando versiones de compiladores, _librerías_ y _frameworks_ probados mateniendo la libertad del desarrollador para seguir utilizando su IDE preferido.

Usando contenedores es posible disponer de múltiples versiones de las mismas _librerías_ o _frameworks_ sin tener que lidiar con posibles incompatibilidades.

También es más ágil distribuir actualizaciones de la plataforma de desarrollo, ya que Docker únicamente descarga las diferencias con las imágenes previas.