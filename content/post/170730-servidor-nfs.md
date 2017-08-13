+++
draft = true
tags = ["linux", "alpine", "nfs"]
categories = ["ops"]
thumbnail = "images/linux.png"
title =  "Configurar un servidor NFS"
date = "2017-07-30T08:54:00+02:00"

+++

Uno de los temas pendientes relacionado con Kubernetes es el almacenamiento en el clúster. En Docker es sencillo montar un volumen del _host_ en el contenedor. En Kubernetes, al tratarse de un clúster, el _scheduler_ puede planificar el _pod_ en cualquier nodo. Si el _pod_ es eliminado del nodo1, desde donde había montado un volumen, cuando se arranca una nueva copia del _pod_ en el nodo2, es muy probable que en este nodo no exista la misma carpeta. Y si existe, no contendrá los datos que existían en el nodo1.

Hay varias soluciones para el problema; la más sencilla es que el almacenamiento de los _pods_ esté **fuera** del clúster y se monte por NFS.

En este artículo voy a explorar el primer paso para conseguir disponer de almacenamiento vía NFS en los _pods_ del clúster de Kubernetes.
<!--more-->

En primer lugar voy a usar una máquina con Ubuntu Server 16 LTS como servidor NFS, así que empiezo actualizando:

```shell
sudo apt-get update && sudo apt-get upgrade -y
````

Apago la máquina y hago un _snapshot_.

# Instalación del servidor NFS

La instalación del paquete NFS se realiza mediante `apt-get install nfs-kernel-server`:

```shell
$ sudo apt-get install nfs-kernel-server
[sudo] password for operador:
Reading package lists... Done
Building dependency tree
Reading state information... Done
The following additional packages will be installed:
  keyutils libnfsidmap2 libpython-stdlib libpython2.7-minimal libpython2.7-stdlib libtirpc1 nfs-common python
  python-minimal python2.7 python2.7-minimal rpcbind
Suggested packages:
  watchdog python-doc python-tk python2.7-doc binutils binfmt-support
The following NEW packages will be installed:
  keyutils libnfsidmap2 libpython-stdlib libpython2.7-minimal libpython2.7-stdlib libtirpc1 nfs-common
  nfs-kernel-server python python-minimal python2.7 python2.7-minimal rpcbind
0 upgraded, 13 newly installed, 0 to remove and 0 not upgraded.
Need to get 4,383 kB of archives.
After this operation, 18.5 MB of additional disk space will be used.
Do you want to continue? [Y/n]
...
```

# Creación de la carpeta compartida y asignación de permisos

Una vez instalado, el siguiente paso es crear la carpeta que vamos a exportar a través de NFS. En nuestro caso, creamos la carpeta `/var/nfs/storage` mediante el comando:

```shell
sudo mkdir /var/nfs/storage -p
````

Al haber utilizado `sudo`, la carpeta pertence al `root`:

```shell
$ ls /var/nfs/storage/ -la
total 8
drwxr-xr-x 2 root root 4096 Jul 30 11:29 .
drwxr-xr-x 3 root root 4096 Jul 30 11:29 ..
````

NFS convierte todas las operaciones en el cliente realizadas por el `root` (del cliente) a las credenciales `nobody:nogroup` como medida de seguridad. Por tanto, necesitamos cambiar el propietario de la carpeta.

```shell
sudo chown nobody:nogroup /var/nfs/storage
```

Ahora la carpeta está lista para ser exportada por NFS.

# Exportación de las carpetas compartidas en el servidor _host_

El siguiente paso es indicar al servidor NFS qué carpetas están listas para ser compartidas a través de la red.

Para ello, editamos el fichero `/etc/exports`:

```shell
sudo nano /etc/exports
```

> Comprobamos mediante `cat /etc/exports` que el fichero no contiene ninguna configuración previa. En caso contrario, haríamos una copia de seguridad mediante `sudo cp /etc/exports /etc/exports.bkp` por precaución.

La sintaxis del fichero `/etc/exports` es:

* Carpeta a compartir
* cliente (opcion1, opcion2, ..., opcionN)

Tenemos que crear una línea para cada una de las carpetas que queremos compartir En nuestro ejemplo, el cliente tiene la IP (ficticia) `192.168.1.256`, por lo que la configuración en el fichero `/etc/exports` será:

```txt
/var/nfs/storage  192.168.1.10(rw,sync,no_subtree_check)
```

> La opción de autenticar el sistema cliente a través de la IP puede ser un problema cuando estamos trabajando con contenedores (a no ser que el acceso al host NFS se realice desde los nodos del clúster, que sí que tienen IPs definidas y que no cambian). Revisar esto!!

Las opciones que hemos incluido significan:

* **rw**: La máquina cliente tiene acceso de lectura y escritura
* **sync**: Esta opción fuerza a NFS a escribir los cambios al disco antes de responder. Esta opción resulta en un entorno más estable y consistente, ya que la respuesta refleja el estado real del volumen remoto. En contrapartida, las operaciones sobre los ficheros se ejecutan más lentamente.
* **no_subtree_check**: Esta opción evita que NFS deba comprobar si el fichero todavía está disponible en el arbol de carpetas exportado durante cada petición. Esto puede provocar problemas si el fichero se renombra mientras el cliente lo tiene abierto. En general, es mejor dejar desactivada siempre esta opción.

Una vez finalizada la configuración es necesario reiniciar el servicio NFS para que los cambios sean efectivos.

```shell
sudo systemctl restart nfs-kernel-server
```

El siguiente paso es montar la carpeta compartida en el servidor vía NFS en el cliente. Como nuestros clientes van a ser _pods_ desde el clúster Kubernetes, antes se seguir la configuración de [How To Set Up an NFS Mount on Ubuntu 16.04 en DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nfs-mount-on-ubuntu-16-04), voy a revisar la documentación en [Kubernetes.io](https://kubernetes.io).

# [Volumes en Kubernetes.io](https://kubernetes.io/docs/concepts/storage/volumes/)

Notas:

* To use a volume, a pod specifies what volumes to provide for the pod (the `spec.volumes` field) and where to mount those into containers(the `spec.containers.volumeMounts` field).

Creo que la IP que debe autorizarse en el fichero `/etc/exports/` es la del nodo **master**, ya que supongo que éste es el que conecta con el servidor NFS. Sin embargo, no he encontrado ningún sitio donde se especifique (se da por supuesto) la configuración del servidor NFS para Kubernetes.

En la documentación de Red Hat [CHAPTER 2. GET STARTED PROVISIONING STORAGE IN KUBERNETES](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux_atomic_host/7/html/getting_started_with_kubernetes/get_started_provisioning_storage_in_kubernetes) se indica cómo crear los _Persistent Volumes_ y los _Persistent Volume Claim_, así como la manera de montar estos volúmenes desde un _pod_.