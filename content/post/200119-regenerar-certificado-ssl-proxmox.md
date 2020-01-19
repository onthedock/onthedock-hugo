+++
title = "Regenerar certificado SSL en Proxmox"
date = "2020-01-19T11:01:05+01:00"
draft = false

categories = ["ops"]
tags = ["linux", "proxmox", "ssl"]
thumbnail = "images/linux.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
+++
Hace relativamente poco que he cambiado de piso, lo que ha afectado a la *toopología* de la red de casa, en particular, ha sido necesario cambiar la IP del equipo de laboratorio donde tengo instalado [Proxmox VE](https://www.proxmox.com/en/).

Como el acceso a la consola web de Proxmox VE se realiza a través de https, los navegadores rechazaban la conexión al tratarse de un certificado inválido (emitido para una IP que no coincide con la actual) (además de la habitual alerta indicando que la entidad certificadora que firma el certificado no se reconoce).

En esta entrada indico cómo regenerar el certificado SSL autofirmado por Proxmox VE.
<!--more-->

Después de aceptar todas los cuadros de diálogo de alertas de seguridad del navegador he conseguido acceder a la consola de administración de Proxmox VE ([https://lab:8006](https://lab:8006)).

En el panel lateral selecciono el nodo `lab`. A continuación, dentro de la sección *System*, selecciono *Certificates*:

{{% img src="images/200119/certificates-ip.png" w="1283" h="341" %}}

El certificado `pve-ssl.pem` contiene la IP del nodo, lo que provocaba las alertas en los navegadores (en la imagen ya aparece la IP actual).

Para lanzar el comando que regenera el certificado, pulsa el botón *Shell* en la parte superior.

En la ventana que aparece, ejecuta el comando:

```bash
pvecm updatecerts -f
```

Tras reiniciar el equipo, el servidor ya se identifica usando el nuevo certificado.

{{% img src="images/200119/update-cert.png" w="744" h="428" %}}

En función del comportamiento de tu navegador, puede que siga usando el certificado anterior durante un determinado tiempo. Puedes buscar online cómo eliminar los certificados *cacheados* para agilizar el proceso.

En mi caso también ha sido necesario actualizar el fichero `hosts` local de Proxmox VE (*System* > *Hosts*) y actualizar la IP.
