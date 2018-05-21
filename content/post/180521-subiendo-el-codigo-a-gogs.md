+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev", "ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "gogs", "integracion continua"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/gogs.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" %}}

title=  "Pipeline - Subiendo el código a Gogs"
date = "2018-05-21T09:03:13+02:00"
+++

Ya hemos instalado [Gogs]({{< ref "180520-pipeline-gogs-el-repositorio-de-codigo.md" >}}) y [Jenkins]({{< ref "180520-pipeline-instalacion-y-actualizacion-de-jenkins.md" >}}) en nuestro sistema; ahora es el momento de empezar a subir código y ver qué podemos hacer con él.
<!--more-->

Gogs, como repositorio de código, es el punto de partida del proceso de integración continua.

Como mis habilidades programando son limitadas, usaremos el código fuente del tutorial sobre Maven ofrecido por los desarrolladores del _framework_ para Java **Sping**: [Building Java Projects with Maven](https://spring.io/guides/gs/maven/). El código fuente se encuentra publicado en GitHub: [spring-guides/gs-maven
](https://github.com/spring-guides/gs-maven).

Clonamos el repositorio en una máquina de desarrollo (en `~/gs-maven`) mediante :

```shell
$ git clone https://github.com/spring-guides/gs-maven.git
Cloning into 'gs-maven'...
remote: Counting objects: 478, done.
remote: Total 478 (delta 0), reused 0 (delta 0), pack-reused 478
Receiving objects: 100% (478/478), 140.22 KiB | 0 bytes/s, done.
Resolving deltas: 100% (238/238), done.
$
```

# Creación del repositorio

En primer lugar, accedemos a Gogs y creamos un repositorio para nuestro código:

{{% img src="images/180521/gogs-new-repo.png" w="320" h="205" caption="Gogs - New repository" %}}

Le damos un nombre como `gs-maven` y tras la creación del repositorio, se nos indica cómo añadir un repositorio existente en el repositorio recién creado:

> Como el nombre `origin` se ha añadido automáticamente al clonar el repositorio desde GitHub, cambiamos el nombre del _remoto_ en Gogs por `gogs-origin`:

```shel
git remote add gogs-origin http://192.168.1.209:10080/operador/gs-maven.git
git push -u gogs-origin master
```

# Configuración del remoto `gogs-origin` y subida del código

Siguiendo las instrucciones proporcionadas por Gogs convenientemente modificadas, subimos el código desde la máquina de desarrollo a Gogs:

```shell
$ git remote add gogs-origin http://192.168.1.209:10080/operador/gs-maven.git
$
```

Verificamos que se ha añadido el remoto correctamente:

```shell
$ git remote -v
gogs-origin http://192.168.1.209:10080/operador/gs-maven.git (fetch)
gogs-origin http://192.168.1.209:10080/operador/gs-maven.git (push)
origin https://github.com/spring-guides/gs-maven.git (fetch)
origin https://github.com/spring-guides/gs-maven.git (push)
```

Observamos que se muestra tanto el remoto en GitHub _origin_ como en Gogs _gogs-origin_.

Ahora ya sólo tenemos que subir el código mediante:

```shell
$ git status
On branch master
Your branch is up-to-date with 'origin/master'.
nothing to commit, working tree clean
$ git push gogs-origin master
Counting objects: 478, done.
Delta compression using up to 2 threads.
Compressing objects: 100% (214/214), done.
Writing objects: 100% (478/478), 140.24 KiB | 0 bytes/s, done.
Total 478 (delta 238), reused 478 (delta 238)
Username for 'http://192.168.1.209:10080': operador
Password for 'http://operador@192.168.1.209:10080':
remote: Resolving deltas: 100% (238/238), done.
To http://192.168.1.209:10080/operador/gs-maven.git
 * [new branch]      master -> master
$
```

Primero comprobamos con `git status` que no hay cambios pendientes que añadir. A continuación añadimos el código a `gogs-origin`.

Accediendo a Gogs podemos validar que el código se ha subido correctamente.