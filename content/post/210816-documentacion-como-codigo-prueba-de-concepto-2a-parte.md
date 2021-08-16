+++
draft = false
categories = ["dev"]
tags = ["linux", "kubernetes", "k3s", "mkdocs"]
thumbnail = "images/mkdocs-material-logo.svg"

title=  "Documentación como código - 2a parte"
date = "2021-08-16T20:16:34+02:00"
+++

En la [entrada anterior]({{< ref "210731-documentacion-como-codigo-poc-1a-parte.md" >}}) indicaba la idea general en la que estoy trabajando para implementar una solución funcional de *documentación como código*.


Reducida a su mínima expresión, la prueba de concepto lo que tiene que mostrar es la *velocidad* a la que se puede ir actualizando la documentación si se sigue el mismo proceso -y herramientas- de desarrollo a las que está acostumbrado el equipo de proyecto.

No se trata de crear un sistema listo para producción, sino de mostrar *algo* que **funcione** &trade; más o menos, como funcionaría la solución final.
<!--more-->
La prueba de concepto se ha montado sobre un clúster *mono-nodo* de **K3s**:

{{< figure src="/images/210816/doc-as-code.svg" width="100%" >}}

## *Job* (o *ConJob*) como "pipeline" de construcción

En el escenario ideal, el repositorio de código dispararía un *webhook* al recibir un *commit* o una *pull request*. En respuesta al evento, el orquestador ejecutaría las tareas de la *pipeline* para construir una nueva versión de la documentación (con los últimos cambios introducidos en el *commit* / *pull request*).

En la prueba de concepto, el *webhook* se simula mediante la ejecución manual de un *Job* (o periódica, si se usa un *CronJob*).

Las tareas de la *pipeline* son dos comandos concatenados en un *script*: `git clone` y `mkdocs build`; como el volumen donde se construye la versión web de la documentación es el mismo usado para publicar la documentación generada, tenemos cubierta automáticamente la parte de *continuous deployment*.

## Publicación web (*CD*)

La *rama* derecha del diagrama describe los objetos de Kubernetes implicados en la publicación de contenido web.

### Volumen

La clave de la prueba de concepto está en usar un volumen como "elemento común" para la construcción y para el *deployment*. Como comenté en la entrada anterior en el apartado de *Publicación de la documentación*, otras opciones más robustas complican la solución, así que opté por esta solución de espítiru *macgyvero* **porque funciona** y sobretodo, porque sirve para mostrar **el concepto** evitando la complejidad técnica.

### *Namespace*

Para aislar los recursos de la *prueba de concepto* del resto de aplicaciones en el clúster, si las hubiera, creo el *namespace* `doc-as-code`:

```yaml
---
kind: Namespace
apiVersion: v1
metadata:
  name: doc-as-code
```

### Volumen compartido

El *Persistent Volume Claim* `website-pvc` se monta en los *pods* basados en Nginx en modo *read only*.

Al crear el *PVC*, como no especificamos una *storageClass*, usamos la *storageClass* por defecto en el clúster. En el caso de K3s se usa [`local-path`](https://github.com/rancher/local-path-provisioner/blob/master/README.md), que permite la provisión dinámica de volúmenes de tipo `hostPath`.

El fichero de definición del *PVC*:

```yaml
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: website-pvc
  namespace: doc-as-code
  labels:
    app.kubernetes.io/name: doc-as-code-pvc
    app.kubernetes.io/component: storage
    app.kubernetes.io/part-of: doc-as-code
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
```

> Aplicamos algunas de las etiquetas recomandadas ([Recommended Labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/)) de la documentación oficial de Kubernetes.

### Servidor web

Usamos Nginx para servir la documentación en formato HTML generada por MkDocs.

Los ficheros servidos se publican desde el volumen montado en la ruta por defecto para Nginx `/usr/share/nginx/html` (en modo *ReadOnly*).

### *Deployment*

El *Deployment* está basado en Nginx y monta el volumen que contiene la documentación en formato web.

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: doc-as-code-nginx
  namespace: doc-as-code
  labels:
    app.kubernetes.io/name: doc-as-code-nginx
    app.kubernetes.io/component: webserver
    app.kubernetes.io/part-of: doc-as-code
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: doc-as-code-nginx
      app.kubernetes.io/component: webserver
      app.kubernetes.io/part-of: doc-as-code
  replicas: 1
  template:
    metadata:
      labels:
        app.kubernetes.io/name: doc-as-code-nginx
        app.kubernetes.io/component: webserver
        app.kubernetes.io/part-of: doc-as-code
    spec:
      containers:
        - name: nginx
          image: nginx:stable-alpine
          imagePullPolicy: IfNotPresent
          ports:
          - name: http-tcp
            containerPort: 80
          volumeMounts:
            - name: webdocs
              mountPath: /usr/share/nginx/html
              readOnly: true # Montamos el volumen como ReadOnly en el webserver
      volumes:
        - name: webdocs
          persistentVolumeClaim:
            claimName: website-pvc
```

### *Service*

*Publicamos* el servicio de forma interna usando `ClusterIP`, porque la web será accesible desde *fuera* del clúster a través de un *Ingress*:

```yaml
---
kind: Service
apiVersion: v1
metadata:
  name: doc-as-code-web
  namespace: doc-as-code
  labels:
    app.kubernetes.io/name: doc-as-code-service
    app.kubernetes.io/component: webserver-service
    app.kubernetes.io/part-of: doc-as-code
spec:
  ports:
    - port: 80
      name: http-tcp
  selector:
    app.kubernetes.io/name: doc-as-code-nginx
    app.kubernetes.io/component: webserver
    app.kubernetes.io/part-of: doc-as-code
```

### *Ingress*

La configuración del *Ingress* puede depende del (o de los) *Ingress Controller* que haya desplegados en el clúster.

En K3s el *Ingress Controller* por defecto es [Traefik](https://doc.traefik.io/traefik/).

> El nombre del *host* `docs.k3s.vm.lab` está definido en el fichero `/etc/hosts` del equipo cliente desde el que se realiza la demo.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: doc-as-code-traefik-ingress
  namespace: doc-as-code 
  labels:
    app.kubernetes.io/name: doc-as-code-traeffik-ingress
    app.kubernetes.io/component: ingress
    app.kubernetes.io/part-of: doc-as-code 
spec:
  rules:
  - host: docs.k3s.vm.lab
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: doc-as-code-web
            port: 
              number: 80 
```

## *Build*

### Repositorio

Para simplificar, se usa un repositorio público en GitHub. De esta forma evitamos tener que desplegar infraestructura adicional.

Al usar un repositorio público se evitan las complicaciones de la autenticación para acceder a un repositorio privado.

El repositorio público contiene un sitio de ejemplo elaborado con MkDocs.

### *Job* - tarea 1: clonar el código fuente

La imagen [squidfunk/mkdocs-material](https://hub.docker.com/r/squidfunk/mkdocs-material/) contiene Git, lo que permite clonar el repositorio sin necesidad de tener que usar una imagen personalizada en la que se haya instalado Git.

La imagen base declara la carpeta de trabajo como `WORKDIR /docs` en el [`Dockerfile`](https://github.com/squidfunk/mkdocs-material/blob/master/Dockerfile); clonamos el repositorio en esa carpeta:

```bash
git clone https://github.com/onthedock/k8s-devops.git /docs
```

La URL del repositorio la pasaremos al contenedor a través de una variable de entorno cargada desde un *ConfigMap*.

Generamos el *ConfigMap* usando la opción `--dry-run=client`:

```bash
kubectl create configmap doc-as-code-repo-url \
  --from-literal repo_url=https://github.com/onthedock/k8s-devops.git \
  --dry-run=client -o yaml | tee doc-as-code-repo-url-configmap.yaml
```

Esto genera, después de añadir algunas etiquetas adicionales:

```yaml
apiVersion: v1
data:
  repo_url: https://github.com/onthedock/k8s-devops.git
kind: ConfigMap
metadata:
  namespace: doc-as-code
  creationTimestamp: null
  name: doc-as-code-repo-url
  labels:
    app.kubernetes.io/name: doc-as-code-configmap
    app.kubernetes.io/component: configuration
    app.kubernetes.io/part-of: doc-as-code
```

### *Job* - tarea 2: construir la documentación en formato web

La segunda tarea de la *pipeline* es la contrucción de la documentación en formato web usando MkDocs.

Hemos clonado el *código fuente* en la carpeta `docs/`, que es donde MkDocs espera encontrar el fichero `mkdocs.yaml` con la configuración del sitio web a construir : `mkdocs build ...`

### *Job* - tarea 3 (bueno, 2, continuada): publicar la documentación en el servidor web

Usamos la opción `--site-dir` del comando `mkdocs build` para generar la documentación web en la ruta `/usr/share/nginx/html` del volumen montado. El volumen también está montado en el *pod* de Nginx, por lo que el servidor web publicará automáticamente los ficheros HTML, CSS, etc ubicados en esa carpeta.

Esto nos ahorra tener que copiar los ficheros web generados al servidor Nginx y simplifica la prueba de concepto.

El fichero de definición del *Job* queda:

```yaml
---
kind: Job
apiVersion:  batch/v1
metadata:
  namespace: doc-as-code
  labels:
    app.kubernetes.io/name: doc-as-code-build
    app.kubernetes.io/component: builder
    app.kubernetes.io/part-of: doc-as-code
  generateName: doc-as-code-builder-
spec:
  template:
    metadata:
      labels:
        app.kubernetes.io/name: doc-as-code-build
        app.kubernetes.io/component: builder
        app.kubernetes.io/part-of: doc-as-code
    spec:
      restartPolicy: Never
      containers:
        - name: doc-as-code-builder
          image: squidfunk/mkdocs-material
          imagePullPolicy: IfNotPresent
          env:
            - name: DOCS_REPO_URL
              valueFrom:
                configMapKeyRef:
                  name: doc-as-code-repo-url
                  key: repo_url
          volumeMounts:
            - name: website-docs
              mountPath: /usr/share/nginx/html
          command: ["/bin/sh"]
          args:
            - "-c"
            - "git clone $DOCS_REPO_URL /docs && mkdocs build --site-dir /usr/share/nginx/html"
      volumes:
        - name: website-docs
          persistentVolumeClaim:
            claimName: website-pvc
```

## Ejecución

Como hemos comentado al principio, ejecutamos el *Job* manualmente cada vez que se actualice la documentación en el repositorio:

```bash
kubectl create -f job.yaml
```

En los logs del *pod* generado por el *Job* observamos que se genera la documentación en `/usr/share/nginx/html` (desde el *pod* de MkDocs):

```bash
Cloning into '/docs'...
INFO - Cleaning site directory
INFO - Building documentation to directory: /usr/share/nginx/html
INFO - Documentation built in 2.68 seconds
```

## Resumen

La solución propuesta en este artículo permite hacer una *demo* rápida del **concepto** de **documentación como codigo** sin demasiadas complicaciones técnicas ni uso excesivo de recursos.

En las siguientes entradas *escalaremos* esta *prueba de concepto* en un escenario algo más realista; aunque seguimos usando un clúster *mono-nodo*, desplegamos *Gitea* y usamos *Tekton Pipelines* para actualizar automáticamente la construcción de la documentación cada vez que se guarda un cambio en el repositorio.
