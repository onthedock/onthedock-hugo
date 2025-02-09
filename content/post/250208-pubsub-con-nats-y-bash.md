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

title=  "PubSub con NATS y Bash"
date = "2025-02-08T22:22:53+01:00"
+++
Bash es increiblemente permisivo, por lo que se ha convertido en mi lenguaje de *prototipado* por defecto.
Combinado con SQLite y Jq, me faltaba una última pieza para completar los diseños: un sistema *pubsub*.
Ahora he encontrado una manera sencilla de integrar NATS (corriendo en Docker) con Bash.
<!--more-->

NATS es un sistema de mensajería *pubsub* escrito en Go. Aunque es relativamente sencillo usar las [bibliotecas](https://docs.nats.io/using-nats/developer) que ofrecen para desarrollar clientes e interaccionar con NATS, quería aprovechar la existencia de NATS CLI para integrarlo en mis scripts de manera sencilla.

## El problema

Usando el cliente `nats`, suscribirse a un *topic* es tan sencillo como:

```console
nats sub <topic-name>
```

Sin embargo, al ejecutar el comando, el cliente `nats` se queda *escuchando*, y no finaliza.
El comando muestra los mensajes que se reciben en el *topic* indicado, pero no he sabido capturarlos de forma que pudiera consumir los mensajes recibidos desde un script en Bash.

## La solución

La solución ha venido de revisar la ayuda del comando y descubrir que se puede finalizar "la suscripción" tras recibir un número determinado de mensajes:

```console
$ nats sub --help
usage: nats subscribe [<flags>] [<subject>]

Generic subscription client

Args:
  [<subject>]  Subject to subscribe to

Flags:
...
--count=COUNT                 Quit after receiving this many messages
```

Al finalizar el comando, el mensaje recibido se puede capturar en una variable, y el script continua, *consumiendo* el valor y haciendo con él lo que queramos...

Una simple prueba de concepto:

```console
#!/usr/bin/env bash

while true ; do
    sleep 0.1
    msg=$(nats sub stuff --raw --count=1)
    echo "message: $msg"
done
```

Añadimos `--raw` para evitar el mensaje de NATS del número de mensaje recibido, etc..

```console
message: 19:30:08 Subscribing on sample.topic
[#1] Received on "sample.topic"
hola
```

Una vez *desbloqueada* la recepción de los mensajes, la publicación no presenta ningún problema.
En este ejemplo, enviamos un ID y un *timestamp* generados por NATS en bucle:

```console
#!/usr/bin/env bash

while true ; do
    sleep 0.5
    nats pub stuff '{ "id": "{{ ID }}", "time": "{{ UnixNano }}" }'
done
```

El *subscriber* recibe el mensaje y lo imprime por pantalla usando `echo`:

```console
$ bash subscriber.sh
message: { "id": "vqUCNi4QzgspHAGj2WyfZl", "time": "1739102475245242000" }
message: { "id": "AC6pFZcnRHQ5Xzt9CV5RbP", "time": "1739102475787266000" }
message: { "id": "7s8IiQxxeife2AxTXOG1JR", "time": "1739102476327454000" }
...
```

## Ejecutando *pipelines*

Imprimir un mensaje a `stdout` no lleva prácticamente nada de tiempo... Pero si queremos hacer alguna cosa más "complicada", que lleve más tiempo, el *subscriber* podría perder algunos mensajes... Para evitar esto, usamos la idea de las *go routines*, lanzando un proceso independiente para no bloquear la ejecución de `subscriber.sh`.
En Bash, movemos el proceso "pesado" a segundo plano añadiendo un `&` tras el comando.

Por ejemplo:

```console
#!/bin/bash

while true ; do
    sleep 0.1
    msg=$(nats sub stuff --raw --count=1)
    echo "processing '$msg'..."
    ./processor.sh "$msg" &
done
```

`processor.sh` llevaría a cabo un proceso que requiere más tiempo (que en este caso simulamos con un `sleep`), aunque en este caso sólo se trata de guardar los mensajes que recibimos en un fichero CSV:

```console
#!/usr/bin/env bash

parser() {
    local msg="$1"
    id=$(echo $1 | jq -r '.id')
    time=$(echo $1 | jq -r '.time')
    if [[ "$id" == "" ]]; then
        echo "error: malformed message '$msg'"
        exit 1
    fi

    echo "$id,$time" >> registry.csv
    sleep 2
}

if [[ ! -f ./registry.csv ]]; then
    echo "ID, TimeStamp (Unix)" > ./registry.csv
fi

parser "$@"
```

## Discriminando mensajes

Podemos tener múltiples suscriptores *escuchando* a un topic.
La idea es que cada uno de los suscriptores sólo procese un determinado "tipo" de mensaje.
Para ello, en primer lugar, deberíamos tener diferentes tipos de mensajes.

Imaginemos que nuestro sistema de mensajería pubsub recibe el resultado del lanzamiento de una moneda:

```console
#!/bin/bash

flipper() {
    (( RANDOM % 2 )) && echo "cara" || echo "cruz"
}

while true ; do
    sleep 0.5
    nats pub stuff '{ "result": "'$(flipper)'" }' 
done
```

Como antes, generamos un *subscriber*, pero esta vez sólo actuará cuando el mensaje contenga `cara`:

```console
#!/bin/bash

while true ; do
    sleep 0.1
    msg=$(nats sub stuff --raw --count=1)
    ./flip_logger.sh "$msg" &
done
```

El *subscriber* en sí no contiene ninguna lógica; sólo pasa la información al script *flip_logger.sh* para que éste la procese sin bloquear la recepción de mensajes.
El análisis y procesado del contenido del mensaje se hace en `flip_logger.sh`; en este caso, se muestra un mensaje en `stdout` indicando que el lanzamiento ha resultado `cara`:

```console
#!/usr/bin/env bash

if [[ "$(echo $1 | jq -r '.result')" == "cara" ]]; then
    echo "Ha salido 'Cara'"
fi
```

No es el script más útil del mundo, pero muestra cómo podemos tener múltiples scripts suscritos a un topic haciendo que cada uno de ellos reaccione únicamente cuando se detecte un mensaje -o una propiedad del mensaje- determinada.
