+++
draft = false

# TAGS
# HW->OS->PRODUCT->specific tag
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "kubernetes", "play-with-kubernetes"]

# CATEGORIES = "dev" / "ops"
categories = ["dev", "ops"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/kubernetes.png"

# SHORTCODES (for reference)

# YouTube
# {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Imagenes
# {{< figure src="/images/image.jpg" w="600" h="400" >}}
# {{< figure src="/images/image.jpg" w="600" h="400" class="right" >}}
# {{< figure src="/images/image.jpg" w="600" h="400" class="left" >}}
# {{< figure src="/images/image.jpg" w="600" h="400" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# Clear (floats)
# {{% clear %}}
# Twitter
# {{% twitter tweetid="780599416621297xxx" >}}

title=  "Play With Kubernetes"
date = "2017-08-18T20:25:31+02:00"
+++

Hace unas semanas descubrí el sitio [PWK](http://play-with-k8s.com), **Play with Kubernetes**. Su creador, [Marcos Nils](https://medium.com/@marcosnils) explica en [Introducing PWK (Play with K8s)](https://medium.com/@marcosnils/introducing-pwk-play-with-k8s-159fcfeb787b) que tenía ganas de extender la plataforma PWD (Play with Docker) a Kubernetes.

El sitio PWK permite montar clústers de Kubernetes y lanzar servicios replicados de manera rápida y sencilla. Se trata de un entorno donde realizar pruebas y _jugar_ durante cuatro horas con varias instancias de Docker sobre las que podemos usar `kubeadm` para instalar y configurar Kubernetes, creando un clúster en menos de un minuto.

<!--more-->

En el siguiente gif animado puedes ver lo sencillo que es crear un clúster de Kubernetes directamente desde el navegador:

<small>Puedes visualizar el gif en una nueva pestaña, a pantalla completa, pulsando en : <a href="/images/170818/play-with-k8s.gif" target="_blank">Play with K8s</a></small>

{{< figure src="/images/170818/play-with-k8s.gif" >}}

Para crear el clúster de Kubernetes, sigue los pasos indicados en la pantalla:

1. Instalar Kubernetes usando `kubeadm`
1. Instalar la capa de red en el clúster
1. (Opcionalmente) Instalar Kubernetes Dashboard.

Para añadir nodos, pulsa el botón "+ADD NEW INSTANCE" en el panel lateral izquierdo y ejecuta `kubectl join` para añadir nodos adicionales al clúster.

En la última versión de PWD, el equipo de PWK anunciaba a través de [Easiest Single Node Kubernetes Cluster](https://medium.com/@marcosnils/easiest-single-node-kubernetes-cluster-f1deaf229bd5) la opción de subir ficheros arrastrando y soltando sobre la ventana del navegador, lo que simplifica todavía más la creación de los diferentes objetos en el clúster:

<small>Puedes visualizar el gif en una nueva pestaña, a pantalla completa, pulsando en : <a href="/images/170818/pwk-uploads.gif" target="_blank">Subida de ficheros a PWK</a></small>

{{< figure src="/images/170818/pwk-uploads.gif" >}}

# Resumen

PWK proporciona un entorno completo donde probar Kubernetes sin las complicaciones de tener que gestionar la infraestructura que da soporte al clúster. Accediendo simplemente desde el navegador es posible inicializar tantos nodos como queramos y realizar tantas pruebas como sean necesarias.

Gracias a PWK disponemos de un entorno siempre listo para utilizar en demos, para hacer tutoriales, pruebas...