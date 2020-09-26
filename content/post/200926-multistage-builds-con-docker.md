+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "docker"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/docker.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Clear (floats) {{% clear %}}

title=  "Multi-stage builds con Docker"
date = "2020-09-26T09:19:18+02:00"
+++
Los *multi-stage builds* son una funcionalidad introducida en Docker en la versión 17.05 que proporciona importantes ventajas respecto a los *builds* "todo-en-uno", principalmente en cuanto a **seguridad** y **tamaño** de la imagen resultante.
<!--more-->

## Herramientas "mágicas"

El escenario con el que me he encontrado esta semana es un equipo de desarrollo no habituado a desplegar aplicaciones en contenedores, y que cuando lo hace, usa [Source-to-Image (S2I)](https://docs.openshift.com/container-platform/4.5/builds/understanding-image-builds.html#build-strategy-s2i_understanding-image-builds).

S2I es una herramienta para construir artefactos e inyectarlos en una imagen de contenedor. S2I *inspecciona* el código y determina de qué lenguaje de programación se trata. A partir de ahí, S2I usa las instrucciones del `pom.xml`, por ejemplo, para realizar la compilación del código. Una vez compilado el código, S2I descarga una imagen base con el *runtime* necesario para ejecutar el artefacto generado, copia el artefacto, y construye una imagen de contenedor lista para desplegar.

Como ves, S2I realiza una serie de elecciones en nombre del desarrollador como la selección de la imagen base, el *registry* desde donde descargarla, etc. Si hay restricciones sobre la selección de la imagen, el acceso a determinados *registros* públicos o si se debe realizar acciones adicionales de *personalización*, no es posible usar S2I como herramienta de construcción de la imagen.

## Herramientas "mágicas" en el "mundo real"

En las empresas es habitual que únicamente se soporten/permitan/recomienden determinadas versiones de los *frameworks* o lenguajes usados para el desarrollo de aplicaciones (especialmente si no se trata de una compañía cuyos productos sean el propio software).

Esto hace que la elección de la imagen base con el *tooling* de compilación del código deba especificarse de acuerdo a esa normativa interna.

Del mismo modo, es habitual que por motivos de seguridad no se permita el uso de imágenes púbilcas y que se proporcionen imágenes "securizadas" (o las medidas a aplicar) de acuerdo a lo establecido por los equipos de seguridad...

El resultado de estas limitaciones es que es soluciones como S2I que actúan "automágicamente" no son viables más allá de las primeras fases de desarrollo, mientras el equipo de proyecto realiza el *onboarding* y se adapta a las regulaciones de cada empresa.

## *Multi-stage builds* al rescate

Usando un *multi-stage build* podemos proporcionar cierta flexibilidad al equipo de desarrollo a la vez que aplicamos las medidas habituales de un entorno empresarial.

La construcción de una imagen final usando múltiples pasos intermedios nos proporciona una funcionalidad similar a Jenkins o Tekton en procesos de CI/CD, pero a nivel de la construcción de la imagen.

El proceso para construir la imagen, en general, se divide en dos pasos: la compilación del código y la inyección del artefacto generado en la imagen final.

### Compilación del código

En este ejemplo voy a usar código en Go ya que permite generar ejecutables que no requieren una máquina virtual independiente (como Java).

El código de la *aplicación* es el siguiente:

```golang
package main

import "fmt"

func main() {
    fmt.Println("Hello world from Go!")
}
```

Para compilar el código usaremos un contenedor con las herramientas de desarrollo para Go; el fichero `Dockerfile` sería algo como:

```dockerfile
FROM golang:1.14.2-alpine
WORKDIR /src
COPY src .
RUN go build -o /out/helloworld .
```

Usando `docker build ...` construiríamos una imagen, con el binario ya compilado que podríamos usar para ejecutar la aplicación.

Si revisamos más de cerca la imagen generada y la comparamos con la imagen base usada:

```bash
$ docker images
REPOSITORY   TAG             IMAGE ID       CREATED        SIZE
<none>       <none>          06ca475ca0bc   2 hours ago    372MB
golang       1.14.2-alpine   dda4232b2bd5   5 months ago   370MB
```

Haciendo una sencilla resta, vemos que la "aplicación" que hemos generado ocupa aproximadamente 2MB, pero que la imagen resultante son 372MB debido a todas las herramientas de compilación necesarias para Go.

En la imagen final que despleguemos en producción las herramientas de compilación no son necesarias; además de ocupar espacio, aumentan la *superficie de ataque* de la imagen (es decir, pueden introducir vulnerabilidades que un atacante podría explotar para "colarse" en el contenedor).

En vez de compilar el código y generar el binario "dentro" del contenedor, podríamos montar una carpeta local y obtener como resultado únicamente el binario final (`docker run -v ... golang:1.14.2-alpine go build ...`).

Esto es mucho más eficiente, pero es sólo la "mitad" de la historia; tenemos el binario, pero todavía tenemos que *inyectarlo* en una imagen para poder desplegarlo en Kubernetes, por ejemplo.

## *Multi-stage build*

En vez de generar un segundo `Dockerfile` que simplemente *copie* el artefacto en una nueva imagen base, el proceso de *multi-stage build* permite realizar los dos pasos necesarios en este caso **usando un único `Dockerfile`**.

```Dockerfile
FROM golang:1.14.2-alpine AS builder
WORKDIR /src
COPY src .
RUN go build -o /out/helloworld .

FROM scratch AS bin
COPY --from=builder /out/helloworld /
ENTRYPOINT ["/helloworld"]
```

Como ves, el primer bloque es igual que en el caso "habitual", de compilación del código. La única diferencia es que asignamos el *alias* `builder` a la imagen resultante de la ejecución de las instruciones de este bloque; de esta forma, podemos hacer referencia a ella en pasos posteriores en el `Dockerfile`.

El segundo bloque usa una imagen base **diferente** de partida (en este caso, una imagen vacía, `scratch`).

En la instrucción `COPY`, en vez de indicar un origen "local" en el *filesystem* del equipo donde ejecutamos Docker usamos `--from=builder`. Con este parámetro Docker monta la ruta `/out/helloworld` de la imagen que hemos llamado `builder` como origen de la instrucción `COPY`.

### Construcción de una imagen usando un *multi-stage build*

La construcción de la imagen se realiza del mismo modo que en un proceso *single-stage*:

```bash
$ docker build -t helloworld:multi .
Sending build context to Docker daemon  3.584kB
Step 1/7 : FROM golang:1.14.2-alpine AS builder
 ---> dda4232b2bd5
Step 2/7 : WORKDIR /src
 ---> Using cache
 ---> 3e133d545734
Step 3/7 : COPY src .
 ---> Using cache
 ---> 9c877140ab21
Step 4/7 : RUN go build -o /out/helloworld .
 ---> Using cache
 ---> 06ca475ca0bc
Step 5/7 : FROM scratch AS bin
 --->
Step 6/7 : COPY --from=builder /out/helloworld /
 ---> Using cache
 ---> 5ae13095cb32
Step 7/7 : ENTRYPOINT ["/helloworld"]
 ---> Running in 7a9e8a42aeff
Removing intermediate container 7a9e8a42aeff
 ---> b23c0b2e9ca6
Successfully built b23c0b2e9ca6
Successfully tagged helloworld:multi
```

Podemos validar que la imagen generada contiene la aplicación:

```bash
$ docker run --rm helloworld:multi
Hello World from Go!
```

Si observamos la imagen generada `helloworld:multi` podemos comprobar que el tamaño es muy inferior a la imagen original:

```bash
$ docker images
REPOSITORY   TAG             IMAGE ID       CREATED          SIZE
helloworld   multi           b23c0b2e9ca6   13 minutes ago   2.07MB
golang       1.14.2-alpine   dda4232b2bd5   5 months ago     370MB
```

La imagen con las herramientas de compilación se usa como una imagen intermedia cualquiera en el proceso de construcción de la imagen final; se guarda en la caché local de Docker, pero no se incorpora a la imagen final.

### Usando una imagen no vacía

El uso de imágenes `scratch` es óptimo desde el punto de vista de la seguridad y la eficiencia, pero en general se usa una imagen base con las herramientas básicas proporcionadas por una distribución alineada con las medidas corporativas de la empresa.

En el siguiente ejemplo usaremos la versión 3.12 de *Alpine Linux*.

### Adecuando la imagen final a los requerimientos de la empresa

En general, es posible que haya que aplicar medidas de seguridad en la imagen, eliminando paquetes innecesarios, etc.

Para simplificar el ejemplo, imaginamos que el departamento de *compliance* de la empresa SUPERCORP, Inc indica que hay que incorporar un texto determinado de "términos de uso".

```text
This image is provided AS IS.

You use the software at your own risk.

We make no warranties as to performance, merchantability,
fitness for a particular purpose, or any other warranties
whether expressed or implied.

Under no circumstances shall SUPERCORP, Inc be liable for
direct, indirect, special, incidental, or consequential
damages resulting from the use, misuse, or inability to use
this software.
```

El uso de *multi-stage build* permite mantener inalterado el paso de compilación y adecuar la imagen final a los requerimientos de seguridad, compliance, etc que requiere SUPERCORP, Inc usando la imagen que nos indiquen; en el ejemplo, Alpine Linux:3.12:

```Dockerfile
FROM golang:1.14.2-alpine AS builder
WORKDIR /src
COPY src .
RUN go build -o /out/helloworld .

FROM alpine:3.12 AS bin
COPY --from=builder /out/helloworld /
COPY compliance /compliance
CMD ["/helloworld"]
```

La imagen resultante `helloworld:multi-alpine-v1.1` sigue teniendo un tamaño comedido, gracias al uso de Alpine:

```bash
$ docker images
REPOSITORY   TAG                 IMAGE ID       CREATED          SIZE
helloworld   multi-alpine-v1.1   44253a0a8e89   6 minutes ago    7.64MB
helloworld   multi               b23c0b2e9ca6   56 minutes ago   2.07MB
alpine       3.12                a24bb4013296   3 months ago     5.57MB
```

Comprobamos que la aplicación sigue funcionando después de aplicar las medidas exigidas por la empresa:

```bash
$ docker run --rm helloworld:multi-alpine-v1.1
Hello World from Go!
```

Esta nueva imagen incluye los requerimientos no funcionales de la compañía:

```text
$ docker run --rm helloworld:multi-alpine-v1.1 cat /compliance/legal_terms.txt
This image is provided AS IS.

You use the software at your own risk.

We make no warranties as to performance, merchantability,
fitness for a particular purpose, or any other warranties
whether expressed or implied.

Under no circumstances shall SUPERCORP, Inc be liable for
direct, indirect, special, incidental, or consequential
damages resulting from the use, misuse, or inability to use
this software.
```

## Imágenes en registros diferentes a Docker Hub

Hasta ahora todas las imágenes base que hemos usado son públicas y provienen el *registry* por defecto de Docker: [Docker Hub](https://hub.docker.com/).

Es habitual que la empresa disponga de un *registry* corporativo privado, con imágenes que han sido *securizadas* y que son examinadas de forma periódica en busca de vulnerabilidades, actualizadas para corregir bugs, etc...

Dado que no es un escenario aplicable únicamente a los *multi-stage builds* -y a que la entrada ya es un pelín larga-, lo comento en un *post* separado.

En vez de usar un *registry* privado, usaré un *registry* público diferente a Docker Hub. Los registros privados pueden presentar sus propios *challenges*, especialmente por temas de autenticación. Usar un registro público "alternativo" permite mostrar cómo usar registros diferentes al establecido "por defecto" así como el uso de registros privados sin autenticación ("públicos" dentro de perímetro de red de la empresa).
