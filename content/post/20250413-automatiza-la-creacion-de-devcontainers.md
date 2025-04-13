+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["devcontainers"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/devcontainer.svg"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/
# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}

title=  "Automatizando la creación de devcontainers"
date = "2025-04-13T09:15:37+02:00"
+++
Desde que descubrí los [*devcontainers*](https://code.visualstudio.com/docs/devcontainers/containers) se han convertido en una parte esencial tanto de mi trabajo como de mi *hobby* tecnológico.
Y sin embargo, no había escrito nunca al respecto en el blog.
Así que ha llegado el momento de solucionarlo.
<!--more-->
## Motivación

Anteriormente, mi equipo de trabajo era un portátil con Windows, pero trabajando principalmente en el *cloud*, donde todo funciona con Linux, suponía un problema.
Estoy hablando de cuando WSL todavía no existía, o cuando, existiendo, las medidas de seguridad de la empresa hacían que usarlo fuera una pesadilla.

En cierto momento, conseguí la autorización para instalar Virtual Box y poder desplegar un Linux completo, lo que resolvió la mayor parte de mis problemas (excepto los relacionados con el proxy, pero eso es otra historia).

La parte negativa era el tiempo que tarda en arrancar una VM y los recursos que consume... Y esos dos problemas son los que resuelven los contenedores... Así que empecé a investigar hasta descubrir los *devcontainers*. Básicamente, levantas un contanedor con las herramientas que necesitas y conectas tu editor al contenedor.
Teniendo Docker (o alguna alternativa) en el equipo, VSCode se puede encargar de todo el proceso: construir la imagen a partir de un `Dockerfile`, levantar el contenedor, conectarse al mismo, montar tu copia local del repositorio en el contenedor...

En resumen, la solución a todos mis problemas.

## Mi "nuevo" problema

Al usar un Mac, que es "casi, casi" un Linux de verdad, me encontré con un nuevo problema: aunque incluye Bash, usa la versión 3.2.
Como en nuestro entorno de Cloud usamos Bash en las automatizaciones, uso un *devcontainer* para disponer de una versión actual de Bash.

Problema resuelto, ¿no?

Bueno, el problema no era ése; para cada nuevo repositorio que clono en el Mac, tengo que añadir la configuración del *devcontainer* al repositorio antes de ponerme a realizar cualquier prueba o cambio.

La solución elegida, hasta ahora, era de la buscar otro repositorio local y *copy-paste*ar la carpeta de la configuración en el nuevo clon.

Habitualmente me encontraba con el problema de que la versión de la imagen referenciada en el fichero `devcontainer.json` era vieja y la había borrado del sistema, por lo que la tenía que descargar de nuevo (y esto es un problema, especialmente desde algunas redes wifi).
En algunas configuraciones no tenía instaladas las extensiones que uso actualmente, etc...

Por tanto, antes de ponerme a hacer cualquier cosa productiva, tenía que perder un tiempo en *repasar* la configuración existente, ajustarla, etc...

Esta situación se repetía en relación con mi propósito de aprender a programar en Go (para lo que también uso *devcontainers*).

## Automatización al poder

Llevaba un tiempo dando vueltas a la idea de crear una herramienta para automatizar el proceso.
Mi idea era ejecutar "devcontainer init" y que la herramienta creara la configuración necesaria. Como uso diferentes contenedores en función de lo que tengo que hacer, debería añadir un parámetro para especificar el tipo de configuración que esta herramienta debería crear...

Pensaba que sería fácil...

Al desarrollar esta herramienta el principal problema era que intentaba hacer que fuera completamente flexible. Y como suele pasar en estos proyectos personales, eso complica mucho las cosas.

Al final, he optado por un enfoque más pragmático: primero, hacer que funcione. Después, ya lo mejoraré.

Actualmente utilizo dos contenedores: uno basado en la imagen de `gcloud` y otra en `go`.

Para el desarrollo en Go, VSCode proporciona una imagen para el *devcontainer* que incluye prácticamente todo lo que necesito. La configuración para el desarrollo en Go es muy sencilla.

Para mi trabajo, la cosa es más complicada, porque la imagen que uso es una imagen orientada a un entorno productivo, no de desarrollo, así que le faltan muchas de las "herramientas adicionales" que me facilitan mi trabajo.

### Estandarizar la configuración

Como indicaba más arriba, uno de los problemas con los que me encuentro es que tengo múltiples configuraciones para el mismo entorno (que fueron creadas en diferentes momentos del tiempo). Así que el primer objetivo era tener una *implementación de referencia*.

Otro requerimiento que me he impuesto es tener una única configuración, de manera que si en el futuro decido incluir una nueva extensión en VSCode, por ejemplo, no tenga que recorrer todos los repositorios para actualizar las configuraciones existentes.

La manera en como he decidido implementarlo es mediante un *volumen*. En Docker tenemos dos tipos de volúmenes; los volúmenes tipo *bind* montan una carpeta especificada por el usuario en el punto de montaje indicado en el contenedor. Pero también hay otro tipo llamado `volume`. En este caso, cuando se crea un volumen, Docker genera una carpeta donde se almacenará el contenido. Es decir, la gestión de la "carpeta" que se monta en el contedor la gestiona Docker, no el usuario.

Hay algunas ventajas asociadas a usar volúmenes de este tipo ([When to use volumes](https://docs.docker.com/engine/storage/volumes/#when-to-use-volumes)), y en particular, me interesa *Volumes can be more safely shared among multiple containers*. Gracias a esta posibilidad de ser compartidos entre múltiples contenedores, puedo usar un único volumen con la configuración que quiero en todos los *devcontainers* del mismo tipo. Y a la hora de actualizar, únicamente será necesario actualizar la configuración en el volumen.

### Crear el volumen

La creación del volumen no tiene misterio:

```console
docker volume create sidecar_gcloud
```

Del mismo modo, crearé otro volumen para Go llamado `sidecar_go`.

> He optado por el nombre de *sidecar* aunque se trate de un volumen, y no de un contenedor en sí, por el "concepto", no por lo que significa en K8s.

### Punto de montaje en el *devcontainer*

En la configuración del *devcontainer* (en el fichero `devcontainer.json`), indicamos cómo montar el volmen mediante dos parámetros:

- el nombre del volumen a montar
- el punto de montaje en el contenedor

En el fichero `devcontainer.json`:

```json
"mounts": [
"source=sidecar_gcloud,target=/sidecar/,type=volume,consistency=cached"
]
```

En el fichero `devcontainer.json` también especifico extensiones para VSCode, etc...

## Configurando el *devcontainer*

La [especificación de los devcontainers](https://containers.dev/implementors/spec/) permite ejecutar scripts en determinados momentos de la vida del *devcontainer*.

En vez de personalizar la imagen base, prefiero configurar el contenedor generado. Para ello, lanzo un script asociado al evento de `postCreate`, una vez que se ha creado el *devcontainer*.

Este script es simplemente un script que se encarga de mover/enlazar las herramientas/configuraciones que se encuentran en el *volumen* montado a la ubicación donde *deben estar*.

Por ejemplo, para que el autocompletado de Git funcione en el contenedor, tengo que añadir el fichero a `.bashrc`:

```console
echo "Git autocomplete"
grep --quiet --fixed-strings --line-regexp 'source /sidecar/completion/git.bash' "\$HOME/.bashrc" || echo 'source /sidecar/completion/git.bash' >> "\$HOME/.bashrc"
```

Para ejecutables como Jq, la solución es crear un enlace a `/usr/local/bin`:

```console
echo "Jq installation"
ln -s /sidecar/jq/jq /usr/local/bin/jq
jq --version
```

## `devcontainer init`

Ya tengo todas las piezas que necesito para conseguir lo que buscaba: ahora tengo que ponerlo todo junto.

Gracias al volumen, todas las herramientas y configuraciones adicionales que quiero para mi *devcontainer* están accesibles en el *devcontainer* en el punto de montaje  `/sidecar/`.

Esto simplifica el fichero `devcontainer.json`, que queda como:

```json
{
  "image": "gcr.io/google.com/cloudsdktool/google-cloud-cli",
  "runArgs": [
    "--platform=linux/amd64"
  ],
  "postCreateCommand": "bash .devcontainer/post_create_command.sh",
  "customizations": {
    "vscode": {
      "settings": {
        "extensions.verifySignature": false
      },
      "extensions": [
        "DavidAnson.vscode-markdownlint",
        "mhutchie.git-graph",
        "timonwong.shellcheck",
        "sdras.night-owl"
      ]
    }
  },
  "mounts": [
    "source=sidecar_gcloud,target=/sidecar/,type=volume,consistency=cached"
  ]
}
```

He decidido prescindir de la versión en la imagen base. No es relevante para lo que necesito en este caso (sí que lo es para Go, por ejemplo).
En cuanto a la plataforma, como Docker Desktop usa una máquina virtual que emula la arquitectura AMD64, así evito que `docker pull` descargue la versión ARM64 (la arquitectura de los Mac M#).

El script que se ejecuta en el evento *postCreate* lo sigo ubicando en la carpeta `.devcontainer/`, pero como se ejecuta **después** de que se haya creado el contenedor -y por tanto, montado el volumen-, quizás pueda moverlo también **dentro** del volumen...

A continuación, especifico las extensiones que quiero instaladas en el *devcontainer* y finalmente, monto el volumen *sidecar*.

Para conseguir mi requerimiento de ejecutar un comando y que se cree toda la configuración necesaria, de momento, uso un script llamado `init.sh`:

```console
#!/usr/bin/env bash
if [ ! -d .devcontainer ]; then
    mkdir .devcontainer
fi

cat > .devcontainer/devcontainer.json <<EOF
...
EOF

cat > .devcontainer/post_create_command.sh <<EOF
...
EOF

chmod +x .devcontainer/post_create_command.sh
```

Básicamente, crea la carpeta `.devcontainer/` si no existe, y a continuación crea tanto el fichero `devcontainer.json` como el script `post_create_command.sh` (y lo hace ejecutable).

Al colocar el script `init.sh` en el `$PATH`, puedo ejecutarlo desde cualquier carpeta y hacer que VSCode lance el *devcontainer* con la configuración lista al momento.

## Siguientes pasos

El primero es hacer que el script `init.sh` acepte un parámetro para especificar el tipo de configuración del *devcontainer*. Así, podré generar diferentes configuraciones de manera sencilla (por ahora, para `gcloud` y para `go`)

Teniendo el problema principal solucionado, de cara al futuro quiero desarrollar una herramienta para gestionar el contenido del volumen.
El volumen actual ha sido generado a mano, por lo que si se borra accidentalmente, tengo que recrearlo a mano desde cero.
Mi idea es automatizar la creación del script, de manera que se pueda regerar de forma automatizada en caso de desastre.
