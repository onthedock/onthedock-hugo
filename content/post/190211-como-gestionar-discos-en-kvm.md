+++

# CATEGORIES = "dev" / "ops"
categories = ["ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "ubuntu", "kvm"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/linux.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" %}}

title=  "Cómo gestionar discos en KVM"
date = "2019-02-11T19:31:08+01:00"
+++
Una vez creados los _storage pools_ llega el momento de empezar a llenarlos con discos.

En la [entrada anterior]({{< ref "190209-como-crear-un-storage-pool-en-kvm.md" >}}) hemos visto cómo añadir una imagen ISO al _pool_ que hemos creado para los medios de instalación.

Ahora vamos a crear discos para las máquinas virtuales.

<!--more-->

# Crear discos en KVM

Para crear un disco (un _volumen_), usamos el comando `vol-create-as`, indicando el _pool_ donde vamos a almacenarlo, el nombre del disco y su tamaño:

```bash
$ virsh vol-create-as default vdisk-b12447 10G
Vol vdisk-b12447 created
```

Comprobamos que el disco se ha creado:

> Un gran número de comandos admiten el parámetro `--details`, que muestra información adicional en la salida del comando.

```bash
$ virsh vol-list default --details
 Name          Path                                  Type   Capacity  Allocation
---------------------------------------------------------------------------------
 vdisk-b12447  /var/lib/libvirt/images/vdisk-b12447  file  10.00 GiB   10.00 GiB
```

KVM soporta diferentes tipos de discos; por defecto `vol-create-as` crea el disco en formato `raw`. El formato `raw` proporciona mejor rendimiento que `qcow2` ya que no se aplica ningún formato a las imágenes de los discos (pero todo el almacenamiento debe provisionarse de entrada).

El formato `qcow2` es el formato nativo de KVM y usa _copy on write_. De esta forma se desacopla la capa física de almacenamiento de la capa lógica y los bloques físicos. (Referencia: [2.4. Storage Formats for Virtual Machine Disk Images](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Virtualization/3.5/html/Technical_Guide/QCOW2.html))

Para crear un disco en formato `qcow2`, debemos especificarlo durante la creación del disco:

```bash
$ virsh vol-create-as --pool default --format qcow2 vdisk-u39572.qcow2 10G
Vol vdisk-u39572.qcow2 created
```

A diferencia de los discos `raw`, el espacio de los discos `qcow2` crece a medida que se necesita:

```bash
$ virsh vol-list default --details
 Name                Path                                        Type   Capacity  Allocation
---------------------------------------------------------------------------------------------
 vdisk-b12447        /var/lib/libvirt/images/vdisk-b12447        file  10.00 GiB   10.00 GiB
 vdisk-u39572.qcow2  /var/lib/libvirt/images/vdisk-u39572.qcow2  file  10.00 GiB  196.00 KiB
```

Como vemos, aunque los dos discos tienen una capacidad de 10GB, el disco en formato `qcow2` consume sólo 196KB en disco, a diferencia del disco en formato `raw`, que consume en disco los 10GB.

## Clonar discos

Otra operación habitual a realizar con los discos es clonarlos (por ejemplo, para hacer copias de una _machine image_ que sirve de base para crear máquinas homogéneas).

Para clonar un disco, especificamos el _pool_, el nombre del disco a clonar y el nombre del disco clonado:

```bash
$ virsh vol-clone --pool default vdisk-u39572.qcow2 vdisk-cloned-disk.qcow2
Vol vdisk-cloned-disk.qcow2 cloned from vdisk-u39572.qcow2
```

Al finalizar el clon, comprobamos que tenemos un disco adicional en el _pool_ `default`: `vdisk-cloned-disk.qcow2`

```bash
$ virsh vol-list default --details
 Name                     Path                                             Type   Capacity  Allocation
------------------------------------------------------------------------------------------------------
 vdisk-b12447             /var/lib/libvirt/images/vdisk-b12447             file  10.00 GiB   10.00 GiB
 vdisk-cloned-disk.qcow2  /var/lib/libvirt/images/vdisk-cloned-disk.qcow2  file  10.00 GiB  196.00 KiB
 vdisk-u39572.qcow2       /var/lib/libvirt/images/vdisk-u39572.qcow2       file  10.00 GiB  196.00 KiB
```

El problema es que al clonar el disco se crea una copia exacta del mismo. Si hemos instalado el sistema operativo, el nuevo disco contienen los mismos identificadores de máquina, la misma configuración de red (incluyendo las mismas direcciones MAC para las tarjetas de red), etc...

En la siguiente entrada usaremos `virt-clone` para realizar clones de máquinas virtuales completas. También usarmeos `virt-sysprep` "generalizar" las máquinas clonadas.