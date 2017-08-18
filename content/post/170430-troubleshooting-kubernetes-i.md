+++
draft = false
thumbnail = "images/kubernetes.png"
categories = ["ops"]
tags = ["raspberry pi", "hypriot", "kubernetes", "troubleshooting"]
date = "2017-04-30T15:24:35+02:00"
title = "Troubleshooting Kubernetes (I)"

+++

Tras la alegría inicial pensando que la configuración de _rsyslog_ era la causante de los cuelgues de las dos RPi 3 ([El nodo k3 del clúster colgado de nuevo]({{% ref "170430-k3-colgado-de-nuevo.md" %}})), pasadas unas horas los dos nodos **k2** y **k3** han dejado de responder de nuevo.

Así que es el momento de atacar el problema de forma algo más sistemática. Para ello seguiré las instrucciones que proporcina la página de Kubernetes [Troubleshooting Clusters](https://kubernetes.io/docs/tasks/debug-application-cluster/debug-cluster/).
<!--more-->

# Descripción del problema

Tras unas horas activos y formando parte del clúster, los dos nodos que corren sobre Raspberry Pi 3 dejan de responder y el clúster los muestra como _NotReady_.

El clúster está formado por tres Raspberry Pi; el nodo _master_ es una Raspberry Pi 2 B mientras que los dos nodos _worker_ son Raspberry Pi 3 B.

```shell
$ kubectl get nodes -o wide
NAME      STATUS     AGE       VERSION   EXTERNAL-IP   OS-IMAGE                        KERNEL-VERSION
k1        Ready      19d       v1.6.2    <none>        Raspbian GNU/Linux 8 (jessie)   4.4.50-hypriotos-v7+
k2        NotReady   15d       v1.6.2    <none>        Raspbian GNU/Linux 8 (jessie)   4.4.50-hypriotos-v7+
k3        NotReady   14d       v1.6.2    <none>        Raspbian GNU/Linux 8 (jessie)   4.4.50-hypriotos-v7+
```

# Ping

## Ping al nombre del nodo

La prueba más sencilla para ver si los nodos están colgados, es lanzar un ping desde el portátil:

```shell
$ ping -c5 k2.local
ping: cannot resolve k2.local: Unknown host
$ ping -c5 k3.local
ping: cannot resolve k3.local: Unknown host
```

En esta prueba vemos que ninguno de los nodos responde al nombre que _publica_ el servicio [Avahi](https://en.wikipedia.org/wiki/Avahi_(software)) en el sistema.

## Ping a la IP del nodo

```shell
$ ping -c5 192.168.1.12
PING 192.168.1.12 (192.168.1.12): 56 data bytes
64 bytes from 192.168.1.12: icmp_seq=0 ttl=64 time=3.842 ms
64 bytes from 192.168.1.12: icmp_seq=1 ttl=64 time=6.678 ms
64 bytes from 192.168.1.12: icmp_seq=2 ttl=64 time=10.789 ms
64 bytes from 192.168.1.12: icmp_seq=3 ttl=64 time=7.411 ms
64 bytes from 192.168.1.12: icmp_seq=4 ttl=64 time=10.518 ms

--- 192.168.1.12 ping statistics ---
5 packets transmitted, 5 packets received, 0.0% packet loss
round-trip min/avg/max/stddev = 3.842/7.848/10.789/2.584 ms
$ ping -c5 192.168.1.13
PING 192.168.1.13 (192.168.1.13): 56 data bytes
Request timeout for icmp_seq 0
Request timeout for icmp_seq 1
Request timeout for icmp_seq 2
Request timeout for icmp_seq 3

--- 192.168.1.13 ping statistics ---
5 packets transmitted, 0 packets received, 100.0% packet loss
$
```

En este caso, el nodo **k2** sí que responde a ping a la IP, mientras que el nodo **k3** actúa como si estuviera apagado o con la red deshabilitada.

## SSH

Aunque el nodo **k2** responde a ping, no es posible conectar vía SSH; el intento de conectar no tiene éxito, pero tampoco falla (por _timeout_, por ejemplo). He probado a conectar tanto desde el portátil como desde el nodo **k1**, con el mismo resulado:

```shell
ssh pirate@192.168.1.12

```

# kubelet describe node

Usamos el comando `kubelet describe node` para los dos nodos colgados.

## Nodo **k2**

```shell
$ kubectl describe node k2
Name:			k2
Role:
Labels:			beta.kubernetes.io/arch=arm
			beta.kubernetes.io/os=linux
			kubernetes.io/hostname=k2
Annotations:		node.alpha.kubernetes.io/ttl=0
			volumes.kubernetes.io/controller-managed-attach-detach=true
Taints:			<none>
CreationTimestamp:	Sat, 15 Apr 2017 10:25:31 +0000
Phase:
Conditions:
  Type			Status		LastHeartbeatTime			LastTransitionTime			Reason			Message
  ----			------		-----------------			------------------			------			-------
  OutOfDisk 		Unknown 	Sun, 30 Apr 2017 11:56:26 +0000 	Sun, 30 Apr 2017 11:57:11 +0000 	NodeStatusUnknown 	Kubelet stopped posting node status.
  MemoryPressure 	Unknown 	Sun, 30 Apr 2017 11:56:26 +0000 	Sun, 30 Apr 2017 11:57:11 +0000 	NodeStatusUnknown 	Kubelet stopped posting node status.
  DiskPressure 		Unknown 	Sun, 30 Apr 2017 11:56:26 +0000 	Sun, 30 Apr 2017 11:57:11 +0000 	NodeStatusUnknown 	Kubelet stopped posting node status.
  Ready 		Unknown 	Sun, 30 Apr 2017 11:56:26 +0000 	Sun, 30 Apr 2017 11:57:11 +0000 	NodeStatusUnknown 	Kubelet stopped posting node status.
Addresses:		192.168.1.12,192.168.1.12,k2
Capacity:
 cpu:		4
 memory:	882632Ki
 pods:		110
Allocatable:
 cpu:		4
 memory:	780232Ki
 pods:		110
System Info:
 Machine ID:			9989a26f06984d6dbadc01770f018e3b
 System UUID:			9989a26f06984d6dbadc01770f018e3b
 Boot ID:			84bf8a2b-b83f-445b-a4b3-250dc6e5db40
 Kernel Version:		4.4.50-hypriotos-v7+
 OS Image:			Raspbian GNU/Linux 8 (jessie)
 Operating System:		linux
 Architecture:			arm
 Container Runtime Version:	docker://Unknown
 Kubelet Version:		v1.6.2
 Kube-Proxy Version:		v1.6.2
PodCIDR:			10.244.2.0/24
ExternalID:			k2
Non-terminated Pods:		(2 in total)
  Namespace			Name				CPU Requests	CPU Limits	Memory Requests	Memory Limits
  ---------			----				------------	----------	---------------	-------------
  kube-system			kube-proxy-g580s		0 (0%)		0 (0%)		0 (0%)		0 (0%)
  kube-system			weave-net-kxpk6			20m (0%)	0 (0%)		0 (0%)		0 (0%)
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  CPU Requests	CPU Limits	Memory Requests	Memory Limits
  ------------	----------	---------------	-------------
  20m (0%)	0 (0%)		0 (0%)		0 (0%)
Events:		<none>
```

### Nodo **k3**

```shell
$ kubectl describe node k3
Name:			k3
Role:
Labels:			beta.kubernetes.io/arch=arm
			beta.kubernetes.io/os=linux
			kubernetes.io/hostname=k3
Annotations:		node.alpha.kubernetes.io/ttl=0
			volumes.kubernetes.io/controller-managed-attach-detach=true
Taints:			<none>
CreationTimestamp:	Sat, 15 Apr 2017 14:10:06 +0000
Phase:
Conditions:
  Type			Status		LastHeartbeatTime			LastTransitionTime			Reason			Message
  ----			------		-----------------			------------------			------			-------
  OutOfDisk 		Unknown 	Sun, 30 Apr 2017 10:33:45 +0000 	Sun, 30 Apr 2017 10:34:28 +0000 	NodeStatusUnknown 	Kubelet stopped posting node status.
  MemoryPressure 	Unknown 	Sun, 30 Apr 2017 10:33:45 +0000 	Sun, 30 Apr 2017 10:34:28 +0000 	NodeStatusUnknown 	Kubelet stopped posting node status.
  DiskPressure 		Unknown 	Sun, 30 Apr 2017 10:33:45 +0000 	Sun, 30 Apr 2017 10:34:28 +0000 	NodeStatusUnknown 	Kubelet stopped posting node status.
  Ready 		Unknown 	Sun, 30 Apr 2017 10:33:45 +0000 	Sun, 30 Apr 2017 10:34:28 +0000 	NodeStatusUnknown 	Kubelet stopped posting node status.
Addresses:		192.168.1.13,192.168.1.13,k3
Capacity:
 cpu:		4
 memory:	882632Ki
 pods:		110
Allocatable:
 cpu:		4
 memory:	780232Ki
 pods:		110
System Info:
 Machine ID:			9989a26f06984d6dbadc01770f018e3b
 System UUID:			9989a26f06984d6dbadc01770f018e3b
 Boot ID:			23bf96e4-ec65-489c-be00-d0fa848265f3
 Kernel Version:		4.4.50-hypriotos-v7+
 OS Image:			Raspbian GNU/Linux 8 (jessie)
 Operating System:		linux
 Architecture:			arm
 Container Runtime Version:	docker://Unknown
 Kubelet Version:		v1.6.2
 Kube-Proxy Version:		v1.6.2
PodCIDR:			10.244.3.0/24
ExternalID:			k3
Non-terminated Pods:		(2 in total)
  Namespace			Name				CPU Requests	CPU Limits	Memory Requests	Memory Limits
  ---------			----				------------	----------	---------------	-------------
  kube-system			kube-proxy-bkl4g		0 (0%)		0 (0%)		0 (0%)		0 (0%)
  kube-system			weave-net-3bf40			20m (0%)	0 (0%)		0 (0%)		0 (0%)
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  CPU Requests	CPU Limits	Memory Requests	Memory Limits
  ------------	----------	---------------	-------------
  20m (0%)	0 (0%)		0 (0%)		0 (0%)
Events:		<none>
```

El nodo **k2** deja de responder a las 11:56:26, mientras que el **k3** lo hace a las 10:33:45.

* [x] Cuando reinicie los dos nodos lo haré a la misma hora, para comprobar si hay diferencias en el tiempo que tarda en dejar de responder cada nodo.
* [ ] Actualizar la zona horaria de las Raspberry Pi.

### Nodo **k1** (`Ready`)

Como referencia, incluimos el mismo comando para el nodo _master_ **k1**:

```shell
$ kubectl describe node k1
Name:			k1
Role:
Labels:			beta.kubernetes.io/arch=arm
			beta.kubernetes.io/os=linux
			kubernetes.io/hostname=k1
			node-role.kubernetes.io/master=
Annotations:		node.alpha.kubernetes.io/ttl=0
			volumes.kubernetes.io/controller-managed-attach-detach=true
Taints:			node-role.kubernetes.io/master:NoSchedule
CreationTimestamp:	Mon, 10 Apr 2017 20:22:32 +0000
Phase:
Conditions:
  Type			Status	LastHeartbeatTime			LastTransitionTime			Reason				Message
  ----			------	-----------------			------------------			------				-------
  OutOfDisk 		False 	Sun, 30 Apr 2017 14:01:10 +0000 	Sun, 30 Apr 2017 06:37:10 +0000 	KubeletHasSufficientDisk 	kubelet has sufficient disk space available
  MemoryPressure 	False 	Sun, 30 Apr 2017 14:01:10 +0000 	Sun, 30 Apr 2017 06:37:10 +0000 	KubeletHasSufficientMemory 	kubelet has sufficient memory available
  DiskPressure 		False 	Sun, 30 Apr 2017 14:01:10 +0000 	Sun, 30 Apr 2017 06:37:10 +0000 	KubeletHasNoDiskPressure 	kubelet has no disk pressure
  Ready 		True 	Sun, 30 Apr 2017 14:01:10 +0000 	Sun, 30 Apr 2017 06:37:20 +0000 	KubeletReady 			kubelet is posting ready status
Addresses:		192.168.1.11,192.168.1.11,k1
Capacity:
 cpu:		4
 memory:	882632Ki
 pods:		110
Allocatable:
 cpu:		4
 memory:	780232Ki
 pods:		110
System Info:
 Machine ID:			9989a26f06984d6dbadc01770f018e3b
 System UUID:			9989a26f06984d6dbadc01770f018e3b
 Boot ID:			55e1fad0-d40c-480b-b039-5586ff728d2c
 Kernel Version:		4.4.50-hypriotos-v7+
 OS Image:			Raspbian GNU/Linux 8 (jessie)
 Operating System:		linux
 Architecture:			arm
 Container Runtime Version:	docker://Unknown
 Kubelet Version:		v1.6.2
 Kube-Proxy Version:		v1.6.2
PodCIDR:			10.244.0.0/24
ExternalID:			k1
Non-terminated Pods:		(7 in total)
  Namespace			Name					CPU Requests	CPU Limits	Memory Requests	Memory Limits
  ---------			----					------------	----------	---------------	-------------
  kube-system			etcd-k1					0 (0%)		0 (0%)		0 (0%)		0 (0%)
  kube-system			kube-apiserver-k1			250m (6%)	0 (0%)		0 (0%)		0 (0%)
  kube-system			kube-controller-manager-k1		200m (5%)	0 (0%)		0 (0%)		0 (0%)
  kube-system			kube-dns-279829092-1b27r		260m (6%)	0 (0%)		110Mi (14%)	170Mi (22%)
  kube-system			kube-proxy-3dggd			0 (0%)		0 (0%)		0 (0%)		0 (0%)
  kube-system			kube-scheduler-k1			100m (2%)	0 (0%)		0 (0%)		0 (0%)
  kube-system			weave-net-6qr0l				20m (0%)	0 (0%)		0 (0%)		0 (0%)
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  CPU Requests	CPU Limits	Memory Requests	Memory Limits
  ------------	----------	---------------	-------------
  830m (20%)	0 (0%)		110Mi (14%)	170Mi (22%)
Events:		<none>
```

## Revisando los logs en el nodo _master_

En la guía de _Troubleshooting_ de Kubernetes, el siguiente paso es revisar los logs. En el caso del nodo _master_, los logs relevantes se encuentran en:

* `/var/log/kube-apiserver.log` - El _API Server_, encargado de servir la API
* `/var/log/kube-scheduler.log` - El _Scheduler_, encargado de las decisiones de planificar los _pods_ en los nodos
* `/var/log/kube-controller-manager.log` - El responsable de gestionar los _replication controllers_ encargados de mantener el **estado deseado**

Sin embargo, los logs indicados **no existen en la ruta indicada**:

```shell
$ ls /var/log/kube*
ls: cannot access /var/log/kube*: No such file or directory
```

Es probable que la documentación no esté actualizada, así que continuaré en cuanto encuentre los logs para poder revisarlos.
