+++
draft = false

# CATEGORIES = "dev"
categories = ["dev"]
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

title=  "KubeLinter: identifica malas configuraciones en los objetos de Kubernetes"
date = "2021-02-12T21:36:01+01:00"
+++
KubeLinter es un [*linter*](https://es.wikipedia.org/wiki/Lint) para los objetos de Kubernetes; es decir, KubeLinter comprueba configuraciones *sospechosas* en los ficheros de definición de los objetos de Kubernetes.

En la documentación oficial tienes una lista de las validaciones que realiza y cuáles vienen habilitadas por defecto: [KubeLinter checks](https://docs.kubelinter.io/#/generated/checks).

KubeLinter es una herramienta *opensource* desarrollada por StackRox, una empresa orientada a la seguridad que recientemente ha sido adquirida por Red Hat, precisamente, para mejorar la seguridad de OpenShift.
<!--more-->

Para usar KubeLinter, [descarga](https://github.com/stackrox/kube-linter/releases) la última versión disponible para tu plataforma.

Usarlo es tan sencillo como lanzar `kube-linter lint /ruta/al/fichero/yaml` (también permite analizar *Helm Charts*).

## Un ejemplo práctico

Crearemos un fichero YAML que contenga el *namespace* donde desplegaremos un Pod basado en `busybox`.

Los ficheros con la definición de los diferentes objetos se encuentran en la ruta `$YAML_FOLDER`.

La definición del *namespace* es:

```yaml
---
kind: Namespace
apiVersion: v1
metadata:
  name: jumpod
```

Lanzamos el análisis con `kube-linter`:

```bash
$ kube-linter lint $YAML_FOLDER
No lint errors found!
```

De momento, ¡todo ok!

Ahora pasamos a definir un Pod:

```yaml
---
kind: Pod
apiVersion: v1
metadata:
  name: jumpod
spec:
  containers:
    - name: busybox
      image: busybox
      command:
        - sleep
        - "3600"
      imagePullPolicy: IfNotPresent
  restartPolicy: Always
```

Repetimos el análisis, pero ahora el resultado no es bueno.

```bash
jumpod.yaml: (object: <no namespace>/jumpod /v1, Kind=Pod) container "busybox" does not have a read-only root file system (check: no-read-only-root-fs, remediation: Set readOnlyRootFilesystem to true in your container's securityContext.)

jumpod.yaml: (object: <no namespace>/jumpod /v1, Kind=Pod) container "busybox" is not set to runAsNonRoot (check: run-as-non-root, remediation: Set runAsUser to a non-zero number, and runAsNonRoot to true, in your pod or container securityContext. See https://kubernetes.io/docs/tasks/configure-pod-container/security-context/ for more details.)

jumpod.yaml: (object: <no namespace>/jumpod /v1, Kind=Pod) container "busybox" has cpu request 0 (check: unset-cpu-requirements, remediation: Set your container's CPU requests and limits depending on its requirements. See https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits for more details.)

jumpod.yaml: (object: <no namespace>/jumpod /v1, Kind=Pod) container "busybox" has cpu limit 0 (check: unset-cpu-requirements, remediation: Set your container's CPU requests and limits depending on its requirements. See https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits for more details.)

jumpod.yaml: (object: <no namespace>/jumpod /v1, Kind=Pod) container "busybox" has memory request 0 (check: unset-memory-requirements, remediation: Set your container's memory requests and limits depending on its requirements. See https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits for more details.)

jumpod.yaml: (object: <no namespace>/jumpod /v1, Kind=Pod) container "busybox" has memory limit 0 (check: unset-memory-requirements, remediation: Set your container's memory requests and limits depending on its requirements. See https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits for more details.)

Error: found 6 lint errors
```

## Ausencia de *requests* y *limits*

Tenemos cuatro errores similares:

```bash
(...) container "busybox" has cpu request 0
(...) container "busybox" has cpu limit 0
(...) container "busybox" has memory request 0
(...) container "busybox" has memory limit 0
```

Como podemos comprobar en el [enlace sugerido](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits) para corregir esta situación, debemos especificar *requests* y *limits* para el consumo de CPU y memoria del *pod*.

```yaml
---
kind: Pod
apiVersion: v1
metadata:
  name: jumpod
spec:
  containers:
    - name: busybox
      image: busybox
      command:
        - sleep
        - "3600"
      imagePullPolicy: IfNotPresent
      resources:
        requests:
          memory: "64Mi"
          cpu: "10m"
        limits:
          memory: "64Mi"
          cpu: "10m"
  restartPolicy: Always
```

Si analizamos de nuevo el fichero, estos cuatro errores deben haber desaparecido:

```bash
jumpod.yaml: (object: <no namespace>/jumpod /v1, Kind=Pod) container "busybox" does not have a read-only root file system (check: no-read-only-root-fs, remediation: Set readOnlyRootFilesystem to true in your container's securityContext.)

jumpod.yaml: (object: <no namespace>/jumpod /v1, Kind=Pod) container "busybox" is not set to runAsNonRoot (check: run-as-non-root, remediation: Set runAsUser to a non-zero number, and runAsNonRoot to true, in your pod or container securityContext. See https://kubernetes.io/docs/tasks/configure-pod-container/security-context/ for more details.)

Error: found 2 lint errors
```

## El contenedor no debe ejecutarse como *root*

```bash
(...) container "busybox" is not set to runAsNonRoot
```

De nuevo en el mensaje de salida de KubeLinter se proporciona un enlace donde consultar la solución en la documentación oficial de Kubernetes: [Set the security context for a Pod](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/).

```yaml
---
kind: Pod
apiVersion: v1
metadata:
  name: jumpod
spec:
  containers:
    - name: busybox
      image: busybox
      command:
        - sleep
        - "3600"
      imagePullPolicy: IfNotPresent
      securityContext:
        runAsUser: 1001
        runAsGroup: 1001
      resources:
        requests:
          memory: "64Mi"
          cpu: "10m"
        limits:
          memory: "64Mi"
          cpu: "10m"
  restartPolicy: Always
```

Además de especificar el UID del usuario con el que se ejecuta el contenedor, también especificamos el GID (`runAsGroup`) ya que si se omite el *group ID* primario será `root` (0).

Si analizamos la definición del Pod de nuevo:

```bash
$ kube-linter $YAML_FOLDER
jumpod.yaml: (object: <no namespace>/jumpod /v1, Kind=Pod) container "busybox" does not have a read-only root file system (check: no-read-only-root-fs, remediation: Set readOnlyRootFilesystem to true in your container's securityContext.)

Error: found 1 lint errors
```

> KubeLinter no devuelve errores relacionados con `runAsUser` incluso si se omite `runAsGroup`.

## Eliminando el aviso sobre `readOnlyRootFilesystem: true`

```bash
(...) )container "busybox" does not have a read-only root file system
(check: no-read-only-root-fs, remediation: Set readOnlyRootFilesystem
 to true in your container's securityContext.)
```

Tal y como indica la salida de KubeLinter, modificamos el fichero de definición del Pod para incluir la  opción `readOnlyRootFilesystem: true`:

```yaml
---
kind: Pod
apiVersion: v1
metadata:
  name: jumpod
spec:
  containers:
    - name: busybox
      image: busybox
      command:
        - sleep
        - "3600"
      imagePullPolicy: IfNotPresent
      securityContext:
        runAsUser: 1001
        runAsGroup: 1001
        readOnlyRootFilesystem: true
      resources:
        requests:
          memory: "64Mi"
          cpu: "10m"
        limits:
          memory: "64Mi"
          cpu: "10m"
  restartPolicy: Always
```

Comprobamos de nuevo con KubeLinter y confirmamos que hemos eliminado el último aviso relativo al sistema de ficheros del volumen raíz del contenedor.

```bash
$ kube-linter lint $YAML_FOLDER 
No lint errors found!
```

En este caso, **aunque el contenedor se ejecutara con el usuario *root*, no podría modificar los ficheros en el *root volume filesystem* porque lo hemos marcado como *readOnly***.

## Conclusión

KubeLinter ha identificado tres configuraciones que nos han permitido aplicar buenas prácticas en la definición de un Pod.

Definir las *requests* permite al *Scheduler* de Kubernetes desplegar el Pod en un nodo que disponga de como mínimo los recursos especificados. Además, al especificar los *limits* evitamos que un mal funcionamiento de la aplicación pueda consumir todos los recursos del clúster.

Esta simple configuración facilita que la aplicación disponga de los recursos que hemos identificado como necesarios para su correcto funcionamiento. Por otro lado, los límites nos aseguran que el clúster permanece estable y que un eventual mal comportamiento de algún Pod no afecta al resto.

Además, KubeLinter ha identificado dos configuraciones adicionales relativas a la seguridad: `runAsUser` y `readOnlyRootFilesystem`.

En la próxima entrada, [Seguridad en Kubernetes: runAsUser y readOnlyRootFilesystem]({{< ref "210212-runasuser-y-readonlyrootfilesystem.md" >}}) reviso con detalle los efectos de aplicar estas dos medidas.
