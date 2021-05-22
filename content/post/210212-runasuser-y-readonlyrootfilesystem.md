+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["kubernetes", "kubelinter"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/kubernetes.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}

title=  "Seguridad en Kubernetes: runAsUser y readOnlyRootFilesystem"
date = "2021-02-12T23:02:05+01:00"
+++
En la entrada anterior [KubeLinter: identifica malas configuraciones en los objetos de Kubernetes]({{< ref "210212-kubelinter.md" >}}), KubeLinter identificaba dos errores que se solucionan usando las opciones: `runAsUser` y `readOnlyRootFilesystem`.

En esta entrada comparo los efectos de aplicar una u otra, así como qué pasa cuando se aplican las dos al mismo tiempo.
<!--more-->

La definición del Pod es:

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

Al analizar este fichero de definición con KubeLinter, obtenemos los errores:

```bash
jumpod.yaml: (object: <no namespace>/jumpod /v1, Kind=Pod) container "busybox" does not have a read-only root file system (check: no-read-only-root-fs, remediation: Set readOnlyRootFilesystem to true in your container's securityContext.)

jumpod.yaml: (object: <no namespace>/jumpod /v1, Kind=Pod) container "busybox" is not set to runAsNonRoot (check: run-as-non-root, remediation: Set runAsUser to a non-zero number, and runAsNonRoot to true, in your pod or container securityContext. See https://kubernetes.io/docs/tasks/configure-pod-container/security-context/ for more details.)

Error: found 2 lint errors
```

Filtrando la salida anterior:

```bash
(...) container "busybox" does not have a read-only root file system (...)

(...) container "busybox" is not set to runAsNonRoot (...)
```

El primer aviso apunta a que la solución pasa por especificar un *root file system* en modo lectura. El segundo hace referencia al usuario con el que se ejecuta el contenedor (que no debería ser el usuario *root*).

Para solucionar el primer error, especificamos `readOnlyRootFilesystem: true` y para el segundo, especificamos `runAsUser: 1001`:

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

## Comparando el efecto de estas opciones

### Primer caso: `runAsUser: 1001`

Abrimos una *shell* en el Pod desplegado con el YAML donde se indica que el contenedor debe ejecutarse como usuario 1001:

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
        # readOnlyRootFilesystem: true
      resources:
        requests:
          memory: "64Mi"
          cpu: "10m"
        limits:
          memory: "64Mi"
          cpu: "10m"
  restartPolicy: Always
```

```bash
kubectl exec -it pod/jumpod -n jumpod -- /bin/sh
```

En el Pod:

```bash
/ $ whoami
whoami: unknown uid 1001
```

Si revisamos a qué tiene acceso el usuario en el contenedor, vemos que sólo tiene permisos para escribir en `/tmp`, mientras que en el resto sólo tiene permisos de lectura y de ejecución: `drwxr-xr-x` (el propietario es `root`):

```bash
/ $ ls -lah
total 44K    
drwxr-xr-x    1 root     root        4.0K Feb 12 18:47 .
drwxr-xr-x    1 root     root        4.0K Feb 12 18:47 ..
drwxr-xr-x    2 root     root       12.0K Feb  1 19:44 bin
drwxr-xr-x    5 root     root         360 Feb 12 18:47 dev
drwxr-xr-x    1 root     root        4.0K Feb 12 18:47 etc
drwxr-xr-x    2 nobody   nobody      4.0K Feb  1 19:44 home
dr-xr-xr-x  368 root     root           0 Feb 12 18:47 proc
drwx------    2 root     root        4.0K Feb  1 19:44 root
dr-xr-xr-x   13 root     root           0 Feb 12 18:47 sys
drwxrwxrwt    1 root     root        4.0K Feb 12 18:50 tmp
drwxr-xr-x    3 root     root        4.0K Feb  1 19:44 usr
drwxr-xr-x    1 root     root        4.0K Feb 12 18:47 var
/ $ touch /tmp/test
/ $ ls /tmp/
/tmp/test
```

El usuario con `uid: 1001` tiene permisos sobre `/tmp` y puede crear ficheros en esa carpeta. En el resto, no tiene permisos de escritura.

### Segundo caso: `readOnlyRootFilesystem: true`

En el segundo caso, si especficamos la opción `readOnlyRootFilesystem: true`, el usuario con el que se ejecutar el Pod es `root`:

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
        #runAsUser: 1001
        #runAsGroup: 1001
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

```bash
/ # whoami
root
```

Aunque el usuario tiene permisos de escritura sobre el sistema de ficheros del Pod, cuando intentamos crear un fichero:

```bash hl_lines="5 15 16 17"
/ # ls -lah
total 44K
drwxr-xr-x    1 root     root        4.0K Feb 12 19:17 .
drwxr-xr-x    1 root     root        4.0K Feb 12 19:17 ..
drwxr-xr-x    2 root     root       12.0K Feb  1 19:44 bin
drwxr-xr-x    5 root     root         360 Feb 12 19:17 dev
drwxr-xr-x    1 root     root        4.0K Feb 12 19:17 etc
drwxr-xr-x    2 nobody   nobody      4.0K Feb  1 19:44 home
dr-xr-xr-x  375 root     root           0 Feb 12 19:17 proc
drwx------    2 root     root        4.0K Feb  1 19:44 root
dr-xr-xr-x   13 root     root           0 Feb 12 19:17 sys
drwxrwxrwt    2 root     root        4.0K Feb  1 19:44 tmp
drwxr-xr-x    3 root     root        4.0K Feb  1 19:44 usr
drwxr-xr-x    1 root     root        4.0K Feb 12 19:17 var
/ # touch /bin/test
touch: /bin/test: Read-only file system
```

### Tercer caso: `runAsUser: 1001` y `readOnlyRootFilesystem: true`

Si desplegamos un Pod en el que especificamos un usuario no-root (`uid: 1001`) y además un **sistema de ficheros de sólo lectura**:

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

```bash  hl_lines="2 14 17 18"
/ $ whoami
whoami: unknown uid 1001
/ $ ls -lah
total 44K    
drwxr-xr-x    1 root     root        4.0K Feb 12 19:33 .
drwxr-xr-x    1 root     root        4.0K Feb 12 19:33 ..
drwxr-xr-x    2 root     root       12.0K Feb  1 19:44 bin
drwxr-xr-x    5 root     root         360 Feb 12 19:33 dev
drwxr-xr-x    1 root     root        4.0K Feb 12 19:33 etc
drwxr-xr-x    2 nobody   nobody      4.0K Feb  1 19:44 home
dr-xr-xr-x  373 root     root           0 Feb 12 19:33 proc
drwx------    2 root     root        4.0K Feb  1 19:44 root
dr-xr-xr-x   13 root     root           0 Feb 12 19:33 sys
drwxrwxrwt    2 root     root        4.0K Feb  1 19:44 tmp
drwxr-xr-x    3 root     root        4.0K Feb  1 19:44 usr
drwxr-xr-x    1 root     root        4.0K Feb 12 19:33 var
/ $ touch /tmp/test
touch: /tmp/test: Read-only file system
```

En este caso, aunque el usuario `uid: 1001` tiene permisos de escritura en `/tmp`, como el sistema de ficheros es *readOnly*, **no puede escribir en el sistema de ficheros**.

## Conclusión

Configurar el *root volume filesystem* como sólo lectura es la opción que puede tener un mayor impacto en el funcionamiento de la aplicación. Al activar esta configuración ningún usuario (incluyendo al usuario *root*) puede escribir en el sistema de ficheros raíz.

Si especificamos sólo `readOnlyRootFilesystem: true` el contenedor sigue ejecutándose como *root*, lo que va en contra de las buenas prácticas. Por tanto, también es recomendable usar la opción de `runAsUser` para usar un usuario con menos privilegios.

Una solución de compromiso podría ser usar sólo `runAsUser` con un usuario no *root*; de esta forma el sistema de permisos de Linux permite limitar dónde puede escribir el proceso iniciado por el usuario indicado, mientras que permite el acceso a carpetas como `/tmp` que algunos procesos pueden utilizar por defecto.
