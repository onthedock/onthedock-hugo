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

title=  "Git sparse-checkout para clonar sólo subcarpeta(s) de un repositorio"
date = "2023-03-09T19:41:48+01:00"
+++
El ejemplo habitual para introducir los *sparse checkouts* es cuando todo el código de un equipo se encuentra en un *mono repo*, es decir, un repositorio **para todo**.
En el repositorio cada "carpeta" contiene el código de un microservicio, por ejemplo...

En esta situación, un miembro del equipo tiene que clonar el repositorio entero aunque sólo tenga que trabajar en una parte muy pequeña del mismo, generalmente circunscrita a una funcionalidad que se encuentra en una carpeta del repositorio.

Del mismo modo, para compilar el código de uno de los microservicios de este mono repo, es necesario clonarlo completamente...

En este tipo de situaciones es cuando podemos usar `git sparse-checkout`.
<!--more-->

## Repositorio de ejemplo

Como repositorio de ejemplo usaré [xaviatwork/reference_bash_scripts](https://github.com/xaviatwork/reference_bash_scripts).
El repositorio contiene un conjunto de scripts en Bash agrupados por funcionalidad.
Me sirve como analogía de ese *monorepo* que contiene el código de múltiples microservicios.

En este caso, queremos usar los scripts en cada carpeta del repositorio como "bibliotecas de funciones" (aka *librerías*) que incorporaremos a un nuevo script en el que estamos trabajando.

Del conjunto de scripts presentes en el repositorio, sólo estamos interesados en la función para generar el UUID y en la relacionada con los logs.

En vez de clonar el repositorio completo, usaremos *sparse-checkout*.

## Clonando sólo lo que nos interesa del repositorio

Usamos la opción `--no-checkout` para realizar el *clone* sin descargar el repositorio completo.

```bash
$ git clone --no-checkout https://github.com/xaviatwork/reference_bash_scripts.git .
Cloning into '.'...
remote: Enumerating objects: 119, done.
remote: Counting objects: 100% (119/119), done.
remote: Compressing objects: 100% (81/81), done.
remote: Total 119 (delta 42), reused 93 (delta 24), pack-reused 0
Receiving objects: 100% (119/119), 18.30 KiB | 669.00 KiB/s, done.
Resolving deltas: 100% (42/42), done.
```

La carpeta no contiene ningún fichero (aunque hayamos clonado el repositorio):

```bash
$ ls -a 
.  ..  .git
```

Ejecutamos el subcomando *sparse-checkout*, especificando qué carpeta(s) nos interesan del repositorio mediante `set`; como habíamos anticipado, indicamos a Git que sólo queremos la carpeta `generate_uuid` y `logmsg`:

```bash
git sparse-checkout set generate_uuid logmsg
```

Seguimos sin tener nada en la carpeta, pero el comando ha preparado Git para "trackear" sólo las carpetas que nos interesan.

> Incluso tras ejecutar `git sparse-checkout set generate_uuid logmsg`, Git interpreta la carpeta vacía como si el contenido del repositorio hubiera sido  borrado; puedes comprobarlo ejecutando:
>
> ```bash
> $ git status 
> On branch main
> Your branch is up-to-date with 'origin/main'.
> 
> Changes to be committed:
>   (use "git restore --staged <file>..." to unstage)
>     deleted:    aws_configure_profile/aws_configure_profile.sh
>     deleted:    aws_configure_profile/config
>     deleted:    bash-ini-parser/bash-ini-parser
>     deleted:    bash-ini-parser/getKeyFromSection.sh
>     deleted:    generate_uuid/generate_uuid.sh
>     deleted:    helm/install_helm_chart.sh
>     deleted:    kubernetes/get_kubeconfig.sh
>     deleted:    kubernetes/set_default_storageclass.sh
>     deleted:    logmsg/logmsg.sh
>     deleted:    logmsg/tests.sh
>     deleted:    parse_cli_args/README.md
>     deleted:    parse_cli_args/parse_cli_args.sh
>     deleted:    parse_cli_args/test.sh
>     deleted:    request_user_input/README.md
>     deleted:    request_user_input/request.sh
>     deleted:    request_user_input/test.sh
> ```

Finalmente, establecemos la rama del repositorio (en este caso, `main`):

```bash
$ git switch main
Already on 'main'
Your branch is up-to-date with 'origin/main'.
```

Aunque nos indica que ya estábamos en `main`, el resultado de `git status` ahora es:

```bash
$ git status 
On branch main
Your branch is up-to-date with 'origin/main'.

You are in a sparse checkout with 19% of tracked files present.

nothing to commit, working tree clean
```

Git ahora **sabe** que está trabajando con un *sparse-checkout* (no que los ficheros se han borrado, como indicaba antes).

Fíjate en la línea:

```bash
You are in a sparse checkout with 19% of tracked files present.
```

Y si mostramos los ficheros en la copia local del repositorio:

```bash
$ ls   
generate_uuid  logmsg
$ tree .
.
├── generate_uuid
│   └── generate_uuid.sh
└── logmsg
    ├── logmsg.sh
    └── tests.sh

2 directories, 3 files
```

> La documentación oficial para [`sparse-checkout`](https://git-scm.com/docs/git-sparse-checkout) (en este caso, para la versión 2.39.2) inidica que `git sparse-checkout init --clone` está *deprecated* y que puede ser eliminado en el futuro.
> Este artículo de GitHub [Bring your monorepo down to size with sparse-checkout](https://github.blog/2020-01-17-bring-your-monorepo-down-to-size-with-sparse-checkout/) del 2020 (actualizado en Marzo 2021) que me ha servido como punto de partido todavía hace referencia a `git sparse-checkout init --cone`.
