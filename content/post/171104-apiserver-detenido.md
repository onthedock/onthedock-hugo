+++
draft = false

# TAGS
# HW->OS->PRODUCT->specific tag
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["kubernetes"]

# CATEGORIES = "dev" / "ops"
categories = ["ops"]

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

title=  "API server detenido: The connection to the server was refused"
date = "2017-11-04T21:58:52+01:00"
+++

Hoy, al intentar lanzar un comando con `kubectl`, he obtenido el típico mensaje indicando que no se puede conectar con el servidor. El problema está en el servidor de API, que es el que actua como intermediario entre el usuario y Kubernetes. Últimamente he encontrado el mismo error y lo he solucionado reiniciando el nodo _master_ del clúster. Pero hoy he investigado un poco... Y lo que he encontrado no me ha gustado demasiado.

<!--more-->

El problema se observa en cuanto intentas lanzar un comando con `kubectl`:

```shell
$ kubectl get nodes
The connection to the server 192.168.1.11:6443 was refused - did you specify the right host or port?
```

Como no hay forma de comunicar con Kubernetes, uso `docker ps` para observar el estado de los diferentes contenedores del _control plane_ de Kubernetes:

```shell
$ docker ps -a
CONTAINER ID        IMAGE                                                  COMMAND                  CREATED             STATUS                     PORTS               NAMES
6ef208ad4c36        gcr.io/google_containers/kube-apiserver-arm            "kube-apiserver --..."   3 days ago          Exited (255) 3 days ago                        k8s_kube-apiserver_kube-apiserver-k1_kube-system_c0f77be12d1bf28aaecf7cc373a774b6_5
45cee0251e6e        gcr.io/google_containers/k8s-dns-sidecar-arm           "/sidecar --v=2 --..."   9 days ago          Up 9 days                                      k8s_sidecar_kube-dns-66ffd5c588-5gvsc_kube-system_5ef537a4-b67c-11e7-8cb3-b827eb650fdb_1
a832db03112d        gcr.io/google_containers/k8s-dns-dnsmasq-nanny-arm     "/dnsmasq-nanny -v..."   9 days ago          Up 9 days                                      k8s_dnsmasq_kube-dns-66ffd5c588-5gvsc_kube-system_5ef537a4-b67c-11e7-8cb3-b827eb650fdb_1
288ab144f5c5        gcr.io/google_containers/k8s-dns-kube-dns-arm          "/kube-dns --domai..."   9 days ago          Up 9 days
...
```

Como puede observarse en la salida del comando, el contenedor del API server falló hace tres días (he estado fuera 4 días). He intentado arrancar el contenedor mediante `docker start`, pero no ha funcionado.

He intentado obtener los logs del contenedor, pero tampoco he tenido éxito, precisamente porque no puedo conectar con el API server:

```shell
$ kubectl logs 6ef208ad4c36
The connection to the server 192.168.1.11:6443 was refused - did you specify the right host or port?
```

Así que, de nuevo, he intentado usar Docker directamente:

```shell
$ docker logs 6ef208ad4c36
Error response from daemon: stat /var/lib/docker/overlay2/1d2dd8b0acc2ec2c153faf571fd80c27b8ff113ece23a97860a5b049f9d3b183: no such file or directory
```

Sin información de qué es lo que le ha pasado al contenedor, no puedo avanzar mucho. En la documentación oficial de Kubernetes, en la [sección de _troubleshooting_](https://kubernetes.io/docs/tasks/debug-application-cluster/debug-cluster/) se indica que los _logs_ se encuentran en:

>  Master
>
> * /var/log/kube-apiserver.log - API Server, responsible for serving the API
> * /var/log/kube-scheduler.log - Scheduler, responsible for making scheduling decisions
> * /var/log/kube-controller-manager.log - Controller that manages replication controllers
>
> Worker Nodes
>
> * /var/log/kubelet.log - Kubelet, responsible for running containers on the node
> * /var/log/kube-proxy.log - Kube Proxy, responsible for service load balancing

Sin embargo, los logs no se encuentran en la ubicación indicada:

```shell
$ ls /var/log/kube-*
ls: cannot access /var/log/kube-*: No such file or directory
```

Para encontrar dónde se encuentra el fichero, busco usando:

```shell
$ sudo find / -iname "kube*log"
/var/log/pods/dda418d2bc54e897654d295f2156b331/kube-controller-manager_0.log
/var/log/pods/c0f77be12d1bf28aaecf7cc373a774b6/kube-apiserver_0.log
/var/log/pods/864488f96fd16d6c70d1eb754228dd63/kube-scheduler_0.log
/var/log/pods/5ef537a4-b67c-11e7-8cb3-b827eb650fdb/kubedns_0.log
/var/log/pods/5ef6f558-b67c-11e7-8cb3-b827eb650fdb/kube-proxy_0.log
/var/log/containers/kube-dns-66ffd5c588-5gvsc_kube-system_kubedns-627ae5eebc9e0d261033f323820b1b2c58a03b7bbaaf7d510e8cb242e80bde1f.log
/var/log/containers/kube-apiserver-k1_kube-system_kube-apiserver-e2f69b23c5ed6c30c440bd2974362a4b66ef1e03bf24a91c8d45386cb7465074.log
/var/log/containers/kube-proxy-g9wg2_kube-system_kube-proxy-e71af338d9df5606c6c1925dbda3315221f203ef46e28f3a36b7393937231167.log
/var/log/containers/kube-apiserver-k1_kube-system_kube-apiserver-6ef208ad4c36ac7dae20a7f4d1bbd23725027c5505d71a41e2476d6bfc0fa826.log
/var/log/containers/kube-dns-66ffd5c588-5gvsc_kube-system_sidecar-07fb05e5e076de09c4ca8e898865cf7d23e120ba2d4a1f12168bacf5a358fb1c.log
/var/log/containers/kube-dns-66ffd5c588-5gvsc_kube-system_dnsmasq-198e2648d2aeab19642c386ddae02d373af6950bc68ce82121785fd41ae0e64f.log
```

Entre los resultados observo que se encuentra el fichero `kube-appiserver_0.log`, que es lo más parecido al log que busco.

```shell
$ sudo !!
sudo tail /var/log/pods/c0f77be12d1bf28aaecf7cc373a774b6/kube-apiserver_0.log
{"log":"I1023 01:18:42.960933       1 trace.go:76] Trace[337274143]: \"Get /api/v1/namespaces/kube-system\" (started: 2017-10-23 01:18:42.38724446 +0000 UTC) (total time: 573.403754ms):\n","stream":"stderr","time":"2017-10-23T01:18:42.961947592Z"}
{"log":"Trace[337274143]: [572.874013ms] [572.800003ms] About to write a response\n","stream":"stderr","time":"2017-10-23T01:18:42.962312802Z"}
{"log":"I1023 02:42:38.361259       1 trace.go:76] Trace[1274919061]: \"GuaranteedUpdate etcd3: *api.Endpoints\" (started: 2017-10-23 02:42:37.785909186 +0000 UTC) (total time: 575.108669ms):\n","stream":"stderr","time":"2017-10-23T02:42:38.36211817Z"}
{"log":"Trace[1274919061]: [574.898772ms] [573.472622ms] Transaction committed\n","stream":"stderr","time":"2017-10-23T02:42:38.362468223Z"}
{"log":"I1023 02:42:38.362198       1 trace.go:76] Trace[103451536]: \"Update /api/v1/namespaces/kube-system/endpoints/kube-scheduler\" (started: 2017-10-23 02:42:37.785238299 +0000 UTC) (total time: 576.700235ms):\n","stream":"stderr","time":"2017-10-23T02:42:38.362646088Z"}
{"log":"Trace[103451536]: [576.161015ms] [575.766326ms] Object stored in database\n","stream":"stderr","time":"2017-10-23T02:42:38.362784474Z"}
{"log":"I1023 03:12:12.811461       1 trace.go:76] Trace[1516791138]: \"GuaranteedUpdate etcd3: *api.Node\" (started: 2017-10-23 03:12:12.280394866 +0000 UTC) (total time: 530.751679ms):\n","stream":"stderr","time":"2017-10-23T03:12:12.812799938Z"}
{"log":"Trace[1516791138]: [529.976416ms] [509.72492ms] Transaction committed\n","stream":"stderr","time":"2017-10-23T03:12:12.813138273Z"}
{"log":"I1023 04:13:09.997217       1 trace.go:76] Trace[745949868]: \"GuaranteedUpdate etcd3: *api.Node\" (started: 2017-10-23 04:13:09.329786766 +0000 UTC) (total time: 659.869359ms):\n","stream":"stderr","time":"2017-10-23T04:13:09.99824922Z"}
{"log":"Trace[745949868]: [650.270324ms] [649.75251ms] Transaction prepared\n","stream":"stderr","time":"2017-10-23T04:13:09.998615002Z"}
```

Pero la información contenida en el fichero de log no coincide -por fechas- con los _últimos momentos de vida_ del _pod_ c0f77be12d1bf28aaecf7cc373a774b6.

Si embargo, siguiendo la pista de la misma página [https://kubernetes.io/docs/tasks/debug-application-cluster/debug-cluster/](https://kubernetes.io/docs/tasks/debug-application-cluster/debug-cluster/), se indica que en las distribuciones que usen `systemd` hay que usar `journalctl`.

Usando `journalctl` fue tan sencillo como lanzar `sudo journalctl | grep apiserver | less`. Entre la salida del comando se observa un patrón de mensajes:

```log
...
Nov 05 06:07:57 k1 kubelet[319]: E1105 06:07:57.028616     319 reflector.go:205] k8s.io/kubernetes/pkg/kubelet/config/apiserver.go:47: Failed to list *v1.Pod: Get https://192.168.1.11:6443/api/v1/pods?fieldSelector=spec.nodeName%3Dk1&resourceVersion=0: dial tcp 192.168.1.11:6443: getsockopt: connection refused
Nov 05 06:07:57 k1 kubelet[319]: E1105 06:07:57.076083     319 kuberuntime_manager.go:840] PodSandboxStatus of sandbox "7d9ec7433434e66bee7d0458ece2e142e80a5825884cca2f5f17a5f0ca548d2a" for pod "kube-apiserver-k1_kube-system(c0f77be12d1bf28aaecf7cc373a774b6)" error: rpc error: code = Unknown desc = Error response from daemon: open /var/lib/docker/overlay2/74217d05e7d37d111ce00a444c0a4237618a5474a8ca72393feeea664532d30b/lower: structure needs cleaning
Nov 05 06:07:57 k1 kubelet[319]: E1105 06:07:57.076376     319 generic.go:241] PLEG: Ignoring events for pod kube-apiserver-k1/kube-system: rpc error: code = Unknown desc = Error response from daemon: open /var/lib/docker/overlay2/74217d05e7d37d111ce00a444c0a4237618a5474a8ca72393feeea664532d30b/lower: structure needs cleaning
Nov 05 06:07:57 k1 kubelet[319]: E1105 06:07:57.236495     319 kuberuntime_manager.go:840] PodSandboxStatus of sandbox "7d9ec7433434e66bee7d0458ece2e142e80a5825884cca2f5f17a5f0ca548d2a" for pod "kube-apiserver-k1_kube-system(c0f77be12d1bf28aaecf7cc373a774b6)" error: rpc error: code = Unknown desc = Error response from daemon: open /var/lib/docker/overlay2/74217d05e7d37d111ce00a444c0a4237618a5474a8ca72393feeea664532d30b/lower: structure needs cleaning
...
```

En primer lugar, el mensaje de _connection refused_ que se obtiene al intentar ejecutar cualquier comando con _kubectl_. A continuación, mensajes de errores de RPC del _pod_ donde se ejecuta el API Server: _Error response from daemon_. Y la causa parece ser que al intentar abrir `/var/lib/docker/overlay2/74217d05e7d37d111ce00a444c0a4237618a5474a8ca72393feeea664532d30b/lower` se produce un error `structure needs cleaning`.

Al intentar averiguar qué le pasa al fichero, lanzo `sudo ls -la  /var/lib/docker/overlay2/74217d05e7d37d111ce00a444c0a4237618a5474a8ca72393feeea664532d30b/` y la salida es preocupante:

```shell
$ sudo ls -la  /var/lib/docker/overlay2/74217d05e7d37d111ce00a444c0a4237618a5474a8ca72393feeea664532d30b/
ls: cannot access /var/lib/docker/overlay2/74217d05e7d37d111ce00a444c0a4237618a5474a8ca72393feeea664532d30b/link: Structure needs cleaning
ls: cannot access /var/lib/docker/overlay2/74217d05e7d37d111ce00a444c0a4237618a5474a8ca72393feeea664532d30b/lower: Structure needs cleaning
total 32
drwx------  5 root root  4096 Oct 23 04:17 .
drwx------ 95 root root 16384 Nov  1 06:48 ..
drwxr-xr-x  2 root root  4096 Oct 23 04:17 diff
-?????????  ? ?    ?        ?            ? link
-?????????  ? ?    ?        ?            ? lower
drwxr-xr-x  1 root root  4096 Oct 23 04:17 merged
drwx------  3 root root  4096 Oct 23 04:17 work
```

El sistema operativo no sabe qué son los fichero `link` o `lower`. Si intentas inspeccionar su contenido:

```shell
$ sudo cat /var/lib/docker/overlay2/74217d05e7d37d111ce00a444c0a4237618a5474a8ca72393feeea664532d30b/lower
cat: /var/lib/docker/overlay2/74217d05e7d37d111ce00a444c0a4237618a5474a8ca72393feeea664532d30b/lower: Structure needs cleaning
```

Al buscar en Google `Structure needs cleaning` todas las respuestas apuntan a una corrupción del sistema de ficheros (por ejemplo: [Has anyone ever gotten "structure needs cleaning" errors on their EXT4 file system?](https://www.reddit.com/r/linuxquestions/comments/4b47r2/has_anyone_ever_gotten_structure_needs_cleaning/) o [Cannot remove file: “Structure needs cleaning”](https://unix.stackexchange.com/questions/330742/cannot-remove-file-structure-needs-cleaning)).

Aunque todas las soluciones apuntan de una forma u otra a ejecutar un `fsck`, siempre se refieren a particiones diferentes a `/`, que al estar montada no puede analizarse (o que puede provocar más problemas de los que soluciona).
Así que he optado por marcar el sistema de ficheros como `dirty` y reiniciar, con la esperanza de que el propio sistema realice la limpieza. Después del reinicio -y de que el _control plane_ arranque-, he podido ejecutar de nuevo los comandos vía _kubectl_.

Como no estaba seguro de si se había ejecutado la limpieza, he seguido las instrucciones en [Linux Force fsck on the Next Reboot or Boot Sequence](https://www.cyberciti.biz/faq/linux-force-fsck-on-the-next-reboot-or-boot-sequence/) para **forzar** la limpieza del disco después del reinicio.

Y de nuevo, después de volver a arrancar, el sistema responde y no encuentro problemas con el API server.

Durante los próximos días revisaré si el problema con el _pod_ del API server se reproduce o si se ha solucionado definitivamente después de ejecutar el _fsck_.