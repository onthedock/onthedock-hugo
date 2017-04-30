+++
date = "2017-04-30T11:39:20+02:00"
title = "El nodo k3 del clúster colgado de nuevo"
tags = ["debian", "raspberry pi"]
draft = false
thumbnail = "images/raspberry_pi.png"
categories = ["ops"]

+++

En la entrada anterior [Múltiples mensajes 'action 17 suspended' en los logs]({{% ref "170430-multiples-mensajes-action-17-suspended.md" %}}) comentaba que estaba a la espera de obtener resultados; después de apenas unas horas, ya los tengo: **k3** se ha vuelto a _colgar_ mientras que **k2** no.

Este resultado parece demostrar que la mala configuración de _rsyslog_ es la causante de los _cuelgues_ de las RPi 3 en el clúster de Kubernetes.

<!--more-->

A modo de recordatorio, los cambios realizados en los dos nodos sobre Raspberry Pi 3 han sido (incluyo el nodo **k1** con RPi2):

```
                                |  k1  |  k2  |  k3  |
                                | RPi2 | RPi3 | RPi3 |
 -------------------------------|------|------|------|
| Modificada conf. de rsyslog   |  No  |  Sí  |  No  |
| Actualización a versión 1.6.2 |  Sí  |  Sí  |  Sí  |
 ----------------------------------------------------
```

Hasta ahora, los únicos nodos que se _colgaban_ eran el **k2** y el **k3** (sobre RPi3).

Al modificar la configuración en de _rsyslog_ en **k2** y pasadas unas horas, el único nodo que se sigue colgando es el **k3**. 

```shell
$ kubectl get nodes
NAME      STATUS     AGE       VERSION
k1        Ready      19d       v1.6.2
k2        Ready      14d       v1.6.2
k3        NotReady   14d       v1.6.2
```

 Es decir, el fallo a la hora de redirigir los mensajes a `/dev/xconsole`:

 * sólo afectan a las RPi3
 * provoca que el sistema se acabe colgando

 Para solucionarlo, como `root`:

 1. Abre `/etc/rsyslog.conf`
 1. Modifica las últimas líneas (al final del fichero) y coméntalas: 

    ```txt
    # The named pipe /dev/xconsole is for the `xconsole' utility.  To use it,
# you must invoke `xconsole' with the `-file' option:
#
#    $ xconsole -file /dev/xconsole [...]
#
# NOTE: adjust the list below, or you'll go crazy if you have a reasonably
#      busy site..
#
daemon.*;mail.*;\
        news.err;\
        *.=debug;*.=info;\
        *.=notice;*.=warn       |/dev/xconsole
    ```
   deben quedar como:
   ```txt
#daemon.*;mail.*;\
#        news.err;\
#        *.=debug;*.=info;\
#        *.=notice;*.=warn       |/dev/xconsole
   ```
   Podrías comentar la redirección `|/dev/xconsole`, pero en este caso el bloque no tendría ninguna funcionalidad, por lo que creo que es _más limpio_ comentar todo el bloque.
1. Reinicia el equipo mediante `reboot`.