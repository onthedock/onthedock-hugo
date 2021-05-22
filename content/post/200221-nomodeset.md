+++
draft = false
categories = ["ops"]
tags = ["linux", "amd"]
thumbnail = "images/linux.png"
title=  "Instalación de Linux en modo gráfico seguro"
date = "2020-03-21T21:20:25+01:00"
+++
Los *kernels* de Linux modernos han movido la configuración de los modos de vídeo al *kernel*. Algunas tarjetas gráficas no funcionan correctamente tras este cambio, por lo que el proceso de instalación de Linux falla de un modo u otro; en mi caso, el sistema se reinicia a los pocos segundos de empezar el proceso de arranque del sistema, aunque lo habitual es que la pantalla se quede "en blanco".
<!--more-->

La solución para estos problemas durante el arranque se puede conseguir mediante parámetros del *kernel*. El proceso varía en cada distribución, pero suponen detener el arranque automático y entrar en un modo interactivo para modificar los parámetros pasados al *kernel* por defecto.

En algunos casos, como en [Zorin OS](https://zorinos.com/), el instalador ofrece una opción de arranque con "con gráficos seguros", mientras que en Ubuntu se pueden pasar diferentes tipos de parámetros opcionales pulsando cualquier tecla cuando se muestra el menú inicial (`nomodeset` se encuentra dentro del menú mostrado al pulsar `F6 Other Options`):

{{< figure src="/images/200221/ubuntu-installer-options.png" w="640" h="480" >}}

Una excelente explicación de algunas de las diferentes opciones que se pueden pasar al *kernel* durante el arranque es [How to set NOMODESET and other kernel boot options in grub2](https://ubuntuforums.org/showthread.php?t=1613132). Aunque se trata de una entrada del 2010, el primer párrafo de esta entrada está tomada, casi literalmente, de ese artículo:

> `nomodeset`: The newest kernels have moved the video mode setting into the kernel. So all the programming of the hardware specific clock rates and registers on the video card happen in the kernel rather than in the X driver when the X server starts.. This makes it possible to have high resolution nice looking splash (boot) screens and flicker free transitions from boot splash to login screen. Unfortunately, on some cards this doesnt work properly and you end up with a black screen. Adding the nomodeset parameter instructs the kernel to not load video drivers and use BIOS modes instead until X is loaded."

Es importante tener en cuenta que, para que el parámetro se aplique en cada arranque de manera automática -y no sólo cuando lo especifiquemos manualmente- debemos editar el fichero de configuración de `grub2`.
