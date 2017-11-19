+++
draft = false
tags = ["raspberry pi", "docker", "gogs"]
categories = ["dev", "ops"]
thumbnail = "images/gogs.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Imagenes
# {{% img src="images/image.jpg" w="600" h="400" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}


title=  "Gogs No Arranca en la Raspberry Pi después de la configuración inicial"
date = "2017-11-18T22:34:59+01:00"
+++

En la entrada [Gogs - Cómo crear tu propio servicio de hospedaje de repositorios Git]({{<ref "171106-gogs-como-crear-tu-propio-servicio-de-hospedaje-de-repos-git.md">}}) describía cómo montar un servicio como GitHub usando Gogs.

Hoy he intentado montar lo mismo sobre la Raspberry Pi aprovechando que Gogs ofrece una imagen específica: [gogs/gogs-rpi](https://hub.docker.com/r/gogs/gogs-rpi/),
<!--more-->

Después de arrancar el contenedor y realizar la configuración inicial de Gogs, he querido deshabilitar la funcionalidad de auto-registro.

La configuración de Gogs no puede realizarse (Gogs 0.11.29) desde la interfaz gráfica. Para realizar cualquier modificación en la configuración es necesario modificar el fichero `conf/app.ini`.

Para que los cambios sean efectivos, es necesario reiniciar Gogs, lo que em mi caso significa parar y arrancar de nuevo el contenedor.

Pero al arrancar de nuevo, la interfaz web no se muestra:

{{% img src="images/171118/not-found.png" height="708" width="623" %}}

He comprobado que el contenedor estaba arrancado y he consultado los logs, que no muestran nada anormal:

```logs
...
[Macaron] 2017-11-18 16:29:18: Started POST /install for 192.168.1.206
2017/11/18 16:29:18 [TRACE] Session ID: 36be09fb40f384ee
2017/11/18 16:29:18 [TRACE] CSRF Token: KLiCQ33Lhr8dUcRDPBVaaCDJBRM6MTUxMTAyMjIxOTUwMzkxNDYyMA==
2017/11/18 16:29:20 [TRACE] Custom path: /data/gogs
2017/11/18 16:29:20 [TRACE] Log path: /app/gogs/log
2017/11/18 16:29:20 [TRACE] Build Time: 2017-08-15 11:47:11 UTC
2017/11/18 16:29:20 [TRACE] Build Git Hash:
2017/11/18 16:29:20 [TRACE] Log Mode: File (Trace)
2017/11/18 16:29:20 [ INFO] Gogs 0.11.29.0727
[Macaron] 2017-11-18 16:29:21: Completed POST /install 302 Found in 3.248179882s
[Macaron] 2017-11-18 16:29:22: Started GET /user/login for 192.168.1.206
[Macaron] 2017-11-18 16:29:22: Completed GET /user/login 302 Found in 9.911956ms
[Macaron] 2017-11-18 16:29:22: Started GET / for 192.168.1.206
[Macaron] 2017-11-18 16:29:22: Completed GET / 200 OK in 107.641008ms
[Macaron] 2017-11-18 16:29:22: Started GET /img/favicon.png for 192.168.1.206
[Macaron] [Static] Serving /img/favicon.png
[Macaron] 2017-11-18 16:29:22: Completed GET /img/favicon.png 200 OK in 2.680918ms
[Macaron] 2017-11-18 16:29:22: Started GET /avatars/1 for 192.168.1.206
[Macaron] [Static] Serving /1
[Macaron] 2017-11-18 16:29:22: Completed GET /avatars/1 200 OK in 1.734935ms
[Macaron] 2017-11-18 16:29:22: Started GET /assets/octicons-4.3.0/octicons.woff2?ef21c39f0ca9b1b5116e5eb7ac5eabe6 for 192.168.1.206
[Macaron] [Static] Serving /assets/octicons-4.3.0/octicons.woff2
[Macaron] 2017-11-18 16:29:22: Completed GET /assets/octicons-4.3.0/octicons.woff2?ef21c39f0ca9b1b5116e5eb7ac5eabe6 200 OK in 6.758595ms
[Macaron] 2017-11-18 16:29:30: Started GET /user/logout for 192.168.1.206
[Macaron] 2017-11-18 16:29:30: Completed GET /user/logout 302 Found in 8.500196ms
[Macaron] 2017-11-18 16:29:30: Started GET / for 192.168.1.206
[Macaron] 2017-11-18 16:29:30: Completed GET / 200 OK in 19.206313ms
Nov 18 16:29:39 syslogd exiting
Nov 18 16:29:51 syslogd started: BusyBox v1.25.1
Nov 18 16:29:51 sshd[26]: Server listening on :: port 22.
Nov 18 16:29:51 sshd[26]: Server listening on 0.0.0.0 port 22.
2017/11/18 16:29:51 [TRACE] Custom path: /data/gogs
2017/11/18 16:29:51 [TRACE] Log path: /app/gogs/log
2017/11/18 16:29:51 [TRACE] Build Time: 2017-08-15 11:47:11 UTC
2017/11/18 16:29:51 [TRACE] Build Git Hash:
2017/11/18 16:29:51 [TRACE] Log Mode: File (Trace)
2017/11/18 16:29:51 [ INFO] Gogs 0.11.29.0727
```

He intentado conectar a una _shell_ dentro del contenedor pero no lo he conseguido. (_Update: Más tarde he pensado que la imagen está basada en Alpine y `/bin/sh` no existe, pero no he probado `/bin/ash`:(_)

Revisando los _issues_ abiertos para Gogs he encontrado [Raspberry pi docker image is broken #4796](https://github.com/gogits/gogs/issues/4796), pero como no hay ninguna respuesta, no he podido avanzar más. El usuario `schvabodka-man` también usa una Raspberry Pi 3, mientras que la imagen está construida para una Raspberry Pi 2, pero esto no debería suponer un problema.

He confirmado que en el contenedor creado a partir de `gogs/gogs` no se reproduce el problema.

Dado que el usuario con el que corre Gogs en el contenedor es el usuario `git` -diferente al usuario con permisos sobre la carpeta del volumen en la RPi- he dado permisos _full_ sobre la carpeta a todo el mundo con `sudo chmod -R 777 /shared/gogs`, pero tampoco ha supuesto ninguna diferencia.

La conexión a través de SSH para Git parecía funcionar, pero tampoco he realizado demasiadas pruebas en esta dirección, ya que parece algún problema con el interfaz web.

La única forma en la que he conseguido devolver a la vida la interfaz web ha sido borrando el fichero `app.ini` y configurando Gogs de nuevo :(