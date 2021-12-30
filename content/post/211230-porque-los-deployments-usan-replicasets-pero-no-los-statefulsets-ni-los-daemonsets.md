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

title=  "¿Por qué los Deployments usan Replicasets pero los Statefulsets y los Daemonsets no?"
date = "2021-12-30T12:12:02+01:00"
+++
Revisando el *feed* del foro de Kubernetes [discuss.kubernetes.io](https://discuss.kubernetes.io/), me llamó la atención la pregunta de `user2` [Why deployment need replicaset, but daemonset and statefulset don’t need](https://discuss.kubernetes.io/t/why-deployment-need-replicaset-but-daemonset-and-statefulset-dont-need/18334).

[Respondí en el foro](https://discuss.kubernetes.io/t/why-deployment-need-replicaset-but-daemonset-and-statefulset-dont-need/18334/2?u=xavi), pero quiero ampliar la respuesta aquí.
<!--more-->
La pregunta me pareció interesante porque "nadie se fija" en los *ReplicaSets*; para desplegar un componente de la aplicación se usa, en general, un *Deployment*; en el *Deployment* especificamos el número de réplicas que queremos, lo aplicamos en el clúster y el sistema se encarga de que en todo momento tengamos tantos pods como hayamos especificados.

Fin de la historia.

Pero lo cierto es que, como se apunta en la pregunta, el *Deployment* -de hecho, su *controller*- genera un *ReplicaSet* y **es ahí donde se definen los pods que se crean** (los gestiona el *ReplicaSet controller*), no el *Deployment*.

Sin embargo, cuando en un *StatefulSet* especificamos varias réplicas, es el propio *StatefulSet* el que define los pods que se generan, sin necesidad de generar un *ReplicaSet* "intermedio". Algo "parecido" pasa con el *DaemonSet*, ya que aquí no definimos un número de réplicas, sino que se genera un pod en cada nodo -*compute*- del clúster.

Así que la pregunta es ¿porqué?

Voy a responder por partes...

## ¿Por qué los *StatefulSet* no requieren un *ReplicaSet*?

De la definición del [*ReplicaSet*](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/) en la documentación oficial de Kubernetes (las negritas son mías):

> El objeto de un ReplicaSet es el de mantener un conjunto estable de réplicas de Pods ejecutándose en todo momento. Así, se usa en numerosas ocasiones para garantizar la disponibilidad de un número específico de **Pods idénticos**.

Si comparamos con la definición del [*StatefulSet*](https://kubernetes.io/es/docs/concepts/workloads/controllers/statefulset/) (de nuevo, las negritas son mías):

> Gestiona el despliegue y escalado de un conjunto de Pods, y ***garantiza el orden y unicidad de dichos Pods***.
>
> Al igual que un Deployment, un StatefulSet gestiona Pods que se basan en una especificación idéntica de contenedor. **A diferencia de un Deployment, un StatefulSet mantiene una identidad asociada a sus Pods**. Estos pods se crean a partir de la misma especificación, pero no pueden intercambiarse; **cada uno tiene su propio identificador persistente** que mantiene a lo largo de cualquier re-programación.

La definición ya especifica que en el caso del *StatefulSet* los pods no son idénticos, aunque se generan a partir de una misma definición. Como los pods generados por el *StatefulSet* no son idénticos, no podrían gestionarse con un *ReplicaSet*.

## ¿Por qué los *DeamonSet* no requieren un *ReplicaSet*?

De nuevo, de la definición del [*DaemonSet*](https://kubernetes.io/es/docs/concepts/workloads/controllers/daemonset/) (las negritas son mías):

> Un DaemonSet garantiza que todos (o algunos) de los nodos ejecuten **una copia** de un Pod.

En este caso, tenemos una copia por nodo; las copias del *ReplicaSet* no están asociadas a un nodo en particular, por lo que, de nuevo, el *ReplicaSet* no es necesario para gestionar los pods del *DaemonSet*.

## ¿Por qué el *Deployment* **sí requiere** un *ReplicaSet*?

Hasta ahora nos hemos centrado en ver porqué el *StatefulSet* y el *DaemonSet* no usan un *ReplicaSet*. Pero ¿por qué el *Deployment* **sí lo requiere** (en vez de gestionar los pods directamente, como hacen los *StatefulSet* y los *ReplicaSet*)?

La respuesta corta es "por las actualizaciones".

Inicialmente, el encargado de gestionar las réplicas de un mismo pod era el [*ReplicationController*](https://kubernetes.io/es/docs/concepts/workloads/controllers/replicationcontroller/). Al realizar las [actualizaciones](https://kubernetes.io/docs/concepts/workloads/controllers/replicationcontroller/#rolling-updates), el proceso acordado era:

- generar un nuevo *ReplicationController*
- escalar hacia arriba (+1) un pod del *nuevo* *ReplicationController*
- escalar hacia abajo (-1) un pod del *ReplicationController* a reemplazar

Se repite el proceso hasta que se han reemplazado todos los pods del *ReplicationController* "antiguo" y se elimina el *ReplicationController* cuando quedan 0 pods. Para poder realizar la actualización, el *antiguo* y el *nuevo* *ReplicationController* debían diferenciarse **como mínimo** en una etiqueta.

Este proceso es robusto, porque permite ir validando que los pods del *nuevo* *ReplicationController* están listos para realizar tareas (a través de las *readiness probes*) o revertir el proceso si algo sale mal durante la actualización.

Además, es un proceso **automatizable**, de ahí que se definiera un nuevo objeto que incluyera esta capacidad de actualización.

Para no romper la compatibilidad hacia atrás, se creó un objeto diferente al *ReplicationController*:  el *ReplicaSet*. El "meta-objeto" que permite realizar las *rolling updates*, pasando de un *ReplicaSet* a otro, es el *Deployment*.

El *Deployment **Controller*** es el que se encarga de automatizar el escalado arriba y abajo de los diferentes *ReplicaSet* sin que sea necesario realizar la intervención manual, teniendo en cuenta los resultados de las *readiness probes* durante el proceso de actualización para garantizar que no hay pérdida de servicio.

## ¿Y cómo se actualizan los *StatefulSet* y los *DaemonSet* sin *ReplicaSet*?

Pues interrumpiendo el servicio; en el caso de las [Rolling updates - *StatefulSet*](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#rolling-updates):

> When a StatefulSet's `.spec.updateStrategy.type` is set to `RollingUpdate`, the StatefulSet controller will delete and recreate each Pod in the StatefulSet. It will proceed in the same order as Pod termination (from the largest ordinal to the smallest), updating each Pod one at a time.

Y de forma similar, para las [Rolling Update - *DaemonSets*](https://kubernetes.io/docs/tasks/manage-daemon/update-daemon-set/#daemonset-update-strategy):

> With `RollingUpdate` update strategy, after you update a DaemonSet template, old DaemonSet pods will be killed, and new DaemonSet pods will be created automatically, in a controlled fashion. At most one pod of the DaemonSet will be running on each node during the whole update process.
