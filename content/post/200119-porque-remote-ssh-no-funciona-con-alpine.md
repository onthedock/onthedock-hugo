+++
categories = ["dev"]
tags = ["linux", "alpine", "visual studio code", "ssh"]
thumbnail = "images/code.jpg"


# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}

title=  "Por qué Remote-SSH no funciona con Alpine Linux"
date = "2020-01-19T12:56:18+01:00"
+++
En la entrada sobre [cómo configurar Visual Studio Code para editar código remoto]({{<ref "200118-configurar-vscode-para-editar-codigo-remoto.md">}}) con la extensión *Remote - SSH* indicaba cómo configurar Code para editar código en una máquina remota.

Mi intención era usar una máquina ligera, con Alpine Linux como equipo remoto; al fin y al cabo, sólo necesito Python. Con esa idea escribí la entrada [Alpine para desarrollo con Python]({{<ref "200118-alpine-para-desarrollo-con-python.md">}}).

Sin embargo, *Remote - SSH* no funciona cuando la máquina remota es Alpine Linux.

<!--more-->

### Problemas con sistemas con un *shell* diferente a `bash`, por ejemplo Alpine Linux

En la página [Remote Development Tips and Tricks](https://code.visualstudio.com/docs/remote/troubleshooting) se indica que una causa por la que Visual Studio Code puede no conectar con un equipo remoto es porque se lance una *shell* diferente a `bash`.

> **Check whether a different shell is launched during install**
>
> Some users launch a different shell from their .bash_profile or other startup script on their SSH host because they want to use a different shell than the default. This can break VS Code's remote server install script and isn't recommended. Instead, use chsh to change your default shell on the remote machine.

Existe un *issue* abierto al respecto: [remote-ssh: Add possibility to invoke a login shell #1671](https://github.com/microsoft/vscode-remote-release/issues/1671) en el que se están valorando diferentes opciones para permitir diferentes *shells*.

En mi caso, esto implica que "Remote - SSH" no funciona *out of the box* con Alpine como sistema remoto, ya que el *shell* es ASH y no BASH, como se puede ver en el error que muestra Code:

```bash
...
Got stderr from ssh: OpenSSH_7.6p1 Ubuntu-4ubuntu0.3, OpenSSL 1.0.2n  7 Dec 2017
Running script with connection command: ssh -T -D 38627 -o ConnectTimeout=15 192.168.1.141 bash
Install and start server if needed
> ash: bash: not found
Got some output, clearing connection timeout
"install" terminal command done
Install terminal quit with output: ash: bash: not found
Received install output: ash: bash: not found
Stopped parsing output early. Remaining text: ash: bash: not found
Failed to parse remote port from server output
...
```

### Instalación de `bash` en Alpine Linux

Se puede instalar `bash` en Alpine, lo que permitiría sortear este problema mientras no se soluciona el *issue* abierto en GitHub para poder elegir -o detectar- el *shell* del equipo remoto.

```bash
sudo apk update
sudo apk add bash bash-completion
```

El paso final es modificar la *shell* que se lanza en el login de los usuarios. Para modificarla, hay que editar el fichero `/etc/passwd` (como `root`) y sustituir `/bin/ash` por `/bin/bash`.

### Problemas -irresolubles- con bibliotecas del sistema en Alpine Linux

Después de instalar BASH, Remote - SSH no conecta porque [Alpine no cumple con los requerimientos](https://code.visualstudio.com/docs/remote/linux#_remote-host-container-wsl-linux-prerequisites) de las "librerías" `glibc` y `libstdc++`:

```bash
...
> a30126f6ffac: running
> Illegal option -p
> musl libc (x86_64)
> Version 1.1.20
> Dynamic Program Loader
> Usage: ldd [options] [--] pathname
> Missing GLIBC >= 2.17!
> Found version 
> a30126f6ffac$$1$$
> Acquiring lock on /home/operador/.vscode-server/bin/26076a4de974ead31f97692a0d32f90d735645c0/vscode-remote-lock.26076a4de974ead31f97692a0d32f90d735645c0
> ls: unrecognized option: sort=time
> BusyBox v1.29.3 (2019-01-24 07:45:07 UTC) multi-call binary.
...
```

Uno de los motivos por los que Alpine Linux es tan ligero es porque usa [uClibc](https://uclibc.org/about.html) en vez de [glibc, the GNU C Library](https://www.gnu.org/software/libc/libc.html). *uClibc* es mucho más pequeño que *glibc*, orientado a sistemas incrustados (*embedded systems*) y aunque casi todas las aplicaciones funcionan perfectamente con *uClibc*, algunas *no lo hacen*.

En la página dedicada a [ejecutar aplicaciones *glibc*](https://wiki.alpinelinux.org/wiki/Running_glibc_programs) en Alpine Linux se indica -aunque es un *work in progress*- cómo ejecutar aplicaciones que usan *glibc* en diferentes escenarios.

Sin embargo, en mi caso, lo más sencillo es usar Debian u otra distribución como sistema operativo de la máquina remota en la que desarrollar aplicaciones con Python.
