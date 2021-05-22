+++
draft = false
categories = ["dev"]
tags = ["linux", "python", "pip"]
thumbnail = "images/python.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}

title=  "Cómo instalar pip"
date = "2019-04-28T13:25:13+02:00"
+++
`pip` es el _instalador de paquetes_ de Python más usado.

Sin embargo, nunca me ha resultado demasiado evidente cómo instalarlo, gracias a instrucciones tan poco afortunadas como las siguientes que he tenido la mala suerte de encontrar vía Google.
<!--more-->

## Instalación de pip

1. Descarga `get-pip.py`: `wget https://bootstrap.pypa.io/get-pip.py`
2. Instala con `sudo python get-pip.py`: `sudo python get-pip.py`

(Referencia - Documentación oficial del paquete `pip`: [pip 19.1 documentation](https://pip.pypa.io/en/stable/installing/))

## Instalación de `pip` (versión mala suerte buscando en Google, supongo)

En la página de la PyPA ([Python Packaging Authority](https://www.pypa.io/en/latest/)):

{{< figure src="/images/190428/pypa_instructions.png" >}}

Como puedes ver, se indica que se pulse el logo para descargar `pip`. Pero no, en la página de destino, se indica que para instalar `pip`, uses `pip` ¯\\\_(ツ)_/¯:

{{< figure src="/images/190428/pip_install_pip.png" >}}

Tras estas informativas instrucciones, más abajo encontramos dos paquetes.
Soy totalmente _noob_ en Python, así que no sé cual de los dos paquetes descargar o qué hacer con ellos cuando los descargue.
Así que sigo el enlace que indican precisamente para esta situación: [installing packages](https://packaging.python.org/tutorials/installing-packages/).

En esa página se indican las intrucciones para asegurarse de que puedes ejecutar `pip` en la línea de comandos [Ensure you can run pip from the command line](https://packaging.python.org/tutorials/installing-packages/#ensure-you-can-run-pip-from-the-command-line).

Lo primero que tienes que comprobar es que `pip` no esté ya instalado (que no lo está).

```bash
$ pip --version
-bash: pip: command not found
```

A continuación indica cómo instalarlo:

```bash
$ python -m ensurepip --default-pip
/usr/bin/python: No module named ensurepip
```

Again, no luck :(

Finalmente, la manera que funciona **de verdad**:

1. Descarga `get-pip.py`:
2. Instala con `sudo python get-pip.py`:

```bash
$ wget https://bootstrap.pypa.io/get-pip.py
--2019-04-28 --  https://bootstrap.pypa.io/get-pip.py
Resolving bootstrap.pypa.io (bootstrap.pypa.io)... 151.101.132.175, 2a04:4e42:1f::175
Connecting to bootstrap.pypa.io (bootstrap.pypa.io)|151.101.132.175|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 1709825 (1.6M) [text/x-python]
Saving to: 'get-pip.py.1'

get-pip.py         100%[======================>]   1.63M  --.-KB/s    in 0.07s

2019-04-28 (22.5 MB/s) - 'get-pip.py' saved [1709825/1709825]
$ sudo python get-pip.py
[sudo] password for operador:
Collecting pip
  Using cached https://files.pythonhosted.org/packages/f9/fb/863012b13912709c13cf5cfdbfb304fa6c727659d6290438e1a88df9d848/pip-19.1-py2.py3-none-any.whl
Installing collected packages: pip
  Found existing installation: pip 19.1
    Uninstalling pip-19.1:
      Successfully uninstalled pip-19.1
Successfully installed pip-19.1
```

> En mi caso ya lo había conseguido instalar antes, por lo que primero lo desinstala.

Como ves, la instalación de `pip` no es nada complicada... cuando sabes cómo hacerlo ;).