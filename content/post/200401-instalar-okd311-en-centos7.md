+++
draft = false

categories = ["ops"]
tags = ["linux", "centos7", "okd", "openshift", "origin"]
thumbnail = "images/okd.png"

title=  "Instalar OKD 3.11 en Centos 7 (Minimal)"
date = "2020-04-01T18:51:15+02:00"
+++
La instalación de [OKD](https://www.okd.io/), la distribución *opensource* de [OpenShift](https://www.openshift.com/) es compleja y tiene unos prerequisitos que, al menos en mi caso, me han echado un poco *pa'trás* a la hora de instalarlo.

Recientemente he encontrado una instalación basada completamente en contenedores que, aunque no es exactamente igual a la versión *estándard*, permite familiarizarse con el producto, el despliegue de aplicaciones, etc...

En esta entrada indico cómo instalar OKD 3.11 sobre Centos 7 (Minimal).
<!--more-->

La entrada se basa en las notas que fui recogiendo hace un par de días del proceso de instalación, por lo que no hay capturas de pantalla ni nada *fancy*, pero a mí me vale.

> Estas notas contienen nombres específicos -como el de la tarjeta de red o direcciones IP- que debes cambiar para adaptar a tu entorno.

## Prerequisitos

La instalación la he realizado sobre VirtualBox 6.1, en una máquina con 16Gb de RAM y 50Gb de disco.

Tras instalar las *VBoxGuestAdditions*, observo que el consumo inicial de RAM es de unos 300MB. Al lanzar el clúster, el uso empieza a subir, pero sin dispararse, quedando sobre unos 2GB de RAM al finalizar el proceso de arranque. Más tarde, el consumo de memoria ha ido aumentando y ahora ya está en 3.5Gb (y sigue aumentando), por lo que parece *overkill* asignar 16GB de RAM.

He asignado sólo 1 vCPU -lo que diría que es un error-, pero de momento funciona. Intentaré asignarle más vCPUs para ver si cambia alguna cosa.

## Instalación de Centos 7 (Minimal)

Realicé una instalación estándard a partir de Centos 7 (Minimal). La única configuración "especial" durante la instalación fue añadir el soporte para la distribución de teclado "ES".

> Todos los comandos se ejecutan como usuario `root`. Para convertirte en `root`, `sudo -i`, por ejemplo.

Tras la instalación, establezco la el *mapa de teclado* mediante (Referencia: [How to change system keyboard keymap layout on CentOS 7 Linux](https://linuxconfig.org/how-to-change-system-keyboard-keymap-layout-on-centos-7-linux)):

```bash
localectl set-keymap es
```

## Habilitar la tarjeta de red

En CentOS, la tarjeta de red está deshabilitada por defecto.

Para que *autoarranque* automáticamente al iniciar el sistema, hay que modificar el fichero (como `root`) `/etc/sysconfig/network-scripts/ifcfg-enp0s3/` y modificar la línea `ONBOOT=yes`.

Para habilitarla (la `c` es de *connection*),

```bash
nmcli c up enp0s3
```

## Instalación de Docker

Nos convertimos en el usuario `root` e instalamos Docker:

```bash
sudo -i
yum update
yum install docker -y
```

Docker está instalado pero no activo. Podemos validarlo con `systemctl status docker`
Para habilitarlo, (como *root*) `systemctl enable docker`. Antes de activarlo, vamos a configurar un registro privado.

### Configuración de un registro inseguro

> Este paso es necesario para poder usar el *registry* interno proporcionado por la instalación de OKD/OpenShift. Si no habilitamos el uso de registros inseguros, el comando `oc cluster up` **fallará**.

Como `root`, crea el fichero `/etc/docker/daemon.json`:

```bash
# cat << EOF >/etc/docker/daemon.json
{
 "insecure-registries": [
 "172.30.0.0/16"
 ]
}
EOF
```

Finalmente, arrancamos Docker: `systemctl start docker` (y lo validamos con `systemctl status docker`).

## Configuración del firewall

La configuración por defecto del firewall no permite el tráfico por los puertos requeridos por Openshift. Hay que ajustarlos mediante la herramienta `firewall-cmd`:

```bash
firewall-cmd --permanent --new-zone dockerc
firewall-cmd --permanent --zone dockerc --add-source 172.17.0.0/16
firewall-cmd --permanent --zone dockerc --add-port 8443/tcp
firewall-cmd --permanent --zone dockerc --add-port 53/udp
firewall-cmd --permanent --zone dockerc --add-port 8053/udp
firewall-cmd --reload
```

## Descargando la herramienta `oc`

El cliente de Openshift es una herramienta llamada `oc`, disponible en los repositorios. Se puede descargar de [https://github.com/openshift/origin/releases](https://github.com/openshift/origin/releases) (idealmente deberías usar los repositorios de CentOS).

```bash
yum -y install centos-release-openshift-origin311
yum -y install origin-clients
```

## Arrancando un clúster de OpenShift

Una vez tenemos todos los prerequisitos, podemos arrancar el clúster con `oc cluster up`. Este comando descarga todas las imágenes requeridas de repositorios públicos y arrancará los contenedores que haga falta (tardará un rato, en función de la velocidad de tu conexión de red).

Puedes especificar una versión concreta mediante `--version=3.9.0`, por ejemplo. Si la omites, descarga la última versión disponible (la 3.11)

> Para poder acceder a la consola desde un equipo *diferente* a la VM donde estás instalado OKD, pasa el parámetro `--public-hostname=<public ip>`. Sin embargo, esto no me ha funcionado y existe un *issue* abierto al respecto [Access fail with 'oc cluster up --public-hostname={public ip}' and redirect to 127.0.0.1 #20726](https://github.com/openshift/origin/issues/20726)

```bash
oc cluster up
```

Cuando finaliza la instalación, se muestra un mensaje que nos indica cómo acceder -vía línea de comandos- a OpenShift:

- **Como developer**: Ya estás logado como `developer` (cualquier valor es admitido como *password*). P.ej. `developer`.
- **Como administrador**: `oc login -u system:admin`. Puedes indicar cualquier password, por ejemplo `admin`.

> En realidad puedes acceder con cualquier usuario que te inventes, que asumirá el rol de *developer*. Prueba `oc login -u anthonymachine`.

## Conectar a la consola de OpenShift (desde otro equipo)

No he conseguido acceder a la consola de OKD desde un equipo diferente al de la VM.

Debería ser posible acceder a la consola web de OKD a través de [https://{vm-ip}:8443](https://{vm-ip}:8443) abriendo el firewall. Sin embargo, tras aceptar el *warning* del navegador (por usar un certificado autofirmado), se redirige a [https://localhost:8443/console](https://localhost:8443/console).

Como indicaba más adelante, hay un *issue* abierto en GitHub al respecto [Access fail with 'oc cluster up --public-hostname={public ip}' and redirect to 127.0.0.1 #20726](https://github.com/openshift/origin/issues/20726). El *issue* es del 2018 y se informó inicialmente para la versión 3.10, pero en la 3.11 también sucede.

Dado que, aunque todavía está soportada, RedHat ya está trabajando en la rama 4.x, es poco probable que lo solucionen.

La única manera que me ha funcionado para acceder a la consola es mediante un túnel SSH:

```bash
ssh -N -L 8443:127.0.0.1:8443 {username}@{vm-ip}
```

## Créditos

Para realizar la instalación seguí las instrucciones del artículo [Working with oc cluster up](https://medium.com/@fabiojose/working-with-oc-cluster-up-a052339ea219).
