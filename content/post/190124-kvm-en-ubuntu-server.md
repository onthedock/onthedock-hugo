+++
draft = false

categories = ["ops"]
tags = ["linux", "ubuntu", "kvm"]
thumbnail = "images/linux.png"

title=  "KVM en Ubuntu Server"
date = "2019-01-24T20:11:23+01:00"
+++

KVM es un módulo de virtualización que permite al kernel de Linux funcionar como hipervisor. Al formar parte del kernel de Linux, no requiere un entorno de escritorio. Esto permite reducir el _peso extra_ del sistema, pero también supone un reto a la hora de gestionar las máquinas virtuales.

<!--more-->

KVM es un hipervisor desarrollado originalmente por Qumranet, una starup que más tarde fue adquirida por RedHat. KVM usa una versión modificada de QEMU como _front-end_. El uso de QEMU -asociado al mal recuerdo del rendimiento que obtuve con QEMU en el pasado- me habían mantenido alejado de KVM hasta que hace un par de semanas decidí darle una oportunidad.

Mi objetivo era convertir el laboratorio casero a un entorno 100% linux, eliminando Hyper-V como hipervisor. Estuve dando vueltas a la idea de volver a Xen, e incluso me tentó la opción de usar una distribución de escritorio y optar por la vía Vagrant/VirtualBox. Al final decidí salir completamente de mi zona de confort y empezar con algo desconocido como KVM.

Amazon empezó a migrar en 2017 toda su infraestructura a [Nitro](https://aws.amazon.com/es/ec2/faqs/#ec2-hypervisor), basado en KVM así que aprender cómo funciona KVM también me serviría en mi avance hacia obtener un conocimiento profundo del _cloud_ a todos los niveles.

## Firmware Bug

Al intentar instalar Ubuntu Server 18.04.1, me topé con el siguiente mensaje:

```bash
...
[Firmware Bug]: AMD-Vi: IOAPIC[0] not in IVRS table
[Firmware Bug]: AMD-Vi: No southbridge IOAPIC found
AMD-Vi: Disabling interrupt remapping
...
```

El error se produce al arrancar el instalador de Ubuntu; la pantalla se queda en negro y el equipo se reinicia. A continuación el equipo se queda congelado en la pantalla de POST.

Encontré información relativa al error en múltiples sitios de internet (como por ejemplo [IOAPIC[0] not in IVRS table](https://superuser.com/questions/1052023/ioapic0-not-in-ivrs-table)), pero incluso tras haber actualizado la BIOS a la última versión disponible en la web del fabricante, seguía obteniendo el mismo error.

A partir de aquí estuve probando varias distribuciones, como Xubuntu, que pude instalar sin problemas. Pero los tutoriales que seguía para instalar KVM hacían referencia a otras distribuciones "de servidor", por lo que me sentía remando a contracorriente y dedicando mucho más tiempo del necesario para instalar el hipervisor y configurar la tarjeta de red en modo _bridge_.

Antes de darme por vencido, decidí probar con otra distribución "de servidor"; descargué e instalé CentOS 6 sin problemas. Aunque al arrancar el proceso de instalación se mostraba el error, la instalación continuaba permitiendo instalar el sistema operativo con normalidad.

No estoy demasiado familizarizado con distros basadas en RPM (como CentOS/RHEL), pero la documentación (y Google) me ayudaron a ir solucionando todas las dudas que surgían. Después de leer en múltiples sitios que la actualización de versión _major_ de CentOS es complicada (y que se recomienda instalar desde 0), decidí que ya que me ponía, lo haría con CentOS 7 (y así me ahorraba el problema de actualizar en el futuro).

Sin embargo, la instalación de CentOS 7 ya no es en modo texto, sino de forma gráfica. Y fue así, buscando la forma de lanzar la el instalador en modo texto cuando descubrí que podía usar las opciones de configuración para "forzarlo" y continuar con la instalación pese al fallo del instalador en modo gráfico.

Aunque finalmente instalé CentOS 7, decidí darle una nueva oportunidad a Ubuntu Server usando el "truco" del instalador en modo texto ([BootOptions](https://help.ubuntu.com/community/BootOptions)). Así, después de mucho ensayo y error, finalmente conseguí instalar Ubuntu Server 18.04.1 LTS (Bionic Beaver).

> El error sigue apareciendo en los logs, pero no afecta -hasta donde he podido comprobar- el funcionamiento del sistema.

## Configurar la red _bridge_

Quiero que las máquinas virtuales gestionadas por KVM formen parte de la red local de casa (sin pasar por un NAT); para ello necesitamos configurar una red _bridge_.

En Ubuntu Server 18.04 la configuración de red se realiza mediante NetPlan.

Editamos el fichero: `/etc/netplan/50-cloud-init.yaml`, que inicialmente es:

```yaml
network:
    ethernets:
        enp1s0:
            addresses: []
            dhcp4: true
    version: 2
```

Eliminamos la configuración automática de la tarjeta de red mediante DHCP y añadimos un _bridge_:

> Es recomendable realizar la configuración de forma local, ya que al aplicar los cambios, el equipo cambia de dirección de IP y se pierde la conexión vía SSH.

```yaml
network:
  ethernets:
    enp1s0:
      dhcp4: false
      dhcp6: false
  version: 2

  bridges:
    br0:
      interfaces: [enp1s0]
      dhcp4: false
      dhcp6: false
      addresses: [192.168.1.2/24]
      gateway4: 192.168.1.1
      nameservers:
        addresses: [1.1.1.1, 8.8.8.8]
```

Guardamos el fichero y aplicamos los cambios mediante:

```bash
sudo netplan apply
```

Tras aplicar los cambios, comprobamos que se ha creado un nuevo interfaz de red con la IP especificada:

```bash
$ ip address show
[...]
2: enp1s0:  mtu 1500 qdisc fq_codel master br0 state UP group default qlen 1000
    link/ether d8:cb:8a:36:aa:43 brd ff:ff:ff:ff:ff:ff
3: br0:  mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 42:56:eb:da:b2:35 brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.2/24 brd 192.168.1.255 scope global br0
       valid_lft forever preferred_lft forever
    inet6 fe80::4056:ebff:feda:b235/64 scope link
       valid_lft forever preferred_lft forever
```

## Instalar KVM

### Comprobar soporte de virtualización

La manera más sencilla de comprobar si nuestro equipo soporta virtualización es:

```bash
$ lscpu | grep -i virtualization
Virtualization:      AMD-V
```

## Instalar paquetes KVM

> No vamos a instalar _Virtual Machine Manager_ (_virt-manager_) ya que la gestión de las máquinas virtuales la realizaremos desde un equipo de administración y no desde el host de virtualización.

```bash
sudo apt update
sudo apt install qemu qemu-kvm libvirt-bin  bridge-utils
```

Habilitamos y arrancamos el servicio `libvirtd`:

```bash
$ sudo systemctl enable libvirtd
Synchronizing state of libvirtd.service with SysV service script with /lib/systemd/systemd-sysv-install.
Executing: /lib/systemd/systemd-sysv-install enable libvirtd
$ sudo systemctl start libvirtd
$
```

## Ready to go!

Aunque la aplicación base ya está instalada, todavía no hemos creado ninguna máquina virtual; a partir de aquí tenemos dos opciones:

- Instalación de `virtinstall` y realizar la creación de VMs desde la línea de comando (en el propio _host_)
- Instalar Virtual Machine Manager en un _equipo de administración_ y realizar la gestión de las máquinas de forma remota.

Mi objetivo es realizar una gestión de las VMs lo más desatendida posible; para ello quiero poder gestionar todas las operaciones a realizar sobre las  máquinas virtuales desde la línea de comandos o desde scripts, en remoto.

> Para realizar la instalación desde la ISO del fabricante del sistema operativo he creado la máquina localmente, pero para completar todos los pasos de configuración desde el instalador he usado Virtual Machine Manager desde el equipo remoto.

### `virtinstall`

Usando `virt-install` puedes lanzar una nueva máquina desde línea de comando mediante:

```bash
virt-install --name userver --vcpus 1 --memory 2048 --cdrom /var/lib/libvirt/images/ubuntu-server-18.04.1-amd64.iso --disk size=10 --network bridge:br0
```

Esta máquina tiene 1 vPUD, 2GB de RAM, un disco de 10GB y está conectada a la red _bridge_ `bridge:br0`; la ISO de instalación de Ubuntu Server está conectada a la unidad virtual de CDROM de la VM.

> Para realizar la configuración del sistema operativo mediante el instalador, necesitas una máquina con entorno gráfico.

## Virtual Machine Manager

Virtual Machine Manager es un gestor de máquinas virtuales para hipervisores compatbles; entre ellos, KVM.

Además de gestionar máquinas de forma local, podemos conectarnos con hipervisores remotos. En este caso, si el usuario tiene los permisos adecuados, puede crear nuevas máquinas en el equipo remoto.

Para que la máquina virtual tenga acceso a la red _bridge_ debemos especificar en la configuración de red el nombre de la red _bridge_ definida en pasos anteriores:

{{% img src="images/190124/VMM-NETWORK-Conf-2019-01-23 20-07-07.png"  %}}

# Siguientes pasos

Esta entrada no es más que unas notas "pasadas a limpio" sobre el proceso de instalación y configuración de KVM sobre Ubuntu Server 18.04.

La instalación se realiza con los paquetes mínimos y sin incluir, al menos inicialmente, `virtinstall`. Más adelante fue necesario instalarlo para poder crear una máquina virtual "desde cero".

También se describe cómo configurar una red _bridge_ de manera que las máquinas virtuales sobre KVM tengan acceso -y sean accesibles- a la red local sin tener que usar NAT.

Desde un equipo remoto he usado Virtual Machine Manager para gestionar la instalación de una máquina creada desde línea de comando usando `virsh`.

Quiero seguir avanzando en reducir la necesidad de instalar paquetes adicionales -como `virtinstall`- en el equipo _host_. Una opción puede ser disponer de imágenes base con Cloud-Init; clonar el disco y pincharlo en la nueva VM para que se autoconfigure durante el primer arranque usando la configuración contenida en el `user-data`. Otra opción es usar el comando `virsh create $fichero.xml` o quizás incluso usando una "consola" mediante `virt-install`...

En resumen, sólo he empezado a descubrir las posibilidades que ofrece KVM como hipervisor.