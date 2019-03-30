+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["documentacion", "markdown", "asciidoc"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/asciidoctor.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" %}}

title=  "Documentación"
date = "2019-03-30T21:23:15+01:00"
+++
Debido a un inminente cambio en mi carrera profesional tengo que planificar el traspaso de las tareas que realizo a la persona que ocupe mi posición y que -cosas de los procesos de contratación- todavía no se ha incorporado (ni sabemos cuándo lo hará). Aunque cambio de departamento en la organización (es decir, no dejo la empresa), esta situación me ha llevado a reflexionar sobre todas esas cosas que hacemos en el día a día y que no están documentadas en ningún sitio.
<!--more-->

# Buscando una solución

He estado pensando  en cómo documentar todas esas tareas que realizo en mi puesto de trabajo y cómo, desde hace ya un tiempo, uso Markdown para redactar la documentación -en el ámbito personal- que genero (como este blog). Es un formato sencillo, que se aprende sin esfuerzo pero que tiene algunos _puntos oscuros_ como la falta de un estándar, lo que provoca que, en cuanto te desvías de los casos de uso sencillos, cada herramienta procese las marcas de manera diferente. Hay argumentaciones mucho más elaboradas describiendo con detalles otros problemas que presenta Markdown, como [Why You Shouldn’t Use “Markdown” for Documentation](https://www.ericholscher.com/blog/2016/mar/15/dont-use-markdown-for-technical-docs/).

Aunque la flexibilidad y _ligereza_ de Markdown supera con creces los problemas que presenta en determinadas situaciones, a nivel profesional es difícil defender el uso de un formato que no produce resultados consistentes.

A partir de un _badge_ en la parte inferior de la [página de documentación de OKD](https://docs.okd.io/latest/welcome/index.html) he descubierto AsciiDoc (en realdad, [AsciiBinder](http://asciibinder.org/), que está a punto de desaparecer).

AsciiDoc es algo así como _lo que Markdown querría ser de mayor_. Al igual de Markdown, AsciiDoc es un lenguaje de marcado ligero ["semánticamente equivalente a DocBook XML, aunque usando convenciones basadas en texto plano"](https://en.wikipedia.org/wiki/AsciiDoc). Al igual que Markdown, puede ser leído por humanos _tal cual_ o se puede transformar en otros formatos como HTML, PDF, epub, etc.

A diferencia de Markdown, AsciiDoc fue creado desde el principio con una clara orientación a la publicación del contenido, de manera que sigue unas convenciones fijas, es extensible y, en la mayor parte de los casos, usa incluso menos _marcas_ que el mismo texto formateado de forma equivalente con Markdown.

Pese a todo, AsciiDoc no es tan popular como Markdown y hay muchas menos herramientas que lo soportan directamente.

## Soporte de AsciiDoc: herramientas

Tanto AsciiDoc como Markdown son lenguajes de marcado basados en texto plano, por lo que se puede generar un documento de cualquiera de los dos tipos usando un simple editor de texto. En general, resulta más sencillo _ver_ el resultado del formateado del texto de forma visual (en vez de tener que imaginarlo).

Si para Markdown tenemos editores de texto como [Typora](https://typora.io/), [Marktext](https://marktext.github.io/website/) o plugins de _previsualización_ para prácticamente cualquier editor como Visual Code, Brackets, Atom, etc, el soporte para AsciiDoc no está tan extendido.

En cuanto a herramientas dedicadas, la más popular es [AsciiDocFX](https://www.asciidocfx.com/), de código abierto y multiplataforma.

### Sistemas de control de versiones

Disponer de documentación en texto plano permite aprovechar los sistemas de control de versiones donde guardamos el código de la infraestructura (IaC) junto con los ficheros de su documentación.

AsciiDoc permite incluir otros ficheros -o parte de ellos- en el documento; de esta forma, al actualizar el código _incrustado_, la documentación se actualiza automáticamente, sin necesidad de copiar y pegar la nueva versión del código en el fichero de documentación.

El hecho de poder generar la documentación en diferentes formatos encaja con la filosofía _devops_ y lo que podríamos llamar *documentación como código*: a partir del código fuente -la documentación en texto plano- es posible compilarla y generar un artefacto final "ejecutable" (¿_leíble_?) en PDF o HTML de forma dinámica, con cada cambio.

## Soporte para AsciiDoc: sistemas de control de versiones

Github soporta AsciiDoc en los ficheros subidos -como el típico `README`-, visualizando los ficheros `.adoc` ya formateados. También soporta este formato para generar las páginas del Wiki, pero **no permite habilitar Wikis en repositorios privados** :(

[Bitbucket no soporta AsciiDoc](https://jira.atlassian.com/browse/BSERV-4769) ni parece que haya planes para soportarlo de forma nativa (la petición se abrió en 2014!), ni en los documentos tipo `README` ni como formato para el Wiki. Sí que soporta otros formatos _alternativos_ a Markdown como [ReStucturedText](https://es.wikipedia.org/wiki/ReStructuredText).

# Siguientes pasos

Después de haber revisado las ventajas de AsciiDoc con respecto a Markdown, el siguiente paso es presentar una propuesta algo elaborada con las ventajas de usar un sistema de documentación _dinámico_ que pueda seguir el ritmo de las actualizaciones de código generado de forma **Agile**.

Idealmente, me gustaría disponer de un [contenedor](https://hub.docker.com/r/asciidoctor/docker-asciidoctor/) con AsciiDoctor que permita generar una versión de PDF y en ePub a partir de un documento formateado (de momento, lanzado manualmente o a través de un script). En una futura versión el PDF/ePub se generaría como respuesta a una actualización de la documentación o del código en GitHub de forma automática.

Se avecinan tiempos interesantes...