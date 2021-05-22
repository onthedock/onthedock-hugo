+++
draft = false
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["hugo", "blog", "theme"]
thumbnail = "images/hugo.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}

title=  "Solucionado: Warning '.Hugo is deprecated'"
date = "2019-04-19T13:06:12+02:00"
+++
En la [entrada anterior]({{< ref "190419-cambios-en-el-blog.md" >}}) indicaba que después de actualizar a la versión 0.55 de Hugo, recibía el mensaje:

```bash
WARN 2019/04/19 Page's .Hugo is deprecated and will be removed in a future release. Use the global hugo function.
```

Después de revisarlo, he encontrado la causa: en el fichero `layouts/partials/meta.html` del tema, aparece `{ .Hugo.Generator }`.
<!--more-->

Esta variable aparece en la documentación como [Hugo Variables](https://gohugo.io/variables/hugo/) y **no se indica que haya pasado a desaconsejada**.

El objetivo de esta variable es _inyectar_ una etiqueta `meta` indicando que la página ha sido generada con Hugo:

```txt
.Hugo.Generator
   <meta> tag for the version of Hugo that generated the site. .Hugo.Generator outputs a complete HTML tag; e.g. <meta name="generator" content="Hugo 0.18" />
```

Aunque mi primer impulso ha sido eliminar el _tag_ y acabar con el problema, creo que es una cuestión de buena _nettiqueta_ el mencionar el generador del site... No cuesta nada y sirve para apoyar a este gran producto...

Así que después de investigar un poco, he encontrado la manera de deshacerme del _warning_ sin dejar de incluir la etiqueta `meta` en el site; la solución la proporciona [zwbetz](https://discourse.gohugo.io/u/zwbetz) en su [respuesta](https://discourse.gohugo.io/t/pages-hugo-is-deprecated-as-of-0-55-0/17991/2) (he optado por la segunda opción, `hugo.Generator`):

```txt
{{ .Page.Hugo.Generator }} <!-- deprecated -->
{{ $.Hugo.Generator }} <!-- okay -->
{{ hugo.Generator }} <!-- okay -->
```