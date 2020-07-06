+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev","ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "kvm", "cloud-init"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/cloud-init.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" %}}

title=  "Lanzar instancias en KVM y configurarlas con Cloudinit"
date = "2020-07-06T20:27:27+02:00"
+++
En la [entrada anterior]({{< ref "200627-creacion-de-vm-en-kvm-con-virsh.md" >}}) describía los pasos para lanzar una instancia en KVM usando `virsh`. Pero aunque esto resuelve la creación de la máquina virtual, todavía tenemos que realizar la configuración manual del sistema operativo, establecer el `hostname`, crear usuarios, instalar de paquetes, etc.

Usando [`cloud-init`](https://cloudinit.readthedocs.io) podemos automatizar el proceso de configuración tal y como lo hacen los proveedores de cloud público (AWS, Azure, Google Cloud...)
<!--more-->

La clave de *cloud-init* reside en pasar infomación de configuración a la instancia para que los scripts puedan realizar la configuración durante el arranque de la máquina virtual. En [AWS](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html), por ejemplo, esta información se obtiene desde la IP 169.254.169.254; a través de la red.

Sin embargo, la manera más sencilla -si no estás en el cloud- de *pasar* los datos de configuración a la instancia -para el *data source* [`NoCloud`](https://cloudinit.readthedocs.io/en/latest/topics/datasources/nocloud.html)- es mediante una imagen de CD pinchada en la VM.

Hace un par de años ya escribí sobre ello, aunque entonces usaba Windows y Hyper-V: [Automatizando la personalización de máquinas virtuales con cloud-init]({{< ref "181009-cloud-init.md" >}}).

Esta vez intento avanzar respecto a la situación anterior, uniendo en un mismo *script* todo el proceso:

- Generar el fichero el fichero de configuración de `cloud-init`
- Generar la imagen ISO con la configuración
- Generar una VM en KVM (partiendo de una imagen "cloud") y la imagen con los datos de cloud-init
- Disfrutar mientras todo se configura automáticamente (y siempre de la misma forma)

> El script está colgado en [vm-kvm-ubuntu.sh](https://github.com/onthedock/script-kvm-cloudinit/blob/master/vm-kvm-ubuntu.sh) y está probado en Ubuntu 20.04.

## Enfoque incremental

He decidido generar el fichero de configuración de `cloud-init` en el mismo *script* para no tener dos ficheros separados para cada tipo de instancia; probablemente no es la mejor solución, pero no espero tener demasiados tipos diferentes de instancias -y por tanto de ficheros de configuración-; si tengo que cambiar alguna cosa común a todos los casos, tendré que modificar varios ficheros.

`cloud-init` permite realizar prácticamente cualquier configuración que necesites sobre el sistema en la máquina virtual; de todas formas, creo que es mejor empezar poco a poco e incorporar sólo nuevas configuraciones cuando las necesite, no simplemente por el hecho de que se pueden realizar.

En esta línea, primero he creado el script para desplegar una imagen con Ubuntu Server 20.04 LTS, sin ninguna configuración adicional (excepto la capacidad de hacer login usando un *password*).

Una vez he conseguido que funcione, he copiado el *script* y lo he "ampliado" para desplegar Docker CE. Finalmente, ampliaré de nuevo el *script* para poder desplegar máquinas con los requisitos de Kubernetes y poder desplegar clústers de manera ágil.

## Fichero `cloud-config`

El fichero de configuración de `cloud-init` genera un nuevo usuario por defecto llamado `operador` (en vez del usuario "ubuntu" que viene predefinido en la imagen). El *password* se solicita al ejecutar el *script*, por lo que es seguro guardar el *script* en GitHub o en cualquier otro repositorio.

Habilito el acceso vía *password* porque en el laboratorio tiendo a recrear las claves SSH frecuentemente.

La línea `shell: /bin/bash` es necesaria porque se establece `/bin/sh` como *shell* para el nuevo usuario; eso significa que no funciona el autocompletado, los cursores escupen caracteres extraños, no funciona el historial de comandos ejecutados, etc... Me he vuelto loco hasta que he encontrado la solución en StackOverflow (aunque me temo que no he guardado el enlace).

Estableciendo `bash` como *shell* por defecto para el usuario `operador`, todo funciona como estoy acostumbrado.

Para acabar, habilito la autenticación con credenciales vía SSH e instalo el agente de QEmu.

El fichero de configuración se guarda en `/tmp/$VM_NAME-cloudinit.config`.

## Prepara la imagen para KVM

Las imagenes *cloud* que comentaba en la entrada anterior las tengo guardadas localmente en una carpeta llamada `ISOS/cloud-imgs`.

El primer paso es realizar una copia de la imagen cloud. Modificaremos la copia, de manera que siempre tengamos la imagen original inalterada.

El tamaño del disco virtual de las imágenes cloud es muy pequeño, por lo que para evitar problemas más adelante, expandimos el tamaño hasta los 10G.

## Crear la imagen con los ficheros de `cloud-init`

En vez de tener que generar la imagen ISO *a pelo*, ahora tenemos el paquete `cloud-image-utils` que simplifica el proceso.

El *script* valida que el paquete está instalado antes de crear la imagen `"$POOL_FOLDER/$VM_NAME.cloudconfig.img"`.

Cuando tenemos todas las piezas, lanzamos la creación de la máquina virtual.

## Consideraciones

El comando `virt-install` finaliza en cuanto ha creado la máquina. Las siguientes instrucciones en el *script* se ejecutan inmediatamente y eso provoca *resultados extraños*...

La extracción de la ISO del `cdrom` con la configuración de `cloud-init`, por ejemplo, resultaba en que la instancia nunca recibía una dirección IP, ni era posible acceder a la instancia porque no se establecía el password para el usuario `operador`...

El comando `virsh domifaddr $VM_NAME` tampoco devolvía información, ya que se ejecutaba antes de que la instancia pueda obtener una IP...

He comentado estas instrucciones porque no soy muy fan de los *sleep 60* y otros trucos que suelen usarse, ya que o bien se espera mucho más de lo necesario, o no se espera lo suficiente (es un poco lotería).

La solución pasará seguramente por usar algo como  `virsh qemu-agent-command` para revisar el estado del fichero `/var/lib/cloud/instance/boot-finished`, que `cloud-init` crea al finalizar todas las acciones de configuración.

Otra opción sería el fichero `/var/lib/cloud/data/result.json`, pero al intentar ejecutar un comando obtengo el error:

> Los comandos `guest-file-*` están deshabilitados por defecto en RHEL; además, el agente se ejecuta sujeto a las restricciones de SELinux. [Ref: qemu guest agent can not read/write existing file in guest](https://bugzilla.redhat.com/show_bug.cgi?id=1447943#c2)

### Problemas con el agente en las máquinas virtuales creadas

```bash
$ virsh qemu-agent-command --cmd '{ "execute": "guestinfo" }' --domain docker
error: Guest agent is not responding: QEMU guest agent is not connected
```

El problema está en que el agente está desconectado en la máquina virtual:

```bash
$ virsh dumpxml docker | grep -i agent
      <source mode='bind' path='/var/lib/libvirt/qemu/channel/target/domain-10-docker/org.qemu.guest_agent.0'/>
      <target type='virtio' name='org.qemu.guest_agent.0' state='disconnected'/>
```

Es decir, el agente está instalado en la VM pero no ha arrancado; iniciándolo manualmente se habilita la posibilidad de ejecutar comandos, por lo que una posible solución es arrancar el servicio tras la instalación vía `cloud-init`:

```yaml
...
runcmd:
  - systemctl enable qemu-guest-agent
  - systemctl start qemu-guest-agent
```

Así que tengo que modificar la configuracion de `cloud-init` para que además de instalar el agente de QEmu, también lo arranque.

### Comprobando la existencia de un fichero mediante `qemu-agent-command`

Siguiendo con el tema de usar `qemu-agent-command` para comprobar la existencia del fichero `/var/lib/cloud/instance/boot-finished`, se trata de un proceso de dos pasos: primero con `guest-file-open` se obtiene un *handle* al fichero y después, con este *handle*, se lee el contenido del fichero con `guest-file-read`.

En mi caso sólo quiero saber si el fichero existe, por lo que en cuanto el comando devuelve un *handle*, significa que existe y por tanto el proceso de arranque de `cloud-init` ha finalizado.

Así que una forma de comprobar si el proceso ha finalizado es mediante algo como:

```bash
virsh qemu-agent-command $VM_NAME --cmd '{"execute": "guest-file-open", "arguments": {"path":"/var/lib/cloud/instance/boot-finished"}}' 2>/dev/null
while [ $? -ne 0 ]; do
  sleep 1
  virsh qemu-agent-command $VM_NAME --cmd '{"execute": "guest-file-open", "arguments": {"path":"/var/lib/cloud/instance/boot-finished"}}' 2>/dev/null
done
echo "cloud-init configuration process finished.
```

Finalmente, el bucle ha quedado:

```bash
...
if [ $wait = "true" ]; then
  # Waiting until cloud-init finishes
  virsh qemu-agent-command $VM_NAME --cmd '{"execute": "guest-file-open", "arguments": {"path":"/var/lib/cloud/instance/boot-finished"}}' 1>/dev/null 2>/dev/null
  while [ $? -ne 0 ]; do
    sleep $time2wait
    echo "... waiting for cloud-init $time2wait more seconds ..."
    virsh qemu-agent-command $VM_NAME --cmd '{"execute": "guest-file-open", "arguments": {"path":"/var/lib/cloud/instance/boot-finished"}}' 1>/dev/null 2>/dev/null
  done
  echo "cloud-init configuration process finished."

  echo "Ejecting $POOL_FOLDER/$VM_NAME.cloudconfig.img from $VM_NAME ..."
  virsh change-media --path "$POOL_FOLDER/$VM_NAME.cloudconfig.img" $VM_NAME --eject

  virsh domifaddr $VM_NAME
fi
...
```

## Siguientes pasos

Por el momento estoy contento con el *script* y me ha servido para aprender un poco más de *bash*...

Al incorporar el parámetro `$wait` (y estableciéndolo en `"false"`, por ejemplo) puedo hacer que se lancen varias instancias seguidas y dejar el proceso de `cloud-init` se ejecute casi de forma simultánea en varias máquinas (sí, estoy pensando en un clúster de K8s... o K3s).

Imagino que los siguientes pasos irán en la dirección de convertirlo en un *script* más flexible, que permita pasar los parámetros desde la línea de comando, pero por ahora me permite levantar máquinas de manera rápida y desatendida.
