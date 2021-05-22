+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev", "ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["aws"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/aws.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}

title=  "Instala la herramienta de línea de comandos de AWS"
date = "2019-08-20T19:48:20+02:00"
+++
Los primeros pasos en el cloud de Amazon se dan a través de la consola web de AWS.

Sin embargo, la verdadera potencia de AWS es que todas las acciones que se realizan a través de la consola se pueden ejecutar desde la línea de comandos.

Y si pueden ejecutarse desde la línea de comandos, pueden **automatizarse**.

Ahí es donde empieza lo interesante...

Pero antes necesitamos instalar `aws-cli` (o simplemente `aws`), la herramienta de línea de comandos para interaccionar con la API de AWS.
<!--more-->

La consola está desarrollada en Python, por lo que puedes instalarla en cualquier sistema operativo donde puedas correr Python. Sí, eso incluye Windows (aquí tienes la documentación sobre cómo hacerlo: [Install the AWS CLI on Windows](https://docs.aws.amazon.com/cli/latest/userguide/install-windows.html)), aunque lo habitual es trabajar desde Linux.

En Linux, es habitual tener Python instalado _de base_ en el sistema operativo. Para comprobarlo, ejecuta `python --version`:

```bash
$ python --version
Python 2.7.15+
```

> En la mayoría de las versiones de Linux se incluye tanto Python 2.7 como Python 3.
> Puedes comprobarlo ejecutando `python3 --version`

El siguiente paso es instalar `pip`. De nuevo, puedes comprobar si está instalado usando `pip --version` o `pip3 --version`.

```bash
$ pip --version

Command 'pip' not found, but can be installed with:

sudo apt install python-pip
```

Como ves, en mi caso no tengo ni uno ni otro. Así que siguiendo la recomendación de la página [Install the AWS CLI on Linux](https://docs.aws.amazon.com/cli/latest/userguide/install-linux.html), instalo la versión para Python 3 de `pip`: `sudo apt install python3-pip`.

Tras la instalación:

```bash
$ pip3 --version
pip 9.0.1 from /usr/lib/python3/dist-packages (python 3.6)
```

Una vez tenemos los requerimientos previos, pasamos a instalar **`aws`**:

> Con `--user` instalamos la consola sólo para el usuario actual, sin necesidad de permisos de `root`.

```bash
$  pip3 install awscli --upgrade --user
Collecting awscli
  Downloading https://files.pythonhosted.org/packages/2a/e1/4dd677b7e92577d9b3a1427bf6b619d6bc98156196e24564a85fbe74c344/awscli-1.16.221-py2.py3-none-any.whl (1.9MB)
    100% |████████████████████████████████| 1.9MB 785kB/s
Collecting colorama<=0.3.9,>=0.2.5 (from awscli)
  Downloading https://files.pythonhosted.org/packages/db/c8/7dcf9dbcb22429512708fe3a547f8b6101c0d02137acbd892505aee57adf/colorama-0.3.9-py2.py3-none-any.whl
Collecting s3transfer<0.3.0,>=0.2.0 (from awscli)
...
```

Sólo queda comprobar que la herramienta de línea de comandos `aws` se ha instalado correctamente:

```bash
$ aws --version

Command 'aws' not found, but can be installed with:

sudo snap install aws-cli  # version 1.16.148, or
sudo apt  install awscli

See 'snap info aws-cli' for additional versions.
```

**Oops!**

Siguiendo las instrucciones de la página oficial parece la ruta en la que se ha instalado `aws` no forma parte del `path`.

> Para otros errores relacionados con `aws` tienes la página [Troubleshooting AWS CLI Errors](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-troubleshooting.html)

Una manera sencilla de comprobar esta hipótesis es ejecutar `aws` incluyendo toda la ruta:

```bash
$ ~/.local/bin/aws --version
aws-cli/1.16.221 Python/3.6.8 Linux/4.15.0-58-generic botocore/1.12.211
```

Uno de los muchos lugares de internet donde explican como añadir una ruta al _PATH_ es [How to permanently set $PATH on Linux/Unix?](https://stackoverflow.com/questions/14637979/how-to-permanently-set-path-on-linux-unix)

Puedes editar el fichero `~/.profile` o `~/.bash_login`; en mi caso en el fichero `~/.profile` ya se incluye un condicional que debería añadir esta ruta al `PATH`...

```bash
...
# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi
...
```

_Googleando_ sobre los diferentes ficheros, `~/.profile` (ver por ejemplo la entrada [What are the functional differences between .profile .bash_profile and .bashrc
](https://serverfault.com/questions/261802/what-are-the-functional-differences-between-profile-bash-profile-and-bashrc)), el fichero `.profile` es genérico, mientras que `.bash_profile` es específico para la _shell_ BASH.

La raíz de mi problema, sin embargo, parece estar relacionado con _cuándo_ se lee este fichero: durante el inicio de una sesión interactiva (un _login_). Esto me obligaría a cerrar sesión y volver a entrar para recargar el fichero.

Sin embargo, hay una forma alternativa de hacer que se lea el fichero sin necesidad de hacer _login_ de nuevo; y la respuesta se encuentra en [Reload bash's .profile without logging out and back in again](https://askubuntu.com/questions/59126/reload-bashs-profile-without-logging-out-and-back-in-again):

```bash
$ . ~/.profile
$
```

El punto es un sinónimo de `source` (mira la sección _SHELL BUILTIN COMMANDS_ de [bash](http://manpages.ubuntu.com/manpages/disco/en/man1/bash.1.html)), que "exporta" -a falta de un nombre mejor- el contenido del fichero y lo pone a disposición de la _shell_.

Comprobamos de nuevo -ahora sin la ruta completa- la versión de `aws`:

```bash
$ aws --version
aws-cli/1.16.221 Python/3.6.8 Linux/4.15.0-58-generic botocore/1.12.211
```

Y ahora sí, ¡todo funciona correctamente!

`aws cli` es un "cliente" para interaccionar con la API de AWS. Usando la API puedes interaccionar con las diferentes cuentas que tengas en AWS y realizar **virtualmente** cualquier acción que podrías realizar a través de la consola web de AWS.

> Existen algunos pocos casos en los que la API **todavía** no expone determinadas funcionalidades, pero tienen a ser casos muy específicos (como establecer la información fiscal de las cuentas).

Para poder empezar a interaccionar con la API necesitarás crear un usuario IAM (y sus credenciales); en el siguiente artículo explico cómo configurar AWS cli de manera que puedas usar estas credenciales para realizar acciones sobre tu cuenta a través de la API desde la línea de comandos.
