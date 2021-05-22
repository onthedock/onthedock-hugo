+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["hugo"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/hugo.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}

title=  "Hugo: plantilla del tema actualizada"
date = "2019-03-08T21:13:04+01:00"
+++

Cada cierto tiempo instalo la última versión de Hugo, el _motor_ que convierte contenido estático -en formato markdown- a las páginas HTML que estás leyendo ahora mismo. Sin embargo, al actualizar a la versión `v0.54.0-B1A82C61 darwin/amd64`, obtuve múltiples mensajes de error que me impedían _construir_ el sitio web y por tanto, no podía generar nuevas versiones del _site_.
<!--more-->

Los errores que obtenía eran de la forma (lo he formateado para que se muestre en múltiples líneas):

```bash
Building sites … ERROR 2019/03/08 21:06:48 render of "page" failed:
"[...]/themes/aglaus-custom/layouts/_default/baseof.html:19:84":
execute of template failed: template: _default/single.html:19:84:
executing "_default/single.html" at <.Source.Path>:
can't evaluate field Source in type *hugolib.Page
...
```

En la [documentación oficial](https://gohugo.io/variables/files/) no se habla de la variable `.Source.Path`, sino de `File.Path`. He realizado una prueba, modificando esta variable en el fichero de la plantilla indicado y _voilà!_, un error menos.

He repetido la sustitución en el resto de ficheros para los que aparecía el error y he conseguido generar el site de nuevo.

Buscando en Google he encontrado la raíz del problema: `.Source` fue eliminado en la versión `0.50`: [Hugo theme stopped working with hugo 0.50: how to fix it?](https://discourse.gohugo.io/t/hugo-theme-stopped-working-with-hugo-0-50-how-to-fix-it/15051)

¡Misterio resuelto!
