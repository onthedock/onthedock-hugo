+++
draft = false
categories = ["dev"]
tags = ["hugo"]
thumbnail = "images/hugo.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" %}}

title=  "Enlace simbólico a Hugo"
date = "2019-05-06T20:31:51+02:00"
+++
Una de esas cosas que no sé porqué no había hecho antes: crear un enlace simbólico para Hugo.

En el Mac, tengo "instalado" Hugo en `~/Applications/hugo`, que está fuera del _path_, por lo que para llamar a la aplicación, debo especificar siempre la ruta completa.

Creando el enlace simbólico puedo llamar a Hugo desde cualquier punto.
<!--more-->

Para ello, abre un terminal y navega hasta la carpeta `/usr/local/bin`.
Desde ahí, crea un enlace a la hubicación "real" del ejecutable de Hugo.

```bash
cd /usr/local/bin
sudo ln -s /Users/xavi/Applications/hugo
```
