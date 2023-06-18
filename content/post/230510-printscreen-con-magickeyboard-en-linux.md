+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = []
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "mac"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/linux.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/

# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}

title=  "Cómo capturar la pantalla usando un Magic Keyboard en Linux (Pop!_OS)"
date = "2023-05-20T20:56:20+02:00"
+++
Desde hace unos días he empezado a usar de forma exclusiva un teclado Magic Keyboard, tanto con mi equipo de trabajo (un Mac) como con el personal (con Linux - Pop!_OS).

Como el teclado no incluye una tecla dedicada [PrtSc](https://en.wikipedia.org/wiki/Print_Screen), en esta entrada indico cómo asignar una combinación de teclas en Pop!_OS para realizar capturas de pantalla.
<!--more-->

## Contexto

En Mac OS las capturas de pantalla se realizan con una combinación de teclas, por lo que el teclado no incluye una *tecla dedicada* como [`PrtSc`](https://en.wikipedia.org/wiki/Print_Screen).

Hasta ahora, usaba un teclado [Logitech bluetooth multidispositivo K380](https://www.logitech.com/es-es/products/keyboards/k380-multi-device.920-007576.html) (que es mucho más barato en Amazon), que al ser compacto, tampoco incluye una tecla Prtsc dedicada... Pero en la tecla de `tab` incluye la captura de pantalla como función secundaria:

{{< figure src="/images/230520/logitech-k380-prtsc.png" width="100%">}}

Pero al cambiar de empresa, me han proporcionado un Mac junto con un Magic Keyboard y un Magic Mouse.

El Magic Mouse es, simplemente **imposible de usar**. Sin embargo, el Magic Keyboard me encanta, por lo que he empezado a usarlo como "teclado principal".

Como el Magic Keyboard no es multidispositivo -como el Logitech-, en vez de andar sincronizando el teclado con cada equipo cuando quiero usarlo, he aprovechado el hecho de que también puedo usarlo con cable. Así, uso el equipo vía Bluetooth con el Mac y vía cable con el equipo con Linux.

## Asignar una combinación de teclas para realizar la captura de pantalla

Inicialmente mi plan era asignar PrtSc a alguna otra tecla... Pero existe una opción mucha más sencilla: cambiar el *atajo de teclado* para realizar la captura.

En Pop!_OS (22.04), abre la aplicación *Settings* y en el partado *Keyboard*, pulsa *View and Customise Shortcuts*.

Usa la caja de búsqueda para encontrar los *atajos* asociados a las captura de pantalla; en mi caso, busco `screenshot`:

{{< figure src="/images/230520/settings.png" width="100%" >}}

Pulsa sobre la cambiar la combinación de teclas asociada a la función que quieres modificar y a continuación pulsa la nueva combinación de teclas.

Para establecer la nueva combinación de teclas, pulsa el botón *Set*:

{{< figure src="/images/230520/set_new_shortcut.png" width="100%" >}}

## "Memoria muscular"

Puede parecer que la combinación de teclas elegida es algo *rara*... La explicación es que paso más tiempo trabajando (y por tanto, usando las combinaciones de teclas del Mac). Por tanto, en vez de establecer *la combinación anterior* (Fn+Tab) he decidido usar la misma combinación que uso junto con la aplicación [shottr](https://shottr.cc/); al fin y al cabo, es la combinación que ya tengo grabada en mi ["memoria muscular"](https://en.wikipedia.org/wiki/Muscle_memory).

Por el mismo motivo, modificaré la combinación de teclas para ajustar ventanas al margen izquierdo y derecho, que en Pop!_OS es `Crtl + Super + ->` ( y `Crtl + Super + <-`) por la equivalente en [Rectangle](https://rectangleapp.com/), que es la aplicación que uso en Mac (`Ctrl + Option + ->/<-`).
