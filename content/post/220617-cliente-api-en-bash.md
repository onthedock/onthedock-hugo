+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "bash", "curl"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/bash.svg"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/

# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}
# YouTube           {{< youtube w7Ft2ymGmfc >}}
# Gist              {{< gist username 7896402 >}}
# Highlight         {{< highligth language >}}...{{< /highlight >}}
# Twitter           {{< tweet user="SanDiegoZoo" id="1453110110599868418" >}}

title=  "Cliente API en Bash (con curl)"
date = "2022-06-17T20:46:13+02:00"
+++
En una entrada anterior, [Obtener respuesta y código de la petición HTTP con curl]({{< ref "220518-obtener-respuesta-y-http-status-con-curl.md" >}}), explicaba cómo mejorar, en mi opinión, la *relación* con la API desde los *scripts* (en Bash) que se ejecutan desde una *pipeline*.

La idea que explicaba en el artículo era cómo usar el código HTTP devuelto por la función que expone la API para controlar posibles errores.

Como prueba de concepto fue satisfactoria, pero no resulta práctica aplicarla; en un caso real se usan múltiples documentos y la repetición del mismo código una y otra vez hace que se alcance el límite de cuatro mil caracteres en un *paso* de la *pipeline*...

Así que la solución es *encapsular* esta idea en una función en vez de repetir el mismo código una y otra vez: [Don't repeat yourself](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself)
<!--more-->

## Creando un cliente en Bash

El patrón habitual de interacción con la API es

- Generar el *payload* en JSON y guardarlo en una variable.
- Ejecutar la petición usando `curl` y guardar la respuesta en un fichero.
- Filtrar la respuesta usando `jq` leyendo el fichero.

### *Parseo* de parámetros en las funciones

Aunque no tiene nada que ver con la API, uno de los elementos clave para construir el cliente ha sido disponer una función con la que analizar los parámetros pasados a una función en Bash.

Para ello me he basado en una función que desarrollé hace tiempo [`parse_cli_args.sh`](https://github.com/onthedock/reference_bash_scripts/blob/main/parse_cli_args/parse_cli_args.sh).

Con la intención de dividir la interacción con la API en funciones, quería poder nombrar los parámetros, de manera que fuera sencillo identificar qué es lo que se está pasando a la función:

```shell
# Bad
build_query '1234' '/path/to/file.json'
# Good
build_query --id '1234' --output '/path/to/file.json'
```

Además, en la función *receptora*, aunque se asignen los parámetros posicionales a variables "con un nombre claro", el problema es que los parámetros son **posicionales**, lo que obliga a recordad qué hay que pasar y **en qué orden**:

```shell
build_query() {
    local id, output
    id="$1"
    output="$2"
    # do something
}
```

Lo que he hecho ha sido crear una función `parse_args` y llamarla desde cada función que necesite *parsear* parámetros. En vez crear una función `parse_args` para cada función (multiplicando el mismo código una y otra vez), he mantenido una única función `parse_args` con todos los parámetros que se usan en todas las funciones del *cliente*.

Probablemente no es la mejor solución, pero funciona `¯\_(ツ)_/¯`.

Así:

```shell
build_query() {
    parse_args $@
    # do something with $id and $output
}

build_query --id '1234' --output '/path/to/file.json'
```

> Probablemente se puedan definir las variables (`id` y `output` en el ejemplo) como [`local`](https://tldp.org/LDP/abs/html/othertypesv.html) dentro de la función y así se eviten efectos imprevistos si se declaran también a nivel global...

### Construcción de la *query*

En función de la acción a realizar, los campos a incluir en la *query* varían de una acción a otra.

En una consulta para filtrar documentos con un determinado valor en un campo concreto, la *query* sería algo como:

```json
{
    "action": "query",
    "field": "name",
    "operand": "==",
    "value": "$name"
}
```

Mientras que para obtener un documento específico, tendríamos algo como:

```json
{
    "action": "get",
    "id": "$id"
}
```

De nuevo, la solución ha sido la más sencilla (IMHO); usar un bloque `case`:

```shell
build_query() {
    parse_args $@
    case "$action" in
    "get")
        cat <<-GET_QUERY
        {
            "action": "get",
            "id": "$id"
        }
GET_QUERY
        ;;
    "query")
        cat <<-QUERY
        {
            "action": "query",
            "field": "$field",
            "operand": "==",
            "value": "$value" 
        }
QUERY
        ;;
    *)
        printf "[ERROR] Unknown command to build the query %s\n" "cmd"
        exit 1
        ;;
    esac
```

## Llamar a la API

Este bloque está inspirado directamente en el código de la entrada [Obtener respuesta y código de la petición HTTP con curl]({{< ref "220518-obtener-respuesta-y-http-status-con-curl.md" >}}).

La única diferencia es que ahora se encuentra dentro de una función:

```shell
call_api() {
    parse_args $@
    api_response="$(curl ...)
    if [[ "$api_response" != '200' ]]; then
        printf "[ERROR] API status code %s\n" "$api_response"
        exit 1
    else
        # write retrieved document to file
    fi
}
```

> Hace unos días leí el artículo  [Code: Align the happy path to the left edge](https://medium.com/@matryer/line-of-sight-in-code-186dd7cdea88) de Mat Ryer, por lo que quizás la reescriba para que el *happy path* esté a la izquierda y sea más fácil de "leer".

## Funciones sencillas de recordar

La función `build_query` requiere diferentes parámetros en función del tipo de *query* que quieras hacer. Pero para mí resulta confuso tener que recordar todos los parámetros en función de cada tipo de consulta.

Así que he creado unas funciones que *envuelven* (*wrap*) las funciones necesarias para hacer la llamada a la API pero que son -eso espero- más sencillas de usar.

Por ejemplo, `get_document_by_id` deja claro que requiere un `id`, así que resulta *natural* `get_document_by_id --id '1234'`. (O incluso `get_document_with --id '1234'`, por ejemplo, aunque prefieron la forma "explícita").

Del mismo modo, `get_documents_by_type --type 'contacto' --field 'name' --value 'xavi'`; puede "leerse" como "*obtén los documentos de tipo 'contacto' que en el campo 'name'  tienen el valor 'xavi'*". Esto simplifica el uso de las funciones y evita errores.

Estas funciones invocan a las funciones "de bajo nivel":

```shell
get_documents_by_type() {
    parse_args $@
    query=$(build_query --action "query" --type "$type" --field "$field" --value "$value")
    call_api --query "$query"
}
```

Todas estas funciones se encuentran en un fichero `api_client.sh` que se puede *importar* (vía `source`) en otros *scripts* y reusar una y otra vez.

```shell
#!/bin/bash
source ~/lib/api_client.sh

# Do something
```

## Resumen

En esta entrada le he dado una *nueva vuelta de tuerca* al uso de Bash para interaccionar con una API usando `curl`.

En vez de repetir el código una y otra vez para validar la respuestas de la API, he creado una nueva versión de un *cliente* para la API.

El objetivo es proporcionar una mayor funcionalidad (control de errores, parámetros con nombre, etc) para que sea más sencillo interaccionar con la API y evitar que se *cuelen* respuestas incorrectas que hagan fallar las *pipelines* inesperadamente o peor aún, que modifiquen la información de la base de datos de manera inconsistente.

Como con la primera versión, habrá que ver si a la práctica la idea es suficientemente buena como para que sea integrada en el equipo y empiece a usarse. Entonces habrá que plantear extender las acciones soportadas por el cliente en Bash para incluir el resto de acciones disponibles en la API.
