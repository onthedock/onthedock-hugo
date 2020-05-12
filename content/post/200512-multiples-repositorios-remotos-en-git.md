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

# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" %}}

title=  "Múltiples repositorios remotos en Git"
date = "2020-05-12T22:06:13+02:00"
+++
Al clonar un repositorio, Git añade una referencia en la configuración del repositorio clonado para incluir el repositorio "original" como "remote". Este repositorio se denomina, por defecto, `origin`. De esta forma, si quieres enviar cambios a este repositorio, ejecutas el comando `git push origin ${rama}`.

En algunas situaciones te puede interesar trabajar con múltiples repositorios remotos, por lo que en esta entrada explico cómo revisar los repositorios remotos configurados en tu repositorio, cómo añadir y eliminar repositorios "remotos" adicionales, cambiarles el nombre, etc.
<!--more-->
## Revisando los repositorios remotos

Como decía, si has clonado tu repositorio local desde GitHub, por ejemplo, el repositorio "original" se ha añadido automáticamente como "remoto" con el nombre `origin`.

Git proporciona el subcomando `remote` con el que interaccionar con los repositorios remotos configurados.

Puedes consultar la ayuda para este comando mediante `git remote --help` o consultar el libro oficial con la documentación de Git en el capítulo [2.5 Git Basics - Working with Remotes](https://git-scm.com/book/en/v2/Git-Basics-Working-with-Remotes). El libro está traducido a varios idiomas -entre ellos, el castellano- y puedes consultarlo libremente online.

Ejecutando el comando `git remote` *a pelo*:

```bash
$ git remote
origin
```

En la salida, se indica que hay un repositorio configurado con el nombre `origin`, pero no aporta demasiada información.

Añade `-v` o `--verbose` para que Git proporcione algo más de información:

```bash
$ git remote
origin  https://github.com/onthedock/onthedock-hugo.git (fetch)
origin  https://github.com/onthedock/onthedock-hugo.git (push)
```

En la salida vemos que el repositorio remoto `origin` aparece dos veces; al observar con más detalle, al final de la URL se indica la acción asociada a la URL; la primera URL corresponde a la acción de [`fetch`](https://git-scm.com/docs/git-fetch) (descarga de cambios desde el repositorio remoto hacia tu repositorio local) mientras que la segunda es para las acciones de [`push`](https://git-scm.com/docs/git-push) (envío de cambios de tu repositorio hacia el remoto).

Si quieres todavía más información sobre un repositorio remoto concreto, puedes usar `git remote show`, para el remoto en el que estás interesado.

```bash
$ git remote show origin
* remote origin
  Fetch URL: https://github.com/onthedock/onthedock-hugo.git
  Push  URL: https://github.com/onthedock/onthedock-hugo.git
  HEAD branch: master
  Remote branch:
    master tracked
  Local branch configured for 'git pull':
    master merges with remote master
  Local ref configured for 'git push':
    master pushes to master (up to date)
```

## Repositorios remotos... o no

Aunque en realidad nos referimos al repositorio "de origen" como "remoto", el repositorio puede estar en tu mismo equipo, en otra ruta. En el libro sobre Git, en [2.1 Git Basics - Getting a Git Repository](https://git-scm.com/book/en/v2/Git-Basics-Getting-a-Git-Repository) tienes explicado con detalle cómo crear un repositorio de Git.

Si clonas un repositorio existente en tu equipo local mediante `git clone /home/proyecto/ /home/copia-repo-proyecto/`, donde `/home/proyecto` es la ruta a un repositorio local de Git, en el nuevo repositorio (el clon) la referencia al repositorio "remoto" `origin` apunta a `/home/proyecto/`.

Por tanto, un repositorio "remoto" en realidad es "otro repositorio" con el que tu repositorio sabe "contactar" y que tiene guardado en su "agenda de contactos" con el nombre `origin`.

## Cambiar el nombre de un remoto

Si por cualquier motivo quieres cambiar el nombre de un repositorio remoto, es tan sencillo como lanzar el comando `git remote rename`.

Suponiendo que has clonado el respositorio original desde GitHub, puedes cambiar el nombre con el que se identifica el remoto de `origin` a `github`, por ejemplo:

```bash
git remote rename origin github
```

El comando no muestra ninguna salida si todo funciona correctamente; si quieres comprobarlo puedes usar de nuevo `git remote -v`:

```bash
$ git remote -v
github  https://github.com/onthedock/onthedock-hugo.git (fetch)
github  https://github.com/onthedock/onthedock-hugo.git (push)
```

## Añadiendo un remoto adicional

Supongamos por un momento que eres un *friky* ;) y que tienes montado tu propio "github" personal en casa con [Gitea, la versión mejorada de Gogs]({{< ref "180713-gitea-la-version-mejorada-de-gogs.md" >}}); has creado un repositorio en Gitea cuya URL es `http://192.168.1.123/xavi/onthedock-gitea.git` y quieres añadirlo como *remote* a tu repositorio mediante el comando `git remote add`:

```bash
git remote add gitea http://192.168.1.123/xavi/onthedock-gitea.git
```

Ahora, si compruebas los repositorios remotos:

```bash
$ git remote -v
gitea   http://192.168.1.123/xavi/onthedock-gitea.git (fetch)
gitea   http://192.168.1.123/xavi/onthedock-gitea.git (push)
github  https://github.com/onthedock/onthedock-hugo.git (fetch)
github  https://github.com/onthedock/onthedock-hugo.git (push)
```

Puedes añadir tantos repositorios *remotos* a tu repositorio como necesites en tu flujo de trabajo habitual.

Para obtener (vía `fetch` o envíar con `push`) cambios de/al repositorio remoto, debemos especificarlo explícitamente en el comando (en el caso de `push` también se requiere la rama).

Aunque en el ejemplo he nombrado los repositorios en función de su ubicación, podrían corresponder a entornos de desarrollo diferentes, como `integracion` y `produccion` o `trabajo` y `cliente`, etc... O incluso podrías cambiarle el nombre porque prefieres llamar a tus remotos de alguna manera "graciosa" (`git push harder master`, `git push iamthebest dev`)...

El nombre con el que identificas el repositorio remoto sólo es relevante en tu copia "personal" del repositorio.

Si en algún momento quieres eliminar un repositorio remoto, usa el comando `git remote rm ${nombreRemoto}`. Aunque eliminar un repositorio remoto no elimina ningún fichero local, sí que pierdes la capacidad de enviar u obtener cambios de ese repositorio (ya que Git no sabe cómo contactar con él).

## Conclusión

Git gestiona la creación del remoto `origin` "por defecto" al realizar el clonado de un repositorio, por lo que en general, no es una tarea que debas realizar manualmente si habitualmente clonas repositorios existentes (o que otra persona ha generado previamente).

Si tienes que trabajar con múltiples repositorios remotos, Git proporciona una manera muy sencilla de organizarlos como quieras de manera que siempre sea evidente a/de qué repositorio remoto estás enviando/recibiendo cambios.
