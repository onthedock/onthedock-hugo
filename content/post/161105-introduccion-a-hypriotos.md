+++
thumbnail = "images/hypriot.png"
tags = ["raspberry pi", "hypriot os", "docker"]
categories = ["ops"]
date = "2016-11-05T10:37:47+01:00"
title = "Introducción a Hypriot OS"

+++

[HypriotOS](http://blog.hypriot.com/about/#hypriotos:6083a88ee3411b0d17ce02d738f69d47) es un sistema operativo basado en [Debian](http://www.debian.org/) optimizado para ejecutar [Docker](http://www.docker.com/) en plataformas ARM como las [Raspberry Pi](https://www.raspberrypi.org/).

<!--more-->

# HypriotOS

Las características principales de HypriotOs son:

* Sistema operativo basado de Debian: la mayor parte de la gente saber cómo usar Debian y las distribuciones basadas en Ubuntu.
* Optimizado para Docker: Todo en HypriotOS está orientado a conseguir que Docker se ejecute de maravilla, desde las configuraciones del kernel de Linux hasta el sistema de ficheros.
* Versiones actualizadas de Docker: Hypriot se actualiza cada vez que se publica una nueva versión de Docker.
* Listo para usar: descargar, *flashear* y arrancar, es lo único que hace falta para ponerse en marcha con HypriotOS.

## Instalación de HypriotOS

La instalación de HypriotOS en la Raspberry Pi es muy sencilla.

En el blog de Hypriot tienes información para grabar la imagen en una tarjeta SD tanto si usas [Windows, Linux o Mac](http://blog.hypriot.com/getting-started-with-docker-on-your-arm-device/).

En mi caso, he usado un equipo con Windows para pasar la imagen a la tarjeta SD siguiendo los siguientes pasos:

1. Descarga la imagen con Hypriot en formato comprimido desde [sección de descargas del blog de Hypriot](http://blog.hypriot.com/downloads/)).
1. Descomprime el *zip*.
1. Usa [Win32DiskImager](http://sourceforge.net/projects/win32diskimager/) para pasar la imagen descomprimida a la tarjeta SD.

¡Eso es todo!

El siguiente paso es colocar de nuevo la tarjeta SD en la Raspberry Pi y arrancar.

## Obtener la dirección IP de la Raspberry Pi

Por defecto, la Raspberry Pi con HypriotOS obtiene una dirección IP del DHCP local. En el blog de Hypriot recomiendan usar un programa para escanear tu red local y obtener la dirección asignada a la Raspberry Pi ([ZenMap](http://sourceforge.net/projects/nmap.mirror/?source=typ_redirect) o [Angry IP Scanner](http://angryip.org/download/#windows), en los comentarios). En mi caso, he accedido a la lista de clientes a los cuales el DHCP les ha asignado una dirección IP y he obtenido la dirección asignada al equipo llamado *black-pearl*.

Una vez obtenida la dirección IP, conéctate usando [*Putty*](http://the.earth.li/~sgtatham/putty/latest/x86/putty.exe).

Introduce la IP asignada a la Raspberry Pi en el campo *Host Name (or IP address)* y verifica que el puerto es el 22.

La primera vez que conectes a la dirección IP de la Raspberry Pi obtendrás un mensaje de aviso indicando si quieres confiar en el equipo.

Puedes iniciar sesión en la Raspberry Pi usando el nombre de usuario `pirate` y el password  `hypriot`.

Finalmente, para verificar que Docker se encuentra presente, ejecuta `docker info`. La salida de este comando te devolverá las versiones de cliente y servidor instaladas.

## Crea tu primer contenedor

Ya está todo listo para ejecutar tu primer contenedor. Y es tan sencillo como lanzar el comando:

```sh
docker run -d -p 80:80 hypriot/rpi-busybox-httpd
```

Este comando ejecuta un contendor (`docker run`) en segundo plano, de forma no interactiva (`-d`, *dettached*), conectando el puerto 80 (web) de tu equipo local con el puerto 80 del contenedor. El contenedor se creará a partir de la imagen `hypriot/rpi-busybox-httpd`.

Cuando Docker intenta crear el contenedor, busca la imagen indicada en su registro local. Si no lo encuentra, se conecta a un registro público -por defecto Docker Hub- y busca la imagen allí.

Una vez localizada la imagen, descarga en el registro local una copia de la imagen y finalmente arranca un contenedor basado en esa imagen.

```sh
$ docker run -d -p  80:80 hypriot/rpi-busybox-httpd
Unable to find image 'hypriot/rpi-busybox-httpd:latest' locally
latest: Pulling from hypriot/rpi-busybox-httpd
c74a9c6a645f: Pull complete
6f1938f6d8ae: Pull complete
e1347d4747a6: Pull complete
a3ed95caeb02: Pull complete
Digest: sha256:c00342f952d97628bf5dda457d3b409c37df687c859df82b9424f61264f54cd1
Status: Downloaded newer image for hypriot/rpi-busybox-httpd:latest
19d131999ea3142d44a83a6e943c9052d8defa43f7da372bd08ec441ee55f31b
```

La imagen descargada contiene `busybox` y un servidor web minimalista. Puedes acceder al servidor arrancado en el contenedor a través de un navegador, indicando la IP de la Raspberry Pi.

### Un contenedor más útil

Como ejemplo de primer contenedor y de lo fácil que es lanzar contenedores con Docker, el ejemplo anterior no está mal.

Sin embargo, vamos a seguir los mismos pasos para crear un contenedor que proporciona un entorno web de gestión de Docker:

```sh
docker run -d -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock hypriot/rpi-dockerui
```

En este caso observamos que, además de las instrucciones que hemos visto en el caso anterior, tenemos un nuevo parámetro `-v`, que permite *montar* una ruta local del equipo *host* en el contenedor. Sin embargo, no te preocupes si ahora no entindes todos los detalles.

Una vez arrancado el contenedor, accede a través de un navegador a `http://{IP-equipo-docker}:9000`. Desde este entorno web puedes controlar el estado de tu instalación de Docker vía web gracias a [UI-for-Docker](https://github.com/kevana/ui-for-docker).

## Asigna una IP estática

En el apartado anterior hemos visto cómo instalar Docker y hemos lanzado los primeros contenedores. Pero la Raspberry Pi sigue con la configuración de la dirección IP dinámica, por lo que puede que la próxima vez que intentes acceder a la RPi, su dirección haya cambiado.

Para evitar estos problemas, vamos a asignar la IP -estática- 192.168.1.51.

Abrimos el fichero `/etc/network/interfaces` y encontramos que se hace referencia a una carpeta de configuración:

```config
# interfaces(5) file used by ifup(8) and ifdown(8)
# Include files from /etc/network/interfaces.d:
source-directory /etc/network/interfaces.d
```

Abrimos el fichero de configuración de la tarjeta de red `eth0`:

```config
allow-hotplug eth0
iface eth0 inet dhcp
```

Vemos que está configurada en modo `DHCP`, por lo que comentamos la segunda línea y especificamos la configuración de IP estática:

```config
# iface eth0 inet dhcp

# Set static IP
iface eth0 inet static
address 192.168.1.51
gateway 192.168.1.1
domain_name_servers=8.8.8.8, 8.8.4.4
```

Por supuesto, debes indicar la configuración de red de tu entorno.

Guardamos los cambios y reiniciamos el servicio de red mediante:

```sh
$ sudo $ sudo /etc/init.d/networking restart
[....] Restarting networking (via systemctl): networking.service
. ok
```

> Como la IP de la Raspberry Pi ha cambiado, la conexión remota desde tu equipo se perderá.
>
> Debes conectar de nuevo con la Raspberry Pi usando la IP que acabas de asignar.

### Encontrando tu Raspberry Pi en la red gracias a Avahi

Desde la versión 0.3 *Jack*, HypriotOS usa [Avahi](https://en.wikipedia.org/wiki/Avahi_(software)), el sistema que permite a los programas publicar y descubrir servicios y hosts en una red local. De esta forma puedes acceder a los servicios publicados por los contenedores vía web (o hacer un ping) usando el nombre del sistema: **`black-pearl`** (por defecto).

> He comprobado que funciona desde un equipo Mac; falta comprobarlo desde un equipo Windows.
