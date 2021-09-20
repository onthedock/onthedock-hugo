+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = []
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "kubernetes", "vagrant", "k3s", "k3sup"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/kubernetes.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}

title=  "Provisionar Kubernetes con Vagrant y K3sup - 2a parte"
date = "2021-09-20T19:25:15+02:00"
+++

1. [Provisionar Kubernetes con Vagrant y K3sup - 1a parte]({{< ref "210919-provisionar-kubernetes-con-vagrant-y-k3sup-1.md" >}})
1. [Provisionar Kubernetes con Vagrant y K3sup - 2a parte]({{< ref "210920-provisionar-kubernetes-con-vagrant-y-k3sup-2.md" >}})

En la entrada anterior, tenemos un fichero `Vagrantfile` que permite provisionar máquinas virtuales a partir de la imagen base seleccionada. Las máquinas generadas están configuradas a nivel de hipervisor, con los recursos de CPU y memoria elegidos. También se ha configurado el nombre de la máquina virtual y se ha establecido una IP estática. También se han deshabilitado algunos aspectos específicos de Vagrant, como las carpetas compartidas o la comprobación de actualizaciones de la imagen base.

En esta segunda parte nos centramos en la configuración del sistema operativo aprovechando la capacidad de Vagrant de ejecutar *scripts* en las máquinas creadas.
<!--more-->

> Todavía estoy refinando esta parte, por lo que es la que está sujeta a mayores cambios. La última versión se encuentra disponible en el repositorio [onthedock/vagrant](https://github.com/onthedock/vagrant/) en GitHub.  

## Mis requerimientos

Quiero poder trabajar con las máquinas provisionadas por Vagrant como lo haría con máquinas creadas  de cualquier otra manera. Eso significa configurar acceso directo a las máquinas virtuales vía SSH. También necesito poder conectar a las máquinas virtuales a través de cualquier puerto (vía HTTP) sin necesidad de configurar *port-forwarding* en VirtualBox o de cualquier otra forma.

Para poder instalar Kubernetes (**k3s**) usando **[k3sup](https://github.com/alexellis/k3sup#pre-requisites-for-k3sup-servers-and-agents)**, necesito un usuario con posibilidad de conectar a las máquinas vía SSH y con capacidad de elevar permisos vía **sudo** sin contraseña. Los nodos deben tener una IP estática. También es necesario que las máquinas puedan comunicarse directamente entre ellas (es un requerimiento de Kubernetes).

### Problemas con la configuración por defecto de Vagrant

Por defecto, Vagrant configura la interfaz de red `eth0` como NAT; esto es un requerimiento fundamental de Vagrant, como se indica en el *issue 2093* [Vagrant Box - eth0 NAT](https://github.com/hashicorp/vagrant/issues/2093#issuecomment-23458455). Aunque este *issue* es de 2013, no parece que se haya modificado el comportamiento por defecto de Vagrant, así que `eth0` sigue configurándose por defecto como NAT.

Buscando en Google se pueden encontrar varias alternativas o *workarounds* a este requerimiento, pero en mi caso la solución ha pasado por añadir una segunda interfaz de red y conectarla a una red pública (que en [Vagrant quiere decir, más o menos, una red *bridged*](https://www.vagrantup.com/docs/networking/public_network)).

El problema es que al tener que configurar la interfaz de red "local" en el equipo físico, ésta será diferente en cada equipo, en general.

La solución de Vagrant es preguntar al usuario con qué interfaz de red físico debe crearse el *bridge*, ofreciendo una lista de posibilidades. Esto interrumpe el proceso automático de creación de las máquinas virtuales, así que la única opción para que el proceso funcione de forma desatendida es proporcionando la interfaz en el fichero de configuración.

Mientras no resuelva el *issue* [El nombre de la tarjeta de red "bridged" está fijado en el Vagrantfile #1](https://github.com/onthedock/vagrant/issues/1), el nombre de la interfaz de red física con la que debe crear el *bridge* con la interfaz de la VM **está *hardcodeado*** en el fichero `Vagrantfile`.

Las máquinas virtuales deben poder comunicarse entre ellas y con internet, así que la única manera de conseguirlo es haciendo que estén conectadas a la red "local" del laboratorio (192.168.1.x).

Sin este requerimiento, no es posible instalar Kubernetes en las máquinas provisionadas, hasta donde he podido averiguar.

### Acceso vía SSH

Usé como punto de partida los ficheros de Venkat Nagappan del repositorio [justmeandopensource/vagrant](https://github.com/justmeandopensource/vagrant/tree/master/vagrantfiles/ubuntu20). Venkat usa un fichero de *bootstrap* en el que habilita el acceso para el usuario `root` via SSH (y establece el *password* como `admin`). Sin embargo, no me sentía del todo cómodo con esta opción, por lo que creé un usuario *no-root* llamado `operador`. De esta forma no es necesario modificar el fichero de configuración de SSH. Y aunque soy consciente de que se trata de una máquina de laboratorio sin acceso directo desde internet y la posibilidad de que un *bot* consiga acceder como se indica en [Why is root login via SSH so bad that everyone advises to disable it?](https://unix.stackexchange.com/a/82639) es muy baja, creo que es una buena práctica que no está de más adoptar siempre.

Todavía mantengo los comandos *heredados* de Venkat para el acceso usando `root` (aunque están comentados en el `Vagrantfile`), pero tras la creación del usuario *no-root*, es posible que los acabe elimiando ( issue [Eliminar líneas para permitir el acceso vía SSH para el usuario root #10](https://github.com/onthedock/vagrant/issues/10)).

El usuario *no-root* también es necesario para realizar la instalación de *K3s* mediante *k3sup*. Como requerimiento adicional de *k3sup*, este usuario *no-root* debe poder elevar permisos mediante *sudo* sin necesidad de proporcionar la contraseña.

### *Script* de *bootstrap*

Este *script* está basado en el fichero de Venkat Nagappan:

```bash
$bootstrap = <<-SCRIPT
#!/bin/bash

# Enable ssh password authentication
echo "Enable ssh password authentication"
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
# No need for root SSH login
# sed -i 's/.*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
systemctl reload sshd

# Create operador user
echo "Create user operador"
useradd -s /bin/bash -m -G sudo -U operador
echo "Set operador password"
echo -e "admin\nadmin" | passwd operador >/dev/null 2>&1
 
# Set Root password
echo "Set root password"
echo -e "admin\nadmin" | passwd root >/dev/null 2>&1
SCRIPT
```

La primera sección modifica el fichero de configuración de SSH para permitir el acceso usando autenticación con contraseña; aunque fue útil al principio, una vez configurado el acceso usando claves SSH, ya no es necesario y probablemente acabe eliminando estas líneas:

```bash
# Enable ssh password authentication
echo "Enable ssh password authentication"
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
```

A continuación, se habilita el acceso SSH para el usuario `root`; tras validar la creación del usuario *no-root* `operador`, no es necesario acceder con `root`, así que comenté estas líneas y, de nuevo, las eliminaré en una iteración futura.

En la siguiente sección genero el usuario *no-root* `operador` y establezco su contraseña (como `admin`, que sin duda no es una elección acertada):

```bash
# Create operador user
echo "Create user operador"
useradd -s /bin/bash -m -G sudo -U operador
echo "Set operador password"
echo -e "admin\nadmin" | passwd operador >/dev/null 2>&1
```

Dado que conseguí habilitar el acceso usando claves SSH para acceder a las máquinas virtuales provisionadas usando el usuario `operador`, ya no es necesario establecer la contraseña para el usuario.

En la parte final del *script* se establece la contraseña para el usuario `root`; de nuevo, esto no es necesario, ya que el usuario *no-root* puede elevar permisos usando *sudo*.

En algún momento del futuro, este *script* se reducirá a:

```bash
$bootstrap = <<-SCRIPT
#!/bin/bash

# Create operador user
echo "Create user operador"
useradd -s /bin/bash -m -G sudo -U operador
SCRIPT
```

### Elevación de permisos con *sudo* sin contraseña

```bash
$passwordlessSudo = <<-SCRIPT
#!/bin/bash

echo "operador    ALL=(ALL) NOPASSWD:ALL" >> "/etc/sudoers.d/operador"
SCRIPT
```

Este segundo *script*  crea un fichero en la carpeta *sudoers.d* para que el usuario recién creado pueda elevar permisos sin proporcionar la contraseña (como requiere *k3sup*).

Dado que se trata de una sola línea, probablemente tiene mucho más sentido agrupar este comando con la creación del usuario `operador`.

Una mejora del *script* es que el nombre elegido para el usuario *no-root* pueda ser definido a través de una variable.

### Copia de la clave SSH a las máquinas provisionadas

Este es un ejemplo de lo *terriblemente hardcodeado* que está el nombre del usuario, el nombre de la clave pública, la ruta de destino... *Gets the job done*, pero necesita darle un poco de cariño y refinarlo para darle algo más de flexibilidad:

```bash
# Passwordless SSH access for operador
node.vm.provision "file", source: "~/.ssh/id_rsa.pub", destination: "/tmp/xavi.pub"
node.vm.provision "shell", inline: <<-SHELL
    sudo su operador
    sudo mkdir -p /home/operador/.ssh/
    cat /tmp/xavi.pub >> /home/operador/.ssh/authorized_keys
SHELL
```

### Detección de la tarjeta de red física activa

> Este *script* todavía no forma parte del fichero `Vagrantfile`, sólo existe de momento como [comentario](https://github.com/onthedock/vagrant/issues/1#issuecomment-902933074) del *issue* en GitHub.

Para configurar la tarjeta de red adicional en las máquinas provisionadas en modo *bridge*, debe indicarse qué tarjeta física es la que está conectada a la red local.

**Suponiendo que sólo hay una tarjeta de red activa** y haciendo algo de fontanería:

```bash
$  ip link
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: enp2s0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc fq_codel state DOWN mode DEFAULT group default qlen 1000
    link/ether XX:YY:ZZ:2c:de:58 brd ff:ff:ff:ff:ff:ff
3: wlp3s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DORMANT group default qlen 1000
    link/ether XX:YY:ZZc6:ec:6f brd ff:ff:ff:ff:ff:ff
4: br-ad180e80edaa: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN mode DEFAULT group default 
    link/ether 02:42:50:bd:70:39 brd ff:ff:ff:ff:ff:ff
5: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN mode DEFAULT group default 
    link/ether 02:42:d1:e7:c5:d8 brd ff:ff:ff:ff:ff:ff

$ ip link show | grep -i 'state UP' | awk '{gsub(/:/,"") ; print $2}'
wlp3s0
```

La idea es usar algo en esta línea para poder determinar la tarjeta *física* activa y así poder configurar las máquinas virtuales sin tener que *hardcodear* nada en el *script*.

## Instalación de K3s con *k3sup*

De momento, la instalación de Kubernetes en las máquinas provisionadas se realiza con un *script* separado, desde CLI, una vez ha finalizado la creación y configuración de las máquinas virtuales usando Vagrant.

De nuevo, el *script* "funciona", pero tiene serias limitaciones:

- el número de nodos que se configura no está relacionado con el número de máquinas que se provisionan
- lo mismo para las direcciones IPs de los nodos
- sólo permite usar un nodo *server* en el clúster

El *script* no tiene misterio si has revisado la documentación de [k3sup](https://github.com/alexellis/k3sup):

```bash
#!/usr/bin/env bash

export IPControlPlaneNode=192.168.1.101
export IPWorkerNode1=192.168.1.102
export IPWorkerNode2=192.168.1.103
export REMOTE_USER=operador

# Install the ControlPlane
k3sup install --ip $IPControlPlaneNode --user $REMOTE_USER --k3s-extra-args='--flannel-iface enp0s8'
# Install the agents/worker nodes
k3sup join --ip $IPWorkerNode1 --server-ip $IPControlPlaneNode --user $REMOTE_USER --k3s-extra-args='--flannel-iface enp0s8'
k3sup join --ip $IPWorkerNode2 --server-ip $IPControlPlaneNode --user $REMOTE_USER --k3s-extra-args='--flannel-iface enp0s8'
```

En algún momento del futuro me gustaría integrarlo dentro del fichero `Vagrantfile` si es posible, de manera que al finalizar la ejecución de `vagrant up` tuviéramos un clúster de Kubernetes (de cualquier número de nodos *agents*, aunque sólo tenga un nodo *server*).

## Conclusión

Este es sin duda el artículo más *work in progress* que he escrito hasta el momento. Normalmente enfoco el artículo como un registro de todo el proceso, pruebas y fallos incluidos, pero una vez que todo está *presentable*.

Quizás es que cada vez más me siento más cómodo con esta forma *agile* de trabajar, de conseguir un producto mínimo que funcione e ir avanzando, refinando, a partir de ahí. Quizás es sólo el efecto *post-vacaciones* y que me siento más relajado...

En cualquier caso, el código sigue avanzando en el repositorio [onthedock/vagrant](https://github.com/onthedock/vagrant).
