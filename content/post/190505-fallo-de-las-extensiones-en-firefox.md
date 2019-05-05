+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["ops"]
tags = ["firefox"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/bug.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})
# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}

title=  "Fallo en las extensiones de Firefox"
date = "2019-05-05T18:50:31+02:00"
+++
Ayer noté que veía muchos anuncios en las páginas que suelo visitar. Revisando las opciones de Firefox, observé que se había deshabilitado la extensión de bloqueo de anuncios "al no poder _verificarse_": `One or more installed add-ons cannot be verified and have been disabled`.

Imaginé algún cambio en la normativa de extensiones de Firefox -similar a lo que pasó con Safari hace un tiempo- y no le di mayor importancia.

Me dirigí a la "tienda" oficial de Mozilla para descargar alguna extensión alternativa y pronto descubrí que el problema era mucho peor de lo que había imaginado.
<!--more-->

Tras intentar instalar una extensión similar de bloqueo de anuncios, encontré problemas para descargar la extensión. Probé con otra y obtuve el mismo error.

Después de reiniciar el navegador -y el portátil- decidí investigar en internet y dí con la página 
[Your Firefox extensions are all disabled? That's a bug!](https://www.ghacks.net/2019/05/04/your-firefox-extensions-are-all-disabled-thats-a-bug/).

La página indica que el problema con las extensiones lo ha causado un _bug_ que impide comprobar la firma -obligatoria desde Firefox 48- y que hace que ninguna extensión pueda verificarse.

No hay solución por el momento (hasta que Firefox consiga arreglar el fallo).

## Los anuncios son el virus que invade internet

Llevo tanto tiempo navegando con un bloqueador de anuncios que no me había dado cuenta de lo incómodo que es navegar por internet sin ellos.

De hecho, tras el cambio en la forma de gestionar los bloqueadores de anuncios en Safari (sobre lo que puedes leer más detalles en [What's different in the AdBlock for Safari extension after the September 2018 update?](https://help.getadblock.com/support/solutions/articles/6000202459-what-s-different-in-the-adblock-for-safari-extension-after-the-september-2018-update-)
), cambié de navegador por defecto en el Mac, pasando de Safari a Firefox.

Entonces tenía una alternativa, pero ahora con el fallo de la verificación de la firma de extensiones en Firefox, sólo me queda Chrome (que intento evitar todo lo que puedo desde hace un tiempo por otros motivos...)

Anuncios que sólo puedo saltar tras cinco segundo de _peaje visual_ en YouTube (incluso uno que ha interrumpido un vídeo sobre dnsmasq!!), anuncios entre párrafo y párrafo de un texto, además de los que plagan la barra lateral, anuncions flotantes con vídeos que se autoreproducen...
Es como si de pronto, las prácticas que hace un tiempo estaban restringidas a las páginas más "turbias" de internet -y con una búsqueda de rendimiento económico más agresiva- se hubiera adueñado del resto de la red.

Los "creadores de contenido" usan el argumento de que necesitan los ingresos de los anuncios para poder seguir creando contenido... Pero las plataformas -como YouTube, Wordpress, Medium- también quieren cobrar por la plataforma en sí...
Es decir, que según ese planteamiento unilateral yo como consumidor debería pagar a YouTube, a Medium, a Wordpres una primera cuota "de acceso" y después una "cuota adicional" para poder financiar al creador de contenidos...

Desde mi punto de vista esta estrategia es inviable para el consumidor; si tengo que invertir dinero, prefiero financiar al creador de un **adblocker eficaz** que no tener que pagar cuotas en cada uno de los sitios que quiero visitar.

El micromecenazgo -vía Patreon o similares- permite a los creadores de contenido obtener vías de financiación viables sin tener que penalizar a los visitantes ocasionales que llegan a su blog a través de una búsqueda en Google o un enlace en algún otro medio.

En cuanto a las plataformas, deben ser capaces de mantenerse usando modelos _freemium_ que les permitan ofrecer contenido gratuito -si lo desean- sin agredir al visitante a base de anuncios indiscriminados.

Internet es una relación simbiótica entre creadores de contenido y plataformas por un lado y los visitantes (internautas) por otros; sin cualquiera de ellos, deja de tener sentido y ambas partes deben reconocerse como iguales.


