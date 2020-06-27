+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "kvm", "ubuntu"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/linux.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" %}}

title=  "Creación de una máquina virtual en KVM con virsh"
date = "2020-06-27T17:35:24+02:00"
+++
En la entrada [Instalación de KVM en Ubuntu 20.04]({{< ref "200627-instalacion-de-kvm-en-ubuntu-20.04.md" >}}) instalamos KVM; ahora empieza lo divertido y vamos a crear una máquina virtual en KVM desde línea de comando con `virsh`.
<!--more-->

La utilidad de gestión de recursos virtuales desde línea de comandos es `virsh` (*virtualization shell*).

En primer lugar, comprobamos que no tenemos ninguna máquina virtual:

```bash
$ sudo virsh list
 Id   Name   State
--------------------
```

> Puedes consultar todos los parámetros usados en [virt-install(1) - Linux man page](https://linux.die.net/man/1/virt-install).

Para crear una máquina virtual, usamos el comando `virt-install` especificando las propiedades de la VM; por ejemplo:

```bash
sudo virt-install --name vm-test \
    --virt-type kvm --hvm --os-variant=ubuntu20.04 \
    --ram 1024 -vcpus 2 --network network=default \
    --graphics vnc,password=remotevnc,listen=0.0.0.0 \
    --disk pool=default,size=20,bus=virtio,format=qcow2 \
    --cdrom /home/xavi/Documents/isos/alpine-virt-3.12.0-aarch64.iso \
    --noautoconsole \
    --boot cdrom,hd

Starting install...
Allocating 'vmtest.qcow2'                                                         |  20 GB  00:00:00
Domain installation still in progress. You can reconnect to
the console to complete the installation process.
```

> Si no especificamos `--os-variant=${OperatingSystemID}` obtenedremos la alerta `WARNING  No operating system detected, VM performance may suffer. Specify an OS with --os-variant for optimal results.`. Más adelante indico cómo obtener una lista de los identificadores para cada sistema operativo soportado.

No todos los parámetros específicados son necesarios; he dividido el comando en diversas líneas en un intento por agruparlos por "categoría"; consulta lo que hace cada parámetro en la [documentación](https://linux.die.net/man/1/virt-install).

- `--virt-type kvm --hvm --os-variant=ubuntu20.04` KVM puede gestionar máquinas virtuales de diferentes tipos, por lo que aquí especificamos que queremos usar  `kvm`. `--hvm` permite usar toda la funcionalidad del hipervisor y con `--os-variant` habilitamos optimizaciones para el sistema opertivo indicado.
- `--ram 1024 -vcpus 2 --network network=default` Configuración de la VM a nivel "hierro": CPU, RAM, red...
- `--graphics vnc,password=remotevnc,listen=0.0.0.0` Probablmente con la configuración por defecto sea suficiente, pero en este caso he *apuntado* la posibilidad de configurar una contraseña para el acceso a la "consola gráfica" de la máquina virtual expuesta a través de VNC. Tanto con `virt-viewer` como con `virt-manager` se pregunta el password indicado antes de "conectar". Debes tener en cuenta que este password puede quedar registrado en los logs de KVM. Establecer un password para VNC no supone una medida de seguridad fuerte, pero sí que es un *nice to have*. La opción de poder especificar en qué IP escucha VNC puede ser útil para máquinas con múltiples tarjetas de red (posiblemente en redes diferentes).
- `--disk pool=default,size=20,bus=virtio,format=qcow2` Disco para la VM; en muchas referencias en internet en vez de usar un *storage pool* se indica el *path* al fichero, lo que también es una alternativa viable (y que permite especificar el nombre del fichero del "disco"). En el caso del *pool*, el disco se nombre a partir del valor de la VM (especificado en `--name`).
- `--cdrom /home/xavi/Documents/isos/alpine-virt-3.12.0-aarch64.iso` También puede usarse una referencia a un *pool*, pero en este caso apunto directamente a una ISO indicando la ruta completa.
- `--noautoconsole` Al crear la VM KVM lanza automáticamente la consola para acceder a la máquina recién creada; este parámetro lo impide.
- `--boot cdrom,hd` Orden de los dispositivos de arranque.

Una vez lanzado el comando, podemos validar que la máquina ha arrancado correctamente:

```bash
sudo virsh list
 Id   Name     State
------------------------
 1    vmtest   running
```

> He tenido problemas al arrancar la máquina con las ISOs de Alpine. El error (`Could not read from cdrom (Code 0009)`) parece estar relacionado con la ISO, por lo que la única solución parece ser cambiar de ISO; en mi caso, usando Ubuntu Server 20.04 no he tenido problemas.

Puedes conectar a la máquina virtual usando `sudo virt-viewer vmtest &`; si has especificado un password para VNC,deberás proporcionarlo antes de poder conectar con la VM.

## Conexión a la VM usando *virt-manager*

La gestión de las máquinas virtuales desde línea de comandos es muy adecuada para automatizar el proceso; sin embargo, para un entorno de pruebas tipo laboratorio, lo más sencillo es usar una herramienta gráfica como [Virtual Machine Manager](https://virt-manager.org/).

Aunque se usa principalmente para gestionar máquinas virtuales de KVM, también puede gestionar Xen y LXC (contenedores de Linux).

## Especificando `os-variant`

KVM puede optimizar la configuración del sistema operativo *guest* en la VM especificando el parámetro `--os-variant` (mira [VIRT-INSTALL(1)](https://manpages.debian.org/testing/virtinst/virt-install.1.en.html)).

Para obtener una lista de los identificadores de los diferentes sistemas operativos debes instalar el paquete `libosinfo-bin` en la máquina anfitrión con KVM:

```bash
sudo apt install libosinfo-bin
```

Consulta la lista de sistemas soportados mediante:

```bash
$ osinfo-query os
 Short ID             | Name                                               | Version  | ID
----------------------+----------------------------------------------------+----------+-----------------------------------------
 alpinelinux3.5       | Alpine Linux 3.5                                   | 3.5      | http://alpinelinux.org/alpinelinux/3.5  
 alpinelinux3.6       | Alpine Linux 3.6                                   | 3.6      | http://alpinelinux.org/alpinelinux/3.6  
 alpinelinux3.7       | Alpine Linux 3.7                                   | 3.7      | http://alpinelinux.org/alpinelinux/3.7
 ...
```

## Obtener IP de las máquinas virtuales

Con `virsh` puedes obtener la(s) IP(s) de la máquina virtual sin tener que conectarte a ella, ejecutar `ip addr show`, salir para conectar vía SSH desde tu equipo anfitrión.

El comando es `sudo virsh domifaddr vmtest`:

```bash
$ sudo virsh domifaddr vmtest
 Name       MAC address          Protocol     Address
-------------------------------------------------------------------------------
 vnet0      52:54:00:36:5a:0e    ipv4         192.168.122.240/24
```

> El comando parece mucho más críptico de lo que es; KVM denomina *domain* a la máquina virtual; de ahí que el comando en `virsh` para obtener la IP empiece por `dom`; el resto del comando es *el mismo* que usas para obtener la IP... (bueno, antes de que se cambiara a `ip address...`) En la Wikipedia puedes encontrar información sobre [ifconfig](https://en.wikipedia.org/wiki/Ifconfig).

Desde el equipo anfitrión puedes conectar vía SSH a la IP (aunque `virbr0` esté configurado como NAT):

```bash
$ ssh operador@192.168.122.240
operador@192.168.122.240's password:
Welcome to Ubuntu 20.04 LTS (GNU/Linux 5.4.0-39-generic x86_64)
...
```

## Resumen

Aunque hay **mucho** más por investigar y aprender con respecto a KVM, con la capacidad de poder crear máquinas y conectarse a ellas vía `virt-viewer` o `virt-manager` tienes la base de un entorno de pruebas sólido.
