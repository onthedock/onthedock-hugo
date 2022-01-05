+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "oh-my-zsh"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/bash.svg"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/

# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}
# YouTube           {{< youtube w7Ft2ymGmfc >}}
# Gist              {{< gist username 7896402 >}}
# Highlight         {{< highligth language >}}...{{< /highlight >}}
# Twitter           {{< tweet user="SanDiegoZoo" id="1453110110599868418" >}}

title=  "Tema personalizado de Oh My Zsh"
date = "2021-12-29T23:22:36+01:00"
+++
[Oh My Zsh](https://ohmyz.sh/) es un *framework* para gestionar la configuración de Zsh.

[Zsh](https://es.wikipedia.org/wiki/Zsh) es un *shell* alternativo a [BASH](https://es.wikipedia.org/wiki/Bash), el *shell* por defecto de la mayoría de distribuciones Linux. Sin embargo, desde Mac OS Catalina, Zsh se convirtió en el *shell* del terminal de los Mac. Este hecho, junto a la *vistosidad* de los temas que pueden aplicarse al *prompt* en Zsh (en especial, gracias a Oh My Zsh), ha convertido Zsh en un *shell* cada vez más popular.

> **Update** : [Joe Block](https://github.com/unixorn/) ha sido tan amable de incluir mi tema de Oh My Zsh en la lista que mantiene en GitHub [unixorn/awesome-zsh-plugins](https://github.com/unixorn/awesome-zsh-plugins).
<!--more-->

El *prompt* del *shell* de Linux, se puede personalizar; lo habitual suele ser indicar el nombre de usuario y en el nombre del sistema en el que se ha inciado sesión, junto con la ruta actual en el sistema:

```bash
xavi@macbook-air /home/xavi/Documents $ 
```

La *definición* del *prompt* se realiza a través de la variable `$PS1` (aunque hay otras variables para casos específicos, `$PS2`, `$PS3` y `$PS4`). El intérprete de la *shell* muestra información en base a unas "variables", como en el *prompt* por defecto de BASH: `\s-\v\$`; `\s` indica el nombre de la *shell* actual, `-` es el literal `-` y `\v` es la versión del *shell*, seguido del carácter especial `$` (que como tienen un significado especial en BASH, debe *escaparse* precediéndolo de `\`). El *prompt* `\s-\v\$` muestra `bash-3.2$` al ejecutar `bash` en mi Mac, por ejemplo.

Sin embargo, `bash-3.2$` no aporta demasiada información útil, así que la mayoría de distribuciones cambian el *prompt* por defecto a `[\u@\h \W]\$` (`\u` usuario, `@` *at* `\h` nombre del *host*, seguido de la ruta actual `\W` y el símbolo del dólar `\$`).

Los terminales soportan colores, por lo que una personalización adicional suele ser mostrar el *prompt* en rojo cuando se usa el superadministrador *root*, por ejemplo.

El *prompt* también puede mostrar el resultado de la ejecución de comandos y funciones, lo que hace que las posibilidades de configuración sean ilimitadas...

En BASH -hasta donde sé- esas personalizaciones han sido siempre algo *individual*, por llamarlo de algún modo: "alguien" realiza una configuración que se ajusta a lo que necesita y, como mucho, la comparte *online* y otros la copian o la adaptan a sus necesidades.

Oh My Zsh parte de esa idea pero establece un "lenguaje común" (un *framework*) para realizar la configuración del *prompt*. Esa *estandarización* es lo que ha permitido que se desarrollen *temas* que aprovechan las funciones desarrolladas por el equipo de Oh My Zsh para mostrar todo tipo de información y *colorines* en el *prompt* de manera sencilla.

Así, además de mostrar información sobre el usuario y el *host*, el *prompt* se extiende para incluir la rama activa en un repositorio de git, si hay ficheros modificados o no... Del mismo modo, si trabajas con Python, puedes mostrar qué *entorno virtual* está activo.

Oh My Zsh se basa en *plugins* que permiten añadir o eliminar la funcionalidad que mejor se ajusta a tus necesidades de configuración del *prompt* del terminal.

## Buscando un tema

Hay una [infinidad](https://github.com/ohmyzsh/ohmyzsh/wiki/Themes) de temas incluidos en Oh My Zsh. Además, existen temas adicionales [External themes](https://github.com/ohmyzsh/ohmyzsh/wiki/External-themes) y muchos más todavía en GitHub (tanto en los *gists* [Gist zsh themes search](https://gist.github.com/search?l=Shell&q=extension%3Azsh-theme&ref=searchresults&utf8=%E2%9C%93) como en repositorios [GitHub zsh themes search](https://github.com/search?l=Shell&q=extension%3Azsh-theme+PS1+%7C%7C+PROMPT+&ref=searchresults&type=Code&utf8=%E2%9C%93))... Y todo esto sólo en GitHub; habrá muchos otros en GitLab o Bitbucket...

Como dice el refrán, *para gustos, los colores*... Y esa es la base de la multiplicidad de los temas en Oh my Zsh: unos prefieren muchos colorines, otros no; unos con mucha información y otros un *prompt* minimalista... El *prompt* en una sola línea o en dos, con información sólo a la izquierda, o con información a izquierda y derecha...

*Ad nauseam*.

En mi caso, siempre había utilizado alguno de los temas incluidos en Oh My Zsh, generalmente, [agnoster](https://github.com/agnoster/agnoster-zsh-theme). Pero **agnoster** requiere una fuente que contenga determinados caracteres especiales para mostrarse correctamente y recientemente he vuelto a usar la fuente [IBM Plex Mono](https://www.ibm.com/plex/) de forma habitual.

Al *desaparecer* los caracteres especiales, el *prompt* de Zsh me daba la sensación de estar "roto", y ahí es donde me animé a buscar un tema alternativo a **agnoster**.

Pese haber **tantos** temas, con tan pocas variaciones entre ellos, el proceso de revisarlos acaba derivando en:

- horas y horas revisando temas y más temas
- buscar en Google "best theme for oh-my-zsh" o algo por el estilo

En el segundo caso, uno de los primeros resultados es [Top 12 Oh My Zsh Themes For Productive Developers](https://travis.media/top-12-oh-my-zsh-themes-for-productive-developers/). El criterio para seleccionar algunos de los temas es *cuestionable*, pero es lo que tienen estas listas...

- Apple: *Kind of nice for us mac lovers (though the apple is pink 😒).But somewhat minimal and refreshing.*
- *...the miloshadzic theme has a nice, cartoonish lightning bolt. And everyone likes a good lightning bolt*

Pese a todo, la lista me sirvió para descubrir el tema [gnzh](https://github.com/ohmyzsh/ohmyzsh/blob/master/themes/gnzh.zsh-theme), incluído *de serie* en Oh My Zsh.

Es un tema sencillo, con la información básica (usuario, *host*) junto con información del repositorio de Git. Otro detalle que me gustó es que la información se muestra en dos líneas, lo que hace que el comando siempre empiece a la izquierda de la ventana, independientemente de la ruta en la que te encuentres.

No me acabó de convencer la *decoración* de la *flecha* que une la línea superior con el símbolo del *prompt*.

Revisando el fichero de configuración me sorprendió gratamente ver que es relativamente sencillo, por lo que animé a modificarlo; al fin y al cabo, lo único que quería hacer era eliminar esa "decoración" entre las dos líneas...

Eliminar la decoración fue tan sencillo como pasar de:

```bash
PROMPT="╭─${user_host} ${current_dir} \$(ruby_prompt_info) ${git_branch}
╰─$PR_PROMPT "
```

a

```bash
PROMPT="${user_host} ${current_dir} \$(ruby_prompt_info) ${git_branch}
$PR_PROMPT "
```

El *triángulo* como símbolo para el *prompt* tampoco me convencía del todo, así que me animé e intenter poner un *emoji*:

```bash
PR_PROMPT='👉️ %f'
```

Como en mi caso siempre uso Oh My Zsh en mis equipos *personales* (no en los servidores y/o máquinas virtuales que uso como *laboratorios*), no me aporta nada que se muestre el *host* en el que me encuentro, así que lo eliminé del *prompt*.

Después *me vine arriba* y quise añadir también un *emoji* que cambiara mostrando si había ficheros modificados o no en el repositorio de Git... A base de revisar otros temas, acabé con las variables:

```bash
ZSH_THEME_GIT_PROMPT_DIRTY=" 🚩️"
ZSH_THEME_GIT_PROMPT_CLEAN=" ✅️"
```

Lo que tenía que ser una pequeña modificación del tema se acabó convirtiendo en ir probado *emojis*, intentando añadir el número de ficheros *untracked* y *modified* en el repositorio, el número de *commits* por detrás de *origin*, etc...

Tras unas cuantas horas, decidí dejar *mi tema personalizado* casi como el original **gnzh** (excepto por los *emojis*):

```bash
xavi 📂️~/Dev/hugo/onthedock-githubpages (master 🚩️)
👉️  
```

Mi versión del tema *gnzh* se encuentra en el repositorio de Github: [onthedock/xavi.zsh-theme](https://github.com/onthedock/xavi.zsh-theme).
