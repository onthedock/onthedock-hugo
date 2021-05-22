+++
draft = false

categories = ["dev"]
tags = ["linux", "elementaryOS"]
thumbnail = "images/linux.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}

title=  "Cambiando a Elementary"
date = "2019-05-11T07:44:35+02:00"
+++
Hace unos meses me regalaron un [Cubi 3 Silent](https://es.msi.com/Desktop/Cubi-3-Silent-7m/Overview) de MSI. Como tengo un exceso de equipos por casa y no tenía memoria DDR4 o discos M.2, el equipo se convirtió en una especie de pisapapeles _high-tech_ y poco más.

Quiero racionalizar un poco el _cacharrerío_ que acumulo, así que he decidido renovar los viejos portátiles [Dell D630](https://www.dell.com/support/home/us/en/04/product-support/product/latitude-d630/drivers) y sustituirlos por el Cubi 3.
<!--more-->

Compré memoria y disco en Amazon y tras un pequeño retraso en la entrega de este último, ayer instalé [Elementary OS](https://elementary.io/es/).

# Algo de historia

Allí por el 2013 me cansé de Windows, de estar lidiando con actualizaciones constantes, con un sistema que en el peor momento (en la biblioteca) se ponía a "actualizar" cosas en segundo plano y disparaba los ventiladores... Decidí cambiar de portátil (por el ruido de los ventiladores) y dar el salto a un Mac.

Pese al precio, decidí considerarlo como una inversión, basándome en mi experiencia con el [iPod Mini](https://es.wikipedia.org/wiki/IPod_mini); sí, porque compré el ipod en 2005 y en 2013 seguía funcionando perfectamente -con la duración de la batería reducida- pero siendo perfectamente usable. De hecho, sigue funcionando todavía hoy (2019), aunque ahora lo tengo _pinchado_ a una altavoz y ya no lo uso como un dispositivo portátil.

Desde entonces, excepto en el trabajo, siempre he usado Mac OS o Linux en casa. Como los equipos que acumulo suelen ser equipos que otros descartan, no son ordenadores potentes. Así que en la elección de la distribución de Linux que instalo, **prima la ligereza**. Eso me ha llevado a usar [CrunchBang Linux](https://www.bunsenlabs.org/) o [Lubuntu](https://lubuntu.net/), básicamente (con otras combinaciones como Debian +  OpenBox y cosas por el estilo de forma puntual).

Estos equipos los uso como equipos de ofimática en los que no realizo ninguna tarea ofimática, por lo que no tengo instalado -ni necesito- LibreOffice, Gimp, ni el resto de cosas que las distribuciones suelen considerar "esenciales" y que de un tiempo a esta parte, se han convertido en "muy difíciles de desinstalar", al venir integradas con el escritorio.

En resumen, siempre ha habido fuertes condicionantes que me impedían instalar Ubuntu, Fedora o cualquier otra distribución de escritorio "estándar".

## Elementary OS

Después de la introducción anterior, parecería que al librarme de las restricciones que me impedían instalar Ubuntu, por ejemplo, ésta sería mi primera elección en el Cubi 3.

Sin embargo, como dejaba entrever, mis necesidades de escritorio no incluyen la mayoría de paquetes que estas distribuciones incluyen por defecto.
Podría instalar un sistema _pelado_ e instalar sólo lo que necesito...
Pero cuando he seguido ese camino, he perdido mucho tiempo arreglando cosas que no funcionan como deberían; al fin y al cabo, los equipos que "montan" las distribuciones de Linux se esfuerzan en limar todos esos detalles para construir un producto final sin "rough edges".

Y ahí es donde entra Elementary OS; es un sistema basado en Debian, con un aspecto estupendo y que no me fuerza a usar cosas que no necesito.

## Primera toma de contacto

La instalación de Elementary ha sido tan sencilla como cabía esperar de una distribución de Linux moderna: un asistente pregunta cuatro cosas básicas y después de reiniciar ya tienes un sistema usable.

He abierto las aplicaciones ancladas al dock por defecto, he quitado la de vídeos y la de fotos y he añadiendo el terminal.

## Epiphany _fail_

Epiphany, el navegador por defecto, se ha colgado sin motivo aparente durante la reproducción de vídeos en YouTube, al abrir una segunda pestaña no se han cargado las páginas web...

Inicialmente pensaba que era un problema de rendimiento, al estar actualizando el sistema en segundo plano, pero tras reiniciar, Epiphany ha seguido fallando.

No fue algo puntual; hoy se ha vuelto a colgar varias veces y le he dado carpetazo.

**¡Firefox al rescate!**

YouTube reproduciendo música en una pestaña, varias pestañas abiertas con búsquedas, la ventana de "previsualización" de Hugo... Todo funcionando sin problemas y a una velocidad significativamente superior a los tiempos de carga de Epiphany.

Una vez instalado un bloqueador de anuncios ([uBlock](https://addons.mozilla.org/es/firefox/addon/ublock/)), me he reconciliado con internet.

## Botón derecho en Firefox

El botón derecho, en Firefox, tampoco funcionaba como esperaba :(

Al pulsar con el botón secundario sobre un enlace para abrirlo en una nueva pestaña, el menú contextual se abre centrado sobre el puntero -no a la derecha- y registra el click inmediatamente al levantar el dedo del botón (en vez de esperar a que se haga click sobre la opción que se quiera seleccionar).

La solución la he encontrado en este hilo en Reddit [Firefox right click context menu gets activated and closes immediately instead of staying open](https://www.reddit.com/r/elementaryos/comments/9ucdxd/firefox_right_click_context_menu_gets_activated/).

1. Abre una nueva pestaña y abre las opciones de configuración escribiendo `about:config` en la barra de navegación.
1. Busca la opción `ui.context_menus.after_mouseup` y cambia su valor a `true`.

## Sin botón de minimizar

Por algún motivo que no entiendo, Elementary no incluye botón para minimizar las ventanas. Es una pequeña molestia, pero de momento vivo con ella. La solución que he encontrado por internet pasa por instalar un paquete de "customización" del sistema, pero siempre que puedo, evito instalar este tipo de cosas que sólo usaré una vez.

De momento, uso el mouse para _apartar_ la ventana o uso el botón derecho, donde la opción de minimizar es la primera que aparece en el menú contextual (aunque no en Visual Code, instalada vía Snap, por ejemplo).


## AeroSnap (versión Elementary)

En cuanto a la gestión de ventanas, Elementary incluye una versión del AeroSnap de Windows que funciona muy bién.

A diferencia de la versión original, que siempre separa la pantalla en dos mitades iguales, en Elementary el sistema es más flexible. Si tenemos una ventana _maximizada verticalmente_ (es decir, ocupa todo el espacio vertical de la pantalla, pero sólo un tercio, por ejemplo, del espacio horizontal), al acercar la ventana a un lado de la pantalla se "maximiza" para ocupar todo el espacio disponible.

Al igual que en Windows, se muestra un marco azul para indicar el tamaño final de la ventana, por lo que el efecto no sólo es visualmente agradable, sino que además es muy útil para indentificar el tamaño final de la ventana.

## El audio no funciona después de "despertar" de la suspensión

Al arrancar el equipo desde el estado suspendido, el audio no funcionaba.

La solución ha pasado por reiniciar el servicio de PulseAudio:

```bash
pulseaudio -k
pulseaudio -D
```

# Conclusión

No hace ni 48h que he empezado a usar Elementary como sistema principal; apenas he instalado Git, Visual Code y Hugo y ya estoy trabajando con normalidad, sin ningún tipo de fricción.

Y esa es quizás la mejor crítica que se le puede hacer a un sistema: que funcione tan bien que te olvides de que esté ahí.
