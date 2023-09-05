+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["docker", "vscode", "devcontainer"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/vscode.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/

# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}
# YouTube           {{< youtube w7Ft2ymGmfc >}}
# Gist              {{< gist username 7896402 >}}
# Highlight         {{< highligth language >}}...{{< /highlight >}}
# Twitter           {{< tweet user="SanDiegoZoo" id="1453110110599868418" >}}

title=  "Autocompletado de comandos (y ramas) de Git en Devcontainer"
date = "2023-09-05T20:37:11+02:00"
+++
En una entrada anterior ([Usa un contenedor como entorno de desarrollo con 'devcontainers']({{< ref "post/230719-usa-un-contenedor-como-entorno-de-desarrollo-con-devcontainers.md" >}})) explicaba cómo usar un contenedor y Devcontainers para suplir las carencias de MacOS con respecto a Bash.

Desde entonces uso Devcontainers más y más; por ejemplo, para desarrollar en Go ya no tengo que levantar una máquina virtual o instalar Go en mi equipo: genero un fichero `devcontainer.json`, indico la imagen oficial de Go y ¡listo!

No todo es perfecto; una de las cosas que últimamente estaba *sufriendo* es que Git no autocompleta, por ejemplo, los nombres de las ramas.

La solución a la que siempre acabo acudiendo (y ejecutando manualmente) es [Autocomplete Git Commands and Branch Names](https://pagepro.co/blog/autocomplete-git-commands-and-branch-names-in-terminal/).

Pero claro, yo quería automatizarlo ;)

Así que hoy explico cómo he conseguido incluir el autocompletado de Git directamente al arrancar un *devcontainer*.
<!--more-->

En la especificación, vemos que Devcontainers puede ejecutar [*lifecycle scripts*](https://containers.dev/implementors/json_reference/#lifecycle-scripts). Es decir, cuando se produce un determinado *evento*, DevContainer lanza un *script* como respuesta.

En mi caso, quiero configurar el fichero `~/.bashrc` en el contenedor cuando se ha creado; para ello, he añadido a mi fichero `devcontainer.json`:

```json
{
  "postCreateCommand": "/bin/bash .devcontainer/post-create.sh"
}
```

En la carpeta `.devcontainer/`, he creado el fichero `post-create.sh`, con el siguiente contenido:

```console
/usr/bin/env bash

grep --quiet --fixed-strings --line-regexp 'source .devcontainer/git-completion.bash' ~/.bashrc || echo 'source .devcontainer/git-completion.bash' >> ~/.bashrc
```

El comando añade una línea al fichero `~/.bashrc` si no existe (los detalles del comando los expliqué en la entrada [Agrega una línea a un fichero sólo si no está presente #TIL]({{< ref "post/230713-agrega-linea-a-un-fichero-solo-si-no-esta-presente.md" >}})).

De esta forma, tras crear el contenedor, automáticamente se añade la línea en el fichero `~/.bashrc`.
Cada vez que el contenedor arranque, se habilita el autocompletado para Git **dentro** del contenedor.

¡Problema resuelto!

P.S. Obviamente, el mismo mecanismo se puede usar para incluir el autocompletado de otras herramientas, como `gcloud`, etc.
