+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "kubernetes", "vagrant", "k3s", "k3sup"]

# Optional, referenced at `$HUGO_ROOT/static/images/kubernetes.png`
thumbnail = "images/kubernetes.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}

title=  "Provisionar Kubernetes con Vagrant y K3sup - 1a parte"
date = "2021-09-19T10:31:17+02:00"
+++
Desde mis inicios con Kubernetes, una de las cosas más pesadas del proceso de creación del clúster (para mí) ha sido el tener que desplegar y configurar las máquinas que formarán el clúster.

En esta entrada explico algo de mi relación histórica con Vagrant y el proceso de automatización que estoy siguiendo para desplegar clústers locales (*no cloud*) en mi laboratorio.

<!--more-->

## Un poco de historia: Vagrant y los `machine-id`

Trabajando con máquinas virtuales, parece que debería ser sencillo clonar una máquina existente y ¡listo! O la manera, todavía más sencilla: usando Vagrant. Sin embargo, cuando lo intenté hace unos años, encontré un problema relacionado con que las máquinas genereadas no disponían de un `machine-id` único, como comenté en [Pods encallados en estado CreatingContainer en Kubernetes con nodos creados usando Vagrant]({{< ref "180610-pods-en-estado-creatingcontainer-en-k8s.md" >}}). Esto hacía que los *pods* no arrancasen porque las tarjetas de red no tenían una *MAC address* única.

Afortunadamente, he vuelto a usar Vagrant para generar las máquinas del clúster y el problema no ya no se da; quizás Vagrant lo ha corregido, quizás era un problema de Weave... Sea como sea, desde hace un tiempo Vagrant ha vuelto a ganarse mi confianza.

## Vagrant: una revisión (superficial) de las principales características

*Grosso modo*, [Vagrant](https://www.vagrantup.com/docs) automatiza el proceso de provisionar máquinas virtuales a partir de un fichero de configuración llamado `Vagrantfile`, de manera *similar* a lo que hace Docker con el `Dockerfile`.

Para provisionar un clúster de Kubernetes, necesitamos una o más máquinas virtuales, que actuarán como *nodos* del clúster.

Vagrant puede generar máquinas virtuales con diferentes hipervisores, pero el más habitual es VirtualBox. Las máquinas virtuales se generan a partir de imágenes disponibles en [Vagrant Cloud](https://app.vagrantup.com/boxes/search). Siguiendo con la analogía entre Vagrant y Docker, *Vagrant Cloud* sería el equivalente de DockerHub.

El fichero `Vagrantfile` puede contener variables, bucles, etc (en Ruby) tanto para configurar las propiedades de la  máquina virtual (en el hipervisor) como conectarse al sistema operativo de la máquina virtual y ejecutar *scripts* de configuración (al estilo de Ansible).

Esto proporciona toda la potencia y flexibilidad que necesitemos para provisionar y configurar cualquier número de máquinas con Vagrant.

## El fichero `Vagrantfile`

> Todos los ficheros se encuentran disponibles en el repositorio público [onthedock/vagrant](https://github.com/onthedock/vagrant) en GitHub, en la carpeta `k3s-ubuntu-cluster`.  
> Voy refinando poco a poco tanto el fichero como los *scripts*; por favor, si encuentras algún problema no dudes en abrir un *[issue](https://github.com/onthedock/vagrant/issues)* o una *pull request*.

Podemos generar clústers de Kubernetes con 1 nodo (clúster mono-nodo), 1+n (un *server* y `n` nodos *agent*), 3+n nodos, etc. Dado que el objetivo de Vagrant es únicamente el de provisionar máquinas virtuales, uso un bucle para generar tantas máquinas como nodos tendrá el clúster (independientemente del rol de cada nodo).

Para ello, defino la variable `NodeCount` y aplico la misma configuración a todas las máquinas, usando un bucle en el `Vagrantfile`:

```ruby
Vagrant.configure("2") do |config|
  NodeCount = 3
  
  (1..NodeCount).each do |i|
    
    # CONFIGURACION DE LAS MAQUINAS VIRTUALES

  end
end
```

### Configuración básica de las máquinas virtuales

Defino un bucle para cada nodo; aquí especifico especifico la *box* escogida (la imagen base para la máquina virtual) que uso; en mi caso, `ubuntu/focal64` así como la versión de la *box* seleccionada.

```ruby
Vagrant.configure("2") do |config|
  NodeCount = 3
  
  (1..NodeCount).each do |i|
    config.vm.define "k3s-#{i}" do |node|
      node.vm.box               = "ubuntu/focal64"
      node.vm.box_version       = "20210803.0.0"
...
```

Para tener un entorno controlado, deshabilito la actualización automática de la *box* usada mediante: `node.vm.box_check_update  = false`.

También deshabilito la carpeta compartida entre el *host* y las máquinas virtuales: `node.vm.synced_folder ".", "/vagrant", disabled: true`.

### Recursos de las máquinas

Creo un bucle adicional para configurar algunas propiedades de las máquinas virtuales en VirtualBox, como los recursos asignados y el nombre con el que se muestra en la interfaz gráfica:

```ruby
  (1..NodeCount).each do |i|
    config.vm.define "k3s-#{i}" do |node|
    ...
      node.vm.provider :virtualbox do |v|
        v.name    = "k3s-#{i}"
        v.memory  = 2048
        v.cpus    = 1
    ...
```

### Configuraciones adicionales (que probablemente eliminaré en el futuro)

Inicialmente instalé el *plugin* [vagrant-vbguest](https://github.com/dotless-de/vagrant-vbguest/blob/main/Readme.md) para instalar automáticamente las *VirtualBox Guest Additions* en la máquinas virtuales creadas. Para evitar la actualización de la instalación de las *guest additions* (o su instalación) en las máquinas virtuales para Kubernetes: `node.vbguest.auto_update = false`.

También configuro el *hostname* para las máquinas virtuales (`node.vm.hostname = "k3s-#{i}.192.168.1.10#{i}.nip.io"'`), aunque después realizo la instalación de Kubernetes proporcionando las direcciones IPs de los nodos, no sus nombres públicos.

### Configuración de la red

La última configuración en la máquina virtual es conectar la máquina virtual a una red pública, en el sentido de *VirtualBox*, usando una tarjeta de red adicional en modo *bridge*.

Por defecto, Vagrant configura la interfaz de red por defecto en la máquina virtual como NAT. Durante la configuración de *k3sup*, los *agents* necesitan contactar con la IP del nodo *server*.

No es posible configurar la tarjeta de red por defecto en otro modo que no sea NAT, de manera que la solución es configurar un dispositivo adicional y conectarlo a una red de tipo público (en VirtualBox).

```ruby
node.vm.network "public_network", ip: "192.168.1.10#{i}", bridge: 'wlp3s0'
```

Como puede observarse en la línea anterior, la tarjeta de red que se usa como *bridge* está *hardcodeada* en la configuración de la máquina virtual. Para solucionarlo, está abierto el [issue #1](https://github.com/onthedock/vagrant/issues/1).

Con las configuraciones realizadas, el `Vagrantfile` define la configuración para provisionar `NodeCount` máquinas virtuales.

```ruby
Vagrant.configure("2") do |config|
  NodeCount = 3
  
  (1..NodeCount).each do |i|
    config.vm.define "k3s-#{i}" do |node|
      node.vm.box               = "ubuntu/focal64"
      node.vm.box_version       = "20210803.0.0"
      node.vm.box_check_update  = false
      node.vm.synced_folder ".", "/vagrant", disabled: true

      node.vm.hostname = "k3s-#{i}.192.168.1.#{100+i}.nip.io"

      node.vm.network "public_network", ip: "192.168.1.#{100+i}", bridge: 'wlp3s0'

      # Configure provider VirtualBox
      node.vm.provider :virtualbox do |v|
        v.name    = "k3s-#{i}"
        v.memory  = 2048
        v.cpus    = 1
      end
      
      # Plugin vagrant-vbguest
      node.vbguest.auto_update   = false

    end
  end
end
```

Hasta ahora, el fichero `Vagrantfile` provisiona y configura las máquinas virtuales, pero no realiza ninguna configuración en el sistema resultante.

En la siguiente parte, comento la ejecución de *scripts* para realizar una configuración básica de los sistemas instalados.
