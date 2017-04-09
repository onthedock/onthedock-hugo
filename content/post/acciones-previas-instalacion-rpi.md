+++
date = "2017-04-09T21:34:16+02:00"
title = "Acciones previas a la instalación de Kubernetes en Raspberry Pi"
tags = ["raspberry pi", "hypriot os", "kubernetes"]
draft = false
thumbnail = "images/raspberry_pi.png"
categories = ["ops"]

+++

Uno de los objetivos motivadores de la existencia de este blog es instalar un clúster de Kubernetes sobre Raspberry Pi. Este artículo se centra en las tareas previas a la instalación en sí.

Kubernetes requiere una instalación previa de Docker, una tarea simplificada gracias a HypriotOS, la _distro_ creada específicamente con este fin.

El siguiente paso, la instalación de Kubernetes en la Raspberry será objeto de otra(s) entrada(s). Pero sin duda esta tarea sería mucho más complicada sin las contribuciones del joven finlandés [Lucas Käldström](https://www.cncf.io/blog/2016/11/29/diversity-scholarship-series-programming-journey-becoming-kubernetes-maintainer/) y su proyecto -ahora integrado la rama principal- [Kubernetes on ARM](https://github.com/luxas/kubernetes-on-arm).

<!--more-->

* Descarga la imagen de [HypriotOS](https://blog.hypriot.com/downloads/).
* Traspásala a una tarjeta microSD usando, por ejemplo, [Etcher](https://etcher.io/)
* Inserta la tarjeta microsSD en la Raspberry Pi y arranca la RPi.
* Comprueba que ha arrancado correctamente haciendo ping a `black-pearl.local`
* Accede a la RPi mediante `ssh pirate@black-pearl.local`
* Acepta el mensaje de seguridad (es la primera vez que conectas al equipo)
* Edita el fichero `/boot/device-init.yaml` para modificar el nombre de la RPi. En mi caso, he cambiado el nombre a `k1`: `hostname: k1`
* Crea un backup del fichero de configuración de la tarjeta de red: `sudo cp /etc/network/interfaces.d/eth0 /etc/network/interfaces.d/eth0.original`
* Edita el fichero `/etc/network/interfaces.d/eth0` para establecer una IP estática para la RPi:

  ```shell
  allow-hotplug eth0
  iface eth0 inet static
	address 192.168.1.11
	gateway 192.168.1.1
  ```

* Reinicia la RPi para que los cambios sean efectivos: `sudo reboot`
* Comprueba que la RPi responde a ping con el nuevo nombre: `ping k1.local`
* Accede a la RPi mediante `ssh pirate@k1.local`
* Actualiza la RPi: `sudo apt-get update && sudo apt-get upgrade -y`
* Verifica la versión de Docker instalada: `$ docker version`
