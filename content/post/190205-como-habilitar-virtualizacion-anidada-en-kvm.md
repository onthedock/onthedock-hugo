+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "ubuntu", "kvm"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/linux.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" %}}

title=  "Cómo habilitar virtualizacion anidada en KVM"
date = "2019-02-05T22:14:15+01:00"
+++

La virtualización anidada permite ejecutar una máquina virtual _dentro_ de otra máquina virtual aprovechando las posibilidades de aceleración por hardware que proporciona el sistema anfitrión.

<!--more-->

Hyper-V no permite la virtualización anidada para equipos con procesadores AMD, como se indica en [Ejecución de Hyper-V en una máquina virtual con la virtualización anidada](https://docs.microsoft.com/es-es/virtualization/hyper-v-on-windows/user-guide/nested-virtualization):

> (Requisitos previos) Un procesador Intel con tecnología VT-x y EPT: el anidamiento es actualmente **solo para Intel**.

Una vez [instalado KVM]({{< ref "190124-kvm-en-ubuntu-server.md">}}) en el equipo, el primer paso es comprobar si esta característica está soportada. Para ello seguimos las instrucciones de la sección [Checking if nested virtualization is supported](https://docs.fedoraproject.org/en-US/quick-docs/using-nested-virtualization-in-kvm/):

```bash
$ cat /sys/module/kvm_amd/parameters/nested
1
```

Si el fichero muestra `1` o `yes`, el equipo soporta virtualización anidada.

> Podemos realizar la misma comprobación para equipos con procesador Intel mostrando el contenido del fichero `/sys/module/kvm_intel/parameters/nested`.

## Habilitar la virtualización anidada

> Todas las máquinas virtuales deben estar paradas para realizar este cambio.

1. Descargamos el módulo `kvm_probe`
   ```bash
   modprobe -r kvm_amd
   ```

1. Activamos la virtualización anidada:
   ```bash
   modprobe kvm_amd nested=1
   ```

Estas modificaciones habilitan la _nested virtualization_ hasta que el sistema se reinicia. Para que la virtualización anidada esté disponible de forma permanente, editamos el fichero de configuración de KVM `/etc/modprobe.d/kvm.conf`:

```bash
options kvm_amd nested=1
```

## Configurar virtualización anidada en Virt-Manager

Para habilitar _nested virtualization_ en una máquina virtual, en Virt-Manager:

1. Abre las propiedades de la máquina virtual en Virtual Machine Manager
1. Selecciona _Show virtual hardware details_
1. Haz _click_ en el menú lateral.
1. En la sección _Configuration_ tenemos dos opciones:
   1. Escribe `host-passthrough` en el campo _Model_
   1. Selecciona el checkbox _Copy host CPU configuration_ (esto rellena `host-model` en el campo _Model_)
1. Finalmente, pulsa _Apply_ para aplicar los cambios.

> Usar la opción `host-passthrough` **no se recomienda** de forma general y sólo debe habilitarse cuando se use virtualización anidada.

Referencia: [How to enable nested virtualization in KVM](https://docs.fedoraproject.org/en-US/quick-docs/using-nested-virtualization-in-kvm/) en fedora DOCS.
