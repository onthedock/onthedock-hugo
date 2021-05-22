+++
draft = false

categories = ["dev"]
tags = ["linux", "aws", "cloud-init"]
thumbnail = "images/190101/amazonlinux.png"
title=  "Probando Amazon Linux 2"
date = "2019-01-01T16:43:58+01:00"
+++
{{< figure src="/images/190101/what-are-clouds-made-of.jpg" w="600" h="400" >}}

Como dice el chiste, las nubes están compuestas básicamente de servidores Linux. Una de estas nubes, Amazon Web Services (AWS), ofrece su propia distribución de Linux: [Amazon Linux 2](http://amazonlinux.com).
<!--more-->

Puedes descargar Amazon Linux 2 en forma de máquina virtual para diferentes plataformas desde [OS Images](https://cdn.amazonlinux.com/os-images/latest/), como Hyper-V, KVM, VirtualBox o VMware, así como en forma de contenedor.

Yo he descargado la imagen de disco para Hyper-V, de unos 640MB (comprimida). El zip contiene un disco en formato VHDX que descomprimido ocupa algo más de 26GB. He creado una máquina y le he pinchado el disco.

# Antes de arrancar, configura Cloud-Init

Esta máquina virtual tiene Cloud-Init preinstalado, por lo que necesitas proporcionar información de configuración (para crear un usuario y poder acceder, por ejemplo).

AWS ofrece una imagen `seed.iso` que puedes descargar desde el enlace [OS Images](https://cdn.amazonlinux.com/os-images/latest/), aunque quizás la mejor opción es seguir las instrucciones de [Running Amazon Linux 2 as a Virtual Machine On-Premises](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/amazon-linux-2-virtual-machine.html) para crear una imagen ISO con tus ficheros personalizados. También puedes echarle un vistazo al artículo que escribí al respecto: [Automatizando la personalización de máquinas virtuales con cloud-init]({{<ref "181009-cloud-init.md" >}}).

En mi caso, he creado una imagen con la configuración de red estática y con una contraseña definida para el usuario creado por defecto `ec2-user`. Además, finalizo la configuración de red para poder "despinchar" la imagen ISO más adelante. Los ficheros son:

## Fichero `user-data`

```yml
#cloud-config
# vim:syntax=yaml
users:
# A user by the name ec2-user is created in the image by default.
  - default
# The following entry creates user1 and assigns a plain text password.

chpasswd:
  list: |
    ec2-user:sup3rs3cr3tp@55w0rd:)
# In the above line, do not add any spaces after 'ec2-user:'.

# NOTE: Cloud-init applies network settings on every boot by default. To retain network settings from first
boot, uncomment the following ‘write_files’ section:
#write_files:
  - path: /etc/cloud/cloud.cfg.d/80_disable_network_after_firstboot.cfg
    content: |
      # Disable network configuration after first boot
      network:
        config: disabled
```

## Fichero `meta-data`

```yml
local-hostname: amazonlinux.onprem
# eth0 is the default network interface enabled in the image. You can configure static network settings with an entry like the following.
network-interfaces: |
  auto eth0
  iface eth0 inet static
  address 192.168.1.225
  network 192.168.1.0
  netmask 255.255.255.0
  broadcast 192.168.1.255
  gateway 192.168.1.1
```

# Sin conectividad de red

La VM configura la disposición del teclado en inglés, lo que complica encontrar algunos caracteres, como el `-` necesario para acceder al sistema con el usuario `ec2-user`.

> El `-` se encuentra en la tecla `'` del teclado con la distribución en español.

Tras acceder localmente a la máquina virtual he descubierto que la configuración de red no se ha aplicado (o eso parece). Lanzando `ip add show` se puede comprobar que la tarjeta de red `eth0` sólo tiene configurada IPv6.

He intentado *levantar* el interfaz mediante `sudo systemctl start network` y he obtenido un mensaje de error. Siguiendo las intrucciones mostradas, he consultado `sudo systemctl status network`, donde se muestra, entre otras cosas **vendor preset: disabled**.

Tras buscar en Google, descubro que en RHEL/CentOS, la red viene desactivada por defecto y [hay que activarla explícitamente](https://unix.stackexchange.com/questions/468058/systemctl-status-shows-vendor-preset-disabled).

```bash
sudo systemctl enable network
sudo systemctl start network
```

# Haciendo las cosas bien (actualización)

En la primera prueba con Amazon Linux 2 cometí el error de especificar una IP que estaba siendo usada por una máquina Vagrant. Al tener una IP duplicada, la máquina virtual con Amazon Linux 2 no podía levantar la red.

Una vez descubierto el problema (que documento paso a paso más abajo), he repetido los pasos necesarios para arrancar una máquina virtual con Amazon Linux 2 y no he tenido ningún problema.

Es necesario habilitar la red después del primer arranque, aunque esto es una característica que Amazon Linux 2 hereda de RHEL/CentOS.

Una vez habilitado el servicio de red, se puede *levantar* sin más.

> El problema para levantar la red se deben a que la IP que había especificado en el fichero de configuración `meta-data` estaba duplicada :(

## Diagnosticando el problema de red (spoiler: IP duplicada)

De nuevo, error, aunque esta vez **Failed to start LSB: Bring up/down**. El [primer resultado en Google](https://unix.stackexchange.com/questions/278155/network-service-failed-to-start-lsb-bring-up-down-networking-centos-7) apunta a que la causa puede ser que no existe el fichero `/etc/sysconfig/network`.

> La `/` se encuentra en la tecla `-` del teclado con la distribución en español.

Verifico que el fichero existe y que contiene información autoconfigurada por Cloud-Init:

```bash
$ cat /etc/sysconfig/network
...
NETWORKING=yes
```

La información en el [segundo resultado de la búsqueda en Google](https://unix.stackexchange.com/questions/396096/centos-7-network-service-failed-to-start-because-systemd-starts-the-daemon-too) apunta a editar el fichero `/etc/sysconfig/network-scripts/ifcfg-eno1` (en mi caso, `ifcfg-eth0`).

Revisando el contenido del fichero, todo parece OK... Hasta que me he dado cuenta que parece que había algún problema con la IP que estaba usando (estaba usando una IP asignada por DHCP a una máquina Vagrant). Solucionado el error, he podido levantar la red sin más problemas.

> Para salir de Vi, es necesario usar los "dos puntos", `:` que se encuentran en el tecla `Ñ` (Shift+Ñ) del teclado con la distribución en español.

Para acabar con la configuración de la máquina, he intentado acceder remotamente (usando PuTTY).
He obtenido el mensaje de error indicando que no se permitía el acceso usando la autenticación basada en usuario y contraseña. Amazon Linux 2 viene configurado *de fábrica* sólo con autenticación basada en claves SSH.

La solución pasa por editar el fichero `/etc/ssh/sshd_config` y descomentar la línea con el parámetro **PasswordAuthentication**, que debe estar en `yes`. Un reinicio más tarde del servicio de SSH (`sudo service restart sshd`), ya puedo acceder a la máquina con Amazon Linux 2 en remoto.

# Amazon Linux 2 ¿sí o no?

Amazon Linux 2 es una distribución de Linux que usa el gestor de paquetes YUM, basada en RHEL <sup>[Wikipedia](https://en.wikipedia.org/wiki/Amazon_Machine_Image#Amazon_Linux_AMI)</sup>. Personalmente, casi siempre he trabajado con distribuciones Debian o derivadas, por lo que me siento *más cómodo* con este tipo de distribuciones.

A parte de este detalle puramente personal, Amazon Linux 2 es una distribución Linux que está estrechamente ligada a AWS. Por tanto, el caso más habitual de uso sería el de usarlo como base en máquinas _on premise_ para desarrollo que después se vayan a desplegar sobre AWS. Otra opción sería para aquellos operadores que deban gestionar despliegues sobre AWS para familiarizarse con detalles específicos de esta distribución en entornos híbridos (_cloud público + on premises_ pero dando prioridad a los despliegues en la nube).

Al tratarse de una distribución específica para AWS, hay que valorar las ventajas de disponer de las herramientas de línea de comando de AWS integradas, las actualizaciones y revisiones de seguridad frecuentes que proporciona Amazon y el soporte extendido frente a otras opciones menos específicas como Debian/Ubuntu/CentOS.