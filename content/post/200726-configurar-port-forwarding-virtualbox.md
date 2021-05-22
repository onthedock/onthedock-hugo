+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["virtualbox"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/virtualbox.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}

title=  "Configurar port-forwarding en Virtualbox"
date = "2020-07-26T17:35:23+02:00"
+++
Para poder conectar a una máquina virtual conectada a la red mediante NAT (o NAT Service) es necesario habilitar *port-forwarding*.

En esta entrada indico cómo habilitar *port-forwarding*.

<!--more-->
## Configurar *port-forwarding* desde línea de comando

Usaremos el comando `vboxmanage natnetwork modify`, especificando el nombre de la red en que configuraremos el *port-forwarding* (para IP v4).

La regla permite especificar un nombre (`ssh`) y el protocolo (`tcp`). A continuación dejamos la IP local en blanco y especificamos el puerto que vamos a redirigir a la máquina virtual.

Para la máquina virtual debemos especificar la IP y el puerto (no pueden dejarse en blanco). Al final, el comando para configurar el *port-forwarding* quedaría:

```bash
VBoxManage natnetwork modify --netname ${networkName} --port-forward-4 \
  "ssh:tcp:[]:1022:[10.0.2.5]:22"
```

Una vez establecido el *port-forwarding*, podemos conectar con la máquina virtual mediante `ssh operador@localhost -p 1022`, por ejemplo.

## Configurar *port-forwarding* desde el entorno gráfico

VirtualBox permite añadir y editar las reglas también de forma gráfica.

En la pantalla de bienvenida de VirtualBox, selecciona *Preferences*.

Pulsa sobre el icono de *Network*, selecciona la *NAT network* para la que quieres configurar el *port-forwarding* y en el borde derecho de la ventana, selecciona el botón correspondiente para añadir, eliminar o editar una nueva red de NAT.

En la ventana del cuadro de diálogo para configurar la *NAT network*, pulsa el botón *Port forwarding*.

Se muestra una nueva ventana con las reglas definidas para IPv4.
