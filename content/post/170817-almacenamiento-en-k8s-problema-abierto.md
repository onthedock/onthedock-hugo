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

title=  "Almacenamiento en Kubernetes: problema abierto"
date = "2017-08-17T17:11:05+02:00"
+++

Leía el otro día que desde el principio la tendencia hacia los microservicios estaba pensada para las aplicaciones _stateless_, es decir, sin "memoria" del estado, donde cada interacción con la aplicación se considera independiente del resto. El ejemplo clásico de aplicación _stateless_ es un servidor web. Así que no es de extrañar que la aplicación que siempre aparece en todo tutorial que se precie de Docker/Kubernetes  es Nginx.

En el mundo real, sin embargo, la mayoría de aplicaciones requieren algún tipo de persistencia, incluso las webs más sencillas (así surgieron las _cookies_). Pero por el momento, Kubernetes y el almacenamiento son dos conceptos que no combinan demasiado bien, aunque funcionan perfectamente por separado.

<!--more-->

Los contenedores (y los _pods_) son objetos perecederos, de _usar y tirar_, casi literalmente. Pero claro, esto es un problema cuando quieres almacenar datos. En Docker la solución pasa por los volúmenes, bien montados directamente desde el _host_ en el contenedor o usando **contenedores de datos**. No me consta que en Kubernetes exista la opción de crear contenedores de este tipo. En cuanto a la opción de montar una carpeta del _host_ en un contenedor deja de ser viable en cuanto tienes más de un nodo, por lo que la solución pasa por sacar el almacenamiento **fuera** del clúster de Kubernetes.

"Fuera" quiere decir que la aplicación guarda la información en una base de datos en una máquina -física o virtual- a la que la  aplicación se conecta remotamente. Otro caso habitual es el almacenamiento de ficheros; en este caso la aplicación en Kubernetes se conecta a algún tipo de recurso compartido externo, normalmente NFS o almacenamiento en la nube ([AWS EBS](https://aws.amazon.com/es/ebs/), [AWS S3](https://aws.amazon.com/s3/?nc2=h_m1) o [Google Cloud Storage](https://cloud.google.com/products/storage/)). En este sentido hay dos soluciones destacadas: [GlusterFS](https://www.gluster.org/) y [Ceph](http://ceph.com/).

## Almacenamiento en Kubernetes: un proceso de dos fases

Sea como sea, el proceso de conseguir almacenamiento para un _pod_ en Kubernetes tiene dos fases: la **provisión** y el **consumo** del.

El primer aspecto -la provisión- queda fuera del ámbito de Kubernetes y corre a cargo de un "administrador", que define los _PersistentVolumes_ **fuera** del clúster: en Gluster, un servidor NFS o en un servicio cloud.

En la segunda fase, un usuario -en el fichero de definición del _Pod_ o cualquier otro objeto en Kubernetes que requiera almacenamiento- **reclama** el espacio para ser usado mediante un _PersistentVolumeClaim_.

En función del sistema de almacenamiento, cuando se reclamar una determinada cantidad de almacenamiento de un _StorageClassName_ concreto que lo soporte, Kubernetes puede provisionar dinámicamente el volumen.

El hecho de que la provisión de almacenamiento quede fuera del ámbito de los tutoriales supone que la curva de aprendizaje de Kubernetes se convierte en un _rampa empinada_ en cuanto dejas los ejemplos basados en Nginx.

## Mi experiencia personal

Estoy aprovechando para mejorar mis conocimientos sobre Kubernetes siguiendo los tutoriales de la página oficial [Kubernetes.io](https://kubernetes.io/docs/tutorials/). Al intentar seguir el tutorial [StatefulSet Basics](https://kubernetes.io/docs/tutorials/stateful-application/basic-stateful-set/) se da por supuesto conocimiento con el provisionamiento de _PersistentVolume_. En particular, se supone que el clúster está configurado para provisionar **dinámicamente** _PersistentVolumes_, o en su defecto, que se provisionen manualmente.

> This tutorial assumes that your cluster is configured to dynamically provision PersistentVolumes. If your cluster is not configured to do so, you will have to manually provision five 1 GiB volumes prior to starting this tutorial.

Desafortunadamente, no hay ningún tutorial sobre cómo crear los _PersistentVolumes_ y en la página de [Conceptos sobre _PersistentVolumes_](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) no me queda claro la relación entre el _PersistentVolumeClaim_ que se especifica en el _pod_ de ejemplo y el apartado _VolumeClaimTemplates_ que aparece en la definición del _StatefulSet_. En particular, en [Claims as Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#claims-as-volumes) se indica que los _pods_ acceden al almacenamiento usando el _claim_ como un volumen.

> The cluster finds the claim in the pod’s namespace and uses it to get the PersistentVolume backing the claim. The volume is then mounted to the host and into the pod.

Sobre **cómo** encuentra el clúster el _claim_ en el espacio de nombres del _pod_ y lo relaciona con un _PersistentVolume_ disponible, no se dan detalles.

En la próxima entrada explicaré cómo conseguí crear correctamente los _pods_ del _StatefulSet_ del tutorial. 

> **Actualización**: La entrada ya está publicada: [Troubleshooting: Creación de pods del tutorial 'StatefulSet Basics']({{< ref "170818-troubleshooting-creacion-de-pods-del-tutorial-statefulset-basics.md" >}})

El problema de ráiz era que creaba un _PersistentVolume_ y un _PersistentVolumeClaim_ manualmente (como se indica en la página de conceptos). El _PVClaim_ se _enlazaba_ (_bound_) correctamente con el _PV_. Sin embargo, los _pods_ del _StatefulSet_ no se creaban. Examinando al detalle los _pods_ observé que la creación del _pod_ desde el _StatefulSet_ creaba un nuevo _PVClaim_ que no conseguía ligarse a ningún _PV_ disponible.

Al desconocer el mecanismo por el cual un _claim_ "encuentra" un _PV_ adecuado, la única vía disponible fue la de _ensayo y error_.

El siguiente objetivo es crear un tutorial _previo_ al de [StatefulSet Basics](https://kubernetes.io/docs/tutorials/stateful-application/basic-stateful-set/) donde describir el proceso de creación de los _PersistentVolumes_ para el _StatefulSet_ del tutorial.