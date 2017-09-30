+++
draft = false

tags = ["docker"]

categories = ["dev", "ops"]

thumbnail = "images/docker.png"

title=  "Cómo arrancar contenedores durante el inicio del sistema"
date = "2017-09-20T22:09:46+02:00"
+++

Una de las desventajas de Docker respecto a Kubernetes, es que en caso de fallo del nodo donde corren los contenedores, éstos no arrancan automáticamente cuando el nodo se recupera. El caso más sencillo es cuando hay que apagar/reiniciar el nodo por algún motivo.

En mi caso, el _motivo de fallo_ del nodo ha sido que lo he apagado durante las vacaciones ;)

De todas formas, he decidido configurar los contenedores de forma que se inicien automáticamente con el arranque del sistema. En este artículo te explico cómo.

<!--more-->

Como en Hypriot OS (un derivado de Debian) se usa **systemd** para gestionar el arranque, parada, etc de procesos del sistema operativo. Para conseguir que el contenedor arranque al iniciar el sistema crearemos un `unit file`, el fichero que define las propiedades del proceso que quieres ejecutar. En este caso, el "proceso" será el comando Docker que lanza un contenedor.

systemd se organiza alrededor de dos conceptos: el `unit file` y el `target`. El `unit file` es el fichero de configuración que describe las propiedades del proceso, mientras que el `target` es el mecanismo para agrupar procesos y arrancarlos a la misma vez (durante los _init levels_ del arranque del sistema).

## Creando el `unit file`

Los ficheros `unit file` se encuentran en `/etc/systemd/system`.

Creamos un fichero `home-dns.service` para el  [servicio de DNS creado en la entrada anterior]({{< ref "170827-dnsmasq-en-docker.md" >}}) usando **dnsmasq**.

```shell
[Unit]
Description=Home DNS (dnsmasq)
After=docker.service
Requieres=docker.service

[Service]
TimeoutStartSec=0
ExecStartPre=/usr/bin/docker stop home-dns
ExecStartPre=/usr/bin/docker rm home-dns
ExecStart=/usr/bin/docker run --name home-dns -p 53:53 -p 53:53/udp --cap-add=NET_ADMIN -v /home/pirate/rpi-alpine-dnsmasq/dnsmasq.conf:/etc/dnsmasq.conf -v /home/pirate/rpi-alpine-dnsmasq/hosts:/etc/hosts xaviaznar/rpi-dnsmasq

[Install]
WantedBy=multi-user.target
```

El fichero está dividido en tres secciones:

- `Unit` Indica en qué orden debe lanzarse el proceso, en este caso, después del arranque del servicio `docker.service`. Para que el proceso funcione también especificamos que se requiere `docker.service`. En cuanto a `Description`, el valor indicado aparece en los _logs_ de sistema, etc.

- `Service` En esta sección del fichero se describe el proceso:
  - `ExecStartPre` son tareas que se realizan **antes** de la ejecución del proceso. Del mismo modo tenemos `ExceStartPost`, para ejecutar tareas **después** de arrancar el proceso. Si usamos `=-` en vez de `=`, systemd ignorará los errores que devuelva la tarea especificada.
  - `ExecStart`es donde especificamos el comando a ejecutar. En nuestro caso, un comando `docker run`.

  > No hay que usar la opción `-d` en `docker run` para evitar que el proceso pase a segundo plano, lo que haría que el contenedor no fuera un descendiente de proceso `systemd`; esto se interpretaría como que ha fallado y el _daemon_ se detendría.

- `Install` En esta sección del fichero se indica en qué grupo se iniciará el proceso especificado en la sección anterior.

Para crerar el nuevo _servicio_, habilitamos la nueva _unit_ y lo arrancamos:

```shell
sudo systemctl enable home-dns.service
sudo systemctl start home-dns
```

Puedes verificar que el contenedor ha arrancado mediante `docker ps`, por ejemplo.

Podemos ampliar el fichero `unit` incluyendo también comandos para la acción `stop`:

```shell
[Unit]
Description=Home DNS (dnsmasq)
After=docker.service
Requieres=docker.service

[Service]
TimeoutStartSec=0
ExecStartPre=-/usr/bin/docker stop home-dns
ExecStartPre=-/usr/bin/docker rm home-dns
ExecStart=/usr/bin/docker run --name home-dns -p 53:53 -p 53:53/udp --cap-add=NET_ADMIN -v /home/pirate/rpi-alpine-dnsmasq/dnsmasq.conf:/etc/dnsmasq.conf -v /home/pirate/rpi-alpine-dnsmasq/hosts:/etc/hosts xaviaznar/rpi-dnsmasq
ExecStop=/usr/bin/docker stop home-dns
ExecStopPost=/usr/bin/docker rm home-dns

[Install]
WantedBy=multi-user.target
```

Ahora, al arrancar el equipo, el servicio de DNS arrancará como un servicio más del sistema operativo.

Puedes leer más sobre los `unit files` en:

- [Getting started with systemd](https://coreos.com/os/docs/latest/getting-started-with-systemd.html#unit-file)
- [man page para systemd](https://www.freedesktop.org/software/systemd/man/systemd.service.html)
- [How To Use Systemctl to Manage Systemd Services and Units](https://www.digitalocean.com/community/tutorials/how-to-use-systemctl-to-manage-systemd-services-and-units)