+++
draft = false

categories = ["dev"]

tags = ["blog", "hugo", "theme"]

thumbnail = "images/MabelAmber-mini.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}

title=  "Caja de búsqueda en el site con DuckDuckGo"
date = "2019-09-12T20:38:01+02:00"
+++

Ayer volví a ver el vídeo [Implementing DNS via dnsmasq](https://www.youtube.com/watch?v=P2kiinwg00c) sobre **dnsmasq** y revisando el funcionamiento en una VM con Alpine que tengo en el equipo de laboratorio.

No recordaba si había escrito en el pasado sobre **dnsmasq** en el blog; creía que sí, pero no recordaba cuándo o qué había escrito. Usando la opción `site:https://onthedock.github.io/` en Google realicé una búsqueda sobre el blog y encontré varios artículos al respecto.

Hace un tiempo había considerado añadir una caja de búsqueda al _site_, pero recuerdo que tras buscar información sobre cómo incluir una caja de búsqueda de Google personalizada abandoné esta vía (No lo recuerdo con exactitud, pero _me parece_ que Google había dejado de ofrecer esta opción).

No recuerdo cómo exactamente, pero descubrí que [DuckDuckGo](https://duckduckgo.com), el navegador que respeta la privacidad, **si que ofrece esta opción**: [DuckDuckGo Search Box](https://duckduckgo.com/search_box).

Así que tras modificar ligeramente las plantillas, ¡ya está lista la caja de búsqueda en el blog!
<!--more-->

## Ubicando la caja de búsqueda en la plantilla

Inicialmente incorporé la caja de búsqueda bajo la cabecera del blog (el título y la _tagline_) en el fichero `/themes/aglaus-custom/layouts/_default/baseof.html`. Sin embargo esta opción no me convencía, ya que la caja de búsqueda se mostraba tanto en la página principal como en la página de cada artículo individual. Mi argumento contra esta opción es que una vez que estás leyendo el artículo, ya has encontrado lo que habías venido a buscar.

En la página principal has aterrizado y quizás no sepas cómo llegar a determinado contenido (como yo ayer con el tema de **dnsmasq**). En la página principal, por tanto, sí que tiene sentido que la caja de búsqueda esté al principio del contenido, bien visible para localizar lo que se busca.

Una vez has aterrizado en un artículo determinado, vas a leerlo (bueno, esa es la idea ;) ). En este caso, la caja de búsqueda, en mi opinión, tenía más sentido que estuviera **al final** del artículo. El _theme_ tiene una sección con botones para compartir el artículo en diversas redes sociales, así que la caja de búsqueda debería estar ahí.

La solución para que la caja de búsqueda se muestre en dos sitios diferentes es incluirla en dos ficheros del tema:

- `themes/aglaus-custom/layouts/_default/list.html` : La plantilla para la página principal.
- `themes/aglaus-custom/layouts/partials/share.html` : La plantilla de los botones para compartir en redes sociales.

Si revisas el _commit_[c80d55](https://github.com/onthedock/onthedock-hugo/commit/c80d554a6cf72af1ff5852b2ee6010a98378e12e) puedes ver exactamente dónde se ha insertado el código de la caja de búsqueda en cada fichero.

La inclusión del código proporcionado por DuckDuckGo para la caja de búsqueda quedaba alineado junto al borde izquierdo de la ventana y no centrado, como el resto del contenido.

## Algo de estilo

La solución fue crear un `div` con un estilo específico y aplicarlo para poder centrar la caja de búsqueda; nada espectacular:

```css
.searchbar{
  display: block;
  border: none;
  margin: 1em auto;
  max-width: 780px;
  text-align: center;
}
```

## Siguientes pasos

No soy muy fan de las redes sociales, así que nunca había prestado demasiada atención a los botones para compartir que venían por defecto en el tema para Hugo.

Ayer al modificar esta parte de la plantilla me fijé en que las redes sociales que aparecen tiene una fuerte influencia asíatica, sin duda, debido al origen de la creadora de la plantilla que usé como base. [Hatena](https://en.wikipedia.org/wiki/Hatena_(company)) es una empresa proveedora de servicios japonesa, [Line](https://en.wikipedia.org/wiki/Line_(software)), una aplicación de mensajería instantánea -como WhatsApp- con origen en Korea y que, según la Wikipedia, es la aplicación más popular en Japón. El resto son los "sospechosos habituales": Facebook, Twitter y Google+.

Sin embargo, [Google+ cerró para usuarios particulares el 2 de abril de 2019](https://en.wikipedia.org/wiki/Line_(software)]), por lo que no tiene demasiado sentido mantener el botón.

Como no realizo ningún _tracking_ en las redes sociales (ni sobre visitas en el blog) para saber si alguien comparte contenido o si el tráfico procede de estas redes sociales, no tengo claro si la eliminación de estos botones tendrá algún impacto.

Así que los mantendré por si alguien va compartiendo como loco el contenido del blog en Hathena con sus amigos ;)
