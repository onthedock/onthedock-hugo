+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "vagrant", "automation"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/vagrant.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/

# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}
# YouTube           {{< youtube w7Ft2ymGmfc >}}
# Gist              {{< gist username 7896402 >}}
# Highlight         {{< highligth language >}}...{{< /highlight >}}
# Twitter           {{< tweet user="SanDiegoZoo" id="1453110110599868418" >}}

title=  "Error en Vagrant tras actualizar a Pop_Os! 22.04"
date = "2022-05-07T10:55:52+02:00"
+++
> *TL,DR;* Solución en [Vagrant up error on Ubuntu 22.04: pkeys are immutable on OpenSSL 3.0](https://discuss.hashicorp.com/t/vagrant-up-error-on-ubuntu-22-04-pkeys-are-immutable-on-openssl-3-0/38734)

Ayer actualicé a la nueva versión de PoP_OS!, basada en Ubuntu 22.04 LTS. Todo funcionó de maravilla, como debe ser. El único problema -por llamarlo de algún modo- identificado tras la actualización ha sido la pérdida de la configuración de [Cool Retro Term](https://github.com/Swordfish90/cool-retro-term); *no big deal*...
<!--more-->

Sin embargo, esta mañana, al intentar *levantar* el laboratorio local del clúster de Kubernetes basado en Vagrant (échale un vistazo en GitHub [onthedock/k3s-ubuntu-cluster](https://github.com/onthedock/vagrant/tree/devkube/k3s-ubuntu-cluster)), Vagrant ha empezado a dar problemas...

En primer lugar, Vagrant se ha quejado de los *plugins*, pero afortunadamente el contenido de los los mensajes de error proporciona los comandos para reinstalarlos.

Tras solucionar el problema con los *plugins*, la creación de las máquinas virtuales también ha fallado... Después de reinstalar de nuevo Vagrant (en la línea de la solución para el problema de los *plugins*) sin que ésto solucionara el problema, he revisado con más detalle la *verborreica* salida del error en Vagrant.

El proceso comienza con normalidad, pero las cosas se complican cuando se intenta acceder por SSH a la nueva máquina:

```bash
$ vagrant up        
Bringing machine 'k3s-1' up with 'virtualbox' provider...
Bringing machine 'k3s-2' up with 'virtualbox' provider...
Bringing machine 'k3s-3' up with 'virtualbox' provider...
==> k3s-1: Importing base box 'ubuntu/focal64'...
==> k3s-1: Matching MAC address for NAT networking...
==> k3s-1: Setting the name of the VM: k3s-1
==> k3s-1: Clearing any previously set network interfaces...
==> k3s-1: Preparing network interfaces based on configuration...
    k3s-1: Adapter 1: nat
    k3s-1: Adapter 2: bridged
==> k3s-1: Forwarding ports...
    k3s-1: 22 (guest) => 2222 (host) (adapter 1)
==> k3s-1: Running 'pre-boot' VM customizations...
==> k3s-1: Booting VM...
==> k3s-1: Waiting for machine to boot. This may take a few minutes...
    k3s-1: SSH address: 127.0.0.1:2222
    k3s-1: SSH username: vagrant
    k3s-1: SSH auth method: private key
    k3s-1: Warning: Remote connection disconnect. Retrying...
    k3s-1: Warning: Connection reset. Retrying...
==> k3s-1: Attempting graceful shutdown of VM...
==> k3s-1: Attempting graceful shutdown of VM...
...
```

Después de un tiempo intentantdo el *graceful shutdown* de la VM, se produce el error (lo muestro en dos líneas):

```bash
/usr/share/rubygems-integration/all/gems/net-ssh-6.1.0/lib/net/ssh/transport/kex/ecdh_sha2_nistp256.rb:21:in \
`generate_key!': pkeys are immutable on OpenSSL 3.0 (OpenSSL::PKey::PKeyError)
...
```

Al buscar el mensaje de error en Google, he llegado a la página [Vagrant up error on Ubuntu 22.04: pkeys are immutable on OpenSSL 3.0](https://discuss.hashicorp.com/t/vagrant-up-error-on-ubuntu-22-04-pkeys-are-immutable-on-openssl-3-0/38734) de los foros de Hashicorp.

El problema está reportado también tras la actualización de Pop_OS! de 20.04 a 22.04 y apunta a una entrada en StackOverflow.

En StackOverflow, el problema está reportado para Ubuntu 22.04 en la que se indica que la solución pasa por instalar la versión 2.2.19 de Vagrant a partir del paquete `.deb` de instalación. De hecho, el autor de la respuesta en StackOverflow indica que la solución procede del *issue* [Vagrant up fails with Ubuntu 22.04 #12751](https://github.com/hashicorp/vagrant/issues/12751) en el repositorio de Vagrant.

La causa raíz del problema está (o eso parece) en un problema de compatibilidad del paquete [`ruby-net-ssh`](https://bugs.launchpad.net/ubuntu/+source/ruby-net-ssh/+bug/1964025) relacionado con SSL 3.0

La instalación de Vagrant 2.2.19 soluciona el problema:

```bash
sudo apt install vagrant=2.2.19
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following packages were automatically installed and are no longer required:
  ...
Use 'sudo apt autoremove' to remove them.
The following packages will be DOWNGRADED:
  vagrant
0 to upgrade, 0 to newly install, 1 to downgrade, 0 to remove and 0 not to upgrade.
Need to get 41,5 MB of archives.
After this operation, 113 MB of additional disk space will be used.
Do you want to continue? [Y/n] y
Get:1 https://apt.releases.hashicorp.com jammy/main amd64 vagrant amd64 2.2.19 [41,5 MB]
Fetched 41,5 MB in 11s (3.854 kB/s)                                                                                                                        
dpkg: warning: downgrading vagrant from 2.2.19+dfsg-1ubuntu1 to 2.2.19
(Reading database ... 272930 files and directories currently installed.)
Preparing to unpack .../vagrant_2.2.19_amd64.deb ...
Unpacking vagrant (2.2.19) over (2.2.19+dfsg-1ubuntu1) ...
Setting up vagrant (2.2.19) ...
Processing triggers for man-db (2.10.2-1) ...
```

Como se indica en el foro de Hashicorp, el *downgrade* es entre:

```bash
Unpacking vagrant (2.2.19) over (2.2.19+dfsg-1ubuntu1) ...
```

Pero bueno, funciona ¯\\\_(ツ)_/¯
