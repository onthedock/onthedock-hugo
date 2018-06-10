+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev","ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "vagrant", "kubernetes", "weave.net"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/kubernetes.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" %}}

title=  "Pods encallados en estado CreatingContainer en Kubernetes con nodos creados usando Vagrant"
date = "2018-06-10T20:54:27+02:00"
+++

Una de las maneras más sencillas de crear un entorno de desarrollo para Kubernetes es usando Vagrant y Ansible.

En el `Vagrantfile` definimos un conjunto de tres máquinas, llamadas `node1`, `node2` y `node3`.

Una vez las máquinas están levantadas, desde el servidor de Ansible uso `ssh-copy-id` para habilitar el _login_ sin password de Ansible en los nodos del clúster.

A partir de aquí, tanto la instalación de los prerequisitos como la inicialización del clúster funcionan sin problemas; sin embargo, al intentar desplegar una aplicación, los _pods_ se quedan en el estado _CreatingContainer_.

<!--more-->

# Análisis de logs

Analizando los logs el problema apuntaba a un problema de red con Weave.net. Al parecer, cada _pod_ de Weave Net obtiene una lista de los nodos que componen el clúster e intenta conectar con los _pods_ que corren en cada nodo. Esto implica que también intenta conectar consigo mismo, lo que genera un error.

```shell
[...] connection shutting down due to error: Cannot connect to ourself
```

Sin embargo, este error es "normal" (hay alguna [_queja_](https://github.com/weaveworks/weave/issues/1305) en internet).

Aunque el error al intentar conectar consigo mismo es inocuo, otro error debido a colisión de nombres no lo es:

```shell
[...] connection shutting down due to error: local and remote peer names collision
```

Junto al mensaje de error aparecen las _MAC address_ de las interfaces de red generadas por Weave, que coincidían en los tres nodos del clúster.

Finalmente he encontrado la explicación y la solución en [Quorum not being reached on machines with identical IDs](https://github.com/weaveworks/weave/issues/2767)

## Causa

{{% img src="images/vagrant.png" w="198" h="194" class="right" %}}

Las tres máquinas se han generado a partir de la misma imagen de Vagrant, por lo que el **identificador de máquina** en los ficheros `/etc/machine-id` y `/var/lib/dbus/machine-id` eran el mismo en los tres nodos.

De alguna manera, la _MAC_ de la interfaz virtual `weave` se genera a partir del _machine-id_ (que debería ser único). Pero en este caso, al ser el mismo en las tres máquinas virtuales, la _MAC_ del interfaz `weave` también coincidía en los _pods_ generados por Weave Net. Por este motivo se obtenía el error de colisión de nombres.

```shell
$ ip address show
...
6: weave: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1376 qdisc noqueue state UP group default qlen 1000
    link/ether 76:2f:d2:46:f8:94 brd ff:ff:ff:ff:ff:ff
    inet 10.44.0.1/12 brd 10.47.255.255 scope global weave
       valid_lft forever preferred_lft forever
...
```

## Solución

La solución es elimnar el _machine-id_ y generar uno nuevo:

```shell
sudo rm /etc/machine-id
sudo rm /var/lib/dbus/machine-id
sudo systemd-machine-id-setup
```

Tras reiniciar los nodos del clúster, el _pod_ de prueba del clúster se ha iniciado con normalidad.