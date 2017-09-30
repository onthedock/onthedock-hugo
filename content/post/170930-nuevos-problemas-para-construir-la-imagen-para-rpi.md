+++
draft = false

# TAGS
# HW->OS->PRODUCT->specific tag
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["raspberry pi", "linux", "docker"]

# CATEGORIES = "dev" / "ops"
categories = ["dev"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/docker.png"

# SHORTCODES (for reference)

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

title=  "Nuevos problemas al construir la imagen con Caddy y PHP, ahora para Raspberry Pi"
date = "2017-09-30T17:30:45+02:00"
+++

En la entrada anterior [Dokuwiki en un contendor]({{< ref "170924-dokuwiki_en_un_contenedor_notas.md">}}) dejaba constancia de los problemas que encontré creando una imagen para ejecutar Dokuwiki en un contenedor.

Al final de la entrada indicaba que la creación de la misma imagen, pero para ARM sería tan sencillo como cambiar la imagen base. **Pues no.**

Como he tenido que revisar a fondo los pasos que seguí -en particular para configurar la carpeta desde donde Caddy publica los ficheros-, he introducido algunos cambios que simplifiquen y mejoren el uso de la imagen.

<!--more-->

## Imagen base

Lo que originalmente debía ser tan sencillo como un cambio de imagen base, no ha funcionado a la primera.

La imagen base que pensaba utilizar era [xaviaznar/rpi-alpine-base](https://hub.docker.com/r/xaviaznar/rpi-alpine-base/). Esta imagen está basada en [hypriot/rpi-alpine-scratch](https://hub.docker.com/r/hypriot/rpi-alpine-scratch/), pero resulta que esta imagen no se actualiza desde hace más de un año:

{{% img src="images/170930/alpine-scratch.png" %}}

Así que los paquetes de PHP 7 no estaban todavía incluidos en los repositorios y la construcción de la imagen ha fallado.

Afortunadamente existen una imagenes _semi-oficiales_ para ARM de la mano de [arm32v6](https://hub.docker.com/u/arm32v6/) (para Raspberry Pi "1") y [arm32v7](https://hub.docker.com/u/arm32v7/) (para las Raspberry 2 y 3).

Así que para la RPi 1, he usado como base [arm32v6/alpine](https://hub.docker.com/r/arm32v6/alpine/).

La dependencia de imágenes base de terceros es uno de los problemas que hay que tener en cuenta en el diseño de los contenedores. Esto es especialmente sensible para equipos ARM para los cuales todavía no hay siempre una imagen oficial del desarrollador del producto y se depende de imágenes creadas por voluntarios.

## Rutas (de nuevo)

En la entrada anterior los ficheros del wiki se encontraba en la carpeta `~/dokuwiki`, por lo que [montaba el volumen en comando `docker run`](https://github.com/onthedock/alpine-caddy-php/blob/master/runWiki.sh) el volumen mediante `-v /home/operador/dokuwiki:/var/www`. En el fichero `Caddyfile` sin embargo, la raíz de las carpetas publicadas por Caddy `root /var/www/wiki`.

Es decir, en el sistema de ficheros locales tenía `~/dokuwiki/wiki/{ficheros php}`, pero debido a la similitud de los nombres, pensaba que tenía `~/dokuwiki/{ficheros php}`, por lo que he estado un buen rato intentando averiguar el porqué de los errores 404 que mostraba el navegador, los logs, etc.

Para evitar este tipo de errores en el futuro, la raíz de las carpetas públicas en Caddy será siempre `/var/www`. Los ficheros _locales_ siempre estarán en una carpeta llamada `www`, que será la que se monte sobre ésta carpeta del contenedor.

Otro punto que hay que tener en cuenta es que el contenido de la carpeta del contenedor sobre la que se monta la carpeta del _host_ no se fusiona con el contenido de ésta: sólo son visibles los ficheros de la carpeta del _host_ montada en el contenedor.

En mi caso, por ejemplo, al construir la imagen se copian los ficheros `index.htm` y `phpinfo.php` en `/var/www`. Pero cuando se monta la carpeta `~/wiki` en `/var/wwww`, sólo aparecen los ficheros presentes en `~/wiki`. Los ficheros `index.php` y `phpinfo.php` sólo son _visibles_ si no se monta un volumen en el contenedor.

## Volúmenes compartidos entre el host y el contenedor

Para simplificar la organización de las carpetas montadas en los contenedores, he creado una carpeta llamada `/shared`, en la raíz del árbol de carpetas. Dentro de esta carpeta habrá una carpeta para cada contenedor que tenga un volumen local montado.

Para el caso anterior, si el contenedor tiene por nombre `wiki`, cada uno de los volúmenes montados será una subcarpeta de ésta.

Un ejemplo:

```txt
/shared/
├── wiki/
│   ├── www/
│   └── logs/
├── otro_contenedor/
│   ├── foo/
│   └── bar/
```

Este cambio hace que tenga que modificar todos los _lanzadores_ -como el `runWiki.sh`-, aunque es un problema menor; una vez que el contenedor se ha lanzado, se puede gestionar el arranque y la parada mediante `docker start/stop $NOMBRE_CONTENEDOR`.

## Siguientes pasos

Una vez he resuelto todos los problemas que han ido apareciendo en esta fase de desarrollo, el siguiente paso es documentar todos los pasos -correctos- que hay que dar para obtener tanto la imagen con Caddy y PHP como para usarla en un contenedor sirviendo una aplicación web en PHP.
