+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "fedora"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/linux.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" %}}

title=  "Odiando Fedora en menos de 1 hora"
date = "2020-06-20T19:37:41+02:00"
+++
Hace aproximadamente seis meses cambié de piso; el cambio no le sentó bien a mi equipo de laboratorio, ya que dejó de estar conectado por cable al router y pasó a depender de una tarjeta wifi PCI. Proxmox VE, que era la distro que usaba para virtualizar, nunca reconoció la tarjeta por lo que finalmente tuve que instalar un Windows 10 y usar Virtual Box.

Hoy he decidido volver a instalar Linux en el equipo; el primer problema lo he encontrado porque parece que AMD Radeon y Linux no se llevan bien, por lo que no puedo instalar si no paso el parámetro `nomodeset` como opción de arranque (ya me había pasado antes, pero no deja de ser igual de frustante [Instalación de Linux en modo gráfico seguro]({{<ref "200221-nomodeset.md" >}})).

Pulsando Ctrl+D he podido pasar el parámetro en la instalación de ProxMox VE e instalarlo. En la documentación de ProxMox VE se indica cómo configurar la red wifi y he validado que el chip de la tarjeta wifi está soportado en Linux... Pero aunque `modinfo rt2500pci` indica que se ha detectado, no he encontrado la manera de habilitarla...

Ese ha sido el primero de muchos suplicios que me ha deparado este equipo de laboratorio...
<!--more-->

He instalado Debian 10 y siguiendo las instrucciones de la documentación oficial, he conseguido instalar ProxMox. Sin embargo, tras instalar `wpasupplicant`, el equipo ha dejado de arrancar (para ser exactos, ha entrado en un bucle continuo de reinicios...)

Finalmente, he cambiado el enfoque y he decido convertir el equipo (con 32GB de RAM) en mi PC de escritorio y virtualizar directamente en él. Mi primera opción ha sido Pop OS!, de System 76. Lo instalé en un Cubi3 Barbone que usaba como equipo *ofimático* cuando me cansé de lo "particular" que es Elementary OS y lo poco que se deja *customizar* y no he vuelto a mirar atrás. El ajuste en mosaico automático de las ventanas fue molesto hasta que aprendí a cambiarlas de *workspace* con el teclado, a cambiar el foco con el teclado, a lanzar aplicaciones con el teclado... Además, no incorpora aplicaciones *de serie*, por lo que no tengo que perder el tiempo desinstalándolas justo cuando acabo de instalar y/o actualizar el sistema (como ha pasado con Fedora, por ejemplo).

Debido al *problemilla* con la tarjeta gráfica -y a que no he sido capaz de encontrar cómo pasar el parámetro `nomodeset` durante la  instalación- he tenido que abandonar la instalación de Pop OS! (y ha sido después de estar buscando una tarjeta gráfica no AMD en Amazon, tan poco dispuesto estaba a renunciar a Pop OS!).

Finalmente, he descargado Fedora Desktop y -`nomodeset` mediante- he instalado el escritorio. Al fin y al cabo, tanto Pop OS! como Fedora Desktop usan GNOME Shell, por lo que no debería haber demasiadas diferencias...

Tras el arranque, el sistema me ha avisado de que había actualizaciones disponibles, así que las he descargado e instalado. Antes de continuar, he decidido hacer un rápido reinicio para seguir con el aterrizaje en Fedora... Mi sorpresa ha sido que, durante unos diez o quince minutos he contemplado un mensaje de "se están instalando actualizaciones", como si hubiera vuelto a Windows, con su porcentaje que no se actualiza y que te deja con la duda de si se ha colgado...En fin, la misma experiencia que en Windows, pero en Fedora.

Tras finalizar la instalación de actualizaciones y un nuevo reinicio (la instalación de un nuevo kernel en ProxMox, no ha sido tan aparatosa, sin ir más lejos), he empezado a desinstalar aplicaciones (Cheese?, Calendario, etc) y después adaptando los atajos de teclado para que fueran los mismos que en Pop OS! Pese a todo, he empezado a sentir la fricción en esos pequeños detalles que, hasta ahora, no había notado con Pop OS!

He instalado Tweaks para poder *meterle mano a fondo* al escritorio y limar esos detallitos, pero nada...

Después de darme de bruces de nuevo con la triste realidad de navegar por internet con Firefox sin un bloqueador de anuncios, he instalado Brave Browser. He leído un par de artículos sobre las excelencias de GNOME Boxes y me he dispuesto a probarlo.

Sí, el aspecto es minimalista, pero a mí lo que me importa es que funcione. A la hora de crear la máquina virtual, de entrada se ofrecen las distribuciones de RedHat, lo que, en mi opinión, raya la publicidad no deseada. He pulsado sobre Fedora y se ha lanzado lo que supongo que es una descarga de un imagen de disco con el sistema pre-configurado... Así que mientras esperaba, he descargado la ISO de Alpine Linux.

He creado una máquina virtual, la he lanzado y Boxes me ha mostrado una pantalla diciendo que no se encontraba un disco de arranque. He revisado la "box" de Alpine, y efectivamente, tenía *pinchada* la ISO. He probado a reiniciar y nada... Tras unos segundos, Boxes me ha mostrado un mensaje diciendo que la máquina tardaba mucho en reiniciar y que si quería pararla a la brava. He dicho que sí... Y de nuevo nada.

He vuelto a arrancar la VM y sí, `No bootable device`. *Again*. Nuevo cuelgue de Boxes (o *freeze*, o lo que sea), incapaz de reiniciar la máquina virtual con Alpine. *Again*.

{{% img src="images/200620/boxes-alpine-no-boot.png" w="989" h="876" %}}

He creado una nueva máquina, con las opciones por defecto (pero a partir de la ISO de Alpine) y la cosa ha mejorado algo, ya que ha aparecido un menú para seleccionar el "medio" de arranque. Por desgracia, ninguna de las opciones ha conseguido "identificar" la ISO asociada la unidad de CD de Boxes ni arrancar Alpine.

Como he apagado Boxes y lo he vuelto a arrancar, por si fuera un problema transitorio, la descarga de la "box" de Fedora se ha cancelado... Así que la he vuelto a lanzar; curiosamente, no ha continuado la descarga sino que ha empezado de nuevo.

Pensaba que Box guardaría algún tipo de copia local, ya que no sé si tiene mucho sentido tener que descargar la imagen base una y otra vez (¿y qué pasa si no tengo conexión a internet?)

He realizado una captura de pantalla -ya pensando en realizar esta entrada- y al pulsar sobre la imagen de la captura se ha abierto "Image Viewer". En el "dock" o como se llame en GNOME, una de las aplicaciones *pineadas* es Photos. Así que he pulsado con el botón secundario para hacer un "Abrir con" y así recortar la captura... Pero las únicas aplicaciones mostradas eran Brave y Image Viewer; he pulsado "Todas las aplicaciones" y ni aún así ha aparecido "Photos".

{{% img src="images/200620/no-photos-app.png" w="889" h="595" %}}

Esa ha sido la gota que ha colmado el vaso; porque Boxes puede fallar porque Alpine es una distro "especial", porque Boxes intenta hacer muchas cosas a la vez (crear máquinas virtuales, conectarse a máquinas remotas, etc) y, siendo más complejo, puede haber cosas que fallen... Pero cuando incluyes una aplicación en tu sistema operativo, enfocada a un usuario normal, como Photos y la aplicación no aparece en "todas las aplicaciones", es que el sistema operativo no está bien hecho. Y si una aplicación "incluida de fábrica" ya presenta este tipo de problemas de integración con el sistema operativo, no quiero invertir tiempo peleándome con otros fallos que puedan aparecer con otras aplicaciones que necesito para poder disfrutar de mi tiempo y de mi *hobby*.

La diferencia con Pop OS!, que llevo usando desde la salida de la versión 20.04, es simplemente, **abismal**.

Y aunque hoy ha sido un día largo y estoy cansado de descargar una distro tras otra, instalarla -o intentarlo- y pasar por el siempre tedioso proceso de instalación, la experiencia con Fedora Desktop ha sido tan desastrosa que prefiero pasar por todo ello de nuevo antes que seguir con Fedora como sistema operativo.
