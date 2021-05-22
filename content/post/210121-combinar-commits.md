+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["git"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/git.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}

title=  "Cómo combinar commits en Git (squash)"
date = "2021-01-31T09:33:38+01:00"
+++
Las buenas prácticas (por ejemplo [Version Control Best Practices](https://www.git-tower.com/learn/git/ebook/en/command-line/appendix/best-practices/)) relacionadas con el control de versiones usando Git indican que hay que guardar (*commit*) los cambios de forma frecuente, conteniendo únicamente pequeños cambios.

Sin embargo, el desarrollo no se produce de una forma lineal, de principio a fin; a veces, lo que parece una buena idea que funciona al principio, más adelante es necesario cambiarla o modificarla...

Si guardamos todos los *commits*, la historia del repositorio quedará llena de estos cambios de dirección durante el desarrollo. Por este motivo, una de las opciones que tenemos es la de reescribir la historia del repositorio antes de, por ejemplo, hacer *merge* de la rama de *feaure* sobre la rama principal.

En este artículo vemos cómo conseguirlo usando `git rebase`.
<!--more-->

> El artículo que mejor lo explica, de los que he consultado, por su claridad y orden a la hora de exponer los pasos a realizar es [Squash commits into one with Git](https://www.internalpointers.com/post/squash-commits-into-one-git), actualizado en 21/12/2020.

## `git rebase` reescribe la historia del repositorio

Lo principal que debes tener en cuenta a la hora de usar `git rebase` es que se modifica la historia del repositorio. Por este motivo sólo deberías usarlo, en general, en cambios que todavía no hayas compartido con otros.

## Cómo comprimir (*squash*) *commits* en Git

El comando que nos permite combinar *commits* es `git rebase --interactive ${id-del-commit}` (o `git rebase -i ${id-del-commit}`, en su forma corta).

El `${id-del-commit}` especifica **a partir de** qué *commit* queremos reescribir la historia.

Podemos especificar el SHA del *commit* o una referencia relativa (como `HEAD~3`).

Suponiendo que la historia de nuestro repositorio es:

```bash
# Esta es la historia que refleja qué ha pasado durante el desarrollo
$ git log --oneline
ba06e7a (HEAD -> feature-1) Ok, funcionalidad Y completa!
150c964 Limpieza de código
28506fa Corrige warnings
529b7bc Corrige ésto y aquello (no podía funcionar a la primera ;) ) 
da2045b Implementación
b185d06 Prerequisitos para la funcionalidad Y
429c084 (master) Funcionalidad X (issue #111111) Documenta cómo funciona git rebase -i para comprimir commits
5488b91 Primer commit
```

Vemos que a partir del *commit* `429c084` se creó la rama `feature-1`, pero contiene *commits* con mensajes *mejorables* o que no aportan demasiado.

Tras el proceso de `rebase` nos gustaría tener una historia como:

```bash
# Esta es la historia que nos gustaría tener tras el rebase
$ git log --oneline
XXXXXXX (HEAD -> feature-1) Funcionalidad Y (issue #123456)
429c084 (master) Funcionalidad X (issue #111111)
5488b91 Primer commit
```

Si queremos reescribir la historia a partir del *commit* `429c084` lanzamos:

```bash
git rebase -i 429c084
```

Git abre el editor predefinido con la lista de *commits* involucrados en el *rebase* (todos los posteriores al *commit* indicado).

> El editor que abre `git rebase` muestra los *commits* en orden inverso al del comando `git log`; `git rebase` muestra primero los *commits* más antiguos y después los más nuevos.

Por defecto, el identificador de cada *commit* va precedido de la acción a realizar (por defecto, `pick`); también se muestra el mensaje de *commit* para que sea más sencillo saber qué *commit* se está modificando.

Tras la lista de *commits* Git muestra ayuda con las opciones disponibles durante el proceso de `rebase`.

```bash
pick b185d06 Prerequisitos para la funcionalidad Y
pick da2045b Implementación
pick 529b7bc Corrige ésto y aquello (no podía funcionar a la primera ;) ) 
pick 28506fa Corrige warnings
pick 150c964 Limpieza de código
pick ba06e7a Ok, funcionalidad Y completa!

...
```

Si queremos comprimir todos los *commits* en uno sólo, seleccionamos el primero y marcamos el resto con `squash` (o `s` para abreviar):

```bash
pick b185d06 Prerequisitos para la funcionalidad Y
squash da2045b Implementación
squash 529b7bc Corrige ésto y aquello (no podía funcionar a la primera ;) ) 
squash 28506fa Corrige warnings
squash 150c964 Limpieza de código
squash ba06e7a Ok, funcionalidad Y completa!
```

> `git rebase` procesa las acciones de arriba a abajo, por lo que antes del primer `squash` debe habe un `pick`.

Guarda el fichero y cierra el editor.

`git rebase` combina todos los *commits* marcados con `squash` con el *commit* marcado como `pick`.

A continuación, se abre un nuevo editor que contiene por defecto los mensajes de *commit* de los *commits* que van a combinarse en uno solo al ejecutar el *rebase*.

Puedes editar el mensaje de *commit* para ajustarlo al estilo del resto de *commits* del repositorio.

Al finalizar el *rebase* la historia del repositorio sería:

```bash
$ git log --oneline
8da3fcd (HEAD -> feature-1) Funcionalidad Y (issue #123456)
429c084 (master) Funcionalidad X (issue #111111)
5488b91 Primer commit
```
