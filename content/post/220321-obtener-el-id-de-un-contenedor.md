+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "kubernetes"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/kubernetes.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/

# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}
# YouTube           {{< youtube w7Ft2ymGmfc >}}
# Gist              {{< gist username 7896402 >}}
# Highlight         {{< highligth language >}}...{{< /highlight >}}
# Twitter           {{< tweet user="SanDiegoZoo" id="1453110110599868418" >}}

title=  "Obtener el ID de un contenedor #discuss.kubernetes.io"
date = "2022-03-21T22:14:17+01:00"
+++
Estaba leyendo las nuevas entradas en el foro de Kubernetes y me he encontrado con [Getting Pod ID and container ID of a container when it restarts](https://discuss.kubernetes.io/t/getting-pod-id-and-container-id-of-a-container-when-it-restarts/19413).

La pregunta es cómo obtener el identificador de un *pod* (y de un contenedor dentro del *pod*) cuando éste se reinicia. Lo curioso -al menos para mí- es que esa información es necesaria porque hay *otro pod* que monitoriza el primero que necesita esta información (supondo que para identificar el *pod* monitorizado).
<!--more-->

En la pregunta falta mucho contexto, pero no acabo de entender para qué es necesario conocer el *containerID* de un contenedor dentro de un pod para poder monitorizarlo. Aún en el caso de tener que monitorizar un *pod* específico (o un contenedor específico), quizás sería una mejor opción usar algo como una etiqueta que identifique el *pod* a monitorizar... Asumo que se trata de un único *pod*, pero incluso siendo múltiples *pods* -presumiblemente creados por un *Deployment*- parece más sencillo usar una etiqueta para identificar qué *pods* deben monitorizarse.

Por otro lado, ¿qué es lo que se monitoriza? Comprobar que el *pod* está en ejecución no garantiza que la aplicación *dentro* esté fallando por algún motivo... Para validar que la aplicación funciona como debe se pueden definir *readiness* y *heath probes*...

En cualquier caso, la propia extrañeza del requerimiento me ha hecho pensar en qué identificadores únicos se pueden usar para un *pod* y para un contenedor...

> He descubierto que el Deployment Controller añade la etiqueta [`pod-template-hash`](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#pod-template-hash-label) a los *pods* creados y que ese valor se usa como parte del nombre de los *pods* gestionados por el ReplicaSet. El valor de `pod-template-hash` es una cadena aleatoria.

Obtener el identificador de un *pod* puede referirse a varias cosas; por un lado, tenemos el nombre del *pod*, que lo identifica de forma unívoca... Usando únicamente `kubectl`:

```bash
$ kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o jsonpath='{ .items[].metadata.name }'
argocd-server-bff55c87-6sld4
```

Cada *pod* tiene un identificador único `uid`:

```bash
$ kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o json | jq -r '.items[].metadata.uid'
0e486b81-8e5d-4e61-adcf-3febfd61c9c5
```

En estos ejemplos, sólo tenemos un *pod* que encaje con la etiqueta que usamos para filtrar, pero si tuviéramos varios *pods*, la expresión funciona del mismo modo:

```bash
$ kubectl get pods -n longhorn-system -l app=csi-snapshotter -o json | jq -r '.items[].metadata.uid'
337b5202-ac4f-4531-b8c9-c87c1de05ef6
49e9cec6-82c7-4889-aa0b-fdb960673f50
43fe7d09-791f-4076-9565-f98a27e4033f
```

Pero la pregunta en el foro hacía referencia al *containerID*. Esto me resulta todavía más extraño; al fin y al cabo, el *containerID* es algo que sólo necesita conocer el *container engine*, pero que a nivel de aplicación es completamente irrelevante...

En cualquier caso, le *he dado una vuelta* y he creado un *script* en plan *quick & dirty* que obtiene el *containerID* cada vez que el contenedor se reinicia:

```bash
#!/usr/bin/env bash
set -e

if [ -z "$KUBECONFIG" ]
then
    printf "\$KUBECONFIG not set.\n"
    exit 1
fi

pod_label="$1"
pod_namespace="$2"
wait_seconds=4
last_container_id=""

get_container_id() {
    echo $(kubectl get pods -l "app.kubernetes.io/name=${pod_label}" -n "${pod_namespace}" -o json | jq -r '.items[].status.containerStatuses[].containerID' | tr -d 'containerd://')
}

printf 'Watching namespace "%s" (with label "%s") ... \n' "${pod_namespace}" "${pod_label}"

while true
do
    container_id=$(get_container_id)
    # printf "ContainerID: %s\n" "$container_id"
    if [[ "$container_id" != "$last_container_id" ]]
    then
        printf "ContainerID: %s\n" "$container_id"
        last_container_id="${container_id}"
    fi
    sleep "${wait_seconds}"
done
```

El *script* usa `kubectl` y el fichero de configuración para conectar al clúster y obtener el *containerID* del *pod* (o *pods*) que coinciden con una determinada etiqueta. A partir de ahí, obtiene los *containerID* usando `jq`.

Al ejecutar el *script*, indicamos la etiqueta (para filtrar los *pods*) y el *namespace* en el que se encuentran:

```bash
$ ./pod_id.sh "argocd-server" "argocd"
Watching namespace "argocd" (with label "argocd-server") ... 
ContainerID: 21281939115633b63455b13b6079528b37f904f9ffb268b190bf0
```

El *script*, que se ejecuta en un bucle infinito, muestra el *containerID* y comprueba periódicamente si el valor del *containerID* del contenedor en ejecución es diferente al *containerID* guardado (del anterior *check*); el *script* sólo actualiza la salida si el *containerID* cambia.

Forzando el reinicio mediante:

```bash
$ kubectl -n argocd rollout restart deployment argocd-server
deployment.apps/argocd-server restarted
```

El *script* se actualiza como estaba previsto, pero tarde un par de iteraciones en mostrar el *containerID* del nuevo contenedor (corriendo en el nuevo *pod*):

```bash
$ ./pod_id.sh "argocd-server" "argocd"
Watching namespace "argocd" (with label "argocd-server") ... 
ContainerID: 21281939115633b63455b13b6079528b37f904f9ffb268b190bf0
ContainerID: 21281939115633b63455b13b6079528b37f904f9ffb268b190bf0 ull
ContainerID: 08047900167b20192704669334768182f825281777f540
```

Para eliminar estos *efecto transitorio* quizás lo más sencillo sería aumentar el tiempo que espera el *script* entre una comprobación y la siguiente del valor del *containerID*...

En cualquier caso, espero que [mi respuesta](https://discuss.kubernetes.io/t/getting-pod-id-and-container-id-of-a-container-when-it-restarts/19413/2?u=xavi) sirva de ayuda.
