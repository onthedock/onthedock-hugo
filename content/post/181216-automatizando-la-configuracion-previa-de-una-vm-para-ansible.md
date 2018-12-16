+++
draft = false
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "virtual machine", "ansible", "automation"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/ansible.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" %}}

title=  "Automatizando la configuracion de una VM para Ansible"
date = "2018-12-16T13:55:30+01:00"
+++

Con Ansible podemos automatizar la gestión de la configuración de las máquinas virtuales (o no) que creamos. Pero para poder explotar la potencia de Ansible necesitamos que la máquina gestionada cumpla unos requisitos previos: disponer de Python 2.6 o superior y que Ansible pueda conectar con la máquina.

Todas estas tareas se pueden automatizar, así que vamos a ver cómo conseguirlo.
<!--more-->

En mi caso he estado haciendo pruebas con máquinas generadas usando Vagrant, con IP dinámica asignada a través de DHCP.

El script de configuración se encuentra en un repositorio de Git, por lo que en la máquina gestionada tenemos que descargarlo -usando `curl` o `wget`- y convertirlo en ejecutable (`chmod +x vmconfig4ansible.sh`).

> He subido el script al repositorio [onthedock/vmconfig4ansible](https://github.com/onthedock/vmconfig4ansible) en GitHub.

Asumo que "de alguna manera" tienes forma de conectar a la máquina recién creada y que conoces las credenciales para poder acceder (y elevar permisos una vez conectado).

## Conexión a la máquina gestionada

Tras crear la máquina con Vagrant, obtendo la IP asignada por DHCP consultando el hipervisor. Supongamos que esta IP es 192.168.1.221.
Al tratarse de una máquina Vagrant, el usuario `vagrant` tiene contraseña `vagrant`, aunque también puedes acceder usando el comando `vagrant ssh`.

> En las máquinas Vagrant el usuario `vagrant` tiene permisos para elevar permisos sin necesidad de introducir el password, por lo que el _script_ funciona sin interrupción al ejecutar las instrucciones `sudo ...`.

## Instalando Python

El script empieza instalando Python 3 y actualizando la ubicación del intérprete de Python en la máquina gestionada.

```bash
# Always install Python 3
sudo apt install python3 -y
# Update Python location
sudo ln -sf /usr/bin/python3 /usr/bin/python
```

En mi caso, la máquina Vagrant (con Debian 9) tenía instalado tanto Python 2.7 como Python 3.5. Sin embargo, `/usr/bin/python` apuntaba a la versión 2.7. En las primeras versiones, el script validaba la versión de Python para comprobar si era necesario actualizar, pero de esta forma el script es más sencillo. Al no tener requerimientos específicos respecto a la versión de Python, he optado por usar Python 3 por defecto.

> En la documentación de Ansible se indica la posibilidad de usar el módulo `raw` para instalar Python en aquellas máquinas que no tengan una versión soportada. Échale un vistazo a los [requerimientos para máquinas gestionadas](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#managed-node-requirements).

## Usuario para Ansible

Para simplificar el mantenimiento de los sistemas las tareas de gestión realizadas desde la máquina de control de Ansible, usaremos un usuario dedicado; en mi caso le he llamado `ansible`:

```bash
# Create ansible user
echo "Adding user $ANSIBLE_USER ..."
sudo useradd $ANSIBLE_USER
```

Ansible se conectará usando este usuario a los diferentes sistemas usando claves SSH. Para poder conectar sin problemas, añadimos la clave pública al fichero `authorized_keys` en la carpeta `.ssh` del usuario `$ANSIBLE_USER`:

```bash
# Create .ssh folder
echo "Configuring user $ANSIBLE_USER authorized_keys"
sudo mkdir -p /home/$ANSIBLE_USER/.ssh
# Copy PUBKEY to authorized_keys for $ANSIBLE_USER
echo $PUBKEY >> authorized_keys
sudo mv authorized_keys /home/$ANSIBLE_USER/.ssh/authorized_keys
sudo chown ansible:ansible -R /home/$ANSIBLE_USER/
sudo chmod 600 /home/$ANSIBLE_USER/.ssh/authorized_keys
```

Después de copiar el fichero, ajustamos los permisos de manera que sólo el usuario pueda leer y escribir en este fichero.

## Elevación de privilegios sin password

En vez de modificar el fichero `/etc/sudoers` aprovechamos que `sudo` procesa este fichero hasta encontrar la directiva `#includedir /etc/sudoers.d`. A partir de este punto se incluyen los ficheros en la ruta especificada. Esto nos permite crear un fichero por usuario, por ejemplo y así tener mejor organizados los permisos.

> El `#` **no es un comentario** y **no debe eliminarse**.

Creamos un fichero llamado `user-ansible` en `/etc/sudoers.d/` y añadimos la directiva de manera que el usuario pueda ejecutar cualquier comando sin necesidad de proporcionar la contraseña:

```bash
# Passwordless sudo
echo "Configuring passwordless sudo..."
echo "$ANSIBLE_USER ALL=NOPASSWD: ALL" >> user-$ANSIBLE_USER
# Fix permissions
sudo chown root:root user-$ANSIBLE_USER
sudo mv user-$ANSIBLE_USER /etc/sudoers.d/
```

Finalmente, ajustamos el propietario del fichero al usuario `root` (en caso contrario, se produce un error al intentar acceder desde la máquina de control).

Subimos el fichero a un repositorio desde donde podamos usarlo siempre que sea necesario (en mi caso, un repositorio de un Git local).

## Comprobación en una nueva máquina Vagrant

Creamos una nueva máquina virtual (`vagrant destroy -f`, `vagrant up`) y accedemos a ella (por ejemplo, mediante `vagrant ssh`).

Descargamos el fichero, lo convertimos en ejecutable y lo lanzamos:

```bash
vagrant@scratch:~$ wget http://gitea.local:3000/xavi/vmconfig4ansible/raw/branch/master/vmconfig4ansible.sh
--2018-12-16 04:52:03--  http://gitea.local:3000/xavi/vmconfig4ansible/raw/branch/master/vmconfig4ansible.sh
Connecting to gitea.local:3000... connected.
HTTP request sent, awaiting response... 200 OK
Length: 1235 (1.2K) [text/plain]
Saving to: 'vmconfig4ansible.sh'

vmconfig4ansible.sh   100%[=======================>]   1.21K  --.-KB/s    in 0s

2018-12-16 04:52:03 (124 MB/s) - 'vmconfig4ansible.sh' saved [1235/1235]

vagrant@scratch:~$ chmod +x vmconfig4ansible.sh
vagrant@scratch:~$ ./vmconfig4ansible.sh
Reading package lists... Done
Building dependency tree
Reading state information... Done
python3 is already the newest version (3.5.3-1).
python3 set to manually installed.
0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded.
Adding user ansible ...
Configuring user ansible authorized_keys
Configuring passwordless sudo...
```

Tras haber realizado la configuración previa, verificamos que desde Ansible podamos lanzar un *playbook*.

## Comprobación desde Ansible

Conectado en la máquina de control con Ansible, creamos un fichero de inventario temporal para realizar la validación de la configuración realizada por el *script* en la máquina gestionada. En el fichero de inventario, añadimos el nombre e IP de la máquina Vagrant de test:

```bash
:~$ nano temp-vagrant
[vagrant]
192.168.1.221
```

A continuación, lanzamos un *ping* sobre la máquina con etiqueta `vagrant` (usando este *inventario* de ejemplo):

```bash
:~$ ansible vagrant -i vagrant-test -m ping
The authenticity of host '192.168.1.221 (192.168.1.221)' can't be established.
ECDSA key fingerprint is SHA256:EWnDBzCe7HyElk5vKD+nhEKVyPMIe0/MpO1S94Eus0c.
Are you sure you want to continue connecting (yes/no)? yes
192.168.1.221 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

Observa que cuando Ansible intenta conectar con la máquina gestionada vía SSH por primera vez, se muestra una alerta indicando que no se puede validar la autenticidad del *host* remoto. Obviamente, esto detiene la ejecución del *playbook* hasta que se responde la pregunta. Si quieres evitar esta pregunta -la primera vez que conectas a una máquina remota- puedes configurar la variable `host_key_checking = False` (a través del fichero de configuración en `/etc/ansible/ansible.cfg` o `~/.ansible.cfg` o mediante la variable de entorno `$ export ANSIBLE_HOST_KEY_CHECKING=False`) según se indica en la sección [Host Key Checking](https://docs.ansible.com/ansible/latest/user_guide/intro_getting_started.html#host-key-checking) de la documentación oficial de Ansible.

Una vez verificado que Ansible puede conectar con la máquina gestionada, podemos incluirla en el fichero de *inventario real* para realizar las configuraciones adicionales que deseemos:

```bash
:~$ ansible-playbook -i vagrant-test playbooks/update-all/update-server.yml

PLAY [all] ***************************************************************************

TASK [Gathering Facts] ***************************************************************
ok: [192.168.1.221]

TASK [update and upgrade] ************************************************************
ok: [192.168.1.221]

PLAY RECAP ***************************************************************************
192.168.1.221              : ok=2    changed=0    unreachable=0    failed=0
```
