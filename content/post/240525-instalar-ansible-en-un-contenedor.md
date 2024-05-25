+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "ansible", "docker", "container", "automation"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/ansible.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/
# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}

title=  "Instalar Ansible en un contenedor"
date = "2024-05-25T13:41:03+02:00"
+++
Después de un tiempo cogiendo polvo, he decidido darle una segunda vida a mi antiguo equipo de laboratorio.
Aunque se trata de un sólo equipo, quería practicar con Ansible para automatizar la instalación de Docker.
No quería instalar Ansible en mi equipo y pensé que lo ideal era usar un contenedor como *máquina de control*.
Sin embargo, no he encontrado ninguna imagen (fiable/actualizada) de Ansible en DockerHub, por lo que me animé a construir la mía.

En este artículo, explico cómo.
<!--more-->
## Plan

Mi plan constaba de tres pasos:

1. Construir una imagen con Ansible que pueda usar como *máquina de control* para gestionar el equipo de laboratorio.
1. Levantar un contenedor usando Docker Compose para tener la configuración del contenedor como código.
1. Conectarme al contenedor con Ansible para ejecutar *playbooks* contra las máquinas remotas (de momento, únicamente el equipo de laboratorio).

### `Dockerfile`

Buscando por internet, las referencias que encontré para realizar la instalación de Ansible eran usando *pip*.
Sin embargo, en las pruebas que iba haciendo para verificar que Ansible en el contenedor era *usable*, recibía errores relativos a *pip*.
Unas búsquedas después, parece que el error era que, para evitar problemas, *pip* me indicaba que debía usar un *virtual env* (y yo no lo hacía)...

Finalmente, volví al punto de partida y realicé la instalación usando el gestor de paquetes de Alpine Linux (aunque conservando `py3-pip` en el contenedor). Quizás el paquete se podría eliminar, pero de momento, he decidido mantenerlo en el fichero `Dockerfile`.

Algo parecido sucede con `sshpass`; en principio, es necesario para que Ansible pueda solicitar el password para conectar vía SSH a la(s) máquina(s) remota(s). Sin embargo, una vez configurado el acceso usando una clave SSH, es probable que no sea necesario. De nuevo, de momento, lo mantengo en la definición de la imagen del contenedor en el fichero `Dockerfile`.

```dockerfile
FROM alpine:3.19
ENV ALPINE_ANSIBLE_PKG_VERSION=8.6.1-r0
RUN apk add gcc python3 py3-pip \
            openssh sshpass \
            ansible=$ALPINE_ANSIBLE_PKG_VERSION
```

La imagen resultante, con Ansible Core (2.16.1) en Alpine 3.19 se encuentra disponible en Docker Hub [xaviaznar/ansible:2.16](https://hub.docker.com/repository/docker/xaviaznar/ansible/general).

## Docker Compose

En vez de crear un *script* para lanzar el contenedor, sigo la práctica de usar un fichero de `docker-compose.yaml`, que incluye todos los parámetros, volúmenes, etc en un solo fichero YAML.

```Dockerfile
version: "3"
name: ansible
services:
  cli:
    image: xaviaznar/ansible:2.16
    stdin_open: true # equivalent to docker flag -i
    tty: true # equivalent to docker flag -t
    command: /bin/sh
    volumes:
      - $PWD:/data
      - $HOME/.ssh/ansible.key:/ansible.key
```

Como vemos en el fichero `docker-compose.yaml`, usamos `stdin_open: true` y `tty: true`, que son el equivalente a las opciones `-it` al ejecutar `docker run`.

Montamos dos volúmenes: uno, corresponde a la carpeta local, que se monta en `/data` dentro del contenedor.
Los *playbooks* (y el inventario) de Ansible estarán en la carpeta local del equipo *host*, de manera que el contenedos es completamente *stateless* y no guarda ninguna información (es desechable).

El otro volumen monta la clave privada que usará Ansible para autenticarse en las máquinas remotas.
Una posible mejora sería la de montar esta clave privada como *read only* para evitar borrarla o modificarla por error desde el contenedor.

Levantamos la "máquina de control" de Ansible mediante el comando:

```console
docker compose up -d
```

Una vez el contenedor ha arrancado, nos conectamos para ejecutar los *playbooks*:

```console
docker exec -it ansible-cli-1 /bin/sh
```

Una vez conectados al contenedor, ejecutamos Ansible:

> Usamos la clave privada con la que hemos configurado el acceso a la máquina remota para el usuario `xavi`, en este caso.

```console
ansible-playbook playbooks/docker.yaml -i inventory.yaml -u xavi --key-file /ansible.key
```

## *Playbook* de instalación de Docker CE

Ansible se conecta vía SSH a las máquinas remotas. Al conectar por primera vez a un equipo remoto por SSH, si la "firma" del equipo remoto no se encuentra en el fichero `$HOME/.ssh/known_hosts`, openSSH espera hasta que se le indica si debe confiar o no el equipo al que intenta conectar.

Como el contenedor es desechable, el fichero `$HOME/.ssh/known_hosts` no existe/está vacío para cada nueva instancia del contenedor.
Para evitar que Ansible pregunte si debe confiar en la máquina remota, tenemos que hacer varias cosas en el *playbook*.

### Deshabilitar `gather_facts`

Ansible se conecta a las máquinas remotas y obtiene información de las máquinas remotas que se puede utilizar en el *playbook*.
Pero como esa conexión se realiza a través de SSH, la ejecución se detiene hasta que se indica si confiamos en el equipo remoto o no **antes de que podamos realizar ninguna acción para evitarlo**.

Así que lo primero que hacemos en el *playbook* es desactivar la recolección de "hechos"

```yaml
---
- hosts: all
  become: true
  # Don't gather facts automatically because that will trigger
  # a connection, which needs to check the remote host key
  gather_facts: false
```

A continuación, creamos el fichero la carpeta `$HOME/.ssh/` y el fichero `known_hosts` en el contenedor:

```yaml
---
- hosts: all
  become: true
  # Don't gather facts automatically because that will trigger
  # a connection, which needs to check the remote host key
  gather_facts: false

  tasks:
    - name: Make sure the .ssh/ directory exists in control machine (container)
      delegate_to: localhost
      ansible.builtin.file:
        path: $HOME/.ssh
        state: directory
    - name: Make sure known_hosts file exists in control machine (container)
      delegate_to: localhost
      ansible.builtin.file:
        path: $HOME/.ssh/known_hosts
        state: touch
```

Estas acciones deben realizarse en la *máquina de control*, es decir, en el contenedor donde se ejecuta Ansible.
Lo habitual es que Ansible realice acciones en *máquinas remotas*; por lo que usamos la directriz `delegate_to: localhost` para indicar que las acciones se deben realizar en la máquina local (la *máquina de control*).

Finalmente, una vez que samos que el fichero `$HOME/.ssh/known_hosts` existe, anadimos la firma de la máquina remota:

```yaml
---
- hosts: all
  become: true
  # Don't gather facts automatically because that will trigger
  # a connection, which needs to check the remote host key
  gather_facts: false

  tasks:
  # ...
    - name: Check known_hosts for {{ inventory_hostname }}
      delegate_to: localhost
      ansible.builtin.known_hosts:
        path: $HOME/.ssh/known_hosts
        name: "{{ inventory_hostname }}"
        key: 192.168.1.2 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID+nWlJUq/kqtg2z0AK2FcIRkUjMyxcNu2o1dh1jQVlr
        state: present
    - name: Delayed gathering of facts
      setup:
```

> No he dedicado demasiado tiempo a encontrar una solución general, ya que sólo tengo una máquina en el inventario. Así que lo que he hecho es incluir la *firma* de la máquina en el fichero `known_hosts`.
> Idealmente, se debería calcular la firma de cada una de las máquinas en el inventorio y agregarla al fichero `known_hosts` de forma dinámica...

Una vez hemos indicado que la máquina remota es de confianza (porque se encuentra en el fichero de *hosts* conocidos), lanzamos la acción de `setup`; recogemos los datos de las máquinas remotas que no hemos realizado al principio de la ejecución del *playbook*.

### Elevación de permisos

Con los pasos descritos hasta ahora, hemos conseguido conectar a las máquinas remotas, pero todavía no hemos realizado ninguna acción sobre ellas.

El usuario con el que nos conectamos debe ser capaz de, como mínimo, usar `sudo` para elevar los permisos y poder realizar acciones como instalar aplicaciones en los equipos remotos.

Para que el usuario utilizado por Ansible pueda elevar sus permisos usando `sudo`, debe estar incluido en el fichero de *sudoers*.

En vez de proporcionar permisos de manera individual a cada usuario, creamos el grupo `ansible` en la(s) máquina(s) remota(s):

```console
sudo groupadd ansible
```

A continuación, añadimos el usuario o usuarios que Ansible usará en la máquina remota; en nuestro caso, únicamente el usuario actual:

```console
sudo usermod -aG ansible $USER
```

Validamos que el usuario se ha añadido al grupo `ansible`:

```console
$ groups $USER
xavi : xavi adm cdrom sudo dip plugdev lxd ansible
```

A continuación, incluimos el grupo `ansible` en el fichero de *sudoers* (usando `visudo`):

```code
# Users of the 'ansible' group do not require password to become root
%ansible ALL=(ALL) NOPASSWD: ALL
```

## Instalación de Docker CE

Siguiendo las instrucciones de la página de Docker, instalamos los pre-requisitos, añadimos la *key* para autenticar el repositorio de paquetes de Docker, añadimos el repositorio y finalmente instalamos:

```yaml
    - name: Install required system packages
      ansible.builtin.apt:
        pkg:
          - apt-transport-https
          - ca-certificates
          - curl
        state: latest
        update_cache: true
    - name: Add Docker GPG apt key
      ansible.builtin.apt_key:
        url: https://download.docker.com/linux/ubuntu/gpg
        id: 9DC858229FC7DD38854AE2D88D81803C0EBFCD88
        keyring: /etc/apt/trusted.gpg.d/docker.gpg
        state: present
    - name: Add Docker package repository
      ansible.builtin.apt_repository:
        repo: deb https://download.docker.com/linux/ubuntu noble stable
    - name: Update apt and install Docker CE
      ansible.builtin.apt:
        name: docker-ce
        state: latest
        update_cache: true
```
