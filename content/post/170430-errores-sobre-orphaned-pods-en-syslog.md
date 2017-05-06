+++
draft = false
date = "2017-04-30T12:55:44+02:00"
title = "Errores sobre Orphaned pods en syslog"
thumbnail = "images/raspberry_pi.png"
categories = ["ops"]
tags = ["raspberry pi", "hypriot os", "kubernetes", "troubleshoting kubernetes"]

+++

Los nodos **k2** y **k3** del clúster dejan de responder pasadas unas horas. La única manera de solucionarlo es reiniciar los nodos. Siguiendo con la revisión de logs, he encontrado que se genera una gran cantidad de entradas en _syslog_ en referencia a _orphaned pods_. Además, el número de estos errores no para de crecer **rápidamente**.

<!--more-->

```shell
$ grep "kubelet_volumes.go:114] Orphaned pod" /var/log/syslog | wc -l
118938
$ grep "kubelet_volumes.go:114] Orphaned pod" /var/log/syslog | wc -l
119022
$ grep "kubelet_volumes.go:114] Orphaned pod" /var/log/syslog | wc -l
119170
```

Revisando las últimas entradas del log:

```log
Apr 30 10:57:57 k2 kubelet[3619]: E0430 10:57:57.186318    3619 kubelet_volumes.go:114] Orphaned pod "5064b9d9-2c9e-11e7-a7ae-b827eb650fdb" found, but volume paths are still present on disk.
Apr 30 10:58:01 k2 kubelet[3619]: E0430 10:58:01.759595    3619 kubelet_volumes.go:114] Orphaned pod "6c601e9c-2c9c-11e7-a7ae-b827eb650fdb" found, but volume paths are still present on disk.
Apr 30 10:58:03 k2 kubelet[3619]: E0430 10:58:03.226372    3619 kubelet.go:1549] Unable to mount volumes for pod "weave-net-bs9bs_kube-system(4461d51d-2d93-11e7-a7ae-b827eb650fdb)": timeout expired waiting for volumes to attach/mount for pod "kube-system"/"weave-net-bs9bs". list of unattached/unmounted volumes=[weavedb cni-bin cni-bin2 cni-conf dbus lib-modules weave-net-token-61scv]; skipping pod
Apr 30 10:58:03 k2 kubelet[3619]: E0430 10:58:03.238315    3619 pod_workers.go:182] Error syncing pod 4461d51d-2d93-11e7-a7ae-b827eb650fdb ("weave-net-bs9bs_kube-system(4461d51d-2d93-11e7-a7ae-b827eb650fdb)"), skipping: timeout expired waiting for volumes to attach/mount for pod "kube-system"/"weave-net-bs9bs". list of unattached/unmounted volumes=[weavedb cni-bin cni-bin2 cni-conf dbus lib-modules weave-net-token-61scv]
Apr 30 10:58:05 k2 kubelet[3619]: E0430 10:58:05.830432    3619 kubelet_volumes.go:114] Orphaned pod "bb4d3ea6-2b80-11e7-9388-b827eb650fdb" found, but volume paths are still present on disk.
Apr 30 10:58:08 k2 kubelet[3619]: E0430 10:58:08.435567    3619 kubelet_volumes.go:114] Orphaned pod "cb23be0d-2d7e-11e7-a7ae-b827eb650fdb" found, but volume paths are still present on disk.
```

Todas estas entradas se encuentran en los logs del nodo **k2**, donde no hay ningún _pod_ en ejecución (a parte de los propios de  Kubernetes que el clúster planifica en los diferentes nodos).

**Actualización**: [Troubleshooting Kubernetes (II)]({{< ref "170506-troubleshooting-kubernetes-ii.md" >}})

