+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["kubernetes", "k3s", "gitea", "devtoolbox"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/gitea.jpg"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}

title=  "Desplegar Gitea en Kubernetes"
date = "2020-12-12T12:13:18+01:00"
+++
Ya he hablado varias veces de [Gitea en este sitio](/tags/gitea), así que no me repetiré (mucho)
; Gitea es una solución ligera de alojamiento de repositorios Git (a lo GitHub).

En esta entrada se indica el proceso que he seguido para la creación de los diferentes objetos necesarios para desplegar Gitea (usando SQLite como base de datos) en Kubernetes.

Puedes seguir los pasos de la [documentación oficial para desplegar Gitea](https://docs.gitea.io/en-us/install-on-kubernetes/) sobre Kubernetes usando Helm.
<!--more-->

Como parte del proyecto [devtoolbox](/tags/devtoolbox), una de las primeras herramientas que he desplegado es Gitea, como repositorio de código para el equipo de desarrollo.

Sería mucho más sencillo usar Helm y las instrucciones de la documentación de Gitea para desplegar la aplicación en Kubernetes, pero como el objetivo principal es **aprender**, he partido de la imagen oficial de Gitea y he generado *desde cero* los ficheros de definición de los objetos para desplegar Gitea en Kubernetes.

Gitea requiere una base de datos para almacenar información de configuración de la aplicación. Esta base de datos puede ser MySQL o PostgreSQL, aunque como primera aproximación, usaré la base de datos SQLite *embebida*.

Esto significa que en esta iteración (voy por la segunda) todavía no puedo escalar el número de réplicas.

> En la primera iteración me concentré en la *kubernetización* de la aplicación; en la segunda, en automatizar completamente el despliegue, realizando la configuración de Gitea mediante un *configMap*. Más adelante planeo añadir la opción de usar una base de datos externa antes de pasar a realizar un despliegue completo usando Helm.

## Creación del *namespace*

Todos los componentes los despliego en un *namespace* personalizado llamado *toolbox-${nombre-aplicación}*, así que el primer paso es crear el fichero de definición del *namespace*:

```yaml
---
apiVersion: v1
kind: Namespace
metadata:
    name: toolbox-gitea
```

## Creación del volumen

La creación del *persistent volume* generalmente se realiza automáticamente usando alguno de los *storage class* disponibles en el clúster al crear el *persistent volume claim*.

> Como estoy usando un clúster de un solo nodo basado en K3s, crearé un volumen de tipo *hostPath*. Este tipo de volumen sólo es recomendable para desarrollo, por ejemplo.

### Creación del *persistent volume*

La creación del *persistent volume* la debe realizar un administrador del clúster.

> La carpeta local elegida (en mi caso, `/mnt/data`) debe existir en los nodos del clúster: `mkdir -p /mnt/data`.

```yaml
---
apiVersion: v1
kind: PersistentVolume
metadata:
    name: gitea-volume
    namespace: toolbox-gitea
    labels:
        type: local
spec:
    storageClassName: manual
    capacity:
        storage: 10Gi
    accessModes:
        - ReadWriteOnce
    hostPath:
        path: "/mnt/data/gitea"
```

### Creación del *persistent volume claim*

Al crear el *persistent volume claim* solictamos al clúster una determinada cantidad de almacenamiento de un tipo concreto. Como en nuestro caso la *storageClass* es `manual`, un administrador debe haber creado anteriormente un *persistent volume* que permita satisfacer el requerimiento de almacenamiento expresado en el *claim*.

Cuando desplegamos el *persistent volume claim*, el sistema asocia un *persistent volume* disponible para su uso en los pods creados por el *deployment*.

Si no hay ningún volumen disponible que satisfaga el *claim*, el pod no arranca.

Para otros tipos de *storage class* diferente a `manual`, la creación del *persistent volume* se realiza de forma dinámica cuando se crea el *persistent volume claim*.

La definición del *persistent volume claim*:

```yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
    name: gitea-volume-claim
    namespace: toolbox-gitea
spec:
    storageClass: manual
    accessModes:
        - ReadWriteOnce
    resources:
        requests:
            storage: 10Gi
```

## Configuración de Gitea

La configuración de Gitea se realiza a través de una combinación de variables de entorno (en el *deployment*) y el fichero de configuración `app.ini`

> Quizás es posible usar únicamente el fichero `app.ini` para realizar la configuración de Gitea, pero creo que algunos valores -como en nombre a mostrar- son más *visibles* en el fichero de definición del *deployment*.

El fichero `app.ini` podemos crearlo desde cero, usar un fichero de configuración de referencia (como [app.example.ini](https://github.com/go-gitea/gitea/blob/master/custom/conf/app.example.ini) en el repositorio oficial de Gitea en Github) o *exportalo* de una instancia en marcha (`kubectl exec <gitea-pod-name> -- cat /data/gitea/conf/app.ini > app.ini`)

Una vez configurado el fichero `app.ini` (en [Configuration Cheat Sheet](https://docs.gitea.io/en-us/config-cheat-sheet/) tienes el detalle de las opciones de configuración), crea el fichero de definición del *configMap* mediante:

```bash
kubectl create configmap gitea-config -n toolbox-gitea --from-file=app.ini -o yaml --dry-run
```

```yaml
---
apiVersion: v1
kind: configMap
metadata:
    name: gitea-config
    namespace: toolbox-gitea
data:
    app.ini: "APP_NAME = GiteaToolbox\nRUN_MODE = prod\nRUN_USER = git\n\n[repository]\nROOT
    = /data/git/repositories\n\n[repository.local]\nLOCAL_COPY_PATH = /data/gitea/tmp/local-repo\n\n[repository.upload]\nTEMP_PATH
    = /data/gitea/uploads\n\n[server]\nAPP_DATA_PATH    = /data/gitea\nDOMAIN           =
    gitea.dev.lab\nSSH_DOMAIN       = gitea.dev.lab\nHTTP_PORT        = 3000\nROOT_URL
    \        = https://gitea.dev.lab/\nDISABLE_SSH      = true\nSSH_PORT         =
    22\nSSH_LISTEN_PORT  = 22\nLFS_START_SERVER = true\nLFS_CONTENT_PATH = /data/git/lfs\nLFS_JWT_SECRET
    \  = O6jMwi1miKPfeNtwFy6YQ_Xw73KIFfDumbhiyvFW000\nOFFLINE_MODE     = false\nLANDING_PAGE
    \    = login\n\n[database]\nPATH     = /data/gitea/gitea.db\nDB_TYPE  = sqlite3\nHOST
    \    = localhost:3306\nNAME     = gitea\nUSER     = root\nPASSWD   = \nLOG_SQL
    \ = false\nSCHEMA   = \nSSL_MODE = disable\nCHARSET  = utf8\n\n[indexer]\nISSUE_INDEXER_PATH
    = /data/gitea/indexers/issues.bleve\n\n[session]\nPROVIDER_CONFIG = /data/gitea/sessions\nPROVIDER
    \       = file\n\n[picture]\nAVATAR_UPLOAD_PATH            = /data/gitea/avatars\nREPOSITORY_AVATAR_UPLOAD_PATH
    = /data/gitea/repo-avatars\nDISABLE_GRAVATAR              = false\nENABLE_FEDERATED_AVATAR
    \      = true\n\n[attachment]\nPATH = /data/gitea/attachments\n\n[log]\nMODE                 =
    console\nLEVEL                = info\nREDIRECT_MACARON_LOG = true\nMACARON              =
    console\nROUTER               = console\nROOT_PATH            = /data/gitea/log\n\n[security]\nINSTALL_LOCK
    \  = true\nSECRET_KEY     = 4EmLHC2wGvIblUzjkz3bui41Otq2od3ZvK6B4mTtrc1G4S1bJlDwytmkIjLBMx0X\nINTERNAL_TOKEN
    = eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYmYiOjE2MDUwNDQ1NTd9.L4EcHeKNY46zwK9GdXAVXEdTAl1E7dEKQuYIXFvXgBc\n\n[service]\nDISABLE_REGISTRATION
    \             = true \nREQUIRE_SIGNIN_VIEW               = false\nREGISTER_EMAIL_CONFIRM
    \           = false\nENABLE_NOTIFY_MAIL                = false\nALLOW_ONLY_EXTERNAL_REGISTRATION
    \ = false\nENABLE_CAPTCHA                    = false\nDEFAULT_KEEP_EMAIL_PRIVATE
    \       = false\nDEFAULT_ALLOW_CREATE_ORGANIZATION = false\nDEFAULT_ENABLE_TIMETRACKING
    \      = false\nNO_REPLY_ADDRESS                  = \n\n[oauth2]\nJWT_SECRET =
    PCG9Yl-fjaUi54pBTCoaJPH7C-v2r_bBIh4SYSfKysk\n\n[mailer]\nENABLED = false\n\n[openid]\nENABLE_OPENID_SIGNIN
    = false\nENABLE_OPENID_SIGNUP = false\n\n"
```

## Fichero de despliegue

Una vez tenemos todos los elementos necesarios, creamos el fichero de definición del *deployment* de Gitea:

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
    name: gitea
    namespace: toolbox-gitea
    labels:
        app: gitea
spec:
    replicas: 1
    selector:
        matchLabels:
            app: gitea
    template:
        metadata:
            labels:
                app: gitea
        spec:
            containers:
                - name: gitea
                  image: gitea/gitea
                  ports:
                    - name: gitea-ui
                      containerPort: 3000
                  env:
                    - name: APP_NAME
                      value: GiteaToolbox
                    - name: DOMAIN
                      value: gitea.dev.lab
                    - name: ROOT_URL
                      value: https://gitea.dev.lab
                  volumeMounts:
                    - name: gitea-data
                      mountPath: /data
                    - name: gitea-config
                      mountPath: /data/gitea/conf
            volumes:
                - name: gitea-data
                  persistentVolumeClaim:
                    claimName: gitea-volume-claim
                - name: gitea-config
                  configMap:
                    name: gitea-config
```

Especificamos una única réplica ya que al usar SQLite (dentro del contenedor), no tendría sentido escalar. En la sección `spec.template.metadata.labels` indicamos que los *pods* creados por el *deployment* incluyan la etiqueta `app=gitea`, lo que nos permite seleccionarlos en el siguiente paso, donde crearemos el *service*.

El fichero de configuración `app.ini` lo montamos en `/data/gitea/conf` (la ubicación por defecto) usando un volumen. El otro volumen montado en el *pod* contiene los datos de los repositorios gestionados por Gitea.

## Creación del servicio

Gitea expone dos puertos: 22 (SSH) y 3000 (gitea-ui). El uso de Git a través de SSH requiere configuración adicional, ya que los *ingress* sólo permiten tráfico HTTP y HTTPS. Por este motivo sólo exponemos el puerto 3000 para conectar con Gitea usando HTTPS.

```yaml
---
apiVersion: v1
kind: Service
metadata:
    name: gitea
    namespace: toolbox-gitea
spec:
    ports:
        - name: gitea-ui
          port: 3000
    selector:
        app: gitea
```

## Creación del *ingress* para proporcionar acceso a Gitea desde fuera del clúster

Al crear el servicio anterior, por defecto, se asigna una IP de tipo `ClusterIP` al servicio. Esto impide que se pueda acceder a la aplicación desde *fuera* del clúster.

Usamos un *ingress* para exponer el servicio al exterior:

```yaml
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
    name: gitea
    namespace: toolbox-gitea
    annotations:
        kubernets.io/ingress.class: traefik
        ingress.kubernetes.io/ssl-redirect: "false" # from https://github.com/rancher/k3d/blob/main/docs/usage/guides/exposing_services.md
spec:
    rules:
        - host: gitea.dev.lab # configured in DNS or hosts file
          http:
            paths:
                - path: /
                  backend:
                      serviceName: gitea
                      servicePort: gitea-ui
```

En K3s el *ingress* desplegado por defecto es [Traefik](https://doc.traefik.io/traefik/), por lo que las anotaciones quizás no tengan sentido para otras *ingress controllers*.

## Despliegue

Hemos creado el fichero `gitea-sqlite.yaml` con los diferentes fragmentos de código del artículo. De esta forma, podemos desplegar todos los recursos necesarios para el funcionamiento de Gitea mediante un único comando:

```bash
$ kubectl apply -f gitea-sqlite.yaml
namespace/toolbox-gitea created
persistentvolume/gitea-volume created
persistentvolumeclaim/gitea-volume-claim created
deployment.apps/gitea created
service/gitea created
ingress.extensions/gitea created
```

> Hemos especificado `metadata.namespace: toolbox-gitea` en la definición de todos los recursos; si no lo has hecho, recuerda que debes especificar `-n <namespace>` indicando el *namespace* de destino (si quieres desplegar en un *namespace* diferente al `default`).

Tras algo menos de un minuto, Gitea está en marcha y ya podrás acceder a través de `https://gitea.dev.lab`
