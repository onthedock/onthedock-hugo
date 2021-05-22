+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "transmission", "samba"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/linux.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}

title=  "Transmission y Samba"
date = "2018-05-16T23:09:43+02:00"
+++

En esta entrada algo _offtopic_ indico cómo instalar y configurar un equipo para descargar ficheros en formato `torrent` usando [Transmission](http://transmissionbt.com/).

Los ficheros descargados se comparten vía [Samba](https://www.samba.org) para el resto de equipos de casa (linux, Mac y Windows).
<!--more-->

Tengo un equipo en casa que uso para descargar ficheros de internet usando BitTorrent. Hasta ahora, el equipo -un viejo Optiplex GX 260- ejecutaba Windows 7 con 2 Gb de memoria. El equipo iba _extremadamente lento_, por lo que hacía tiempo que me rondaba por la cabeza instalar Linux y Transmission en modo _headless_.

# Instalación del sistema operativo

El equipo es 32 bits, de manera que he tenido que instalar Ubuntu Server 17.10, al ser la última versión de 32 bits ofrecida por [Canonical](http://releases.ubuntu.com/artful/).

Durante la instalación, he seleccionado únicamente la opción de instalar el servidor OpenSSH.

## Configuración de IP fija

El método para configurar la red se cambió en Ubuntu 17.10, pasando a utilizar [NetPlan](https://netplan.io).

NetPlan permite configurar la red a través de ficheros _yaml_ en `/etc/netplan/*.yaml`.

En primer lugar, hacemos una copia de srguridad:

```shell
sudo cp /etc/netplan/01-netcfg.yaml /etc/netplan/01-netcfg.yaml.original
```

Editamos el fichero y lo cambiamos por:

```shell
# This file describes the network interfaces available on your system
# For more information, see netplan(5).
network:
 version: 2
 renderer: networkd
 ethernets:
   ens33:
     dhcp4: no
     addresses: [192.168.1.101/24]
     gateway4: 192.168.1.1
     nameservers:
       addresses: [1.1.1.1,1.0.0.1]
```

> Usamos los DNS de CloudFlare.

Al finalizar, guardamos los cambios y aplicamos mediante `sudo netplan appy`. Los cambios tienen efecto inmediatamente.

## Automontaje del disco de datos

El equipo de descargas tiene dos discos: uno para el sistema (`/dev/sda`) y otro para los ficheros descargados (`/dev/sdb`).

Al tratarse de un disco _reutilizado_, uso `sudo fdisk /dev/sab` para eliminar las particiones existentes en el disco. He creado una nueva partición primaria de tipo Linux.

A continuación, creamos el sistema de ficheros formateando el disco `sudo mkfs.ext4 /dev/sdb1`. Una vez ha finalizado el formateo, reiniciamos el equipo.

Antes de modificar el fichero `/etc/fstab`, hacemos una copia de seguridad:

```shell
sudo cp /etc/fstab /etc/fstab.original
```

Obtenemos el UUID del segundo disco mediante el comando _blkid_:

```shell
$ sudo blkid
/dev/sda1: UUID="6ceae456-bfba-433c-94e0-b09ec8e29f00" TYPE="ext4" PARTUUID="f561a758-01"
/dev/sdb1: UUID="22432f7a-a810-482f-9836-2179ebf47493" TYPE="ext4" PARTUUID="25f625f5-01"
```

Creamos el punto de montaje: `sudo mkdir /samba`.

Creamos la entrada en el fichero `/etc/fstab`:

```shell
...
# / was on /dev/sda1 during installation
UUID=6ceae456-bfba-433c-94e0-b09ec8e29f00 /       ext4   errors=remount-ro 0       1
/swapfile                                 none    swap   sw                0       0
UUID=22432f7a-a810-482f-9836-2179ebf47493 /samba  ext4   defaults          0       0
```

Validamos que todo funciona mediante el comando `sudo mount -a`.

## Instalación de samba

Instalamos [Samba](https://www.samba.org):

```shell
sudo apt install samba
```

El comando instala tanto el servidor Samba como el servidor NetBIOS de Samba (que no necesitamos). Por seguridad, lo paramos y lo deshabilitamos.

```shell
$ sudo systemctl stop nmbd.service
$ sudo systemctl disable nmbd.service
Synchronizing state of nmbd.service with SysV service script with /lib/systemd/systemd-sysv-install.
...
```

Paramos el servicio de Samba mientras realizamos la configuración.

```shell
sudo systemctl stop smbd
```

### Obtener interfaces locales

Antes de empezar la configuración de Samba, necesitamos conocer cuáles son las interfaces locales presentes en el sistema. Para ello, usamos el comando `ip  link`:

```shell
$ ip link
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP mode DEFAULT group default qlen 1000
    link/ether 00:15:5d:01:64:7d brd ff:ff:ff:ff:ff:ff
```

### Configuración global de Samba

La configuración de Samba la realizamos a través del fichero `/etc/samba/smb.conf`.

Antes de realizar cualquier modificación en el fichero de configuración, creamos una copia de seguridad:

```shell
sudo mv /etc/samba/smb.conf /etc/samba/smb.conf.original
```

Creamos un fichero de configuración de Samba `sudo touch /etc/samba/smb.conf` y lo editamos con nuestro editor preferido con el siguiente contenido:

```shell
[global]
   server string = sambashare
   server role = standalone server
   interfaces = lo eth0
   bind interfaces only = yes
   disable netbios = yes
   smb ports = 445
   log file = /var/log/samba/smb.log
   max log size = 10000
```

Llamamos a nuestro servidor `sambashare` y lo configuramos como un servidor aislado (_standalone_) (que no forma parte de un Dominio). Nuestro servidor recibirá tráfico por las _interfaces_ `lo` y `eth0` únicamente. Esto es útil si tienes otras interfaces presentes (como `docker0`, por ejemplo).

> Siempre que se edita el fichero `smb.conf`, es conveniente ejecutar `testparm` para validar que la configuración es correcta.

```shell
$ testparm
Load smb config files from /etc/samba/smb.conf
rlimit_max: increasing rlimit_max (1024) to minimum Windows limit (16384)
Loaded services file OK.
Server role: ROLE_STANDALONE

Press enter to see a dump of your service definitions

# Global parameters
[global]
  bind interfaces only = Yes
  interfaces = lo eth0
  server string = sambashare
  log file = /var/log/samba/smb.log
  max log size = 10000
  disable netbios = Yes
  smb ports = 445
  server role = standalone server
  idmap config * : backend = tdb
```

### Creando la carpeta compartida

Como carpeta compartida, usaremos `/samba/public`.

Para crear esta carpeta:

```shell
sudo mkdir -p /samba/public
```

Para que los usuarios dentro del grupo `sambashare` tengan permisos sobre esta carpeta, cambiamos el propietario:

> El grupo `sambashare` se crea durante la instalación de Samba.

```shell
sudo chown -R :sambashare /samba
sudo chmod 2770 /samba/public
```

> - Para facilitarnos el trabajo, podemos añadir el usuario actual `operador` al grupo `sambashare` para poder listar el contenido de la carpeta `/samba/public`: `sudo usermod --append -G sambashare operador` (es necesario volver a hacer login para que los cambios sean efectivos).
>
> - Es importante incluir el parámetro `-a` o `-—append` para añadir el grupo _sambashare_ a los grupos en los que está incluido el usuario. En caso contrario, eliminamos todos los grupos y sólo dejamos el grupo indicado (eliminamos el usuario del grupo _sudoers_, por ejemplo, y dejamos de tener la posibilidad de elevar permisos). [Ref: usermod(8) - Linux man page](https://linux.die.net/man/8/usermod).

### Creando el usuario Samba

Este es el usuario `remote` con el que se validan los clientes remotos.

Al crear el usuario, se solicita una contraseña para el usuario.

```shell
$ sudo adduser --no-create-home --shell /usr/bin/nologin --ingroup sambashare remote
Adding user `remote' ...
Adding new user `remote' (1001) with group `sambashare' ...
Not creating home directory `/home/remote'.
Enter new UNIX password:
Retype new UNIX password:
passwd: password updated successfully
Changing the user information for remote
Enter the new value, or press ENTER for the default
  Full Name []: Remote User
  Room Number []:
  Work Phone []:
  Home Phone []:
  Other []:
Is the information correct? [Y/n] y
```

Samba gestiona su propia base de datos de usuarios, por lo que tenemos que añadir el usuario recién creado a esta base de datos para que el usuario pueda hacer login en Samba (y habilitarlo).

> El password que se requiere para Samba puede ser diferente del creado en el paso anterior.

```shell
$ sudo smbpasswd -a remote
New SMB password:
Retype new SMB password:
Added user remote.
$ sudo smbpasswd -e remote
Enabled user remote.
```

### Configuración del _share_

Ahora que tenemos el usuario creado y la carpeta para compartir, configuramos el _share_ en Samba.
Abrimos de nuevo el fichero de configuración `/etc/samba/smb.conf` con nuestro editor favorito y añadimos la información del _share_ `public`:

```shell
...
[public]
  path = /samba/public
  browseable = yes
  read only = no
  force create mode = 0660
  force directory mode = 2770
  valid users = @sambashare
```

Como _valid users_ especificamos los usuarios del grupo `sambashare`; de esta forma será más sencillo gestionar quién tiene acceso a la carpeta `/samba/public`.

Los permisos de las carpetas creadas `2770` indican que las nuevas carpetas se crearán con los mismos permisos que la carpeta superior.

## Instalación de Transmission (_headless_)

```shell
sudo apt install transmission-daemon
```

> El interfaz web se encuentra en el paquete `transmission-common` que se ha instalado con `transmission-daemon`.

El servicio se arranca automáticamente. Lo detenemos para poder hacer cambios en la configuración de Transmission.

```shell
sudo systemctl stop transmission-daemon
```

### Obtener el usuario con el que se ejecuta Transmission

Una de las cosas que necesitaremos más adelante, es conocer el usuario con el que se ejecuta el servicio `transmission-daemon`. Podemos obtener esta información del fichero de configuración del servicio:

```shell
$ cat /etc/init/transmission-daemon.conf
start on (filesystem and net-device-up IFACE=lo)
stop on runlevel [!2345]

# give time to send info to trackers
kill timeout 30

setuid debian-transmission
setgid debian-transmission

respawn
...
```

Como vemos, el usuario y el grupo con el que se ejecuta `transmission-daemon` es el usuario `debian-transmission`.

También podemos obtener esta información del fichero `/etc/init.d/transmission-daemon`:

```shell
$ cat /etc/init.d/transmission-daemon
...
NAME=transmission-daemon
DAEMON=/usr/bin/$NAME
USER=debian-transmission
STOP_TIMEOUT=30
...
```

Añadimos el usuario al grupo `sambashare` para que tenga acceso al _share_ `public` (que será donde dejaremos los ficheros completados descargados).

```shell
sudo usermod -aG sambashare debian-transmission
```

### Configuración de Transmission

La configuración de Transmission se realiza a través del fichero `/etc/transmission-daemon/settings.json`

Como siempre, es mejor hacer una copia antes de empezar a modificarlo:

```shell
sudo cp /etc/transmission-daemon/settings.json /etc/transmission-daemon/settings.json.original
```

El objetivo es que Transmission deje los ficheros descargados en la carpeta `public`, de manera que modificaremos el parámetro:

```shell
...
  "download-dir": "/samba/public",
...
```

### Otros parámetros a modificar

- `"ratio-limit-enabled": true,` (`false` por defecto). Finaliza la compartición cuando se alcanza el ratio definido.
- `"ratio-limit": 1.5000,` (2 por defecto). Límite de compartición por archivo.
- `"rpc-whitelist": "127.0.0.1,192.168.1.*",` (por defecto sólo permite 127.0.0.1) Habilitar la conexión remota (al interfaz web)
- `"incomplete-dir-enabled": true,` Los ficheros incompletos se almacenan en la carpeta especificada en _incomplete-dir_.
- `"incomplete-dir": "/var/lib/transmission-daemon/downloads"` La carpeta para las descargas incompletas es `downloads` con **minúsculas**, ya que por defecto se especifica `Downloads` que no existe, generando un error de "Acceso denegado".

## Arrancando los servicios

Arrancamos Samba y Transmission:

```shell
sudo systemctl start smbd
sudo systemctl start transmission-daemon
```

Puedes verificar que Samba funciona accediendo al _share_ compartido (usando el usuario `remote`).

Para validar que Transmission funciona, accede a [http://192.168.1.123:9091](http://192.168.1.123:9091) usando las credenciales `transmission` (como usuario y password usados por defecto).

## Resumen

Después de seguir estos pasos debes tener un servidor Linux con Ubuntu Server instalado con un _share_ compartido accesible desde otros ordenadores en la red local.

Además, el servidor ejecuta Transmission para descargar ficheros vía BitTorrent. Los ficheros descargados se copian al recurso compartido `/samba/public`.

La gestión de Transmission se realiza desde la interfaz web a través de [http://IP-Servidor:9091](http://IP-Servidor:9091).

### Referencias

- Configuración de Ubuntu Server
  - [CONFIGURING STATIC IP ADDRESSES ON UBUNTU 17.10 SERVERS](https://websiteforstudents.com/configuring-static-ips-ubuntu-17-10-servers/)
  - [How to Make Your Internet Faster with Privacy-Focused 1.1.1.1 DNS Service](https://thehackernews.com/2018/04/fastest-dns-service.html)
- Samba
  - [Digital Ocean: How To Set Up a Samba Share For A Small Organization on Ubuntu 16.04](https://www.digitalocean.com/community/tutorials/how-to-set-up-a-samba-share-for-a-small-organization-on-ubuntu-16-04)
- Transmission
  - [Running Transmission on a headless machine](https://trac.transmissionbt.com/wiki/HeadlessUsage/General)
  - [Transmission-Daemon Notes for Debian based Distributions](https://trac.transmissionbt.com/wiki/UnixServer/Debian)
  - [init.d Script](https://trac.transmissionbt.com/wiki/Scripts/initd#StartStop)