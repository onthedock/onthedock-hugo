+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "hugo"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/linux.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}

title=  "Como enviar un proceso a segundo plano (y recuperarlo después)"
date = "2019-12-08T08:19:29+01:00"
+++
Cuando se lanza un comando en la terminal -en general-, hace lo que tiene que hacer y termina. Sin embargo, algunos procesos se ejecutan indefinidamente (hasta que el usuario los termina usando `Ctrl+C`). En este caso, el terminal queda *bloqueado*, en el sentido de que el usuario no puede lanzar nuevos comandos.

En esta entrada indico las diferentes opciones que tienes para poder gestionar comandos en un terminal de Linux.
<!--more-->

Durante esta entrada voy a usar como ejemplo [`hugo server`](https://gohugo.io/commands/hugo_server/); el servidor web que Hugo proporciona para construir y servir un sitio web durante el desarrollo de las diferentes entradas del sitio (en local, antes de subirlo a producción/publicarlo en internet).

Si ejecutas el comando tal cual:

```bash
$ hugo server
Building sites … WARN 2019/12/08 08:42:47 .File.Path on zero object. Wrap it in if or with: {{ with .File }}{{ .Path }}{{ end }}

                   | EN
+------------------+-----+
  Pages            | 287
  Paginator pages  |  48
  Non-page files   |   0
  Static files     | 172
  Processed images |   0
  Aliases          |  83
  Sitemaps         |   1
  Cleaned          |   0

Total in 1157 ms
Watching for changes in /Users/xavi/Dev/hugo/onthedock-githubpages/{content,static,themes}
Watching for config changes in /Users/xavi/Dev/hugo/onthedock/onthedock-config.toml
Environment: "development"
Serving pages from memory
Running in Fast Render Mode. For full rebuilds on change: hugo server --disableFastRender
Web Server is available at http://localhost:1313/ (bind address 127.0.0.1)
Press Ctrl+C to stop
```

Como puedes ver en la salida del comando, Hugo se mantiene en ejecución *vigilando* el contenido de una carpeta y en caso de modificación, reconstruye el sitio web y actualiza el servidor web para cargar el nuevo contenido:

```bash
...
Running in Fast Render Mode. For full rebuilds on change: hugo server --disableFastRender
Web Server is available at http://localhost:1313/ (bind address 127.0.0.1)
Press Ctrl+C to stop

Change detected, rebuilding site
2019-12-08 08:54:34.175 +0100
Source changed "/Users/xavi/Dev/hugo/onthedock/content/post/191208-como-enviar-un-proceso-a-segundo-plano-y-recuperarlo-despues.md": WRITE
Total in 101 ms
```

Mientras `hugo server` está en ejecución, no devuelve el control al terminal y, por tanto, no es posible ejecutar nuevos comandos.

## Abrir un nuevo terminal

La primera opción para poder lanzar nuevos comandos mientras un proceso en ejecución bloquea el terminal es, simplemente, lanzar un nuevo terminal.

Si estás en un equipo con entorno gráfico, puedes lanzar una nueva instancia de tu programa de terminal (o abrir una nueva pestaña).

Si estás conectado en remoto a un equipo vía SSH, por ejemplo, puedes abrir una nueva conexión contra el mismo equipo.

Si estás conectado localmente a un equipo sin entorno gráfico, puedes abrir una nueva terminal mediante la combinación de `Alt` y las teclas de función (`F1`, `F2`, etc.). Si el sistema tienen una sesión X abierta, la combinación es `Ctrl+Alt`y las teclas de función.

> Al comprobar la combinación de teclas en el párrafo anterior, he encontrado el artículo [How To Switch Between TTYs Without Using Function Keys In Linux](https://www.ostechnix.com/how-to-switch-between-ttys-without-using-function-keys-in-linux/) con un montón de formas adicionales que desconocía para cambiar entre consolas.

## Gestión de procesos

En vez de crecer en horizontal, lanzando consolas adicionales, puedes gestionar los procesos en una única consola.

### Suspender un proceso

Si has lanzado un proceso y por algún motivo necesitas de forma imperiosa realizar otra cosa sin interrumpirlo, puedes suspenderlo. Para ello, pulsa `Ctrl+z`:

```bash
...
Environment: "development"
Serving pages from memory
Running in Fast Render Mode. For full rebuilds on change: hugo server --disableFastRender
Web Server is available at http://localhost:1313/ (bind address 127.0.0.1)
Press Ctrl+C to stop
^Z
[1]  + 2402 suspended  hugo server
$
```

Al pulsar `Ctrl+z` (que la consola recoge como `^Z`), el proceso con PID 2402 -en mi caso- se *suspende*. Esto significa que sigue en memoria, pero no se está ejecutando. Puedes comprobarlo con `ps | grep 2402`.

También puedes observar como en el terminal aparece de nuevo el *prompt*, listo para ejecutar nuevos comandos.

Para *despertar* el proceso suspendido, escribe `fg`:

```bash
$ fg
[1]  + 2402 continued  hugo server --config onthedock-config.toml

Change detected, rebuilding site
2019-12-08 17:52:54.473 +0100
Source changed "/Users/xavi/Dev/hugo/onthedock-githubpages/content/post/191208-como-enviar-un-proceso-a-segundo-plano-y-recuperarlo-despues.md": WRITE|CHMOD
Total in 111 ms
```

### Continuar un proceso suspendido en segundo plano

Al suspender un proceso, se detiene su ejecución (aunque no se interrumpe de forma definitiva).

Si se trata, como en este caso, de lanzar un servidor web, lo ideal sería que el proceso continue en ejecución, pero que *libere* la terminal para seguir ejecutando comandos.

Esto podemos lograrlo de dos formas diferentes.

Si tenemos el proceso en marcha, como en el caso anterior, pulsando `Ctrl+z` lo suspendemos. Como hemos dicho, el comando está en segundo plano, pero no se ejecuta.

Podemos *activarlo* **dejándolo en segundo plano** mediante el comando `bg` (la forma *corta* de *background*):

```bash
Source changed "/Users/xavi/Dev/hugo/onthedock-githubpages/content/post/191208-como-enviar-un-proceso-a-segundo-plano-y-recuperarlo-despues.md": WRITE
Total in 150 ms
^Z
[1]  + 2402 suspended  hugo server

$ bg
[1]  + 2402 continued  hugo server

$
```

Al lanzar `bg` el comando en estado *suspended* pasa a *continued*, aunque permanece en segundo plano.

### Ejecutar un proceso en segundo plano

Aunque con la combinación de `Ctrl+z` seguida del comando `bg` conseguimos tener un proceso en ejecución en segundo plano, existe una manera más sencilla -o directa- de conseguir el mismo resultado.

Para ello, lanza el comando -`hugo server` en nuestro caso- **seguido de `&`** (*ampersand*):

```bash
$ hugo server &
[1] 3367
Building sites … WARN 2019/12/08 18:04:36 .File.Path on zero object. Wrap it in if or with: {{ with .File }}{{ .Path }}{{ end }}
...
$
```

Observa que la terminal muestra el *prompt*, lo que indica que sigue aceptando la entrada de nuevos comandos.

Además, la salida indica:

```bash
[1] 3367
```

Esto indica que el proceso con el PID 3367 se ejecuta en segundo plano.

Como en el caso anterior, puedes devolver el proceso en segundo plano al primer plano mediante el comando `fg` (*foreground*).

### Feedback de los procesos en segundo plano

Si alguno de los procesos envía información a `stdout` o `stderr` mientras se encuentra en segundo plano, ésta aparece en la terminal.

Puedes comprobarlo lanzando `sleep 10  &` y esperando que finalice:

```bash
$ sleep 10 &
[1] 3922
$
(10 segundos después)
[1] - 3922 done sleep 10
$
```

## Gestionando múltiples procesos

Hasta ahora sólo hemos estado gestionando un único proceso. Sin embargo, podemos tener varios procesos ejecutándose en segundo plano y nos puede interesar trearlos a primer plano de forma alternativa, por ejemplo, para revisar el progreso de cada uno.

He lanzado dos comandos `sleep` seguidos de `&` para enviarlos a segundo plano.

Para consultar los procesos en ejecución en segundo plano, ejecuta el comando `jobs`:

```bash
$ jobs
[1]    running    hugo server
[2]  - running    sleep 200
[3]  + running    sleep 250
```

Como ves, cada uno de los procesos está precedido del número de *job*.

Para devolver el proceso identificado con el *job id* `2` a primer plano, ejecuta el comando `fg %2`:

```bash
$ fg %2
[2]  - 4259 running    sleep 200
```

Si tienes varios procesos suspendidos en segundo plano, puedes activarlos selectivamente mediante `bg %#`, donde `#` es el número de *job* asociado al proceso.

```bash
$ jobs
[1]    running    hugo server
[2]  - suspended  sleep 200
[3]  + suspended  sleep 250

$ bg %3
[3]  - 4997 continued  sleep 250

$ jobs
[1]    running    hugo server
[2]  + suspended  sleep 200
[3]  - running    sleep 250
```

## Resumen

En esta entrada hemos repasado los diferentes comandos que permiten gestionar procesos en ejecución en Linux. Usando `Ctrl+Z`, `fg` y `bg` puedes controlar los procesos en ejecución, enviándolos a segundo plano y suspendiéndolos cuando sea necesario sin necesidad de interrumpirlos.
