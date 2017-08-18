+++
draft = false

# TAGS
# HW->OS->PRODUCT->specific tag
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "kubernetes"]

# CATEGORIES = "dev" / "ops"
categories = ["dev", "ops"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/kubernetes.png"

# SHORTCODES (for reference)
# YouTube
# {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Imagenes
# {{% img src="images/image.jpg" w="600" h="400" %}}
# {{% img src="images/image.jpg" w="600" h="400" class="right" %}}
# {{% img src="images/image.jpg" w="600" h="400" class="left" %}}
# {{% img src="images/image.jpg" w="600" h="400" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# Clear (floats)
# {{% clear %}}
# Twitter
# {{% twitter tweetid="780599416621297xxx" %}}

title=  "Troubleshooting: Creación de pods del tutorial 'StatefulSet Basics'"
date = "2017-08-18T17:45:03+02:00"
+++

Esta entrada es un registro de las diferentes acciones que realicé para conseguir que los _pods_ asociados al _StatefulSet_ del tutorial [StatefulSet Basics](https://kubernetes.io/docs/tutorials/stateful-application/basic-stateful-set/) se crearan correctamente.

Lo publico como lo que es, un _log_ de todos los pasos que fui dando, en modo _ensayo y error_, hasta que conseguí que los _pods_ se crearan con éxito. Mi intención al publicarlo no es tanto que sirva como referencia sino como archivo. Y si alguien se encuentra con un problema similar, que pueda consultar los pasos que he dado durante el _troubleshooting_.

Como indicaba en el artículo anterior, quiero publicar un tutorial paso a paso con el proceso correcto para provisionar los _PersistentVolumes_ necesarios para el tutorial [StatefulSet Basics](https://kubernetes.io/docs/tutorials/stateful-application/basic-stateful-set/) del sitio de Kubernetes.

<!--more-->

# Creación de un _StatefulSet_

[StatefulSet Basics](https://kubernetes.io/docs/tutorials/stateful-application/basic-stateful-set/)

## Creación del _PersistentVolume_

1. Creamos la carpeta que contiene el _PersistentVolume_:

    ```shell
    mkdir /tmp/data/pv001 -p
    ```

1. Definimos el _PersistentVolume_ (`vi pv001.yaml`):

    ```yaml
    kind: PersistentVolume
    apiVersion: v1
    metadata:
        name: pv001
        labels:
            type: local
    spec:
        storageClassName: manual
        capacity:
            storage: 1Gi
        accessModes:
        - ReadWriteOnce
        hostPath:
            path: "/tmp/data/pv001"
    ```

1. Creamos el _PersistentVolume_

    ```shell
    $ kubectl apply -f pv001.yaml
    persistentvolume "pv001" created
    $ kubectl get pv
    NAME      CAPACITY   ACCESSMODES   RECLAIMPOLICY   STATUS      CLAIM     STORAGECLASS   REASON    AGE
    pv001     1Gi        RWO           Retain          Available             manual                   10s
    ```

1. Definimos un _PersistentVolumeClaim_ (`pv001claim.yaml`)

    ```shell
    $ vi pv001-claim.yaml
    kind: PersistentVolumeClaim
    apiVersion: v1
    metadata:
        name: pv001claim
    spec:
        storageClassName: manual
        accessModes:
        - ReadWriteOnce
        resources:
            requests:
                storage: 1Gi
    ```

1. Creamos el _PersistentVolumeClaim_

    ```shell
    $ kubectl apply -f pv001-claim.yaml
    persistentvolumeclaim "pv001claim" created
    ```

1. Verificamos que el _PVClaim_ ha quedado ligado al _PV_:

    ```shell
    $ kubectl get pvc
    NAME         STATUS    VOLUME    CAPACITY   ACCESSMODES   STORAGECLASS   AGE
    pv001claim   Bound     pv001     1Gi        RWO           manual         43s
    ```

## Creación del _StatefulSet_

### Creación del _headless service_

1. Definimos el _headless service_ `nginx`

```yaml
kind: Service
apiVersion: v1
metadata:
    name: nginx
    labels:
        app: nginx
spec:
    ports:
- port: 80
name: web
clusterIP: None # Headless Service
selector:
    app: nginx
```

1. Creamos el servicio:
   ```shell
    $ kubectl apply -f nginx_svc.yaml
    service "nginx" created
   ```

## Definición del _StatefulSet_

1. Definimos el _StatefulSet_

    ```yaml
    kind: StatefulSet
    apiVersion: apps/v1beta1
    metadata:
        name: web
    spec:
        serviceName: "nginx"
        replicas: 2
        template:
            metadata:
                labels:
                    app: nginx
            spec:
                containers:
                - name: nginx
                image: gcr.io/google_containers/nginx-slim:0.8
                ports:
                - containerPort: 80
                    name: web
                volumeMounts:
                - name: www
                mountPath: /usr/shere/nginx/html
        volumeClaimTemplates:
        - metadata:
            name: www
        spec:
            accessModes: [ "ReadWriteOnce" ]
            resources:
                requests:
                    storage: 1Gi
    ```

1. Creamos el _StatefulSet_:
   ```shell
    $ kubectl apply -f statefulset.yaml
    statefulset "web" created
   ```

1. Verificamos:
   ```shell
    $ kubectl get statefulset
    NAME      DESIRED   CURRENT   AGE
    web       2         1         53s
    $ kubectl describe statefulset web
    Name:                   web
    Namespace:              default
    CreationTimestamp:      Thu, 17 Aug 2017 09:55:10 +0000
    Selector:               app=nginx
    Labels:                 app=nginx
    Annotations:            kubectl.kubernetes.io/last-applied-configuration={"apiVersion":"apps/v1beta1","kind":"StatefulSet","metadata":{"annotations":{},"name":"web","namespace":"default"},"spec":{"replicas":2,"serviceName":"...
    Replicas:               2 desired | 1 total
    Pods Status:            0 Running / 1 Waiting / 0 Succeeded / 0 Failed
    Pod Template:
    Labels:       app=nginx
    Containers:
    nginx:
        Image:              gcr.io/google_containers/nginx-slim:0.8
        Port:               80/TCP
        Environment:        <none>
        Mounts:
        /usr/shere/nginx/html from www (rw)
    Volumes:      <none>
    Volume Claims:
    Name:         www
    StorageClass:
    Labels:       <none>
    Annotations:  <none>
    Capacity:     1Gi
    Access Modes: [ReadWriteOnce]
    Events:
    FirstSeen     LastSeen        Count   From            SubObjectPath   Type            Reason                  Message
    ---------     --------        -----   ----            -------------   --------        ------                  -------
    2m            2m              1       statefulset                     Normal          SuccessfulCreate        create Claim www-web-0 Pod web-0 in StatefulSet web success
    2m            2m              1       statefulset                     Normal          SuccessfulCreate        create Pod web-0 in StatefulSet web successful
    $
   ```

    Observamos que hay 1 _pod_ en _waiting_.

    Revisamos los _pods_

    ```shell
    kubectl get pods
    NAME      READY     STATUS    RESTARTS   AGE
    web-0     0/1       Pending   0          5m
    $ kubectl describe pod web-0
    Name:           web-0
    Namespace:      default
    Node:           <none>
    Labels:         app=nginx
                    controller-revision-hash=web-3274782773
    Annotations:    kubernetes.io/created-by={"kind":"SerializedReference","apiVersion":"v1","reference":{"kind":"StatefulSet","namespace":"default","name":"web","uid":"27fe7496-8332-11e7-9fc4-024216ac27e1","apiVersion":...
    Status:         Pending
    IP:
    Created By:     StatefulSet/web
    Controlled By:  StatefulSet/web
    Containers:
    nginx:
        Image:              gcr.io/google_containers/nginx-slim:0.8
        Port:               80/TCP
        Environment:        <none>
        Mounts:
        /usr/shere/nginx/html from www (rw)
        /var/run/secrets/kubernetes.io/serviceaccount from default-token-klj21 (ro)
    Conditions:
    Type          Status
    PodScheduled  False
    Volumes:
    www:
        Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
        ClaimName:  www-web-0
        ReadOnly:   false
    default-token-klj21:
        Type:       Secret (a volume populated by a Secret)
        SecretName: default-token-klj21
        Optional:   false
    QoS Class:      BestEffort
    Node-Selectors: <none>
    Tolerations:    node.alpha.kubernetes.io/notReady:NoExecute for 300s
                    node.alpha.kubernetes.io/unreachable:NoExecute for 300s
    Events:
    FirstSeen     LastSeen        Count   From                    SubObjectPath   Type            Reason                  Message
    ---------     --------        -----   ----                    -------------   --------        ------                  -------
    7m            7s              29      default-scheduler                       Warning         FailedScheduling        PersistentVolumeClaim is not bound:"www-web-0"
    $
    ```

    El problema está en que no consigue _montar_ el _PersistentVolumeClaim_. En la salida del comando el _ClaimName_ es `www-web-0`.

1. Troubleshooting del primer _pod_

    1. Cambio de nombre del _PVClaim_

        No parece ser posible actualizar un _PVClaim_, por lo que borramos y creamos uno con el nombre `www`. No hay ninguna diferencia.

        Eliminamos el _PVClaim_ ligado al _PV_, pero tampoco cambia nada.

        Eliminamos el _PV_ y lo creamos de nuevo, para ver si el _PVClaim_ lo enlaza. Tampoco funciona.

    1. Eliminar _StorageClassName_ del _PV_

        El _PVClaim_ creado automáticamente con el _StatefulSet_ no especifica una _StorageClassName_. Vamos a crear un nuevo _PV_ **sin _StorageClassName_**. Tras unos segundos, el _PVClaim_ enlaza con el nuevo _PV_ automáticamente.

        ```shell
        $ kubectl apply -f pv001.yaml
        persistentvolume "pv001" created
        $ kubectl get pvc
        NAME        STATUS    VOLUME    CAPACITY   ACCESSMODES   STORAGECLASS   AGE
        www         Pending                                      manual         8m
        www-web-0   Pending                                                     21m
        $ kubectl get pvc
        NAME        STATUS    VOLUME    CAPACITY   ACCESSMODES   STORAGECLASS   AGE
        www         Pending                                      manual         8m
        www-web-0   Pending                                                     22m
        $ kubectl get pvc
        NAME        STATUS    VOLUME    CAPACITY   ACCESSMODES   STORAGECLASS   AGE
        www         Pending                                      manual         8m
        www-web-0   Bound     pv001     1Gi        RWO                          22m
        ```

        Eliminamos el _PVClaim_ creado manualmente.

        Revisamos qué ha pasado con los _pods_ pendientes de creación.

        ```shell
        $ kubectl get pods
        NAME      READY     STATUS    RESTARTS   AGE
        web-0     0/1       Pending   0          24m
        $ kubectl describe pod web-0
        ...
        Events:
        FirstSeen     LastSeen        Count   From                    SubObjectPath   Type            Reason                  Message
        ---------     --------        -----   ----                    -------------   --------        ------                  -------
        25m           3m              78      default-scheduler                       Warning         FailedScheduling        PersistentVolumeClaim is not bound:"www-web-0"
        2m            11s             14      default-scheduler                       Warning         FailedScheduling        No nodes are available that match all of the following predicates:: PodToleratesNodeTaints (1).
        ```

        Parece que el mensaje de error se debe a que no hay nodos disponibles donde planificar el _pod_. Aunque estoy haciendo las pruebas con un clúster de un solo nodo, he aplicado el _taint_ para poder planificar _pods_ en el nodo **master**. Por si acaso, aplicamos de nuevo:

        ```shell
        $ kubectl taint nodes --all node-role.kubernetes.io/master-
        node "node1" untainted
        ```

        Revisamos los _pods_ de nuevo:

        ```shell
        $ kubectl describe pod web-0
        ...
        Events:
        FirstSeen     LastSeen        Count   From                    SubObjectPath           Type            Reason                  Message
        ---------     --------        -----   ----                    -------------           --------        ------                  -------
        33m           11m             78      default-scheduler                               Warning         FailedScheduling        PersistentVolumeClaim is not bound: "www-web-0"
        10m           1m              36      default-scheduler                               Warning         FailedScheduling        No nodes are available that match all of the following predicates:: PodToleratesNodeTaints (1).
        33s           33s             1       default-scheduler                               Normal          Scheduled               Successfully assigned web-0 to node1
        33s           33s             1       kubelet, node1                                  Normal          SuccessfulMountVolume   MountVolume.SetUp succeeded for volume "pv001"
        33s           33s             1       kubelet, node1                                  Normal          SuccessfulMountVolume   MountVolume.SetUp succeeded for volume "default-token-klj21"
        32s           32s             1       kubelet, node1          spec.containers{nginx}  Normal          Pulling                 pulling image "gcr.io/google_containers/nginx-slim:0.8"
        26s           26s             1       kubelet, node1          spec.containers{nginx}  Normal          Pulled                  Successfully pulled image"gcr.io/google_containers/nginx-slim:0.8"
        26s           26s             1       kubelet, node1          spec.containers{nginx}  Normal          Created                 Created container
        26s           26s             1       kubelet, node1          spec.containers{nginx}  Normal          Started                 Started container
        $
        ```
1. Troubleshooting del segundo _pod_

    Ya tenemos un _pod_ corriendo... Pero todavía nos falta otro :(

    ```shell
    $ kubectl get pods
    NAME      READY     STATUS    RESTARTS   AGE
    web-0     1/1       Running   0          34m
    web-1     0/1       Pending   0          1m
    $ kubectl describe pod web-1
    ...
                    node.alpha.kubernetes.io/unreachable:NoExecute for 300s
    Events:
    FirstSeen     LastSeen        Count   From                    SubObjectPath   Type            Reason                  Message
    ---------     --------        -----   ----                    -------------   --------        ------                  -------
    2m            1s              9       default-scheduler                       Warning         FailedScheduling        PersistentVolumeClaim is not bound: "www-web-1"
    ```

    Seguimos teniendo el problema de que no tenemos el _PVClaim_ enlazado con un _PV_. Parece claro que el la causa es que sólo hemos creado un _PV_ y necesitamos otro para el segundo _pod_.

    Creamos un segundo _PV_ (sin especificar _StorageClassName_):

    ```shell
    mkdir /tmp/data/pv002 -p
    cp pv001.yaml pv002.yaml
    vi pv002.yaml
    ```

    Modificamos el fichero de definición del `pv002` para cambiar el nombre y la ruta a la carpeta donde se almacenarán los ficheros.

    Creamos el `pv002`:

    ```shell
    $ kubectl apply -f pv002.yaml
    persistentvolume "pv002" created
    ```

    Revisamos de nuevo el estado del segundo _pod_:

    ```shell
    $ kubectl get pods
    NAME      READY     STATUS    RESTARTS   AGE
    web-0     1/1       Running   0          42m
    web-1     1/1       Running   0          9m
    ```

## Resumen

Después de estar peleando con los diferentes problemas que he encontrado, queda claro que:

1. Es necesario crear los _PersistentVolumes_ sin _StorageClassName_ o especificar en el _PVClaim_ el mismo _StorageClassName_ indicado en el _PV_. Este caso no tengo claro cómo debe hacerse.
1. Hay que crear tantos _PersistentVolumes_ como _pods_ existan en el _StatefulSet_.

Queda pendiente crear una guía de creación de los _PersistentVolumes_ para ser consumidos por los _pods_.