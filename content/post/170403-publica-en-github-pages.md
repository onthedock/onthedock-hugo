+++
date = "2017-04-03T22:38:35+02:00"
title = "Publica en Github Pages"
thumbnail = "images/github.png"
categories = ["dev", "ops"]
tags = ["hugo", "github"]

+++

Cómo publicar el sitio web generado con Hugo en GitHub Pages.

<!--more-->

Siguiendo las instrucciones de la página de Hugo sobre [cómo publicar en Github Pages](https://gohugo.io/tutorials/github-pages-blog/#hosting-personal-organization-pages):

* Creo un repo llamado `onthedock.github.io`: este albergará el sitio público.
* Creo un repo llamado `onthedock-hugo` que contendrá todo el site: ficheros de hugo, el template, etc.

Creo una carpeta local llamada `onthedock-githubpages`.

Dentro de la carpeta, lanzo:

```sh
$ git clone https://github.com/onthedock/onthedock-hugo.git`
Cloning into '.'...
warning: You appear to have cloned an empty repository.
$
```

Compruebo que tengo un repositorio local inicializado:

```sh
$ git status
On branch master

Initial commit

nothing to commit (create/copy files and use "git add" to track)
$
```

Copio el contenido del _site_ de Hugo (que previamente he movido a otra carpeta):

```sh
$ git status
On branch master
Initial commit
Untracked files:
  (use "git add <file>..." to include in what will be committed)
   config.toml
   content/
   static/
   themes/
nothing added to commit but untracked files present (use "git add" to track)
$
```

> Las carpetas vacías no se añaden a Git.

Eliminamos la carpeta `$HUGO/public`.

Añadimos un [_submodulo_](https://git-scm.com/book/es/v1/Las-herramientas-de-Git-Subm%C3%B3dulos):

```sh
$ git submodule add -b master https://github.com/onthedock/onthedock.github.io.git public
Cloning into '/Users/xavi/Dropbox/dev/hugo/onthedock-githubpages/public'...
remote: Counting objects: 3, done.
remote: Compressing objects: 100% (2/2), done.
remote: Total 3 (delta 0), reused 0 (delta 0), pack-reused 0
Unpacking objects: 100% (3/3), done.
$
```

Comprobamos el estado del repositorio:

```sh
$ git status
On branch master

Initial commit

Changes to be committed:
  (use "git rm --cached <file>..." to unstage)

   new file:   .gitmodules
   new file:   public

Untracked files:
  (use "git add <file>..." to include in what will be committed)

   config.toml
   content/
   static/
   themes/

$
```

Añadimos los ficheros del _andamiaje_ de Hugo:

```sh
$ git add .
$
```

Verifico que el repositorio _remoto_ es el correcto:

```sh
git remote -v
origin https://github.com/onthedock/onthedock-hugo.git (fetch)
origin https://github.com/onthedock/onthedock-hugo.git (push)
$
```

Y subo el sitio al _repo_ remoto: `onthedock-hugo`:

```sh
$  git push origin master
error: src refspec master does not match any.
error: failed to push some refs to 'https://github.com/onthedock/onthedock-hugo.git'
$
```

Oopps.

El problema era que no había guardado ningún cambio, por lo que no existía la rama `master`. Aunque he interpretado correctamente el mensaje, he corregido el problema en el extremo opuesto (en el repositorio remoto); he creado un fichero `License.md` y he lanzado `git pull`:

```sh
$ git pull origin
remote: Counting objects: 3, done.
remote: Compressing objects: 100% (2/2), done.
remote: Total 3 (delta 0), reused 0 (delta 0), pack-reused 0
Unpacking objects: 100% (3/3), done.
From https://github.com/onthedock/onthedock-hugo
 * [new branch]      master     -> origin/master
$
```

`git pull` hace un `git fetch` y un `git merge`, lo que crea un _commit_ (que era lo que me faltaba por hacer):

Vuelvo a intentarlo y esta vez sí:

```sh
$ git commit

(había añadido los cambios al _staging area_ pero no los había guardado con _commit_)

$ git push origin master
Username for 'https://github.com': onthedock
Password for 'https://onthedock@github.com':
Counting objects: 64, done.
Delta compression using up to 4 threads.
Compressing objects: 100% (56/56), done.
Writing objects: 100% (64/64), 3.28 MiB | 547.00 KiB/s, done.
Total 64 (delta 2), reused 0 (delta 0)
remote: Resolving deltas: 100% (2/2), done.
To https://github.com/onthedock/onthedock-hugo.git
   92f53f2..5ecc4bc  master -> master
$
```

Ahora voy a generar el sitio (después de actualizar el fichero `config.toml` para que el parámetro `baseURL` apunte a la dirección _pública_ del sitio en GitHub):

```sh
$ hugo
Started building sites ...
Built site for language en:
0 draft content
0 future content
0 expired content
6 regular pages created
14 other pages created
0 non-page files copied
12 paginator pages created
8 tags created
2 categories created
total in 68 ms
$ git status
On branch master
Your branch is up-to-date with 'origin/master'.
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git checkout -- <file>..." to discard changes in working directory)
  (commit or discard the untracked or modified content in submodules)

   modified:   public (untracked content)

no changes added to commit (use "git add" and/or "git commit -a")
$
```

El contenido de la carpeta `$HUGO/public`  está contenida en un _submódulo_ de Git.

```sh
$ cd public/
$ git status
On branch master
Your branch is up-to-date with 'origin/master'.
Untracked files:
  (use "git add <file>..." to include in what will be committed)

   404.html
   categories/
   images/
   index.html
   index.xml
   page/
   post/
   sitemap.xml
   tags/

nothing added to commit but untracked files present (use "git add" to track)
$
```

Ahora, desde este _sub-repositorio_, lanzo `git add`:

```sh
$ git add .
$ git status
On branch master
Your branch is up-to-date with 'origin/master'.
Changes to be committed:
  (use "git reset HEAD <file>..." to unstage)

   new file:   404.html
   new file:   categories/dev/index.html
   new file:   categories/dev/index.xml
   new file:   categories/dev/page/1/index.html
   new file:   categories/index.html
   new file:   categories/ops/index.html
   new file:   categories/ops/index.xml
   new file:   categories/ops/page/1/index.html
.
.
.
```

Lanzo un _commit_ para guardar los cambios:

```sh
git commit
```

Verifico que el repositorio remoto es `onthedock.github.io`:

```sh
$ git remote -v
origin https://github.com/onthedock/onthedock.github.io.git (fetch)
origin https://github.com/onthedock/onthedock.github.io.git (push)
$
```

Ahora, subo los cambios al repositorio de GitHub Pages:

```sh
$ git push origin master
Username for 'https://github.com': onthedock
Password for 'https://onthedock@github.com':
Counting objects: 104, done.
Delta compression using up to 4 threads.
Compressing objects: 100% (74/74), done.
Writing objects: 100% (104/104), 911.20 KiB | 0 bytes/s, done.
Total 104 (delta 41), reused 0 (delta 0)
remote: Resolving deltas: 100% (41/41), done.
To https://github.com/onthedock/onthedock.git
   49c08af..5432d12  master -> master
$
```

La web estará accesible en los próximos diez minutos, aproximadamente, en `http://onthedock.github.io`.

> El nombre del repositorio debe ser `onthedock.github.io`, y no sólo  `onthedock`. Si te pasa como a mi y debes cambiar el nombre del _repo_ , recuerda que ¡puedes hacerlo!

Se puede renombrar el repositorio desde GitHub, pero eso supone que también hay que actualizar el nombre del repositorio en la configuración del  _remote_ en el repositorio local.

Para ello, usa el comando:

```sh
$ git remote set-url origin https://github.com/onthedock/onthedock.github.io.git
$ git remote -v
origin https://github.com/onthedock/onthedock.github.io.git (fetch)
origin https://github.com/onthedock/onthedock.github.io.git (push)
$
```

Una vez cambiado el nombre del repositorio, tras una corta espera, el sitio ya es accesible a través de `https://onthedock.github.io`.