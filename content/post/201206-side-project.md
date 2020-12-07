+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev", "ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["blog", "devtoolbox"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/roadmap.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" %}}

title=  "Side Project: devtoolbox"
date = "2020-12-06T22:02:24+01:00"
+++
Ya hace casi dos meses de la última entrada en el blog; en esta entrada explico en qué he estado trabajando y qué me ha mantenido apartado de la publicación en el blog.
<!--more-->

Una serie de cambios en las tareas que suelo realizar en mi día a día en el trabajo ha hecho pivotar mi atención de la infraestructura *pura y dura* al despliegue de aplicaciones sobre Kubernetes.

Independientemente de los detalles de las diferentes *distribuciones* de Kubernetes -tanto de proveedores *cloud* como de otros fabricantes- las herramientas usadas son muchas veces las mismas. En este sentido, **IMHO**, que una determinada aplicación forme parte del *porfolio* de la CNCF ayuda a cristalizar la toma de decisiones respecto a qué herramienta adoptar a nivel empresarial.

Además de cierta *homogeneización* en cuanto a herramientas, creo que también las *prácticas* están evolucionando hacia lo que se ha denominado *GitOps*. Empezamos con *DevOps*, se incluyó la "automatización" de la seguridad con *DevSecOps* y ahora *GitOps* sería el resumen de esa "automatización global": cuando **todo** es código, el repositorio se convierte en el *hub* que permite la interacción segura de todos los participantes en el proyecto.

**devtoolbox** quiere ser una forma de proporcionar un conjunto de herramientas de referencia que permitan que un equipo pueda ponerse a trabajar con la menor fricción posible con los sistemas de provisión corporativos. El objetivo es que el equipo pueda ser productivo desde el "día 2"; de esta forma se pueden realizar los trámite burocráticos -solicitud de acceso, usuarios, etc- de forma paralela al desarrollo sin retrasarlo.

La idea del proyecto es automatizar el aprovisionamiento de las herramientas necesarias para un escenario "clásico" de desarrollo: un repositorio Git de código, herramientas de análisis estático de código, vulnerabilidades, compilación, testing, despliegue... También quiero incluir la documentación para mostrar que esta filosofía "devops" es aplicable más allá del desarrollo de aplicaciones.

Al tratarse de un proyecto personal me ciño a herramientas *open source* y a distribuciones Kubernetes *vanilla*. La idea es que en el proyecto puedan usar -o no usar- cualquiera de las herramientas proporcionadas en función de las preferencias del equipo. Intento evitar al máximo la dependencia entre las herramientas o usar servicios de un deteminado proveedor o fabricante.

Las herramientas se seleccionan para cubrir necesidades básicas; es probable que un equipo habituado a determinada herramienta disponga de su propio sistema de automatización para desplegar y configurarla de forma rápida.

**devtoolbox** es sobretodo una herramienta de aprendizaje personal.
