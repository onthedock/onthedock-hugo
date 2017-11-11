+++
draft = false

# TAGS
# HW->OS->PRODUCT->specific tag
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux"]

# CATEGORIES = "dev" / "ops"
categories = ["dev", "ops"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/linux.png"

# SHORTCODES (for reference)

# YouTube
# {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Imagenes
# {{% img src="images/image.jpg" w="600" h="400" %}}
# {{% img src="images/image.jpg" w="600" h="400" class="right" %}}
# {{% img src="images/image.jpg" w="600" h="400" class="left" %}}
# {{% img src="images/image.jpg" w="600" h="400" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# Clear (floats)
# {{% clear %}}
# Twitter
# {{% twitter tweetid="780599416621297xxx" %}}

title=  "Trucos para para línea de comandos"
date = "2017-10-02T20:44:00+02:00"
+++

Últimamente paso mucho tiempo en la línea de comando, por lo que aprender algunos _trucos_ en forma de combinaciones de teclas, etc, que me ayuden a ser mucho más ágil.

<!--more-->

# Cursor arriba/abajo

Pulsando la tecla de cursor arriba/abajo, puedes desplazarte por el historial de comandos ejecutados.

Es decir, si ejecutas un comando, por ejemplo `ls -l`, puedes devolverlo a la línea de comando pulsando la tecla de cursor arriba. Pulsando repetidamente la tecla de cursor arriba (&uarr;) retrocedes en el historial de comandos.

En el siguiente GIF muestro el historial de comandos con el comando `history` y después pulso repetidas veces la tecla de cursor arriba &uarr;, con lo que se puede observar cómo se van mostrando los comandos ejecutados en orden cronológico inverso:

{{% img src="images/171002/using_arrow.gif" %}}

Puedes avanzar y retroceder por la historia de los comandos ejecutados usando las teclas de cursores arriba y abajo (&uarr; y &darr;).

# Ejecutar el último comando como root

¿Cuántas veces has lanzado un comando y sólo has obtenido como resultado un `Access Denied` porque has olvidado lanzarlo usando `sudo`?

En vez de pulsar &uarr;, &larr;, &larr;, ..., &larr;, para retroceder al inicio de la línea y después escribir `sudo`, es mucho más rápido y sencillo lanzar `sudo !!`

{{% img src="images/171002/sudo_last_command.gif" %}}

# Limpiar la pantalla

Puedes limpiar la pantalla de la terminal lanzando el comando `clear` (en Linux)... Pero es mucho más rápido conseguir lo mismo mediante la combinación `Ctrl+l`:

{{% img src="images/171002/ctrl+l.gif" %}}

# Limpiando la línea de comandos

Con la combinación anterior limpias la pantalla, pero no lo que hayas escrito en la línea de comandos. Puedes pulsar repetidamente la tecla de borrar... o puedes usar la combinación `Ctrl+u`; mediante esta combinación de teclas borras todo el contenido de la línea de comandos **a la izquierda del cursor**

```shell
$ scp file.txt operador@|rpi.local:/home/operador/
# Pulsando Ctrl+u, borramos todo a la izquierda del cursor
$ |rpi.local:/home/operador/
```

Puedes borrar el contenido de la línea de comandos **a la derecha del cursor** mediante la combinación `Ctrl+k`.

```shell
$ scp file.txt operador@|rpi.local:/home/operador/
# Pulsando Ctrl+k, obtenemos:
$ scp file.txt operador@|
```

# Combinando history y grep

Puedes combinar el comando `history` y la capacidad de filtro del comando `grep` para buscar un comando concreto que hayas ejecutado anterioremente:

{{% img src="images/171002/history-grep.gif" %}}

# Ejecutar un comando anterior

Un truco relacionado con la combinación anterior; una vez que hemos encontrado el comando que queremos volver a lanzar, es lanzar `!` seguido por el número que aparece junto con el comando:

```shell
$ history | grep ssh
   30  cat /etc/systemd/system/sshd.service
  501  history | grep ssh
  502  history | grep "ssh"
  503  cat /etc/systemd/system/sshd.service
  504  history | grep ssh
  505  cat /etc/systemd/system/sshd.service
  506  history | grep ssh
HypriotOS/armv6: pirate@rpi in ~
$ !30
cat /etc/systemd/system/sshd.service
[Unit]
Description=OpenBSD Secure Shell server
After=network.target auditd.service
ConditionPathExists=!/etc/ssh/sshd_not_to_be_run
...
```

{{% img src="images/171002/relaunch-previous-command.gif" %}}

# Búsqueda inversa

El _combo_ `history + grep + ! #_de_comando` está bien, pero es muy largo; puedes conseguir lo mismo usando la combinación de teclas `Ctrl+r`. En cuanto cambia el _prompt_, puedes escribir y el terminal mostrará la primera coincidencia en el historial de comandos:

{{% img src="images/171002/ctrl+r.gif" %}}

Si hay varias coincidencias, puedes mostrarlas pulsando repetidamente `Ctrl+r` de nuevo:

{{% img src="images/171002/ctrl+r-cycle.gif" %}}

# Resumen

Convierte la línea de comandos en un entorno mucho más productivo usando éstos y otros trucos.