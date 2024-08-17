+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["hugo"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/hugo.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/
# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}

title=  'Fix Deprecated ".Site.GoogleAnalytics" error en la plantilla del blog'
date = "2024-08-17T11:12:04+02:00"
+++
Ha pasado *muuuucho* tiempo desde la última publicación; lo cierto es que todo se ha debido a que, principalmente, he pasado a usar otro portátil como mi dispositivo desde el que "hago cosas", y por pereza, no había clonado el repositorio de este blog.

Pero hoy he decidido acabar con esta situación... y lo primero que me he encontrado al *reconstruir* el blog ha sido el error:

```console
.Site.GoogleAnalytics was deprecated in Hugo v0.120.0 and will be removed in Hugo 0.133.0. Use .Site.Config.Services.GoogleAnalytics.ID instead.
```
<!--more-->

Parte del error se debe a que, en el otro portátil, hace tiempo que no actualizo Hugo, por lo que supongo que tengo una versión anterior a la indicada `v0.120.0`.

Hoy, al instalar Hugo, he descargado la última versión, la v0.132.0`, por lo que he visto el mensaje *por primera vez*.

Tenía dos opciones:

- actualizar la directriz a `.Site.Config.Services.GoogleAnalytics.ID`, como se recomienda
- eliminar la directriz completamente de la plantilla (ya que no uso ningún tipo de analítica en el blog)

Dado que no uso ningún tipo de sistema de análisis en el blog (lo publico principalmente para mí), he decidido eliminar las dos aparicions de la directriz en la plantilla.

Esto soluciona el problema para siempre 😉.

Por otro lado reabre la cuestión de qué hacer con la plantilla del blog; como he comentado alguna otra vez, la plantilla original dejó de estar mantenida por su creador desde hace años, por lo que periódicamente, me debato en crear una propia desde cero o bien migrar el blog a otra plantilla...

Una vez más, la cuestión quedará en el aire...
