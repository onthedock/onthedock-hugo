+++
draft = false

# TAGS
# HW->OS->PRODUCT->specific tag
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = []

# CATEGORIES = "dev" / "ops"
categories = []

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/dokuwiki-on-docker.png"

# SHORTCODES (for reference)

# YouTube
# {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Imagenes
# {{< figure src="/images/image.jpg" w="600" h="400" >}}
# {{< figure src="/images/image.jpg" w="600" h="400" class="right" >}}
# {{< figure src="/images/image.jpg" w="600" h="400" class="left" >}}
# {{< figure src="/images/image.jpg" w="600" h="400" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# Clear (floats)
# {{% clear %}}
# Twitter
# {{% twitter tweetid="780599416621297xxx" >}}

title=  "Dokuwiki en Docker - Uso de CPU en Raspberry Pi"
date = "2017-11-05T12:22:00+01:00"
+++

En la entrada anterior [Cómo crear una imagen con Caddy y PHP]({{<ref "170930-como-crear-una-imagen-con-caddy-y-php.md">}}) explicaba el proceso para conseguir _containerizar_ Dokuwiki y ejecutarlo sobre Docker.

Sin embargo, la potencia de la Rapsberry Pi (1) es insuficiente para poder usar Dokuwiki de forma cómoda de esta forma.
<!--more-->

En las pruebas que he estado realizando -configurando usuarios, instalando extensiones, etc- Dokuwiki respondía de forma bastante lenta.

He analizado el uso de CPU y RAM del contenedor usando Portainer y en las gráficas se ve claramente cómo cada vez que Dokuwiki tiene que _renderizar_ una página, el consumos de la CPU sube hasta el 80%. El uso de memoria se mantiene más o menos estable entre los 35-50 MB, por lo que el factor limitante es la escasa potencia del primer modelo de la Raspberry Pi.

{{< figure src="/images/171105/cpu-usage.png" >}}

Como referencia y contraste, el consumo de CPU del contenedor cuando no se está usando Dokuwiki está por debajo del 0.02% de la CPU.

{{< figure src="/images/171105/cpu-usage-iddle.png" >}}

Este uso intensivo de la CPU por parte del contenedor hace que, aunque no use Dokuwiki de forma intensiva, sí que supone un ejercicio de paciencia a la hora de previsualizar/guardar los cambios en la página, tomando cada acción entre uno y dos segundos.

En el siguiente GIF he intentado capturar el comportamiento del Wiki en un uso simulado de login, edición de una página y guardado de los cambios:

{{< figure src="/images/171105/using-dokuwiki.gif" h="950" w="875" >}} 