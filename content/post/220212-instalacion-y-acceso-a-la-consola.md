+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev", "ops"]
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

title=  "GitOps con ArgoCD - Instalación y acceso a la consola"
date = "2022-02-12T15:39:46+01:00"
+++
GitOps es una forma de gestionar los clústers de Kubernetes y el proceso de *application delivery*, según consta en la definición que hacen los inventores del término, el equipo de Weave.works en [What is GitOps?](https://www.weave.works/technologies/gitops/).

El concepto *gitOps* proporciona un modelo operativo en el que *el estado deseado* del clúster (y de las aplicaciones desplegadas en él) se encuentra definido de forma **declarativa** en un repositorio Git.

Un agente se encarga de reconciliar el *estado deseado* (en Git) con el *estado real* (en Kubernetes), considerando -en general- como **fuente de la verdad** el contenido del repositorio.

Aunque Weave.works desarrolló inicialmente [Flux](https://fluxcd.io/) (ahora forma parte de la CNCF), en este *post* hablaré de [ArgoCD](https://argo-cd.readthedocs.io/en/stable/). Hay otras herramientas con las que implementar GitOps, pero sin duda Flux y ArgoCD son las referencias indiscutibles.
<!--more-->

## Cómo desplegar ArgoCD

El proyecto ArgoCD ofrece un fichero YAML que incluye todos los elementos necesarios para realizar el despliegue de la aplicación en [argo-cd/stable/manifests/install.yaml](https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml)

El fichero de instalación *espera* que la aplicación se despliegue en el *namespace* `argocd`; si quieres instalar ArgoCD en otro *Namespace*, debes modificar modificar el valor especificado en los *ClusterRoleBinding* del fichero `install.yaml`:

```yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  labels:
    app.kubernetes.io/component: application-controller
    app.kubernetes.io/name: argocd-application-controller
    app.kubernetes.io/part-of: argocd
  name: argocd-application-controller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: argocd-application-controller
subjects:
- kind: ServiceAccount
  name: argocd-application-controller
  namespace: argocd  # <--- argocd NAMESPACE
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  labels:
    app.kubernetes.io/component: server
    app.kubernetes.io/name: argocd-server
    app.kubernetes.io/part-of: argocd
  name: argocd-server
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: argocd-server
subjects:
- kind: ServiceAccount
  name: argocd-server
  namespace: argocd # <--- argocd NAMESPACE
```

## Acceso a la consola de ArgoCD

Una de las principales diferencias entre ArgoCD y Flux es que ArgoCD proporciona una consola gráfica desde donde gestionar las aplicaciones.

Para acceder a la consola de ArgoCD, usa el usuario `admin`; como contraseña, inicialmente se establece usando el nombre del pod generado por el *Deployment* `argocd-server`.

```bash
$ kubect get pods -n argocd -l app.kubernetes.io/name=argocd-server↵
NAME                             READY   STATUS    RESTARTS         AGE
argocd-server-7765664bc6-wfm9l   1/1     Running   16 (4h52m ago)   5h38m
```

Aunque ésto parece una buena idea (el nombre del pod generado por un *deployment* incluye una cadena aleatoria), si el pod se reinicia por algún motivo, el nombre del pod y el valor almacenado en el *Secret* **no coincidirán**, con lo que no podrás acceder a la consola de ArgoCD usando este método.

Tampoco podrás averiguar el valor en el *Secret* inspeccionando el valor almacenado en como `admin.password`:

```bash
$ kubectl get secret argocd-secret -n argocd -o jsonpath='{.data.admin\.password}' | base64 -d
$2a$10$WCI9VQi91sDbHFplnb11S.WLMSWOeC026TDMABhoTHUDkWYGWotjG
```

El *password* de acceso a ArgoCD se almacena después de usar [`bcrypt`](https://en.wikipedia.org/wiki/Bcrypt)[^bcrypt].

## Cambia la contraseña

No pierdas el tiempo y establece una contraseña de tu elección modificando el *Secret* `argocd-secret`. En las *preguntas frecuentes* de la documentación oficial se indica cómo hacerlo [I forgot the admin password, how do I reset it?](https://argo-cd.readthedocs.io/en/stable/faq/#i-forgot-the-admin-password-how-do-i-reset-it):

1. Usa *bcrypt* para generar el *hash* del password
1. *Parchea* el *secret* con el valor obtenido (no es necesario *codificarlo* previamente en base64):

```bash
# bcrypt(password)=$2a$10$rRyBsGSHK6.uc8fntPwVIuLVHgsAhAX7TcdrqW/RADU0uh7CaChLa
kubectl -n argocd patch secret argocd-secret \
  -p '{"stringData": {
    "admin.password": "$2a$10$rRyBsGSHK6.uc8fntPwVIuLVHgsAhAX7TcdrqW/RADU0uh7CaChLa",
    "admin.passwordMtime": "'$(date +%FT%T%Z)'"
  }}'
```

### `bcrypt` en sistemas basados en Debian

Debido al [bug 700758](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=700758), Debian incluye una versión de `bcrypt` que sólo permite descrifrar [^bcrypt2], pero no cifrar, usando este algoritmo.

Para generar la contraseña si no dispones de la utilidad `bcrypt` en tu sistema operativo, puedes usar un servicio online como: [Bcrypt-Generator.com](https://bcrypt-generator.com/), [Bcrypt Password Generator](https://www.browserling.com/tools/bcrypt) o [bcrypt.online](https://bcrypt.online/)

[^bcrypt]: `bcrypt` es tanto una función de *hash* (Wikipedia: [brypt](https://en.wikipedia.org/wiki/Bcrypt)) como una herramienta de encriptación basada en el cifrado [Blowfish](https://en.wikipedia.org/wiki/Blowfish_(cipher)).

[^bcrypt2]: El *bug* 700758 creo que hace referencia al método de cifrado. En la sección [Blowfish in practice](https://en.wikipedia.org/wiki/Blowfish_(cipher)#Blowfish_in_practice) se indica "*bcrypt is a password hashing function which, combined with a variable number of iterations (work "cost"), exploits the expensive key setup phase of Blowfish to increase the workload and duration of hash calculations, further reducing threats from brute force attacks.*"

## *Exponiendo* la consola de ArgoCD

Todos los servicios creados por ArgoCD son de tipo *ClusterIP*, por lo que sólo son accesibles desde *dentro* del clúster.

```bash
$ kubectl get svc -n argocd
NAME                    TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
argocd-dex-server       ClusterIP   10.43.120.14    <none>        5556/TCP,5557/TCP,5558/TCP   51d
argocd-metrics          ClusterIP   10.43.177.205   <none>        8082/TCP                     51d
argocd-redis            ClusterIP   10.43.189.137   <none>        6379/TCP                     51d
argocd-repo-server      ClusterIP   10.43.124.151   <none>        8081/TCP,8084/TCP            51d
argocd-server           ClusterIP   10.43.204.2     <none>        80/TCP,443/TCP               51d
argocd-server-metrics   ClusterIP   10.43.153.141   <none>        8083/TCP                     51d
```

En la documentación oficial se indican tres manera de acceder a la consola de ArgoCD [Access The Argo CD API Server](https://argo-cd.readthedocs.io/en/stable/getting_started/#3-access-the-argo-cd-api-server).

La primera, cambiar el tipo del servicio `argocd-server` a `LoadBalancer` (requiere un balanceador en el proveedor *cloud* o usar algo como [MetalLB](https://metallb.universe.tf/)).

La opción de usar [*port-forwarding*](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/) puede ser útil en algún escenario concreto, por ejemplo, si sólo un equipo reducido requiere acceso a la consola de ArgoCD de forma esporádica. Quizás en este caso una mejor opción sería usar la versión [ArgoCD *core*](https://argo-cd.readthedocs.io/en/stable/operator-manual/installation/#core), que no incluye la consola web por defecto (tampoco permite el acceso vía API ni alta dispoinibilidad), pero es mucho más ligero.

### Acceso a la consola de ArgoCD usando Traefik Ingress

En mi caso, expongo la aplicación usando un *Ingress*, [Traefik](https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/#traefik-v22).

Para ello, es necesario configurar el modo de acceso *inseguro* (sin TLS) al API Server; puedes configurar TLS en el *Ingress*, si lo necesitas.

En la documentación oficial se indica que debe lanzarse `argocd-server` con el *flag* `--insecure`; esto obliga a modificar el fichero de despliegue `install.yaml` (en particular, el *Deployment* de `argocd-server`):

```yaml
containers:
  - command:
    - argocd-server
    - --staticassets
    - /shared/app
    - --insecure
```

A partir de la versión 2.1.17 se puede usar un *ConfigMap* para definir las variables de entorno usadas por ArgoCD. Como se indica en [Declarative Setup](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/), podemos usar el *ConfigMap* [`argocd-cmd-params-cm`](https://argo-cd.readthedocs.io/en/stable/operator-manual/argocd-cmd-params-cm.yaml) para configurar el modo *inseguro* (entre muchos otros parámetros de ArgoCD):

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

Antes de *reiniciar* del *Deployment* para que los cambios surtan efecto, desplegamos la configuración del *Ingress*:

```yaml
---
apiVersion: networking.k8s.io/v1 # Kubernetes 1.19+
kind: Ingress
metadata:
  annotations:
    ingress.kubernetes.io/ssl-redirect: "false"
    kubernets.io/ingress.class: traefik
  name: argocd
  namespace: argocd
spec:
  rules:
  - host: "argocd.dev.lab"
    http:
      paths:
        - path: "/"
          pathType: Prefix
          backend:
            service:
              name: argocd-server
              port:
                number: 80
```

De esta forma podemos realizar el despliegue y configuración de ArgoCD de forma declarativa, mediante un solo comando `kubectl apply -f argocd/` (la carpeta `argocd/` contendría el fichero de despliegue `install.yaml`, la configuración del modo inseguro y el *ingress*).

Si has desplegado ArgoCD previamente, debes *reiniciar* el *deployment* con `kubectl rollout restart deployment argocd-server -n argocd`.

Ahora puedes acceder a la consola:

{{< figure src="/images/220212/argocd-console.png" width="100%" >}}

## Resumen

En esta entrada hemos visto cómo desplegar ArgoCD y acceder a la consola, usando como contraseña el nombre del pod generado por el *Deployment* de `argocd-server` o usando una contraseña establecida por nosotros (incluso en aquellos sistemas que no incluyen `bcrypt`).

Se han comentado los tres métodos de exponer la consola de ArgoCD y en particular, cómo hacerlo usando el *Ingress* Traefik. Para ello hemos configurado ArgoCD para trabajar en modo *inseguro* usando un *ConfigMap*, lo que permite realizar todo el proceso de forma *declarativa*.
