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
# Twitter {{% twitter tweetid="780599416621297xxx" %}}

title=  "Usar una imágen base de un registry diferente a Docker Hub"
date = "2020-09-26T14:02:56+02:00"
+++
A continuación de la entrada anterior, [Multi-stage builds con Docker]({{<ref "200926-multistage-builds-con-docker.md">}}), la idea es explicar cómo usar una imagen base de un registro diferente a Docker Hub, que es el registro por defecto para Docker.
<!--more-->

## Nombre de las imágenes

Al crear una imagen de forma local en nuestro equipo, usamos el parámetro `-t` para aplicar una etiqueta a la imagen.

En los ejemplos de la [entrada anterior]({{<ref "200926-multistage-builds-con-docker.md">}}), por ejemplo, he generado varias imágenes, con nombres como `helloworld:multi` o `helloworld:multi-alpine-v1.1`. Las imágenes bases descargadas desde Docker Hub tenían un nombre con una estructura parecida: `golang:1.14.2-alpine` o `alpine:3.12`.

En el primer caso, `helloworld` sería el nombre de la imagen, mientras que tras los ":" se muestra la etiqueta, por ejemplo: `multi` o `3.12` (en el caso de Alpine).

El nombre es en realidad el *repositorio* en el que se guardan todas las versiones de la imagen.

Las etiquetas se usan, en general, para identificar diferentes versiones de una imagen, (`v1`, `v2`), pero en realidad son arbitrarias, a elección del creador de la imagen. Se pueden aplicar múltiples etiquetas a una misma imagen.

Observa, por ejemplo, cómo el `IMAGE ID` de estas dos imágenes es el mismo, aunque tienen etiquetas diferentes (`8.2` y `latest`):

```bash
$ docker images
REPOSITORY                                    TAG      IMAGE ID       CREATED       SIZE
registry.access.redhat.com/ubi8/ubi-minimal   8.2      28095021e526   3 weeks ago   142MB
registry.access.redhat.com/ubi8/ubi-minimal   latest   28095021e526   3 weeks ago   142MB
```

La etiqueta `latest` se aplica por defecto si no se especifica otra etiqueta de forma explícita.

Diferentes proyectos asignan a la etiqueta `latest` un uso diferente: en algunos casos, se trata de la imagen construida más recientemente. En otros, se aplica a la versión **stable** más reciente... En cualquier caso, al ser una etiqueta que "identifica" versiones de la imagen que pueden tener un contenido diferente, es mejor no usarlas como "base" para construir tus propias imágenes. En los ficheros `Dockerfile` deberías siempre especificar como etiqueta una versión específica de la imagen base usada para construir tu imagen; de esta forma, podrás reproducir en el futuro la creación de la imagen sin riesgo de que la imagen base haya variado.

## Compartir imágenes

El nombre de la imagen base debe ser único para cada usuario.

Para poder compartir una imagen en un repositorio como Docker Hub, cada usuario se identifica con un nombre de usuario. De esta forma, si dos usuarios tienen una imagen con el mismo nombre, no hay conflicto porque la imagen debe especificarse como `usuario1/myapp:v1` y `usuario2/myapp:v1`.

> Para subir una imagen local a un repositorio es obligatorio etiquetar la imagen con el nombre de usuario.

Los repositorios como Docker Hub permiten a los fabricantes/mantenedores de algunas imágenes muy populares publicarlas omitiendo el nombre de usuario; por ejemplo, la imagen *oficial* de [Nginx](https://hub.docker.com/search?q=nginx&type=image) se llama únicamente `nginx`. Otras imágenes -incluso del mismo usuario- como `nginx/nginx-ingress` sí que incorporan el nombre del mantenedor.

## Imágenes de diferentes repositorios

Docker Hub es el repositorio por defecto de Docker, pero existen otros repositorios de imágenes públicos como, por ejemplo, [Quay](https://quay.io).

Bitnami mantiene imágenes que distribuye en múltiples *registries*, como por ejemplo [`bitnami/nginx` en Docker Hub](https://hub.docker.com/r/bitnami/nginx) y [`bitnami/nginx` en Quay](https://quay.io/repository/bitnami/nginx).

Para distinguir estas dos imágenes, hay que inicluir el nombre del repositorio en el que se encuentra alojada la imagen:

- `bitnami/nginx` en Docker Hub (el cliente Docker *apunta* por defecto a Docker Hub)
- `quay.io/bitnami/nginx` en Quay

En general, el nombre **completo** de una imagen tiene la siguiente estructura `REGISTRY[:PORT]/USER/REPO[:TAG]`.

En `podman` se definen en el fichero `/etc/containers/registries.conf` los *registries* a los que consultar cuando la imagen solicitada no está cacheada en el sistema de ficheros local. En Docker la posición oficial (por ejemplo [#11815](https://github.com/moby/moby/issues/11815), [#33069](https://github.com/moby/moby/issues/33069), etc) parece ser la de evitar que se pueda modificar el *registry* por defecto.

## Usar imágenes de otros repositorios en los ficheros `Dockerfile`

Si has llegado hasta aquí, ya habrás intuído que lo único que hay que hacer para usar una imagen de un repositorio diferente a Docker Hub es especificar el **nombre completo** de la imagen en el `Dockerfile`.

Siguiendo con el ejemplo de la entrada anterior, si SUPERCORP Inc nos indica que debemos usar como imagen base [UBI](https://catalog.redhat.com/software/containers/ubi8/ubi-minimal/5c359a62bed8bd75a2c3fba8?container-tabs=gti&gti-tabs=unauthenticated) (*Universal Base Image* basada en Red Hat Enterprise Linux), modificamos el `Dockerfile`:

```Dockerfile
FROM golang:1.14.2-alpine AS builder
WORKDIR /src
COPY src .
RUN go build -o /out/helloworld .

FROM registry.access.redhat.com/ubi8/ubi-minimal:8.2 AS bin
COPY --from=builder /out/helloworld /
COPY compliance /compliance
CMD ["/helloworld"]
```

En este caso usamos el acceso a la imagen que no requiere autenticación (público). Para el resto de accesos, es necesario hacer pasos adicionales.

Construimos la imagen de la manera habitual:

```bash
docker build -t helloworld:multi-ubi8-v1.1 .
Sending build context to Docker daemon  7.168kB
Step 1/8 : FROM golang:1.14.2-alpine AS builder
 ---> dda4232b2bd5
Step 2/8 : WORKDIR /src
 ---> Using cache
 ---> 3e133d545734
Step 3/8 : COPY src .
 ---> Using cache
 ---> 9c877140ab21
Step 4/8 : RUN go build -o /out/helloworld .
 ---> Using cache
 ---> 06ca475ca0bc
Step 5/8 : FROM registry.access.redhat.com/ubi8/ubi-minimal:8.2 AS bin
 ---> 28095021e526
Step 6/8 : COPY --from=builder /out/helloworld /
 ---> cdb6a5778269
Step 7/8 : COPY compliance /compliance
 ---> 41a9145155b0
Step 8/8 : CMD ["/helloworld"]
 ---> Running in 0aa55f19d5e7
Removing intermediate container 0aa55f19d5e7
 ---> 22eadb871ff7
Successfully built 22eadb871ff7
Successfully tagged helloworld:multi-ubi8-v1.1
```

Y finalmente validamos que la aplicación sigue funcionando con normalidad:

```bash
$ docker run -it helloworld:multi-ubi8-v1.1
Hello World from Go!
```

Como ejercicio, podemos comparar el tamaño de todas las imágenes generadas en estas dos entradas:

```bash
$ docker images
REPOSITORY                                    TAG                 IMAGE ID            CREATED             SIZE
helloworld                                    multi-ubi8-v1.1     22eadb871ff7        28 seconds ago      144MB
helloworld                                    multi-alpine-v1.1   44253a0a8e89        2 hours ago         7.64MB
helloworld                                    multi               b23c0b2e9ca6        3 hours ago         2.07MB
registry.access.redhat.com/ubi8/ubi-minimal   8.2                 28095021e526        3 weeks ago         142MB
registry.access.redhat.com/ubi8/ubi-minimal   latest              28095021e526        3 weeks ago         142MB
alpine                                        3.12                a24bb4013296        3 months ago        5.57MB
golang                                        1.14.2-alpine       dda4232b2bd5        5 months ago        370MB
```
