+++
draft = false
categories = ["dev"]
tags = ["linux", "debian", "powershell"]
thumbnail = "images/linux.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}

title=  "Instalación de Powershell en Debian 9"
date = "2018-02-07T19:58:18+01:00"
+++

Las instrucciones para instalar Powershell en Linux [Package Installation Instructions](https://github.com/PowerShell/PowerShell/blob/master/docs/installation/linux.md) hacen referencia a Ubuntu. Cuando se intenta instalar Powershell en Debian 9, se obtiene un error relativo a paquetes que no se encuentran.

<!--more-->

En concreto, el error es el siguiente:

```shell
$ sudo apt-get install powershell
Reading package lists... Done
Building dependency tree
Reading state information... Done
Some packages could not be installed. This may mean that you have
requested an impossible situation or if you are using the unstable
distribution that some required packages have not yet been created
or been moved out of Incoming.
The following information may help to resolve the situation:

The following packages have unmet dependencies:
 powershell : Depends: libssl1.0.0 but it is not installable
              Depends: libicu55 but it is not installable
E: Unable to correct problems, you have held broken packages.
```

La solución pasa por modificar el fichero `/etc/apt/sources.list.d/microsoft.list` y cambiarlo por `deb [arch=amd64] https://packages.microsoft.com/debian/stretch/prod stretch main` tal y como se indica en [PowerShell fails to install on Debian-9](https://github.com/PowerShell/PowerShell/issues/4320).

Tras modificar el fichero `/etc/apt/sources.list.d/microsoft.list`:

```shell
~$ sudo apt-get install powershell
Reading package lists... Done
Building dependency tree
Reading state information... Done
The following additional packages will be installed:
  liblttng-ust-ctl2 liblttng-ust0 libunwind8 liburcu4
The following NEW packages will be installed:
  liblttng-ust-ctl2 liblttng-ust0 libunwind8 liburcu4 powershell
0 upgraded, 5 newly installed, 0 to remove and 0 not upgraded.
Need to get 52.5 MB of archives.
After this operation, 142 MB of additional disk space will be used.
Do you want to continue? [Y/n] y
Get:1 http://ftp.us.debian.org/debian stretch/main amd64 libunwind8 amd64 1.1-4.1 [48.7 kB]
Get:2 https://packages.microsoft.com/debian/stretch/prod stretch/main amd64 powershell amd64 6.0.1-1.debian.9 [52.1 MB]
Get:3 http://ftp.us.debian.org/debian stretch/main amd64 liburcu4 amd64 0.9.3-1 [61.9 kB]
Get:4 http://ftp.us.debian.org/debian stretch/main amd64 liblttng-ust-ctl2 amd64 2.9.0-2 [99.5 kB]
Get:5 http://ftp.us.debian.org/debian stretch/main amd64 liblttng-ust0 amd64 2.9.0-2 [174 kB]
Fetched 52.5 MB in 2s (23.5 MB/s)
Selecting previously unselected package libunwind8.
(Reading database ... 43191 files and directories currently installed.)
Preparing to unpack .../libunwind8_1.1-4.1_amd64.deb ...
Unpacking libunwind8 (1.1-4.1) ...
Selecting previously unselected package liburcu4:amd64.
Preparing to unpack .../liburcu4_0.9.3-1_amd64.deb ...
Unpacking liburcu4:amd64 (0.9.3-1) ...
Selecting previously unselected package liblttng-ust-ctl2:amd64.
Preparing to unpack .../liblttng-ust-ctl2_2.9.0-2_amd64.deb ...
Unpacking liblttng-ust-ctl2:amd64 (2.9.0-2) ...
Selecting previously unselected package liblttng-ust0:amd64.
Preparing to unpack .../liblttng-ust0_2.9.0-2_amd64.deb ...
Unpacking liblttng-ust0:amd64 (2.9.0-2) ...
Selecting previously unselected package powershell.
Preparing to unpack .../powershell_6.0.1-1.debian.9_amd64.deb ...
Unpacking powershell (6.0.1-1.debian.9) ...
Setting up liburcu4:amd64 (0.9.3-1) ...
Setting up liblttng-ust-ctl2:amd64 (2.9.0-2) ...
Setting up libunwind8 (1.1-4.1) ...
Processing triggers for libc-bin (2.24-11+deb9u1) ...
Processing triggers for man-db (2.7.6.1-2) ...
Setting up liblttng-ust0:amd64 (2.9.0-2) ...
Setting up powershell (6.0.1-1.debian.9) ...
Processing triggers for libc-bin (2.24-11+deb9u1) ...
$
```

Una vez solucionado el problema de la instalación, podemos lanzar Powershell mediante:

```shell
$ pwsh
PowerShell v6.0.1
Copyright (c) Microsoft Corporation. All rights reserved.

https://aka.ms/pscore6-docs
Type 'help' to get help.

PS /home/vagrant>
```
