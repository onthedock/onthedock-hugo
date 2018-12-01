+++
draft = false

categories = ["dev"]
tags = []
thumbnail = "images/181124/roadmap.png"

title=  "Roadmap"
date = "2018-11-24T11:53:53+01:00"
+++

Kubernetes y el ecosistema que se ha desarrollado a su alrededor evoluciona a un ritmo increíble. Kubernetes lanza nuevas *releases* cada tres meses, con nuevas funcionalidades impulsadas por alguno de los SIGs trabajando en el desarrollo.

En cuanto a las herramientas *relacionadas*, hace unos días leía acerca de la entrada de [Harbor](https://www.cncf.io/blog/2018/11/13/harbor-into-incubator/) en la incubadora de la CNCF. El mes anterior lo hizo [Rook](https://www.cncf.io/blog/2018/09/25/toc-votes-to-move-rook/)...

Aunque es fascinante el ritmo de aceptación de Kubernetes y el ecosistema al que ha dado lugar, es muy difícil mantenerse al día de todo. Y prácticamente imposible conocer con detalle todas y cada una de las herramientas *interesantes* que, se desplieguen o no sobre Kubernetes, tienen que ver con conceptos afines, como [Ansible](https://www.ansible.com/), [Cloud-Init](https://cloudinit.readthedocs.io/en/latest/), [OpenStack](https://www.openstack.org/), [GlusterFS](https://docs.gluster.org/en/latest/), [Jenkins X](https://jenkins.io/projects/jenkins-x/), etc, etc.

<!--more-->

Dado que el tiempo que puedo dedicar a *trastear* con todos estos productos y tecnologías (y a escribir sobre ellos), he decidido agrupar las aplicaciones en *líneas de trabajo*. Mi objetivo es poder llevar un mejor seguimiento de las tareas que voy realizando, así como definir cuales son los siguientes pasos con los que debo continuar adelante.

Sólo puedo dedicar un tiempo -normalmente, durante los fines de semana- a "probar cosas", por lo que pueden pasar varias semanas entre un paso y el siguiente. Con la cantidad de productos implicados y teniendo en cuenta que puede pasar un tiempo considerable desde la última vez que *visité* un producto concreto, es necesario, por un lado, focalizar y definir un objetivo a conseguir y por otro lado, documentar mejor.

Definir un objetivo a conseguir implica una tarea de análisis sobre *cómo deben hacerse las cosas* bien porque sean buenas prácticas de la industria bien porque lo plantee como un ejercicio para resolver problemas en mi trabajo actual. Esto supone un *metatrabajo* y conlleva mucho más tiempo que el que se requiere para montar una solucion *siguiendo el tutorial de internet*. A esto hay que sumarle que, en general, se asume que para la parte de *plataforma* se dispone de un servicio cloud como [AWS](https://aws.amazon.com), [Google Cloud Platform](https://cloud.google.com) o simplemente [GitHub](https://github.com/). Si has montado Kubernetes *on premises*, esto plantea problemas adicionales, por ejemplo, para resolver el tema del *storage* para los *pods* sobre Kubernetes.

Debido a mi trayectoria, soy una persona más de *ops* que de *dev*, así que parte de mi tendencia es a centrarme en temas como *infraestructura como código* y la operación del sistema frente al desarrollo de aplicaciones, Sin embargo, por mi trabajo gestionando el servicio de mantenimiento de aplicaciones e implantando el proceso devops, el tema de CI/CD, Jenkins (X), etc centra gran parte de mis esfuerzos.

Existe una tercer factor a tener en cuenta: mi propio *proceso*, por llamarlo de alguna manera. Creo firmemente en el proverbio chino que dice que "la tinta más pobre vale más que la mejor memoria", por lo que documento todo lo que hago. No se trata únicamente de registrar cómo construir determinada aplicación sino también el **porqué** he decidido hacerlo de esa determinada manera. Del mismo modo que "yo soy yo y mis circunstancias", las aplicaciones son como son -o las considero como lo hago- por una serie de motivos que son relevantes en un contexto dado. Rara vez las soluciones tecnológicas sirven en cualquier entorno. Las decisiones que deben tomarse -en todos los niveles- para "adoptar" Kubernetes o DevOps son muy diferentes en el caso de un desarrollador independiente, una pequeña *startUp* o una gran empresa.

Para mantener la documentación *future proofed*, uso texto plano (con Markdown), de manera que aprovecho las cualidades de Git para gestionar el versionado. La publicación la realizo directamente sobre [BitBucket Pages](https://pages.bitbucket.io/), en formato HTML. Para transformar los ficheros de markdown a HTML uso [Hugo](https://gohugo.io/).

El proceso de escribir la documentación en texto plano, versionarla en Git, *compilarla* para producir la versión *funcional* en HTML y después publicarla en [BitBucket Pages](https://pages.bitbucket.io/) sigue los mismos pasos que el proceso de CI/CD para una aplicación, por lo que es una buen proyecto con el que practicar toda la *pipeline* de CI/CD.

## Tres grandes bloques

Un primer bloque dedicado a la plataforma: sistema operativo, hipervisor, automatización de la creación de máquinas virtuales y gestión de la configuración.

En segundo lugar, Docker, Kubernetes y ecosistema.

Finalmente, CI/CD y proceso *DevOps* aplicado a la documentación personal.

## Infraestructura

Por *motivos históricos*, en la máquina de laboratorio tenía instalado Windows 10, por lo que al respecto del hipervisor, elegí Hyper-V (que usé de forma intensiva en trabajos anteriores). Para automatizar la creación de máquinas virtuales he estado probando [Vagrant](https://www.vagrantup.com/), pero está fuertemente orientado a [Virtual Box](https://www.virtualbox.org/) y algo limitado con respecto a Hyper-V.

Para crear máquinas virtuales sobre Hyper-V he desarrollado un módulo en PowerShell; funciona bien y es mucho más sencillo que Vagrant, pero estoy teniendo problemas para integrarlo en un entorno que es prácticamente 100% linux. Recientemente he descubierto que es posible provisionar VMs sobre [Hyper-V con Ansible](https://www.ansible.com/integrations/infrastructure/windows), gracias a la posibilidad de lanzar scripts en PowerShell desde Ansible.

Otra vía que he estado probando es [LXC/LXD](https://linuxcontainers.org/), pero he tenido problemas con el _networking_ (tengo pendiente escribir sobre ello). También he probado [OpenStack](https://www.openstack.org/), pero necesito dedicarle más tiempo antes de tomar una decisión al respecto.

[Cloud-Init](http://cloudinit.readthedocs.io/) es la solución a los problemas para realizar la configuración del sistema en el primer arranque de la máquina; he conseguido [buenos resultados usando un CD]({{<ref "181009-cloud-init.md">}}) como origen de la configuración individual de la VM. Tengo pendiente dar el *next step* y poder servir estos ficheros desde un servidor web, lo que permitiría que el propio *script* de creación de las máquinas generara los fichero de configuración específicos.

Dado que Cloud-Init también permite instalar software, todavía tengo que decidir si es mejor hacerlo directamente desde Cloud-Init o usar Ansible para ello; esta segunda opción parece más robusta, pero requiere disponer de Ansible y añade complejidad al despliegue. Por supuesto, también requiere saber como funciona Ansible y desarrollar los *playboooks*, etc... En un entorno de laboratorio quizás sea más sencillo usar únicamente Cloud-Init, ya que las máquinas probablemente se destruyan tras las pruebas o la demo; en un entorno más estable, es recomendable tener Ansible ejecutándose periódicamente para asegurar que el sistema no se desvía del estado deseado, realizar actualizaciones, etc.

## Kubernetes and friends

Con Kubernetes el problema pendiente de resolver es el *storage*; en Docker es muy sencillo usar un *bind mount* para montar una carpeta del *host* local en el contenedor o crear un contenedor de datos. En Kubernetes, al tratarse de un clúster, la posibilidad de montar el almacenamiento local de un nodo en un *pod*, aunque posible, es una **muy mala opción**; si el *pod* se crea en otro nodo, tendremos *problemas* (el punto de montaje que el *pod* espera no existe en otro nodo o cada nodo tiene datos diferentes). En las plataformas *cloud* los volúmenes se montan a través de la red; en una instalación *on premises* tenemos que proporcionar una fuente de almacenaje remota. Los artículos que he consultado no dejan en buen lugar a NFS -aunque es la opción más sencilla-, así que estoy probando [GlusterFS](https://docs.gluster.org/en/latest/). Pero para que el almacenaje replicado en GlusterFS se pueda usar en Kubernetes, necesitamos una pieza adicional: [Heketi](https://github.com/heketi/heketi).

Aunque es posible usar GlusterFS en forma de *pods* corriendo en Kubernetes, para poder montar el almacenaje local estos *pods* deben ejecutarse con *privilegios*. Esta opción permite una solución *compacta*, con el clúster de Kubernetes y el de *storage* trabajando juntos. Sin embargo, con la entrada de Rook en la incubadora de la CNCF, probablemente este producto pase a ser el *almacenaje por defecto* de Kubernetes. La última vez que estuve revisando Rook todavía estaba muy verde, pero dado el interés en el producto, es posible que se haya avanzado mucho desde entonces. Rook además, trabaja con [Ceph](https://ceph.com/), que me parece más complejo que GlusterFS.

Al contrario de lo que pasa con el almacenaje, el apartado de monitorización de las aplicaciones desplegadas y el propio clúster gira alrededor de dos herramientas: [Prometheus](https://prometheus.io/) y [Graphana](https://grafana.com/).

Para el despliegue de aplicaciones el clúster, la [CNCF está incubando](https://www.cncf.io/blog/2018/06/01/cncf-to-host-helm/) [Helm](https://helm.sh/). Helm permite desplegar de forma conjunta todos los objetos asociados con la aplicación en el clúster.

Y todo esto sin tener en cuenta las funcionalidades *core* de Kubernetes, que se introducen a un buen ritmo...

## CI/CD y DevOps para la documentación

Había programado -a nivel *hobby*- con PHP y Python en el pasado... Sin embargo, nunca he pasado de un *Hello World!* en Java, generalmente, siguiendo un tutorial de internet. Sólo he utilizado herramientas como [Maven](https://maven.apache.org/) o [Ant](https://ant.apache.org/) cuando he estado revisando cómo funcionan estas herramientas. Estoy mejorando mis conocimientos de programación con [Go](https://golang.org/), pero como he dicho, era más una persona de *operaciones*.

En el proceso DevOps usamos herramientas como [Sonarqube](https://www.sonarqube.org/), [Nexus](https://www.sonatype.com/nexus-repository-oss), [Jenkins](https://jenkins.io/) y otras que no son OpenSource como [Jira](https://es.atlassian.com/software/jira), [HP ALM](https://software.microfocus.com/es-es/solutions/software-development-lifecycle), [HP UFT](https://software.microfocus.com/es-es/products/unified-functional-automated-testing/overview) o [LoadRunner](https://software.microfocus.com/es-es/products/loadrunner-load-testing/overview).

Mi objetivo inicial era reproducir el proceso usando -en la medida posible- aplicaciones OpenSource sobre contenedores, compilando y desplegando aplicaciones Java y .Net, por ejemplo.

Por ahora, estoy cambiando el alcance de esta parte y me voy a focalizar en algo más concreto y específico: usar algunas de esas mismas herramientas para "compilar" y publicar la documentación. Mi intención es centrarme en el flujo y algunos retos como la "promoción" de aplicación entre los entornos de *staging* y *producción*. En las demos, tras la ejecución de los tests se despliega directamente sobre un entorno final. Creo que es más realista pensar en un proceso CI/CD con *paradas* y un proceso de aprobación antes del pase a producción.

El despliegue directo sobre entornos de producción (en forma de contenedores) puede plantearse con aplicaciones *cloud native* en forma de pequeños microservicios. Para aplicaciones monolíticas en la que los test de aceptación se realizan de forma manual, por ejemplo, hay que usar herramientas que permitan definir flujos de aprobación antes de la promoción de los cambios al entorno productivo. En este sentido, hay que revisar herramientas como [Spinnaker](https://www.spinnaker.io/) o [Weave Flux](https://github.com/weaveworks/flux).

En el caso específico de estos artículos, el entorno *prelive* corre en una Raspberry Pi con Nginx sobre Docker, de manera que "testeo" los nuevos desarrollos -en cuanto al diseño del blog o la revisión de errores tipográficos- antes de pasarlos al entorno "productivo" en Bitbucket. De cara al futuro, me gustaría testear usando [Selenium](https://www.seleniumhq.org/) o alguna herramienta similar.

Localmente, uso [Gitea](https://gitea.io/) como sustituto de GitHub/Bitbucket. Siguiendo la vía [GitOps](https://www.weave.works/blog/gitops-operations-by-pull-request), la subida de un nuevo artículo debería lanzar un *job* en Jenkins que compile la documentación y la suba a la Raspberry Pi. Después de realizar los tests -de forma manual o usando alguna herramienta- la subida a Bitbucket se debe realizar de forma automática.

Para ser más realista, querría revisar las posibilidades que ofrece Spinnaker y ver si es posible transicionar poco a poco desde un sistema de aprobación manual a un sistema donde las aprobaciones se realicen vía aceptación de Pull Requests o de forma automática tras la ejecución exitosa de tests de integración.

Jenkins, una de las piezas claves en este proceso, está pasando por un proceso de transformación con tres proyectos -[Jenkins X](https://jenkins.io/projects/jenkins-x/), [Jenkins Configuration as Code](https://jenkins.io/projects/jcasc/) y  [Jenkins Evergreen](https://jenkins.io/projects/evergreen/) muy interesantes a los que seguir la pista.

Sin embargo, también quiero revisar otros sistemas más *ligeros* como [Drone](https://drone.io/) y aplicarlos a la creación de imágenes de contenedores. La automatización del proceso de creación de imágenes, su revisión en busca de vulnerabilidades y la subida a un registro privado lo dejo, de momento, en segundo plano.

## Conclusiones

Estamos en un momento interesante en el que Kubernetes ha ganado la batalla de los orquestadores de contenedores. La industria ha abrazado los contenedores como estándar de despliegue de aplicaciones. Las empresas tecnológicas desarrollan o convierten sus aplicaciones al modelo de microservicios para hacerlas *cloud native*. Y poco a poco el resto de empresas están empezando a implantar esta nueva forma de trabajar: microservicios, contenedores, etc.

Todavía quedan muchas aplicaciones *legacy* que llevará tiempo modernizar. También habrá que vencer cierta "fricción cultural" para implementar esta nueva forma de trabajar, rompiendo barreras entre desarrollo y operaciones.

Al margen del tipo de *cloud* que se use -pública, híbrida- definir infraestura como código permite extender los "avances" en las metodologías que han demostrado su efectividad en el mundo del desarrollo a la infrestructura. Pero también introducen nuevos retos -en cuanto a la formación del personal existente, los cambios en las estructuras organizativas, etc- que hay que tener en cuenta.

En mi caso, supone un reto conseguir emular una plataforma *cloud* con los recursos de los que dispongo.

En esta línea de trabajo, la provisión de las máquinas virtuales sigo realizándola de manera manual. La configuración de las máquinas la realizaré con una combinación de Cloud-Init y Ansible. Además de la provisión en sí, en este grupo de tareas se encuentran aquellos servicios auxiliares, como DNS, LDAP, etc.

Con las máquinas provisionadas, siempre que sea posible, las aplicaciones las desplegaré como contenedores. Inicialmente, sobre Docker (o Docker-Compose) hasta tener solucionado el almacenamiento en Kubernetes. A partir de ese momento, el foco debe ser usar Kubernetes como plataforma de gestión de las aplicaciones.

Kubernetes y las herramientas que forman parte del ecosistema relacionado serán el foco de mis esfuerzos a partir de ese momento.

En paralelo quiero poner en marcha una cadena de CI/CD asociada a la publicación de la documentación. También quiero integrar otros tipos de documentos que hasta ahora están al margen de los artículos que publico en el blog: no sólo los "documentos técnicos" como Dockerfiles, manifiestos de Kubernetes, playbooks de Ansible sino también algo en la línea de un wiki donde ir recogiendo diferentes "recetas" o píldoras de información como utilicé hace tiempo -con éxito- durante la ejecución de proyectos.

Espero que agrupar todas las tareas que tengo en *backlog* en estas tres líneas de trabajo, infraestructura, Kubernetes y CI/CD/documentación me permita distribuir mejor el tiempo que puedo dedicar a aprender sobre todos estos temas.