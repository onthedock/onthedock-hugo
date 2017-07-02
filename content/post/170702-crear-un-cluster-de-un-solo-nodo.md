+++
date = "2017-07-02T23:14:22+02:00"
title = "Crear un cluster de un solo nodo"
tags = ["linux", "kubernetes"]
draft = false
thumbnail = "images/kubernetes.png"
categories = ["dev", "ops"]

+++

Para tener un clúster de desarrollo con la versatilidad de poder hacer y deshacer cambios (usando los _snapshots_ de una máquina virtual), lo más sencillo es disponer de un clúster de Kubernetes de un solo nodo.

<!--more-->
Por defecto, el nodo master de un clúster de Kubernetes no ejecuta ningún tipo de carga de trabajo relacionada con los pods desplegados en el clúster, centrándose en las tareas de gestión de los _pods_ y del propio clúster.

Para permitir que el nodo master pueda ejecutar _pods_, debemos modificar las opciones por defecto de Kubernetes. 

En primer lugar, comprobamos que todos los pods del espacio de nombres de sistema han arrancado y se ejecutan correctamente: 

```
$ kubectl get nodes --all-namespaces
```

Para que el nodo master admita el despliegue de _pods_, modificamos mediante:

```
$ kubectl taint nodes --all node-role.kubernetes.io/master-
node "k8s-snc" untainted
```