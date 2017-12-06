+++
draft = true
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

title=  "Buenas practicas en Kubernetes"
date = "2017-08-22T11:34:51+02:00"
+++

En la sección de [Concepts](https://kubernetes.io/docs/concepts/configuration/overview/) de la web de Kubernetes hay una sección de _buenas prácticas_.

En esta entrada recojo algunas de las buenas prácticas reflejadas en el artículo.

<!--more-->

## Recomendaciones generales de configuración

* Siempre especificar la última versión estable de la API (actualmente, v1).
* Los ficheros de configuración deben ser almacenados en sistemas de control de versiones **antes de ser aplicados en el clúster**. De esta forma es sencillo y rápido hacer un _roll-back_ de la configuración si es necesario. Además, ayuda a recrear y/o restaurar el clúster si es necesario.
* Es preferible escribir los ficheros de configuración en YAML en vez de JSON, aunque los dos formatos son intercambiables. En general, YAML es algo más amigable.
* Agrupa los ficheros de configuración en un sólo fichero siempre que tenga sentido. Así es más sencillo gestionarlo. Además, muchos comandos de `kubectl` pueden aplicarse a una carpeta completa, por lo que puedes ejecutar `kubectl create` sobre una carpeta de ficheros de configuración.
* No especifiques los valores por defecto, lo que ayuda a simplificar y minimizar los ficheros de configuración, además de reducir la probabilidad de cometer errores.

## Pods "desnudos" frente a Replication Controllers y Jobs

* Si hay una alternativa biable a _pods_ "desnudos" (es decir, _pods_ qu eno están asociados a un _replication controller_), usa simpre la alternativa. Los _pods_ "desnudos" no son re-planificados en caso de que el nodo falle.

Los _replication controllers_ son casi siempre preferibles a la creación de _pods_ "desnudos", excepto en algunos escenarios de `restartPolicy: Never`. En algunos casos, un _Job_ también puede ser apropiado.

## Servicios

* En general, típicamente es mejor crear un **servicio** antes que sus correspondientes **replication controllers**. Ésto permite distribuir los _pods_ que componen el servicio.
* No uses `hostPort` a no ser que sea absolutamente necesario (por ejemplo, en un nodo _deamon_). `hostPost` especifica el número de puerto del _host_ que hay que exponer. Cuando usas `hostPort` hay un número limitado de sitios donde puede planificarse un _pod_ debido a conflictos de puertos; sólo puedes planificar tantos _pods_ como nodos tenga el clúster. Si necesitas acceder a un puerto determinado por motivos de depuración, puedes usar `kubectl proxy` y el `proxy apiserver` o `kubectl port-forward`. Puedes usar el objeto `Service` para acceder a servicios externos. Si necesitas exponer el puerto de un _pod_ en una máquina _host_, condiera usar un servicio `NodePort` antes de usar un `hostPort`.
* Evita usar `hostNetwork` por las mismas razones que `hostPort`.
* Usa `headless services` para facilitar el _service discovery_ cuando no necesitas balanceo de carga de **kube-proxy**.

## Usando etiquetas

* Define y usa etiquetas que identifiquen **atributos semánticos** para tu aplicación o despliegue.  Por ejemplo, `{app: myapp, tier: frontend, phase: test, deplyment: v3}`. Esto te permite seleccionar los grupos de objetos apropiados para el contexto.

Un servicio puede contener varios _deployments_, como pasa con las _rolling updates_, simplemente omitiendo etiquetas específicas de _release_ del selector, en vez de actualizar el selector del servicio para que se ajuste completamente al del _replication controller_.

* Para facilitar las _rolling update_ incluye información de la versión en los nombres de los _replication controllers_, por ejemplo como sufijo del nombre. Es útil establecer una etiqueta de versión también. Las _rolling updates_ crear un nuevo _replication controller_ en vez de modificar el controlador existente. Así que habrá problemas con los nombres de controladores versión agnósticos.

Fíjate en que un objeto _deployment_ evita tener que gestionar los "nombres de versiones" de los _replication controllers_. El estado deseado de un objeto está descrito en un _Deployment_ y los cambios a las especificaciones son _aplicadas_, lo que significa que el _deployment controller_ realiza cambios desde el estado actual al estado deseado de forma controlada.

* Puedes manipular etiquetas para depurar. Como los _replication controllers_ y los _services_ en Kubernetes usan las etiquetas para seleccionar _pods_, esto te permite eliminar un _pod_ de un _controller_ o de obtener tráfico de un _service_ eliminando las etiquetas relevantes usadas en el selector.

## Imágenes de contenedores

TODO

## Usando `kubectl`

* Usa `kubectrl create -f <carpeta>` siempre que sea posible. Esto hace que `kubectl` busque todos los objetos `.yaml`, `yml` y `.json` en la `<carpeta>` y que los pase a `create`.
* Usa `kubectl delete` en vez de `stop`. `Delete` tiene un superconjunto de la funcionalidad de `stop` y `stop` está desaconsejado (_deprecated_).
* Usa `kubectl run` y `expose` para crear y exponer rápidamente _deployments_ de un solo contenedor.
