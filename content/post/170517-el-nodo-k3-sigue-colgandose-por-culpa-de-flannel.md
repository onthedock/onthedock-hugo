+++
categories = ["ops"]
tags = ["raspberry pi", "hypriot", "kubernetes", "troubleshooting"]
draft = false
thumbnail = "images/kubernetes.png"
date = "2017-05-17T21:02:21+02:00"
title = "El nodo k3 sigue colgandose por culpa de Flannel"

+++

En la entrada [Troubleshooting Kubernetes (II)]({{< ref "170506-troubleshooting-kubernetes-ii.md" >}}) encontré restos de la instalación de [Flannel](https://github.com/coreos/flannel) en la Raspberry Pi. Eliminé los _pods_ que hacían referencia a Flannel y conseguí que el nodo **k2** no se volviera a colgar.

Sin embargo, el problema sigue dándose en el nodo **k3**.

Revisando el contenido de `/var/lib/kubernetes/pods/` he visto que algunos _pods_ hacían referencia, todavía, a Flannel.

<!--more-->

```shell
...
/var/lib/kubelet/pods/3a5e2819-21e5-11e7-bcfd-b827eb650fdb/volumes/kubernetes.io~configmap/wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_flannel-cfg.deleting~470691428.deleting~439642480.deleting~747926470.deleting~067946013.deleting~791070092.deleting~964331938.deleting~717873461.deleting~755129373.deleting~499171027
/var/lib/kubelet/pods/3a5e2819-21e5-11e7-bcfd-b827eb650fdb/volumes/kubernetes.io~configmap/wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_flannel-cfg.deleting~504683568.deleting~184413472.deleting~138413964.deleting~985160408.deleting~943143520.deleting~459558341.deleting~578589077.deleting~501462031.deleting~769373718
/var/lib/kubelet/pods/3a5e2819-21e5-11e7-bcfd-b827eb650fdb/volumes/kubernetes.io~configmap/wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_flannel-cfg.deleting~613861491.deleting~841547526.deleting~012178845.deleting~177797190.deleting~192052322.deleting~958792988.deleting~338401309.deleting~623810479.deleting~369130424
/var/lib/kubelet/pods/3a5e2819-21e5-11e7-bcfd-b827eb650fdb/volumes/kubernetes.io~configmap/wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_flannel-cfg.deleting~470691428.deleting~288881360.deleting~534630955.deleting~520377076.deleting~598159984.deleting~426698803.deleting~142931759.deleting~872800923.deleting~808586860
/var/lib/kubelet/pods/3a5e2819-21e5-11e7-bcfd-b827eb650fdb/volumes/kubernetes.io~configmap/wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_flannel-cfg.deleting~470691428.deleting~439642480.deleting~747926470.deleting~067946013.deleting~791070092.deleting~622848191.deleting~646325460.deleting~868409130.deleting~824166496
/var/lib/kubelet/pods/3a5e2819-21e5-11e7-bcfd-b827eb650fdb/volumes/kubernetes.io~configmap/wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_flannel-cfg.deleting~668636622.deleting~334825066.deleting~737147422.deleting~055159245.deleting~572255670.deleting~485248219.deleting~690855316.deleting~753094008.deleting~457647557
/var/lib/kubelet/pods/3a5e2819-21e5-11e7-bcfd-b827eb650fdb/volumes/kubernetes.io~configmap/wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_flannel-cfg.deleting~756292309.deleting~273222811.deleting~039503494.deleting~182629307.deleting~984614903.deleting~081831640.deleting~628560452.deleting~303652395.deleting~450650534
/var/lib/kubelet/pods/3a5e2819-21e5-11e7-bcfd-b827eb650fdb/volumes/kubernetes.io~configmap/wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_wrapped_flannel-cfg.deleting~883601122.deleting~535739903.deleting~385002935.deleting~558075878.deleting~174007749.deleting~757820208.deleting~194356513.deleting~813327027.deleting~485662152
...
```

Esta vez he detectado el problema al intentar calcular el espacio usado por esta carpeta, ya que la Raspberry Pi se ha quedado como "colgada", aunque al lanzar _htop_ no se observaba un uso excesivo de CPU.

Finalmente, he usado el mismo sistema que la otra vez: eliminar todas las subcarpetas de cada uno de los _pods_ (dejando únicamente los que no se pueden borrar al estar en uso).

Después de la purga masiva de `rm -rf /var/lib/kubelet/pods/` sólo han quedado dos carpetas _en uso_; el número corresponde con el número de _pods_ planificados sobre el nodo **k3** desde `kubectl`:

```shell
$ kubectl get pods --all-namespaces -o wide
NAMESPACE     NAME                         READY     STATUS    RESTARTS   AGE       IP             NODE
kube-system   etcd-k1                      1/1       Running   4          36d       192.168.1.11   k1
kube-system   kube-apiserver-k1            1/1       Running   4          36d       192.168.1.11   k1
kube-system   kube-controller-manager-k1   1/1       Running   4          36d       192.168.1.11   k1
kube-system   kube-dns-279829092-1b27r     3/3       Running   12         36d       10.32.0.2      k1
kube-system   kube-proxy-20t3b             1/1       Running   0          25m       192.168.1.13   k3
kube-system   kube-proxy-3dggd             1/1       Running   4          36d       192.168.1.11   k1
kube-system   kube-proxy-5b8k3             1/1       Running   2          12d       192.168.1.12   k2
kube-system   kube-scheduler-k1            1/1       Running   4          36d       192.168.1.11   k1
kube-system   weave-net-6qr0l              2/2       Running   8          36d       192.168.1.11   k1
kube-system   weave-net-mxp2w              2/2       Running   0          25m       192.168.1.13   k3
kube-system   weave-net-tmmdj              2/2       Running   4          12d       192.168.1.12   k2
$
```

Un reinicio y ¡listo!, problema -espero- resuelto de forma definitiva.
