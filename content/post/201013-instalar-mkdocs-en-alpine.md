+++
draft = false
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "alpine", "python", "mkdocs"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/bug.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" %}}

title=  "[Solucionado] Instalación de MkDocs en Alpine y en MacOS (Catalina)"
date = "2020-10-13T18:43:49+02:00"
+++
Estos días he encontrado un extraño error a la hora de instalar [MkDocs](https://www.mkdocs.org/), pero por lo que parece, no es un problema específico ni de MkDocs ni de Alpine...
<!--more-->

## TL;DR;

Al final del artículo resumo los paquetes y módulos a instalar como requerimientos para la instalación de MkDocs en Alpine Linux y Mac OS Catalina.

## Error en la instalación

Al intentar instalar MkDocs, aparece un mensaje de error indicando:

```bash
...
Running setup.py install for regex ... error
    ERROR: Command errored out with exit status 1:
     command: /usr/bin/python3 -u -c 'import sys, setuptools, tokenize; sys.argv[0] = '"'"'/tmp/pip-install-9nfj6k97/regex/setup.py'"'"'; __file__='"'"'/tmp/pip-install-9nfj6k97/regex/setup.py'"'"';f=getattr(tokenize, '"'"'open'"'"', open)(__file__);code=f.read().replace('"'"'\r\n'"'"', '"'"'\n'"'"');f.close();exec(compile(code, __file__, '"'"'exec'"'"'))' install --record /tmp/pip-record-_5wq4jam/install-record.txt --single-version-externally-managed --compile --install-headers /usr/include/python3.8/regex
         cwd: /tmp/pip-install-9nfj6k97/regex/
```

Al parecer, la instalación del paquete `regex` requiere compilar algo y a partir de aquí empiezan los problemas.

He creado una máquina virtual con Alpine 3.12 y he realizado pruebas hasta solucionar el problema; ahora, he creado una nueva VM para documentar cuál de todas las cosas que he probado es la solución que hay que aplicar.

Realizo una instalación de Alpine 3.12 con la mayor parte de los valores por defecto, *despincho* la ISO y reinicio.

Cambio la conectividad de red de la VM a *Bridged* y habilito la conexión vía SSH del usuario `root` (para poder copiar y pegar en la terminal).

```bash
# cat /etc/os-release
NAME="Alpine Linux"
ID=alpine
VERSION_ID=3.12.0
PRETTY_NAME="Alpine Linux v3.12"
HOME_URL="https://alpinelinux.org/"
BUG_REPORT_URL="https://bugs.alpinelinux.org/"
```

Comprobamos que en la instalación por defecto no tenemos ninguna versión de Python:

```bash
vm01:~# which python
vm01:~# python --version
-ash: python: not found
vm01:~# python3 --version
-ash: python3: not found
```

Instalamos Python 3:

```bash
# apk add python3
(1/7) Installing libbz2 (1.0.8-r1)
(2/7) Installing expat (2.2.9-r1)
(3/7) Installing libffi (3.3-r2)
(4/7) Installing gdbm (1.13-r1)
(5/7) Installing readline (8.0.4-r0)
(6/7) Installing sqlite-libs (3.32.1-r0)
(7/7) Installing python3 (3.8.5-r0)
Executing busybox-1.31.1-r19.trigger
OK: 863 MiB in 145 packages
```

Instalamos `pip`:

```bash
vm01:~# apk add py3-pip
ERROR: unsatisfiable constraints:
  py3-pip (missing):
    required by: world[py3-pip]
```

Como podemos comprobar en [py3-pip](https://pkgs.alpinelinux.org/package/edge/community/x86/py3-pip), el paquete se encuentra en el repositorio `world`.

Lo habilitamos eliminando `#` de la línea `http://dl-cdn.alpinelinux.org/alpine/edge/community` en el fichero:

```bash
vm01:~# vi /etc/apk/repositories
```

Actualizamos e instalamos `py3-pip`:

```bash
# apk update
fetch http://dl-cdn.alpinelinux.org/alpine/v3.12/main/x86_64/APKINDEX.tar.gz
fetch http://dl-cdn.alpinelinux.org/alpine/edge/community/x86_64/APKINDEX.tar.gz
v3.12.0-401-g86b6908751 [http://dl-cdn.alpinelinux.org/alpine/v3.12/main]
v20200917-2188-g82e8db59ac [http://dl-cdn.alpinelinux.org/alpine/edge/community]
OK: 13242 distinct packages available
vm01:~# apk add py3-pip
(1/26) Installing py3-appdirs (1.4.4-r1)
(2/26) Installing py3-ordered-set (4.0.1-r0)
...
```

Con esto debería ser suficiente; revisamos el estado actual:

```bash
vm01:~# python3 --version
Python 3.8.5
vm01:~# pip --version
pip 20.1.1 from /usr/lib/python3.8/site-packages/pip (python 3.8)
```

## Instalando `mkdocs`

```bash
vm01:~# pip install mkdocs
Collecting mkdocs
  Downloading mkdocs-1.1.2-py3-none-any.whl (6.4 MB)
     |████████████████████████████████| 6.4 MB 5.8 MB/s
Collecting Jinja2>=2.10.1
  Downloading Jinja2-2.11.2-py2.py3-none-any.whl (125 kB)
     |████████████████████████████████| 125 kB 6.2 MB/s
Collecting Markdown>=3.2.1
  Downloading Markdown-3.3.1-py3-none-any.whl (95 kB)
     |████████████████████████████████| 95 kB 3.1 MB/s
Collecting click>=3.3
  Downloading click-7.1.2-py2.py3-none-any.whl (82 kB)
     |████████████████████████████████| 82 kB 747 kB/s
Collecting livereload>=2.5.1
  Downloading livereload-2.6.3.tar.gz (25 kB)
Collecting lunr[languages]==0.5.8
  Downloading lunr-0.5.8-py2.py3-none-any.whl (2.3 MB)
     |████████████████████████████████| 2.3 MB 5.6 MB/s
Collecting tornado>=5.0
  Downloading tornado-6.0.4.tar.gz (496 kB)
     |████████████████████████████████| 496 kB 4.2 MB/s
Collecting PyYAML>=3.10
  Downloading PyYAML-5.3.1.tar.gz (269 kB)
     |████████████████████████████████| 269 kB 4.8 MB/s
Collecting MarkupSafe>=0.23
  Downloading MarkupSafe-1.1.1.tar.gz (19 kB)
Requirement already satisfied: six in /usr/lib/python3.8/site-packages (from livereload>=2.5.1->mkdocs) (1.15.0)
Collecting future>=0.16.0
  Downloading future-0.18.2.tar.gz (829 kB)
     |████████████████████████████████| 829 kB 5.8 MB/s
Collecting nltk>=3.2.5; python_version > "2.7" and extra == "languages"
  Downloading nltk-3.5.zip (1.4 MB)
     |████████████████████████████████| 1.4 MB 4.7 MB/s
Collecting joblib
  Downloading joblib-0.17.0-py3-none-any.whl (301 kB)
     |████████████████████████████████| 301 kB 5.8 MB/s
Collecting regex
  Downloading regex-2020.10.11.tar.gz (690 kB)
     |████████████████████████████████| 690 kB 4.9 MB/s
Collecting tqdm
  Downloading tqdm-4.50.2-py2.py3-none-any.whl (70 kB)
     |████████████████████████████████| 70 kB 4.1 MB/s
Using legacy setup.py install for livereload, since package 'wheel' is not installed.
Using legacy setup.py install for tornado, since package 'wheel' is not installed.
Using legacy setup.py install for PyYAML, since package 'wheel' is not installed.
Using legacy setup.py install for MarkupSafe, since package 'wheel' is not installed.
Using legacy setup.py install for future, since package 'wheel' is not installed.
Using legacy setup.py install for nltk, since package 'wheel' is not installed.
Using legacy setup.py install for regex, since package 'wheel' is not installed.
Installing collected packages: MarkupSafe, Jinja2, Markdown, click, tornado, livereload, future, joblib, regex, tqdm, nltk, lunr, PyYAML, mkdocs
    Running setup.py install for MarkupSafe ... done
    Running setup.py install for tornado ... done
    Running setup.py install for livereload ... done
    Running setup.py install for future ... done
    Running setup.py install for regex ... error
    ERROR: Command errored out with exit status 1:
     command: /usr/bin/python3 -u -c 'import sys, setuptools, tokenize; sys.argv[0] = '"'"'/tmp/pip-install-nqaj9jv0/regex/setup.py'"'"'; __file__='"'"'/tmp/pip-install-nqaj9jv0/regex/setup.py'"'"';f=getattr(tokenize, '"'"'open'"'"', open)(__file__);code=f.read().replace('"'"'\r\n'"'"', '"'"'\n'"'"');f.close();exec(compile(code, __file__, '"'"'exec'"'"'))' install --record /tmp/pip-record-atsw5nld/install-record.txt --single-version-externally-managed --compile --install-headers /usr/include/python3.8/regex
         cwd: /tmp/pip-install-nqaj9jv0/regex/
    Complete output (17 lines):
    running install
    running build
    running build_py
    creating build
    creating build/lib.linux-x86_64-3.8
    creating build/lib.linux-x86_64-3.8/regex
    copying regex_3/__init__.py -> build/lib.linux-x86_64-3.8/regex
    copying regex_3/regex.py -> build/lib.linux-x86_64-3.8/regex
    copying regex_3/_regex_core.py -> build/lib.linux-x86_64-3.8/regex
    copying regex_3/test_regex.py -> build/lib.linux-x86_64-3.8/regex
    running build_ext
    building 'regex._regex' extension
    creating build/temp.linux-x86_64-3.8
    creating build/temp.linux-x86_64-3.8/regex_3
    gcc -Wno-unused-result -Wsign-compare -DNDEBUG -g -fwrapv -O3 -Wall -fomit-frame-pointer -g -fno-semantic-interposition -fomit-frame-pointer -g -fno-semantic-interposition -fomit-frame-pointer -g -fno-semantic-interposition -DTHREAD_STACK_SIZE=0x100000 -fPIC -I/usr/include/python3.8 -c regex_3/_regex.c -o build/temp.linux-x86_64-3.8/regex_3/_regex.o
    unable to execute 'gcc': No such file or directory
    error: command 'gcc' failed with exit status 1
    ----------------------------------------
ERROR: Command errored out with exit status 1: /usr/bin/python3 -u -c 'import sys, setuptools, tokenize; sys.argv[0] = '"'"'/tmp/pip-install-nqaj9jv0/regex/setup.py'"'"'; __file__='"'"'/tmp/pip-install-nqaj9jv0/regex/setup.py'"'"';f=getattr(tokenize, '"'"'open'"'"', open)(__file__);code=f.read().replace('"'"'\r\n'"'"', '"'"'\n'"'"');f.close();exec(compile(code, __file__, '"'"'exec'"'"'))' install --record /tmp/pip-record-atsw5nld/install-record.txt --single-version-externally-managed --compile --install-headers /usr/include/python3.8/regex Check the logs for full command output.
```

Revisando donde se produce el error vemos:

```bash
Running setup.py install for regex ... error
    ERROR: Command errored out with exit status 1:
     command: /usr/bin/python3 -u -c 'import sys, setuptools, tokenize; sys.argv[0] = '"'"'/tmp/pip-install-nqaj9jv0/regex/setup.py'"'"'; __file__='"'"'/tmp/pip-install-nqaj9jv0/regex/setup.py'"'"';f=getattr(tokenize, '"'"'open'"'"', open)(__file__);code=f.read().replace('"'"'\r\n'"'"', '"'"'\n'"'"');f.close();exec(compile(code, __file__, '"'"'exec'"'"'))' install --record /tmp/pip-record-atsw5nld/install-record.txt --single-version-externally-managed --compile --install-headers /usr/include/python3.8/regex
         cwd: /tmp/pip-install-nqaj9jv0/regex/
```

### Instalando todo lo necesario

Como vemos en el mensaje de error, parece que falta el paquete `setuptools`.

Lo instalamos mediante:

```bash
vm01:~# pip install --upgrade setuptools
Collecting setuptools
  Downloading setuptools-50.3.0-py3-none-any.whl (785 kB)
     |████████████████████████████████| 785 kB 2.5 MB/s
Installing collected packages: setuptools
  Attempting uninstall: setuptools
    Found existing installation: setuptools 47.0.0
    Uninstalling setuptools-47.0.0:
      Successfully uninstalled setuptools-47.0.0
Successfully installed setuptools-50.3.0
```

Reintentamos la instalación de `mkdocs`, pero vuelve a fallar...

Revisando unas líneas por encima del error en sí mismo, vemos que hay una serie de avisos de que `wheel` no está instalado:

```bash
...
Using legacy setup.py install for PyYAML, since package 'wheel' is not installed.
Using legacy setup.py install for nltk, since package 'wheel' is not installed.
Using legacy setup.py install for regex, since package 'wheel' is not installed.
...
```

Instalamos el módulo `wheel`:

```bash
# pip install wheel
Collecting wheel
  Downloading wheel-0.35.1-py2.py3-none-any.whl (33 kB)
Installing collected packages: wheel
Successfully installed wheel-0.35.1
```

De nuevo falla... Nos fijamos ahora en que el problema está en que no encuentra `gcc`:

```bash
...
unable to execute 'gcc': No such file or directory
  error: command 'gcc' failed with exit status 1
  ----------------------------------------
  ERROR: Failed building wheel for regex
...
```

Instalamos `gcc`:

```bash
apk add gcc
```

Vuelve a fallar, pero el error es diferente; vemos que no encuentra `Python.h`:

```bash
...
 regex_3/_regex.c:48:10: fatal error: Python.h: No such file or directory
       48 | #include "Python.h"
          |          ^~~~~~~~~~
    compilation terminated.
...
```

La solución la encontramos en StackOverflow: [fatal error: Python.h: No such file or directory](https://stackoverflow.com/questions/21530577/fatal-error-python-h-no-such-file-or-directory); tenemos que instalar `python3-dev`.

```bash
vm01:~# apk add python3-dev
(1/4) Upgrading gdbm (1.13-r1 -> 1.18.1-r0)
(2/4) Upgrading python3 (3.8.5-r0 -> 3.8.6-r0)
(3/4) Installing pkgconf (1.7.3-r0)
(4/4) Installing python3-dev (3.8.6-r0)
Executing busybox-1.31.1-r19.trigger
OK: 1027 MiB in 184 packages
```

Intentamos instalar de nuevo y obtenemos un error similar al anterior:

```bash
...
In file included from regex_3/_regex.c:48:
    /usr/include/python3.8/Python.h:11:10: fatal error: limits.h: No such file or directory
       11 | #include <limits.h>
          |          ^~~~~~~~~~
    compilation terminated.
    error: command 'gcc' failed with exit status 1
```

De nuevo, la respuesta proviene de StackOverflow: [No such file or directory “limits.h” when installing Pillow on Alpine Linux](https://stackoverflow.com/questions/30624829/no-such-file-or-directory-limits-h-when-installing-pillow-on-alpine-linux); este error parece específico de Alpine, al usar [musl-libc](https://www.musl-libc.org/). La solución pasa por instalar `musl-dev`:

```bash
vm01:~# apk add musl-dev
(1/2) Upgrading musl (1.1.24-r9 -> 1.2.1-r2)
(2/2) Installing musl-dev (1.2.1-r2)
OK: 1037 MiB in 185 packages
```

Esta vez, cuando lanzamos la instalación de `mkdocs` el proceso de compilación se lanza: 

```bash
...
Collecting regex
  Using cached regex-2020.10.11.tar.gz (690 kB)
Collecting tqdm
  Using cached tqdm-4.50.2-py2.py3-none-any.whl (70 kB)
Building wheels for collected packages: regex
  Building wheel for regex (setup.py) ... \
```

... tras unos minutos la compilación finaliza con éxito:

```bash
...
  Created wheel for regex: filename=regex-2020.10.11-cp38-cp38-linux_x86_64.whl size=755925 sha256=31dcdcf2b21b001a04a12ac3808a3d36b91bd73884a7e501a3483d7ff84a316c
  Stored in directory: /root/.cache/pip/wheels/c1/71/60/434b56771bf84ab28e88f95ec6e772e3ff42212bb5fb24985f
Successfully built regex
Installing collected packages: regex, tqdm, nltk, lunr, mkdocs
Successfully installed lunr-0.5.8 mkdocs-1.1.2 nltk-3.5 regex-2020.10.11 tqdm-4.50.2
vm01:~#
```

Validamos la versión instalada:

```bash
vm01:~# mkdocs --version
mkdocs, version 1.1.2 from /usr/lib/python3.8/site-packages/mkdocs (Python 3.8)
```

## Instalación de `mkdocs-material`

La instalación de `mkdocs-material` (o de sus dependencias) ya no presenta ningún problema y se instala sin novedad:

```bash
# pip install mkdocs-material
Collecting mkdocs-material
  Downloading mkdocs_material-6.0.2-py2.py3-none-any.whl (3.9 MB)
     |████████████████████████████████| 3.9 MB 2.4 MB/s
Collecting Pygments>=2.4
...
Installing collected packages: Pygments, mkdocs-material-extensions, pymdown-extensions, mkdocs-material
Successfully installed Pygments-2.7.1 mkdocs-material-6.0.2 mkdocs-material-extensions-1.0.1 pymdown-extensions-8.0.1
```

## TL;DR

Después del proceso de *troubleshooting*, creo una nueva máquina con Alpine Linux 3.12 para validar la instalación:

### Instalación de paquetes de Alpine

Primero, habilitamos el repositorio `http://dl-cdn.alpinelinux.org/alpine/edge/community` en el fichero `/etc/apk/repositories`.

```bash
apk update
apk add python3 py3-pip gcc python3-dev musl-dev
```

### Instalación de módulos de Python

```python
pip install setuptools wheel mkdocs mkdocs-material
```

Finalmente, podemos validar que se ha instalado correctamente mediante:

```bash
mkdocs --version
```

## Mismo error en MacOS 10.15.7 (Catalina)

Al intentar instalar/actualizar MkDocs en el Mac, obtengo el mismo error relacionado con `regex`:

```bash
$ pip3 install --upgrade mkdocs
...
Building wheels for collected packages: regex
  Building wheel for regex (setup.py) ... error
  ERROR: Command errored out with exit status 1:
   command: /Library/Frameworks/Python.framework/Versions/3.7/bin/python3 -u -c 'import sys, setuptools, tokenize; sys.argv[0] = '"'"'/private/var/folders/q5/ph3nkkqn2t723nj5m_x0_rvr0000gn/T/pip-install-tovs356k/regex/setup.py'"'"'; __file__='"'"'/private/var/folders/q5/ph3nkkqn2t723nj5m_x0_rvr0000gn/T/pip-install-tovs356k/regex/setup.py'"'"';f=getattr(tokenize, '"'"'open'"'"', open)(__file__);code=f.read().replace('"'"'\r\n'"'"', '"'"'\n'"'"');f.close();exec(compile(code, __file__, '"'"'exec'"'"'))' bdist_wheel -d /private/var/folders/q5/ph3nkkqn2t723nj5m_x0_rvr0000gn/T/pip-wheel-5k1bg8x2
       cwd: /private/var/folders/q5/ph3nkkqn2t723nj5m_x0_rvr0000gn/T/pip-install-tovs356k/regex/
```

Los módulos de Python ya están instalados:

```bash
$ pip install --upgrade setuptools wheel
Requirement already up-to-date: setuptools in /Library/Frameworks/Python.framework/Versions/3.7/lib/python3.7/site-packages (50.3.0)
Requirement already up-to-date: wheel in /Library/Frameworks/Python.framework/Versions/3.7/lib/python3.7/site-packages (0.35.1)
```

La instalación de `setuptools` para Python 3 en Mac OS la he obtenido de StackOverflow [how to install setuptools in mac](https://stackoverflow.com/questions/26032836/how-to-install-setuptools-in-mac#comment47574833_26034737):

```bash
curl https://bootstrap.pypa.io/ez_setup.py -o - | python3
```

De nuevo vemos que el error viene de intentar compilar `wheel`, ya que no encuentra `gcc`.

Las propuestas de instalar XCode usando `xcode-select --install` fallan con el mensaje de error: `Can't install the software because it is not currently available from the Software Update server."

Al parecer, el método de instalación vía `xcode-select` ya no es válido (ver [Problem installing Command Line Tools for Mojave](https://developer.apple.com/forums/thread/110552)) y hay que acceder a [More Downloads for Apple Developers](https://developer.apple.com/download/more/)` para descargar las herramientas de línea de comando (unos 450MB), que una vez instalados en disco ocupan 2.40GB!!

Tras la instalación de las *Command Line tools for XCode 12.1 GM*, finalmente se instala `mkdocs`, aunque con algunos *warnings*:

```bash
...
Installing collected packages: regex, nltk, lunr, mkdocs
  Attempting uninstall: mkdocs
    Found existing installation: mkdocs 1.0.4
    Uninstalling mkdocs-1.0.4:
      Successfully uninstalled mkdocs-1.0.4
ERROR: After October 2020 you may experience errors when installing or updating packages. This is because pip will change the way that it resolves dependency conflicts.

We recommend you use --use-feature=2020-resolver to test your packages with the new resolver before it becomes the default.

mkdocs-material 4.6.0 requires markdown<3.2, but you'll have markdown 3.3 which is incompatible.
mkdocs-material 4.6.0 requires pymdown-extensions<6.3,>=6.2, but you'll have pymdown-extensions 8.0.1 which is incompatible.
mkdocs-material-extensions 1.0.1 requires mkdocs-material>=5.0.0, but you'll have mkdocs-material 4.6.0 which is incompatible.
Successfully installed lunr-0.5.8 mkdocs-1.1.2 nltk-3.5 regex-2020.10.11
```

Los avisos desaparecen una vez que actualizamos las dependencias:

```bash
pip install --upgrade markdown pymdown-extensions mkdocs-material
```

Finalmente, también en Mac:

```bash
> mkdocs --version
mkdocs, version 1.1.2 from /Library/Frameworks/Python.framework/Versions/3.7/lib/python3.7/site-packages/mkdocs (Python 3.7)
```