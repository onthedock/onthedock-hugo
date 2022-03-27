+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "cockpit"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/cockpit.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/

# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}
# YouTube           {{< youtube w7Ft2ymGmfc >}}
# Gist              {{< gist username 7896402 >}}
# Highlight         {{< highligth language >}}...{{< /highlight >}}
# Twitter           {{< tweet user="SanDiegoZoo" id="1453110110599868418" >}}

title=  "Cockpit: Cannot refresh cache whilst offline"
date = "2022-03-27T20:32:32+02:00"
+++
Hoy he instalado [Cockpit](https://cockpit-project.org/) y después de configurar una IP estática para el servidor que uso de *laboratorio*, la sección *Software Updates* ha dejado de funcionar, mostrando el mensaje de error `Cannot refresh cache whilst offline`.

La solución la he encontrado en [Cockpit – “cannot refresh cache whilst offline”](https://caissyroger.com/2020/10/05/cockpit-cannot-refresh-cache-whilst-offline/).
<!--more-->

> El servidor tiene instalado Ubuntu Server 20.0.4 TLS.

Conectado a la consola de **Cockpit**, abriendo un *terminal* mediante la entrada del panel lateral *Terminal*, edita el fichero de configuración de Netplan (en mi caso, para la wifi):

```bash
sudo vi /etc/netplan/00-installer-config-wifi.yaml
```

En el fichero, incluye la línea `renderer: NetworkManager` (por ejemplo, bajo la línea `version` para tener una guía del nivel de indentación necesario):

```yaml
# This is the network config written by 'subiquity'
network:
  version: 2
  renderer: NetworkManager
  wifis:
# ... 
```

Guarda los cambios y aplícalos mediante:

```bash
sudo netplan apply
```

Volviendo a la sección *Software Updates* del panel lateral, el sistema comprueba si hay actualizaciones pendientes con éxito:

```bash
System is up to date
```
