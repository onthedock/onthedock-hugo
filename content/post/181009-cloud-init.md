+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "cloud-init"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/cloud-init.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}

title=  "Automatizando la personalización de máquinas virtuales con cloud-init"
date = "2018-10-10T20:11:56+02:00"
+++

_cloud-init_ se define como **el estándar para personalizar instancias _cloud_**. Las imágenes para las instancias _cloud_ empiezan siendo idénticas entre sí, al ser clones. Es la información proporcionada por el usuario lo que le da a la instancia su _personalidad_ y _cloud-init_ es la herramienta que aplica esta configuración a las instancias de forma automática.

_cloud-init_ fue desarrollado inicialmente por Canonical para las imágenes _cloud_ de Ubuntu usadas por AWS. Desde entonces, la aplicación ha evolucionado y puede ser usada en otras muchas distribuciones y en otros entornos _cloud_ (y no _cloud_).

<!--more-->

Personalmente he estado usando Vagrant para simplificar y agilizar el proceso de creación de máquinas virtuales durante las pruebas con Docker y Kubernetes. Sin embargo, el hecho de usar _clones_ de una máquina base [presenta sus propios problemas específicos]({{<ref "180810-generando-un-machine-id-unico.md">}}).

La solución pasa por _generalizar_ la instalación del sistema operativo. Para ello, podemos encontrar _scripts_ que eliminan todos aquellos identificadores que deben ser únicos. Puedes encontrar uno de estos _scripts_ en la entrada [How to Generalize a Linux VM Template](https://nerddrivel.com/2016/08/23/how-to-generalize-a-linux-vm-template/).

Después de eliminar todas las características específicas del clon, pasamos a personalizar la instancia asignando un _hostname_, una IP, a instalar software, etc...

Una de las formas más potentes y sencillas de conseguir personalizar la máquina virtual es usar `cloud-init`.

## Personalizando la máquina virtual con _cloud-init_

`cloud-init` se instala como un paquete más en cualquiera de las distribuciones linux en las que está soportado. En mi caso, usaré Debian. (Ubuntu proporciona las [_cloud images_](http://cloud-images.ubuntu.com/), que incluyen `cloud-init`, pero no he tenido éxito con ellas). La instalación se realiza como la de cualquier otro paquete:

```shell
sudo apt install cloud-init
```

Una vez instalado, `cloud-init` se ejecuta durante el proceso de arranque de la máquina virtual e intenta obtener la configuración de la instancia a partir de algún _datasource_.

El _datasource_ es una abstracción que permite que `cloud-init` se adapte a los diferentes entornos en los que se ejecuta. Por ejemplo, el _datasource_ `NoCloud` proporciona información de configuración desde medios locales, como un diskette o una imagen de CD/DVD montada en la máquina virtual. Esto permite especificar parámetros de configuración incluso antes de que el sistema operativo haya _levantado_ la conexión de red.

`cloud-init` puede obtener los parámetros de configuración para la máquina a partir de ficheros en formato YAML o de _scripts_.

## Usando `cloud-init`

El primer paso para crear la plantilla a partir de la que crear los clones es instalar uno de los sistemas operativos soportados por `cloud-init` en una máquina virtual. Instala únicamente los paquetes mínimos necesarios (el resto los puedes instalar más adelanta a través de `cloud-init`). En esta instalación mínima, incluye `cloud-init`.

Crea una imagen base a partir de la instalación que acabas de realizar (el método varía para cada hipervisor). Para evitar problemas más adelante, elimina cualquier identificador único de la máquina virtual antes de crear esta "imagen-plantilla".

Si creas una nueva máquina virtual a partir de esta plantilla, observarás que el sistema operativo no arranca con éxito: después de una espera, el sistema entra en bucle intentando contactar con la URL [http://169.254.169.254/user-data](http://169.254.169.254/user-data). Esta URL forma parte del _datasource_ EC2 asociado a AWS.

Durante el arranque `cloud-init` intenta contactar con los _datasources_ configurados. En mi caso, pasaré la configuración de la máquina a través de los ficheros `user-data` y `meta-data`. Estos ficheros los guardaré en una imagen ISO que _pincharé_ a la máquina virtual para que `cloud-init` los encuentre durante el arranque.

> Las primeras pruebas las realicé con un _diskette virtual_, pero no tuve éxito hasta que empecé a usar una imagen ISO.

Como no existe ningún _cmdlet_ en PowerShell para crear una imagen ISO, he descargado de la versión para Windows del paquete `cdrtools`, que incluye `mkisofs.exe` desde [Cdrtools: Win x86_64 Binaries](https://www.student.tugraz.at/thomas.plank/index_en.html).

Para que `cloud-init` identifique la ISO como un _datasource_ debemos etiquetarla como `cidata`. En comando con el que he construido las imágenes es (`.\initimg` es la carpeta donde se encuentran los ficheros a copiar en la ISO):

```shell
mkisofs.exe -volid cidata -juliet -rational-rock -iso-level 2 -output init.iso .\initimg\
```

Conectamos la ISO y arrancamos la VM:

```ps
Set-VMDvdDrive -VMName TestVM -Path .\init.iso
Start-VM -Name TestVM
```

El fichero `meta-data` contiene el _ID_ de la instancia y la configuración IP:

```yml
instance-id: cloudimg
network-interfaces: |
  iface eth0 inet static
  address 192.168.1.199
  network 192.168.1.0
  netmask 255.255.255.0
  broadcast 192.168.1.255
  gateway 192.168.1.1
```

El fichero `user-data` contiene el grueso de la configuración.

```yml
#cloud-config
manage_etc_hosts: true
hostname: vm-userdata-04
fqdn: vm-userdata-04.lab.local

default:
mounts:
  - [ swap, null ]

# package_upgrade: true # Causes an upgrade (apt get upgrade -y)
packages: ['figlet']

timezone: "Europe/Madrid"

write_files:
  - path: /etc/cloud/cloud-init.disabled
```

En este ejemplo, el primer bloque especifica el _hostname_ de la máquina virtual. A continuación, inhabilita la _swap_, instala el paquete `figlet` y establece la zona horaria para configurar el reloj del sistema.

La última instrucción crea un fichero que deshabilita la ejecución de `cloud-init` (en caso contrario, se ejecutaría durante cada arranque). Una vez realizada la configuración de la máquina, podemos _desmontar_ la imagen ISO.

Esto es sólo una prueba de concepto para probar la capacidad de `cloud-init`; consulta los [ejemplos de la documentación oficial](https://cloudinit.readthedocs.io/en/latest/topics/examples.html) para hacerte una idea de las posibilidades que ofrece `cloud-init`.

# Resumen

Mediante _cloud-init_ podemos realizar la configuración automática de una máquina virtual a través de un fichero de configuración.

Podemos generar los ficheros de configuración de manera dinámica y específica para cada máquina. Aunque en esta primera prueba de concepto hemos entregado la configuración a través de ficheros en una imagen ISO, podemos hacer que `cloud-init` los obtenga accediendo a una URL desde un servidor web.

Después de dar el primer paso para adoptar la _infraestructura como código_ (usando Vagrant, scripts personalizados o cualquier otra opción), `cloud-init` nos permite seguir adelante personalizando las máquinas virtuales creadas a partir de una plantilla. 

`cloud-init` permite instalar software además de realizar configuración de la máquina, por lo que debemos valorar ventajas e inconvenientes de utilizar `cloud-init` frente a otras opciones especializadas como Ansible o Puppet, por ejemplo.