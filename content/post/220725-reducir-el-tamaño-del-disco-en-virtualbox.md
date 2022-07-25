+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "virtualbox"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/virtualbox.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/

# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}
# YouTube           {{< youtube w7Ft2ymGmfc >}}
# Gist              {{< gist username 7896402 >}}
# Highlight         {{< highligth language >}}...{{< /highlight >}}
# Twitter           {{< tweet user="SanDiegoZoo" id="1453110110599868418" >}}

title=  "Reducir el tamaño del disco en VirtualBox"
date = "2022-07-25T20:24:20+02:00"
+++
Los discos dinámicos en VirtualBox crecen automáticamente a medida que aumentan los datos que se guardan... Sin embargo, el tamaño no decrece aunque borremos ficheros. Esto significa que aunque el fichero del disco de una máquina virtual ocupe, en el sistema anfitrión, 50GB, por ejemplo, gran parte de esos 50GB pueden estar vacíos...

En esta entrada indico los pasos a seguir para reducir el tamaño del fichero del disco, eliminando todo ese [*espacio desaprovechado*](https://www.imdb.com/title/tt0118884/quotes/qt0379383).
<!--more-->
## Causa del problema: crecer automáticamente sí, ¿reducir el tamaño automáticamente no 🤔?

VirtualBox no puede reducir el tamaño del disco automáticamente porque, aunque hayamos borrado datos y ficheros, en realidad, lo que hace el sistema operativo es "quitarlos del índice" que indica dónde está cada fichero... Pero los datos siguen estando en el disco, solo que no sabemos dónde (en eso se basan las herramientas de recuperación de ficheros borrados).

En nuestro caso, VirtualBox no puede distinguir, examindo los datos en el disco, un fragmento con información de un fichero que nos interesa de otro que hemos borrado (pero que sigue ahí). Así que el primer paso es usar una herramienta como [`zerofree`](https://manpages.ubuntu.com/manpages/xenial/man8/zerofree.8.html) en Linux o [`sdelete.exe`](https://docs.microsoft.com/en-us/sysinternals/downloads/sdelete) en Windows.

Estas herramientas sobreescriben el espacio en disco que no contiene ficheros "activos" (es decir, ficheros que han sido borrados).

Imagina que la cadena `asdaeevsviosdfxxfsiofadsf` representa el fichero de disco de una máquina virtual. Los ficheros -de sistema o de usuario- se representan con vocales, mientras que el resto de letras corresponden a ficheros borrados. Al ejecutar `zerofree`, todas las consonantes (los *restos* de ficheros borrados) se sustituyen por `0`: `a00aee000io0000000io0a000`.

Como sólo el sistema operativo sabe qué partes del disco corresponden a ficheros "activos", `zerofree` (o `sdelete.exe`) se deben ejecutar desde *dentro* de la máquina virtual.

Una vez que VirtualBox es capaz de distinguir los fragmentos del disco que contienen datos *de verdad* de los que sólo contienen ceros (gracias al trabajo de `zerofree` o `sdelete.exe`), podemos reducir el tamaño del fichero de disco de la máquina virtual.

Esta segunda parte del proceso se realiza mediante la herramienta [`VBoxManage.exe`](https://www.virtualbox.org/manual/ch08.html#vboxmanage-modifymedium) de VirtualBox.

## Instrucciones

### Montar el dispositivo en modo de sólo lectura

Para que `zerofree` pueda modificar el disco de forma segura, es necesario que el sistema de ficheros esté *montado* en modo de *sólo lectura*. Para ello, en la pantalla de arranque del sistema operativo (en Linux), pulsa `ESC` hasta que se muestre el menú de GRUB y selecciona la opción de arrancar en *modo de recuperación* o *Recovery Mode*; las instrucciones para Ubuntu se encuentran en [RecoveryMode](https://wiki.ubuntu.com/RecoveryMode).

En el modo de recuperación, selecciona la opción `root` para tener acceso a la consola con el usuario `root`:

{{< figure src="/images/220725/root_recovery.png" width="650" height="300" >}}

> En las guías que he consultado, el sistema de ficheros *debería* estar montado en modo de sólo lectura, pero en mi caso no ha sido así. Por ello, incluyo los pasos adicionales que he tenido que seguir para conseguir montar `/` en modo `ro`.

Para conseguir montar el sistema de ficheros en modo de lectura, he tenido que detener los servicios `systemd-journal*` y deshabilitar la *swap* mediante:

```shell
systemctl stop systemd-journal*
swapoff -a
```

Identifica qué *desmontar* ejecutando `df` y mirándo en qué dispositivo se encuentra la raíz del sistema de ficheros `/`.

Ahora sí, ya puedo volver a montar el sistema de ficheros en modo de sólo lectura con:

```shell
mount -o remount,ro /dev/sda1
```

### Ejecutar `zerofree`

Ejecutamos `zerofree` sobre el dispositivo:

```shell
zerofree -v /dev/sda1
```

Tras unos minutos, `zerofree` habrá sobrescrito todos los ficheros borrados que todavía hubiera en el disco con `0`.

Al finalizar, apaga la máquina virtual.

### Reducir el tamaño del fichero del disco

La herramienta `VBoxManage.exe` se  encuentra en la carpeta de instalación de VirtualBox. Navega hasta la carpeta y ejecuta:

```shell
c:\Program Files\Oracle\VirtualBox\VBoxManage.exe list hdds
```

Este paso no es necesario, pero ayuda a indentificar cuál es el disco que quieres *encoger*; la salida del comando indica la ubicación de los discos de las diferentes máquinas virtuales en tu equipo.

Una vez identificada la ruta al fichero del disco, ejecuta el siguiente comando (por supuesto, el nombre y la ubicación de tu disco será diferente):

```shell
c:\Program Files\Oracle\VirtualBox\VBoxManage.exe modifymedium disk d:\VMs\vm-02\vm-02-hdd-1.vdi --compact
```

Y en unos cuantos minutos, ¡el tamaño del fichero que representa el disco se habrá reducido!

En mi caso, en un par de máquinas similares, la reducción de tamaño ha sido aproximadamente de un 50%, aunque la reducción conseguida depende de los ficheros existentes en cada disco, así que *your mileage may vary*, como dicen los anglosajones...

## Resumen

Las actualizaciones de paquetes, las descargas de ficheros o simplemente la *cache* del navegador escriben en el disco de la VM haciendo que aumente su tamaño constantemente. Al cabo del tiempo -y en función del tamaño del disco o partición en el que se encuentra la VM- este incremento de tamaño puede resultar problemático.

Los pasos a seguir para disminuir el tamaño del disco de una máquina virtual no son complicados, pero suponen un pequeño incordio con el que es necesario lidiar de vez en cuando... Y claro, de una vez para otra nunca recuerdo el proceso exacto.

Así que esta entrada es un recordatorio para mi *yo del futuro* sobre qué hacer cuando el disco del portátil vuelva a quedarse prácticamente sin espacio 😉
