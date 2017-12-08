+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev", "ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["virtual machine", "linux", "dns"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/linux.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})


title=  "Ignorar el DNS asignado por el servidor DHCP"
date = "2017-12-08T08:39:09+01:00"
+++

Después de instalar y configurar `dnsmasq`, quiero hacer que éste sea el DNS usado por defecto. Como el servidor DHCP proporciona, además de la IP los servidores DNS, las máquinas virtuales en el equipo de laboratorio no son capaces de resolver los nombres del resto de máquinas del definidos en `dnsmasq`.

<!--more-->

La manera más sencilla con la que hacer que un equipo ignore los servidores DNS proporcionados por el servidor DHCP es añadir una línea en el fichero `/etc/dhc/pdhclient.conf`:

```conf
supersede domain-name-servers 192.168.1.10;
```

Si quieres añadir más de un servidor DNS, separa los diferentes valores por comas:

```conf
supersede domain-name-servers 8.8.8.8, 8.8.4.4;
```

La opción _supersede_ permite especificar otras opciones del fichero de configuración; _copypasteando_ de la documentación:

```txt
The supersede statement

       supersede [ option declaration ];

       If for some option the client should always  use  a  locally-configured
       value  or  values rather than whatever is supplied by the server, these
       values can be defined in the supersede statement.
```

He encontrado la solución en el StackExchange para Unix y Linux: [Ignore DNS from DHCP server in Ubuntu](https://unix.stackexchange.com/questions/136117/ignore-dns-from-dhcp-server-in-ubuntu)