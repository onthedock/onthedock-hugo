+++
draft = false
categories = ["ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "alpine", "proxmox"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/alpine.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}

title=  "Cómo habilitar qemu-guest-agent en Alpine Linux"
date = "2019-04-29T19:50:54+02:00"
+++
`qemu-guest-agent` es un agente que puede instalarse en los sistemas invitados en Proxmox VE que permite obtener información sobre los sistemas corriendo en máquinas virtuales.
Uno de esos datos es la IP del sistema.

Sin embargo, para los sistemas Alpine Linux, el servicio no arranca automáticamente.
Se puede habilitar de forma manual, pero lo ideal es que el _demonio_ arranque automáticamente durante el arranque.
<!--more-->

Se puede configurar `qemu-guest-agent` para que arranque durante el inicio del sistema mediante [rc-update](https://old.calculate-linux.org/main/en/rc-update):

```bash
rc-update add qemu-guest-agent default
```

Sin embargo, tras reiniciar el equipo, el servicio _crashea_; consultando los logs observamos:

```bash
# cat /var/log/messages | grep -i qemu-guest-agent
Apr 28 22:24:05 dns daemon.err /etc/init.d/qemu-guest-agent[2440]: status: crashed
Apr 28 22:24:10 dns daemon.err /etc/init.d/qemu-guest-agent[2460]: start-stop-daemon: no matching processes found
```

## Bug de qemu-guest-agent en Alpine Linux

Buscando información en Google sobre el problema de `qemu-guest-agent` en Alpine Linux, he encontrado el [Bug #8894 Qemu-Guest-Agent not working](https://bugs.alpinelinux.org/issues/8894).

El problema parece estar en la configuración del script de arranque del servicio es incorrecta; se apunta la solución en los comentarios del bug: modificar el script especificando el dispositivo real (`/dev/vport2p1`) y no el "configurado" en el script del servicio (`-p ${GA_PATH:-/dev/virtio-ports/org.qemu.guest_agent.0}`).

El script que permite arrancar el servicio automáticamente queda:

```bash
# cat /etc/init.d/qemu-guest-agent
#!/sbin/openrc-run

name="QEMU Guest Agent"
pidfile="/run/qemu-ga.pid"
command="/usr/bin/qemu-ga"
command_args="-m ${GA_METHOD:-virtio-serial} -p qemu-ga -p /dev/vport2p1 -l /var/log/qemu-ga.log -d"
```

Tras corregirlo, configuramos `qemu-guest-agent` para que arranque durante el inicio del sistema:

```bash
rc-update add qemu-guest-agent default
```

Para validar que todo funciona como esperamos, reiniciamos el equipo y comprobamos el estado del servicio:

```bash
# service qemu-guest-agent status
 * status: started
```