+++
thumbnail = "images/hugo.png"
categories = ["dev","ops"]
tags = ["hugo"]
date = "2017-04-01T18:10:12+02:00"
title = "De Blogger a Hugo"

+++

Porqué me estoy planteando dejar Blogger y pasar a un sitio estático gracias a Hugo.

Hugo es un _generador de sitios estáticos_ a partir de ficheros en formato _markdown_. Hugo aplica una plantilla al contenido de los ficheros en formato _markdon_ y crea los ficheros HTML.

<!--more-->

## Motivación

Aunque llevo _toda la vida_ con un blog personal en [Blogger](https://www.blogger.com/), Google ha desatendido la plataforma y poco a poco se ha ido quedando atrás en prestaciones.

[Ghost](https://ghost.org) es la platforma que cada vez más desarrolladores y escritores _técnicos_ usan, tanto en la versión alojada como en sus propias instalaciones. Es la que me gustaría usar para mis blogs: soporta _markdown_ y no se entromete en el proceso ni de escribir ni de publicar los artículos.

Mi objetivo era ejecutar Ghost en la Raspberry Pi, pero al no existir soporte de SQLite para la arquitectura ARM, las imágenes para [_contenedores_ Docker](https://github.com/alexellis/ghost-on-docker) están desactualizadas y no siempre son fáciles de _construir_.

Por otro lado, el objetivo del blog en la Raspberry Pi es documentar el proceso de aprendizaje sobre  Docker y Kubernetes (además de Linux). A diferencia de lo que pasaba en mi anterior trabajo, donde estuve usando Hugo de forma _experimental_, ahora estas notas no contienen ningún tipo de información privada, por lo que publicaré también los artículos en internet.

En mis pruebas Hugo se integró en el flujo de trabajo diario sin interferir lo más mínimo, por lo que resultó una experiencia muy positiva.  

Quiero combinar este blog (orientado al avance, a las pruebas, es decir, al proceso) con Dokuwiki (como almacén de conocimiento y documentación). Sin embargo, con Dokuwiki la  _dualidad_ entre en entorno _local_ (en casa) y en internet es más difícil de conseguir de forma directa (usando recursos gratuitos). Tengo un [contenedor en OpenShift](http://wiki-ameisin.rhcloud.com/) con notas sobre diferentes temas, pero en esta instancia de Dokuwiki en OpenShift las carpetas de datos tienen una estructura diferente a la estándar, lo que dificulta mantener _sincronizadas_ la versión _local_ y la alojada en el _cloud_ de Red Hat.

## Hugo

La idea detrás de un generador de sitios estáticos es que, en muchas ocasiones, no es necesario disponer de toda la potencia que ofrecen las plataformas de _blogging_ modernas como [Wordpress](https://wordpress.org), etc. Además, estas plataformas no son siempre fáciles de instalar, configurar y mantener en tu propio entorno local.

La alternativa es mantener un sitio web a partir de ficheros HTML independientes, pero resulta muy costoso en tiempo y esfuerzo.

A medio camino se encuentran los generadores de sitios como [Jekill](https://jekyllrb.com) o [Hugo](https://gohugo.io).

Estos _generadores de sitios estáticos_ parten de ficheros en formato _markdown_ -que son sencillos de escribir- y se encargan de combinarlos con unas plantillas, generar los enlaces entre los diferentes artículos, crear nubes de etiquetas, etc (la parte tediosa) hasta generar los ficheros HTML.

Al final del proceso, tenemos un conjunto de ficheros _web_ (HTML, javascript, css) que podemos alojar en cualquier servidor (o en servicios como [GitHub Pages](https://pages.github.com) o [Bitbucket](https://confluence.atlassian.com/bitbucket/publishing-a-website-on-bitbucket-cloud-221449776.html)).

## Siguientes pasos

En estas fase inicial, únicamente tengo un contenedor con un servidor web (Nginx) sirviendo el sitio estático generado por Hugo (en un portátil).

Más adelante quiero incluir también un contenedor con Hugo (como el proporcionado por [Hypriot](https://hub.docker.com/r/hypriot/rpi-hugo/)) e ir añadiendo poco a poco todas las herramientas del proceso de Integración Continua -en forma de contenedores- desde el _código fuente_ al sitio web publicado automáticamente con cada cambio. Como se apunta en la entrada [Static Website Generation on Steriods with Docker](https://blog.hypriot.com/post/static-website-generation-on-steriods-with-docker/), la idea es montar una cadena de [CI](https://es.wikipedia.org/wiki/Integración_continua): GoGS (repositorio de código _a lo Github_), [Drone](https://github.com/drone/drone) (el _motor_ de Integración Continua: como [Jenkins](https://es.wikipedia.org/wiki/Jenkins), pero escrito en Go) y para el _deployment_, una mezcla de [Nginx](https://hub.docker.com/r/xaviaznar/rpi-alpine-nginx/) (publicación local) y [Bitbucket](https://bitbucket.org/product) (publicación en internet).
