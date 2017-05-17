+++
title = "Tags, categorias y organización en Hugo"
draft = false
thumbnail = "images/hugo.png"
categories = ["dev"]
tags = ["hugo"]
date = "2017-05-06T06:23:50+02:00"

+++

A medida que aumenta el número de artículos me he dado cuenta de que es necesario tener algún conjunto de reglas para organizar los ficheros que componen el blog.

El problema no está en los ficheros de Hugo, sino en los ficheros generados por mi: artículos, imágenes, etc.
<!--more-->

Hugo genera sitios web a partir de un conjunto de ficheros organizados en carpetas: el contenido se encuentra en `$HUGO/content`, las imágenes en `$HUGO/static/images` (o dentro de la carpeta equivalente del _theme_).

Con unos pocos artículos, es fácil identificar qué fichero corresponde a un artículo concreto (simplemente a partir del título). Pero cuando el número de ficheros aumenta, la cosa se complica; el sistama operativo ordena los ficheros por orden alfabético, mientras que en el blog están organizados por fecha de creación. Para complicar más las cosas, el nombre del fichero _puede_ no ser el mismo que el título del artículo.

Pasa algo parecido con las imágenes; con unas pocas no hay problema, pero cuando tenga un montón, será complicado identificar qué imagen corresponde a cada artículo. 

Para evitar complicaciones, creo que lo mejor es definir unas reglas sobre cómo organizar el contenido y definir _consistentemente_ etiquetas, categorías, etc.

## Categorías

El blog está orientado al _DIY tecnológico_ en el aprendizaje sobre contenedores y tecnologías relacionadas.

En este sentido, para simplificar, he decidido limitarme a dos categorías básicas `Dev` y `Ops`.

De momento estoy montando el clúster de Kubernetes, realizando troubleshooting, etc, por lo que la mayoría de artículos son de la categoría `Ops`.

Cuando tenga el clúster montado y pueda crear _pods_ (_replication controllers_, etc), empezaré con la parte más `Dev`; de momento, los únicos artículos `Dev` son los relacionados con Hugo, su configuración, etc.

## Etiquetas

El objetivo de las etiquetas es permitir organizar de forma flexible los artículos en conjuntos relacionados. Esta flexibilidad puede degenerar rápidamente en un montón de etiquetas que se usan sólo una vez y que no aportan nada.

Para evitar definir un conjunto de etiquetas estricto -y perder flexibilidad- he pensado que lo mejor es definir unas _reglas_ sobre qué etiquetas son necesarias en cada artículo.

Ya he utilizado este sistema en otra ocasión y ha funcionado mucho mejor que otras alternativas que intenté en el pasado.

La primera etiqueta se refiere a la arquitectura; puede ser `x64` o `arm`, básicamente. En el primer caso entran tanto equipos físicos como máquinas virtuales; en este caso, no uso ninguna etiqueta concreta (esta es la arquitectura _default_ para contenedores).

En el segundo tenemos las Raspberry Pi, para las que uso la etiqueta `RASPBERRY PI`, aunque igual me planteo usar `ARM` (o las dos). Esto es porque no descarto _ampliar la familia_ e incorporar alguna Orange Pi al clúster.

El siguiente nivel sería identificar el sistema operativo: hasta ahora sólo estoy usando Debian (en máquinas virtuales) o Hypriot OS (en las Raspberry Pi). Si en algún momento empiezo a probar contenedores sobre Windows, sólo tengo que añadir esta etiqueta.

Por encima del sistema operativo tendría la capa de producto: Docker o Kubernetes, por el momento. También  Hugo, por ejemplo, aunque no sea el objetivo principal del blog.

Finalmente, alguna etiqueta específica sobre el tema del artículo.

Creo que esta organización de etiquetas permite identificar todo el _stack_ usado y así distinguir, especialmente pasado un tiempo, qué componentes estaba usando en cada momento (aunque no se expliciten en el artículo).

Sería interesante poder incluir el número de versión de _cada capa_ (RPi 1,2,3, versión del SO, de Docker y Kubernetes...) pero no se me ocurre cómo hacerlo de manera que sea a la vez útil para agrupar artículos y sin provocar _ruido_ (mogollón de etiquetas similares, como con `raspberry pi`, `raspberry pi 2` para poder agrupar por RPi, pero también sobre sólo los artículos sobre RPi2 y no los RPi 3, por ejemplo).

## Fecha en el nombre de fichero

Para que los ficheros se muestren en un orden similar en el blog y en el sistema de ficheros del portátil, el truco es sencillo: los prefijo con la fecha: `yymmdd-nombre-articulo.md`.

No es habitual que escriba varios artículos el mismo día, pero incluso cuando lo hago, diferenciar entre dos o tres artículos no supone un problema.

```txt
$ ls -la content/post/
...
2.6K Apr 30 15:18 170430-k3-colgado-de-nuevo.md
3.5K Apr 30 12:23 170430-multiples-mensajes-action-17-suspended.md
 12K May  6 05:23 170430-troubleshooting-kubernetes-i.md
6.1K May  5 22:51 170505-instala-weave-net-en-kubernetes-1.6.md
4.6K May  6 08:33 170506-tags-categorias-archetypes-en-hugo.md
6.0K May  6 06:11 170506-troubleshooting-kubernetes-ii.md
```

En cuanto al nombre del fichero, uso el guión `-` como sustituyo del espacio en el nombre del fichero. Si cambio el título del artículo, renombro el fichero para que **siempre** el nombre del fichero y el artículo coincidan el máximo posible. 

## Agrupar imágenes

Al estar conectado por consola a las máquinas virtuales o las Raspberry Pi, no suelo hacer muchas capturas de pantalla.

En un blog o un wiki, la propia plataforma se encarga de gestionar las imágenes y nunca he tenido problema porque dos imágenes tuvieran el mismo nombre. La inclusión de la imagen en el artículo se realiza de forma gráfica, por lo que el nombre de la imagen tampoco era importante.

Sin embargo, al escribir los artículos en markdown y tener que enlazar las imágenes manualmente, el nombre del fichero de la imagen **es relevante**.

He decidido crear una carpeta para evitar problemas de _colisión de nombres_ y tener organizadas todas las imágenes de un mismo artículo. El nombre de la carpeta corresponde a la fecha del artículo (de nuevo, en formato `yymmdd`). Dentro de cada carpeta las imágenes se llaman como se tengan que llamar (de manera que tengan un nombre descriptivo) pero sin preocuparme de si ya existe otra imagen con el mismo nombre de fichero.

