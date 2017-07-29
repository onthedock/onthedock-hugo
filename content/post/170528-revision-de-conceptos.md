+++
date = "2017-05-28T07:59:31+02:00"
title = "Revisión de conceptos"
thumbnail = "images/kubernetes.png"
categories = ["dev", "ops"]
tags = ["kubernetes"]
draft = false

+++

Después de estabilizar el clúster, el siguiente paso es poner en marcha aplicaciones. Pero ¿qué es exactamente lo que hay que desplegar?: ¿_pods_?, ¿_replication controllers_?, ¿_deployments_?

Muchos artículos empiezan creando el fichero YAML para un _pod_, después construyen el _replication controller_, etc... Sin embargo, revisando la documentación oficial, crear _pods_ directamente en Kubernetes no tiene mucho sentido.

En este artículo intento determinar qué objetos son los que deben crearse en un clúster Kubernetes.
<!--more-->

# Pod

La unidad fundamental de despliegue en Kubernetes es el [**Pod**](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/). Un _pod_ sería el equivalente a la mínima unidad funcional de la aplicación.

En general, un _pod_ contendrá únicamente un contenedor, aunque no tiene que ser así: si tenemos dos contenedores que actúan de forma conjunta, podemos desplegarlos dentro de un solo _pod_. Dentro de un _pod_ todos los contenedores se pueden comunicar entre ellos usando `localhost`, por lo que es una manera sencilla de desplegar en Kubernetes aplicaciones que, aunque hayan sido _containerizadas_, no puedan modificarse para comunicarse con otras partes de la aplicación usando una IP o un nombre DNS (porque la aplicación espera que el resto de _partes_ de la aplicación estén en el mismo equipo).

En este sentido, todos los contenedores dentro de un _pod_ se podría decir que están instaladas en una mismo equipo (como un _stack_ LAMP).

Sin embargo, un _pod_ es un elemento **no-durable**, es decir, que puede fallar o ser eliminado en cualquier momento. Por tanto, **no es una buena idea desplegar _pods_ individuales en Kubernetes**.

Como indica la [documentación para los _pods_ de la API para la versión 1.6 de Kubernetes](https://kubernetes.io/docs/api-reference/v1.6/#pod-v1-core):

> It is recommended that users create Pods only through a Controller, and not directly.

# ReplicaSet y Replication Controller

El [**Replication Controller**](https://kubernetes.io/docs/concepts/workloads/controllers/replicationcontroller/) o la versión _mejorada_, el [**ReplicaSet**](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/) se encarga de mantener un determinado número de réplicas del _pod_ en el clúster. 

El _ReplicaSet_ asegura que un determinado número de copias -**réplicas**- del _pod_ se encuentran en ejecución en el clúster en todo momento. Por tanto, si alguno de los _pods_ es eliminado, el _ReplicaSet_ se encarga de crear un nuevo _pod_. Para ello, el _ReplicaSet_ incluye una plantilla con la que crear nuevos _pods_.

Así, el _ReplicaSet_ define el **estado deseado** de la aplicación: cuántas copias de mi aplicación quiero tener en todo momento en ejecución en el clúster. 
Modificando el número de réplicas para el _ReplicaSet_ podemos **escalar** (incrementar o reducir) el número de copias en ejecución en función de las necesidades. 

Por tanto, parece que el mejor candidato para ponerse a definir ficheros `YAML` y desplegar aplicaciones en el clúster de Kubernetes sería un _ReplicaSet_.

Si embargo, la [documentación oficial](https://kubernetes.io/docs/api-reference/v1.6/#replicaset-v1beta1-extensions) nos ofrece otra opción:

> In many cases it is recommended to create a Deployment instead of ReplicaSet.

Es decir, tenemos una opción mejor: el [**Deployment**](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/).

# Deployment

El _Deployment_ añade la capacidad de poder actualizar la aplicación definida en un _ReplicaSet_ sin pérdida de servicio, mediante **actualización continua** (_rolling update_).

Si el estado deseado de la aplicación son tres réplicas de un pod basado en `yomismo/app-1.0` y queremos actualizar a `yomismo/app-2.0`, el _Deployment_ se encarga de realizar la transición de la versión 1.0 a la 2.0 de forma que no haya interrupción del servicio. La estrategia de actualización puede definirse manualmente, pero sin entrar en detalles, Kubernetes se encarga de ir eliminado progresivamente las réplicas de la aplicación v1.0 y sustituirlas por las de la v2.0.

El proceso se hace de forma controlada, por lo que si surgen problemas con la nueva versión de la aplicación, la actualización se detiene y es posible realizar _marcha atrás_ hacia la versión estable.

# Resumiendo

Así pues, después de leer la sección de [Concepts](https://kubernetes.io/docs/concepts/) de la documentación de Kubernetes, parece que ya tengo claro cuál es el proceso para desplegar aplicaciones en Kubernetes.

* En Docker
   1. Crear fichero `Dockerfile`
   1. Construir imagen personalizada
   1. Subir imagen a un _Registry_ (de momento, DockerHub)
* En Kubernetes
   1. Crear fichero `YAML` definiendo el _Deployment_
   1. Crear _Deployment_ en el clúster

Hay otros objetos específicos que pueden ser más adecuados para tus necesidades:

* _DaemonSets_ : despliegan una copia de un _pod_ en cada nodo del clúster. Por ejemplo, un antivirus, o una herramienta de gestión de logs, etc
* _Jobs_ y _CronJobs_: crean _pods_ hasta asegurar que un número determinado finaliza con éxito, lo que completa el _job_.
* _StatefulSets_ : todavía en Beta, asignan una identidad única a los _pods_, lo que garantiza que se creen o escalen en un orden determinado.

# Siguientes pasos

Al final de este proceso tendré una aplicación _simple_ desplegada en el clúster. Con "sencilla" quiero decir que las diferentes instancias de la aplicación actuan de forma independiente. Un ejemplo sería un servidor web: con el _deployment_ sería posible escalar la aplicación para dar respuesta a la demanda en todo momento y actualizar el contenido de la web sin interrupciones.

El siguiente paso es crear una aplicación _compleja_ en la que tengamos, por ejemplo, un _frontend_ y un _backend_. Para estas situaciones, necesitaremos definir un [**servicio**](https://kubernetes.io/docs/concepts/services-networking/service/).
