+++
draft = true

# TAGS
# HW->OS->PRODUCT->specific tag
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "docker"]

# CATEGORIES = "dev" / "ops"
categories = ["dev", "ops"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/docker.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# YouTube
# {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Imagenes
# {{% img src="images/image.jpg" w="600" h="400" %}}
# {{% img src="images/image.jpg" w="600" h="400" class="right" %}}
# {{% img src="images/image.jpg" w="600" h="400" class="left" %}}
# {{% img src="images/image.jpg" w="600" h="400" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# Clear (floats)
# {{% clear %}}
# Twitter
# {{% twitter tweetid="780599416621297xxx" %}}

title=  "Plataforma Estandard"
date = "2017-11-11T23:01:50+01:00"
+++

Con frecuencia en una empresa cada nueva aplicación desplegada arrastra su propio conjunto de dependecias. A medida que se descubren nuevas vulnerabilidades de seguridad o se corrigen fallos, estas bibliotecas de las que depende la aplicación se actualizan, introduciendo modificaciones que pueden afectar al funcionamiento de la aplicación.

Con aplicaciones de terceros, el fabricante es el responsable de validar la funcionalidad de la aplicación, liberando nuevas _releases_. Pero con aplicaciones desarrolladas a medida es frecuente que la relación proveedor 
<!--more-->