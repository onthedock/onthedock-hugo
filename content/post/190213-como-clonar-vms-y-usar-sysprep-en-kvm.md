+++
draft = false

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

title=  "Cómo clonar máquinas virtuales y usar virt-sysprep en KVM"
date = "2019-02-13T20:57:24+01:00"
+++
En la entrada anterior hemos visto cómo crear y clonar discos. Si el disco clonado contiene el sistema operativo de una máquina virtual, el clon continene identificadores que deberían ser únicos (como el _machine ID_, direcciones MAC, claves SSH de _host_, etc).

Podemos usar `virt-sysprep` para eliminar todos estos identificadores únicos.
<!--more-->

> [`virt-sysprep`](http://libguestfs.org/virt-sysprep.1.html) forma parte del paquete `libguestfs-tools`.

# `virt-sysprep`

Esta herramienta copia el nombre de la herramienta [`sysprep` de Microsoft](https://en.wikipedia.org/wiki/Sysprep).

Una manera eficiente de crear un conjunto de máquinas homogéneas es clonando el disco después de realizar la instalación y configuración en una máquina de referencia.

En nuestro caso, supomemos que hemos configurado a nuestro gusto la máquina virtual `debian9`.

En primer apagamos la máquina virtual:

```bash
$ virsh shutdown debian9
Domain debian9 is being shutdown
```

Usaremos esta máquina virtual como base para crear la _machine image_ que usaremos como plantilla para crear el resto de máquinas virtuales. Para clonar la máquina usamos `virt-clone`.

> `virt-clone` forma parte del paquete `virtinst`

Puedes usar `--auto-clone` para que `virt-clone` genere un nombre de disco automáticamente (añadiendo `-clone` al nombre del disco):

```bash
$ virt-clone --original debian9 --name debian-machine-image --auto-clone
Allocating 'vdisk-u39572-clone.qcow2'                 |  10 GB  00:00:02

Clone 'debian-machine-image' created successfully.
```

Al tratarse de una _machine image_, es recomendable especificar un nombre significativo para el disco que permita identificarlo fácilmente; para ello, usamos el parámetro `--file` y especificamos el nombre de disco que deseamos:

```bash
$ virt-clone --original debian9 --name debian-machine-image2 --file /var/lib/libvirt/images/debian-machine-image.qcow2
Allocating 'debian-machine-image.qcow2'                                     |  10 GB  00:00:02

Clone 'debian-machine-image2' created successfully.
```

> Cambiamos el nombre de las máquinas virtuales por estética:

```bash
$ virsh domrename debian-machine-image debian-machine-image-funny-disk-name
Domain successfully renamed
$ virsh domrename debian-machine-image2 debian-machine-image
Domain successfully renamed
$ virsh list --all
Id    Name                                 State
----------------------------------------------------
-     debian-machine-image                 shut off
-     debian-machine-image-funny-disk-name shut off
-     debian9                              shut off
```

Lanzamos `virt-sysprep` para generalizar la máquina `debian-machine-image`; `virt-sysprep` también puede realizar algunas operaciones, como establecer el `hostname`de la máquina o la contraseña de los usuarios, entre otras muchas acciones:

```bash
sudo virt-sysprep -d debian-machine-image --hostname debian-machine-image --root-password password:Sup3rs3cr3tp@55w0rd!
[sudo] password for operador:
[   0.0] Examining the guest ...
[   9.1] Performing "abrt-data" ...
[   9.1] Performing "backup-files" ...
[   9.4] Performing "bash-history" ...
[   9.4] Performing "blkid-tab" ...
[   9.4] Performing "crash-data" ...
[   9.4] Performing "cron-spool" ...
[   9.4] Performing "dhcp-client-state" ...
[   9.4] Performing "dhcp-server-state" ...
[   9.4] Performing "dovecot-data" ...
[   9.4] Performing "logfiles" ...
[   9.5] Performing "machine-id" ...
[   9.5] Performing "mail-spool" ...
[   9.5] Performing "net-hostname" ...
[   9.5] Performing "net-hwaddr" ...
[   9.5] Performing "pacct-log" ...
[   9.5] Performing "package-manager-cache" ...
[   9.5] Performing "pam-data" ...
[   9.5] Performing "passwd-backups" ...
[   9.5] Performing "puppet-data-log" ...
[   9.5] Performing "rh-subscription-manager" ...
[   9.5] Performing "rhn-systemid" ...
[   9.5] Performing "rpm-db" ...
[   9.5] Performing "samba-db-log" ...
[   9.5] Performing "script" ...
[   9.5] Performing "smolt-uuid" ...
[   9.5] Performing "ssh-hostkeys" ...
[   9.5] Performing "ssh-userdir" ...
[   9.5] Performing "sssd-db-log" ...
[   9.5] Performing "tmp-files" ...
[   9.5] Performing "udev-persistent-net" ...
[   9.5] Performing "utmp" ...
[   9.5] Performing "yum-uuid" ...
[   9.5] Performing "customize" ...
[   9.5] Setting a random seed
[   9.5] Setting the machine ID in /etc/machine-id
[   9.5] Setting the hostname: debian-machine-image
[  10.3] Setting passwords
[  11.1] Performing "lvm-uuids" ...
```

Como vemos, `virt-sysprep` ha eliminado todas aquellas configuraciones específicas para la máquina, de manera que podemos usar esta VM como base para generar nuevas máquinas virtuales.

## Generar una VM a partir de la _machine image_

Generamos una máquina virtual a partir de la _machine image_ generalizada:

```bash
$ virt-clone --original debian-machine-image --name vm-debian-01 --file vm-debian-01.qcow2
Allocating 'vm-debian-01.qcow2'                                         |  10 GB  00:00:02

Clone 'vm-debian-01' created successfully.
```

El siguiente paso es personalizar esta nueva instancia aprovechando la potencia de `virt-customize`; usando las opciones que proporciona [`virt-customize`](http://libguestfs.org/virt-customize.1.html) puedes generar máquinas personalizadas sin necesidad de recurrir a otras opciones como [Cloud-Init](https://cloudinit.readthedocs.io/en/latest/).

Mediante `virt-customize` puedes establecer el _hostname_ de la nueva VM, inyectar claves SSH, instalar paquetes, etc...

En el siguiente ejemplo, personalizamos la máquina `vm-debian-01` (creada a partir de la _machine image_) estableciendo el _hostname_ y la contraseña del usuario _operador_:

```bash
$ sudo virt-customize -d vm-debian-01 --hostname vm-debian-01 --password operador:password:SecretPasswrd!
[   0.0] Examining the guest ...
[   2.8] Setting a random seed
[   2.8] Setting the hostname: vm-debian-01
[   3.6] Setting passwords
[   4.4] Finishing off
```

### Problemas con el acceso SSH

Al intentar acceder remotamente a la máquina recién clonada, se produce un error de _connection refused_.
Después de comprobar que el puerto 22 está abierto, al revisar el estado del servicio SSH (`sudo systemctl status sshd`) se observan varios errores indicando que no se encuentran las claves de _host_:

```bash
...
debian sshd[387]: Server listening on 0.0.0.0 port 22.
debian sshd[387]: Server listening on :: port 22.
debian sshd[473]: error: Could not load host key: /etc/ssh/ssh_host_rsa_key
debian sshd[473]: error: Could not load host key: /etc/ssh/ssh_host_ecdsa_key
debian sshd[473]: error: Could not load host key: /etc/ssh/ssh_host_ed25519_key
debian sshd[473]: fatal: No supported key exchange algorithms [preauth]
...
```

Revisando la salida del comando `virt-sysprep` se puede ver que estas claves se han borrado:

```bash
...
Performing "smolt-uuid" ...
Performing "ssh-hostkeys" ... <-- Oops, ssh-hostkeys have been deleted :(
Performing "ssh-userdir" ...
...
```

La solución es volver a generar las diferentes claves de forma manual:

```bash
$ sudo ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa
Generating public/private rsa key pair.
Your identification has been saved in /etc/ssh/ssh_host_rsa_key.
Your public key has been saved in /etc/ssh/ssh_host_rsa_key.pub.
The key fingerprint is:
SHA256:3nXA97TIi1HLJViqpNb/7OFiMXm4UTCmZw5F3jWa8NU root@vm-debian-02
The key's randomart image is:
+---[RSA 2048]----+
|          .o . +.|
|          .*B = E|
|         .++=B...|
|        +o.o++=o.|
|       oSo=.==...|
|      .. ..Ooo.  |
|        . .o*o   |
|           ++ .  |
|          . o=   |
+----[SHA256]-----+
```

(Referencia: [Regenerating SSH host keys](https://www.cloudvps.com/helpcenter/knowledgebase/linux-vps-configuration/regenerating-ssh-host-keys))

Tras reiniciar el servicio SSH (`sudo systemctl restart sshd`) se puede conectar vía SSH a la máquina.

**Actualización**: Todas las claves SSH para el host eliminadas por `virt-sysprep` se pueden regenerar **a la vez** mediante `sudo ssh-keygen -A`.

```bash
$ sudo ssh-keygen -A
ssh-keygen: generating new host keys: RSA DSA ECDSA ED25519
```

En la documentación [virt-sysprep - Reset, unconfigure or customize a virtual machine so clones can be made](http://libguestfs.org/virt-sysprep.1.html#ssh-hostkeys) se indica que las claves SSH para el _host_ se deberían recrear automáticamente al arrancar de nuevo la máquina.

En la instalación de Debian 9.6 que estoy usando es necesario recrear las _host keys_ manualmente, aunque quizás se trate de un error específico de mi instalación.

Una opción que puedes considerar es regenerar las claves SSH en la _machine image_; sin embargo, todas las máquinas clonadas a partir de la imagen base compartirán las claves SSH de host. En [Are duplicate SSH server host keys a problem?](https://security.stackexchange.com/questions/41380/are-duplicate-ssh-server-host-keys-a-problem) se explica en qué casos tener _ssh host keys_ duplicadas es "malo" (casi siempre) y cuando no. En un entorno de laboratorio no es crítico, aunque puede solucionarse fácilmente mediante un script que regenere las claves SSH del _host_ (`sudo ssh-keygen -A`) al arrancar si no se encuentran.

### Mensaje "Remote host identification has changed!" en equipos cliente

Al regenerar las claves en el _host_ es necesario actualizarlas también en los ficheros `.ssh/known_hosts` de los equipos en los que se haya agregado alguna de las claves anteriores. Si no se actualiza, se mostrará un mensaje como:

```bash
ssh operador@192.168.1.237
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
Someone could be eavesdropping on you right now (man-in-the-middle attack)!
It is also possible that a host key has just been changed.
The fingerprint for the ECDSA key sent by the remote host is
SHA256:On5KdKaywnbsXiq/D/OJPiN0PegGO9DrVfaBIdFCLg4.
Please contact your system administrator.
Add correct host key in /home/xavi/.ssh/known_hosts to get rid of this message.
Offending ECDSA key in /home/xavi/.ssh/known_hosts:4
  remove with:
  ssh-keygen -f "/home/xavi/.ssh/known_hosts" -R "192.168.1.237"
ECDSA host key for 192.168.1.237 has changed and you have requested strict checking.
Host key verification failed.
```

# Resumen

En esta entrada hemos visto cómo clonar máquinas virtuales desde la línea de comandos usando `virt-clone`.

Hemos usado `virt-sysprep` para _generalizar_ las máquinas clonadas de manera que se eliminen los identificadores únicos asociados a la máquina y así disponer de una plantilla.

En la parte final hemos visto cómo podemos personalizar una máquina virtual usando `virt-customize` definiendo el _hostname_, nuevas contraseñas para los usuarios, cómo instalar paquetes, etc.