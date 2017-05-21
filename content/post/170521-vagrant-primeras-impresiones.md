+++
tags = ["windows", "hyper-v", "vagrant"]
draft = false
date = "2017-05-21T09:26:45+02:00"
title = "Vagrant: primeras impresiones"
thumbnail = "images/vagrant.png"
categories = ["dev"]

+++

He estado probando [Vagrant](https://www.vagrantup.com) para automatizar la creación de máquinas virtuales en las que probar Docker, etc.

En este artículo comento mis primeras impresiones con Vagrant. 

<!--more-->

La _tagline_ de Vagrant es _Development Environments made easy_. Atraido con la posibilidad de ser capaz de crear entornos de forma automática, instalé Vagrant. Tenía la sensación de que sería una especie de _Docker para máquinas virtuales_: hay un repositorio público de _boxes_ llamado [Atlas](https://atlas.hashicorp.com/boxes/search?) y con unos comandos como `vagrant init` y `vagrant up` parece posible _levantar_ un conjunto de máquinas preconfiguradas y listas para trabajar.

Pensaba que Vagrant trabajaba únicamente con VirtualBox, así que me alegré al ver que es posible trabajar con otros _providers_, en particular al ver que soporta Hyper-V _out of the box_.

Busqué una máquina con Ubuntu 16 LTS en Atlas filtrando por `provider hyperv` y encontré https://atlas.hashicorp.com/kmm/boxes/ubuntu-xenial64.

Mediante `vagrant init kmm/ubuntu-xenial64` se crea el Vagrantfile, que describe las configuración de la VM.

Para arrancar la máquina es necesario especificar el _provider_, ya que por defecto se asume VirtualBox: `vagrant up --provider hyperv`. El comando debe ejecutarse con permisos de administrador (debido a una limitación de Hyper-V).

Al lanzar el comando por primera vez, como no tengo una copia local de la _box_, debe descargarse. A diferencia de los contenedores, el tamaño de la máquina virtual es considerable. Afortunadamente la velocidad de la conexión y el hecho de que sólo tengo que hacerlo una vez mitigan este primer inconveniente.

El comando inicializa la máquina y la registra en Hyper-V con el nombre `ubuntu-xenial64`, arranca la máquina y obtiene una IP del DHCP. También se crea una clave SSH para poder conectar a la máquina y se monta una carpeta compartida entre la máquina virtual y el _host_ local (en la carpeta desde donde se lanza el comando `vagrant up`). La máquina virtual también se crea en esa carpeta.

## Conectando vía SSH

En la documentación se indica que para conectar a la VM, hay que usar el comando `vagrant ssh`. En Windows no funciona porque no hay un cliente SSH instalado por defecto.

En Windows lo habitual es usar PuTTY, pero resulta que la clave privada que se ha generado no es compatible y es necesario convertirla al formato `ppk`, usando [PuTTYgen](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html).

Al no tener una contraseña, esto significa que si quiero conectar desde otro equipo (por ejemplo, desde el Mac), tengo que copiar la clave privada al equipo.

## Nombre de la máquina virtual

Aunque en la documentación se indica que puede especificarse el nombre de la máquina virtual mediante la opción [`vmname`](https://www.vagrantup.com/docs/hyperv/configuration.html#vmname), en mi caso no ha funcionado.

## IP de la máquina virtual

Aunque la máquina virtual arranca con la IP configurada en modo DHCP, me gustaría especificar la IP de la máquina a crear. Buscando en Google he encontrado que la IP debería poder configurarse mediante el parámetro: `config.vm.network :public_network, ip: "192.168.1.30"`, tal y como se indica en [Public static ip for vagrant box](https://serverfault.com/questions/418422/public-static-ip-for-vagrant-box).

De nuevo, por algún motivo, no ha funcionado, obteniendo siempre la IP vía DHCP.

No soy el único al que le pasa, por lo que parece: [static IP not set correctly](https://github.com/cogitatio/vagrant-hostsupdater/issues/132). 

## Instalación de Docker

Al final del fichero `Vagrantfile` hay un apartado sobre _provisioning_, para poder instalar paquetes adicionales en la máquina virtual. En mi caso, estaba interesado en instalar Docker, por ejemplo.

Aunque en la documentación se indica que se pueden lanzar los comandos _tal cual_, de nuevo no ha funcionado como esperaba:

```shell
apt-get update
apt-get install docker.io -y
```

Tras el primer fallo he modificado el fichero `Vagrantfile` para que los comandos se lancen como `root` (`sudo apt-get update`), pero no sólo no he solucionado el problema, sino que además al intentar lanzar manualmente, conectado a la máquina virtual la instalación, obtenía un error indicando que el fichero estaba en uso.

## Montaje de la carpeta compartida

Inicialmente he pensado que sería una buena idea poder disponer de una carpeta _de intercambio_. Después de tener que lanzar múltiples máquinas virtuales para las pruebas de cambiar el nombre de la máquina virtual, la configuración de la IP, etc, me he dado cuenta que la carpeta compartida no sólo no me aporta nada, sino que ralentiza el proceso; se solicita usuario y password para montar la carpeta, de manera que el script se detiene (aunque la máquina arranca en Hyper-V). Incluso después de terminar el proceso mediante `Ctrl+C` he tenido problemas para seguir ejecutando otros comandos (`vagrant destroy`). En este caso, Ruby -el lenguaje usado por Vagrant- seguía en memoria y ha sido necesario matarlo a través del adminstrador de tareas para poder seguir ejecutando comandos Vagrant.

## Ubicación de la máquina virtual

Otro problema que me he encontrado es que la máquina virtual se crea en la misma carpeta desde donde se lanza el fichero `Vagrantfile`.

En Hyper-V se puede definir una ruta por defecto donde almacenar las máquinas virtuales, pero parece que Vagrant ignora esta configuración. 

En el equipo de laboratorio tengo dos discos, un SSD y un disco mecánico y he distribuido las máquinas virtuales según mis preferencias. Así que el hecho de que Vagrant cree las máquinas sin tener en cuenta la configuración del proveedor Hyper-V supone un problema que debería corregir, buscando en la configuración de Vagrant (si es que es posible modificar este comportamiento).

## Conclusión

Mi objetivo es automatizar la creación de una nueva máquina virtual con Docker y/o Kubernetes instalado.

Tengo dos máquinas virtuales exportadas con Docker y Kubernetes, respectivamente, por lo que Vagrant no aporta nada que no pueda hacer ahora mismo importando las máquinas en Hyper-V.

Mediante un script en Powershell importo la máquina virtual en Hyper-V con el nombre especificado; no he conseguido hacer lo mismo en Vagrant.

Personalmente prefiero crear un par de scripts con Powershell para conseguir especificar la IP, el nombre del host, etc que no tener que lidiar con el fichero de configuración de Vagrant.

Después de importar la máquina o de crearla vía Vagrant, tengo que conectar igualmente a la VM para cambiar el `hostname` y especificar una IP estática. Al usar la importación en Hyper-V ya tengo instalado Docker y/o Kubernetes, que en las máquinas creadas con Vagrant debo instalar manualmente.

No tengo claro si los problemas que he encontrado con Vagrant se deben a mi desconocimiento del producto o a problemas de _concepto_. Quizás es el hecho de usar un proveedor diferente al que se usa por defecto (Hyper-V vs VirtualBox) o al hecho de que el equipo donde se ejecutan las máquinas virtuales es diferente al equipo de _desarrollo_ (por el fichero `private_key` para conectar vía SSH).

En cualquier caso, Vagrant no se adapta a mis necesidades, creando fricción, por lo que seguiré buscando otras soluciones para automatizar la creación de las máquinas virtuales.