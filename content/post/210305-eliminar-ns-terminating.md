+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev", "ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["kubernetes"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/kubernetes.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}

title=  "Eliminar namespace encallado en Terminating"
date = "2021-03-05T17:53:31+01:00"
+++
Al hacer limpieza de uno de los clústers de desarrollo, he borrado dos *namespaces* y los dos se han quedado en estado *Terminating*

<!--more-->

```bash
k3os [~]$ k get ns
NAME                       STATUS        AGE
[...]
toolbox-argocd             Terminating   147d
toolbox-tekton-pipelines   Terminating   147d

```

He intentado varias cosas (incluso reiniciando la VM), pero los *namespaces* seguían sin eliminarse...

El problema es que hay "*algo*" que impide que el *namespace* se borre; puedes identificar ese *algo* lanzando un `kubectl get ns ${nombre_namespace} -o yaml` del *namespace* y buscando en la sección de `metadata.finalizers`.

```bash
[...]
metadata:
  finalizers:
  - controller.cattle.io/namespace-auth
[...]
```

Aunque no puedo borrar este elemento que bloquea el borrado del *Namespace*, sí que puedo **editar** el *Namespace* para **eliminar** el *finalizer*. Así Kubernetes cree que no hay nada que impida la eliminación del objeto.

Edito el objeto mediante `kubectl edit ns toolbox-argocd` y elimino la línea correspondiente a `- controller.cattle.io/namespace-auth`:

```bash
[...]
  finalizers:
[...]
```

Al guardar los cambios, compruebo de nuevo la lista de *Namespaces* para validar que el *Namespace* se ha borrado correctamente.
