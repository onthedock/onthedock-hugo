+++
date = "2017-07-02T22:07:18+02:00"
title = "IP en mensaje prelogin"
thumbnail = "images/alpine.png"
categories = ["ops"]
tags = ["linux", "alpine"]
draft = false

+++

En la pantalla de _login_ en modo consola de los sistemas Linux se muestra un mensaje de bienvenida.

En este artículo se muestra cómo hacer que se muestre la IP del equipo.

<!--more-->

Cuando tenemos una máquina (virtual) configurada para obtener la IP de forma dinámica mediante DHCP, al desconocer por adelantado la IP que se le ha asignado, es necesario conectarse al hipervisor, hacer login en la máquina virtual para, finalmente, obtener la IP _actual_ de la VM.

Entonces podemos conectarnos _remotamente_ usando PuTTY (desde Windows) o un emulador de terminal desde Linux/OSX.

Sin embargo, hay una manera de agilizar este proceso, aprovechando el mensaje que se muestra antes del login.

> Aunque en este caso he usado Alpine Linux, las instrucciones son igualmente válidas para la mayoría de distribuciones.

En primer lugar necesitamos ejecutar un _script_ durante el arranque del sistema operativo. En el caso concreto de Alpine Linux, he encontrado la solución en [run script on boot](https://forum.alpinelinux.org/forum/general-discussion/run-script-boot).

Ya que no vamos a escribir nuestro propio servicio, usaremos el servicio _local_. Para ello, hay que añadir nuestro _script_ en la carpeta `/etc/local.d/`

```shell
rc-update add local default
```

El `README` ubicado en `/etc/local.d/README` indica que cualquier fichero ejecutable con extensión `.start` se lanza al arrancar el servicio, mientras que si la extensión es `.stop`, se ejecuta al parar el servicio.

En mi caso, he usado el _script_ para obtener la IP de la máquina como se indica en [Show IP address of VM as console pre-login message](http://offbytwo.com/2008/05/09/show-ip-address-of-vm-as-console-pre-login-message.html) y la he escrito en el fichero `/etc/issue`:

```
/sbin/ifconfig | grep "inet addr" | grep -v "127.0.0.1" | awk '{ print $2 }' | awk -F: '{ print $2 }' > /etc/issue
```

Después de convertir el _script_ en ejecutable, he reinciado la máquina para probar que todo funcionaba como esperaba.

Tras los mensajes de arranque, se muestra:

```
192.168.1.208
alpine login:
```

Así no hace falta hacer _login_ en la máquina para obtener la IP.

