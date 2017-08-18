+++
date = "2017-07-23T20:04:45+02:00"
title = "Espacios de nombres en Kubernetes"
thumbnail = "images/kubernetes.png"
categories = ["ops"]
tags = ["linux", "kubernetes", "conceptos", "tareas"]
draft = false

+++

Los [_namespaces_ (espacios de nombres)](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/) en Kubernetes permiten establecer un nivel adicional de separación entre los contenedores que comparten los recursos de un clúster.

Esto es especialmente útil cuando diferentes grupos de DevOps usan el mismo clúster y existe el riesgo potencial de colisión de nombres de los _pods_, etc usados por los diferentes equipos.

<!--more-->

Los espacios de nombres también facilitan la creación de cuotas para limitar los recursos disponibles para cada _namespace_. Puedes considerar los espacios de nombres como clústers _virtuales_ sobre el clúster físico de Kubernetes. De esta forma, proporcionan separación lógica entre los entornos de diferentes equipos.

Kubernetes proporciona dos _namespaces_ por defecto: `kube-system` y `default`. A _grosso modo_, los objetos "de usuario" se crean en el espacio de nombres `default`, mientras que los de "sistema" se encuentran en `kube-system`.

Para ver los espacios de nombres en el clúster, ejecuta:

```sh
$ kubectl get namespaces
NAME          STATUS    AGE
default       Active    21d
kube-system   Active    21d
```

> Puedes obtener el mismo resultado usando `ns` en vez de `namespaces`

Para comprobar la separación lógica entre los objetos de diferentes _namespaces_, lista los pods mediante `kubectl get pods`:

```sh
$ kubectl get pods
NAME                     READY     STATUS    RESTARTS   AGE
nginx-3225377387-xdth3   1/1       Running   0          7d
```

Analizando al detalle el _pod_ mediante `kubectl describe pod nginx-3225377387-xdth3`, observa como se encuentra en el espacio de nombres `default`:

```sh
$ kubectl describe pod nginx-3225377387-xdth3
Name:    nginx-3225377387-xdth3
Namespace:  default
Node:    k8s-snc/192.168.1.10
...
```

Compara los resultados obtenidos con los comandos anteriores con el de `kubectl get pods --all-namespaces`:

```sh
$ kubectl get pods --all-namespaces
NAMESPACE     NAME                              READY     STATUS    RESTARTS   AGE
default       nginx-3225377387-xdth3            1/1       Running   0          7d
kube-system   etcd-k8s-snc                      1/1       Running   3          21d
kube-system   kube-apiserver-k8s-snc            1/1       Running   3          21d
kube-system   kube-controller-manager-k8s-snc   1/1       Running   3          21d
kube-system   kube-dns-2425271678-xbzt8         3/3       Running   12         21d
kube-system   kube-proxy-tbstt                  1/1       Running   3          21d
kube-system   kube-scheduler-k8s-snc            1/1       Running   3          21d
kube-system   weave-net-snspp                   2/2       Running   9          20d
```

La primera columna de la salida del comando anterior indica el espacio de nombres en el que se encuentra cada _pod_, en este caso.

# Crea un nuevo espacio de nombres

Para crear un _namespace_, crea un fichero `YAML` como el siguiente:

```yaml
apiVersion: v1
kind: Namespace
metadata:
   name: developers
```

> El nombre del _namespace_ debe ser compatible con una entrada válida de DNS.

Para crear el _namespace_, ejecuta:

```sh
$ kubectl create -f ns-developers.yaml
namespace "developers" created
```

Al obtener la lista de espacios de nombres disponibles, observa que ahora el nuevo _namespace_ aparece:

```sh
$ kubectl get ns
NAME          STATUS    AGE
default       Active    21d
developers    Active    55s
kube-system   Active    21d
```

Observa con detalle el _namespace_ creado:

```sh
$ kubectl describe ns developers
Name:    developers
Labels:     <none>
Annotations:   <none>
Status:     Active

No resource quota.

No resource limits.
```

Idealmente, el particionamiento del clúster en espacios de nombres permite repartir los recursos del clúster imponiendo cuotas, de manera que los objetos de un determinado _namespace_ no acaparen todos los recursos disponibles.

A continuación indico cómo establecer algunos límites para el _namespace_ (basado en [Apply Resource Quotas and Limits](https://kubernetes.io/docs/tasks/administer-cluster/apply-resource-quota-limit/)).

## Aplicando quotas al número de objetos en el _namespace_

Para aplicar una cuota, creamos un fichero `YAML` del tipo `ResourceQuota`:

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: object-counts
spec:
  hard:
    persistentvolumeclaims: "2"
    services.loadbalancers: "2"
    services.nodeports: "0"
```

Esta cuota limita el número de:

* volúmenes persistentes (2)
* balanceadores de carga (2)
* _node ports_ (0)

Para crear la cuota, aplica el fichero `YAML`.

> Debes especificar el _namespace_ donde aplicar la cuota.

```sh
$ kubectl create -f quota-object-counts.yaml --namespace developers
resourcequota "object-counts" created
```

Comprobamos que se ha aplicado la cuota al _namespace_ `developers`:

```sh
$ kubectl describe ns developers
Name:    developers
Labels:     <none>
Annotations:   <none>
Status:     Active

Resource Quotas
 Name:         object-counts
 Resource      Used  Hard
 --------      ---   ---
 persistentvolumeclaims 0  2
 services.loadbalancers 0  2
 services.nodeports  0  0

No resource limits.
```

Esta cuota impide la creación de más objetos de cada tipo de los especificados en la cuota (es decir, como máximo, puede haber dos _load balancers_ en el espacio de nombres `developers`).

## Aplicando cuotas a los recursos del _namespace_

Habitualmente los límites que se suelen establecer para cada espacio de nombres están enfocados a limitar los recursos de CPU y memoria del _namespace_.

El siguiente fichero `YAML` especifica un límite de 2 CPUs y 2GB de memoria. Además, especifica una limitación en cuanto a las peticiones que debe realizar un _pod_ en este espacio de nombres. Finalmente, también se establece una limitación de como máximo, 4 _pods_.

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-resources
spec:
  hard:
    limits.cpu: "2"
    limits.memory: 2Gi
    requests.cpu: "1"
    requests.memory: 1Gi
    pods: "4"
```

Aplicamos la nueva cuota mediante:

> De nuevo, recuerda que debes especificar el _namespace_ al que aplicar la cuota.

```sh
$ kubectl create -f quota-compute-resources.yaml --namespace developers
resourcequota "compute-resources" created
```

El espacio de nombres está limitado ahora de la siguiente manera:

```sh
$ kubectl describe ns developers
Name:          developers
Labels:        <none>
Annotations:   <none>
Status:     Active

Resource Quotas
 Name:            compute-resources
 Resource         Used  Hard
 --------         ---   ---
 limits.cpu       0     2
 limits.memory    0     2Gi
 pods             0     4
 requests.cpu     0     1
 requests.memory  0     1Gi

 Name:                  object-counts
 Resource               Used  Hard
 --------               ---   ---
 persistentvolumeclaims  0     2
 services.loadbalancers  0     2
 services.nodeports      0     0

No resource limits.
```

La limitación impuesta en las peticiones (`requests`) de memoria y CPU **obligan a que se especifiquen límites en la definición de los recursos asignados a cada _pod_**. En general, al crear la definición de un _deployment_ no se especifican estos límites, lo que puede provocar algo de desconcierto.

Vamos a crear un _Deployment_ en el _namespace_ `Developers`. Aunque asignamos el _deployment_ al _namespace_ desde la línea de comando, en un fichero `YAML` usaríamos:

```yaml
apiVersion: v1
kind: Service
metadata:
   name: ejemplo
   namespace: developers
spec:
   ...
```

Creamos un _deployment_:

```sh
$ kubectl run nginx --image=nginx --replicas=1 --namespace=developers
deployment "nginx" created
```

Todo parece ok hasta que buscamos el _pod_ que debería crearse:

```sh
$ kubectl get pods --namespace developers
No resources found.
```

Analizamos el detalle del _deployment_

```sh
$ kubectl describe deployment nginx --namespace developers
Name:       nginx
Namespace:     developers
CreationTimestamp:   Sun, 23 Jul 2017 21:19:57 +0200
Labels:        run=nginx
Annotations:      deployment.kubernetes.io/revision=1
Selector:      run=nginx
Replicas:      1 desired | 0 updated | 0 total | 0 available | 1 unavailable
StrategyType:     RollingUpdate
MinReadySeconds:  0
RollingUpdateStrategy:  1 max unavailable, 1 max surge
Pod Template:
  Labels:   run=nginx
  Containers:
   nginx:
    Image:     nginx
    Port:      <none>
    Environment:  <none>
    Mounts:    <none>
  Volumes:     <none>
Conditions:
  Type         Status   Reason
  ----         ------   ------
  Available       True  MinimumReplicasAvailable
  ReplicaFailure  True  FailedCreate
OldReplicaSets:      <none>
NewReplicaSet:    nginx-4217019353 (0/1 replicas created)
Events:
  FirstSeen LastSeen Count From        SubObjectPath  Type     Reason         Message
  --------- -------- ----- ----        -------------  -------- ------         -------
  2m     2m    1  deployment-controller         Normal      ScalingReplicaSet Scaled up replica set nginx-4217019353 to 1
```

No se ha creado el _ReplicaSet_. Vamos a ver porqué:

```sh
$ kubectl describe rs nginx-4217019353 --namespace developers
Name:    nginx-4217019353
Namespace:  developers
Selector:   pod-template-hash=4217019353,run=nginx
Labels:     pod-template-hash=4217019353
      run=nginx
Annotations:   deployment.kubernetes.io/desired-replicas=1
      deployment.kubernetes.io/max-replicas=2
      deployment.kubernetes.io/revision=1
Controlled By: Deployment/nginx
Replicas:   0 current / 1 desired
Pods Status:   0 Running / 0 Waiting / 0 Succeeded / 0 Failed
Pod Template:
  Labels:   pod-template-hash=4217019353
      run=nginx
  Containers:
   nginx:
    Image:     nginx
    Port:      <none>
    Environment:  <none>
    Mounts:    <none>
  Volumes:     <none>
Conditions:
  Type         Status   Reason
  ----         ------   ------
  ReplicaFailure  True  FailedCreate
Events:
  FirstSeen LastSeen Count From        SubObjectPath  Type     Reason      Message
  --------- -------- ----- ----        -------------  -------- ------      -------
  4m     1m    16 replicaset-controller         Warning     FailedCreate   Error creating: pods "nginx-4217019353-" is forbidden: failed quota: compute-resources: must specify limits.cpu,limits.memory,requests.cpu,requests.memory
```

El _deployment_ crea un _ReplicaSet_, que a su vez intenta crear uno o más _pods_. Como en el _Deployment_ no se ha especificado un límite para la CPU y memoria del _pod_ y lo hemos exigido en las cuotas impuestas al _namespace_, la creación del _pod_ falla. El mensaje de error es claro:

```sh
Error creating: pods "nginx-4217019353-" is forbidden: failed quota: compute-resources: must specify limits.cpu,limits.memory,requests.cpu,requests.memory
```

Si creamos el _pod_ especificando los límites:

```sh
$ kubectl run nginx \
  --image=nginx \
  --replicas=1 \
  --requests=cpu=100m,memory=256Mi \
  --limits=cpu=200m,memory=512Mi \
  --namespace=developers

$ kubectl get pods --namespace developers
NAME                     READY     STATUS    RESTARTS   AGE
nginx-2432944439-1zqs7   1/1       Running   0          19s
```

Ahora, al revisar el _namespace_:

```sh
$ kubectl describe ns developers
Name:    developers
Labels:     <none>
Annotations:   <none>
Status:     Active

Resource Quotas
 Name:            compute-resources
 Resource         Used  Hard
 --------         ---   ---
 limits.cpu       200m  2
 limits.memory    512Mi 2Gi
 pods             1     4
 requests.cpu     100m  1
 requests.memory  256Mi 1Gi

 Name:                  object-counts
 Resource               Used  Hard
 --------               ---   ---
 persistentvolumeclaims 0     2
 services.loadbalancers 0     2
 services.nodeports     0     0

No resource limits.
```

# _Namespace_ y DNS

Cuando se crear un _service_, se crea la correspondiente entrada en el DNS. Esta entrada es de la forma `<nombre-servicio>.<espacio-de-nombres>.svc.cluster.local`, lo que significa que si un contenedor usa únicamente `<nombre-de-servicio>`, la resolución del nombre se realizará de forma local en el espacio de nombres en el que se encuentre.

Esta configuración permite usar la misma configuración entre diferentes espacios de nombres (por ejemplo _Desarrollo_, _Integración_ y _Producción_).

Para que un contenedor pueda resolver el nombre de otro contenedor en otro _namespace_, debes usar el FQDN.

# Borrando un _namespace_

> AVISO: Al borrar un _namespace_ se borran **todos los objetos** del espacio de nombres.

Para borrar un _namespace_, usa el comando `delete`:

```sh
$ kubectl delete ns developers
namespace "developers" deleted
```

El borrado del _namespace_ es asíncrono, por lo que puedes verlo como `Terminating` hasta que se realiza el borrado definitivo del mismo:

```sh
$ kubectl get ns
NAME          STATUS        AGE
default       Active        21d
developers    Terminating   2h
kube-system   Active        21d
```

# Resumen

En este artículo hemos visto qué es un _Namespace_ y para qué sirve.

También hemos visto cómo crear un espacio de nombres, obtener información sobre él y crear objetos en el _namespace_.

Hemos aplicado cuotas para limitar los recursos disponibles y hemos visto cómo afecta a la creación de _deployments_ en el espacio de nombres.

Finalmente, hemos eliminado el espacio de nombres (y todos los objetos contenidos en él).
