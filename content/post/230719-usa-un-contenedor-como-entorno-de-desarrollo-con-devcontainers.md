+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["docker", "vscode"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/docker.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/

# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}
# YouTube           {{< youtube w7Ft2ymGmfc >}}
# Gist              {{< gist username 7896402 >}}
# Highlight         {{< highligth language >}}...{{< /highlight >}}
# Twitter           {{< tweet user="SanDiegoZoo" id="1453110110599868418" >}}

title=  "Usa un contenedor como entorno de desarrollo con 'devcontainers'"
date = "2023-07-19T07:43:19+02:00"
+++
## Contexto

Apple no incluye versiones modernas de Bash; la versión incluida por defecto es 3.2. Esto se debe a que a partir de esta versión la licencia que cubre Bash es la GPLv3 y ésta obliga a compartir el código fuente, cosa que Apple no quiere hacer.

El caso es que ahora uso un Mac M2 para el trabajo y algunas funcionalidades como los *arrays asociativos* (`name["dog"]="snoopy"`), sólo están disponibles en Bash v4 o superior.

La solución más obvia, actualizar Bash manualmente en el Mac, es posible pero tiene inconvenientes. El Bash "nativo" de Mac OS se encuentra en `/usr/bin`, mientras que otra versión de Bash, sólo puede ser instalada *fuera* de `/usr/bin`, porque el Mac usa algo llamado *System Integrity Protection*, que evita la ejecución de código no autorizado. Aunque [SIP puede deshabilitarse](https://developer.apple.com/documentation/security/disabling_and_enabling_system_integrity_protection), no es una buena idea.

Dado que en Bash nuestros scripts usan el *shebang* `#!/bin/bash` (ver [Shell Style Guide de Google](https://google.github.io/styleguide/shellguide.html#s1.1-which-shell-to-use)), al ejecutar el script en Mac OS, se usaría Bash 3.2 y no la nueva versión (p.ej, Bash v5).
<!--more-->

## Usando Bash en un contenedor

Una opción sería ejecutar un contenedor basado en una imagen que contenga Bash (v5, por ejemplo).

Con el cambio de licencia de Docker Desktop, ejecutarlo en un equipo de empresa puede no ser una opción viable (en mi caso, sí tenemos licencia).

Una opción que estuve investigando fue la de usar *podman*.

> Disclaimer: no uso `brew`

La intalación de *podman* en Mac sólo puede realizarse usando `brew` según la documentación oficial en [Installing on MacOS & Windows](https://podman.io/docs/installation#macos).

Sin embargo, si instalas [Podman Desktop](https://podman-desktop.io/docs/Installation/macos-install), es posible instalar *podman* desde un instalador de Mac OS (en formato `pkg`):

{{< figure src="/images/230719/podman_install_from_pkg.png" width="100%" >}}

Dado que *podman* usa los mismos subcomandos que `docker`, es sencillo una vez instalado, ejecutar `podman run -it -d -v $(pwd):/code $imageName /bin/bash` para probar los scripts en Bash.

Gracias a la extensión oficial en VSCode [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers), VSCode puede conectarse a un contenedor y así desarrollar "remotamente".

El único problema es que no he sido capaz de hacerlo funcionar con Podman, en parte (supongo) porque *podman* no implementa un "servidor" (es "daemonless").

## Rancher Desktop al rescate

Existe otra alternativa a Docker Desktop; [Rancher Desktop para MacOS](https://docs.rancherdesktop.io/getting-started/installation/#installing-rancher-desktop-on-macos). A diferencia de *podman*, Rancher Desktop usa [Moby](https://mobyproject.org/). Moby es un conjunto de herramientas, entre las que se encuentra [containerd](https://containerd.io/), que es el encargado de gestionar el ciclo de vida de los contenedores. *containerd* es la versión *open source* del "core" de `docker`.

A consecuencia de que `containerd` es 100% compatible con `docker` incluso en la arquitectura "cliente-servidor" es un reemplazo perfecto de Docker (Desktop).

La parte relevante en mi escenario es que VSCode (a través de la extensión de Dev Containers), puede conectarse al *daemon* de *containerd* como si fuera éste fuera Docker.

## Gestión integral desde VSCode

Arrancar Docker/Rancher Desktop, ejecutar un contenedor manualmente para después cambiar a VSCode y conectarse al contenedor en marcha está bien... pero podemos hacerlo mejor.

Mediante la extensión [Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers), VSCode permite usar un contenedor como un entorno completo de desarrollo.

{{< figure src="/images/230719/architecture-containers.png" width="100%" >}}

VSCode puede usar la información del fichero `devcontainer.json` para gestionar automáticamente el contenedor: puede construirlo si incluimos un fichero `Dockerfile`, añadir extensiones y configuraciones de VSCode a partir de una imagen de terceros, ejecutar scripts para realizar configuraciones arbitrarias en el mismo, establecer variables de entorno (o inyectar variables de entorno del sistema), montar volúmenes, etc...

## Crea tu entorno de desarrollo (como código)

Crea el fichero `devcontainer.json` en una carpeta en la raíz de tu repositorio/carpeta de trabajo llamada `.devcontainer`:

```bash
mkdir .devcontainer
touch .devcontainer/devcontainer.json
```

El fichero `devcontainer.json` más sencillo posible sería el que especifica únicamente el nombre de la imagen base para ejecutar el contenedor:

```json
{
  "image": "gcr.io/google.com/cloudsdktool/google-cloud-cli:439.0.0"
}
```

La extensión VSCode monta por defecto la carpeta "local" en el contenedor, así que ésta podría ser una configuración funcional completamente minimalista. Tanto en [Developing inside a Container](https://code.visualstudio.com/docs/devcontainers/containers) como en [Development Container Specification](https://containers.dev/implementors/spec/) tienes toda la información necesaria para personalizar el contenedor de acuerdo con tus necesidades específicas.

## ¿ARM64 vs AMD64? selecciona para qué arquitectura quieres la imagen

Todas las opciones para ejecutar Docker en Mac OS usan [qemu](https://www.qemu.org/) para ejecutar una máquina virtual con Linux que es donde se ejecutar "docker".

En el caso de los nuevos MacBooks con chips ARM64 (M1, M2), podemos usar contenedores para arquitecturas tanto ARM64 como AMD64, aunque en este segundo caso, el rendimiento es menor ya que *qemu* tiene que emular AMD64.

Cuando ejecutas `docker pull`, si la imagen es *multi arquitectura*, Docker es capaz de seleccionar la imagen adecuada a la arquitectura del sistema. En el caso del Mac, se descarga la imagen para ARM64 (si está disponible).

En mi caso, en el contanedor quiero instalar un paquete que sólo está disponible para AMD64, por lo que en mi fichero `devcontainer.json` añado la línea:

```json
{
  "image": "gcr.io/google.com/cloudsdktool/google-cloud-cli:438.0.0-slim",
  "runArgs": ["--platform=linux/amd64" ]
}
```

## Montar una carpeta local en el contenedor

El paquete a instalar está disponible en un *bucket* en la nube, pero también lo tengo descargado localmente para no depender de la red. Para poder instalarlo en el contendor desde la "copia local" en mi equipo, monto la carpeta en la que se encuentra en el contenedor:

```json
{
  "image": "gcr.io/google.com/cloudsdktool/google-cloud-cli:438.0.0-slim",
  "runArgs": ["--platform=linux/amd64" ],
  "mounts": [
    "source=${localEnv:HOME}/Downloads/sample_package_1.2.3.deb,target=/tmp/sample_package_1.2.3.deb,type=bind,consistency=cached"
  ]
}
```

Como ves, monto sólo el fichero que me interesa, no toda la carpeta.

También uso la variable `${localEnv:HOME}` que indica a Dev Containers que debe usar la variable de entorno `$HOME` en el sistema "local" (es decir, mi equipo físico).

## Tareas tras la creación del contenedor

Con el fichero `devcontainer.json` tal y como está, VSCode ejecuta un contenedor basado en la imagen especificada, monta la carpeta local (por defecto) y el fichero `sample_package.1.2.3.deb` en `/tmp/sample_package.1.2.3.deb` en el contenedor.

No está mal, pero el paquete `sample_package.1.2.3.deb` lo he montado para instalarlo.

¿No sería fantástico que VSCode también lo instalara automáticamente?

Podemos especificar un comando o un script para que Dev Container lo ejecute tras la creación del contenedor; por ejemplo:

```json
{
  "image": "gcr.io/google.com/cloudsdktool/google-cloud-cli:438.0.0-slim",
  "runArgs": ["--platform=linux/amd64" ],
  "mounts": [
    "source=${localEnv:HOME}/Downloads/sample_package.1.2.3.deb,target=/tmp/sample_package.1.2.3.deb,type=bind,consistency=cached"
  ],
  "postCreateCommand": "bash .devcontainer/postCreateScript.sh"
}
```

El script puede llamarse de cualquier modo; por ejemplo, `postCreateScript.sh` permite instalar paquetes necesarios en el contenedor final (procedentes de repositorios públicos) así como el paquete *custom* que hemos *montado* desde nuestro equipo local:

```bash
#!/bin/bash

apt install vim -y
dpkg -i /tmp/sample_package_1.2.3.deb
```

## Establecer o actualizar variables de entorno en el contenedor

Dev Container también permite establecer variables de entorno en el contendor, por ejemplo:

```json
{
  "image": "gcr.io/google.com/cloudsdktool/google-cloud-cli:438.0.0-slim",
  "runArgs": ["--platform=linux/amd64" ],
  "mounts": [
    "source=${localEnv:HOME}/Downloads/sample_package.1.2.3.deb,target=/tmp/sample_package.1.2.3.deb,type=bind,consistency=cached"
  ],
  "remoteEnv": {
    "PATH": "/usr/bin/custom:${containerEnv:PATH}",
    "BACK_TO_THE_FUTURE_DAY": "October 21, 2015"
  },
  "postCreateCommand": "bash .devcontainer/postCreateScript.sh"
}
```

En la sección `remoteEnv` actualizamos la variable `$PATH` en el contenedor, añadiendo un nuevo *path* a la variable `$PATH` existente; para ello, la referenciamos mediante `${containerEnv:PATH}`.

También establecemos una variable nueva llamada `BACK_TO_THE_FUTURE_DAY`, que estará disponible para el proceso que se ejecute en el contenedor.

## Instalando extensiones adicionales de VSCode en el contenedor

Si usas VSCode para desarrollar, es bastante probable que tengas instaladas algunas extensiones que te facilitan la tarea (como [Power Mode](https://marketplace.visualstudio.com/items?itemName=hoovercj.vscode-power-mode) o [DOOM In your face](https://marketplace.visualstudio.com/items?itemName=VirejDasani.in-your-face)).

Puedes instalarlas también en el contenedor para que hacer que te sientas "como en casa" cuando estés desarrollando dentro del contenedor:

```json
{
  "image": "gcr.io/google.com/cloudsdktool/google-cloud-cli:438.0.0-slim",
  "runArgs": ["--platform=linux/amd64" ],
  "customizations": {
    "vscode": {
      "extensions": [
        "VirejDasani.in-your-face",
        "hoovercj.vscode-power-mode"
      ]
    }
  },
  "mounts": [
    "source=${localEnv:HOME}/Downloads/sample_package.1.2.3.deb,target=/tmp/sample_package.1.2.3.deb,type=bind,consistency=cached"
  ],
  "remoteEnv": {
    "PATH": "/usr/bin/custom:${containerEnv:PATH}"
  },
  "postCreateCommand": "bash .devcontainer/postCreateScript.sh"
}
```

En mi caso no he tenido suerte y las extensiones que me interesan no funcionan en el contenedor por algún motivo (una se queda *installing* mientras que la otra da un *timeout*).

[YMMV](https://en.wiktionary.org/wiki/your_mileage_may_vary#English), como dicen los anglosajones.
