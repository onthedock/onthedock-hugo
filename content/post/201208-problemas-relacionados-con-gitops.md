+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["links", "devops", "argocd"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/links.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" %}}

title=  "Interesante artículo \"More Problems with GitOps — and How to Fix Them\" en TheNewStack"
date = "2020-12-08T07:54:26+01:00"
+++
Hace unos días leía [More Problems with GitOps — and How to Fix Them](https://thenewstack.io/more-problems-with-gitops-and-how-to-fix-them/) sobre los problemas asociados a GitOps, así que aprovecho para inaugurar esta nueva sección de reflexiones sobre artículos que considero interesantes.
<!--more-->

En primer lugar, GitOps es la forma que se está estableciendo como el nuevo estándar de operar sistemas y aplicaciones. El concepto surgió de la empresa Weave y en [Guide To GitOps](https://www.weave.works/technologies/gitops/) describen los pilares en los que se basa:

1. El sistema completo se describe de forma declarativa
1. El estado deseado siempre se encuentra versionado en Git
1. Los cambios aprobados se pueden desplegar automáticamente en los sistemas
1. Agentes automatizados vigilan el sistema, se aseguran de que el estado deseado se aplica y alertan cuando hay divergencias.

En el primer artículo de la serie sobre "problemas con GitOps", Viktor Farcic comentaba como GitOps no sólo es aplicable a despliegue en Kubernetes, ya que se trata de una serie de principios que son aplicables a cualquier sistema cuya configuración pueda describirse de forma declarativa (que hoy en día son la mayoría).

En primer problema es que, en su opinión, GitOps no se entiende correctamente y que las propias herramientas que se promocionan como "GitOps" en realidad, no lo son (del todo).

La idea básica de GitOps es que el estado del sistema se encuentra definido en un repositorio Git. Un agente observa el repositorio y aplica los cambios que se añadan al mismo, de manera que se reconcilie el estado actual del clúster de Kubernetes (por ejemplo) y el estado definido en el repositorio Git.

Como ves, es una idea sencilla y muy potente; se elimina el acceso directo al clúster de forma que desaparecen los cambios "en caliente" sobre el clúster en marcha, todos los cambios quedan registrados en el repositorio y son trazables, etc.

Sin embargo, como apunta el autor en el primer artículo de la serie [The Problems with GitOps — And How to Fix Them](https://thenewstack.io/the-problems-with-gitops-and-how-to-fix-them/), las propias herramientas "gitops" no siguen los principios que promulgan.

Pone el ejemplo de ArgoCD, en cuya documentación se indica que el despliegue debe realizarse mediante `kubectl apply`, lo que contradice el principio de que los despliegues deben realizarlos los agentes... Pero si queremos hacerlo, entonces entramos en el círculo vicioso del huevo y la gallina: **necesitamos ArgoCD para desplegar ArgoCD** (lo mismo sería aplicable a Flux).

Parte del problema es que estas herramientas "gitops" sólo tienen capacidad de alterar el estado del sistema donde deben aplicar los cambios (por ejemplo, Kubernetes), pero no tienen forma de modificar el estado del repositorio Git.

Esto lleva a otro sinsentido: si se guarda un cambio en Git, ArgoCD/Flux/Argo Rollouts/Flagger aplican el cambio sobre el clúster... a no ser que algo falle; en este caso, las herramientas son capaces de hacer un *rollback* y devolver el sistema al estado anterior... Pero entonces, el estado del clúster y el deseado (en Git) son diferentes y **el causante de la divergencia es la propia herramienta "gitops"**.

Como ves, esta serie de artículos plantea cuestiones interesantes sobre las que reflexionar; el autor tiene pendiente una última entrega de esta serie así que ¡no te lo pierdas!
