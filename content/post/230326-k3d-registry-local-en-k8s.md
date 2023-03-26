+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
tags = ["linux", "kubernetes", "k3d", "registry"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/k3s.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/

# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}
# YouTube           {{< youtube w7Ft2ymGmfc >}}
# Gist              {{< gist username 7896402 >}}
# Highlight         {{< highligth language >}}...{{< /highlight >}}
# Twitter           {{< tweet user="SanDiegoZoo" id="1453110110599868418" >}}

title=  "k3d: Registry local en Kubernetes"
date = "2023-03-26T17:38:10+02:00"
+++
En la entrada anterior [k3d: desplegar un clúster de Kubernetes como código]({{< ref "230326-k3d-cluster-como-codigo.md" >}}) incluí un *registry* en el despliegue del clúster con **k3d**.

En esta entrada veremos cómo usarlo para desplegar aplicaciones en el clúster.
<!--more-->

Como parte del despliegue de k3d se puede incluir un *registry*. Con la configuración especificada, el registry está disponible en `registry.localhost` en el puerto 5000 (el puerto por defecto usado por Docker).

> En Linux el "dominio" `.localhost` resuelve siempre a 127.0.0.1

## Configuración de *registro inseguro*

El [*registry* de Docker](https://docs.docker.com/registry/) requiere el uso de conexiones cifradas por TLS, lo que requiere un certificado.

Aunque el despliegue mediante k3d permite especificar los certificados para configurar un *registry* seguro, para un entorno local de pruebas podemos usar conexiones inseguras -esto es, sin TLS- para acceder al *registry*.

Para permitir conexiones inseguras, debemos configurar el *daemon* de Docker a través del fichero `/etc/docker/daemon.json`. Revisa las instrucciones ofrecidas por Docker en [Test an insecure registry](https://docs.docker.com/registry/insecure/).

Crea el fichero `/etc/docker/daemon.json` (si no existe) y añade la URL del registro:

```bash
{
    "insecure-registries": ["http://registry.localhost:5000/"]
}
```

Debes reiniciar Docker para que los cambios sean efectivos.

## Imagen de contenedor

En este caso, vamos a descargar de Docker Hub la imagen de **nginx**, pero del mismo modo podríamos usar la imagen de nuestra aplicación durante el proceso de desarrollo (generada, por ejemplo, con `docker build`).

Descargamos la imagen de Nginx (sobre Alpine) de Docker Hub:

```bash
$ docker pull nginx:1.23-alpine
1.23-alpine: Pulling from library/nginx
63b65145d645: Already exists
8c7e1fd96380: Pull complete
86c5246c96db: Pull complete
b874033c43fb: Pull complete
dbe1551bd73f: Pull complete
0d4f6b3f3de6: Pull complete
2a41f256c40f: Pull complete
Digest: sha256:6318314189b40e73145a48060bff4783a116c34cc7241532d0d94198fb2c9629
Status: Downloaded newer image for nginx:1.23-alpine
docker.io/library/nginx:1.23-alpine
```

Ejecuto localmente un contenedor a partir de la imagen de Nginx y valido que sirve la página por defecto:

```bash
$ docker run -p 8080:80 -d nginx:1.23-alpine
fdecff0efba7dc6e4db0f66cd873f7d4f972ac1b8a8e057c6755527bccc4a436

$ docker ps | grep -i alpine
fdecff0efba7   nginx:1.23-alpine                "/docker-entrypoint.…"   17 seconds ago   Up 16 seconds   0.0.0.0:8080->80/tcp, :::8080->80/tcp   blissful_herschel

$ curl -s localhost:8080 | grep -i 'welcome'
<title>Welcome to nginx!</title>
<h1>Welcome to nginx!</h1>
```

Tenemos la imagen de Nginx localmente, pero lo que queremos es *subirla* al *registry*.
El objetivo es que el clúster de Kubernetes despliegue los contenedores desde el *registry* de **k3d**, no desde nuestra *cache local*.

## Etiquetado y subida de la imagen al *registry*

Etiquetamos la imagen local (en este caso, de Nginx) con la URL y *namespace* del *registry* en **k3d**:

```bash
$ docker images | grep -i 'nginx'
nginx                      1.23-alpine    2bc7edbc3cf2   6 weeks ago   40.7MB

$ docker tag nginx:1.23-alpine registry.localhost:5000/xaviaznar/nginx:v1.23-alpine

$ docker images | grep -i 'nginx'
nginx                                     1.23-alpine    2bc7edbc3cf2   6 weeks ago   40.7MB
registry.localhost:5000/xaviaznar/nginx   v1.23-alpine   2bc7edbc3cf2   6 weeks ago   40.7MB
```

Una vez *taggeada*, subimos la imagen al *registry* en **k3d**:

```bash
$ docker push registry.localhost:5000/xaviaznar/nginx:v1.23-alpine
The push refers to repository [registry.localhost:5000/xaviaznar/nginx]
042cd3f87f43: Pushed
f1bee861c2ba: Pushed
c4d67a5827ca: Pushed
152a948bab3b: Pushed
5e59460a18a3: Pushed
d8a5a02a8c2d: Pushed
7cd52847ad77: Pushed
v1.23-alpine: digest: sha256:3eb380b81387e9f2a49cb6e5e18db016e33d62c37ea0e9be2339e9f0b3e26170 size: 1781
```

Eliminamos la copia local de la imagen de Nginx:

```bash
$ docker rmi nginx:1.23-alpine
Untagged: nginx:1.23-alpine
Untagged: nginx@sha256:6318314189b40e73145a48060bff4783a116c34cc7241532d0d94198fb2c9629

$ docker rmi registry.localhost:5000/xaviaznar/nginx:v1.23-alpine 
Untagged: registry.localhost:5000/xaviaznar/nginx:v1.23-alpine
Untagged: registry.localhost:5000/xaviaznar/nginx@sha256:3eb380b81387e9f2a49cb6e5e18db016e33d62c37ea0e9be2339e9f0b3e26170
Deleted: sha256:2bc7edbc3cf2fce630a95d0586c48cd248e5df37df5b1244728a5c8c91becfe0
Deleted: sha256:9ca6be4cd63171f17f0a5e2ea28d5361a299672f41bd65223e7eac7d3d57e76d
Deleted: sha256:f7aa4d1226879fb1018ed05617572994840f4c75e5d04df2fffe04980cef11b9
Deleted: sha256:f83cdd3286b839bef51f1ae0f1f6164b16e1059a0e131035bfa0bb8bb0021357
Deleted: sha256:61b0680052fcdb48f47c8d68687c0b5bbb279b6e3740701885b39ea22ef7b008
Deleted: sha256:9045770a1273553bb8bd7ccd2d490ecb56ce762ac993ad74698d14186e39bda6
Deleted: sha256:60d9493158e562e8510cd4cabbd7460c03ad39fe2250bbd43bdcd1e75f64ba6f
```

## Despliegue de un contenedor basado en la imagen del *registry* de **k3d**

Creamos un fichero de *deployment*:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 2 # tells deployment to run 2 pods matching the template
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: registry.localhost:5000/xaviaznar/nginx:v1.23-alpine
        ports:
        - containerPort: 80
```

Establecemos el clúster de k3d como *current-context* en kubectl:

```bash
$ kubectl config set current-context k3d-onthedock
Property "current-context" set.
```

Desplegamos el *deployment*:

```bash
$ kubectl apply -f nginx/deployment.yaml 
deployment.apps/nginx created
```

Para validar que los *pods* están sirviendo la página por defecto de Nginx, usamos *port-forward*:

```bash
$ kubectl port-forward pods/nginx-566d6d4899-qtzp8 8080:80 &
$ curl -s  localhost:8080 | grep -i 'welcome'
Handling connection for 8080
<title>Welcome to nginx!</title>
<h1>Welcome to nginx!</h1>
```

Traemos el proceso a primer plano (con `fg`) y lo finalizamos.

Si miramos en detalle cualquiera de los dos *pods*, vemos que están usando la imagen del *registry* en *k3d* y no una imagen descargada desde Docker Hub:

```bash
$ kubectl get pods nginx-566d6d4899-qtzp8 -o jsonpath='{.spec.containers[].image}'
registry.localhost:5000/xaviaznar/nginx:v1.23-alpine
```

## Observación

En realidad, el *registry* desplegado por k3d no está desplegado **en** el clúster, sino que es un contenedor adicional...

Usando el subcomando `list` de `k3d cluster`:

```bash
$ k3d cluster list
NAME        SERVERS   AGENTS   LOADBALANCER
onthedock   1/1       2/2      true
```

La salida indica que tenemos un nodo *server* y dos *agents*. Que bajo la columna *loadbalancer* se muestre `true` significa que tenemos un balanceador "delante" del clúster. Estrictamente el balanceador no forma parte del clúster...

Del mismo modo, si usamos `k3d node list` obtenemos que uno de los *nodos* es el *registry*:

```bash
$ k3d node list
NAME                     ROLE           CLUSTER     STATUS
k3d-onthedock-agent-0    agent          onthedock   running
k3d-onthedock-agent-1    agent          onthedock   running
k3d-onthedock-server-0   server         onthedock   running
k3d-onthedock-serverlb   loadbalancer   onthedock   running
registry.localhost       registry       onthedock   running
```

Pero esto es lo que muestra `k3d`; si usamos `kubectl`, está claro que el *balanceador* no forma parte del clúster:

```bash
$ kubectl get nodes
NAME                     STATUS   ROLES                  AGE     VERSION
k3d-onthedock-agent-0    Ready    <none>                 6h21m   v1.25.7+k3s1
k3d-onthedock-server-0   Ready    control-plane,master   6h21m   v1.25.7+k3s1
k3d-onthedock-agent-1    Ready    <none>                 6h21m   v1.25.7+k3s1
```

Del mismo modo, el *registry* no está desplegado **en el clúster** (como un *pod*), sino en un contenedor "externo":

```bash
$ kubectl get pods --all-namespaces | grep -i 'registry'
$
```

## Conclusión

Independientemente de cómo o dónde está desplegado el *registry* desplegado por k3d, Kubernetes puede usar el registro como origen de las imágenes desde las que desplegar *pods*.

Esto permite agilizar los despligues y las pruebas sobre la aplicación, ya que no es necesario hacer *push* a un *registry* remoto sólo para que al desplegar sobre el clúster, Kubernetes tenga que descargar la imagen de nuevo para poder arrancar los *pods*.

Con k3d disponemos de un entorno autocontenido que nos permite trabajar incluso desconectados de la red.
