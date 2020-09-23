+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "kubernetes", "k3os", "k3s"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/kubernetes.png"

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})


title=  "Configurar hostname en K3OS"
date = "2020-09-23T21:53:31+02:00"
+++
Una de las cosas que no me resultó evidente al empezar a usar [K3OS](https://k3os.io) es que el sistema de ficheros tiene algunas *particularidades* con las que es **absolutamente** necesario estar familiarizado; por ejemplo, que toda la carpeta `/etc` es **EFÍMERA**.
<!--more-->

Es decir, cosas como la configuración del *hostname* (en el fichero `/etc/hostname`), el fichero `/etc/hosts`, la configuración de la red (`/etc/network`) y un largo etcétera  **desaparecen** y se recrean en cada reinicio. En K3OS se considera que toda la configuración del sistema debe ser efímera.

En la sección *Files System Structure* dentro del [Quick Start](https://github.com/rancher/k3os#quick-start) de la documentación oficial así se indica, aunque nunca le había prestado la atención adecuada :(.

Si se quieren realizar cambios persistentes en la configuración de K3OS, deben realizarse a través del fichero `config.yaml`, en la línea de [*cloud-init*](/tags/cloud-init/).

En la sección de [Configuration](https://github.com/rancher/k3os#configuration) se indica que este fichero se encuentra en tres ubicaciones diferentes:

- `/k3os/system/config.yaml` Reservado para la instalación del sistema y que no debe ser modificado en un sistema en marcha (se crea durante el proceso de instalación)
- `/var/lib/rancher/k3os/config.yaml` o `/var/lib/rancher/k3os/config.d/*` que son los ficheros de configuración que pueden manipularse manualmente/a través de *scripting*/mediante un operador en un sistema en ejecución.

Sin embargo, en la versión 0.10.3, en `/var/lib/rancher/k3os/` no se encuentra el fichero `config.yaml`; hay un fichero `hostname` y dos carpetas, `node/` y `ssh/`. En el blog [CentLinux](https://www.centlinux.com/2019/05/configure-network-on-k3os-machine.html#point5) también se hace referencia a este fichero y no a `config.yaml`, por ejemplo.

Para fijar el "nombre" del sistema, es necesario modificar este fichero `hostname` (equivalente al `/etc/hostname`).

El hecho de que `/etc` se recreara cada reinicio hacía que la consola de Rancher con la que gestiono este *clúster* mono-nodo de Kubernetes cambiara de nombre y apareciera como *unavailable* al arrancar el nodo de K3OS; en la máquina con K3OS todos los *pods* aparecían como *Not Ready* y se recreaban de nuevo... En algún momento, el pod del agente de Rancher volvía a estar *Ready*, se comunicaba con la consola de Rancher y el clúster volvía a ser "administrable".

En clústers de K3OS multinodo, la situación era similar al arrancar el clúster: al ejecutar `kubectl get nodes` aparecen el doble de nodos, la mitad en *Not Ready* (los nodos correspondientes al nombre del clúster antes de reiniciar) y los *nuevos* nodos, con el nombre generado tras el último arranque.

Tratándose de un clúster "de laboratorio" no pasa nada pero en un equipo en producción que deba reiniciarse por mantenimiento o por un fallo del nodo, puede tener consecuencias impredecibles debido al cambio de nombre de los nodos.
