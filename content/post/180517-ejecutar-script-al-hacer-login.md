+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "automatizacion"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/linux.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" %}}

title=  "Ejecutar script al hacer login en el sistema"
date = "2018-05-17T08:00:35+02:00"
+++

Al hacer login en un sistema Ubuntu, se suele presentar información acerca de los paquetes disponibles para actualización y otra información relevante.

En esta entrada indico cómo conseguir el mismo resultado mostrando la información que te interesa sobre el sistema.
<!--more-->

En la entrada anterior [Transmission y Samba]({{<ref "180517-transmission-y-samba.md" >}}) hemos configurado un servidor para descargar ficheros de internet vía BitTorrent.

La interacción con el equipo se realizará en general a través del interfaz web de Transmission, por lo que los logins en el equipo serán muy esporádicos.

Sería interesante saber el estado de los discos y de Transmission al hacer login.

```shell
$ ssh operador@192.168.1.101
operador@192.168.1.101's password:
Welcome to Ubuntu 17.10 (GNU/Linux 4.13.0-41-generic i686)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

3 packages can be updated.
3 updates are security updates.

New release '18.04 LTS' available.
Run 'do-release-upgrade' to upgrade to it.

Last login: Wed May 16 22:09:31 2018 from 192.168.1.100
Disk usage
----------
/dev/sda1        37G  3.6G   31G  11% /
/dev/sdb1       110G   14G   91G  13% /samba

Transmission en ejecución.

$
```

# Creación del script

Creamos el script para mostrar la información que nos interesa.

```shell
touch monitor.sh
nano monitor.sh
```

La información de uso de los discos se obtiene mediante el comando `df`. Sin embargo, el resultado del comando muestra mucha más información de la que necesitamos.

Para filtrar la salida del comando, usaremos `grep`, de manera que sólo se muestre la información de las particiones en los discos físicos (`/dev/sda1` y `/dev/sdb1` en nuestro caso):

```shell
$ df -h | grep '/dev/sd'
/dev/sda1        37G  3.6G   31G  11% /
/dev/sdb1       110G   14G   91G  13% /samba
```

La información sobre si el proceso de Transmission está en ejecución la obtenemos mediante el comando `ps`.

Usamos `-u debian-transmission` para obtener los procesos ejecutados por este usuario y filtramos para encontrar el proceso `transmission-daemon`:

```shell
$ ps -u debian-transmission | grep transmission
5445 ?        00:09:22 transmission-da
```

> La salida del comando corta el nombre del proceso, por lo que sólo filtramos por `transmision` y no `transmission-daemon`.

Cuando el proceso esté parado, este comando no dará ningún resultado. Para poder distinguir el resultado, lo más sencillo es contar el número de caracteres de la salida del comando usando el comando `wc -c`.

Usando estos comandos en el script:

```shell
#!/bin/sh
DISK_USAGE=$(df -h | grep /dev/sd)
TRANSMISSION=$(ps -u debian-transmission | grep transmission | wc -c)

echo  "Disk usage\n----------\n$DISK_USAGE"

if [ $TRANSMISSION -eq 0 ]; then
  echo "\033[0;31m********************\nTransmission parado!\n********************\033[0m"
else
  echo "\nTransmission en ejecución.\n"
fi
```

> Los códigos `\033[0;31m` y `\033[0m` son para cambiar el color de la salida por consola.

# Ejecución del script en el login

Para que el script se ejecute al iniciar una sesión interactiva (al hacer login), añadimos el comando al final del archivo `~/.profile`.

En primer lugar, lo convertimos en ejecutable con `chmod +x monitor.sh`.

Editamos el fichero `~/.profile` y añadimos el script al final:

```shell
...
# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

./monitor.sh
```
