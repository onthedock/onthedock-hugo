+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev", "ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "bash", "google-cloud", "workstation"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/bash.svg"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/
# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}

title=  "Google Cloud Workstation Manager - Un script para gestionar Cloud Workstations en Google Cloud"
date = "2024-11-02T17:21:51+01:00"
+++
[Cloud Workstations](https://cloud.google.com/workstations) nos permite tener la misma máquina a todos los miembros del equipo, independientemente de si usamos un Mac o un equipo con Windows.
Partiendo de una imagen de contenedor, podemos desplegar una máquina virtual y usar Code OSS (la versión *open source* de Visual Studio Code) con las mismas extensiones pre-instaladas, la misma configuración, etc...

Quiero presentar el *script* a mis compañeros antes de subirlo a Github, así que en la entrada de hoy me voy a centrar en explicar cómo he simplificado el número de parámetros requeridos para gestionar (crear/arrancar/detener/eliminar) una *workstation* sin tener que recordar (o conocer) el nombre del clúster, de la configuración usada, etc...
<!--more-->
El *script* en sí no es más que un *wrapper* para el grupo de comandos `gcloud workstations`, pero la idea es simplificar todo lo posible el proceso de interacción con la *workstation*.

Cualquiera de los comandos del grupo `workstations` de `gcloud` requiere parámetros que tienen valores difíciles de recordar, como el nombre del clúster o de la "configuración".
Por ejemplo, para *crear* una *workstatation* el comando [`create`](https://cloud.google.com/sdk/gcloud/reference/workstations/create) es:

```console
gcloud workstations create (WORKSTATION : --cluster=CLUSTER --config=CONFIG --region=REGION) [--async] [--env=[KEY=VALUE,…]] [--labels=[KEY=VALUE,…]] [GCLOUD_WIDE_FLAG …]
```

En nuestro caso, tenemos un proyecto dedicado a la Cloud Workstations, por lo que necesitaremos especificar el *project_id* (como mínimo).

Cada miembro del equipo tienen una *workstation* "personal", por lo que para que hemos acordado denominarlas `workstation-<nombre>`.
Esto hace que sea sencillo identificar a quién pertenece cada una de las *workstations*.

Todas las *wokstations* están gestionadas como elementos de un mismo [clúster](https://cloud.google.com/workstations/docs/quickstart-set-up-workstations-console#create_a_workstation_cluster).
Cada "tipo" de *workstation* está definida a través de una [*configuración*](https://cloud.google.com/workstations/docs/create-configuration).
Esta *configuration* es una plantilla a partir de la cual instanciar una *Cloud Workstation* en un clúster determinado.

Todos estos recursos ya existen, por lo que el *script* no comprueba si están presentes o no.

## Work smarter, not harder

Como puede verse en la imagen que indica cómo crear una nueva configuración, la **configuration** contiene toda la información necesaria para ejectuar los comandos del grupo `workstations`:

{{< figure src="/images/241102/console-configurations-page-create-button.png" width="100%" caption="De la documentación oficial <https://cloud.google.com/workstations/docs/create-configuration>" >}}

Es decir, tenemos el nombre de la configuración, el nombre del clúster y su ubicación.
Pero como queremos obtener la información desde un *script* y no desde la consola, usaremos `gcloud workstations configurations list` para obtener la lista de configuraciones (en formato JSON).

En nuestro caso, como en la imagen de la documentación, tenemos varias configuraciones disponibles, por lo que tenemos que indicar qué configuración es la que queremos usar para, por ejemplo, crear unan nueva *workstation*. Desgraciadamente, no tenemos una nomenclatura que permita identificar de forma tan sencilla como en la imagen de la documentación de Google qué configuración es la que debemos seleccionar.

Así que lo que uso para filtrar cuál es la configuración correcta es que la imagen base del contenedor está etiquetada como `stable`.

Por tanto, lo primero que hace el *script* es listar las configuraciones e inspeccionar la propiedad `container.image`:

```console
gcloud workstations configs list --project="$project_id" --format="json" | \
  jq -r '.[] | select( .container.image | contains ("stable") ) | .name' > $tmpfile
```

La propiedad `name` de la configuración, según la [documentación](https://cloud.google.com/workstations/docs/customize-development-environment#resource:-workstationconfig) es un `string`; sin embargo, inspeccionando el *formato* de ese *string*, vemos que tiene es de la forma:

```console
projects/<project_id>/locations/<region>/workstationClusters/<cluster_name>/workstationConfigs/<config_name>
```

Así que, como vemos, podemos extraer información sobre la *región*, el nombre del *clúster* y el nombre de la *configuration* (que corresponde a la imagen base etiquetada como `stable`).

A partir de aquí, usamos `awk` para extraer la información que necesitamos, como en:

```console
region=$(awk -F '/' '{ print $4}' $tmpfile)
```

De esta forma, volviendo al comando `create` que usaba más arriba como ejemplo, tenemos la información relativa al clúster, la configuración y la región.
Estos son los parámetros "difíciles de recordar", por lo que el resto (excepto el *project_id*), los puede facilitar el usuario como parámetro a través de la CLI.

Para simplificar todavía más el uso del *script*, si alguno de los parámetros requridos no se proporciona como parámetro, el *script* pregunta al usuario y espera una respuesta; si ésta está vacía, el *script* finaliza.

Esta estrategia se sigue para el *nombre* de la *workstation* (de la que el usuario sólo tiene que proporcionar su nombre, que debería conocer 😉), y el ID del proyecto.

Si se proporciona la dirección de correo del usuario a través de la variable de entorno `USER_EMAIL`, se realizan algunas configuraciones en la *workstation* para configurar algunas herramientas preinstaladas, por lo que queremos que esté configurada.

Aunque se puede pasar la dirección de correo mediante el *flag* `-e`, el *script* intenta obtenerlo automáticamente de la configuración global de Git, mediante:

```console
email=$(git config user.email 2>/dev/null)
```

Si, en cualquier caso, `$email` está vacío, también se solicita al usuario que lo proporcione de manera interactiva durante la ejecución del *script*:

```console
gcloud workstations create "workstation-$name" \
       --cluster="$cluster" \
       --config="$configuration" \
       --region="$region" \
       --env="USER_EMAIL=$email" \
       --project="$project_id"
```

De esta forma, de todos los parámetros necesario, el usuario sólo debe proporcionar desde la CLI su nombre y el `project_id`.

En base al *feedback* que me proporcione el resto del equipo, quizás podamos incluso eliminar la necesidad de proporcionar el *nombre* desde la CLI, quizás obteniéndolo desde la dirección de correo, por ejemplo.

## Resumen

`workstation_manager.sh` es un pequeño *script* en Bash que permite gestionar Cloud Workstations de forma sencilla para el usuario, sin necesidad de conocer *detalles de implementación* como el nombre de la configuración, el del clúster, la región en la que se encuentra, etc...

El objetivo del *script* es *ocultar* estos detalles al máximo para que el usuario sólo tenga que proporcionar la información relativa a **su** Cloud Workstation, información que tenga sentido para el usuario y que le sea fácil recordar (o conseguir).
