+++
draft = false

tags = ["raspberry pi", "hypriot os", "Docker", "netmasq"]
categories = ["dev"]
thumbnail = "images/linux.png"

# SHORTCODES (for reference)

# YouTube
# {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Imagenes
# {{< figure src="/images/image.jpg" w="600" h="400" >}}
# {{< figure src="/images/image.jpg" w="600" h="400" class="right" >}}
# {{< figure src="/images/image.jpg" w="600" h="400" class="left" >}}
# {{< figure src="/images/image.jpg" w="600" h="400" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# Clear (floats)
# {{% clear %}}
# Twitter
# {{% twitter tweetid="780599416621297xxx" >}}

title=  "dnsmasq en Docker"
date = "2017-08-27T20:48:02+02:00"
+++

[**dnsmasq**](http://www.thekelleys.org.uk/dnsmasq/doc.html) es un [servidor de nombres de dominio (DNS)](https://es.wikipedia.org/wiki/Servidor_de_nombres) ligero y sencillo.

En esta entrada indico cómo ejecutar **dnsmasq** en un contenedor usando Docker.

<!--more-->

A medida que aumenta el número de máquinas en una red local surge la necesidad de disponer de algún sistema que permita identificar cada máquina de forma sencilla. Aunque para poder conectar a una máquina remota necesitamos conocer su dirección IP. En general, los humanos tenemos dificultad para recordad cadenas de números mientras que se nos dan mucho mejor los nombres. Un sistema DNS es una especie de _agenda telefónica_, en la que podemos asociar el nombre de cada máquina con su dirección IP.

En Linux, Windows y Mac el sistema tiene un fichero `hosts` que usa en primera instancia al intentar determinar la dirección IP de un equipo. Para un entorno con pocas máquinas puede ser viable actualizar el fichero `hosts` **de cada máquina en la red** cada vez que añadimos o eliminamos una máquina.

La solución pasa por crear un servidor DNS en nuestra red.

**dnsmasq** cumple con esta función; aunque más sencillo que [**bind9**](https://es.wikipedia.org/wiki/BIND). Si estás interesado en cómo configurar Bind9 quizás te interese revisar el apartado [Servidor DNS bind9](http://www.ite.educacion.es/formacion/materiales/85/cd/linux/m2/servidor_dns_bind9.html) que ofrece el Instituto de Tecnologías Educativas y de Formación del Profesorado del Ministerio de Educación, Cultura y Deporte de España, por ejemplo.

## **dnsmasq** en un contenedor

Mi objetivo es usar **dnsmasq** como un complemento al resto de pruebas que estoy realizando, por lo que voy a instalarlo como contenedor en una de las Raspberry Pi.

Creo el fichero `Dockerfile`:

```Dockerfile
FROM xaviaznar/rpi-alpine-base

RUN apk --no-cache add dnsmasq
EXPOSE 53 53/udp
ENTRYPOINT ["dnsmasq", "-k"]
```

> En Dockerhub he encontrado la imagen de Andy Shinn para dnsmasq: [andyshinn/dnsmasq](https://hub.docker.com/r/andyshinn/dnsmasq/), que he usado como referencia.

El fichero `Dockerfile` parte de mi [imagen con Alpine Linux para Raspbery Pi](https://hub.docker.com/r/xaviaznar/rpi-alpine-base/). A continuación instalo **dnsmasq** y expongo los puertos, lanzando `dnsmasq` con la [opción `-k`](http://www.thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html), que hace que se ejecute "en primer plano" y no como "servicio/demonio".

Creamos la imagen:

```shell
docker build xaviaznar/rpi-dnsmasq .
```

## Configuración

**dnsmasq** se configura a través del fichero `/etc/dnsmasq.conf`. Como _almacén_ para los nombres e IPs asociadas usa el fichero `/etc/hosts` de la máquina en la que está instalada.

### `dnsmasq.conf`

El fichero `dnsmasq.conf` es **muy** extenso, pero en mi caso únicamente modificaré unas pocas opciones (el resto las he dejado por defecto). Puedes encontrar el fichero completo en el repositorio [onthedock/rpi-dnsmasq](https://github.com/onthedock/rpi-dnsmasq) de GitHub:

```txt
# Configuration file for dnsmasq.
...

# Never forward plain names (without a dot or domain part)
domain-needed
# Never forward addresses in the non-routed address spaces.
bogus-priv

...

# Add local-only domains here, queries in these domains are answered
# from /etc/hosts or DHCP only.
local=/ameisin.local/

# Add domains which you want to force to an IP address here.
# The example below send any host in double-click.net to a local
# web-server.
#address=/double-click.net/127.0.0.1
...
```

La opción `#address=/double-click.net/127.0.0.1` permite deshacerse de anuncios y otras plagas de internet. Aunque si estás interesado en usar la Raspberry Pi para filtrar el contenido quizás te interese echar un vistazo a [PI-HOLE&reg;: A BLACK HOLE FOR INTERNET ADVERTISEMENTS](https://pi-hole.net).

> Si el contenedor no arranca debido a que no encuentra la ruta `/etc/dnsmasq.d/` comenta la siguiente línea en el fichero `dnsmasq.conf`:
  ```txt
   # Include all files in a directory which end in .conf
   #conf-dir=/etc/dnsmasq.d/,*.conf
  ```

## Fichero `hosts`

**dnsmasq** usa el fichero `hosts` para obtener la dirección IP asociada a un nombre acerca del que recibe la petición.

Debes adaptar el contenido del fichero `hosts` a los equipos en tu red local.

## Lanzar el contedor

Hay varias cosas a tener en cuenta al lanzar el contenedor para **dnsmasq**. En primer lugar, debe lanzarse con el [privilegio sobre la gestión de la red](https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities) mediante la opción:

```shell
--cap-add=NET_ADMIN
```

Otro punto a tener en cuenta es que estamos montando ficheros en el contenedor. A diferencia de cuando montamos carpetas, en las que los cambios realizados sobre los ficheros contenidos en esas carpetas se actualizan automáticamente en el contenedor, cuando montamos ficheros no sucede así.

Al montar el fichero en el contenedor, se copia del _host_ al contenedor, pero los cambios realizados mientras el contenedor está en ejecución no se reflejan en el fichero montado en el contenedor. Por tanto, para que los cambios realizados sobre el fichero `hosts` tengan efecto, es necesario reiniciar el contenedor (parándolo y arrancándolo de nuevo).

Para simplificar esta tarea, he creado el script `run-home-dns.sh`:

```shell
docker stop home-dns
docker rm home-dns
docker run -d --name home-dns \
   -p 53:53 -p 53:53/udp \
   --cap-add=NET_ADMIN \
   -v /home/pirate/home-dns/dnsmasq.conf:/etc/dnsmasq.conf \
   -v /home/pirate/home-dns/hosts:/etc/hosts \
   xaviaznar/rpi-dnsmasq
```

## Repositorio con los ficheros de configuración y el `Dockerfile`

El fichero `Dockerfile` y los ficheros de configuración están disponibles en el repositorio [onthedock/rpi-dnsmasq](https://github.com/onthedock/rpi-dnsmasq) en GitHub.

## Configuración de los clientes

La configuración de los clientes depende del sistema operativo.

En el caso de las máquinas con sistema operativo Linux, la resolución de nombres se gestiona desde el fichero `/etc/resolv.conf`.

Edita el fichero especificando la dirección del _host_ donde se encuentra el contenedor `rpi-dnsmasq`. En mi caso:

```shell
nameserver 192.168.1.9
```

### El fichero `resolv.conf` se sobrescribe en cada reinicio

Si el fichero de configuración se sobrescribe al reiniciar la máquina (o el servicio de red), edita el fichero `/usr/share/udhcpc/default.script` y modifica la línea:

    RESOLV_CONF="/etc/resolv.conf"

y sustituirla por

    RESOLF_CONF="NO"

[Referencia: How to avoid overwriting of /etc/resolv.conf with dhcp ???](https://forum.alpinelinux.org/forum/networking/how-avoid-overwriting-etcresolvconf-dhcp)