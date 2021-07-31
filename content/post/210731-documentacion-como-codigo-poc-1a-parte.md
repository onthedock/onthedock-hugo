+++
draft = false
categories = ["dev"]
tags = ["linux", "kubernetes", "k3s", "mkdocs"]
thumbnail = "images/mkdocs-material-logo.svg"
title=  "Documentación como código - 1a parte"
date = "2021-07-31T07:33:11+02:00"
+++

Una de las claves del éxito de un proyecto es proporcionar una buena documentación. En los proyectos *open source* cada vez se da más importancia a tener documentación de calidad y completamente actualizada.

En el pasado -aunque tristemente, sigue siendo una práctica muy habitual- la documentación se dejaba como una tarea a realizar una vez el proyecto estuviera prácticamente completado, antes de la entrega al cliente. El problema de esta aproximación es que los proyectos suelen encontrar problemas que hace que las fechas previstas inicialmente no se cumplan, o que se cumplan *artificialmente* entregando sin haber completado tareas como por ejemplo, la documentación.

Con la introducción de las metodologías ágiles, en cada tarea que se crea en el backlog se incluye la documentación como parte del criterio de aceptación, explícita o implícitamente.

En vez de generar un documento enorme, se suele optar por formatos ligeros como [markdown](https://daringfireball.net/projects/markdown/), como paso previo a generar una versión web para el usuario final. Gracias a herramientas como [pandoc](https://pandoc.org/), también es fácil generar documentación final en prácticamente cualquier otro formato que se requiera, como los habituales Microsoft Word o PDF.

De esta forma, el equipo de desarrollo trabaja en paralelo en la creación de nuevas funcionalidades a la vez que las documenta.
<!--more-->

Independientemente de si se trabaja en el desarrollo de una aplicación o en una tesis doctoral, podemos aplicar las mismas técnicas ágiles para generar documentación y automatizar las tareas repetitivas.

El proceso para generar documentación -como este blog- es el mismo que para desarrollar una aplicación:

{{< figure src="/images/210731/process.svg" width="100%" >}}

El concepto de *documentation as code* (documentación como código) consiste precisamente en aplicar el mismo tratamiento a la documentación que al código de una aplicación.

## Herramientas

El *código fuente*, cuando hablamos de *documentación como código* son los ficheros en formato *markdown* se guardan en un repositorio Git.

Para realizar el *testing*, podemos usar herramientas como un corrector ortográfico o un [*linter*](https://www.google.com/search?q=markdown+linter) (para detectar errores de sintaxis). Esto es menos frecuente para  la documentación que para el desarrollo de aplicaciones.

La conversión de formato *markdown* a HTML (PDF, epub, etc) se realiza mediante un *procesador*; para el blog, uso [Hugo](http://gohugo.io/), mientras que para la documentación *técnica* uso [MkDocs](https://www.mkdocs.org/). En mi caso, es un tema histórico; la documentación de [Kubernetes](https://kubernetes.io/es/docs/home/) (absolutamente técnica, se publica usando Hugo).

Para la publicación, dado que el formato final suele ser HTML y CSS, se puede usar prácticamente cualquier cosa: un servidor web ;) , [GitHub Pages](https://pages.github.com/), [S3](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html), etc...

## Automatización

Al ser un proceso iterativo, podemos automatizarlo: cuando se sube (*push*) un cambio en el *código fuente* de la documentación al repositorio, generamos una nueva versión de la documentación publicada. Usando un *webhook* podemos *disparar* una *pipeline* que lance el proceso completo.

Un escenario completamente gestionado (sin necesidad de montar nada en tu equipo) sería usar [GitHub](https://github.com/) como repositorio de código, [GitHub Actions](https://github.com/features/actions) como *pipeline* y GitHub Pages para publicar la documentación web resultante.

Como soy un gran fan de Kubernetes, mi idea es desplegar todas las herramientas en un clúster.

Las herramientas usadas son:

- [Gitea](https://gitea.io/en-us/), como repositorio de código
  - Desplegar Gitea con [Helm](https://helm.sh/), usando la [*chart* oficial](https://docs.gitea.io/en-us/install-on-kubernetes/)
  - Uso de una base de datos externa (desplegada desde la *chart* de Gitea)
- MkDocs como *procesador* de *markdown*
  - [MkDocs-Material](https://squidfunk.github.io/mkdocs-material/) como *tema* para MkDocs
- [Tekton Pipelines](https://tekton.dev/) como orquestador del proceso
  - Tekton Triggers para disparar la *pipeline* en respuesta al evento de *push* en el repositorio
- [Nginx](https://www.nginx.com/) para publicar la documentación
  - [Traefik Ingress](https://doc.traefik.io/traefik/providers/kubernetes-ingress/) para exponer la web al exterior
- [k3s](https://k3s.io/) como distribución de Kubernetes

## Decisiones iniciales

### No usar Tekton (en la prueba de concepto)

Para una primera prueba de concepto decidí *dejar fuera* Tekton. La idea era simular la automatización proporcionada por Tekton con un *Job* (o un *CronJob*) de Kubernetes.

El *Job* lanzaría un *script* que realizaría el *git clone* del repositorio en Gitea, se ejecutaría `mkdocs build` y se publicaría la versión actualizada.

### Gitea desplegado con Helm

El despliegue de Gitea con Helm no tiene ninguna complicación. La *Helm Chart* despliega tanto Gitea como una base de datos externa, pudiendo elegir entre MySQL,  usando Traefik Ingress para el acceso web. Para poder usar SSH con Git habría que montar elementos adicionales, así que para la prueba de concepto lo dejé en acceso HTTP.

En entradas anteriores ya hice una [revisión de la Helm chart oficial de Gitea]({{< ref "210529-revision-de-la-chart-de-gitea.md" >}}) y realicé una [Instalación de Gitea con Helm]({{< ref "210530-instalacion-de-gitea-con-helm.md" >}}).

### Publicación de la documentación

Los ficheros HTML generados por MkDocs se publican usando Nginx. Estuve valorando diversas opciones.

La primera era incluir los documentos generados en la imagen del contenedor. Cada nueva *release* de la documentación estaría asociada a una versión de la imagen. Sin embargo, esta opción resulta costosa en cuanto a recursos, al tener que generar una nueva versión para cada cambio de la documentación.

Además, aumenta la complejidad de la PoC (*proof of concept*), ya que es necesario construir una imagen en el clúster (usando [Kaniko](https://github.com/GoogleContainerTools/kaniko) o [Buildah](https://buildah.io/)), almacenándola en un [Registry](https://docs.docker.com/registry/) y finalmente haciendo un *rollout* del despliegue de la documentación con la nueva versión de la imagen de la documentación.

Otra opción que estuve valorando era la tener un contenedor *sidecar* junto al contenedor con Nginx. Este contenedor descargaría periódicamente la versión web de la documentación de un repositorio Git.

Tirando del hilo de la idea de usar el volumen *local* compartido por los contenedores de un mismo *pod* del escenario del servidor web con *sidecar*, acabé dando forma a una solución de tipo *quick and dirty*. La idea era usar el mismo volumen en varios *pods*. Esta solución tiene limitaciones, pero para una prueba de concepto funcionaría. El *pod* con Nginx monta el volumen con la documentación web en modo *ReadOnly*. De esta forma, el *pod* de MkDocs o un *pod* de "copia de datos", monta el mismo volumen en modo escritura para actualizar los ficheros web de la documentación.

Lo he probado en un clúster de un solo nodo de *k3s* y una sola réplica del *pod* con Nginx y funciona (tanto con un *Job* como con Tekton), pero queda pendiente validar si funcionaría usando múltiples *pods* distribuidos en varios nodos. En *k3s* la *StorageClass* por defecto es [`local-path`](https://github.com/rancher/local-path-provisioner), un *provisionador dinámico* de volúmentes de tipo `hostPath`, por lo que un escenario multi-nodo no tengo claro si esta solución sigue siendo válida.

### MkDocs (con MkDocs-Material)

Revisando la documentación de MkDocs fue sencillo averiguar los parámetros necesarios para especificar la ruta de entrada (para los ficheros en formato markdown) y la de salida (para el *site* generado en HTML).

Además, la imagen de MkDocs-Material incluye Git, lo que no fue necesario construir una imagen *custom* en la que añadir Git para hacer el `git clone`.

## Siguientes pasos

En las siguientes entregas de esta serie iré explicando los pasos conseguidos en este *side project* de montar una solución funcional de **documentación como código**.
