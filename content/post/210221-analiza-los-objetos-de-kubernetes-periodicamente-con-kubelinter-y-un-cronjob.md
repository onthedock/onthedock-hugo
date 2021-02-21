+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["kubernetes", "kubelinter"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/kubernetes.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" %}}

title=  "Analiza los objetos de Kubernetes con Kubelinter y Cronjobs"
date = "2021-02-21T12:08:02+01:00"
+++
Idealmente, el análisis de los ficheros de definición de objetos (YAML) en Kubernetes debería realizarse **antes** de crear los objetos en el clúster. Para ello, uno de los *stages* del proceso de CI/CD debería incorporar KubeLinter (por ejemplo).

De forma paralela, también deberíamos tener un proceso periódico que revise los ficheros de definición de los objetos que tenemos almacenados en el repositorio para identificar, por ejemplo, el uso de versiones de la API desaconsejadas (*deprecated*) en proceso de eliminación de la API.

En este artículo vemos cómo configurar un Cronjob que ejecute KubeLinter para obtener los ficheros de un repositorio remoto y analizarlos.
<!--more-->

## Crear una imagen base con KubeLinter y Git

Usamos como referencia el `Dockerfile` del usuario `cwadley` en DockerHub para crear una imagen con Git y KubeLinter basada en Alpine:

```Dockerfile
# Thanks to https://hub.docker.com/r/cwadley/kube-linter/dockerfile
FROM alpine:3.13
RUN apk add git
RUN wget https://github.com/stackrox/kube-linter/releases/download/0.1.6/kube-linter-linux.tar.gz && \
    tar -xzf kube-linter-linux.tar.gz && \
    mv kube-linter /usr/local/bin && \
    rm kube-linter-linux.tar.gz
ENTRYPOINT ["kube-linter"]
```

Subimos la imagen al repositorio en DockerHub: [xaviaznar/kubelinter:v0.1.6-git](https://hub.docker.com/r/xaviaznar/kubelinter/tags?page=1&ordering=last_updated) (la imagen con etiqueta `v0.1.6` no incorpora Git).

Como sempre, creamos un *namespace* para aislar las pruebas que realizamos; en este caso, llamo al *namespace* `cronjobs`:

```yaml
---
kind: Namespace
apiVersion: v1
metadata:
  name: cronjobs
```

Creamos un *PersistentVolumeClaim* en el que clonar el repositorio remoto para que KubeLinter lo analice.
Esto es necesario porque el volumen raíz del contenedor se configura como *read only*.

> Debes ajustar el tamaño del volumen en función del tamaño en disco del repositorio a analizar, aunque puedes usar opciones como `--depth=1` para clonar únicamente el último *commit* y no toda la historia del repositorio.

```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: volume-repo
  namespace: cronjobs
spec:
  resources:
    requests:
      storage: 50Mi
  accessModes:
    - ReadWriteOnce
```

El siguiente paso es crear un *ConfigMap* para el *script* que se encarga de clonar el repositorio remoto y lanzar `kube-linter`:

```yaml
---
kind: ConfigMap
apiVersion: v1
metadata:
  name: script
  namespace: cronjobs
data:
  linter.sh: |
    #!/bin/sh
    localPath="/repo"

    if [ -d $localpPath ] && [ ! "$(ls -A $localPath)" ]
    then
      git clone --depth=1 --verbose $1 $localPath
    else
        cd $localPath
        echo "[INFO] Fetching $1"
        git fetch --verbose origin $2
        
        localHEAD=$(git rev-parse --short HEAD)
        remoteHEAD=$(git rev-parse --short origin/$2)

        echo "[INFO] localHEAD=$localHEAD remoteHEAD=$remoteHEAD"

        if [ "$localHEAD" != "$remoteHEAD" ]
        then
            echo "Merging FETCH_HEAD"
            git merge --verbose FETCH_HEAD
        else
            echo "[INFO] Local copy in sync with remote. Not updated"
        fi
    fi

    kube-linter lint $localPath
```

El *script* clona el repositorio remoto en el volumen reclamado anteriormente con el *PersistentVolumeClaim* si no existe o lo actualiza si existe (y si es necesario).

> Una mejora para el *script* sería clonar una rama específica (diferente a `master/main`), por ejemplo, mediante `git clone --branch ${nombre-rama} ${repo-url}`.

Tras realizar la actualización, el *script* lanza `kube-linter lint` para analizar el contenido del repositorio en la ubicación definida en `$localPath`.

> Puedes ajustar la ruta a donde apunta `kube-linter` para realizar el análisis si los ficheros YAML no se encuentran en la raíz del repositorio.

## Cronjob

Ya tenemos todas las piezas necesarias para crear el *Cronjob*:

```yaml
---
kind: CronJob
apiVersion: batch/v1beta1
metadata:
  name: kubelinter-repo-testkubelinter
  namespace: cronjobs
spec:
  #suspend: true
  schedule: '*/1 * * * *'
  jobTemplate:
    spec:
      backoffLimit: 0 # Do not retry when it fails
      template:
        metadata:
          creationTimestamp: null
        spec:
          containers:
          - name: kubelinter
            image: xaviaznar/kubelinter:v0.1.6-git
            imagePullPolicy: IfNotPresent
            command:
              - /script/linter.sh
            args:
              - "https://github.com/onthedock/testkubelinter.git"
              - "main"
            securityContext:
              runAsUser: 1001
              runAsGroup: 1001
              readOnlyRootFilesystem: true
            resources:
              requests:
                memory: "128Mi"
                cpu: "0.1"
              limits:
                memory: "512Mi"
                cpu: "0.5"
            volumeMounts:
              - name: repo
                mountPath: /repo
              - name: linter
                mountPath: /script
          restartPolicy: Never
          volumes:
            - name: repo
              persistentVolumeClaim:
                claimName: volume-repo
            - name: linter
              configMap:
                name: script
                defaultMode: 0777
```

Especificamos una periodicidad mediante `schedule: '*/1 * * * *'` (en este caso, cada minuto, para hacer pruebas) y en la plantilla del *job*, usamos la imagen con KubeLinter.

Especificamos el comando a ejecutar, pasando como argumentos la URL del repositorio (público) y el nombre de la rama principal. Montamos el *script* como un volumen de tipo *ConfigMap* y el *PersistentVolumeClaim* como almacenamiento de los pods creados en las diferentes ejecuciones del CronJob.

### Problemas de permisos para ejecutar el *script*

Durante las pruebas obtenía errores de acceso denegado al ejecutar el *script* `/script/linter.sh`. Por ello fue necesario especificar `defaultMode: 0777` para poder proporcionar acceso al usuario con el que se ejecuta el Pod sobre el *script* montado a partir del *ConfigMap*.

### Evitar el reintento de ejecución del Job

KubeLinter finaliza con *exit code 1* (error) si detecta fallos en alguno de los ficheros YAML analizados. Por defecto, Kubernetes está configurado para reinitentar un Job fallido (hasta 6 veces), lo que generaba múltiples ejecuciones del job.

El fallo del Job refleja la detección de errores por parte de KubeLinter al analizar los ficheros YAML del repositorio. No significa que la ejecución del Job ha fallado, por lo que es el comportamiento deseado/esperado.

Para evitar que Kubernetes reintente la ejecución del Job, especificamos `spec.jobTemplate.spec.backoffLimit: 0` (para la definición del CronJob) y `spec.jobTemplate.spec.template.spec.restartPolicy: Never`.

En los logs del Pod creado durante la ejecución del CronJob podemos observar las acciones que realiza el *script*.

En caso de error, por ejemplo:

```bash
$ kubectl get pods -n cronjobs
NAME                                              READY   STATUS      RESTARTS   AGE
kubelinter-repo-testkubelinter-1613909820-r9jrq   0/1     Error       0          47m
```

## Resultado del análisis con KubeLinter

Revisando logs logs del contenedor creado por la ejecución del CronJob:

```bash
$ kubectl -n cronjobs logs pod kubelinter-repo-testkubelinter-1613909820-r9jrq

[INFO] Fetching https://github.com/onthedock/testkubelinter.git
POST git-upload-pack (294 bytes)
POST git-upload-pack (260 bytes)
From https://github.com/onthedock/testkubelinter
* branch main -> FETCH_HEAD
ce96888..6382485 main -> origin/main
[INFO] localHEAD=ce96888 remoteHEAD=6382485
Merging FETCH_HEAD
Updating ce96888..6382485
Fast-forward
cronojb-kubnelinter.yaml | 7 +++++++
1 file changed, 7 insertions(+)
/repo/cronojb-kubnelinter.yaml: (object: cronjobs/kubelinter-repo-testkubelinter batch/v1beta1, Kind=CronJob) container "kubelinter" does not have a read-only root file system (check: no-read-only-root-fs, remediation: Set readOnlyRootFilesystem to true in your container's securityContext.)

/repo/cronojb-kubnelinter.yaml: (object: cronjobs/kubelinter-repo-testkubelinter batch/v1beta1, Kind=CronJob) container "kubelinter" is not set to runAsNonRoot (check: run-as-non-root, remediation: Set runAsUser to a non-zero number, and runAsNonRoot to true, in your pod or container securityContext. See https://kubernetes.io/docs/tasks/configure-pod-container/security-context/ for more details.)

Error: found 2 lint errors
```

Y en caso de que los ficheros de definición de los objetos no contengan errores, el Job acaba como "Completed":

```bash
$ kubectl get pods -n cronjobs
NAME                                              READY   STATUS      RESTARTS   AGE
kubelinter-repo-testkubelinter-1613909820-r9jrq   0/1     Error       0          47m
kubelinter-repo-testkubelinter-1613909880-2fkbg   0/1     Completed   0          46m
```

Y en los logs observamos cómo KubeLinter indica que no se han encontrado problemas en los ficheros analizados:

```bash
$ kubectl -n cronjobs logs pod/kubelinter-repo-testkubelinter-1613909880-2fkbg
[INFO] Fetching https://github.com/onthedock/testkubelinter.git
POST git-upload-pack (294 bytes)
POST git-upload-pack (310 bytes)
From https://github.com/onthedock/testkubelinter
 * branch            main       -> FETCH_HEAD
   6382485..e23b2bf  main       -> origin/main
[INFO] localHEAD=6382485 remoteHEAD=e23b2bf
Merging FETCH_HEAD
Updating 6382485..e23b2bf
Fast-forward
 cronojb-kubnelinter.yaml | 4 ++++
 1 file changed, 4 insertions(+)
No lint errors found!
```

### Suspender temporalmente el CronJob

Si queremos pausar temporalmente la ejecución del CronJob, actualizaremos el fichero de definición incluyendo la opción `.spec.suspend: true`.

Tras actualizar el CronJob, el campo `SUSPEND` se marca como *True* y no se lanzan nuevas ejecuciones del Job (aunque aquellos en ejecución finalizarán con normalidad):

```bash
$ kubectl get cj -n cronjobs
NAME                             SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
kubelinter-repo-testkubelinter   * */1 * * *   True      0        34s             33m
```

## Conclusiones y mejoras

Hemos visto cómo podemos automatizar el análisis de los ficheros de definición de objetos de Kubernetes usando KubeLinter y CronJobs.

En la entrada anterior [KubeLinter: identifica malas configuraciones en los objetos de Kubernetes]({{< ref "210212-kubelinter.md" >}}) usaba KubeLinter como herramienta para mejorar la seguridad de los objetos desplegados en el clúster. Aunque se realizaba el análisis manualmente, lo ideal sería integrar KubeLinter como parte de un proceso de CI/CD.

Quizás las primeras aplicaciones se desplegaran en Kubernetes sin haber incorporado las buenas prácticas en materia de seguridad y ahora sea necesario examinar una gran número de ficheros YAML.

A medida que la API de Kubernetes avanza, también crecen las posibilidades de que los ficheros de definiciones en nuestro repositorio contengan referencias a APIs desaconsejadas y que dejarán de existir en versiones posteriores de Kubernetes. Esto hace necesario configurar algún proceso que revise las definiciones de los ficheros y *Helm Charts* con las que se desplegaron recursos en el clúster.

Para este caso concreto, tenemos herramientas especializadas como [pluto](https://github.com/FairwindsOps/pluto), de Fairwinds.

KubeLinter también analiza las configuraciones de los recursos con un énfasis especial en la seguridad, lo que lo hace una herramienta más completa.

El análisis periódico mediante un CronJob se podría mejorar incluyendo alertas a los responsables del repositorio en el momento que se identifiquen errores, incluyendo este tipo de análisis junto otras revisiones de seguridad aplicables al clúster.
