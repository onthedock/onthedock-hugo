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

title=  "Submódulo en Git"
date = "2020-06-21T08:42:51+02:00"
+++
Mucho ha llovido desde que configuré Hugo para generar este blog ([Publica en GitHub Pages]({{< ref "170403-publica-en-github-pages.md" >}})). Lo hice en mi MacBook Air (Mid 2013) y casi todas las actualizaciones las sigo haciendo desde ahí.

Alguna vez he clonado el repositorio en otro equipo pero siempre había tenido problemas al intentar publicar el resultado final (en HTML) en GitHub Pages.
El problema surge de que los ficheros HTML se generan en la carpeta `public/`, que está configurada como un *submódulo* de Git.
<!--more-->
Al clonar el respositorio que contiene las entradas (en formato Markdown), hay que indicar que contiene *submódulos*.
Esto se consigue mediante: `git clone --recursive ${URl-del-repo}` o con `git clone --recurse-submodules ${URl-del-repo}`.

Sin embargo, tras ejecutar el clonado, la carpeta `public/` seguía siendo *una carpeta normal*, sin los ficheros en formato HTML y sin la carpeta `.git` que la identifica como un repositorio.

En la raíz del repositorio sí que se encontraba el fichero `.gitmodules`.

Después de mucho buscar en internet y tras consultar la documentación oficial para [gitsubmodules - Mounting one repository inside another](https://git-scm.com/docs/gitsubmodules), finalmente me he dado cuenta de mi error leyendo la entrada [Git Submodules: Adding, Using, Removing, Updating](https://chrisjean.com/git-submodules-adding-using-removing-and-updating/).

Por algún motivo, en mi fichero `.gitmodules`, el `path` especificado era `onthedock.github.io`, en vez de la ruta "local" en la que se encuentra el submódulo (la carpeta `public`).

Tras corregirlo, he lanzado:

```bash
git sync
git submodule update --init --recursive
```

Esto ha clonado el repositorio del contenido generado (en HTML) en la carpeta `public/` como debe ser.

La validación de que todo funciona correctamente es esta entrada que estás leyendo ;)
