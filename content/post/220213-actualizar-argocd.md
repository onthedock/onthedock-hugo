+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["kubernetes", "automation", "devops", "argocd"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/argocd.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/

# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}
# YouTube           {{< youtube w7Ft2ymGmfc >}}
# Gist              {{< gist username 7896402 >}}
# Highlight         {{< highligth language >}}...{{< /highlight >}}
# Twitter           {{< tweet user="SanDiegoZoo" id="1453110110599868418" >}}

title=  "Actualizar ArgoCD - ¡ojo! se sobrescriben los ConfigMap de configuración"
date = "2022-02-13T09:04:04+01:00"
+++
A raíz de la entrada anterior [GitOps con ArgoCD - Instalación y acceso a la consola]({{< ref "220212-instalacion-y-acceso-a-la-consola.md">}}) he visto que la versión desplegada en el clúster de laboratorio era la 2.2.1, mientras que la versión actual es la 2.2.5.

Antes de actualizar, al tratarse de una versión *patch release*, no es necesario tener en cuenta ninguna consideración especial, según se indica en la documentación oficial [Upgrading > Overview](https://argo-cd.readthedocs.io/en/stable/operator-manual/upgrading/overview/).

Sin embargo, aplicando el fichero correspondiente a la última versión estable, **se sobreescriben los *ConfigMaps* de configuración**, por lo que las modificaciones realizadas se pierden; en mi caso, la configuración del modo *inseguro* necesario para el acceso a través de un *ingress*.

Como solución temporal, se puede aplicar de nuevo el fichero con el *ConfigMap* y ejecutar `kubectl -n argocd rollout restart deploy argocd-server`.
<!--more-->

Revisando los *issues* abiertos en GitHub, he encontrado un caso similar en [Do not overwrite custom changes on argocd-ssh-known-hosts-cm when upgrading #5054](https://github.com/argoproj/argo-cd/issues/5054). El *issue* está abierto en Diciembre 2020 y se considera una *mejora*.

Por tanto, hasta que se implemente esta *mejora*, como *workaround*:

1. Ejecuta la actualización de ArgoCD
1. Aplica el (o los) *ConfigMaps* que hayas *personalizado*
1. Ejecuta un *rollout restart deployment* para actualizar los cambios.
