+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev", "ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "shell", "bash", "pubsub", "nats"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/bash.svg"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/
# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}

title=  "PubSub con NATS y Bash (II)"
date = "2025-02-09T17:18:18+01:00"
+++
He estado pensando en algunas mejoras con respecto al uso de NATS para montar un sistema de pipelines basado en las ideas de la entrada anterior [PubSub con NATS y Bash]({{< ref "250208-pubsub-con-nats-y-bash.md" >}}).
<!--more-->
## Filtrado de los mensajes - un nuevo enfoque

En al entrada anterior, el filtrado de los mensajes lo realizaba en el script que "hace cosas".
Sin embargo, creo que el lugar adecuado en el que realizar el filtrado es en el *subscriber*, es decir, cuando se recibe el mensaje.
De esta forma, el *subscriber* recibe el mensaje y, antes de lanzar el script que "hace cosas", revisa si es necesario lanzar el script y sólo si el *script* está "interesado" en el tipo de mensaje recibido, se lanza.

Esto emula mejor lo que sucede en Google Cloud con los *triggers*, que únicamente disparan el *build* en Cloud Build si el mensaje verifica el filtro definido en el trigger.

Siguiendo con el ejemplo del sistema que envía mensajes con el resultado del lanzamiento de una moneda, el *subscriber* revisaría el contenido del mensaje y sólo lanza el *processor* si el resultado en el mensaje indica "cara":

```console
#!/bin/bash

while true ; do
    sleep 0.1
    msg=$(nats sub coinflip --raw --count=1)
    if [[ "$(echo $msg | jq -r '.result')" == "cara" ]]; then
        echo "processing '$msg'..."
        ./processor.sh "$msg" &
    fi
done
```

De esta forma, el script *processor.sh* sólo se ejecuta si se dan las condiciones especificadas en el filtro del *subscriber*, simplificando el script.

## Parametrización

Con el formato definido, el *subscriber* (aka, *tigger*), siempre hace lo mismo:

- se suscribe a un *topic*
- *inspecciona* cada mensaje que llega y valida si se verifica el filtro definido
- si el mensaje valida el filtro, se *dispara* el script que "hace cosas" (aka, *processor*)
- si no, el mensaje se ignora

Lo que cambia de una instancia a otra de un *subscriber* es:

- el nombre del *topic* al que se suscribe
- el filtro con el que evalúa cada mensaje recibido
- el script que se lanza si el mensaje verifica el filtro
- (opcionalmente) el periodo de *sleep* de cada ciclo del bucle

Usamos `getopts` para probar el concepto (aunque existen [alternativas mucho mejores](https://github.com/onthedock/argparse-sh/) ;) )

```console
#!/usr/bin/env bash

while getopts ":t:k:v:s:" option; do
    case "${option}" in
        t) topic=${OPTARG} ;;
        k) filter_key=${OPTARG} ;;
        v) filter_value=${OPTARG} ;;
        s) script=${OPTARG} ;;
        *) echo "unknown option ${OPTARG}" 
           exit 0
        ;;
    esac
done
shift $((OPTIND-1))

while true ; do
    sleep 0.1
    msg=$(nats sub $topic --raw --count=1)
    if [[ $(echo $msg | jq -r --arg key $filter_key '.[$key]') == "$filter_value" ]]; then
        $script "$msg" &
    fi
done
```

Verificamos que todo funciona como esperamos:

```console
$ bash trigger.sh -t coinflip -k result -v cara -s ./flip_logger.sh
Ha salido 'Cara'
Ha salido 'Cara'
...
```

## Conclusión

Usando NATS y un poco de Bash, podemos montar la base de un sistema distribuido que lance scripts en función de una de las propiedades de los mensajes recibidos vía NATS.

Aunque la prueba de concepto es muy sencilla, permite lanzar scripts en paralelo, sin bloquear la recepción de nuevos mensajes por parte del *subscriber*.

Para la prueba de concepto he supuesto que los mensajes están en formato JSON y que tenemos Jq instalado en el sistema. No es una hipótesis descabellada, IMO.
