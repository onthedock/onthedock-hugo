+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "bash"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/bash.svg"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/
# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}

title=  "Unmarshal JSON en Bash (Parte I)"
date = "2024-10-05T20:17:43+02:00"
+++
*Unmarshal* es uno de esos verbos ingleses que es difícil de traducir al castellano, al menos para mí.
Según Google, sería algo así como "[desmantelar](https://www.google.com/search?q=to+unmarshal+in+spanish)".

Aplicado a la programación, "to unmarshal" está relacionado con la idea de que, partiendo de un contenido ordenado, en JSON, *desperdigamos* su contenido en variables que podemos utilizar en nuestra aplicación.

Go, por ejemplo, proporciona la función [Unmarshal](https://pkg.go.dev/encoding/json#Unmarshal), sin embargo en Bash, no he encontrado nada parecido.
<!--more-->

## Escenario

El otro día, trabajando, me encontré con que tenía que leer una propiedad de un documento JSON, validar que el valor no estuviera vacío y entonces, asignar su valor a una variable.

De hecho, en el código (en Bash), ya lo había hecho para otras dos propiedades del documento JSON... Así que tener que hacerlo una tercera vez removió algo en mí; dos veces suele ser mi umbral antes de convertir un bloque de código en una función...

Como es una tarea bastante común, pensé que alguien ya habría desarrollado algo por el estilo... Como hoy tenía mucho tiempo libre, he realizado una (superficial) búsqueda por internet y no he encontrado nada como lo que necesitaba...

## Idea

Imagina que tienes un fichero JSON como:

```json
{
    "customer": "Dunder Mifflin Scranton",
    "uuid": "3f6b0814-e923-415b-9fd8-db9407e69546",
    "active": true
}
```

Mi idea era usar una una función como `unmarshal --path customer.json` en el que el script cree una variable para cada una de las *keys* del documento JSON. Además, debe asignar el valor de la *key* en el documento a la variable en Bash; es decir:

```console
#!/usr/bin/env bash
# ...
unmarshal --path customer.json
# ...
echo "CustomerID for customer $customer" is $uuid"
```

El resultado debe ser:

```console
$ bash demo.sh --path customer.json 
CustomerID for customer 'Dunder Mifflin Scranton' is '3f6b0814-e923-415b-9fd8-db9407e69546'
```

> Por si no te suena [Dunder Mifflin Scranton](https://theoffice.fandom.com/wiki/Dunder_Mifflin_Scranton)

### Leer las *keys* del documento JSON

Una de las mejores maneras para interaccionar con JSON desde Bash es usando [Jq](https://jqlang.github.io/jq/).

Para obtener las *keys* de un documento JSON, usamos `jq -r 'keys[]' "$document"` (donde `$document` contiene el valor pasado desde la CLI mediante `--path`).
En nuestro caso:

```console
$ jq -r 'keys[]' customer.json 
active
customer
uuid
```

Pero lo que quiero es añadir las *keys* del documento a un *array* en Bash.
Esto lo consigo mediante:

```console
mapfile -t keys < <(jq -r 'keys[]' "$document")
```

> `readarray` es un sinónimo de `mapfile`. Uso `mapfile` porque `mapfile --help` devuelve más información que `readarray --help`.

Esto era lo más sencillo; el siguiente paso es más complicado.

### Definir variables cuyo nombre es el valor de un variable

Definir una variable en Bash y asignarle el valor de una propiedad de un documento JSON, usando Jq, puede conseguirse mediante:

```console
active=$(jq -r '.active' "$document")
customer=$(jq -r '.customer' "$document")
uuid=$(jq -r '.uuid' "$document")
```

El problema es que, dado que quiero que la función `unmarshal` funcione con cualquier documento JSON (*), **el script no conoce *a priori* los nombres de las *keys* en el documento JSON**.

> (*)= Un documento JSON de **tipo object** `{...}`; otros tipos de documentos [JSON](https://www.json.org/) válidos, de tipo "string", "number" o "array" no están soportados.

Por tanto, lo primero que tengo que hacer es convertir el *array* de *keys* devuelto por Jq y convertirlo en un array de Bash; a continuación, puedo recorrer el *array* en Bash para declarar una variable con el nombre de cada elemento:

```console
declare -a keys # requires Bash 4+
mapfile -t keys < <(jq -r 'keys[]' "$document")

for k in "${keys[@]}"; do
    # ...
done
```

Es decir, `$k` contiene `active` en la primera iteración, `customer` en la segunda, etc...
Dentro del bucle, quiero definir una **variable** llamada `active` en la primera iteración, `customer` en la segunda, etc...

¿Cómo puedo definir una variable cuyo nombre no conozco a priori?

La solución es definir una variable como [*referencia*](https://www.gnu.org/software/bash/manual/html_node/Bash-Builtins.html#index-declare):

```console
for k in "${keys[@]}"; do
    declare -n ref="$k"
    # ...
done
```

Definimos `ref` como referencia a `active` en la primera iteración, `customer` en la segunda... `active`, `customer`, etc. Mediante `declare -n`, Bash define una variable llamada `active` y guarda la referencia a la variable en la variable `$ref`. Lo mismo para las siguiente iteraciones del bucle.

Lo que es importante tener en cuenta es que **no puedo acceder directamente** a esas variables, por ejemplo, para asignarles un valor.

Es decir, `$k="my_customer"` es inválido; sin embargo, mediante `ref="my_customer"` asigno `"my_customer"` a `$ref`, y como `$ref` es una *referencia* a la variable `$customer` (por ejemplo, en la segunda iteración),`ref="my_customer"` es equivalente a `customer="my_customer"`, **aunque nunca se haya definido explícitamente `customer` como variable** (se hace implícitamente al definir una *referencia* a la variable mediante `declare -n`).

Esto resuelve la primera parte del problema, definir una variable para cada *key* del documento JSON.

```console
for k in "${keys[@]}"; do
    declare -n ref="$k"
    ref=... # We have a variable per each key of the JSON document
    # ...
done
```

El siguiente paso es leer la *key* correspondiente en Jq para asignar su valor a la variable.

En Jq, obtenemos el valor de la *key* `customer` (por ejemplo), mediante:

```console
$ jq '.customer' customer.json
"Dunder Mifflin Scranton"
```

Sin embargo, en nuestro caso, el nombre de la propiedad que queremos "leer" desde el documento mediante Jq lo tenemos almacenado en una variable (`$k`) y es diferente en cada iteración del bucle.

Podemos definir variables en Jq y usarlas en nuestros filtros usando [`--arg name value`](https://jqlang.github.io/jq/manual/#invoking-jq).
Generalmente, queremos usar el valor de `value` como el **valor** de una *key* en el documento (por ejemplo, para seleccionar sólo una parte del documento JSON)

```console
$ UUID="3f6b0814-e923-415b-9fd8-db9407e69546"; jq --arg uuid "$UUID" 'select( .uuid == $uuid )' customer.json
{
  "customer": "Dunder Mifflin Scranton",
  "uuid": "3f6b0814-e923-415b-9fd8-db9407e69546",
  "active": true
}

# This UUID does not exist in the 'customer.json' document
$ UUID="eecea761-9476-4f8a-9563-ed927472d418"; jq --arg uuid "$UUID" 'select( .uuid == $uuid )' customer.json
       # <- Found no results
```

En nuestro caso, queremos usar el valor de la variable como una *key* (no como un valor) en el documento JSON.
La solución es usar el "value iterator construct", según se indica, por ejemplo, en [JSON: using jq with variable keys](https://stackoverflow.com/a/64614295).

```console
$ jq --arg key "customer" '.[$key]' customer.json
"Dunder Mifflin Scranton"

$ jq --arg key "active" '.[$key]' customer.json
true
```

Por tanto, ahora tenemos la pieza final del puzzle:

```console
for k in "${keys[@]}"; do
    declare -n ref="$k"
    ref=$(jq -r --arg key "$k" '.[$key]' "$document")
done
```

## MVP

Ya es posible probar una primera versión del *script*:

> argparse.sh proviene de `https://github.com/yaacov/argparse-sh/`

```console
#!/usr/bin/env bash

source ./argparse.sh
define_arg "doc" "" "Path to document" "string" "true"
parse_args "$@"

# Main script logic
declare -a keys
mapfile -t keys < <(jq -r 'keys[]' "$doc")

for k in "${keys[@]}"; do
    declare -n ref="$k"
    ref=$(jq -r --arg key "$k" '.[$key]' "$doc")
done

# Use variables
echo "CustomerID for customer '$customer' is '$uuid' (active: $active)"
```

Y vemos que, efectivamente, funciona como esperamos:

```console
$ bash mvp_unmarshal.sh --doc customer.json
CustomerID for customer 'Dunder Mifflin Scranton' is '3f6b0814-e923-415b-9fd8-db9407e69546' (active: true)
```

## Limitaciones

El MVP es muy básico; no me refiero a que no se comprueba si el fichero proporcionado existe (por ejemplo), sino a la funcionalidad relacionada con el *unmarshalling* del contenido del documento.

Por ejemplo, si alguna de las *keys* del documento contiene un *array* o un *object*, el resultado no es el esperado:

```json
{
    "characters": ["jim", "pam", "michael"],
    "show": { "title": "the office" }
}
```

Cada "bloque de texto" se interpreta como un valor (no importa cómo se formatee el fichero JSON):

```console
$ bash mvp_unmarshal.sh --doc invalid.json 
characters:
 - [
 - "jim",
 - "pam",
 - "michael"
 - ]

show:
 - {
 - "title":
 - "the
 - office"
 - }
```

En la segunda parte del artículo, añado soporte para estos tipos de valores.

[Unmarshal JSON en Bash (Parte II)]({{< ref "241006-unmarshal-json-en-bash-ii.md" >}})
