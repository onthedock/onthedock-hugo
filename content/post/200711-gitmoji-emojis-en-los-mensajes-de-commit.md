+++
draft = false

categories = ["dev"]
tags = ["git"]
thumbnail = "images/git.png"

title=  "gitmoji: Emojis en los mensajes de commit"
date = "2020-07-11T08:01:56+02:00"
+++
Revisando los repositorios del diseñador original del tema de este blog, [Daisuke Tsuji](https://github.com/dim0627) he encontrado el fichero [`.git_commit_message`](https://github.com/dim0627/dotfiles/blob/master/.git_commit_message) que contiene una lista de emojis:
<!--more-->

```ini
# ==== Emojis ====
# :ok_hand: minorfixes
# :sparkles: new feature
# :beetle: fixing a bug
# :hammer: refactoring
# :rotating_light: fixing a linters
# :robot: make or fixing a test
# :fire: remove code or file
# :package: dependency management
# :lipstick: updateing the UI and styles
```

Volviendo a la lista de *commits*, he visto que cada uno de sus mensajes va precedido de un *emoji*... Y entonces he descubierto que existe una iniciativa para *standarizar* el uso de emojis en los mensajes de *commit* en GitHub.

En la web de [gitmoji](https://gitmoji.carloscuesta.me/) puedes encontrar una lista de *emojis* que asociar a algunas acciones habituales relacionadas con la revisión de código...

He empezado a probarlo y parece una buena opción para identificar de manera visual el tipo de *commits* que se realizan en un proyecto.

No parece ser una opción que esté soportada en otros servicios, como Bitbucket ([Add support for Emoji in commit messages too](https://jira.atlassian.com/browse/BSERV-10317)), pero si usas GitHub, puede ser una opción interesante a tener en cuenta.
