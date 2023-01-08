+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "automation", "kubernetes", "k3s", "bash", "vagrant"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/k3s.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/

# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}

title=  "Clúster de K3s: actualización del script de despliegue"
date = "2023-01-08T13:35:14+01:00"
+++
Después de un tiempo focalizado casi exclusivamente en aprender Go, hoy he vuelto a *mis raíces*: Kubernetes.

En el repositorio [onthedock/vagrant](https://github.com/onthedock/vagrant) tengo los *scripts* que me permiten desplegar varias máquinas virtuales usando Vagrant, instalar K3s y configurar un clúster de Kubernetes con (en este momento) un nodo *master* y dos *workers*. Como parte de la automatización, también despliego Longhorn como *storageClass* .

Hoy he testeado con éxito el despliegue de ArgoCD y Gitea en el clúster, dando un pasito adelante para desplegar una plataforma completa de desarrollo sobre Kubernetes.
<!--more-->

## Despliegue de ArgoCD

El despliegue de ArgoCD (1.23.3) lo realizo usando Helm.

En el pasado, desplegar ArgoCD requería realizar algunas configuraciones de forma manual. Desde hace unas versiones, sin embargo, es posible usar una configuración completamente *declarativa* para desplegar y configurar la aplicación.

Una de las modificaciones que ahora pueden realizarse a través de un *ConfigMap* es el llamado *modo inseguro*, es decir, sin configurar certificados para TLS:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  labels:
    app.kubernetes.io/name: argocd-cmd-params-cm
    app.kubernetes.io/part-of: argocd
  name: argocd-cmd-params-cm
  namespace: argocd
data:
  ## Server properties
  # Run server without TLS
  server.insecure: "true"
```

Otra de las configuraciones que realizo sobre ArgoCD es configurar un *Ingress* para poder acceder a la consola a través del nombre DNS (configurado localmente) `argocd.dev.lab` (a través del puerto 80).

Finalmente, establezco una contraseña *predefinida* para poder acceder a la consola; el sistema de establecer como contraseña del administrador el nombre de uno de los *pods* no es práctico en cuanto el *pod* se recrea por cualquier motivo...

El *password* de ArgoCD se genera usando Bcrypt, como se indica en las [FAQ: I forgot the admin password, how do I reset it?](https://argo-cd.readthedocs.io/en/release-2.3/faq/#i-forgot-the-admin-password-how-do-i-reset-it)). El problema es que en los sistemas operativos basados en Debian, sólo se puede usar el algoritmo para *desencriptar* debido a este [*bug*](http://bugs.debian.org/700758).

Por este motivo, inyecto en el *secret* el valor de una contraseña predefinida, en vez de generar una de forma aleatoria durante el despliegue.

Ésto es sólo una situación temporal, ya que en el futuro, probablemente usaré ArgoCD Core, sin interfaz gráfica.

## Gitea

Dado que usar un sistema de gestión de control de versiones es una de las bases de GitOps, disponer de un servidor de Git era uno de los componentes que quería incluir en esta plataforma de desarrollo sobre Kubernetes.

Con la última actualización del *script*, ahora Gitea se depliega en el clúster (de nuevo, usando Helm).

Al margen del *despliegue*, Gitea requiere realizar una configuración inicial. Por ejemplo, el primer usuario que se registra en la aplicación se convierte en administrador...

El *script* se encarga de generar un usuario administrador `gitea_admin` para el que se genera una contraseña aleatoria (que se almacena en un *secret* de Kubernetes).

Adicionalmente, se genera un usuario no-administrador (por defecto, llamado `xavi` 😉), para el que es necesario cambiar la contraseña en el primer acceso.

## Siguientes pasos

Con Gitea y ArgoCD tenemos dos piezas fundamentales en la metodología DevOps disponibles en el clúster: en Gitea almacenamos las aplicaciones que ArgoCD despliega automáticamente sobre el clúster.

Los siguientes pasos estarán orientados en incluir en la plataforma la parte de *CI*, de manera que el equipo de desarrollo pueda usar la plataforma para almacenar el código fuente de las aplicaciones (también en Gitea), compilarlas, *containerizarlas* y guardar las imágenes resultantes en un *Registry* privado desde el que poder desplegar de forma completamente *autónoma*, sin depender de servicios externos.

Mi intención es basar la *pipeline* en Tekton... Había pensado en incluir SonarQube como herramienta de análisis de código y quizás Nexus como repositorio de artefactos... Desde que se incluyó la posibilidad de actuar como *registry*, quizás me planteo usarlo (en vez de Docker Registry).

Todavía quedará, quizás, incluir herramientas de análisis de configuración de los propios manifest de *Kubernetes*, un sistema de autenticación, gestión de certificados, etc...

Herramientas útiles e interesantes hay un montón, así que lo único que necesito en este 2023 es disponer de suficiente tiempo 😉
