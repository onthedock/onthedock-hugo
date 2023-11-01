+++

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["git"]

thumbnail = "images/git.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/

title=  "Usa una plantilla para los commits de Git"
date = "2023-11-01T18:16:45+01:00"
+++
Git proporciona la opción de establecer un fichero como *plantilla* para los *commits* de Git.

Cuando defines una plantilla para los *commits*, al ejecutar `git commit`, el editor que tengas configurado para componer el mensaje de *commmit* carga automáticamente la plantilla que hayas definido.

Ni que decir que usar una plantilla para todos los *commits* ayuda a homogeneizar los mensajes en el repositorio y es una configuración esencial en equipos de trabajo.
<!--more-->

## Cómo establecer la plantilla para los *commits*

En primer lugar, puedes comprobar si ya se ha definido una plantilla para un repositorio mediante:

```console
git config --get commit.template
```

Si el comando no devuelve nada, es que no se ha definido ninguna plantilla para el repositorio actual.

Para establecer la plantilla a usar por Git para los *commits*, ejecuta:

> Si quieres establecer la plantilla para TODOS tus repositorios, añade `--global`

```console
git config commit.template ./path/to/commit/template
```

## Qué incluir en la plantilla para los *commits*

Esto depende **completamente** del equipo, de cuestiones estilísticas, de normativa interna...

La mayoría de artículos relacionados con "cómo escribir un buen *commit*" acaban referenciando éste artículo [How to Write a Git Commit Message](https://cbea.ms/git-commit/), aunque no es el primero que trata el tema.

Basándose en las [7 reglas](https://cbea.ms/git-commit/#seven-rules) que indica el artículo, muchos usan una plantilla como la del siguiente "gist" [Using Git Commit Message Templates to Write Better Commit Messages](https://gist.github.com/lisawolderiksen/a7b99d94c92c6671181611be1641c733).

Personalmente, lo encuentro un poco *overkill*, especialmente si usas VSCode para interaccionar con Git, ya que VSCode carga el mensaje espcificado en la plantilla en la "caja de texto" para el *commit* (que no es demasiado grande).

En la misma línea, además de las *7 reglas* para un buen mensaje de *commit*, podría añadirse una sección adicional sobre los diferentes mensajes sugeridos por [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

Que Git muestre toda esta información en cada uno de los *commits* puede ser una buena manera de *memorizar* estas reglas cuando estás empezando con Git y así no crear *malos hábitos*.

Yo estaba muy acostumbrado a especificar el mensaje de *commit* directamente en la línea de comando: `git ci -m "docs: blah blah...`, por ejemplo. No es un mal hábito como tal, pero al principio interfería con mi voluntad de usar la plantilla para el *commit*. (Como especificas el mensaje al ejecutar el comando `git commit`, no "pasas" por el editor para componerlo y por tanto, la plantilla no se muestra.)

Personalmente uso una plantilla para *commits* muy minimalista, y generalmente, sólo para temas relacionados con el trabajo. En ese entorno, los cambios tienen relación con un ticket en Jira, por lo que tiene sentido *esforzarse* en incluir el ID del ticket en el *commit*; no sólo ayuda con la trazabilidad de los cambios, sino que además las herramientas que usamos enlazan automáticamente el ticket en Jira, con los *builds* que se ejecutan, etc...

Como en el *subject* del *commit* ya incluyo el "identificador" del *conventional commit*, no quiero, además, añadir el identificador del ticket de Jira (especialmente si quiero "cumplir" con el límite de 50 caracteres). Así que lo incluyo como una especie de "firma", al final del texto del *commit*.

En resumen, usar una plantilla para *commits* es una buena forma de estandarizar los mensajes y hacer que `git log` proporcione información útil y estructurada sobre la *historia* del repositorio.
