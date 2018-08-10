+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "vagrant", "kubernetes"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/kubernetes.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" %}}

title=  "Generando un machine-id único"
date = "2018-08-10T18:10:27+02:00"
+++
En la entrada [Pods en estado creatingContainer en K8s]({{<ref "180610-pods-en-estado-creatingcontainer-en-k8s.md">}}) describía el problema surgido al crear un clúster de Kubernetes usando Vagrant. Al partir de la misma imagen, todas las máquinas del clúster tienen el mismo `machine-id`.

El `machine-id` debe ser único, como se describe en los [requerimientos de Kubernetes](https://kubernetes.io/docs/setup/independent/install-kubeadm/#verify-the-mac-address-and-product-uuid-are-unique-for-every-node); si no lo es, se producen problemas como el descrito.

En esta entrada analizo con más detalle cómo se crea el _machine-id_ y cómo generar uno nuevo.
<!--more-->
El fichero `/etc/machine-id` contiene un identificador único de la máquina que se establece durante la instalación o durante el arranque.

El _machine ID_ se suele generar de una fuente aleatoria durante la instalación del sistema operativo o durante el primer arranque y permanece constante durante los siguientes arranques. Este _machine ID_ no cambia al cambiar la configuración de red o cuando se modifica el _hardware_ del sistema.

Este identificador tiene el mismo formato y lógica que el _D-BUS machine ID_.

De hecho, si el fichero `/etc/machine-id` no existe, podemos usar [`systemd-machine-id-setup`](https://www.freedesktop.org/software/systemd/man/systemd-machine-id-setup.html) para generar uno nuevo. Sin embargo, hay que tener en cuenta que: 

> If a valid D-Bus machine ID is already configured for the system, the D-Bus machine ID is copied and used to initialize the machine ID in /etc/machine-id.

Es decir, que si el _D-Bus machine ID_ existe, no se genera un nuevo _machine ID_, sino que se reusa el _D-Bus machine ID_.

En la [documentación de Kubernetes](https://kubernetes.io/docs/setup/independent/install-kubeadm/#verify-the-mac-address-and-product-uuid-are-unique-for-every-node) se indica este identificador debe ser único; sin embargo, en [DMIDecode product_uuid and product_serial.what is the difference?](https://stackoverflow.com/questions/35883313/dmidecode-product-uuid-and-product-serial-what-is-the-difference) se indica que el `product_UUID` está relacionado con la BIOS de la máquina (por lo que no puede ser cambiado).

He comprobado que todas las máquinas virtuales generadas por Vagrant a partir de la misma imagen base comparten el mismo identificador en `/sys/class/dmi/id/product_uuid`.

Pese a coincidir el `product_uuid`, tanto el _machine ID_ como el _D-Bus machine ID_ pueden "regenerarse", de manera que sean únicos en cada máquina virtual:

```shell
sudo rm /etc/machine-id
sudo rm /var/lib/dbus/machine-id
sudo systemd-machine-id-setup
```

En la instalación de Kubernetes parece suficiente que el _machine-id_ sea único.

Referencias:

- [machine-id — Local machine ID configuration file en FreeDesktop.org](https://www.freedesktop.org/software/systemd/man/machine-id.html)
- [systemd-machine-id-setup — Initialize the machine ID in /etc/machine-id en FreeDesktop.org](https://www.freedesktop.org/software/systemd/man/systemd-machine-id-setup.html#)
- [On IDs](http://0pointer.de/blog/projects/ids.html)