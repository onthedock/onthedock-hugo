+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["kubernetes", "k3s", "k3d", "docker"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/k3s.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}

title=  "k3d: k3s en Docker (o la manera más rápida de montar clústers de Kubernetes para desarrollo)"
date = "2021-03-21T18:21:07+01:00"
+++
[kind](https://kind.sigs.k8s.io/) es una herramienta para ejecutar clústers de Kubernetes en los que cada "nodo" del clúster se ejecuta en un contenedor. [k3d](https://k3d.io/) toma esta misma idea pero en vez de un clúster de Kubernetes *vanilla*, despliega un clúster de **[k3s](https://k3s.io/)** usando contenedores como "nodos".
<!--more-->

**k3s** es una distribución certificada de Kubernetes, pero mucho más *ligera*. *k3s* usa SQLite3 como base de datos interna, en vez de *etcd*, por ejemplo y ejecuta los diferentes controladores como un sólo fichero ejecutable. Todas estas modificaciones permiten **mantener toda la funcionalidad de Kubernetes**, pero con un binario de menos de 40MB (según indica la documentación oficial [k3s.io](https://k3s.io/)).

Siguiendo la idea de **kind**, se puede desplegar un clúster de *k3s* usando Docker como plataforma: cada nodo del clúster se despliega como un contenedor.

## Instalación

La instalación de *k3d* requiere disponer de Docker instalado; para desplegar un clúster, se proporciona la herramienta `k3d`, con la que podemos especificar el número de nodos servidores y agentes del clúster, así como muchas otras opciones.

La documentación oficial indica cómo instalar **k3d** usando varios métodos, como por ejemplo usando un *script* de instalación:

> Antes de ejecutar cualquier cosa desde internet, revisa si el *script* hace únicamente lo que se supone que debe hacer.

El cuerpo del *script* revisa el entorno local, descarga *k3d* y lo instala:

```bash
...
initArch
initOS
verifySupported
checkTagProvided || checkLatestVersion
if ! checkK3dInstalledVersion; then
  downloadFile
  installFile
fi
testVersion
cleanup
```

El detalle de la instalación:

```bash
...
# installFile verifies the SHA256 for the file, then unpacks and
# installs it.
installFile() {
  echo "Preparing to install $APP_NAME into ${K3D_INSTALL_DIR}"
  runAsRoot chmod +x "$K3D_TMP_FILE"
  runAsRoot cp "$K3D_TMP_FILE" "$K3D_INSTALL_DIR/$APP_NAME"
  echo "$APP_NAME installed into $K3D_INSTALL_DIR/$APP_NAME"
}
...
```

Una vez revisado el *script*, lanzamos la instalación:

```bash
curl -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash
```

Al finalizar, valida que *k3d* se ha instalado correctamente:

```bash
$ k3d version
k3d version v4.2.0
k3s version v1.20.2-k3s1 (default)
```

## Crear un clúster (manualmente)

Como ejemplo, vamos a crear un clúster llamado `dev-cluster` con un nodo servidor (`-s 1`) y un nodo agente (`-a 1`):

```bash
$ k3d cluster create dev-cluster -s 1 -a 1
INFO[0000] Prep: Network                                
INFO[0000] Created network 'k3d-dev-cluster'            
INFO[0000] Created volume 'k3d-dev-cluster-images'      
INFO[0001] Creating node 'k3d-dev-cluster-server-0'     
INFO[0001] Creating node 'k3d-dev-cluster-agent-0'      
INFO[0001] Creating LoadBalancer 'k3d-dev-cluster-serverlb' 
INFO[0001] Starting cluster 'dev-cluster'               
INFO[0001] Starting servers...                          
INFO[0001] Starting Node 'k3d-dev-cluster-server-0'     
INFO[0010] Starting agents...                           
INFO[0010] Starting Node 'k3d-dev-cluster-agent-0'      
INFO[0023] Starting helpers...                          
INFO[0023] Starting Node 'k3d-dev-cluster-serverlb'     
INFO[0024] (Optional) Trying to get IP of the docker host and inject it into the cluster as 'host.k3d.internal' for easy access 
INFO[0030] Successfully added host record to /etc/hosts in 3/3 nodes and to the CoreDNS ConfigMap 
INFO[0030] Cluster 'dev-cluster' created successfully!  
INFO[0030] --kubeconfig-update-default=false --> sets --kubeconfig-switch-context=false 
INFO[0030] You can now use it like this:                
kubectl config use-context k3d-dev-cluster
kubectl cluster-info
```

*k3d* se ejecuta como contenedores, por lo que podemos ver las imágenes usadas para construir los "nodos" mediante:

```bash
$ docker images
REPOSITORY          TAG            IMAGE ID       CREATED        SIZE
rancher/k3d-proxy   v4.2.0         70ec1f255a8a   5 weeks ago    44.4MB
rancher/k3s         v1.20.2-k3s1   1b02adf07426   2 months ago   154MB
```

Del mismo modo, revisamos los "nodos" del clúster:

```bash
$ docker ps
CONTAINER ID   IMAGE                      COMMAND                  CREATED       STATUS     PORTS                             NAMES
311f7f0cf5dc   rancher/k3d-proxy:v4.2.0   "/bin/sh -c nginx-pr…"   20 hours ago  Up 2 hours 80/tcp, 0.0.0.0:32945->6443/tcp   k3d-dev-cluster-serverlb
81521d5ea62f   rancher/k3s:v1.20.2-k3s1   "/bin/k3s agent"         20 hours ago  Up 2 hours                                   k3d-dev-cluster-agent-0
d995147a0d08   rancher/k3s:v1.20.2-k3s1   "/bin/k3s server --t…"   20 hours ago  Up 2 hours                                   k3d-dev-cluster-server-0
```

Vemos que además de los nodos servidor y agente, *k3d* también ha desplegado un balanceador que expone la API de Kubernetes en un puerto aleatorio (en este caso, 32945). Si queremos especificar un puerto determinado, podemos usar la opción `--api-port` al crear el clúster.

## Crear un clúster (a partir de un fichero de configuración)

Desde la versión v4.0.0 *k3d* permite especificar en un fichero de configuración cualquiera de las opciones que se pueden especificar desde línea de comando. Esto facilita todavía más integrar *k3d* en un *workflow* de integración contínua, por ejemplo, creando un clúster donde desplegar la nueva versión de la aplicación, realizar pruebas y destruirlo al finalizar.

La documentación oficial (en [Config File](https://k3d.io/usage/configfile/)) proporciona un fichero de configuración de ejemplo como referencia; sin embargo, para crear un clúster como el que hemos creado manualmente en la sección anterior, el fichero es sencillamente:

> El fichero de configuración, en este caso, lo llamo `config-1s1a.yaml`.

```yaml
apiVersion: k3d.io/v1alpha2 # this will change in the future as we make everything more stable
kind: Simple # internally, we also have a Cluster config, which is not yet available externally
# name: mycluster # name that you want to give to your cluster (will still be prefixed with `k3d-`)
servers: 1 # same as `--servers 1`
agents:  1 # same as `--agents 1`
options:
  kubeconfig:
    updateDefaultKubeconfig: true # add new cluster to your default Kubeconfig; same as `--kubeconfig-update-default` (default: true)
    switchCurrentContext: true # also set current-context to the new cluster's context; same as `--kubeconfig-switch-context` (default: true)
```

Aunque el fichero de configuración permite especificar el nombre del clúster, podemos especificarlo desde la línea de comando al ejecutar el comando `k3d cluster create`:

```bash
$ k3d cluster create stable-cluster --config config-1s1a.yaml
INFO[0000] Using config file config-1a1s.yaml           
INFO[0000] Prep: Network                                
INFO[0000] Created network 'k3d-stable-cluster'         
INFO[0000] Created volume 'k3d-stable-cluster-images'   
INFO[0001] Creating node 'k3d-stable-cluster-server-0'  
INFO[0001] Creating node 'k3d-stable-cluster-agent-0'   
INFO[0001] Creating LoadBalancer 'k3d-stable-cluster-serverlb' 
INFO[0001] Starting cluster 'stable-cluster'            
INFO[0001] Starting servers...                          
INFO[0001] Starting Node 'k3d-stable-cluster-server-0'  
INFO[0010] Starting agents...                           
INFO[0010] Starting Node 'k3d-stable-cluster-agent-0'   
INFO[0020] Starting helpers...                          
INFO[0020] Starting Node 'k3d-stable-cluster-serverlb'  
INFO[0021] (Optional) Trying to get IP of the docker host and inject it into the cluster as 'host.k3d.internal' for easy access 
INFO[0027] Successfully added host record to /etc/hosts in 3/3 nodes and to the CoreDNS ConfigMap 
INFO[0027] Cluster 'stable-cluster' created successfully! 
INFO[0027] --kubeconfig-update-default=false --> sets --kubeconfig-switch-context=false 
INFO[0027] You can now use it like this:                
kubectl config use-context k3d-stable-cluster
kubectl cluster-info
```

Validamos que el clúster se ha creado:

```bash
$ k3d cluster list
NAME             SERVERS   AGENTS   LOADBALANCER
dev-cluster      1/1       2/2      true
stable-cluster   1/1       1/1      true
```

## Conexión a los clústers creados con **k3d**

Por defecto *k3d* fusiona en el fichero `KUBECONFIG` (por defecto, en `$HOME/.kube/config`) la configuración de acceso al nuevo clúster. (`options.kubeconfig.updateDefaultKubeconfig: true`).

Puedes revisar la lista de todos los *contextos* definidos en el fichero de configuración:

```bash
$ kubectl config get-contexts
CURRENT   NAME                 CLUSTER              AUTHINFO                   NAMESPACE
          k3d-dev-cluster      k3d-dev-cluster      admin@k3d-dev-cluster      
*         k3d-stable-cluster   k3d-stable-cluster   admin@k3d-stable-cluster
```

Como vemos, por defecto se cambia el contexto actual (*current-context*) a la configuración correspondiente al último clúster creado (el *contexto* activo es el indicado con un `*`).

Para usar otro contexto (e interactuar con otro clúster) usa:

```bash
$ kubectl config use-context k3d-dev-cluster
Switched to context "k3d-dev-cluster".
```

## Añadir (o eliminar) nodos al clúster

**k3d** proporciona el comando `k3d node create` con el que añadimos nuevos nodos al clúster.

Para añadir un nodo agente al clúster `dev-cluster`:

> k3d añade el prefijo k3d- y un sufijo numérico indicando el número de réplicas.

```bash
$ k3d cluster list
NAME          SERVERS   AGENTS   LOADBALANCER
dev-cluster   1/1       1/1      true
$ export CLUSTER_NAME=dev-cluster
$ k3d node create dev-cluster-agent-1 --cluster $CLUSTER_NAME --role agent
INFO[0000] Starting Node 'k3d-dev-cluster-agent-1-0'
```

Validamos que se ha creado el nuevo nodo con el rol de agente:

```bash
$ k3d node list
NAME                        ROLE           CLUSTER       STATUS
k3d-dev-cluster-agent-0     agent          dev-cluster   running
k3d-dev-cluster-agent-1-0   agent          dev-cluster   running
k3d-dev-cluster-server-0    server         dev-cluster   running
k3d-dev-cluster-serverlb    loadbalancer   dev-cluster   running
```

## Resumen

Como ves, la creación de clústers usando **k3d** reduce al mínimo la fricción a la hora de generar clústers de Kubernetes para realizar pruebas sin consumir demasiados recursos. Por ello, es una solución conveniente para realizar pruebas prácticamente en cualquier sitio, desde localmente en el portátil del desarrollador, una Raspberry Pi o una instancia en algún servicio cloud.
