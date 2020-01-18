+++
title = "Alpine para desarrollo con Python"
date = "2020-01-18T19:00:21+01:00"
draft = false

categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "alpine", "python"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/python.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}

+++
Para practicar con Python, he instalado una máquina virtual con Alpine 3.9. En esta entrada recojo los diferentes pasos que he realizado para configurarla como entorno de ejecución de Python 3.
<!--more-->
## Habilitar usuario no *root*

Alpine arranca en modo *live* y mediante la ejecución del script `setup-alpine` configuro e instalo la distrbución en el disco duro de la máquina virtual.

Tras la instalación de Alpine únicamente tengo el usuario *root*; es conveniente crear un usuario *no-root* para poder trabajar con los mínimos permisos posibles.

Para crear un usuario *no-root* uso `adduser`

```bash
adduser operador
```

Instalo `sudo` y añado el usuario al fichero `/etc/sudoers`:

```bash
apk add sudo
visudo
```

En el fichero he añadido la línea:

```ini
operador ALL=(ALL) ALL
```

> Inicialmente he creado un fichero `/etc/sudoers.d/operador.usr` (con permisos `0440`) pero al intentar elevar permisos recibía el mensaje `user is not in the sudoers file`, por lo que finalmente he dado permisos directamente en `/etc/sudoers`.

Al disponer de un usuario *no-root*, ya puedo conectar remotamente vía SSH.

## Instalación de Python

En Alpine (3.9) Python no está instalado por defecto (ni Python 2.7 ni 3.x).

> [Desde el 01/01/2020 Python 2.7 ha alcanzado la fecha final de soporte](https://www.python.org/dev/peps/pep-0373/#update) y **no está mantenido oficialmente**.

Instalo Python 3 mediante:

```bash
sudo apk update
sudo apk add python3
```

Compruebo la versión instalada mediante:

```bash
$ python3 --version
Python 3.6.9
```

Valido que también se ha instalado `pip3`:

```bash
$ pip3 --version
pip 18.1 from /usr/lib/python3.6/site-packages/pip (python 3.6)
```

## Creación de entornos virtuales

El módulo `venv` permite crear "entornos virtuales" autocontenidos en una carpeta. De esta forma podemos tener diferentes versiones de Python o de alguno de sus paquetes sin interferencias entre ellos.

Para crear un *entorno virtual* llamado `pydev`:

```bash
python3 -m venv pydev
```

> De forma general `python3 -m venv /ruta/a/la/carpeta/del/entorno/virtual`

Este comando crea la carpeta `pydev` y un fichero `pyvenv.cfg` que contiene la ruta al intérprete de Python usado en el entorno virtual, la versión y otros parámetros de configuración:

```ini
home = /usr/bin
include-system-site-packages = false
version = 3.6.9
```

Una vez creado el entorno virtual, es necesario activarlo. Para ello se usa un script (la ubicación específica depende de la plataforma y *shell* que uses, ver [la documentación oficial](https://docs.python.org/3/library/venv.html)).

ASH, la *shell* que usa Alpine Linux no forma parte de la documentación de `venv`, pero compruebo que el fichero `activate` está en la ruta `(venv)/bin/activate`. Como el comando `source` no se reconoce en Alpine, uso la forma "general", mediante un ".":

```bash
$ . pydev/bin/activate
(pydev) pydev:~$
```

Observa que el *prompt* cambia para indicar te encuentras en el entorno virtual `pydev`.
