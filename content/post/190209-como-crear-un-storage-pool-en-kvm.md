+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["linux", "ubuntu", "kvm"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["ops"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/linux.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" %}}

title=  "Cómo crear un storage pool en KVM"
date = "2019-02-09T19:07:08+01:00"
+++

En KVM existe el concepto de _storage pool_, que como indica su nombre, es un recurso de almacenamiento.

En mi caso, todo el almacenamiento es local, por lo que voy a examinar el _pool_ existente y a continuación crearé un nuevo _storage pool_ para guardar las ISOs de instalación de los diversos sistemas operativos que utilice.

Al disponer únicamente del disco local como espacio de almacenamiento la creación de _storage pools_ adicionales sirve para separar los discos de las VMs (que dejaré en el _pool_ **default**) de las ISOs y de paso, aprender cómo funcionan los _storage pool_ en KVM ;)
<!--more-->

## *Storage pool* `default`

Empezamos listando los _pools_ existentes:

```bash
$ virsh pool-list
Name                 State      Autostart
-------------------------------------------
 default              active     yes
```

Examinamos con detalle este _pool_ creado por defecto por KVM:

```bash
$ virsh pool-info default
Name:           default
UUID:           2be211ef-6810-4f2d-b672-e72761696020
State:          running
Persistent:     yes
Autostart:      yes
Capacity:       468.45 GiB
Allocation:     10.74 GiB
Available:      457.71 GiB
```

Vemos que el _pool_ está en activo (_running_), que es persistente (sobrevive a los reinicios) y que arranca junto con KVM.

Podemos volcar la definición del _pool_ a XML mediante el comando `pool-dumpxml`:

```bash
$ virsh pool-dumpxml default
<pool type='dir'>
  <name>default</name>
  <uuid>2be211ef-6810-4f2d-b672-e72761696020</uuid>
  <capacity unit='bytes'>502994460672</capacity>
  <allocation unit='bytes'>11536527360</allocation>
  <available unit='bytes'>491457933312</available>
  <source>
  </source>
  <target>
    <path>/var/lib/libvirt/images</path>
    <permissions>
      <mode>0711</mode>
      <owner>0</owner>
      <group>0</group>
    </permissions>
  </target>
</pool>
```

En el fichero XML observamos la ruta donde se encuentra el _pool_ `/var/lib/libvirt/images` y los permisos definidos sobre esta ruta.

## *Storage pool* `isos`

Revisando la documentación [20.29.6. Creating, Defining, and Starting Storage Pools](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/virtualization_deployment_and_administration_guide/sect-managing_guest_virtual_machines_with_virsh-storage_pool_commands#sect-Storage_pool_commands-Creating_defining_and_starting_storage_pools) observamos que disponemos de varios comandos para crear un _pool_: `pool-create` y `pool-define`.

El comando `pool-create` crea y arranca un _storage pool_ **no persistente** (_transient storage pool_). Este tipo de _pool_ no guarda la definición del _pool_ en disco y se elimina al apagar KVM.

Para crear un _storage pool_ **persistente** usamos el comando `pool-define`. Este comando crea un fichero XML con la definición del _storage pool_ en `/etc/libvirt/storage`. (Referencia: [Unable to autostart storage pool](https://www.redhat.com/archives/libvirt-users/2010-August/msg00042.html)).

Podemos comprobar que la carpeta indicada contiene el fichero de definición del _pool_ `default`:

```bash
$ sudo ls /etc/libvirt/storage/
[sudo] password for operador:
autostart  default.xml
```

Examinando el fichero XML:

```bash
$ sudo cat /etc/libvirt/storage/default.xml
<!--
WARNING: THIS IS AN AUTO-GENERATED FILE. CHANGES TO IT ARE LIKELY TO BE
OVERWRITTEN AND LOST. Changes to this xml configuration should be made using:
  virsh pool-edit default
or other application using the libvirt API.
-->

<pool type='dir'>
  <name>default</name>
  <uuid>2be211ef-6810-4f2d-b672-e72761696020</uuid>
  <capacity unit='bytes'>0</capacity>
  <allocation unit='bytes'>0</allocation>
  <available unit='bytes'>0</available>
  <source>
  </source>
  <target>
    <path>/var/lib/libvirt/images</path>
  </target>
</pool>
```

Podemos crear el _storage pool_ desde línea de comandos o usando `virsh pool-define isos.xml` desde un fichero XML como:

```XML
<pool type="dir">
  <name>isos</name>
    <target>
      <path>/var/lib/libvirt/isos</path>
  </target>
</pool>
```

Desde la línea de comandos, crearíamos el _pool_ mediante:

```bash
$ sudo mkdir /var/lib/libvirt/isos
$ virsh pool-define-as isos --type dir --target /var/lib/libvirt/isos
Pool isos created
```

`pool-define` sólo crea el _pool_; podemos comprobarlo mediante:

```bash
$ virsh pool-list --all
Name                 State      Autostart
-------------------------------------------
default              active     yes
isos                 inactive   no
```

Para arrancarlo y hacer que autoarranque con KVM, usamos los comandos:

```bash
$ virsh pool-start isos
Pool isos started
$ virsh pool-start isos
Pool isos started
```

## Cómo añadir contenido al _pool_

Descargamos una imagen ISO y la copiamos al _pool_:

```bash
curl http://ftp.caliu.cat/debian-cd/9.6.0/amd64/iso-cd/debian-9.6.0-amd64-netinst.iso -o debian-9.6.0-amd64-netinst.iso
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  291M  100  291M    0     0  2480k      0  0:02:00  0:02:00 --:--:-- 2283k
$ sudo cp debian-9.6.0-amd64-netinst.iso /var/lib/libvirt/isos/
```

Al añadir contenido a un _storage pool_ es posible que no se muestre inmediatamente:

```bash
$ virsh vol-list isos
 Name                 Path
------------------------------------------------------------------------------
```

Actualizamos el contenido del _storage pool_ mediante el comando `pool-refresh`:

```bash
$ virsh pool-refresh isos
Pool isos refreshed

$ virsh vol-list isos
 Name                 Path
------------------------------------------------------------------------------
 debian-9.6.0-amd64-netinst.iso /var/lib/libvirt/isos/debian-9.6.0-amd64-netinst.iso
```

## Resumen

En esta entrada hemos examinado los comandos básicos para gestionar _storage pools_ en KVM.

Hemos visto cómo revisar los _pools_ existentes y obtener información de su estado y propiedades. También hemos visto cómo crear un nuevo _storage pool_ persistente.

Finalmente hemos descargado una ISO y la hemos añadido al _pool_ de ISOs recién creada.

En la siguiente entrada nos centraremos en los _vdisks_ donde almacenar el sistema operativo y los datos de las máquinas virtuales.