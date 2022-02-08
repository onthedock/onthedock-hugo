+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["git"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/git.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/

# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}
# YouTube           {{< youtube w7Ft2ymGmfc >}}
# Gist              {{< gist username 7896402 >}}
# Highlight         {{< highligth language >}}...{{< /highlight >}}
# Twitter           {{< tweet user="SanDiegoZoo" id="1453110110599868418" >}}

title=  "Git desde Cero"
date = "2022-02-08T20:00:48+01:00"
+++
Un grupo de compañeros van a cambiar las tareas que realizan como parte de su trabajo; parte de esa transformación consiste en familiarizarse con el uso de  [Git](https://git-scm.com/).

He decidido *darle una vuelta* a cómo les introduciría en el uso de Git de manera sencilla y que *tenga sentido*.
<!--more-->

Así que he pensado en hacerlo desde el principio, paso a paso...

## Inicializar el repositorio - `git init`

Un *repositorio* es un conjunto de carpetas y ficheros para los que Git gestiona las versiones de los ficheros.

Para convertir una carpeta en un repositorio de Git, ejecutamos `git init <ruta-al-repositorio>`.

Este es el contenido de una carpeta antes de ejecutar el comando:

```bash
$ ls -la
total 0
drwxr-xr-x  2 xavi  wheel   64 Feb  8 20:12 .
drwxrwxrwt  5 root  wheel  160 Feb  8 20:12 ..
```

Ejecutamos `git init .` (`.` indica "la carpeta actual"):

```bash
$ git init .
Initialized empty Git repository in /private/tmp/myfiles/.git/
```

Si inspeccionamos el contenido de la carpeta:

```bash
$ ls -la
total 0
drwxr-xr-x   3 xavi  wheel   96 Feb  8 20:16 .
drwxrwxrwt   5 root  wheel  160 Feb  8 20:12 ..
drwxr-xr-x  10 xavi  wheel  320 Feb  8 20:16 .git
```

Como vemos, la diferencia es una subcarpeta `.git`. Toda la configuración del repositorio y, en parte, de Git, se encuentra en esa subcarpeta. Git almacena en esa carpeta la historia de todos los cambios que se *guardan* en el repositorio.

Como hemos creado el repositorio en una carpeta vacía, el repositorio está vacío, como muestra la salida del comando `git init`.

## Inspeccionando el repositorio - `git status`

Para revisar el estado de los ficheros en el repositorio, usamos el comando `git status`.

```bash
$ git status
On branch master

No commits yet

nothing to commit (create/copy files and use "git add" to track)
```

La salida del comando `git status` nos dice que estamos en la *rama* `master`, que no hay "commits" y que no hay nada que "guardar".

Una *rama* contiene el conjunto de los cambios que se han realizado en el repositorio hasta alcanzar el estado actual.

> La rama por defecto históricamente se denominaba `master`, aunque por motivos de *corrección política* (para evitar referencias a la esclavitud) se tiende a usar un término más neutral, como `main`.

Lo siguiente de lo que nos informa Git es que todavía no hay *commits*. Un *commit* es un estado guardado del repositorio. A diferencia de otros sistemas de control de versiones, **Git guarda el estado completo del repositorio** en cada cambio, no el estado de ficheros individuales.

La última línea de Git también nos informa de que no hay nada que guardar (*commit*) y nos da una pista sobre cuál puede ser nuestro siguiente paso: crear o copiar ficheros y usar `git add` para que Git sepa que debe gestionar sus versiones.

> Hasta ahora he usado las versiones lo más correctas que se me ocurren para traducir los términos relacionados con Git. Sin embargo, es mucho más sencillo usar la versión *castellanizada* de las acciones y conceptos relacionados con Git. Usaré términos como *commitear*, *trackear*, etc. Así que a partir de ahora, que la RAE me perdone...

## Añadir ficheros - `git add`

Git es un sistema de control de versiones; se suele usar para gestionar cosas como el código de aplicaciones, pero en realidad se puede usar para versionar cualquier tipo de fichero. Para ser efectivo en el control de cambios, Git tiene que poder analizar los cambios introducidos, por lo que *brilla* con ficheros en texto plano.

En este tutorial vamos a usar un fichero de texto con la lista de la compra (nada que ver con [Programando en Go: Aplicación de Lista de la compra]({{< ref "220130-programando-una-aplicacion-de-lista-de-la-compra.md" >}}) ;) ).

Creamos un fichero y añadimos algunas cosas que comprar usando un editor de texto cualquiera:

```bash
$ touch lista.txt
$ cat lista.txt
* leche
* galletas
```

Ejecutamos `git status` de nuevo:

```bash
$ git status
On branch master

No commits yet

Untracked files:
  (use "git add <file>..." to include in what will be committed)

  lista.txt

nothing added to commit but untracked files present (use "git add" to track)
```

La salida del comando se parece a la ejecución anterior, solo que Git nos informa que hay ficheros presentes a los que no les está siguiendo la pista.

Si introducimos más elementos en el fichero y ejecutamos `git status` de nuevo, obtenemos la misma información de Git, que hay ficheros *untracked*, que podemos añadirlos, etc...

```bash
$ cat lista.txt
* leche
* galletas
* azúcar

$ git status
On branch master

No commits yet

Untracked files:
  (use "git add <file>..." to include in what will be committed)

  lista.txt

nothing added to commit but untracked files present (use "git add" to track)
```

¿Cómo es que Git no nos muestra los cambios que hemos realizado en el fichero?

Git sólo registra los cambios que se producen en los ficheros que le indicamos; para que Git siga los cambios en un fichero, usamos `git add <nombre-del-fichero>`.

```bash
$ git add lista.txt
$ git status
On branch master

No commits yet

Changes to be committed:
  (use "git rm --cached <file>..." to unstage)

  new file:   lista.txt
```

Git nos indica que se ha añadido un nuevo fichero `lista.txt`; en realidad quiere decir que desde el estado anterior guardado en el repositorio (vacío), ha habido un cambio, la *aparición* del fichero `lista.txt`. Este cambio todavía no se ha registrado (*commit*) en la historia del repositorio.

En Git, el repositorio está dividido en tres "zonas virtuales" en función del estado de sus ficheros. Realizamos cambios sobre los ficheros en el *working directory*. Como hemos visto, podemos realizar modificaciones en los ficheros como sea necesario sin tener que registrarlos en la historia del repositorio. Dicho de otra manera, sólo debemos guardar los cambios realizados cuando tenemos una nueva *versión*: se introduce una nueva funcionalidad en la aplicación, se corrige un fallo, etc.

En nuestro ejemplo, no guardaremos el estado de la lista de la compra hasta completar un determinado objetivo, por ejemplo, listar todos los elementos necesarios para preprarar un desayuno.

Cuando ejecutamos `git add`, guardamos una *copia virtual* del estado del fichero en ese momento. Esta copia virtual se almacena en la zona de *staging*.

Podemos seguir añadiendo modificaciones en el fichero y ver qué muestra el comando `git status`:

```bash
git status
On branch master

No commits yet

Changes to be committed:
  (use "git rm --cached <file>..." to unstage)

  new file:   lista.txt

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git checkout -- <file>..." to discard changes in working directory)

  modified:   lista.txt
```

Desde el momento que añadimos un fichero a Git (mediante `git add`), Git puede evaluar los cambios que se han realizado entre el estado en el que se *añadió* a la zona de *staging* y el estado en el que se encuentra en el *working directory*.

En nuestro caso, añadimos el fichero a la zona de *staging* con tres elementos en la lista de la compra; éso es lo que está guardado en la zona de *staging*. Tras ejecutar `git add`, hemos modificado el fichero, por lo que la copia en el *working directory* y el estado guardado en *staging* son diferentes.

Para revisar las diferencias entre un fichero en la zona de *staging* y en el *working directory*, ejecutamos `gif diff <nombre-fichero>`:

```bash
$ git diff lista.txt
diff --git a/lista.txt b/lista.txt
index f67d531..7f0b75c 100644
--- a/lista.txt
+++ b/lista.txt
@@ -1,3 +1,4 @@
 * leche
 * galletas
 * azúcar
+* café
```

La salida de `git diff` usa el formato unificado de *diff* ([diff](https://en.wikipedia.org/wiki/Diff#Unified_format) en la Wikipedia): la diferencia entre el estado del fichero en la zona de *staging* y en el *working directory* se señala mediante el símbolo `+` para las líneas en las que se ha añadido contenido y un `-` para aquellas en las que se ha eliminado.

Si realizamos más cambios en el fichero `lista.txt`, vemos el comando `git diff` nos muestra de nuevo las diferencias con respecto al estado guardado en *staging*; hemos cambiado el "azúcar" (la línea está precedidad por `-`) por "sacarina" (precedida por `+`) y una línea en blanco al final del fichero:

```bash
 git diff lista.txt
diff --git a/lista.txt b/lista.txt
index f67d531..d0f7e50 100644
--- a/lista.txt
+++ b/lista.txt
@@ -1,3 +1,5 @@
 * leche
 * galletas
-* azúcar
+* sacarina
+* café
+
```

Para actualizar la *copia* en *staging* con la copia en el *working directory* del fichero, usamos de nuevo `git add lista.txt`:

```bash
$ git add lista.txt
$ git status
On branch master

No commits yet

Changes to be committed:
  (use "git rm --cached <file>..." to unstage)

  new file:   lista.txt
```

En la salida del comando `git status` se nos informa que los cambios que se encuentran en la zona de *staging* listos para ser añadidos a la historia del repositorio es la creación de un nuevo fichero. La "copia" del fichero `lista.txt` en el *working directory* y la del *working directory* son iguales (acabamos de añadir los cambios del *working directory* a *staging* mediante `git add`). La copia en *staging* difiere de la "copia" guardada en la historia del repositorio (el fichero no existe en la historia del repositorio), por lo que para Git es un nuevo fichero.

Para guardar los ficheros (en el estado en el que se añadieron a la zona de *staging*) de forma permanente en la historia del repositorio, usamos `git commit`.

> Antes de que Git pueda registrar los cambios en la historia del repositorio, debe saber quiénes somos. Para ello, es necesario proporcionar un nombre y una dirección de correo.
>
> Especifica el nombre mediante `git config user.name "Xavi Aznar"`; para la dirección de correo, `git config user.email "xavi.aznar@example.com"`.

Es necesario aportar una descripción de los cambios introducidos, por lo que si no facilitamos un *mensaje de commit* (con la opción `-m "<mensaje de commit>"`), Git abre el editor por defecto para que lo introduzcamos.

```bash
git commit -m "Alimentos para el desayuno"
[master (root-commit) 202ecfe] Alimentos para el desayuno
 1 file changed, 5 insertions(+)
 create mode 100644 lista.txt
```

Tras guardar los cambios en la historia del repositorio, la salida de `git status` es:

```bash
$ git status
On branch master
nothing to commit, working tree clean
```

Para consultar la historia del repositorio, usa el comando `git log`:

```bash
$ git log
commit 202ecfe0a0bc2ac1cc2b4d34d283cacbe2a024b2 (HEAD -> master)
Author: Xavi <xavi.aznar@example.com>
Date:   Tue Feb 8 22:41:33 2022 +0100

    Alimentos para el desayuno
```

## Resumen

Git es un sistema de control de versiones. Inicializamos el repositorio mediante `git init`.

Los ficheros del repositorio se organizan en tres zonas *virtuales*: el *working directory*, donde hacemos cambios a los ficheros. Consultamos el estado del *working directory* mediante `git status`.

La zona de *staging* es donde guardamos los ficheros (mediante `git add`) en el estado en el que queremos añadirlos a la historia del repositorio.

Para guardar los cambios de forma permanente en la historia del repositorio, usamos `git commit`, proporcionando el mensaje que describe los cambios. Además del mensaje, Git registra información sobre la autoría del cambio (nombre y dirección de correo).

Para consultar la historia del repositorio, usamos el comando `git log`.

```txt
working copy --(git add)-> staging --(git commit)-> history
```

Estos son los comandos que se usan el 80% del tiempo en Git.
