+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["hugo", "blog"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/hugo.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}

title=  "Hugo: Sustituir shortcode img por figure"
date = "2021-05-22T20:56:07+02:00"
+++
En la entrada anterior [No se muestran imágenes en el blog]({{< ref "210522-bug-no-se-muestran-imagenes-en-el-blog.md" >}}) comentaba cómo un cambio en la configuración de Hugo (en la versión 0.60.x) estaba haciendo que no se mostraran las imágenes en los artículos del blog.

En esta entrada comento los pasos que he seguido para actualizar **todos** los artículos con imágenes así como qué otras opciones he estado revisando.
<!--more-->

## *Search and replace*

**TL;DR;** He usado la función de *buscar y reemplazar* de *VS Code* para modificar todas las referencias al *shortcode* `img`, proporcionado por la plantilla del tema *Aglaus* y lo he sustituido por el *shortcode* nativo de Hugo [`figure`](https://gohugo.io/content-management/shortcodes/#figure).

VS Code proporciona la posibilidad de buscar y reemplazar en todos los ficheros de una carpeta. Como el *shortcode* era "&#123;&#123;&#37; img src="ruta/a/la/imagen.png" &#37;&#125;&#125;", he buscado primero la parte inicial de la cadena y la he sustituido por "&#123;&#123; figure src=\"/".

Además de modificar el código del *shortcode* (de `img` a `figure`), también es necesario que la ruta de a la imagen sea absoluta (anteriormente era relativo). Por eso incluyo en la cadena de reemplazo la `/` tras `src=`.

Tras finalizar la modificación de la parte inicial del *shortcode*, queda reemplazar la parte final: `" %}}` por `>}}`. He seguido el mismo procedimiento de *buscar y reemplazar* masivo.

> Como nota curiosa que he descubierto haciendo el *search and replace* es que, por algún motivo, en una de las entradas había dos espacios entre las comillas y el delimitador del *shortcode* (`"  %}}`) y no se ha realizado la sustitución :(

Una vez he validado que las imágenes se muestran correctamente (seleccionando algunas entradas con imágenes al azar), he eliminado el *snippet* del *shortcode* `img` de la carpeta `themes/aglaus-custom/layouts/shortcodes`.

Tras un merge que me ha dado más problemas de los que esperaba, he subido los cambios GitHub Pages y ahora el problema está resuelto.

Puedes comprobarlo en la última entrada que publiqué con una imagen: [Modificar el rango del DHCP de Virtualbox]({{< ref "200725-modificar-rango-dhcp-virtualbox.md" >}}) (de Julio del 2020). Verás que la imagen tiene un tamaño incorrecto, ya que el nuevo *shortcode* no utiliza los mismos parámetros que el *shortcode* anterior :(

## Mirando al futuro

A corto plazo, seguiré con el *buscar y reemplazar* para cambiar los parámetros y arreglar el tema del tamaño de las imágenes insertadas... Pero el futuro pasará, seguramente, por replantear seguir usando un *theme* que no recibe soporte.
