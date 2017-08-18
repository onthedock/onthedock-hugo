+++
date = "2017-07-16T19:38:17+02:00"
title = "Mi primera aplicación en Kubernetes"
categories = ["dev", "ops"]
tags = ["linux", "kubernetes"]
draft = false
thumbnail = "images/kubernetes.png"

+++

Después de [crear un cluster de un solo nodo]({{< ref "170702-crear-un-cluster-de-un-solo-nodo.md" >}}), en esta entrada explico los pasos para publicar una aplicación en el clúster.

<!--more-->

# Objetivo: publicar una aplicación

El objetivo de esta entrada es publicar una aplicación en el clúster accesible a través de la IP del _host_. Es decir, a todos los efectos, el usuario accede a la aplicación sin ningún conocimiento de que se encuentra en el clúster, corriendo sobre uno o varios contenedores.

# Usa ficheros YAML

Los dos objetos necesarios para _publicar_ la aplicación, el _Deployment_ y el _Service_, pueden crearse directamente o usando un fichero YAML.

El [tutorial de Kubernetes](https://kubernetes.io/docs/tutorials/kubernetes-basics/deploy-intro/) usa el método _online_, creando los objetos directamente en la línea de comando. Sin embargo, creo que este método no debería usarse nunca en producción (porque pueden pasar cosas **[muy](https://aws.amazon.com/message/41926/) [malas](http://money.cnn.com/2017/03/02/technology/amazon-s3-outage-human-error/index.html)**), por lo que vamos a usar los ficheros de configuración YAML para crear y actualizar los objetos en el clúster.

## Ejemplo de proceso de aprobación

Idealmente, cualquier cambio en el estado de la aplicación en el clúster debería seguir un flujo similar al de cualquier otra modificación que afecte a un sistema de producción; es decir, el DevOp clona el repositorio con la configuración de la aplicación en su equipo, hace los cambios y los verifica. Una vez satisfecho, los sube al repositorio (pasando por el sistema de aprobación establecido, como por ejemplo, una [_pull request_](https://help.github.com/articles/about-pull-requests/)). Una vez aprobado, se incorpora el cambio al repositorio de configuración de la aplicación en producción, desde donde se aplica al entorno de producción.

{{% img src="images/170716/pull-request-flow.png" caption="Proceso de aprobación basado en pull request." href="https://docs.rhodecode.com/RhodeCode-Enterprise/collaboration/pr-flow.html" %}}

# Define el _deployment_

Como vimos en la entrada de [revisión de conceptos]({{< ref "170528-revision-de-conceptos.md" >}}), el primer paso para desplegar una aplicación en un clúster Kubernetes es crear un _deployment_.

El fichero de declaración del _deployment_ tiene tres bloques (la estructura es común al resto de objetos):

1. Cabecera
1. Metadatos
1. Especificaciones

```yaml
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:stable-alpine
        ports:
        - containerPort: 80
```

## Cabecera del _deployment_

```yaml
apiVersion: apps/v1beta1
kind: Deployment
```

En primer lugar, la [versión de API](https://kubernetes.io/docs/api-reference/v1.6/#deployment-v1beta1-apps) que usamos para definir el _deployment_.

En `kind`, especificamos el tipo de objeto que vamos a definir.

## Metadatos del _deployment_

```yaml
metadata:
  name: nginx
```

Datos que describen el _deployment_; el único necesario es el nombre del _deployment_.

## Especificaciones del _deployment_

```yaml
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:stable-alpine
        ports:
        - containerPort: 80
```

En el apartado de especificaciones se declaran el número de réplicas de la aplicación que queremos en ejecución. Kubernetes se encarga de mantener este número de réplicas en ejecución en todo momento, respondiendo automáticamente en caso de fallo de alguno de los _pods_ o de los nodos del clúster.

Para poder crear nuevos _pods_ si es necesario, debemos definir una `template` (plantilla) a partir de la cual crearlos.

Como, al fin y al cabo estamos definiendo un objeto de tipo _pod_, tenemos de nuevo una sección de metadatos (en este caso, etiquetas para los _pods_ del _deployment_) y las especificaciones para crear un _pod_: el nombre, la imagen base para el contenedor del _pod_ y el puerto publicado por el contenedor.

Pueden definirse muchos otros parámetros, pero estos son los mínimos indispensables para tener un _deployment_ funcional (el único requerido es el `name`).

> La imagen se descarga por defecto desde DockerHub; si quieres usar un _registry_ alternativo, debes indicar la URL completa al recurso.

# Crea el _deployment_

En el [cluster de un solo nodo]({{< ref "170702-ip-en-mensaje-prelogin.md" >}}) de pruebas, he subido el fichero `nginx-deployment.yaml` con la definición del apartado anterior.

Para crear el _deployment_ usamos:

```sh
$ kubectl create -f nginx-deployment.yaml
deployment "nginx" created
```

Otra opción es usar la opción `apply`, que actualiza el _deployment_ si ya existe.

Una vez creado, lo examinamos en detalle con `describe`:

```sh
$ kubectl describe deployment nginx
Name:       nginx
Namespace:     default
CreationTimestamp:   Sun, 16 Jul 2017 11:06:48 +0200
Labels:        app=nginx
Annotations:      deployment.kubernetes.io/revision=1
Selector:      app=nginx
Replicas:      1 desired | 1 updated | 1 total | 1 available | 0 unavailable
StrategyType:     RollingUpdate
MinReadySeconds:  0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:   app=nginx
  Containers:
   nginx:
    Image:     nginx:stable-alpine
    Port:      80/TCP
    Environment:  <none>
    Mounts:    <none>
  Volumes:     <none>
Conditions:
  Type      Status   Reason
  ----      ------   ------
  Available    True  MinimumReplicasAvailable
  Progressing  True  NewReplicaSetAvailable
OldReplicaSets:   <none>
NewReplicaSet: nginx-3287103792 (1/1 replicas created)
Events:
  FirstSeen LastSeen Count From        SubObjectPath  Type     Reason         Message
  --------- -------- ----- ----        -------------  -------- ------         -------
  4m     4m    1  deployment-controller         Normal      ScalingReplicaSet Scaled up replica set nginx-3287103792 to 1
```

El _pod_ creado por Kubernetes tiene una IP asignada y está escuchando en el puerto 80, pero de momento sólo es accesible _desde dentro_ del clúster.

Puedes comprobarlo obteniendo el nombre del _pod_ y usando `describe` para obtener su IP. A continuación, mediante `curl` obtén la página de bienvenida de Nginx:

```html
$ curl http://10.32.0.4:80
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

Si intentas algo parecido _desde fuera_ del clúster, no tendrás respuesta.

## Modifica el número de réplicas

A modo de experimento, puedes modificar el número de réplicas directamente desde la línea de comandos usando:

```sh
kubectl scale deployment nginx --replicas 3
```

Y revisando el resultado del comando anterior:

```sh
$ kubectl get pods -l app=nginx
NAME                     READY     STATUS    RESTARTS   AGE
nginx-3225377387-l0hwp   1/1       Running   0          3m
nginx-3225377387-ptkdt   1/1       Running   0          3m
nginx-3225377387-rrz1x   1/1       Running   0          11m
```

Lo correcto, de todas maneras, habría sido modificar el fichero `nginx-deployment.yaml` y aplicar la nueva configuración mediante `kubectl apply -f nginx-deployment.yaml`

# Publica la aplicación

La aplicación está disponible en el clúster, pero sólo es accesible _desde dentro_ del clúster. De este modo no es especialmente útil (teniendo en cuenta que se trata de un servidor web).

El siguiente paso es definir un _Service_.

Un [service](https://kubernetes.io/docs/concepts/services-networking/service/) define un conjunto de _pods_ y una política de acceso.

Esto quiere decir que el servicio agrupa _pods_ independientes en un conjunto que "trabaja en equipo" para hacer "algo" (que es lo que se llama _microservice_, en terminología _DevOp_).

En cuanto a la política de acceso, es una forma de indicar que -en la mayoría de casos- se asigna un puerto **público** para que se pueda acceder a la aplicación _desde fuera_ del clúster.

# Define el _service_

El _service_ tiene los mismos tres bloques que el _deployment_:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
  type: LoadBalancer
```

## Cabecera del _service_

```yaml
apiVersion: v1
kind: Service
```

En la cabecera tenemos la versión de la API. Los _services_ existen desde la primera versión del API de Kubernetes, a diferencia de los _deployments_.

> Recuerda de la entrada de [revisión de conceptos]({{< ref "170528-revision-de-conceptos.md" >}}) que antes de los _deployments_ se usaban directamente los _Replication Controllers_, que después de mejoraron y se convirtieron en _ReplicaSets_.

En cuanto al tipo de objeto, en este caso definimos un `Service`.

## Metadatos del _service_

```yaml
metadata:
  name: nginx
  labels:
    app: nginx
```

Tampoco hay sorpresas en cuanto a los metadatos del servicio; en este caso, además del nombre, he añadido la etiqueta `app: nginx`.

## Especificaciones del _service_

```yaml
spec:
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
  type: LoadBalancer
```

Como hemos visto en la definición de _servicio_, éste sirve para agrupar _pods_. El conjunto de _pods_ se define mediante un **selector**, que en este caso, se trata de la etiqueta `app: nginx`.

Usar etiquetas permite organizar los _pods_ con total flexibilidad. Por ejemplo, podrías tener diferentes frontales (Nginx para contenido estático y Apache para el resto, por ejemplo) y agruparlos todos bajo una etiqueta llamada `tier: front-end`, por ejemplo, aunque cada tipo tenga, además, etiquetas específicas (`app: nginx` y `app: apache`).

> La elección de las etiquetas es un asunto **muy importante** que debes tener lo mejor organizado posible para tus aplicaciones.

A continuación, en la definición del servicio, tenemos la parte de _política de acceso_: una sección de `ports` en la que se define el protocolo y puerto (o puertos) y el tipo de "conexión".

Finalmente, mediante `type`, define el tipo de acceso _desde el exterior_. En el ejemplo he elegido el tipo `LoadBalancer`.

> Este tipo de acceso creo que no está disponible en Minikube, por lo que si usas este entorno para las pruebas, quizás debas usar `type: NodePort`.

En resumen, el servicio expone el conjunto de _pods_ que verifican la condición expuesta en el `selector` y conecta los puertos locales -de los contenedores- con puertos externos a nivel de clúster de Kubernetes.

# Crea el _service_

El método para crear/actualizar el _service_ es el mismo que para el _deployment_:

```sh
kubectl apply -f nginx-service.yaml
```

Una vez aplicado el _service_, usa `describe` para inspeccionar en detalle el objeto:

```sh
$ kubectl describe service nginx
Name:       nginx
Namespace:     default
Labels:        app=nginx
Annotations:      kubectl.kubernetes.io/last-applied-configuration={"apiVersion":"v1","kind":"Service","metadata":{"annotations":{},"labels":{"app":"nginx"},"name":"nginx","namespace":"default"},"spec":{"ports":[{"port...
Selector:      app=nginx
Type:       LoadBalancer
IP:         10.107.44.10
Port:       <unset>  80/TCP
NodePort:      <unset>  31010/TCP
Endpoints:     10.32.0.3:80
Session Affinity: None
Events:        <none>
```

Para saber con qué puerto externo se ha conectado el puerto local 80/TCP necesitamos revisar el detalle del servicio creado. Como no hemos especificado ningún `targetPort` Kubernetes asigna uno libre al azar.

> El comportamiento es el mismo que cuando se lanza un contenedor mediante `docker run -P`

En mi caso el `NodePort` asignado es el 31010/TCP. Esto significa que si acceso a la IP del clúster a través del puerto 31010, Kubernetes redirigirá la petición al puerto 80 del servicio, con lo que obtendré la página de bienvenida de Nginx.

{{% img src="images/170716/nginx-en-kubernetes.png" %}}

Este es el resultado marcado como éxito para este experimento.

# Resumen

En este artículo he explicado los pasos necesarios para publicar una aplicación en un clúster de Kubernetes:

1. Crear un _Deployment_
1. Crear un _Service_

El _deployment_ crea los diferentes _pods_ que componen la aplicación. El _service_ los agrupa de manera funcional y los expone para que sean accesibles _desde el exterior_ del clúster.
