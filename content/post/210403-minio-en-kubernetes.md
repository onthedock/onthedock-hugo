+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "kubernetes", "minio"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/minio.jpg"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" %}}

title=  "Minio en Kubernetes"
date = "2021-04-03T09:02:58+02:00"
+++
[MinIO](https://min.io/) proporciona almacenamiento de objetos compatible con AWS S3. Desde la última vez que revisé este producto, MinIO ha crecido hasta convertirse en una solución de calidad empresarial.

> También han cambiado el logo, y por lo que veo, el "flamenco" o lo que sea el animal del logo ha quedado relegado al `favicon` y el *footer* de la página web...Yo mantendré por ahora el logo "antiguo" (que curiosamente, tiene al pájaro mirando hacia la izquierda `¯\_(ツ)_/¯`)

En este artículo, voy a desplegarlo sobre Kubernetes de forma manual con un sólo servidor. Usaremos el almacenamiento en MinIO como destino de las copias de seguridad del clúster de Kubernetes usando Velero (en un próximo artículo).
<!--more-->

> La forma *recomendada* de desplegar MinIO en Kubernetes es a través de un operador o de una *Helm Chart*, como se describe en la documentación oficial: [Deploy MinIO on Kubernetes](https://docs.min.io/docs/deploy-minio-on-kubernetes.html). En mi caso lo despliego manualmente *por aprender*.

Siguiendo las buenas prácticas, creamos un *Namespace* para desplegar MinIO:

```YAML
---
kind: Namespace
apiVersion: v1
metadata:
  name: minio
```

Como la finalidad de MinIO es la de proporcionar almacenamiento, definimos un *Persistent Volume Claim* (en este caso, usando la *Storage Class* por defecto en el clúster):

```yaml
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  namespace: minio
  name: minio-data
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
```

En mi escenario, MinIO lo usaré para almacenar las copias de seguridad durante las pruebas con Velero, por eso defino un volumen de tamaño pequeño.

Con estos pre-requisitos mínimos, ya podemos definir el *Deployment* de MinIO:

```yaml
---
kind: Deployment
apiVersion: apps/v1
metadata:
  name: minio
  namespace: minio
spec:
  replicas: 1 
  selector:
    matchLabels:
      app: minio
  template:
    metadata:
      labels:
        app: minio
    spec:
      containers:
        - name: minio
          image: minio/minio
          command: ["minio"]
          args: ["server", "/data"]
          ports:
            - name: web-ui
              containerPort: 9000 
          volumeMounts:
            - name: minio-data
              mountPath: /data
      volumes:
        - name: minio-data
          persistentVolumeClaim:
            claimName: minio-data
```

Como no hemos especificado usuario y *password*, MinIO arranca con las credenciales por defecto: `minioadmin` (como usuario y *password*).

Para especificar credenciales personalizadas, hay que definir las variables de entorno `MINIO_ROOT_USER` y `MINIO_ROOT_PASSWORD`. Los valores de estas variables de entorno las obtendremos de un *Secret*.

Como los *secretos* en Kubernetes están ofuscados usando **base64**, uso `kubectl create secret` con la opción `dry-run` para generar el YAML de definición del *Secret*:

```bash
kubectl create secret generic minio-secret -n minio \
--from-literal=minio-root-user=ACCESSKEYEXAMPLE123 \
--from-literal=minio-root-password=wdvb5rtghn76yujm -o yaml --dry-run=client | tee minio-secret.yaml
```

Esto genera el YAML con los valores ya ofuscados (y evita errores):

```yaml
---
apiVersion: v1
data:
  minio-root-password: d2R2YjVydGdobjc2eXVqbQ==
  minio-root-user: QUNDRVNTS0VZRVhBTVBMRTEyMw==
kind: Secret
metadata:
 name: minio-secret
 namespace: minio
type: Opaque
```

Actualizamos la definición del *Deployment* para que MinIO use las variables de entorno con las credenciales personalizadas (en `spec.containers.env`):

```yaml
...
env:
  - name: MINIO_ROOT_USER
    valueFrom:
      secretKeyRef: 
        name: minio-secret
        key: minio-root-user
  - name: MINIO_ROOT_PASSWORD
    valueFrom:
      secretKeyRef:
        name: minio-secret
        key: minio-root-password
...
```

Finalmente, exponemos MinIO a través de un servicio.

En el escenario de usar MinIO como *backend* para las copias de seguridad de Velero, quizás tiene más sentido que el servicio sea de tipo *ClusterIP*, pero para validar que todo funciona como debe, uso *NodePort* para tener acceso sencillo a la interfaz web de MinIO.

```yaml
--- 
kind: Service
apiVersion: v1
metadata:
  namespace: minio
  name: minio
spec:
  type: NodePort
  selector:
    app: minio
  ports:
    - name: web-ui
      protocol: TCP
      port: 9000
```

Tras desplegar el servicio, revisa qué puerto ha asignado Kubernetes a MinIO con:

```bash
$ kubectl get svc -n minio
NAME    TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
minio   NodePort   10.43.117.250   <none>        9000:30712/TCP   35h
```

Accede a la interfaz web de MinIO a través del puerto asignado (en mi caso, `30712`) y accede con las credenciales especificadas en el *Secret*.
