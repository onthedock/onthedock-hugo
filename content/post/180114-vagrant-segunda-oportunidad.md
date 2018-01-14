+++
draft = false
# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["windows", "hyper-v", "vagrant", "automation"]

thumbnail = "images/vagrant.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" %}}

title=  "Vagrant: Segunda oportunidad (y mejores sensaciones que la primera vez)"
date = "2018-01-14T17:28:40+01:00"
+++

Después de una [primera toma de contacto]({{<ref "170521-vagrant-primeras-impresiones.md" >}}) con sabor agridulce, estos días festivos he dedicado algo más de tiempo a dar una segunda oportunidad a Vagrant.

En este artículo recojo mis impresiones en esta nueva toma de contacto.
<!--more-->

## Escenario: Vagrant en Windows 10 y Hyper-V

Después de haber estado realizando pruebas con XenServer en la máquina de laboratorio acabé instalando Windows 10. Así que cuando necesité máquinas virtuales, la opción más lógica me pareció usar Hyper-V.

Vagrant permite usar Hyper-V como _provider_ de máquinas virtuales, aunque la opción por defecto es VirtualBox.

## Instalación

Desde [Vagrant](https://www.vagrantup.com/docs/installation/) se recomienda descargar el binario directamente desde la web oficial, incluso para las distribuciones Linux (que suelen instalar a través del gestor de paquetes integrado).

En el caso de Windows la única opción es la descarga desde [Download Vagrant](https://www.vagrantup.com/downloads.html).

Tras instalar la versión de 64bits para Windows es necesario reiniciar.

## Verificar la instalación

Para verificar si Vagrant se ha instalado correctamente, abre un terminal y escribe:

```shell
> vagrant -v
Vagrant 2.0.1
```

Esto demuestra que Vagrant está correctamente instalado en la máquina.

El siguiente paso es verificar si empezar a usar Hyper-V como _provider_ de máquinas virtuales.

## Configuración del proyecto

Siguiendo las indicaciones de la página del sitio de Vagrant [Project Setup](https://www.vagrantup.com/intro/getting-started/project_setup.html), creo una carpeta para lanzar `vagrant init`.

```shell
m:> mkdir vagrant
m:> cd vagrant
m:\vms\vagrant>
```

Lanzamos `vagrant init`:

```shell
m:\vms\vagrant>vagrant init
A `Vagrantfile` has been placed in this directory. You are now
ready to `vagrant up` your first virtual environment! Please read
the comments in the Vagrantfile as well as documentation on
`vagrantup.com` for more information on using Vagrant.
```

## Revisión del fichero `Vagrantfile`

Si abrimos el fichero `Vagrantfile` con un editor de texto, observamos que contiene una gran cantidad de comentarios, con las opciones más comunes para configurar las `boxes`, que es la manera en las que Vagrant denomina las máquinas virtuales.

El contenido del fichero, sin la mayoría de los comentarios, es simplemente:

```Vagrantfile
Vagrant.configure("2") do |config|

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  config.vm.box = "base"

end
```

Antes de lanzar `vagrant up` es necesario sustituir `base` por el nombre de una imagen base válida.

## Boxes

En vez de construir una máquina virtual desde cero, Vagrant usa una imagen base para generar una nueva máquina. Especificar la imagen base es el primer paso después de crear el fichero `Vagrantfile`.

Las _boxes_ se añaden a Vagrant usando el comando `vagrant box add`. Este comando descarga y almacena la imagen base especificada de manera que pueda ser reusadas por varios proyectos.

> En mi primera toma de contacto indiqué que las imágenes base se almacenan en la unidad de instalación de Vagrant (por defecto, la unidad c:\). No he encontrado la manera de almacenar las _boxes_ en otra ubicación.
>
> Sólo uso unas pocas imágenes base -Alpine y Debian-, por lo que no supone un problema insalvable, pero es un dato a tener en cuenta de cara a hacer un uso continuado de Vagrant con múltiples imágenes (hay que realizar una limpieza de las _boxes_ antiguas en desuso o consumirán una cantidad importante de disco.)

Pu edes encontrar _boxes_ compartidas por otros usuarios en [Vagrant Cloud](https://app.vagrantup.com/boxes/search).

Al usar Hyper-V, debo filtrar las imágenes base para el _provider_ `hyperv`: [Vagrant Cloud + provider=hyperv](https://app.vagrantup.com/boxes/search?provider=hyperv)

En mi caso voy a probar con la _box_ [`generic/alpine36`](https://app.vagrantup.com/generic/boxes/alpine36) (actualmente en la versión v1.3.30).

```shell
M:\VMS\vagrant>vagrant box add generic/alpine36
==> box: Loading metadata for box 'generic/alpine36'
    box: URL: https://vagrantcloud.com/generic/alpine36
This box can work with multiple providers! The providers that it
can work with are listed below. Please review the list and choose
the provider you will be working with.

1) hyperv
2) libvirt
3) virtualbox
4) vmware_desktop

Enter your choice: 1
==> box: Adding box 'generic/alpine36' (v1.3.30) for provider: hyperv
    box: Downloading: https://vagrantcloud.com/generic/boxes/alpine36/versions/1.3.30/providers/hyperv.box
    box: Progress: 100% (Rate: 20.7M/s, Estimated time remaining: --:--:--)
==> box: Successfully added box 'generic/alpine36' (v1.3.30) for 'hyperv'!

M:\VMS\vagrant>
```

La imagen base está disponible para diferentes _providers_, por lo que el comando `vagrant box add` requiere que seleccionemos el gestor de máquinas virtuales que preferimos.

Para evitar esta interrupción del script, usaremos el parámetro `--provider hyperv` al lanzar `vagrant <cmd>`:

```shell
> vagrant box add generic/alpine36 --provider hyperv
```

## Usando la _box_ en Vagrant

Para usar la _box_ en Vagrant, la especificamos en el fichero `Vagrantfile`.

En Windows 10 con Hyper-V debemos especificar el _provider_ (por defecto se considera Virtual Box). Para evitar incluirlo en la línea de comandos cada vez que queramos realizar una operación con la _box_, podemos especificarlo en el `Vagrantfile`:

```Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.box = "generic/alpine36"
  config.vm.provider = "hyperv"
end
```

Vagrant no sabe cómo configurar la red para Hyper-V, por lo que es necesario especificar manualmente Hyper-V de manera que Vagrant funcione. La manera más sencilla de conseguirlo es usando un _vSwitch_ con conectividad externa.

El `Vagrantfile` queda finalmente:

```Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.box = "generic/alpine36"
  config.vm.provider = "hyperv"
  config.vm.network = "public_network"
end
```

## Configuraciones específicas de Hyper-V

Una de las recomendaciones para usar Vagrant con Hyper-V es la activar las _extensiones de virtualización_ y los discos diferenciales.

```Vagrantfile
config.vm.provider "hyperv" do |h|
  h.enable_virtualization_extensions = true
  h.differencing_disk = true
end
```

De esta forma, el fichero de configuración queda:

```Vagrantfile
Vagrant.configure("2") do |config|
   config.vm.box = "generic/alpine36"
   config.vm.provider = "hyperv"
   config.vm.network "public_network"

   config.vm.provider "hyperv" do |h|
      h.enable_virtualization_extensions = true
      h.differencing_disk = true
   end
end
```

## Usar Hyper-V como proveedor por defecto

Podemos especificar Hyper-V como _provider_ por defecto estableciendo la variable de entorno `VAGRANT_DEFAULT_PROVIDER` tal y como se especifica en [Basic Provider Usage](https://www.vagrantup.com/docs/providers/basic_usage.html), por ejemplo, desde PowerShell:

```Powershell
[Environment]::SetEnvironmentVariable("VAGRANT_DEFAULT_PROVIDER", "hyperv", "User")
```

## Arrancando la máquina

Una vez configurada la máquina, es el momento de arrancarla usando `vagrant up` (desde carpeta donde se encuentra el fichero `Vagrantfile`).

```shell
M:\VMS\vagrant>vagrant up
No usable default provider could be found for your system.

Vagrant relies on interactions with 3rd party systems, known as
"providers", to provide Vagrant with resources to run development
environments. Examples are VirtualBox, VMware, Hyper-V.

The easiest solution to this message is to install VirtualBox, which
is available for free on all major platforms.

If you believe you already have a provider available, make sure it
is properly installed and configured. You can see more details about
why a particular provider isn't working by forcing usage with
`vagrant up --provider=PROVIDER`, which should give you a more specific
error message for that particular provider.
```

Como vemos, pese a que en el fichero `Vagrantfile` se especifica el _provider_, Vagrant no parece capaz de encontrarlo.

Lo intento de nuevo, especificando el proveedor desde la línea de comandos:

```shell
M:\VMS\vagrant>vagrant up --provider=hyperv
The provider 'hyperv' that was requested to back the machine
'default' is reporting that it isn't usable on this system. The
reason is shown below:

The Hyper-V provider requires that Vagrant be run with
administrative privileges. This is a limitation of Hyper-V itself.
Hyper-V requires administrative privileges for management
commands. Please restart your console with administrative
privileges and try again.
```

Ahora el problema es que Hyper-V requiere que Vagrant se lance con permisos de administrador (como indica la documentación: [Providers > Hyper-V > Usage](https://www.vagrantup.com/docs/hyperv/usage.html)).

En el tercer intento, después de lanzar una consola con permisos de administrador, el mensaje de error indica:

```shell
M:\VMS\vagrant> vagrant up
Bringing machine 'default' up with 'hyperv' provider...
==> default: Verifying Hyper-V is enabled...
There are errors in the configuration of this machine. Please fix
the following errors and try again:

vm:
* The following settings shouldn't exist: provider
```

Comento la línea relativa al proveedor y lo intento de nuevo:

```shell
M:\VMS\vagrant> vagrant up
Bringing machine 'default' up with 'hyperv' provider...
==> default: Verifying Hyper-V is enabled...
==> default: Configured Dynamic memory allocation, maxmemory is 2048
==> default: Configured startup memory is 2048
==> default: Configured cpus number is 2
==> default: Configured enable virtualization extensions is true
==> default: Configured differencing disk instead of cloning
==> default: Importing a Hyper-V instance
    default: Please choose a switch to attach to your Hyper-V instance.
    default: If none of these are appropriate, please open the Hyper-V manager
    default: to create a new virtual switch.
    default:
    default: 1) Default Switch
    default: 2) EXTERNAL-vSwitch
    default:
    default: What switch would you like to use? 2
    default: Cloning virtual hard drive...
    default: Creating and registering the VM...
    default: Setting VM Integration Services
    default: Successfully imported a VM with name: generic-alpine36-hyperv
==> default: Starting the machine...
==> default: Waiting for the machine to report its IP address...
    default: Timeout: 120 seconds
    default: IP: 192.168.1.228
==> default: Waiting for machine to boot. This may take a few minutes...
    default: SSH address: 192.168.1.228:22
    default: SSH username: vagrant
    default: SSH auth method: private key
    default:
    default: Vagrant insecure key detected. Vagrant will automatically replace
    default: this with a newly generated keypair for better security.
    default:
    default: Inserting generated public key within guest...
    default: Removing insecure key from the guest if it's present...
    default: Key inserted! Disconnecting and reconnecting using new SSH key...
==> default: Machine booted and ready!
```

Esta vez arranca, aunque hay que especificar manualmente el _vSwitch_ (de los existentes en Hyper-V, aunque sólo hay uno conectado a la red pública). El _provider_ para Hyper-V no permite configurar la red en Vagrant; esta es una de las [limitaciones conocidas](https://www.vagrantup.com/docs/hyperv/limitations.html) para Hyper-V.

### Workaround

En este [comentario](https://github.com/hashicorp/vagrant/issues/7915#issuecomment-286874774) del hilo [enhancement: hyper-v provider vswitch customization parameter #7915](https://github.com/hashicorp/vagrant/issues/7915) se indica un _workaround_ para conseguir que Vagrant seleccione automáticamente el vSwitch:

```Vagrantfile
   config.vm.network "public_network", bridge: "<vSwitchName>"
```

## Conexión a la VM

Para conectar a la máquina virtual se indica que hay que usar `ssh` y la clave privada asociada al usuario `vagrant`.

Revisando los subcomandos de `vagrant`, vemos que podemos conectar a la máquina virtual usando `vagrant ssh default` (donde `default` es el nombre de la _box_):

```shell
M:\VMS\vagrant\> vagrant ssh default
bazinga:~$ cat /etc/os-release
NAME="Alpine Linux"
ID=alpine
VERSION_ID=3.6.2
PRETTY_NAME="Alpine Linux v3.6"
HOME_URL="http://alpinelinux.org"
BUG_REPORT_URL="http://bugs.alpinelinux.org"
```

> Cuando probé Vagrant la primera vez pensaba que el comando `vagrant ssh <vm>` no funcionaría desde Windows al no existir un cliente SSH. Sin embargo, Vagrant incorpora un cliente SSH con el que conectar a las máquinas en la instalación.

## Acceso a la máquina linux usando PuTTY

> Se considera una buena práctica que también sea posible acceder a las _boxes_ Vagrant usando el usuario y password `vagrant` (ver [Default User Settings](https://www.vagrantup.com/docs/boxes/base.html) en _Creating a Base Box_).

Después de toda una vida usando PuTTY para conectar a las máquinas virtuales con Linux, decidí probar de todas formas a conectar usando este popular cliente SSH para Windows.

> No hemos especificado nombre para la VM, por lo que Vagrant la ha llamado `default`

La clave privada se encuentra en la subcarpeta desde donde hemos lanzado `vagrant init`: `.vagrant\machines\default\hyperv\private_key`

> Al crear una _box_ se usa una [clave privada insegura](https://github.com/hashicorp/vagrant/tree/master/keys), que se susituye por una clave segura durante el primer acceso a la VM.

Al intentar conectar con PuTTY, usando la clave privada directamente:

```shell
Unable to use key file "M:\VMS\vagrant\.vagrant\machines\default\hyperv\private_key" (OpenSSH SSH-2 private key (old PEM format))
login as: vagrant
vagrant@192.168.1.228's password:
```

Es decir, no podemos usar la clave directamente en PuTTY.

Para poder usar una clave privada generada por SSH en PuTTY debemos convertirla usando PuTTYgen.

Cargamos la clave `private_key` y la guardamos en el formato `ppk` usado por PuTTY. Ahora podemos conectar a la máquina virtual usando este fichero con la clave privada (en _Connection > SSH > Auth_, en el campo _Private key file for authentication:_).

```shell
login as: vagrant
Authenticating with public key "alpine"
bazinga:~$
```

## Mejoras

Es probable que querramos definir propiedades específicas para las VMs, como el _hostname_, el nombre de la VM o su IP... A continuación se indica cómo realizar las configuraciones en Hyper-V.

### Especificar el nombre de la máquina virtual y el _hostname_

La propiedad `vmname` del _provider_ `hyperv` permite especificar el nombre de la máquina virtual creada en Hyper-V. Mediante la propiedad `config.vm.hostname` especificamos el _hostname_ del sistema operativo en la máquina virtual.

### Especificar recursos de la VM

Dentro de la sección general de configuración de la VM, asignamos los recursos asignados a la VM:

```Vagrantfile
   # Configuración de recursos de la VM
   config.vm.provider :hyperv do |v, override|
      v.cpus = 2
      v.memory = 2048
      v.maxmemory = 2048
```

### Asignar IP estática a la VM

En la versión actual 2.0.1 no es posible especificar una IP estática al sistema operativo _guest_ de la VM para el _provider_ Hyper-V.

Para máquinas Linux podemos utilizar algún método alternativo, como darlas de alta en un DNS en cada arranque o estableciendo la IP de forma estática mediante los scripts de _provisioning_.

## Provisioning

Se puede realizar un _provisioning_ básico usando [_shell scripts_](https://www.vagrantup.com/docs/provisioning/shell.html). Para configuraciones complejas, es más eficiente crear una [_box_ personalizada](https://www.vagrantup.com/docs/boxes/base.html) que contenga todas las modificaciones que son necesarias. Finalmente, también existe la opción de usar aplicaciones como [Ansible](https://www.vagrantup.com/docs/provisioning/ansible.html) para realizar la instalación de software.

Para poder usar Ansible con Vagrant, deben estar instalados en la **misma máquina**. Esto supone un problema en mi configuración actual, ya que Ansible está instalado en una VM sobre Hyper-V, mientras que Vagrant está instalado en la máquina _host_ donde corre Hyper-V.

### Alternativa: VM con Lubuntu con Ansible y Vagrant

He creado una máquina con Linux con la idea de usarla como _mini-laboratorio_, instalando Vagrant con Virtual Box y Ansible sobre Linux, de manera que se cumplan todos los requerimientos. El objetivo es poder desplegar máquinas virtuales mediante Vagrant y gestionar la configuración e instalación de software con Ansible.

El problema es que parece que Hyper-V no expone las características de virtualización del procesador a las máquinas virtuales, lo que no permite crear máquinas virtuales (Virtual Box) dentro de máquinas virtuales (Hyper-V).

Buscando en Google he encontrado referencias a la capacidad de Hyper-V de lo que se denomina _nested virtualization_.

#### Nested virtualization

La _virtualización anidada_ es una característica de Windows 2016 Server o Windows 10 Anniversary Update (o superior) que permite crear máquinas con Hyper-V dentro de máquinas virtuales con Hyper-V. Sin embargo, esta opción de momento sólo está disponible para procesadores Intel (ver referencia [Run Hyper-V in a Virtual Machine with Nested Virtualization](https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/user-guide/nested-virtualization)):

> The Hyper-V host and guest must both be Windows Server 2016/Windows 10 Anniversary Update or later.
> VM configuration version 8.0 or greater.
> An Intel processor with VT-x and EPT technology -- nesting is currently Intel-only.
> There are some differences with virtual networking for second-level virtual machines. See "Nested Virtual Machine Networking".

En mi caso la máquina de laboratorio tiene procesador AMD, así que he llegado al final del camino por esta vía.

## Provisioning integrado en Vagrant vía shell

La _box_ base que estoy usando corre Alpine Linux, por lo que he creado el siguiente _shell script_ para instalar Git:

```shell
sudo apk update
sudo apk upgrade
sudo apk add git
```

He llamado `bootstrap.sh` al fichero y lo he guardado en la misma carpeta en la que se encuentra el fichero `Vagrantfile`.

Modifico el `Vagrantfile` añadiendo la ruta al fichero de aprovisionamiento:

```Vagrantfile
...
   config.vm.provision "shell" do |s|
      s.path= "bootstrap.sh"
   end
```

Referencia: [Shell Provisioner](https://www.vagrantup.com/docs/provisioning/shell.html)

Este script sólo se ejecuta durante la creación de la máquina virtual. Para que se ejecute una vez la máquina ya ha sido creada, hay que especificar el parámetro `--provision`: `vagrant reload --provision`. Esta acción apaga la máquina y la vuelve a arrancar.

> Las modificaciones realizadas por el script no se eliminan al lanzar `reload`, por lo que debes eliminarlas manualmente (lo que debe tenerse en cuenta durante el desarrollo de estos scripts).

La salida del comando `vagrant reload --provision` se muestra a continuación:

```shell
M:\VMS\vagrant\alpine> vagrant reload --provision
==> default: Attempting graceful shutdown of VM...
==> default: Starting the machine...
==> default: Waiting for the machine to report its IP address...
    default: Timeout: 120 seconds
    default: IP: 192.168.1.235
==> default: Waiting for machine to boot. This may take a few minutes...
    default: SSH address: 192.168.1.235:22
    default: SSH username: vagrant
    default: SSH auth method: private key
==> default: Machine booted and ready!
==> default: Running provisioner: shell...
    default: Running: C:/Users/Xavi/AppData/Local/Temp/vagrant-shell20180106-7468-5nbvly.sh

    default: fetch https://dl-3.alpinelinux.org/alpine/v3.6/main/x86_64/APKINDEX.tar.gz
    default: fetch https://mirror.leaseweb.com/alpine/v3.6/main/x86_64/APKINDEX.tar.gz
    default: v3.6.2-240-geb8d8205d9 [https://dl-3.alpinelinux.org/alpine/v3.6/main]
    default: v3.6.2-240-geb8d8205d9 [https://mirror.leaseweb.com/alpine/v3.6/main]
    default: OK: 5553 distinct packages available
    default: OK: 164 MiB in 68 packages
    default: (1/2) Installing expat (2.2.0-r1)
    default: (2/2) Installing git (2.13.5-r0)
    default: Executing busybox-1.26.2-r9.trigger
    default: OK: 183 MiB in 70 packages

M:\VMS\vagrant\alpine>
```

(En la salida por consola, los comandos ejecutados desde el _script_ de aprovisionamiento se muestran en otro color).

## Averiguar la IP de una _box_

En general no es necesario conocer la IP de la VM creada a través de `vagrant up` (ya que podemos conectar usando `vagrant ssh`, sin especificar nada más). Para averiguar la dirección IP asignada a la VM usaremos `vagrant ssh-config`.

En Hyper-V, por ejemplo, no es posible especificar una IP estática para la máquina virtual.

La salida de `vagrant ssh-config` debe _parsearse_ para obtener la dirección IP de la máquina, ya que no he encontrado la forma de filtrar la salida del comando.

## Múltiples máquinas en un Vagrantfile

Referencia: [Multi-Machine](https://www.vagrantup.com/docs/multi-machine/)

Vagrant permite definir múltiples máquinas virtuales en un solo fichero `Vagrantfile` usando el método `config.vm.define`. Esto permite insertar un fichero de configuración dentro de otro fichero de configuración. El contenido _fuera_ del bloque `define` es común para todas las máquinas en el `Vagrantfile`, mientras los parámetros dentro del bloque `define` se aplican a la máquina especificada.

En el siguiente ejemplo, las tres máquinas parten de la imagen base `generic/debian9` y están conectadas a la red pública. Los recursos asignados a las tres máquinas son los mismos. La configuración específica para las máquinas virtuales se limita a especificar el nombre de la VM y el _hostname_.

```Vagrantfile
Vagrant.configure("2") do |config|
   config.vm.box = "generic/debian9"
   config.vm.network "public_network", bridge: "EXTERNAL-vSwitch"

   # Configuración de recursos de la VM
   config.vm.provider "hyperv" do |v, override|
      v.cpus = 2
      v.memory = 2048
      v.maxmemory = 2048
      v.enable_virtualization_extensions = true
      v.differencing_disk = true
   end

   config.vm.define "k0" do |k0|
      k0.vm.hostname = "k0"
      config.vm.provider "hyperv" do |h0|
         h0.vmname = "k0"
      end
   end

   config.vm.define "k1" do |k1|
      k1.vm.hostname = "k1"
      config.vm.provider "hyperv" do |h1|
         h1.vmname = "k1"
      end
   end

   config.vm.define "k2" do |k2|
      k1.vm.hostname = "k2"
      config.vm.provider "hyperv" do |h2|
         h1.vmname = "k2"
      end
   end
end
```

En general, cada máquina parte de una imagen base diferente.

Mi objetivo es crear un clúster de Kuberentes, por lo que a partir de la instalación base con Debian habría que instalar Docker y después Kubernetes (en el mejor de los casos, usando `kubeadm`). Sin embargo, realizar la misma instalación una y otra vez no es la manera más eficiente de construir el clúster. En vez de ello, lo ideal es crear una imagen base (_box_) personalizada, con Docker y Kubernetes preinstalado y configurado.

La creación de una _box_ personalizada la dejo para otra entrada, aunque si estás interesado en seguir en esta línea, consulta la documentación oficial al respecto [Creating a Base Box](https://www.vagrantup.com/docs/boxes/base.html).

# Conclusiones

Vagrant permite _levantar_ máquinas virtuales de manera sencilla usando los parámetros por defecto establecidos en la _box_ base.

La personalización de las máquinas virtuales generadas para adaptarlas a las necesidades de cada proyecto supone invertir tiempo en desarrollar el fichero `Vagrantfile` con las opciones adecuadas para cada _provider_.

En la mayoría de ejemplos se asume que el _provider_ usado es VirtualBox o AWS, por lo que cuando usas otro proveedor de máquinas virtuales a veces las cosas no funcionan como se indica.

Al usar un proveedor menos popular, algunas opciones no están presentes o no funcionan (como establecer una IP estática)... En el caso de VMWare, por ejemplo, el _provider_ -la integración- [es de pago](https://www.vagrantup.com/vmware/index.html) (79 US$).

Usar Ruby para los ficheros de configuración parece una elección algo arbitraria, cuando podría utilizarse una solución más **neutral** como YAML o JSON.

Como solución de _infrastructure as code_ **casera** Vagrant cumple su cometido, generando las máquinas de manera rápida y efectiva.

A nivel funcional, está un paso por encima de los scripts de automatización, pero lejos de otras soluciones que permiten realizar aprovisionamiento de máquinas bajo demanda.

Frente a estas soluciones -que suelen estar ligadas a un único proveedor de VMs-, Vagrant proporciona la **flexibilidad** de cambiar fácilmente de _provider_ manteniendo cierta homogeneidad -en la medida que lo permita el _plugin_ del _provider_- en la definición de la infraestructura.