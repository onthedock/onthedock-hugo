+++
draft = false
categories = ["dev"]
tags = ["windows", "hyper-v", "vagrant", "automation"]
thumbnail = "images/vagrant.png"

title=  "Error `File already exists` al ejecutar vagrant package"
date = "2018-01-20T22:01:35+01:00"
+++

La manera más sencilla de crear una _box_ personalizada para Vagrant es reutilizar una máquina virtual ya creada con Vagrant. Para facilitar este proceso, Vagrant proporciona el comando `package`, que _empaqueta_ una máquina virtual existente en el formato _box_ de Vagrant.

En esta entrada comento los pasos que hay que realizar paso a paso para crear una _box_ personalizada. También indico el origen y cómo solucionar el error `File already exists` que he encontrado al ejecutar `vagrant package`.

<!--more-->

Partimos de una máquina creada con Vagrant mediante el comando `vagrant up`. En esta nueva máquina, nos conectamos mediante `vagrant ssh` y realizamos las modificaciones necesarias para personalizar y adecuar la VM a nuestras necesidades.

En mi caso, la idea es incorporar a la imagen base la instalación de Docker CE, en vez de instalar vía script de _provisioning_ después de crear la máquina (como vimos en la entrada anterior [Instalando Docker-CE usando Vagrant shell provisioning]({{ref "180114-instalando-docker-ce-usando-vagrant-shell-provisioning.md"}})). También he aprovechado para actualizar la imagen base. Para ello, he conectado a la máquina mediante `vagrant ssh` y a continuación:

```shell
$ sudo apt-get update && sudo apt-get upgrade -y
...
$ sudo apt-get autoremove
...
$ sudo apt-get dist-upgrade
```

## Pasos previos

Para preparar la VM para su _re-empaquetado_, Vagrant recomienda rellenar con ceros para mejorar la compresión del disco. En Ubuntu los comandos son:

```shell
vagrant@debian9-docker:~$ sudo dd if=/dev/zero of=/EMPTY bs=1M
dd: error writing '/EMPTY': No space left on device
25700+0 records in
25699+0 records out
26947764224 bytes (27 GB, 25 GiB) copied, 37.9167 s, 711 MB/s
vagrant@debian9-docker:~$ sudo rm -f /EMPTY
```

En este caso, no parece que haya funcionado.

## Limpiar historial de comandos

A continuación, eliminamos los ficheros con el registro de comandos:

```shell
vagrant@debian9-docker:~$ cat /dev/null > ~/.bash_history && history -c && exit
logout
Connection to 192.168.1.245 closed.
```

## Empaquetando la VM

Siguendo la documentación, la opción para preparar una nueva _box_ debería ser tan sencilla como lanzar el comando `vagrant package --output $nombreBox.box`.

Sin embargo, al lanzar el comando:

```shell
> vagrant package --output debian9docker.box
==> default: Verifying Hyper-V is enabled...
==> default: Attempting graceful shutdown of VM...
==> default: off
==> default: Exporting VM...
An error occurred while executing a PowerShell script. This error
is shown below. Please read the error message and see if this is
a configuration error with your system. If it is not, then please
report a bug.

Script: export_vm.ps1
Error:

Export-VM : Failed to copy file during export.
Failed to copy file from 'M:\VMS\vagrant-vms\debian-docker\.vagrant\machines\default\hyperv\Virtual Hard Disks\generic-debian9-hyperv.vhdx' to
'C:\Users\Xavi\.vagrant.d\tmp\vagrant-package-20180120-7844-1j6hx2d\debian9-docker\Virtual Hard Disks\generic-debian9-hyperv.vhdx': The file exists. (0x80070050).
At C:\HashiCorp\Vagrant\embedded\gems\gems\vagrant-2.0.1\plugins\providers\hyperv\scripts\export_vm.ps1:9 char:7
+ $vm | Export-VM -Path $Path
+       ~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [Export-VM], VirtualizationException
    + FullyQualifiedErrorId : OperationFailed,Microsoft.HyperV.PowerShell.Commands.ExportVM
```

### Investigando el error

El script de exportación falla con el mensaje de error de que el disco ya existe (¿?). Al lanzar el comando `vagrant package`, Vagrant crea una carpeta temporal con un nombre aleatorio en la carpeta `C:\Users\$USERNAME\.vagrant.d\tmp\` y se establece como destino de la exportación de la máquina virtual.

El error parece indicar que el script intenta copiar la máquina exportada en la carpeta original de la máquina y que por ello se produce el error. Sin embargo, esta explicación no tiene demasiado sentido, ya que un error _de bulto_ en el funcionamiento de `vagrant package` se habría descubierto -y solucionado- hace mucho. Buscando en internet no encontré nada al respecto, lo que confirmaba mi hipótesis de que la causa debía ser otra.

Como las rutas -tanto de la ubicación inicial de la VM como la de exportación- contienen carpetas cuyo nombre empieza por un punto, pensé que ésta podría ser la causa. Para comprobarlo, copié el disco a la ruta `m:\vms\vagrant-vms\` y modifiqué la configuración de la VM en Hyper-V. Sin embargo, `vagrant package` falló de nuevo con el mismo mensaje de error.

Intenté avanzar realizando manualmente la exportación de la máquina virtual directamente desde Hyper-V, pero de nuevo la exportación falló con el mismo mensaje de error. Esto significa que el error proviene del proceso de exportación de Hyper-V y no del script de Vagrant.

El proceso de exportar una VM desde Hyper-V funcionaba sin problemas para otras máquinas "no Vagrant", lo que reforzaba mi idea del problema con las carpetas con nombres que empezaban por puntos... Pero después de más pruebas y más búsquedas en internet, la ausencia de resultados me indicaba que no podía ser un fallo de Hyper-V o Vagrant, sino algo más específico de las máquinas creadas.

## Solución

Después de revisar el fichero `Vagrantfile`, he caído en la cuenta de que los discos de las máquinas virtuales los configuré _differencing disks_ siguiendo los consejos de [Vagrant and Hyper-V — Tips and Tricks](https://blogs.technet.microsoft.com/virtualization/2017/07/06/vagrant-and-hyper-v-tips-and-tricks/#comment-146355), en particular la Tip 5.

> He dejado un comentario en la entrada advirtiendo del problema de usar _differencing disks_ y `vagrant package`.

He modificado el parámetro a `config.vm.provider.differencing_disk = false` y he repetido los pasos para actualizar la máquina, rellenar de ceros el disco y borrar la historia.

Al lanzar de nuevo el comando `vagrant package`, esta vez la exportación y la creación de la nueva _box_ funciona sin problemas:

```shell
M:\VMS\vagrant-vms\debian-docker> vagrant package --output debian9docker17.12.box
==> default: Verifying Hyper-V is enabled...
==> default: Attempting graceful shutdown of VM...
==> default: off
==> default: Exporting VM...
==> default: Compressing package to: M:/VMS/vagrant-vms/debian-docker/debian9docker17.12.box
M:\VMS\vagrant-vms\debian-docker>
```

## Añadir la box personalizada a nuestro inventario

Ya sólo queda el paso final, que es añadir la nueva _box_ al repositorio local para ser reutilizada:

```shell
M:\VMS\vagrant-vms\debian-docker> vagrant box add debian9docker17.12 debian9docker17.12.box
==> box: Box file was not detected as metadata. Adding it directly...
==> box: Adding box 'debian9docker17.12' (v0) for provider:
    box: Unpacking necessary files from: file://M:/VMS/vagrant-vms/debian-docker/debian9docker17.12.box
    box: Progress: 100% (Rate: 551M/s, Estimated time remaining: --:--:--)
==> box: Successfully added box 'debian9docker17.12' (v0) for 'hyperv'!
M:\VMS\vagrant-vms\debian-docker>
```

Comprobamos que se ha añadido correctamente mediante:

```shell
M:\VMS\vagrant-vms\debian-docker> vagrant box list
debian9docker17.12 (hyperv, 0)
generic/alpine36   (hyperv, 1.3.30)
generic/debian9    (hyperv, 1.3.30)
M:\VMS\vagrant-vms\debian-docker>
```

# Resumen

En esta entrada hemos visto cómo reutilizar una _box_ existente para crear una _box_ personalizada.

Hemos visto el error que se produce al usar discos diferenciales en la máquina virtual y cómo solucionarlo.

Finalmente, hemos añadido la _box_ personalizada a nuestro repositorio local.