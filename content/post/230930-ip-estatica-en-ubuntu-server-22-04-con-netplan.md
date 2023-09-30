+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev", "ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "ubuntu", "netplan"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/linux.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/

# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}
# YouTube           {{< youtube w7Ft2ymGmfc >}}
# Gist              {{< gist username 7896402 >}}
# Highlight         {{< highligth language >}}...{{< /highlight >}}
# Twitter           {{< tweet user="SanDiegoZoo" id="1453110110599868418" >}}

title=  "IP estática en Ubuntu Server 22.04 con Netplan"
date = "2023-09-30T12:13:57+02:00"
+++
Para desplegar un clúster mono-nodo de Kubernetes usando K3s, he clonado una máquina virtual con Ubuntu Server 22.04 LTS que uso como "golden image".

Una de las tareas que realizo sobre la máquina clonada es la de configurar una IP estática, pero siempre tengo que buscar cómo realizar esta configuración en Google, ya que nunca lo recuerdo.

El objetivo de esta entrada es servirme de recordatorio para el futuro.
<!--more-->

El primer paso es localizar los ficheros de configuración de `netplan`; en Ubuntu Server 22.04 se encuentran en `/etc/netplan`.

Netplan fusiona la configuración de todos los ficheros de configuración existentes en (de más a menos prioritario):

- `/run/netplan/*.yaml`
- `/etc/netplan/*.yaml`
- `/lib/netplan/*.yaml`

Los ficheros se aplican en orden alfabético **independientemente** de la carpeta en la que se encuentren (revisa [Hierarchy of configuration files
](https://netplan.io/faq#hierarchy-of-configuration-files) en la documentación oficial).

En mi caso, en la carpeta `/etc/netplan/` se encuentra el fichero `00-installer-config.yaml`, que configura la interfaz de red existente en modo DHCP:

```yaml
# This is the network config written by 'subiquity'
network:
  ethernets:
    enp0s3:
      dhcp4: true
  version: 2
```

En vez eliminar el fichero existente, creamos un nuevo fichero (en la misma carpeta) llamado `01-static-ip-config.yaml` con la siguiente configuración:

```yaml
network:
  ethernets:
    enp0s3:
      dhcp4: no 
      addresses:
        - 192.168.1.101/24
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses: 
          - 1.1.1.1
          - 8.8.8.8
  version: 2
```

## Desactivar la obtención de IP vía DHCP

En primer lugar, modificamos la configuración de la propiedad `dhcp4` y la establecemos como `no`. Si quieres asegurarte que la interfaz tampoco obtiene una IPv6, puedes añadir `dhcp6: no`.

## Especificar la IP estática

A continuación establecemos la IP para la interfaz en formato CIDR: `192.168.1.101/24`.

Como es posible asignar múltiples direcciones IP, el valor de `addresses` es un array. En muchos tutoriales se expresa en formato JSON, es decir, como:

```yaml
addresses: [ 192.168.1.101/24 ]
```

Personalmente, prefiero usar el formato YAML, aunque sea algo más *verbose*.

## Especificar la puerta de enlace por defecto

En la mayoría de tutoriales que he consultado, se usa la propiedad `gateway4` para establecer la puerta de enlace por defecto.
Sin embargo, al aplicar la configuración se indica que **gateway4 está desaconsejado** (*deprecated*).

Dado que el objetivo de la entrada es servirme de guía para el futuro, prefiero usar la forma aconsejada `routes`:

```yaml
routes:
- to: default
  via: 192.168.1.1
```

## Servidores de DNS

Como en el caso de las direcciones IP asignadas al interfaz, para la propiedad `nameservers`, podemos especificar un *array* de direcciones IP de servidores de nombres.
De nuevo, uso la forma "nativa" de YAML para especificar dos servidores de DNS:

```yaml
nameservers:
  addresses: 
    - 1.1.1.1
    - 8.8.8.8
```

## Aplicando la configuración

Para aplicar la configuración, ejecuta:

```console
sudo netplan apply
```

Se puede validar la configuración existente (antes de aplicarla) ejecutando `sudo netplan generate`. Sin embargo, `generate` modifica los ficheros, por lo que es necesario realizar un backup si planeas realizar un *rollback* si surge algún problema con tu configuración actual...

En mi caso, se trata de una máquina virtual local; puedo acceder a ella por consola independientemente de si hay un problema con la configuración de red. Si estás modificando una máquina remota, quizás debas probar con `netplan try`, que incluye la posibilidad de realizar un *rollback* automática si algo no funciona como estaba previsto.
