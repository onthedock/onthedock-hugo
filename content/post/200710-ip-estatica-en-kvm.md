+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev", "ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "kvm"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/linux.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}

title=  "IP estática en KVM"
date = "2020-07-10T18:16:34+02:00"
+++

Las máquinas virtuales en KVM obtienen una IP en el rango `192.168.122.2` a `192.168.122.254` (puedes comprobarlo mediante `virsh net-edit default` (para la red *default*)).

Asignar una IP estática a una máquina virtual en KVM consiste en tres pasos:
<!--more-->
1. Asignar una IP a la *mac address* de la tarjeta de red de la VM en cuestión.
1. Modificar el rango de IP asignadas desde el DHCP.
1. Reiniciar la red -y la vm- para que los cambios tengan efecto.

## Reservar una IP (estática) para la máquina virtual

En vez de fijar una IP en la máquina virtual, reservamos una IP en el DHCP a través de la dirección *mac*. De esta forma, siempre se asigna la misma IP a la máquina virtual.

Para ello, necesitamos obtener la *mac address* de la máquina virtual.
Por ejemplo, mediante: `virsh dumpxml ${nombr-vm} | grep -i 'mac address'`

```bash
$ virsh dumpxml docker | grep -i 'mac address'
      <mac address='52:54:00:91:84:c4'/>
```

Anota la *mac address* porque la necesitaremos en los siguientes pasos.

## Modificar el rango de IPs de la red

Vamos a modificar el rango de IPs asignadas para la red *default*.

Lanza el comando `virsh net-edit default`:

```xml
<network>
  <name>default</name>
  <uuid>234020c3-b70a-457c-b9ac-16c9dd688920</uuid>
  <forward mode='nat'/>
  <bridge name='virbr0' stp='on' delay='0'/>
  <mac address='52:54:00:0a:4b:da'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.254'/>
    </dhcp>
  </ip>
</network>
```

Como puede verse en la salida del comando anterior, tenemos `range start='192.168.122.2' end='192.168.122.254'`. Es decir, cualquier IP valida entre 2 y 254, lo que no deja ningún "hueco" para poder fijar una IP sin que pueda asignarse -via DHCP- a una VM.

Modificando el `range start` o el `end`, hacemos "hueco" para dejar fuera del rango del DHCP tantas IPs como necesitemos.
En mi caso, he modificado el inicio del rango a `start='192.168.122.50'`.

A continuación añade una nueva línea para *reservar* una IP -del rango excluido del DHCP- para la *mac address* de la máquina virtual; en mi caso, he asignado la IP `192.168.122.2` con `<host mac='52:54:00:91:84:c4' name='docker' ip='192.168.122.2'/>`:

```xml
<ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.50' end='192.168.122.254'/>
      <host mac='52:54:00:91:84:c4' name='docker' ip='192.168.122.2'/>
    </dhcp>
  </ip>
```

Si quieres realizar múltiples reservas, simmplemente añade más líneas `<host mac='...` bajo la etiqueta `<range start='...`.

Una vez modificada la configuración de la red `default`, guarda los cambios y reinicia la red:

```bash
$ virsh net-destroy default && virsh net-start default
Network default destroyed

Network default started

$
```

> El comando [`virsh net-update`](https://wiki.libvirt.org/page/Networking#virsh_net-update) sólo permite añadir o eliminar rangos de IPs, no modificarlos.

Arranca la máquina virtual (o reinicia la red) para que la máquina virtual obtenga la IP asignada:

```bash
$ virsh start docker
Domain docker started

$ virsh domifaddr docker
 Name       MAC address          Protocol     Address
-------------------------------------------------------------------------------
 vnet0      52:54:00:91:84:c4    ipv4         192.168.122.2/24
```

Como puedes ver, la máquina obtiene la IP `192.168.122.2` que le hemos reservado.

Referencia: [KVM/libvirt: How to configure static guest IP addresses on the virtualisation host](https://serverfault.com/questions/627238/kvm-libvirt-how-to-configure-static-guest-ip-addresses-on-the-virtualisation-ho) en ServerFault.
