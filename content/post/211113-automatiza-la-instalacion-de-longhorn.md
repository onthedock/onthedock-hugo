+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "kubernetes", "k3s", "longhorn", "storage"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/longhorn.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}

title=  "Automatiza la instalación de Longhorn"
date = "2021-11-13T19:53:33+01:00"
+++
[Longhorn](https://longhorn.io/) es una solución de almacenamiento distribuido de bloques para Kubernetes. Recientemente ha sido incluido en la [*incubadora* de la CNCF](https://www.cncf.io/blog/2021/11/04/longhorn-brings-cloud-native-distributed-storage-to-the-cncf-incubator/).

Longhorn proporciona métricas para Prometheus y es el complemento perfecto para proporcionar almacenamiento a las aplicaciones desplegadas sobre Kubernetes.

En esta entrada automatizamos las [instrucciones oficiales](https://longhorn.io/docs/1.2.2/deploy/install/install-with-helm/) de despliegue usando Helm para desplegarlo sobre Kubernetes.
<!--more-->

> La última versión del *script* se puede encontrar en el repositorio de GitHub [vagrant/k3s-ubuntu-cluster/](https://github.com/onthedock/vagrant/blob/main/k3s-ubuntu-cluster/deploy-longhorn-using-helm.sh)

## TL;DR;

El *script* es:

```bash
#!/usr/bin/env bash

function getKubeconfig {
    scriptDir="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    if test -f "kubeconfig"
    then
        echo "Using $scriptDir/kubeconfig"
        export KUBECONFIG=$scriptDir/kubeconfig
    elif test -f $HOME/.kube/config
    then
        echo "Using default kubeconfig at $HOME/.kube/config"
    elif [[ -z "$KUBECONFIG" ]]
    then
        echo "ERROR - Unable to find a valid kubeconfig"
        exit 1
    else
        echo "Using \$KUBECONFIG=$KUBECONFIG"
    fi
}


function installHelmChart {
    helmChart="$1"
    helmRepoChart="$2"
    chartNamespace="$3"

    checkRelease=$(helm status $helmChart --namespace $chartNamespace 2>/dev/null| grep -i status | awk '{ print $2 }')

    if [ "$checkRelease" != "deployed" ]
    then
        echo "...Installing longhorn"
        helm install $helmChart $helmRepoChart --namespace $chartNamespace --create-namespace
    else
        echo "... $helmChart is already installed in the namespace $chartNamespace"
    fi
}

function setDefaultStorageClass {
    defaultStorageClass="$1"
    storageClassList=$(kubectl get storageclass -o name | awk -F '/' '{print $2}')

    for storageclass in $storageClassList
    do
        if [ "$storageclass" = "$defaultStorageClass" ]
        then
            echo "Set default storageClass for $storageclass"
            kubectl patch storageclass $storageclass -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
        else
            echo "Removing default storageClass for $storageclass"
            kubectl patch storageclass $storageclass -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
        fi
    done
}

function main {
    getKubeconfig

    # Those commands are idempotent
    helm repo add longhorn https://charts.longhorn.io
    helm repo update
    
    installHelmChart "longhorn" "longhorn/longhorn" "longhorn-system"
    setDefaultStorageClass "longhorn"
}

main
```

## Algo de contexto

El *script* de instalación de Longhorn forma parte del proceso de automatización del despliegue y configuración de un clúster de Kubernetes usando Vagrant para demos/laboratorios/pruebas.

El proceso empieza desplegando varias máquinas virtuales mediante Vagrant; a continuación se instala Kubernetes (k3s) usando k3sup.

k3sup puede generar un fichero de configuración `kubeconfig` específico para el clúster desplegado o fusionar la configuración con un fichero `kubeconfig` existente.

El *script* consta de tres funciones (bueno, en realidad 4, pero la última es `main` que podría omitirse):

## `getKubeconfig`

En mi caso, al tratarse en general de clústers temporales, uso el fichero `kubeconfig` creado por k3sup mediante la variable `$KUBECONFIG`.

Mediante la función `getKubeconfig` el *script* trata de localizar un fichero `kubeconfig` que Helm pueda usar para conectar con el clúster.

Primero, busca en la carpeta en la que se encuentra el *script*. De nuevo, esto es porque el *script* y k3sup se encuentran en la misma carpeta.

Si no se encuentra el fichero *local* `kubeconfig`, se intenta usar el fichero `kubeconfig` de la carpeta `$HOME` del usuario; el *script* usa el **contexto actual** (`current context`) definido en el fichero.

Finalmente, se examina la variable de entorno `$KUBECONFIG` y si no esta definida, salimos del *script* (no podremos conectar al clúster con Helm).

## `isHelmAppInstalled`

Si se intenta instalar una *chart* que ya ha sido deplegada, Helm genera un error.

Para evitarlo, primero comprobamos si Longhorn está desplegado en el clúster analizando la salida del comando `helm status`:

```bash
helm status -n longhorn-system longhorn
NAME: longhorn
LAST DEPLOYED: Sat Nov 13 19:33:28 2021
NAMESPACE: longhorn-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Longhorn is now installed on the cluster!

Please wait a few minutes for other Longhorn components such as CSI deployments, Engine Images, and Instance Managers to be initialized.

Visit our documentation at https://longhorn.io/docs/
```

Filtrando el resultado del comando, buscamos el valor del campo `STATUS` para verificar si la *chart* está instalada o no.

## `setDefaultStorageClass`

Aunque la instalación de Longhorn establece la *storageClass* `longhorn` como *storageClass* por defecto en el clúster, **no se modifican las anotaciones de otras *storageClass*** presentes.

Esto puede provocar problemas, como indica la [documentación oficial de Kubernetes](https://kubernetes.io/docs/tasks/administer-cluster/change-default-storage-class/#changing-the-default-storageclass):

> If two or more of them are marked as default, a `PersistentVolumeClaim` without `storageClassName` explicitly specified cannot be created.

El resultado de la instalación de Longhorn es que varias *storageClass* pueden estar marcadas como *storageClass* por defecto del clúster. Abrí el *issue* [Múltiples storageClass por defecto al instalar Longhorn](https://github.com/onthedock/vagrant/issues/12) (que ya está cerrado):

```bash
$ kubectl get storageclass
NAME                   PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
local-path (default)   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  48d
longhorn (default)     driver.longhorn.io      Delete          Immediate              true                   72m
```

La solución es obtener la lista de *storageClass* definidas en el clúster, marcar sólo una como *storageClass* por defecto (en nuestro caso, `longhorn`) y para el resto, marcar como `false` la anotación `is-default-class`.

## Resumen

El *script* obtiene la configuración del fichero `kubeconfig` (o de la variable de entorno `$KUBECONFIG`) para que Helm pueda conectar con el clúster y desplegar Longhorn.

Añadimos el repositorio de la *chart* de Longhorn, actualizamos y finalmente nos aseguramos que sólo hay una *storageClass* por defecto en el clúster.

Así podemos automatizar la instalación de Longhorn en los clústers de Kubernetes.
