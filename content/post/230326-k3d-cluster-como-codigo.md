+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "kubernetes", "k3d", "registry"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/k3s.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/

# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}
# YouTube           {{< youtube w7Ft2ymGmfc >}}
# Gist              {{< gist username 7896402 >}}
# Highlight         {{< highligth language >}}...{{< /highlight >}}
# Twitter           {{< tweet user="SanDiegoZoo" id="1453110110599868418" >}}

title=  "k3d: desplegar un clúster de Kubernetes como código"
date = "2023-03-26T12:20:00+02:00"
+++
Ya he hablado de [k3d](https://k3d.io/) otras veces en el blog; del mismo modo que [kind](https://kind.sigs.k8s.io/) permite desplegar Kubernetes en Docker: cada *nodo* del clúster se ejecuta en un contenedor.

**k3d** hace lo mismo pero en vez de Kubernetes *vanilla*, usa la distribución ligera de Kubernetes, [k3s](https://k3s.io/).

Este fin de semana he actualizado la documentación del repositorio [onthedock/k8s-devops](https://github.com/onthedock/k8s-devops) en lo relativo a k3d y he aprovechado para explorar un par de cosas nuevas: deplegar el clúster de forma declarativa (como código) y el uso del *registry* interno en k3s.

En este artículo me centro en la primera parte: el despliegue del clúster como código.
<!--more-->

> En el momento de escribir este artículo, la versión actual de **k3d** es la v5.4.9.

Desde la versión 4.0.0 de k3d existe la posibilidad de especificar la [configuración](https://k3d.io/v5.4.9/usage/configfile/) del clúster como código.
Sin embargo, si estás acostumbrado a desplegar clústers de k3d desde la línea de comando, debes tener en cuenta que las opciones en el fichero de configuración no coinciden al 100% con los parámetros de la CLI.

El fichero de configuración sólo tiene dos campos obligatorios: `kind` y `apiVersion`:

- `apiVersion: k3d.io/v1alpha4` Esta versión va cambiando, por lo que debes estar atento a la documentación oficial.
- `kind: Simple`

El resto de opciones del fichero de configuración son **opcionales**.

Otro punto a tener en cuenta es que cualquier opción especificada en el fichero de configuración puede ser *sobrescrita* desde el parámetro equivalente de la CLI, que tiene preferencia. Esto permite tener usar un fichero de configuración como una *plantilla* y modificar algunos valores desde la CLI al desplegar (por ejemplo, el nombre del clúster).

## Número de servidores y agentes

Rancher denomina `server` a los nodos del *control plane* (anteriormente, *masters*), y `agent` a los nodos *worker*.

En el fichero de configuración, especificamos cuántos nodos de cada tipo integrarán nuestro clúster:

```yaml
apiVersion: k3d.io/v1alpha4 # this will change in the future as we make everything more stable
kind: Simple                # internally, we also have a Cluster config, which is not yet available externally
# metadata:
#   name: default           # name that you want to give to your cluster (will still be prefixed with `k3d-`)
servers: 1                  # same as `--servers 1`
agents:  2                  # same as `--agents 2`
```

Con esta configuración, k3d genera un clúster con un *control plane* de un solo nodo, y dos nodos adicionales como *workers*.

## Configuración del *endpoint* de la API del clúster

Mediante el siguiente bloque se puede configurar el *endpoint* de la API de Kubernetes del clúster:

```yaml
kubeAPI:                    # same as `--api-port myhost.my.domain:6445` (where the name would resolve to 127.0.0.1)
  host: "myhost.my.domain"  # important for the `server` setting in the kubeconfig
  hostIP: "127.0.0.1"       # where the Kubernetes API will be listening on
  hostPort: "6445"          # where the Kubernetes API listening port will be mapped to on your host system
```

Como el nombre especificado en `host` debe resolver a 127.0.0.1 no suelo tomarme la molestia de especificarlo, y accedo usando `localhost` directamente. Sin embargo, si usas **k3d** de forma local durante el desarrollo, puedes especificar el FQDN del clúster "real" y resolverlo a 127.0.0.1 en `/etc/hosts`, por ejemplo.

## Puerto para el balanceador

Otro bloque que no suelo usar para los clústers locales es el de configuración del balanceador del clúster, pero que es interesante tener en cuenta en algunos casos:

```yaml
ports:
  - port: 8080:80 # same as `--port '8080:80@loadbalancer'`
    nodeFilters:
      - loadbalancer
```

Para el resto de opciones, consulta la documentación oficial en [Using Config Files](https://k3d.io/v5.4.9/usage/configfile/).

## Despliegue de un *registry*

La configuración completa del *registry* se puede especificar mediante el bloque:

```yaml
registries: # define how registries should be created or used
  create: # creates a default registry to be used with the cluster; same as `--registry-create registry.localhost`
    name: registry.localhost
    host: "0.0.0.0"
    hostPort: "5000"
    proxy: # omit this to have a "normal" registry, set this to create a registry proxy (pull-through cache)
      remoteURL: https://registry-1.docker.io # mirror the DockerHub registry
      username: "" # unauthenticated
      password: "" # unauthenticated
    volumes:
      - /some/path:/var/lib/registry # persist registry data locally
  use:
    - k3d-myotherregistry:5000 # some other k3d-managed registry; same as `--registry-use 'k3d-myotherregistry:5000'`
  config: | # define contents of the `registries.yaml` file (or reference a file); same as `--registry-config /path/to/config.yaml`
    mirrors:
      "my.company.registry":
        endpoint:
          - http://my.company.registry:5000
```

Habitualmente, usaremos el *registry* de manera "normal", es decir, para almacenar imágenes en el clúster.
El *registry*  ofrece la posibilidad de usarse como *proxy* para *mirrorear* imágenes de un *registry* externo... De nuevo, es interesante en algunos escenarios pero no es el caso de uso más habitual.

## Configuración definitiva

Para un clúster de desarrollo *personal*, una configuración equilibrada es:

```yaml
apiVersion: k3d.io/v1alpha4 # this will change in the future as we make everything more stable
kind: Simple                # internally, we also have a Cluster config, which is not yet available externally
# metadata:
#   name: demo              # name that you want to give to your cluster (will still be prefixed with `k3d-`)
servers: 1                  # same as `--servers 1`
agents:  2                  # same as `--agents 2`
registries:                 # define how registries should be created or used
  create: # creates a default registry to be used with the cluster; same as `--registry-create registry.localhost`
    name: registry.localhost
    host: 0.0.0.0
    hostPort: "5000"
  config: |
    mirrors:
      "registry.localhost:5000":
         endpoint:
          -  "http://registry.localhost:5000"
```

## Manos a la obra

Creamos el fichero de configuración `k3d-cluster-1s-2a+registry.yaml`.

El fichero tiene el campo `name` comentado porque especificaremos un nombre para el clúster desde la CLI:

```bash
$ k3d cluster create  onthedock --config k3d-cluster-1s-2a+registry.yaml
INFO[0000] Using config file k3d-cluster-1s-2a+registry.yaml (k3d.io/v1alpha4#simple)
INFO[0000] Prep: Network
INFO[0000] Created network 'k3d-onthedock'
INFO[0000] Created image volume k3d-onthedock-images
INFO[0000] Creating node 'registry.localhost'
INFO[0000] Successfully created registry 'registry.localhost'
INFO[0000] Starting new tools node...
INFO[0000] Starting Node 'k3d-onthedock-tools'
INFO[0001] Creating node 'k3d-onthedock-server-0'
INFO[0001] Creating node 'k3d-onthedock-agent-0'
INFO[0001] Creating node 'k3d-onthedock-agent-1'
INFO[0001] Creating LoadBalancer 'k3d-onthedock-serverlb'
INFO[0001] Using the k3d-tools node to gather environment information
INFO[0002] HostIP: using network gateway 172.18.0.1 address
INFO[0002] Starting cluster 'onthedock'
INFO[0002] Starting servers...
INFO[0002] Starting Node 'k3d-onthedock-server-0'
INFO[0013] Starting agents...
INFO[0015] Starting Node 'k3d-onthedock-agent-0'
INFO[0015] Starting Node 'k3d-onthedock-agent-1'
INFO[0029] Starting helpers...
INFO[0029] Starting Node 'registry.localhost'
INFO[0031] Starting Node 'k3d-onthedock-serverlb'
INFO[0039] Injecting records for hostAliases (incl. host.k3d.internal) and for 5 network members into CoreDNS configmap...
INFO[0053] Cluster 'onthedock' created successfully!
INFO[0054] You can now use it like this:
kubectl cluster-info
```

Como no hemos configurado el *endpoint* de la API del clúster, es recomendable ejecutar `kubectl cluster-info` y averiguar en qué puerto se encuentra expuesta, aunque el fichero `.kube/config` se ha actualizado para incluir la información de autenticación en un nuevo contexto en el fichero existente.

```bash
$ kubectl cluster-info
Kubernetes master is running at https://0.0.0.0:39643
CoreDNS is running at https://0.0.0.0:39643/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
Metrics-server is running at https://0.0.0.0:39643/api/v1/namespaces/kube-system/services/https:metrics-server:https/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

Como k3d despliega los *nodos* del clúster de Kubernetes en contenedores, podemos ver los "nodos" del clúster mediante `docker ps`:

```bash
$ docker ps
CONTAINER ID   IMAGE                            COMMAND                  CREATED         STATUS         PORTS                             NAMES
7ff706a7eeaf   ghcr.io/k3d-io/k3d-proxy:5.4.9   "/bin/sh -c nginx-pr…"   6 minutes ago   Up 6 minutes   80/tcp, 0.0.0.0:39643->6443/tcp   k3d-onthedock-serverlb
9642acef4de4   rancher/k3s:v1.25.7-k3s1         "/bin/k3d-entrypoint…"   6 minutes ago   Up 6 minutes                                     k3d-onthedock-agent-1
fa352ab7c521   rancher/k3s:v1.25.7-k3s1         "/bin/k3d-entrypoint…"   6 minutes ago   Up 6 minutes                                     k3d-onthedock-agent-0
fac4d8517805   rancher/k3s:v1.25.7-k3s1         "/bin/k3d-entrypoint…"   6 minutes ago   Up 6 minutes                                     k3d-onthedock-server-0
e5725219073b   registry:2                       "/entrypoint.sh /etc…"   6 minutes ago   Up 6 minutes   0.0.0.0:5000->5000/tcp            registry.localhost
```

Vemos que tenemos los tres nodos del clúster, un nodo `k3d-onthedock-server-0` para el *control plane* y dos *workers* `k3d-onthedock-agent-0` y `k3d-onthedock-agent-1`.

Además, tenemos un balanceador frente a la API del clúster, `k3d-onthedock-serverlb` y un nodo adicional para el *registry* `registry.localhost`.

**k3d** permite gestionar los diferentes clúster desplegados de manera sencilla (aunque en este ejemplo sólo tengo 1):

```bash
$ k3d cluster list
NAME        SERVERS   AGENTS   LOADBALANCER
onthedock   1/1       2/2      true
```

Crear un clúster adicional es tan sencillo como:

```bash
$ k3d cluster create test -s 1 -a 1
INFO[0000] Prep: Network
INFO[0000] Created network 'k3d-test'
INFO[0000] Created image volume k3d-test-images
INFO[0000] Starting new tools node...
INFO[0000] Starting Node 'k3d-test-tools'
INFO[0001] Creating node 'k3d-test-server-0'
INFO[0001] Creating node 'k3d-test-agent-0'
INFO[0001] Creating LoadBalancer 'k3d-test-serverlb'
INFO[0001] Using the k3d-tools node to gather environment information
INFO[0002] HostIP: using network gateway 172.19.0.1 address
INFO[0002] Starting cluster 'test'
INFO[0002] Starting servers...
INFO[0002] Starting Node 'k3d-test-server-0'
INFO[0012] Starting agents...
INFO[0013] Starting Node 'k3d-test-agent-0'
INFO[0024] Starting helpers...
INFO[0024] Starting Node 'k3d-test-serverlb'
INFO[0032] Injecting records for hostAliases (incl. host.k3d.internal) and for 3 network members into CoreDNS configmap...
INFO[0035] Cluster 'test' created successfully!
INFO[0035] You can now use it like this:
kubectl cluster-info
```

Y ahora:

```bash
$ k3d cluster list
NAME        SERVERS   AGENTS   LOADBALANCER
onthedock   1/1       2/2      true
test        1/1       1/1      true
```

Añadimos un nodo `agent` adicional (en el clúster `test`):

```bash
$ k3d node create test-agent-1 -c test
INFO[0000] Adding 1 node(s) to the runtime local cluster 'test'...
INFO[0000] Using the k3d-tools node to gather environment information
INFO[0000] Starting new tools node...
INFO[0000] Starting Node 'k3d-test-tools'
INFO[0001] HostIP: using network gateway 172.19.0.1 address
INFO[0002] Starting Node 'k3d-test-agent-1-0'
INFO[0007] Successfully created 1 node(s)!
```

> De momento, no hay opción de *listar* los nodos de un solo clúster:

```bash
$ k3d node list | grep -i test
k3d-test-agent-0         agent          test        running
k3d-test-agent-1-0       agent          test        running
k3d-test-server-0        server         test        running
k3d-test-serverlb        loadbalancer   test        running
```

Tan fácil como es crear un clúster, podemos destruirlo:

```bash
$ k3d cluster delete test
INFO[0001] Deleting cluster 'test'
INFO[0004] Deleting cluster network 'k3d-test'
INFO[0004] Deleting 1 attached volumes...
INFO[0004] Removing cluster details from default kubeconfig...
INFO[0004] Removing standalone kubeconfig file (if there is one)...
INFO[0004] Successfully deleted cluster test!
```

## Conclusión

**k3d** mejora la velocidad a la que puedes desplegar un clúster para realizar pruebas; el proceso de descarga de la imagen de cada uno de los tipos de nodos es lo que consume mayor tiempo; pero una vez que tenemos copias locales de las imágenes, levantar un clúster de Kubernetes es cuestión de segundos.

A diferencia de otras plataformas -como MiniKube-, k3d (y k3s) fueron desarrollados para entornos productivos, en el *edge*. Gracias a su velocidad (debida en parte a componentes más ligeros), permite generar clústers (y destruirlos) de forma rápida para realizar todo tipo de pruebas durante el desarrollo.

Como hemos visto, k3d incluye un balanceador y, opcionalmente, un *registry*, por lo que simula a la perfección la arquitectura de entornos productivos *desde la comodidad de tu equipo de desarrollo* 😉.
