+++
date = "2017-06-04T18:26:48+02:00"
title = "Instalación de Alpine linux"
thumbnail = "images/alpine.png"
categories = ["ops"]
tags = ["linux", "alpine"]
draft = false

+++

Alpine Linux se ha convertido en la distribución por defecto con la que construir contenedores.

Alpine tiene sus propias particularidades, ya que no deriva de otra distribución, de manera que he pensado que sería una buena idea tener una máquina virtual con la que entrenarme.

En este artículo explico qué diferencias he encontrado en Alpine. 

<!--more-->

## Descargando Alpine Linux

La primera diferencia respecto al resto de distribuciones es el tamaño de la ISO de instalación. En la [página de descarga](https://alpinelinux.org/downloads/) de Alpine Linux, tienes varias versiones para descargar. Además de las habituales, en función de la arquitectura (x86, x86-64, Raspberry Pi, Generic ARM), tienes disponibles versiones orientadas a entornos virtuales, para Xen, etc.

En mi caso he descargado la versión `Virtual`, orientada a sistemas virtuales y la imagen de instalación ocupa 35MB!.

## Máquina virtual

He creado una máquina virtual y he conectado la ISO.

Al arrancar la máquina, el sistema arranca en modo _live-CD_, ejecutándose completamente en memoria.

Para acceder al sistema, teclea `root`.

Mi primera sorpresa ha sido que no se ha solicitado la contraseña.

Una vez dentro, ara configurar el sistema, lanza la utilidad `setup-alpine`.

```
Welcome to Alpine!

The Alpine Wiki contains a large amount of how-to guides and general
information about administrating Alpine systems.
See <http://wiki.alpinelinux.org>.

You can setup the system with the command: setup-alpine

You may change this message by editing /etc/motd.
```

El teclado, por defecto, está en inglés, por lo que el `-` se encuentra bajo la tecla `?` en un teclado en castellano.

El script de instalación pasa por los diferentes pasos de configuración:

* teclado: `es`
* variacion de teclado: `es-cat`
* nombre del equipo: `alpine`
* inicializar interfaz: `eth0`
* configuración de IP: `dhcp`
* ¿quieres realizar alguna configuración de red manual?: `no`
* establecer el password del `root`:
* zona horaria: `CET`
* Proxy: `none`
* Elección del _mirror_: `f` (se selecciona el más rápido)
* instalación de servidor de SSH: `openssh` (opción por defecto)
* cliente NTP: `chrony` (opción por defecto)
* selección de disco: `sda`
* uso del disco: `sys` (selecciona `?` para ver las diferencias entre las opciones presentadas)
* confirmar el borrado del disco: `y`

Y ¡ya está! Sólo queda reiniciar.

En mi caso, he escrito `reboot` y el sistema se ha reiniciado al cabo de unos pocos segundos.

Al hacer login de nuevo, me ha sorprendido que no se me haya solicitado el password y que se haya perdido la configuración introducida :(

Alpine Linux es una distribución tan ligera -y en la máquina de laboratorio tengo un SSD- que me ha costado un momento darme cuenta de que, al reiniciar, la máquina virtual no ha perdido la configuración, sino que ha arrancado de nuevo la versión del _live-CD_.

Una vez expulsada la ISO, he reiniciado de nuevo y he accedido al sistema ya instalado en la VM ;)

## Acceso remoto vía SSH

Por comodidad, prefiero trabajar desde la consola del Mac, pero no quiero crear un nuevo usuario.

Por defecto, OpenSSH no permite la conexión remota del usuario `root`, así que el siguiente paso es modificar el fichero de configuración.

```
# vi /etc/ssh/sshd_config
```

* Desplázate hasta la línea `PermitRootLogin`
* Pulsa `i` para entrar en el modo interactivo de Vi
* Escribe en una nueva línea: `PermitRootLogin yes`
* Pulsa `ESC` para volver al modo de comandos
* Escribe `:wq` (_write_, _quit_) para guardar los cambios y salir de Vi.

Para que los cambios tengan efecto, reinicia el servicio SSH:

```
# service sshd restart
```

## Siguientes pasos

A continuación realizaré la instalación de algunos paquetes.

El objetivo es probar el proceso que se realiza durante la creación de una imagen en Docker, pero en un entorno donde poder observar la salida de los comandos ejecutados, etc.

## Resumen

En este artículo hemos instalado Alpine Linux en una máquina virtual.

También hemos modificado el servidor SSH para poder conectar remotamente como `root` (por comodidad, en un entorno seguro de laboratorio).

En los próximos artículos seguiremos familiarizándonos con Alpine Linux.








