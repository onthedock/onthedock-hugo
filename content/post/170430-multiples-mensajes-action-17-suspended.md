+++
date = "2017-04-30T08:44:27+02:00"
title = "Múltiples mensajes 'action 17 suspended' en los logs"
draft = false
thumbnail = "images/raspberry_pi.png"
categories = ["ops"]
tags = ["debian", "raspberry pi"]

+++
Investigando las causas por las que los dos nodos con Raspberry Pi 3 se _cuelgan_, he encontrado múltiples apariciones de este mensaje en `/var/log/messages`:

```log
Apr 30 06:40:42 k3 rsyslogd-2007: action 'action 17' suspended, next retry is Sun Apr 30 06:41:12 2017 [try http://www.rsyslog.com/e/2007 ]
```

<!--more-->

De hecho, revisando el origen del problema he encontrado este comando que cuenta las apariciones del mensaje:

```shell
$ sudo grep "action.*suspend" /var/log/messages | wc -l
1394
```

Además de _spamear_ los logs, provoca un montón de escrituras innecesarias sobre la tarjeta microSD, lo que puede acortar la vida útil de la misma.

No tengo claro si este puede ser la causa que hace que las dos Raspberry Pi 3 se cuelguen pasado un tiempo y que dejen de responder, lo que hace que deba reiniciarlas (desconectando/conectando el cable) para recuperarlas. Sin embargo, en el nodo _master_ (Raspberry Pi 2 B+) no aparece el mensaje en los logs y no se cuelga (aunque la configuración de _rsyslog_ es la misma).

# Solución a los mensajes de rsyslog

El mensaje de error , es un problema de configuración de la aplicación `rsyslog`, que intenta mostrar mensajes en `/dev/xconsole`, pero falla.

La solución la explica Danny Tuppeny en su blog, en [Removing \[action 'action 17' suspended\] rsyslog Spam on Raspberry Pi (Raspian Jessie)](https://blog.dantup.com/2016/04/removing-rsyslog-spam-on-raspberry-pi-raspbian-jessie/). Él mismo abrió un _bug_ en RPI-Distro: [Default Raspbian Jessie Lite install spams syslog with "rsyslogd-2007: action 'action 17' suspended, next retry is #28](https://github.com/RPi-Distro/repo/issues/28) en él explicaba cómo había eliminado la línea que hace referencia a `/dev/xconsole` de la configuración de _rasyslog_ y que el mensaje desaparecía (después de reiniciar).

Para comprobar si esta es la causa del _cuelgue_ de la RPi 3, he modificado la configuración de _rsyslog_ en el nodo **k2** del clúster, pero no en el **k3**. De esta forma podré averiguar si la configuración de _rsyslog_ es la causante del _cuelgue_.

También he actualizado el sistema (en todos los nodos) y _kubelet_, _kubectl_ y _kubeadm_ se han actualizado a la versión 1.6.2:

```shell
...
Setting up libldap-2.4-2:armhf (2.4.40+dfsg-1+deb8u2) ...
Setting up libicu52:armhf (52.1-8+deb8u5) ...
Setting up kubelet (1.6.2-00) ...
Setting up kubectl (1.6.2-00) ...
Setting up kubeadm (1.6.2-00) ...
Processing triggers for libc-bin (2.19-18+deb8u7)
...
```

```shell
$ kubectl get nodes
NAME      STATUS    AGE       VERSION
k1        Ready     19d       v1.6.2
k2        Ready     14d       v1.6.2
k3        Ready     14d       v1.6.2
```

Ahora sólo queda esperar -normalmente unas cuantas horas- a ver qué pasa: hay tres posibilidades:

1. Se cuelga **k3** pero no **k2**: La configuración de _rsyslog_ era la causa.
1. Se cuelga **k2** pero no **k3**: ¿?
1. No se cuelga ni **k2** ni **k3**: Era un problema de alguno de los componetes actualizados que sólo afecta a la RPi 3.

Informaré en cuanto tenga resultados.

# Unas horas después...

Ya tenngo resultados: la configuración de _rsyslog_ es la que causa el cuelgue del sistema en las RPi3.

Échale un vistazo a cómo solucionar este error en la entrada: [El nodo k3 del clúster colgado de nuevo]({{% ref "170430-k3-colgado-de-nuevo.md" %}})


