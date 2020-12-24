+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["kubernetes"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/kubernetes.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" %}}

title=  "Cómo saber si un recurso de Kubernetes está restringido al namespace o es global"
date = "2020-12-24T11:39:07+01:00"
+++
La mayoría de los recursos de Kubernetes como los *pods*, los *services*, los *replication controllers*, etc están limitados al *namespace* en el que se despliegan. Así, dos recursos pueden tener el mismo nombre, etc si se encuentran en *namespaces* diferentes, ya que el *namespace* define el *alcance* de visibilidad para el recursos. El *namespace* es el límite del *scope* del recurso en Kubernetes.

Sin embargo, no todos los recursos en Kubernetes se encuentran "limitados" por el *namespace*; por ejemplo, el propio recurso `namespace` no está en un *namespace*, ni los `persistentVolumes` tampoco...

¿Cómo podemos obtener una lista de los recursos con alcance restringido al *namespace* en el que se encuentran?
<!--more-->

En la documentación oficial Kubernetes sobre los *Namespaces*, encontramos cómo obtener esta lista en la sección [Not All Objects are in a Namespace](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/#not-all-objects-are-in-a-namespace)

Los recursos limitados a un *namespace* son:

```bash
# In a namespace
kubectl api-resources --namespaced=true
```

Para los que no:

```bash
# In a namespace
kubectl api-resources --namespaced=false
```

## Establecer un *namespace* por defecto

Es una buena práctica especificar **siempre** el *namespace* en los comandos que se ejecutan para evitar errores... Es tan sencillo como incluir el parámetro `-n <nombre-namespace>` en cualquier comando:

```bash
$ kubectl get pods -n toolbox-gitea
NAME                     READY   STATUS    RESTARTS   AGE
gitea-59db876d4f-bqm5f   1/1     Running   1          16h
```

Si embargo, es fácil *despistarse* y no incluirlo, lo que puede resultar fatal; por ejemplo, en un comando del tipo `kubectl apply -f <definicion-de-recursos.yaml>`.

Para evitar este tipo de errores, podemos establecer el *namespace por defecto* para todos los comandos siguiendo las instrucciones de la documentación oficial [Setting the namespace preference](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/#setting-the-namespace-preference)

```bash
kubectl config set-context --current --namespace=<insert-namespace-name-here>
# Validate it
kubectl config view --minify | grep namespace:
```

## El origen de mi duda al respecto del alcance de los recursos en Kubernetes

En el caso de los volúmenes interaccionan elementos "globales" (no restringidos a un *namespace*) como los `persistentVolume`, la `storageClass` y los `volumeattachments` con los `persistentVolumeClaim` que **sí que están en un *namespace***.

Si al crear la definición del `persistentVolumeClaim` no se especifica el *namespace*, se crea por defecto en el *namespace* `default`. Para que el *claim* pueda ser *montado* en un *pod*, es necesario que tanto el *pod* como el *claim* se encuentren en el mismo *namespace*. Esto es así porque tanto el *pod* como el *persistentVolumeClaim* están "namespaciados".

En mi caso el error fue que incluí en el mismo fichero YAML la definición del PV y del PVC, que después apliqué mediante `kubectl apply -f fichero.yaml` (sin especificar el *namespace* en `.metadata.namespace` o mediante `-n <nombre-namespace>`).

Al crear el *pod* que debía usar el volumen especificado en el *claim*, se quedaba en estado *pending* y al revisar los logs, observé que era porque no se podía montar el volumen.

La salida del comando `kubectl get pv -n <namespace>` mostraba que el volumen estaba disponible, así que no entendía porqué no se realizaba el *binding*...

El **fallo** es que los `persistentVolume` son globales, por lo que son visibles desde todos los *namespaces*... De hecho, parece que el parámetro `-n` se ignora para estos elementos; puedes probar usando el nombre de un *namespace* que no exista:

```bash
$ kubectl get pv -n safhadlkfhjaldskfjasd
NAME                                CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                              STORAGECLASS   REASON   AGE
gitea-volume                        10Gi       RWO            Retain           Bound    toolbox-gitea/gitea-volume-claim   manual                  12d
docker-registry-persistent-volume   10Gi       RWO            Retain           Bound    registry/docker-registry-storage   manual                  12h
```

Como puede observarse en la salida del comando `kubectl gt pv`, en la columna `CLAIM`, el nombre del *claim* sí que aparece precedido del nombre del *namespace* en el que se encuentra.

Así, el problema era que el *pod* estaba en un *namespace* pero el *claim*, al no haber especificado ningún *namespace*, se encontraba en el *namespace*  `default`.
