+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev", "ops"]
# TAGS (HW->OS->PRODUCT->specific tag)`
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "docker"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/docker.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/

# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}
# YouTube           {{< youtube w7Ft2ymGmfc >}}
# Gist              {{< gist username 7896402 >}}
# Highlight         {{< highligth language >}}...{{< /highlight >}}
# Twitter           {{< tweet user="SanDiegoZoo" id="1453110110599868418" >}}

title=  "Todo lo que esconden las opciones por defecto en Docker"
date = "2022-03-25T20:33:24+01:00"
+++
El título tiene una sonoridad un poco a *click bait*, así que explicaré rápidamente a qué me refiero.

Hace poco que hemos empezado a colaborar en un proyecto nuevo.
Mientras nos vamos *poniendo al día* estoy ayudando a uno de mis compañeros -un *crack* en *networking*- con temas relacionados con contenedores, con los que está menos familiarizado.

Revisando los ficheros de configuración de *Google Cloud Build*, encontramos, en el mismo fichero, referencias a la imagen de un contenedor como `hashicorp/terraform:latest`, otras en las que el nombre es de la forma `gcr.io/cloud-builders/gcloud` y otras en las que es, *simplemente*, `alpine`.

Y claro, mi compañero no entiende nada...
<!--more-->

## Todo lo que contiene -aunque no se vea- el nombre de una imagen de contenedor

Una buena explicación se encuentra en la documentación de Red Hat [Image-naming conventions](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux_atomic_host/7/html/recommended_practices_for_container_development/naming).

Básicamente, el nombre de una imagen (de contenedor) está compuesto de `REGISTRY[:PORT]/USER/REPO[:TAG]`:

- el FQDN del registro donde se aloja la imagen
- el puerto de acceso al *registry*
- el nombre del usuario *propietario* de la imagen
- el nombre del repositorio que contiene la imagen
- la etiqueta que designa la versión de la imagen

Docker Inc, la compañía que desarrolló `docker` estableció como **registro por defecto** Docker Hub, de manera que no es necesario indicar el FQDN (ni el puerto) para descargar una imagen alojada en Docker Hub.

Esto permite especificar una imagen (siempre que esté alojada en Docker Hub) como `nombre/imagen`, por ejemplo [`hashicorp/terraform`](https://hub.docker.com/r/hashicorp/terraform).

> El uso de DockerHub como *registry* por defecto es para el cliente `docker` (no es configurable); `podman`, en cambio, establece por defecto los registros asociados con Red Hat, pero permite *personalizarlos* mediante el fichero [`/etc/containers/registries.conf`](https://docs.podman.io/en/latest/markdown/podman-search.1.html?highlight=registries).

En el caso de la imagen para `gcloud`, alojada en el Registry de Google (*Google Container Registry*) -y por tanto, no en DockerHub- debemos preceder el nombre de usuario y el de la imagen con la URL del *registry*: `gcr.io/cloud-builders/gcloud`.

¿Qué pasa entonces con `alpine`?

La imagen de Alpine Linux, [alpine](https://hub.docker.com/_/alpine) en DockerHub no incluye el nombre de usuario (`hashicorp` o `cloud-builders`, en los ejemplos del principio del artículo).

La imagen de Alpine es lo que se denomina una [**imagen oficial de Docker**](https://docs.docker.com/docker-hub/official_images/). Estas imágenes están *tutorizadas* por el equipo de DockerHub, que colabora con los *mantenedores* de los productos contenidos en estas imágenes. En este caso, al tratarse de imágenes de *interés general*, no *pertenecen* a ningún usuario, y por tanto, se referencian únicamente por el nombre de la imagen.

La última parte del nombre de la imagen, la *etiqueta* (`tag`), si no se explicita, se asume el valor `latest` (como se indica en la documentación de Docker para [`docker tag`](https://docs.docker.com/engine/reference/commandline/tag/#tag-an-image-referenced-by-id)).

Así, una imagen oficial en DockerHub (etiquetada como `latest`) -por ejemplo `alpine`- puede referenciarse como :

- `alpine`
- `alpine:latest`
- `index.docker.io/alpine:latest`

(Todas las opciones son equivalentes).

Para una imagen *no oficial* (en DockerHub), es necesario añadir el nombre de usuario, por lo que las *variaciones* con respecto al nombre de la imagen son:

- `hashicorp/terraform`
- `hashicorp/terraform:latest`
- `index.docker.io/hashicorp/terraform:latest`

Para cualquier otro *registry*, la única opción es indicar la ruta completa de la imagen (el uso de la etiqueta `latest` sigue siendo opcional, en el caso de que sea la versión elegida).

- `gcr.io/cloud-builders/gcloud`
- `gcr.io/cloud-builders/gcloud:latest`

## Establecer un criterio (y documentarlo)

Todas estas *ambigüedades* desaparecen si se eliminan las *opciones por defecto* y si es necesario, en todos los casos, usar el *nombre completo* de las imágenes.

Aunque Docker Hub es sin duda el registro *público* de imágenes de contenedores más importante, no siempre es *el sitio más seguro* desde el que descargar imágenes. Por ello no es extraño que en entornos empresariales sólo sea posible usar imágenes que han pasado un proceso de verificación por parte del departamento de seguridad y que se encuentren en un registro privado.

En este caso el equipo de IT suele proporcionar información clara sobre cómo hacer referencia a una imagen alojada en el registro corporativo.

Sin embargo, hay situaciones *mixtas* -especialmente en procesos de CI/CD- en los que se usan imágenes de múltiples *registries*, imágenes *oficiales* e imágenes *propias* junto con imágenes de terceros, en las que los miembros de un equipo pueden tener perfiles que no estén familiarizados con el *mundillo* de los contenedores.

En este caso, los *valores por defecto* y las convenciones establecidas generan confusión que puede provocar errores o ineficiencias.

La solución es tan sencilla y evidente como poco común: establecer claramente un *estándar interno* en el que se especifique en qué casos se puede usar el "valor por defecto" (y documentar qué valor toma), o bien *eliminar* los valores por defecto y **homogeneizar** la forma de referenciar imágenes de contenedores, independientemente del cliente usado o del registro en el que se aloje.

Especificar una versión concreta de la imagen (no admitiendo `latest`) o exigir el uso del *hash* para identificar la imagen usada permite tener un mayor control sobre los cambios del software contenido en la imagen.

El proceso de actualización se realiza entonces de manera voluntaria, de forma controlada y realizando las pruebas que aseguren el correcto funcionamiento de la aplicación tras la actualización. Permite además, actualizar la documentación, si es necesario.

## Conclusión

Especifica **siempre** el nombre *completo* de las imágenes usadas en, por ejemplo, los ficheros de configuración de Cloud Build.

Indicando el *registry* en el que se encuentra la image, se documenta específicamente a qué URL debe tener acceso la plataforma de CI/CD interna, si la salida a internet está restringida o limitada desde la zona corporativa en la que se encuentren estos equipos.

Elige, de entre las imágenes necesarias para realizar las tareas, aquella con menor número de componentes. Esto no sólo reduce los tiempos de descarga y los recursos necesarios para la plataforma de CI/CD, sino que además reduce el riesgo de que la imagen contenga vulnerabilidades.

Es habitual que los usuarios ofrezcan una versión basada en *alpine* o algún tipo de variante *slim*; por tanto, siempre que sea posible, lo ideal sería seleccionar la imagen más *compacta*.

Respecto a las imágenes basadas en Alpine, es necesario validar que ninguna de las elecciones que hacen que Alpine sea tan ligera interfiere con el funcionamiento de la aplicación o con el *standard* adoptado.

Por ejemplo, si se define Bash como intérprete de *shell scripts* (como hace Google, por ejemplo en [Shell Style Guide](https://google.github.io/styleguide/shellguide.html#s1.1-which-shell-to-use)), debes tener en cuenta que en Alpine, el intérprete de comandos de la *shell* es `ash`, no `bash`; en general, no es relevante, pero puede introducir pequeñas diferencias en cómo se ejecutar tus *scripts* o aplicaciones que pueden generar errores difíciles de detectar.

En el caso específico de Cloud Build, especifica siempre el `entrypoint` y sé consistente; si quieres usar `bash`, define en el [*shebang*](https://en.wikipedia.org/wiki/Shebang_(Unix)) de tus *scripts* `#!/bin/bash` y no cualquier otra forma. Esto es aplicable a los *shell scripts* en cualquier otro entorno.

Fíjate que, en la Wikipedia, se indica (las negritas son mías):

> - `#!/bin/sh` – Execute the file using the Bourne shell, **or a compatible shell**, assumed to be in the /bin directory
> - `#!/bin/bash` – Execute the file using the Bash shell

Es decir, que usando `#!/bin/sh`, puede usarse un intérpre *shell* **diferente** a `bash` y eso, de nuevo, puede introducir erres o comportamientos difíciles de diagnosticar.

Recuerda finalmente que se considera una **mala práctica** usar la etiqueta `latest` para indicar la versión de la imagen de contenedor. Por ejemplo, el artículo (de 2015 pero completamente vigente) [Docker: The latest Confusion](https://blog.container-solutions.com/docker-latest-confusion) de Adrian Mouat describe todos los problemas y *malentendidos* acerca de la etiqueta `latest`.

Y tampoco cuesta tanto escribir *un poquito más* e indicar `index.docker.io/hashicorp/terraform:1.1.7` en vez de `hashicorp/terraform` teniendo en cuenta todos los problemas que te puedes ahorrar ;)
