+++
categories = ["dev"]
tags = ["linux", "visual studio code", "ssh"]
thumbnail = "images/code.jpg"
# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}

title=  "Configurar Visual Studio Code para editar código remoto"
date = "2020-01-18T20:52:06+01:00"
+++
En la entrada [Alpine para desarrollo con Python]({{<ref "200118-alpine-para-desarrollo-con-python.md">}}) indiqué cómo configurar una máquina virtual con Alpine Linux para desarrollar con Python.
Aunque es posible editar código en Vi o Emacs en un sistema sin entorno gráfico, yo me siento más cómodo usando algo como Visual Studio Code.

> No es posible usar *Remote - SSH* con Alpine Linux; más detalles, en [¿Por qué Remote - SSH no funciona con Alpine?]({{<ref "200119-porque-remote-ssh-no-funciona-con-alpine.md">}}).

La funcionalidad de Visual Studio Code -VS Code o simplemente, Code- puede ampliarse mediante el uso de [*extensiones*](https://code.visualstudio.com/docs/editor/extension-gallery).
En esta entrada explico cómo usar Code desde tu equipo para editar código remoto a través de SSH.
<!--more-->
Microsoft [publicó](https://code.visualstudio.com/blogs/2019/07/25/remote-ssh) la extensión [Remote - SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh) a mediados de 2019. Para usar *Remote - SSH* necesitas un cliente SSH compatible con OpenSSH instalado localmente y un *host* remoto al que conectar vía SSH.

En mi caso, he configurado sin problemas Code en Linux (Elementary 5.1) y en Mac OS X (Catalina). En Windows (10) he tenido más problemas, aunque al tratarse del equipo del trabajo hay otros factores que pueden influir (Code y SSH en modo portable, *proxy* y seguridad corporativa de por medio, sin permisos de administración, etc).

> "Remote - SSH" **envía telemetría a Microsoft**, como se detalla en la descripción de la extensión. Si quieres usar estas extensiones en un entorno *controlado*, quizás debas consultar al equipo de seguridad de tu empresa.
>
> Además de *Remote - SSH*, Microsoft también ofrece otras extensiones para trabajar "remotamente", como [Remote - WSL](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl) o [Remote - Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers), para conectar con el subsistema de Linux en Windows o con contenedores, respectivamente.

## Pasos previos a la instalación de la extensión

Para facilitar la conexión de Code con la máquina remota, es recomendable establecer autenticación basada en claves SSH.

### Crea un par de claves SSH

> Este paso es opcional, si ya dispones de un par de claves.

Creo un par de claves con el comando `ssh-keygen`. El comando permite especificar el tipo de algoritmo de cigfrado, la fortaleza de la clave, etc...

Lanzo el comando sin ningún parámetro:

```bash
$ ssh-keygen
Generating public/private rsa key pair.
Enter file in which to save the key (/home/operador/.ssh/id_rsa): /home/operador/.ssh/id_rsa_code
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /home/operador/.ssh/id_rsa_code.
Your public key has been saved in /home/operador/.ssh/id_rsa_code.pub.
The key fingerprint is:
SHA256:5nq8pzuXPiYZEOxO+vKr8ubn9IDQg++X1ggvvixevyg operador@D630
The key's randomart image is:
+---[RSA 2048]----+
|     .           |
|      o          |
|     . .         |
|   o  +          |
|  o o+ .S        |
|   ooo.o.        |
|    ++o=.o .     |
|  E+++O+B *      |
| ..OX@B+=@..     |
+----[SHA256]-----+
```

Lo primero que pregunta el comando es el fichero en el que guardar la clave. En mi caso, prefiero tener la clave en un fichero independiente: `id_rsa_code`.

Configuraré Code para usar esta clave para conectar a máquinas remotas donde editar código, por lo que no especifico una contraseña (o *passphrase*).

### Copiar la clave **pública** al equipo remoto

> Este paso es opcional, si ya has copiado la clave **pública** al servidor remoto.

En aquellos sistemas en los que existe el comando `ssh-copy-id`:

```bash
$ ssh-copy-id -i ~/.ssh/id_rsa_code.pub <username>@<ip-equipo-remoto>
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/operador/.ssh/id_rsa_code.pub"
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
<username>@<ip-equipo-remoto>'s password:

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh '<username>@<ip-equipo-remoto>'"
and check to make sure that only the key(s) you wanted were added.
```

El comando se conecta a la máquina remota por SSH (autenticándose con la contraseña) y a continuación copia la clave pública en el fichero `~/.ssh/authorized_keys`. Si tu equipo no dispone de `ssh-copy-id`, debes realizar estos pasos manualmente.

> SSH usa la clave pública `~/.ssh/id_rsa` por defecto; como en mi caso uso un fichero de clave diferente, debo indicar la ruta al fichero que contiene la clave mediante el parámetro `-i ruta/al/fichero/clave`.

## Permisos para las claves SSH

He generado un par de claves: `id_rsa_code` (privada) y `id_rsa_code.pub` (pública).

Si no se establecen los permisos correctos para cada tipo de clave, *Remote - SSH* puede rechazar usar las claves con un mensaje de la forma *permissions are too open*.

Los permisos correctos para cada tipo de clave son:

- Clave privada: 600 `-rw-------`
- Clave pública: 644 `-rw-r--r--`

## Instalación de la extensión Remote - SSH

En el panel lateral, pulsa el selector de las Extensiones; busca la extensión que quieres instalar y pulsa *Install*.

En [Extension Marketplace](https://code.visualstudio.com/docs/editor/extension-gallery) tienes todos los detalles.

## Configuración de la extensión Remote - SSH

Para configurar la extensión *Remote - SSH* pulsa `F1` para abrir la *paleta de comandos* y selecciona *Remote-SSH: Connect to Host*, y en el siguiente menú, selecciona *Configure remote hosts*. Selecciona el fichero -local o global- de configuración y edítalo.

```ini
Host pydev
  HostName 192.168.1.141
  User operador
  IdentityFile ~/.ssh/id_rsa_code
```

La variable `Host` permite dar un nombre *amigable* al equipo remoto, mientras que en `HostName` se indica el nombre DNS o IP del equipo. En el fichero también se indica con qué usuario y fichero de clave conectará Code con el equipo remoto.

Para otras situaciones más específicas -como por ejemplo tener que acceder a la máquina remota a través de un *jumpserver*, conectar a través de un proxy, etc, revisa la documentación [Remote Development Tips and Tricks](https://code.visualstudio.com/docs/remote/troubleshooting).
