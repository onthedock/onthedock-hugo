+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/linux.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/

# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}
# YouTube           {{< youtube w7Ft2ymGmfc >}}
# Gist              {{< gist username 7896402 >}}
# Highlight         {{< highligth language >}}...{{< /highlight >}}
# Twitter           {{< tweet user="SanDiegoZoo" id="1453110110599868418" >}}

title=  "Ubuntu: Evita que un paquete se actualice con \"apt-mark hold\""
date = "2022-05-08T13:14:23+02:00"
+++
La solución para el [Error en Vagrant tras actualizar a Pop_Os! 22.04]({{< ref "post/220507-error-en-vagrant-tras-actualizar-a-pop-os-22-04.md" >}}) es la instalación de una versión concreta del software, en este caso, la 2.2.19.
<!--more-->

Sin embargo, esto no impide que al actualizar (`sudo apt update && sudo apt upgrade -y`) se instale de nuevo la versión *problemática* de Vagrant.

Para **fijar** la versión de un paquete y evitar que se actualice, usa el comando

```shell
$ sudo apt-mark hold vagrant
vagrant set on hold.
```

De esta forma, al alcualizar de nuevo el sistema, se muestra:

```shell
$ sudo apt upgrade
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
Calculating upgrade... Done
The following packages have been kept back:
  vagrant
0 to upgrade, 0 to newly install, 0 to remove and 1 not to upgrade.
```

Puedes consultar los paquetes que no se actualizan (*congelados*) mediante el comando:

```shell
apt-mark showhold
```

En el momento que quieras que se actualicen de nuevo, usa `sudo apt-mark unhold <nombre_paquete>`.
