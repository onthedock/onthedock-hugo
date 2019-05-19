+++
draft = false

categories = ["ops"]
tags = ["linux", "alpine", "dnsmasq"]
thumbnail = "images/alpine.png"

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}

title=  "Iniciar dnsmasq durante el inicio del sistema"
date = "2019-05-19T08:42:05+02:00"
+++
dnsmasq es un servidor DNS y por tanto debería estar siempre arrancado, para responder  a las peticiones de resolución de nombres precedentes del resto de máquinas.

La instalación en Alpine Linux no configura el servicio de dnsmasq para iniciar durante el arranque del sistema, por lo que debe iniciarse manualmente.

Esta no es la configuración que queremos, así que vamos a corregirla.

<!--more-->

# Comprobar si un servicio está arrancado en Alpine Linux

El primer paso es averiguar si un servicio está levantado o no; en Alpine Linux lo conseguimos mediante el comando `service`:

```bash
# service dnsmasq status
```

## Comprobar si el servicio _autoarranca_

Podemos averiguar qué servicios arrancan durante el inicio del sistema mediante el comando `rc-status --all`; el comando muestra los servicios que arrancan en cada uno de los _runlevels_ (ver [Alpine Linux Init System: rc-status usage](https://wiki.alpinelinux.org/wiki/Alpine_Linux_Init_System#rc-status_usage)).

```bash
dns:~# rc-status -a
Runlevel: shutdown
 savecache                   [  stopped  ]
 killprocs                   [  stopped  ]
 mount-ro                    [  stopped  ]
Runlevel: nonetwork
Runlevel: default
 qemu-guest-agent            [  started  ]
 sshd                        [  started  ]
 acpid                       [  started  ]
 crond                       [  started  ]
Runlevel: boot
 modules                     [  started  ]
 hwclock                     [  started  ]
 swap                        [  started  ]
 urandom                     [  started  ]
 hostname                    [  started  ]
 sysctl                      [  started  ]
 bootmisc                    [  started  ]
 syslog                      [  started  ]
 networking                  [  started  ]
 loadkmap                    [  started  ]
Runlevel: sysinit
 devfs                       [  started  ]
 dmesg                       [  started  ]
 mdev                        [  started  ]
 hwdrivers                   [  started  ]
Dynamic Runlevel: hotplugged
Dynamic Runlevel: needed/wanted
 sysfs                       [  started  ]
 fsck                        [  started  ]
 root                        [  started  ]
 localmount                  [  started  ]
Dynamic Runlevel: manual
```

Como vemos, dnsmasq no aparece listado en ningún _runlevel_.

# Incluir un servicio en el proceso de arranque

Para incluir un servicio para lograr que se inicie durante el proceso de arranque, usamos el comando `rc-update add`.

```bash
dns:~# rc-update add dnsmasq
 * service dnsmasq added to runlevel default
```

Como no indicamos el _runlevel_ en el que queremos agregar el servicio, se añade a la lista de servicios que arrancan en el _runlevel_ por defecto.

Si ahora comprobamos los servicios de nuevo:

```bash
dns:~$ rc-status
Runlevel: default
 dnsmasq                    [  started  ]
 qemu-guest-agent           [  started  ]
 sshd                       [  started  ]
 acpid                      [  started  ]
 crond                      [  started  ]
Dynamic Runlevel: hotplugged
Dynamic Runlevel: needed/wanted
 sysfs                      [  started  ]
 fsck                       [  started  ]
 root                       [  started  ]
 localmount                 [  started  ]
Dynamic Runlevel: manual
```

Ahora sólo quedaría reiniciar la máquina del DNS para validar que el servicio arrancará automáticamente durante el arranque.

## La historia detraś de esta entrada

Después de instalar dnsmasq no me di cuenta de que no se había añadido a la lista de servicios que arrancan con el sistema. 

Como sólo uso las máquinas de laboratorio para realizar pruebas, no había notado que tenían problemas para resolver direcciones hasta que he intentado actualizar el propio servidor de laboratorio.

Al lanzar un `sudo apt update` desde la máquina he visto que no podía contactar con los repositorios de paquetes y a partir de aquí he ido "tirando del hilo" hasta descubrir que dnsmasq estaba parado.

Afortunadamente, en vez de empezar a buscar las causas de porqué se estaba parando el servicio, he empezado por las opciones básicas: mirar en primer lugar si está configurado para autoarrancar.

En su momento, al instalar dnsmasq debería haberlo comprobado pero, bueno, estas cosas pasan... ¯\\\_(ツ)\_/¯