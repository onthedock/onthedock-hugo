+++
draft = false
tags = ["raspberry pi", "docker", "gogs"]
categories = ["dev", "ops"]
thumbnail = "images/gogs.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Imagenes
# {{< figure src="/images/image.jpg" w="600" h="400" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}


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

{{< figure src="/images/171118/not-found.png" height="708" width="623" >}}

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

# Actualización (19/11/2017)

He descargado la imagen `gogs/gogs` (0.11.29) en el equipo de laboratorio (x64):

```shell
$ docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
gogs/gogs           0.11.29             111330b56503        15 hours ago        139MB
gogs/gogs           latest              111330b56503        15 hours ago        139MB
```

He lanzado un contenedor pero para mi sorpresa, tampoco he conseguido hacerlo funcionar, siendo imposible conectar al interfaz web (lo mismo que me ocurría en la RPi). He seguido las mismas instrucciones que en la entrada [Gogs - Cómo crear tu propio servicio de hospedaje de repositorios Git]({{<ref "171106-gogs-como-crear-tu-propio-servicio-de-hospedaje-de-repos-git.md">}})), pero no ha habido manera.

He modificado los puertos, he dado permisos _full_ a todo el mundo (chmod -R 777 sobre `/shared/gogs/`) sin éxito, he creado una carpeta dentro la home del usuario `operador`... Nada ha funcionado.

He comprobado que la imagen está basada en Alpine Linux, por lo que finalmente sí que he podido acceder mediante `docker exec -it /bin/ash`, pero no he averiguado nada relevante.

Finalmente se me ha ocurrido lanzar el contenedor sin pasarlo a segundo plano (omitiendo el parámetro `-d`), de manera que la salida se mostraba en la línea de comandos.

De esta forma he observado mensajes de error en la salida por pantalla. Y aunque los errores se muestran al ejecutar `docker logs gogs`, cuando redirijo la salida del comando a un fichero  (`docker logs gogs > docker-gogs.log` no se registran los mensajes de error (aunque parece que está en un bucle infinito, que se va repitiendo constantemente):

```shell
$ cat test.log
Nov 19 19:37:32 syslogd started: BusyBox v1.25.1
Nov 19 19:37:32 sshd[31]: Server listening on :: port 22.
Nov 19 19:37:32 sshd[31]: Server listening on 0.0.0.0 port 22.
2017/11/19 19:37:50 [ WARN] Custom config '/data/gogs/conf/app.ini' not found, ignore this if you're running first time
2017/11/19 19:37:50 [TRACE] Custom path: /data/gogs
2017/11/19 19:37:50 [TRACE] Log path: /app/gogs/log
2017/11/19 19:37:50 [TRACE] Build Time: 2017-11-19 04:16:46 UTC
2017/11/19 19:37:50 [TRACE] Build Git Hash:
2017/11/19 19:37:50 [TRACE] Log Mode: Console (Trace)
2017/11/19 19:37:50 [ INFO] Gogs 0.11.33.1116
2017/11/19 19:37:50 [ INFO] Cache Service Enabled
2017/11/19 19:37:50 [ INFO] Session Service Enabled
2017/11/19 19:37:50 [ INFO] SQLite3 Supported
2017/11/19 19:37:50 [ INFO] Run Mode: Development
2017/11/19 19:37:50 [ WARN] Custom config '/data/gogs/conf/app.ini' not found, ignore this if you're running first time
2017/11/19 19:37:50 [TRACE] Custom path: /data/gogs
2017/11/19 19:37:50 [TRACE] Log path: /app/gogs/log
2017/11/19 19:37:50 [TRACE] Build Time: 2017-11-19 04:16:46 UTC
2017/11/19 19:37:50 [TRACE] Build Git Hash:
2017/11/19 19:37:50 [TRACE] Log Mode: Console (Trace)
2017/11/19 19:37:50 [ INFO] Gogs 0.11.33.1116
2017/11/19 19:37:50 [ INFO] Cache Service Enabled
2017/11/19 19:37:50 [ INFO] Session Service Enabled
2017/11/19 19:37:50 [ INFO] SQLite3 Supported
2017/11/19 19:37:50 [ INFO] Run Mode: Development
2017/11/19 19:37:51 [ WARN] Custom config '/data/gogs/conf/app.ini' not found, ignore this if you're running first time
2017/11/19 19:37:51 [TRACE] Custom path: /data/gogs
2017/11/19 19:37:51 [TRACE] Log path: /app/gogs/log
2017/11/19 19:37:51 [TRACE] Build Time: 2017-11-19 04:16:46 UTC
2017/11/19 19:37:51 [TRACE] Build Git Hash:
```

En estas pruebas que estoy realizando, el fichero `app.ini` no se llega a crear (tampoco la base de datos SQLite, `gogs.db`). Esto me ha llevado a pensar en un problema de permisos, pero tampoco se ha creado cuando he asignado permisos a todo el mundo (777).

Para comprobar esta hipótesis he lanzado el contenedor sin montar ningún volumen (es decir, haciendo que la base de datos se genere _dentro_ del propio contenedor). 

```shell
docker run -d -p 8022:22 -p 3000:3000 gogs/gogs
```

Pero tampoco he tenido éxito.

Pensaba que los errores que he visto desfilar por pantalla los causaba el intento de conectar a la URL de Gogs. Después de crear el contenedor y esperar un rato (unos 5 o 10 segundos), he visto que el error aparecía de forma espontánea.

Dado que `docker logs gogs > errores.log` no escribe los errores en el log, he optado por crear un contenedor mediante `docker run --name gogs -p 8022:22 p:3000:3000 gogs/gogs` y esperar...

> Revisando los _issues_ en GitHub, parece que es un error conocido que se trata como _mejora_ :[Panics should get logged](https://github.com/gogits/gogs/issues/1022)

Al haber lanzado el contenedor sin `-d`, los mensajes se muestran por pantalla, de donde he hecho un _copy & paste_:

```shell
 docker run --name gogs -p 3000:3000 gogs/gogs
usermod: no changes
Nov 19 19:37:32 syslogd started: BusyBox v1.25.1
Nov 19 19:37:32 sshd[31]: Server listening on :: port 22.
Nov 19 19:37:32 sshd[31]: Server listening on 0.0.0.0 port 22.
2017/11/19 19:37:50 [ WARN] Custom config '/data/gogs/conf/app.ini' not found, ignore this if you're running first time
2017/11/19 19:37:50 [TRACE] Custom path: /data/gogs
2017/11/19 19:37:50 [TRACE] Log path: /app/gogs/log
2017/11/19 19:37:50 [TRACE] Build Time: 2017-11-19 04:16:46 UTC
2017/11/19 19:37:50 [TRACE] Build Git Hash:
2017/11/19 19:37:50 [TRACE] Log Mode: Console (Trace)
2017/11/19 19:37:50 [ INFO] Gogs 0.11.33.1116
2017/11/19 19:37:50 [ INFO] Cache Service Enabled
2017/11/19 19:37:50 [ INFO] Session Service Enabled
2017/11/19 19:37:50 [ INFO] SQLite3 Supported
2017/11/19 19:37:50 [ INFO] Run Mode: Development
panic: fail to set message file(sk-SK): open conf/locale/locale_sk-SK.ini: no such file or directory

goroutine 1 [running]:
github.com/gogits/gogs/vendor/github.com/go-macaron/i18n.initLocales(0xc4200b8f15, 0x0, 0xf8b4a5, 0xb, 0xc420814270, 0xc42080c060, 0x16, 0xc4204224e0, 0x1a, 0x1a, ...)
	/tmp/go/src/github.com/gogits/gogs/vendor/github.com/go-macaron/i18n/i18n.go:57 +0x5ff
github.com/gogits/gogs/vendor/github.com/go-macaron/i18n.I18n(0xc420072540, 0x1, 0x1, 0xc42080c060, 0x16)
	/tmp/go/src/github.com/gogits/gogs/vendor/github.com/go-macaron/i18n/i18n.go:158 +0xee
github.com/gogits/gogs/cmd.newMacaron(0xc42043a140)
	/tmp/go/src/github.com/gogits/gogs/cmd/web.go:130 +0xab5
github.com/gogits/gogs/cmd.runWeb(0xc42043a140, 0x0, 0xc42043a140)
	/tmp/go/src/github.com/gogits/gogs/cmd/web.go:166 +0x74
github.com/gogits/gogs/vendor/github.com/urfave/cli.HandleAction(0xe631e0, 0xfc7d78, 0xc42043a140, 0xc420428400, 0x0)
	/tmp/go/src/github.com/gogits/gogs/vendor/github.com/urfave/cli/app.go:483 +0xb9
github.com/gogits/gogs/vendor/github.com/urfave/cli.Command.Run(0xf7ee8d, 0x3, 0x0, 0x0, 0x0, 0x0, 0x0, 0xf92aef, 0x10, 0x0, ...)
	/tmp/go/src/github.com/gogits/gogs/vendor/github.com/urfave/cli/command.go:193 +0xb72
github.com/gogits/gogs/vendor/github.com/urfave/cli.(*App).Run(0xc42010ba00, 0xc42000c140, 0x2, 0x2, 0x0, 0x0)
	/tmp/go/src/github.com/gogits/gogs/vendor/github.com/urfave/cli/app.go:250 +0x7d0
main.main()
	/tmp/go/src/github.com/gogits/gogs/gogs.go:41 +0x3ea
2017/11/19 19:37:50 [ WARN] Custom config '/data/gogs/conf/app.ini' not found, ignore this if you're running first time
2017/11/19 19:37:50 [TRACE] Custom path: /data/gogs
2017/11/19 19:37:50 [TRACE] Log path: /app/gogs/log
2017/11/19 19:37:50 [TRACE] Build Time: 2017-11-19 04:16:46 UTC
2017/11/19 19:37:50 [TRACE] Build Git Hash:
2017/11/19 19:37:50 [TRACE] Log Mode: Console (Trace)
2017/11/19 19:37:50 [ INFO] Gogs 0.11.33.1116
2017/11/19 19:37:50 [ INFO] Cache Service Enabled
2017/11/19 19:37:50 [ INFO] Session Service Enabled
2017/11/19 19:37:50 [ INFO] SQLite3 Supported
2017/11/19 19:37:50 [ INFO] Run Mode: Development
panic: fail to set message file(sk-SK): open conf/locale/locale_sk-SK.ini: no such file or directory

goroutine 1 [running]:
github.com/gogits/gogs/vendor/github.com/go-macaron/i18n.initLocales(0xc4200b8ef5, 0x0, 0xf8b4a5, 0xb, 0xc42081e510, 0xc4206ff4e0, 0x16, 0xc4204224e0, 0x1a, 0x1a, ...)
	/tmp/go/src/github.com/gogits/gogs/vendor/github.com/go-macaron/i18n/i18n.go:57 +0x5ff
github.com/gogits/gogs/vendor/github.com/go-macaron/i18n.I18n(0xc420072540, 0x1, 0x1, 0xc4206ff4e0, 0x16)
	/tmp/go/src/github.com/gogits/gogs/vendor/github.com/go-macaron/i18n/i18n.go:158 +0xee
github.com/gogits/gogs/cmd.newMacaron(0xc42043a140)
	/tmp/go/src/github.com/gogits/gogs/cmd/web.go:130 +0xab5
github.com/gogits/gogs/cmd.runWeb(0xc42043a140, 0x0, 0xc42043a140)
	/tmp/go/src/github.com/gogits/gogs/cmd/web.go:166 +0x74
github.com/gogits/gogs/vendor/github.com/urfave/cli.HandleAction(0xe631e0, 0xfc7d78, 0xc42043a140, 0xc420428400, 0x0)
	/tmp/go/src/github.com/gogits/gogs/vendor/github.com/urfave/cli/app.go:483 +0xb9
github.com/gogits/gogs/vendor/github.com/urfave/cli.Command.Run(0xf7ee8d, 0x3, 0x0, 0x0, 0x0, 0x0, 0x0, 0xf92aef, 0x10, 0x0, ...)
	/tmp/go/src/github.com/gogits/gogs/vendor/github.com/urfave/cli/command.go:193 +0xb72
github.com/gogits/gogs/vendor/github.com/urfave/cli.(*App).Run(0xc420109a00, 0xc42000c140, 0x2, 0x2, 0x0, 0x0)
	/tmp/go/src/github.com/gogits/gogs/vendor/github.com/urfave/cli/app.go:250 +0x7d0
main.main()
	/tmp/go/src/github.com/gogits/gogs/gogs.go:41 +0x3ea
2017/11/19 19:37:51 [ WARN] Custom config '/data/gogs/conf/app.ini' not found, ignore this if you're running first time
2017/11/19 19:37:51 [TRACE] Custom path: /data/gogs
2017/11/19 19:37:51 [TRACE] Log path: /app/gogs/log
2017/11/19 19:37:51 [TRACE] Build Time: 2017-11-19 04:16:46 UTC
2017/11/19 19:37:51 [TRACE] Build Git Hash:
2017/11/19 19:37:51 [TRACE] Log Mode: Console (Trace)
2017/11/19 19:37:51 [ INFO] Gogs 0.11.33.1116
2017/11/19 19:37:51 [ INFO] Cache Service Enabled
2017/11/19 19:37:51 [ INFO] Session Service Enabled
2017/11/19 19:37:51 [ INFO] SQLite3 Supported
2017/11/19 19:37:51 [ INFO] Run Mode: Development
panic: fail to set message file(sk-SK): open conf/locale/locale_sk-SK.ini: no such file or directory
...
^C
Nov 19 19:37:55 sshd[31]: Received signal 15; terminating.
Nov 19 19:37:55 syslogd exiting
```

En los logs -que he truncado- se repite una y otra vez el mismo patrón: el contenedor arranca con normalidad, pero pasados unos veinte segundos, aparece un mensaje de pánico al no encontrar un fichero de localización para el idioma sk-SK (¿¡!?) `panic: fail to set message file(sk-SK): open conf/locale/locale_sk-SK.ini: no such file or directory`. Este mensaje de error desencadena una serie de mensajes de error de Go... Hasta que, de nuevo, se vuelve a alertar de la ausencia del fichero de configuración `app.ini` y vuelta a empezar.

> Revisando los _issues_ cerrados, el [Docker won't create/init files #4876](https://github.com/gogits/gogs/issues/4876) que describe exactamente la situación descrita, se ha cerrado hace 3h!!

He revisado en DockerHub y, efectivamente, la imagen para la versión 0.11.33 se ha construido automáticamente hace apenas dos horas...

{{< figure src="/images/171118/gogs-image-2h-ago.png" w="808" h="573" >}}

Y a todo esto, tengo problemas para descargar la última versión:

```shell
$ docker pull gogs/gogs
Using default tag: latest
Error response from daemon: Get https://registry-1.docker.io/v2/: dial tcp: lookup registry-1.docker.io on [::1]:53: read udp [::1]:52357->[::1]:53: read: connection refused
```

La [solución](https://github.com/docker/for-mac/issues/1317) pasa por desinstalar y volver a instalar Docker (¿¡!?) y cuando lo intento descubro que la máquina virtual tiene algún problema con la resolución de nombres (usando los DNSs de Google (¡¡¿¿??!!)), así que después de cambiar de nuevo a IP dinámica, reiniciar, recuperar la conectividad, reinstalar Docker, descargar la última versión de la imagen de Gogs (0.11.33) la página de configuración vuelve a mostrarse.

{{< figure src="/images/171118/gogs-back-to-live.png" w="914" h="411" >}}

En cuanto a la imagen para Raspberry Pi, también se ha construido una nueva versión:

{{< figure src="/images/171118/gogs-rpi-image-4min-ago.png" w="716" h="483" >}}

Después de comprobar que todo ha sido un problema puntual, he vuelto a establecer IP estática en el _host_ y he verificado que Gogs sigue arrancando después de parar el contenedor (y de modificar la configuración).

## Resumen

En pocas palabras, **mala suerte**; al parecer, por un problema de _timing_, la imagen de Gogs tenía algún problema. No acabo de enteneder cómo la prueba del otro día funcionó.

Parece que con esta nueva versión de la imagen de Gogs, Gogs funciona como se espera. Así que probaré de nueva con la RPi (y con el equipo del laboratorio).