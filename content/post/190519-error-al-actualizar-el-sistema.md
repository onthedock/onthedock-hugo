+++
draft = false
categories = ["ops"]
tags = ["linux", "debian", "apt"]
thumbnail = "images/linux.png"

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}

title=  "Error al actualizar el sistema"
date = "2019-05-19T18:11:23+02:00"
+++
Después de resolver el [problema con el DNS]({{<ref "190519-iniciar-dnsmasq-durante-el-inicio-del-sistema.md">}}) en el equipo de laboratorio tenía varias actualizaciones pendientes de instalar.

Sin embargo, una de las actualizaciones ha fallado por no tener bien resueltas las depedencias:

<!--more-->

```bash
$ sudo apt upgrade -y
Reading package lists... Done
Building dependency tree       
Reading state information... Done
You might want to run 'apt --fix-broken install' to correct these.
The following packages have unmet dependencies:
 python-samba : Depends: libwbclient0 (= 2:4.5.16+dfsg-1+deb9u1) but 2:4.5.16+dfsg-1+deb9u2 is installed
                Depends: samba-libs (= 2:4.5.16+dfsg-1+deb9u1) but 2:4.5.16+dfsg-1+deb9u2 is installed
E: Unmet dependencies. Try 'apt --fix-broken install' with no packages (or specify a solution).
```

Siguiendo las instrucciones de la salida del comando, he lanzado `sudo apt --fix-broken install`:

```bash
$ sudo apt --fix-broken install
...
SyntaxError: invalid syntax
dpkg: error processing archive /var/cache/apt/archives/python-samba_2%3a4.5.16+dfsg-1+deb9u2_amd64.deb (--unpack):
 subprocess new pre-removal script returned error exit status 1
Traceback (most recent call last):
  File "/usr/bin/pycompile", line 35, in <module>
    from debpython.version import SUPPORTED, debsorted, vrepr, \
  File "/usr/share/python/debpython/version.py", line 24, in <module>
    from ConfigParser import SafeConfigParser
ImportError: No module named 'ConfigParser'
dpkg: error while cleaning up:
 subprocess installed post-installation script returned error exit status 1
Errors were encountered while processing:
 /var/cache/apt/archives/python-samba_2%3a4.5.16+dfsg-1+deb9u2_amd64.deb
E: Sub-process /usr/bin/dpkg returned an error code (1)
```

## Buscando información sobre el error

A través de Google he encontrado esta entrada en [StackExchange: How to remove/install a package that is not fully installed?](https://askubuntu.com/questions/438345/how-to-remove-install-a-package-that-is-not-fully-installed).

La respuesta indica que el fallo se encuentra en el _pre-removal script returned error exit status 1_, por lo que lo que hay que hacer es revisar este script y ver qué hace para entenderlo.

Aunque el consejo parece lícito, he perdido un buen rato revisando el script y ejecutando comandos potencialmente peligrosos como `root`; el script lista los diferentes scripts en Python que componen el paquete `python-samba` y los elimina:

```bash
$ cat /var/lib/dpkg/info/python-samba.prerm 
#!/bin/sh
set -e

# Automatically added by dh_python2:
if which pyclean >/dev/null 2>&1; then
	pyclean -p python-samba 
else
	dpkg -L python-samba | grep \.py$ | while read file
	do
		rm -f "${file}"[co] >/dev/null
  	done
fi

# End automatically added section
```

Me ha parecido _sospechoso_ el `[co]` tras el nombre de fichero, pero después de eliminarlo, obtenía el mismo error.

## Cambiando el enfoque

Revisando de nuevo el error me he concentrado en la parte del `ImportError`:

```bash
$ sudo apt install python-samba --upgrade
...
ImportError: No module named 'ConfigParser'
dpkg: error while cleaning up:
 subprocess installed post-installation script returned error exit status 1
Errors were encountered while processing:
 /var/cache/apt/archives/python-samba_2%3a4.5.16+dfsg-1+deb9u2_amd64.deb
E: Sub-process /usr/bin/dpkg returned an error code (1)
```

En la entrada de [StackOverflow: Python 3 ImportError: No module named 'ConfigParser'](https://stackoverflow.com/questions/14087598/python-3-importerror-no-module-named-configparser) se deja bien claro que `ConfigParser` ya no existe en Python 3; ha sido renombrado a `configparser`, por lo que el paquete que lo usa no es compatible con Python 3:

> In Python 3, `ConfigParser` has been renamed to `configparser` for PEP 8 compliance. It looks like the package you are installing does not support Python 3.

He comprobado la versión de Python y ¡boom! Python 3:

```bash
$ python --version
Python 3.5.3
```

# Solución

Si el problema es que el paquete no es compatible con Python 3, ¿habría alguna manera de ejecutarlo con Python 2?

Por otras instalaciones de Debian que he realizado sabía que en el sistema están instaladas tanto la versión 2 como la 3.

Vamos a comprobarlo:

```bash
$ ls -l /usr/bin/python*
lrwxrwxrwx 1 root root      16 May 19 18:08 /usr/bin/python -> /usr/bin/python3
lrwxrwxrwx 1 root root       9 Jan 24  2017 /usr/bin/python2 -> python2.7
-rwxr-xr-x 1 root root 3779512 Sep 26  2018 /usr/bin/python2.7
lrwxrwxrwx 1 root root       9 Jan 20  2017 /usr/bin/python3 -> python3.5
-rwxr-xr-x 2 root root 4751184 Sep 27  2018 /usr/bin/python3.5
-rwxr-xr-x 2 root root 4751184 Sep 27  2018 /usr/bin/python3.5m
lrwxrwxrwx 1 root root      10 Jan 20  2017 /usr/bin/python3m -> python3.5m
```

De hecho, cuando lanzas el comando `python`, en realidad se encuentra el enlace simbólico que desde `/usr/bin/python` apunta a `/usr/bin/python3` (que a su ver apunta a `/usr/bin/python3.5`).

## Cambiando la versión de Python usada en el sistema

Para "volver" a Python 2 lo único que tengo que hacer es deshacer el enlace que apunta de `/usr/bin/python` a Python 3.5 y hacer que apunte a Python 2.7:

```bash
$ sudo unlink /usr/bin/python
$ sudo ln -s /usr/bin/python2.7 /usr/bin/python
```

Después de validar que `python` apunta a la versión 2.7, lanzo de nuevo el comando `sudo apt upgrade -y` y **¡esta vez todo funciona correctamente!**.

Tras realizar la actualización, de eliminado el enlace a la versión 2.7 y he vuelto a crear el enlace para la versión 3.5.