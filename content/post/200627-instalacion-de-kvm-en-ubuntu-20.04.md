+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev", "ops"]
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

title=  "Instalación de KVM en Ubuntu 20.04"
date = "2020-06-27T16:27:29+02:00"
+++
Después de convertir el equipo de laboratorio en mi equipo de escritorio, poco a poco lo estoy convirtiendo de nuevo en un **equipo de laboratorio** :D

Después del desagradable sabor de boca con [GNOME Boxes](https://wiki.gnome.org/Apps/Boxes) que me dejó mi [efímera prueba en Fedora]({{<ref "200620-odiando-fedora-en-menos-de-1-hora.md" >}}), he recuperado el entorno basado en KVM (aunque no tuviera éxito con Proxmox VE).

En esta entrada describo los pasos seguidos para instalar KVM en Ubuntu 20.04 con las notas que he ido tomando durante el proceso.
<!--more-->

[KVM](https://www.linux-kvm.org/page/Main_Page) es un hipervisor de tipo 1 implementado como un módulo del Kernel de Linux que usa las extensiones de virtualización de los procesadores modernos.
Esto permite que las máquinas virtuales user la CPU de manera directa, lo que minimiza la penalización de rendimiento que inflinge la virtualización.
Para el sistema operativo, cada máquina virtual es un proceso de Linux.

## Comprobación de las capacidades de virtualización del procesador

Para comprobar si el procesador dispone de las extensiones de virtualización, revisa el contenido del fichero `/proc/cpuinfo` en busca de `vmx` (para Intel) o `svm` para AMD.

```bash
cat /proc/cpuinfo | egrep 'vmx|svm'
```

## Instalación

Empezamos con la instalación de los paquetes relacionados con KVM:

```bash
sudo apt install qemu-kvm libvirt-clients libvirt-daemon-system bridge-utils virtinst libvirt-daemon virt-manager virt-viewer
```

Una vez finalice la instalación de los paquetes, comprueba que `librvirtd` ha arrancado automáticamente:

```bash
sudo systemctl status libvirtd
● libvirtd.service - Virtualization daemon
     Loaded: loaded (/lib/systemd/system/libvirtd.service; enabled; vendor preset: enabled)
     Active: active (running) since Fri 2020-06-26 20:23:46 CEST; 3min 45s ago
TriggeredBy: ● libvirtd-ro.socket
             ● libvirtd-admin.socket
             ● libvirtd.socket
...
```

Otra forma de comprobar que la instalación de KVM ha sido un éxito es usando el comando `kvm-ok`:

```bash
$ sudo kvm-ok
INFO: /dev/kvm exists
KVM acceleration can be used
```

### Revisión de la configuración de red

Por defecto, KVM crea un *virtual switch* llamado `virbr0` que podemos ver mediante el comando `ip address show virbr0`:

```bash
$ ip address show virbr0
4: virbr0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default qlen 1000
    link/ether 52:54:00:0a:4b:da brd ff:ff:ff:ff:ff:ff
    inet 192.168.122.1/24 brd 192.168.122.255 scope global virbr0
       valid_lft forever preferred_lft forever
```

`virbr0` funciona en modo NAT, lo que permite a las máquinas virtuales la comunicación *hacia fuera* (hacia el anfitrión e internet) pero sólo conexiones entrantes desde el equipo anfitrión (y máquinas en la misma subred).

Usando la utilidad `virsh` podemos revisar las redes disponibles para las máquinas virtuales:

```bash
l$ sudo virsh net-list --all
Name      State    Autostart   Persistent
--------------------------------------------
default   active   yes         yes
```

> Creación de un *linux bridge* (`br0`) para las máquinas virtuales: podemos crear un *bridge* para conectar la NIC física con un interfaz de tipo *puente*, de manera que las máquinas virtuales estarían conectadas en la misma red que el equipo anfitrión, recibiendo IPs del DHCP de la red, etc... Puedes revisar el proceso en el paso 4 del artículo [How to Install KVM on Ubuntu 20.04 LTS Server (Focal Fossa)](https://www.linuxtechi.com/install-kvm-on-ubuntu-20-04-lts-server/).

## Configuración del almacenamiento

El *storage-pool* por defecto se encuentra en `/var/lib/libvirt/images/`. Sin embargo, si tenemos un disco dedicado donde almacenar las imágenes nos puede interesar crear una nueva *storage pool*, por ejemplo, en `/data/kvm/pool`:

```bash
$ sudo virsh pool-list --all
 Name      State    Autostart
-------------------------------
 default   active   yes

$ virsh pool-define-as kvmpool --type dir --target /data/kvm/pool
Pool kvmpool defined

$ virsh pool-start kvmpool
$ virsh pool-autostart kvmpool

$ virsh pool-list --all
 Name                 State      Autostart
-------------------------------------------
 default              active     yes
 kvmpool              active     yes
```

Puedes revisar el espacio disponible mediante:

```bash
l$ sudo virsh pool-list --details
 Name      State     Autostart   Persistent   Capacity     Allocation   Available
------------------------------------------------------------------------------------
 default   running   yes         yes          878,70 GiB   9,02 GiB     869,68 GiB
```

> En mi escenario actual tengo espacio suficiente en el disco *de sistema*, pero nunca está de más dejar la puerta abierta para añadir nuevas *storage pool* en el futuro... Probablemente vuelva a una situación como la del artículo [Cómo crear un storage pool en KVM]({{<ref "190209-como-crear-un-storage-pool-en-kvm.md" >}}), con una *storage pool* dedicada a las ISOs.

Como ves, la instalación de KVM no tiene ninguna complicación.

En la siguiente entrada creo una máquina virtual desde línea de comandos (usando `virsh`),