+++
draft = false
categories = ["ops"]
tags = ["linux", "debian", "ansible"]
thumbnail = "images/ansible.png"
title=  "Instalación de Ansible en Debian 9"
date = "2019-04-19T17:04:12+02:00"
+++

Ansible permite automatizar la configuración de máquinas. Curiosamente, aunque he hablado de [Ansible]({{< ref "/tags/ansible" >}}) en otras ocasiones, no había dedicado ninguna entrada al proceso de instalación y configuración.

Vamos a corregir esta situación ;)
<!--more-->

# Instalación de Ansible

Para instalar Ansible en Debian, seguimos los pasos indicados en la documentación oficial [Installation Guide](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#latest-releases-via-apt-debian).

En primer lugar, añadimos el repositorio de Ubuntu. En mi caso, prefiero añadir el repositorio en un fichero separado, en `/etc/apt/sources.list.d/` en vez de hacerlo directamente en `/etc/apt/sources.list`:

```bash
sudo nano /etc/apt/sources.list.d/ubuntu-trusty.list
```

Añade la línea `deb http://ppa.launchpad.net/ansible/ansible/ubuntu trusty main` y guarda los cambios.

Antes de lanzar `apt update` e instalar Ansible, debemos incorporar la clave del repositorio a nuestro sistema:

```bash
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367
sudo apt-get update
sudo apt-get install ansible
```

En mi caso, no es posible recuperar la clave:

```bash
$ sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367
Executing: /tmp/apt-key-gpghome.mI9WEO81of/gpg.1.sh --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367
gpg: failed to start the dirmngr '/usr/bin/dirmngr': No such file or directory
gpg: connecting dirmngr at '/tmp/apt-key-gpghome.mI9WEO81of/S.dirmngr' failed: No such file or directory
gpg: keyserver receive failed: No dirmngr
```

La solución pasa por instalar primero `dirmngr` usando `sudo apt install dirmngr`.

Una vez solucionado, recuperamos la clave pública del repositorio:

```bash
$ sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367
Executing: /tmp/apt-key-gpghome.kkjSRhUytC/gpg.1.sh --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367
gpg: key 93C4A3FD7BB9C367: public key "Launchpad PPA for Ansible, Inc." imported
gpg: Total number processed: 1
gpg:               imported: 1
```

Ahora sí, `update` e `install`:

```bash
sudo apt update
sudo apt install ansible
```

Validamos que Ansible está instalado mediante:

```bash
$ ansible --version
ansible 2.7.10
  config file = /etc/ansible/ansible.cfg
  configured module search path = [u'/home/operador/.ansible/plugins/modules', u'/usr/share/ansible/plugins/modules']
  ansible python module location = /usr/lib/python2.7/dist-packages/ansible
  executable location = /usr/bin/ansible
  python version = 2.7.13 (default, Sep 26 2018, 18:42:22) [GCC 6.3.0 20170516]
```

## Usuario de gestión para Ansible

Vamos a generar un usuario específico para Ansible, que se autenticará en las máquinas gestionadas usando un par de claves SSH.

Para crear el usuario, usamos el comando `adduser`:

> Si usas el comando `useradd`, sólo se crea el usuario (no se crea la carpeta `$home`, no se establece una contraseña para el usuario, etc).

```bash
$ sudo adduser ansible-service-account
Adding user `ansible-service-account' ...
Adding new group `ansible-service-account' (1001) ...
Adding new user `ansible-service-account' (1001) with group `ansible-service-account' ...
Creating home directory `/home/ansible-service-account' ...
Copying files from `/etc/skel' ...
Enter new UNIX password:
Retype new UNIX password:
passwd: password updated successfully
Changing the user information for ansible-service-account
Enter the new value, or press ENTER for the default
   Full Name []: Ansible Service Account
   Room Number []:
   Work Phone []:
   Home Phone []:
   Other []:
Is the information correct? [Y/n] y
$
```

Usando `sudo su ansible-service-account` cambiamos de identidad y nos convertimos en el usuario especificado.

## Generar la clave SSH

En este artículo de 2016, [Upgrade your SSH keys!](https://blog.g3rt.nl/upgrade-your-ssh-keys.html) se recomienda evitar las claves RSA < 2048 bits, usando en vez de ello el nuevo algoritmo ed25519.

Siguiendo esta recomendación, generamos las claves SSH para el usuario recién creado.
Esta cuenta se usará para realizar acciones automatizadas, por lo que no especificaremos una _passphrase_:

> Usamos la opción `-C` para añadir un comentario que permita identificar fácilmente el par de claves generado.

```bash
$ ssh-keygen -o -a 100 -t ed25519 -C ansible-service-account
Generating public/private ed25519 key pair.
Enter file in which to save the key (/home/ansible-service-account/.ssh/id_ed25519):
Created directory '/home/ansible-service-account/.ssh'.
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /home/ansible-service-account/.ssh/id_ed25519.
Your public key has been saved in /home/ansible-service-account/.ssh/id_ed25519.pub.
The key fingerprint is:
SHA256:4Zp/sQr0n3wvwMkQaUt3aqnGvnfIWdicuYEFCW7WFes ansible-service-account
The key's randomart image is:
+--[ED25519 256]--+
|        .o .o.   |
|       .=.+...   |
|       o=+.=.    |
|       +o.+..    |
|      ..S* BEo   |
|     . ++ O B    |
|      +o.. B o   |
|       o.oB.=    |
|        +=+o o.  |
+----[SHA256]-----+
```

En la carpeta `.ssh` recién creada se encuentran el par de claves SSH, tanto la privada (que debes mantener privada) como la pública.

Puedes verificarlo mediante:

```bash
$ ls ~/.ssh/
id_ed25519  id_ed25519.pub
```

La parte pública de la clave únicamente _encaja_ con la parte privada (que sólo tiene el usuario _ansible-service-account_), por lo que el siguiente paso es copiar esta clave pública en los máquinas gestionadas por Ansible.

El usuario _ansible-service-account_ realizará tareas de administración, por lo que debemos proporcionar la capacidad de elevar permisos en las máquinas gestionadas.

## Tareas de configuración

En vez de realizar las mismas acciones una y otra vez, usaremos un _script_ para automatizar estas tareas.
Este script se encuentra en GitHub [onthedock/vmconfig4ansible
](https://github.com/onthedock/vmconfig4ansible).

> Puedes incluir estas configuraciones en tu _imagen base_ o ejecutarlas durante el primer arranque de la máquina si usas [cloud-init](https://cloudinit.readthedocs.io/en/latest/), por ejemplo.

### Crear el usuario de gestión en la máquina gestionada

Creamos el usuario local en la máquina gestionada mediante `useradd`; esto no crea la carpeta `$home` del usuario, ni establece grupos o una contraseña para el usuario.

```bash
# Create ansible user
echo "Adding user $ANSIBLE_USER ..."
sudo useradd $ANSIBLE_USER
```

### Crear la carpeta `$home/$ANSIBLE_USER` manualmente

El sistema remoto buscará si la parte pública de la clave presentada al conectar por SSH se encuentra en el fichero `$home/.ssh/authorized_keys`.
Como el comando `useradd` no ha creado la carpeta `$home`, la creamos manualmente:

```bash
# Create .ssh folder
echo "Configuring user $ANSIBLE_USER authorized_keys"
sudo mkdir -p /home/$ANSIBLE_USER/.ssh
# Copy PUBKEY to authorized_keys for $ANSIBLE_USER
echo $PUBKEY >> authorized_keys
sudo mv authorized_keys /home/$ANSIBLE_USER/.ssh/authorized_keys
sudo chown $ANSIBLE_USER:$ANSIBLE_USER -R /home/$ANSIBLE_USER/
sudo chmod 600 /home/$ANSIBLE_USER/.ssh/authorized_keys
```

> Si tienes problemas para conectar, revisa que tanto la autenticación con clave pública como los permisos sobre `~/.ssh` y `~/.ssh/*` sean los correctos (Referencia: [Can't get SSH public key authentication to work [closed]](https://serverfault.com/a/55458))

### Añadir la clave pública al fichero `authorized_keys`

Una vez creada la carpeta, añadimos la clave pública al fichero. Podemos convertirnos en el usuario `ansible-service-account` y generar el fichero `authorized_keys` o, como hacemos en el script, ejecutar las tareas elevando privilegios (o directamente como `root`).
En cualquier caso, SSH requiere que únicamente el usuario `ansible-service-account` tenga acceso al fichero, por lo que arreglamos los permisos tanto de la carpeta `$home/ansible-service-account` como del fichero `authorized_keys`.

### Elevación de permisos sin contraseña

Para que el usuario `ansible-service-account` pueda realizar tareas administrativas en las máquinas gestionadas en las que se conecta, es necesario que tenga capacidad para elevar privilegios y ejecutar tareas como `root`.

Podemos hacer que el _script_ solicite la contraseña cuando tenga que _elevar_ permisos, pero va en contra de la idea de "automatizar", por lo que configuramos el usuario usado por Ansible para que pueda convertirse en `root` sin contraseña.

Hay varias formas de hacer que un usuario pueda elevarse sus privilegios usando `sudo`; la manera más sencilla es incluir el usuario en el grupo `sudo` (o `admin`, en algunas distribuciones), pero creo que es más adecuado añadir el usuario al fichero de _sudoers_.

```bash
# Passwordless sudo
echo "Configuring passwordless sudo..."
echo "$ANSIBLE_USER ALL=NOPASSWD: ALL" >> $ANSIBLE_USER
# Fix permissions
sudo chown root:root $ANSIBLE_USER
sudo mv $ANSIBLE_USER /etc/sudoers.d/
```

Creamos un fichero con el nombre del usuario usado por Ansible y lo colocamos en `/etc/sudoers.d/`, de manera que `sudo` lo leerá como si formara parte del fichero `/etc/sudoers`, pero así mantenemos el fichero original sin modificaciones.

A través del fichero _sudoers_ podemos restringir qué comandos puede ejecutar el usuario (y en qué máquinas), cosa que no podemos hacer si agregamos el usuario al grupo `sudo`.
Puedes obtener más información sobre cómo configurar `sudo` de forma que el usuario de Ansible sólo pueda ejecutar las tareas que tenga que ejecutar y no otras en la página [Sudoers Manual](https://www.sudo.ws/man/1.8.2/sudoers.man.html).

### Configuración de Python

Para poder ejecutar los _playbooks_ de Ansible, el único requerimiento sobre la máquina gestionada es que tenga instalado Python 2.7 o superior.

En Debian 9, por ejemplo, está instalado tanto Python 2.7 como Python 3.5, por lo que el Python que se usa lo determina el enlace desde `/usr/bin/python`.

Instalamos la última versión de Python 3 y cambiamos el enlace para que el sistema use la versión recién instalada:

```bash
# Always install Python 3
sudo apt install python3 -y
# Update Python location
sudo ln -sf /usr/bin/python3 /usr/bin/python
```

## Test de Ansible

Después de instalar Ansible tanto en la máquina de control como en las máquinas gestionadas, es hora de validar que todo funciona.

Crea o edita el fichero `/etc/ansible/hosts` siguiendo las instrucciones de [Your first commands](https://docs.ansible.com/ansible/latest/user_guide/intro_getting_started.html#your-first-commands) e incluye la IP o el nombre de la(s) máquina(s) gestionada(s).

```bash
sudo nano /etc/ansible/hosts
```

A continuación, cambia al usuario configurado para Ansible y ejecuta el módulo _ping_ sobre todas (_all_) las máquinas configuradas en el inventorio (el fichero `/etc/ansible/hosts`):

```bash
operador@ansible:~$ sudo su ansible-service-account
ansible-service-account@ansible:~$ ansible all -m ping
192.168.1.215 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

Como puedes ver, Ansible se ha conectado al equipo remoto con IP 192.168.1.215, donde ha ejecutado el módulo _ping_, que ha devuelto _pong_, indicando que todo ha funcionado correctamente.

## Resumen

La instalación de Ansible es tan sencilla como `apt install ansible`; en cuanto a configuración, para evitar permitir la conexión remota del usuario `root`, creamos un usuario específico que pueda acceder a las máquinas gestionadas usando claves SSH.

La configuración de las máquinas remotas puede incluirse en la _imagen base_ de tus máquinas virtuales o bien pueden incluirse en el `user-data` si usas _cloud-init_ (o algún proveedor de _cloud_).
En el peor de los casos, puedes automatizar las tareas en un _script_ de configuración de la máquina gestionada y lanzarlo manualmente.

Tras esta configuración inicial de Ansible (y de las máquinas gestionadas), Ansible puede lanzar prácticamente cualquier tarea que sea necesario ejecutar sobre cualquiera de ellas, de forma individual sobre alguno de los grupos definidos en el inventorio.

Puedes encontrar infinidad de _playbooks_ de Ansible para automatizar cualquier cosa imaginable en [Ansible Galaxy](https://galaxy.ansible.com/).