+++
draft = false

categories = ["dev"]
tags = ["hugo", "blog", "theme"]
thumbnail = "images/hugo.png"

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}


title=  "Cambios en el blog"
date = "2019-04-19T06:22:57+02:00"
+++

Hugo sigue evolucinando y eso significa que cada nueva versión introduce pequeñas modificaciones y mejoras que no siempre son _retrocompatibles_.

En mi caso, al actualizar a la versión 0.54 encontré problemas a la hora de construir el blog. En la entrada [Hugo: plantilla del tema actualizada]({{< ref "190308-plantilla-actualizada" >}}) explico cómo solucioné los errores que impedían generar el blog.
<!--more-->
Hace unos días actualicé a la versión `v0.55.2-9D020348`. Al generar el blog con esta versión obtengo varios avisos de funciones usadas por el tema _Aglaus_ que son **desaconsejadas** (_deprecated_) y que se eliminarán en futuras versiones de Hugo.

He conseguido solucionar todos los _warnings_ excepto:

```bash
Building sites … WARN 2019/04/19 Page's .Hugo is deprecated and will be removed in a future release. Use the global hugo function.
WARN 2019/04/19 .File.Path on zero object. Wrap it in if or with: {{ with .File }}{{ .Path }}{{ end }}
```

La causa raíz del problema se encuentra en el tema que uso para el blog: _Aglaus_; el tema no se actualiza desde hace unos diez meses, según su [repositorio en GitHub](https://github.com/dim0627/hugo_theme_aglaus). En Noviembre del 2018, el autor del tema comentaba que el tema ya no está siendo desarrollado activamente y que está de acuerdo con eliminarlo de los temas mostrados por Hugo en su galería: [The Aglaus Theme Demo is broken on the Hugo Themes website](https://github.com/dim0627/hugo_theme_aglaus/issues/17#issuecomment-437571589).

He estado probando otros temas de forma local pero he descubierto que los temas, en general, no son fácilmente intercambiables: la mayoría no producen ninguna salida en HTML al _compilar_ o directamente la creación del blog falla debido a problemas como que no se encuentra el _shortcode_ para las imágenes...

{{% img src="images/190419/xkcd-927-standards.png" caption="XKCD" href="https://xkcd.com/927/" %}}

_Me temo_ que la solución será invertir tiempo en desarrollar un tema propio: un tema simple, sin toda la funcionalidad de los temas más sofisticados, pero que sea sencillo de mantener.

Los únicos requerimientos que me impongo es que sea _responsible_ y que se puedan dejar comentarios; otros _nice to have_ serían la paginación (creo que está explicado con detalle en la documentación), los _artículos relacionados_ y una caja de búsqueda...