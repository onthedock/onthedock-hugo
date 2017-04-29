+++
title = "Agregar nueva entrada con Hugo"
thumbnail = "images/hugo.png"
categories = ["dev"]
tags = ["Hugo"]
date = "2017-04-01T22:36:46+02:00"

+++

Cómo publicar una entrada usando Hugo, el generador de sitios estáticos, desde la creación del _site_ hasta la subida de los ficheros en el servidor web. 

<!--more-->

## Algunas consideraciones previas

En primer lugar, es importante que Hugo esté correctamente configurado. Asegúrate de que todos los pequeños detalles estén controlados -como que en el parámetro `baseURL` se incluya la `/` final- y te evitarás un montón de problemas.

Si haces pruebas en un entorno de integración o consolidación, el único parámetro que hay que modificar al pasar a producción es la `baseURL`.

Para evitar confusiones, en esta entrada a la ruta al ejecutable de Hugo la llamo `$HUGO/hugo`. El servidor web publica la web desde la carpeta `~/web`. Supongo que la ruta a `hugo` se encuentra en el `$PATH` de tu equipo, por lo que puedes ejecutarlo lanzando `hugo` sin necesidad de especificar la ruta al comando.

## Crea del sitio

El primer paso para crear un sitio con Hugo es crear una carpeta llamada y lanzar el comando `hugo new site`:

```shell
$ mkdir mi-sitio-web
$ cd mi-sitio-web
$ hugo new site mi-sitio-web
```

A continuación, elige un tema (o crea el tuyo propio con `hugo new theme`).

Configura los parámetros usados en el tema que hayas escogido en el fichero `$HUGO/config.toml` y ¡listo!.

{{% img src="images/170401/hugo-publicacion-01.png" h="412" %}}

## Crea una entrada

Para crear una entrada, lanza el comando `hugo new post/nombre-entrada.md`.

```shell
$ cd mi-sitio-web
$ hugo new post/mi-primera-entrada.md
```

Esta acción crea el fichero `$HUGO/content/post/nueva-entrada.md`.

{{% img src="images/170401/hugo-publicacion-02.png" h="256" %}}

## Edita la entrada

Abre el fichero de la nueva entrada. Encontrarás algo como:

```
+++
title = "mi primera entrada"
thumbnail = "images/thumbnail.png"
categories = [""]
tags = [""]
date = "2017-04-01T22:36:46+02:00"

+++

```

El contenido de cualquier entrada está compuesto por el _frontmatter_ (_metadata_ sobre la entrada) y el contenido de la entrada en sí: cualquier cosa a partir del bloque delimitado por `+++`. El contenido _por defecto_ proviene del contenido de la carpeta `$HUGO/theme/{tema-usado}/archetypes/default.md` (el contenido varía según el autor de cada tema).

Al crear la entrada, además de la información copiada desde el _archetype_ Hugo añade siempre el título (por defecto, igual que el nombre del fichero) y la fecha.

Ya puedes escribir tu entrada en cualquier editor de texto. Para dar formato al texto -negritas, cursivas-, crear enlaces, insertar imágenes, etc, se usa el [markdown](https://es.wikipedia.org/wiki/Markdown).

Para tener una idea de cómo va quedando la entrada, puedes usar `hugo server watch`. Hugo incorpora un pequeño servidor web con el que puedes visualizar tu blog en modo _borrador_, por llamarlo de algún modo. La opción `watch` hace que Hugo regenere automáticamente el blog en cuanto detecte algún cambio. De esta manera puedes ir visualizando cómo queda la entrada antes de publicarla.

## Publica la entrada

Una vez que satisfecho con la entrada, hay que generar los ficheros que componen el blog.

El blog es un conjunto de ficheros html, javascript y css en la carpeta `$HUGO/public`. Para evitar que se mezclen ficheros de "publicaciones" anteriores, es recomendable borrar la carpeta antes de generar una nueva versión del blog.

Para crear estos ficheros a partir de tus entradas y el tema que has escogido, simplemente lanza el comando `hugo`.

Hugo hace su magia y genera todos los ficheros necesarios, analizando el contenido de los ficheros. Estos ficheros se generan en la carpeta $HUGO/public`.

{{% img src="images/170401/hugo-publicacion-03.png" h="428" %}}

## Sube los ficheros al servidor web

El siguiente paso es subir el contenido de la carpeta al servidor web.

Para evitar que se mezclen los ficheros actuales y los nuevos, primero elimina el contenido de la carpeta del servidor.

Mi servidor web es una Raspberry Pi B+, así que me conecto vía SSH y elimino el contenido de la carpeta `~/web`:

```shell
$ ssh pirate@rpi.local
pirate@rpi.local: ~ $ cd web
pirate@rpi.local: ~/web $ rm -rf *
```

Después, copio el contendio de `$HUGO/public` a `~/web` en el servidor remoto:

```shell
$ cd $HUGO/public
$ scp -r * pirate@rpi.local:/home/pirate/web
```
{{% img src="images/170401/hugo-publicacion-04.png" h="428" %}}

Desde un navegador, comprueba que el blog se ha actualizado con la nueva entrada.

Puedes descargar la referencia para todo el proceso: [Publicación en Hugo: Referencia](../../images/170401/hugo-publicacion-paso-a-paso.png)





