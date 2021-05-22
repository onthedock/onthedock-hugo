+++
categories = ["ops"]
tags = ["linux", "kubernetes", "tareas"]
draft = false
thumbnail = "images/kubernetes.png"
date = "2017-07-29T21:12:35+02:00"
title = "Asignar recursos de CPU y RAM a un contenedor"

+++

Cuando se crea un _pod_ se pueden reservar recursos de CPU y RAM para los contenedores que corren en el _pod_. Para reservar recursos, usa el campo `resources: requests` en el fichero de configuración. Para establecer límites, usa el campo `resources: limits`.

<!--more-->

Kubernetes planifica un _pod_ en un nodo sólo si el nodo tiene suficientes recursos de CPU y RAM disponibles para satisfacer la demanda de CPU y RAM total de todos los contenedores en el _pod_. Es decir, la _request_ es la cantidad que necesita el _pod_ para arrancar y ponerse en funcionamiento.

En función de las tareas que ejecute el _pod_, los recursos que consume pueden aumentar. Mediante el establecimiento de los _limits_ podemos acotar el uso máximo de recursos disponible para el _pod_.

Kubernetes no permite que el _pod_ consuma más recursos de CPU y RAM de los límites especificados para en el fichero de configuración.

Si un contenedor excede el límite de RAM, es eliminado.

{{< figure src="/images/170729/k8s-pod-ram-requests-and-limits.svg" >}}

Si un contenedor excede el límite de CPU, se convierte en un candidato para que su uso de CPU se vea restringido (_throttling_) .

{{< figure src="/images/170729/k8s-pod-cpu-requests-and-limits.svg" >}}

# Unidades de CPU y RAM

Los recursos de CPU se miden en **cpus**. Se admiten valores fraccionados. Puedes usar el sufijo _m_ para indicar "mili"; por ejemplo, `100m cpu` son `100 milicpu` o `0.1 cpu`.

Los recursos de RAM se miden en **bytes**. Puedes indicar la RAM como un entero usando alguno de los siguientes sufijos: `E`, `P`, `T`, `G`, `M`, `Ei`, `Pi`,`Ti`, `Gi`, `Mi`y `Ki`. Por ejemplo, las siguientes cantidades representan aproximadamente el mismo valor:

```txt
128974848, 129e6, 129M , 123Mi
```

Si no conoces por adelantado los recursos que reservar para un _pod_ puedes lanzar la aplicación sin especificar límites, usar el monitor de uso de recursos y determinar los valores apropiados.

Si un contenedor excede los límites establecidos de RAM, se elimina al quedarse sin memoria disponible: `out-of-memory`. Debes especificar un valor ligeramente superior al valor esperado para dar un poco de margen al _pod_.

Si especificas una reserva (`request`), el _pod_ tendrá garantizado disponer de la cantidad reservada del recurso. El _pod_ puede usar más recursos que los reservados, pero nunca más del límite establecido.

En el siguiene ejemplo, especificamos tanto una reserva como el límite de recursos de los que puede disponer un _pod_:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: cpu-ram-demo
spec:
  containers:
  - name: cpu-ram-demo-container
    image: gcr.io/google-samples/node-hello:1.0
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"
        cpu: "1"
```

El _pod_ reserva 64Mi de RAM y 0.25 cpus, pero puede llegar a usar hasta el doble de RAM y toda una CPU.

# Si no especificas reservas o límites

Si no especificas un límite para la RAM, Kubernetes no restinge la cantidad de RAM que puede usar el contenedor. En esta situación un contenedor puede usar toda la memoria disponible en el nodo donde se está ejecutando. Del mismo modo, si no se especifica un límite máximo de CPU, un contenedor puede usar toda la capacidad de CPU del nodo.

Los límites por defecto se aplican en función de la disponibilidad de recursos aplicados al espacio de nombres en el que se ejecutan los _pods_. Puedes consultar los límites mediante: `kubectl describe limitrange limits`.

Es importante tener en cuenta que si se especifican límites a nivel de _namespace_, la creación de objetos en el _namespace_ debe incluir también los límites o se producirán errores al crear objetos (a no ser que se hayan especificado límites por defecto).

En [Set Pod CPU and Memory Limits](https://kubernetes.io/docs/tasks/administer-cluster/cpu-memory-limit/) se indica cómo establecer límites superiores e inferiores para los recursos de un _pod_. También se pueden especificar límites por defecto para los _pods_ aunque el usuario no los haya especificado en el fichero de configuración.

Los límites establecidos en el _namespace_ se aplican durante la creación o modificación de los _pods_. Si cambias el rango de recursos permitidos, no afecta a los _pods_ creados previamente en el espacio de nombres.

Se pueden establecer límites en los recursos consumidos por diferentes motivos, pero normalmente se limitan para evitar problemas _a posteriori_. Por ejemplo, si un nodo tiene 2GB de RAM, evitando la creación de _pods_ que requieran más memoria previene que el _pod_ no pueda desplegarse nunca (al no disponer de memoria suficiente disponible), por lo que es mejor evitar directamente su creación.

El otro motivo habitual para imponer límites es para distribuir los recursos del nodo entre los diferentes equipos/entornos; por ejemplo, asignando un 25% de la capacidad al equipo de desarrollo y el resto a los servicios en producción.

## Actualización

En el caso de que se establezca sólo una de las dos opciones (es decir, sólo _request_ o sólo límites), Kubernetes actúa de la siguiente manera:

* Si sólo se establecen límites, Kubernetes establece una reserva (_request_) **igual** al límite.
* Si sólo se establece una reserva, no hay un límite definido, por lo que el _pod_ puede llegar a consumir el total de la memoria/CPU disponible en el nodo.