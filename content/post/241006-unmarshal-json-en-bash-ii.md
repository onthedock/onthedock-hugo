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

title=  "Unmarshal JSON en Bash (Parte II)"
date = "2024-10-06T11:24:31+02:00"
+++
Este artículo es la segunda parte de [Unmarshal JSON en Bash (Parte I)]({{< ref "241005-unmarshal-json-en-bash-i.md" >}}).

Al final de la primera parte vimos cómo el MVP (*minimum viable product*) no producía el resultado esperado para *keys* en el documento JSON cuyo valor es un *array* o un *object*.

En esta segunda parte, vamos a resolver este problema.
<!--more-->
## Documento de tipo `object`

En cierto punto del artículo anterior indicaba que la función `unmarshal` sólo soporta documentos JSON de tipo `object`, es decir `{ ... }`.
En primer lugar, exploramos qué otros tipos de documentos podemos encontrarnos en [JSON](https://www.json.org/).

## Otros tipos de documentos JSON

### `array`

Si el documento JSON es de la forma:

```json
[ "jim", "pam", "michael"]
```

Las *keys* son valores numéricos, es decir, el índice del elemento en el *array*:

```console
$ jq -r 'keys[]' invalid.json 
0
1
2
```

En Bash no podemos definir una variable usando un número, lo que resutaría en `1="Dunder Mifflin"`, por ejemplo, dando lugar al error `not a valid identifier`.

Otras combinaciones de elementos, si el JSON es un `array`, dan el mismo resultado:

```json
[
    {
        "manager": "michael"
    },
    {
        "employees": ["pam","jim"]
    }
]
```

Por tanto, descartamos dar soporte a los documentos JSON de tipo `array`.

## `string`, `number` y `whitespace`

Si el documento únicamente contiene sólo un elemento de tipo `string` (por ejemplo `"pam"`), es un documento JSON válido, pero no tenemos ninguna *key*:

```console
$ jq -r 'keys[]' invalid.json 
jq: error (at invalid.json:0): string ("pam") has no keys
```

Lo mismo sucede si el contenido del documento JSON es un número, como `1` o `-0.7`:

```console
$ jq -r 'keys[]' invalid.json 
jq: error (at invalid.json:0): number (1) has no keys
```

## Cómo determinar el tipo de documento JSON

Jq proporciona la función [`type`](https://jqlang.github.io/jq/manual/#type) que nos sirve, precisamente, para identificar de qué tipo es el argumento que se le pasa.

Pasamos el documento JSON completo a la función `type` para determinar que se trata de un `object`; si no es así, salimos:

```console
document_type=$(jq -r '. | type' "$doc")
if [[ $document_type != "object" ]]; then
    echo "'$doc' is of an unsupported type: '$document_type' (only 'object' is supported)"
    exit 0
fi
```

De esta forma:

```console
$ bash main.sh --doc invalid.json
'invalid.json' is of an unsupported type: 'array' (only 'object' is supported)
```

## *keys* con valores de tipo `array` u `object`

Ahora hemos restringido los documentos que vamos a procesar, pero todavía podemos encontrar *keys* de tipo `array` y `object`:

```json
{
    "customer": "Dunder Mifflin Scranton",
    "uuid": "3f6b0814-e923-415b-9fd8-db9407e69546",
    "active": true,
    "employees": ["pam", "jim", "michael"]
}
```

El resultado, al intentar usarlo en el *script*:

```console
# ...
# Use variables
echo "customer: $customer"
echo "uuid: $uuid"
echo "active: $active"
for e in ${employees[@]}; do
    echo " - $e"
done
```

Da como resultado:

```console
$ bash mvp_unmarshal.sh --doc customer.json 
customer: Dunder Mifflin Scranton
uuid: 3f6b0814-e923-415b-9fd8-db9407e69546
active: true
 - [
 - "pam",
 - "jim",
 - "michael"
 - ]
```

### Discriminando las *keys*

Podemos usar la función de Jq `type` para determinar qué tipo de valor contiene cada *key*:

```console
for k in "${keys[@]}"; do
    declare -n ref="$k"
    # Determine the type of the value for every key
    type="$(jq -r --arg k "$k" '.[$k] | type' "$document")"
    case $type in
        "string" | "boolean" | "number")
            ref=$(jq -r --arg key "$k" '.[$key]' "$document")
        ;;
        *)
            continue
        ;;
    esac
    ref=$(jq -r --arg key "$k" '.[$key]' "$doc")
done
```

El resultado no es exactamente lo que buscábamos, pero vamos en la buena dirección; las *keys* soportadas se procesan con normalidad y las "problemáticas", se ignoran (por ahora):

```console
$ bash mvp_unmarshal.sh --doc customer.json 
customer: Dunder Mifflin Scranton
uuid: 3f6b0814-e923-415b-9fd8-db9407e69546
active: true
```

## Convertir JSON *array* en Bash *array*

Ya hemos usado anteriormente un mecanismo para convertir de *array* en JSON a *array* en Bash: mediante `mapfile`, para las `keys` del documento.
Vamos a usar el mismo método para aquellas *keys* que son de tipo *array*:

Añadimos un nuevo *case*:

```console
"array")
    mapfile -t "$k" < <(jq -r --arg key "$k" '.[$key][]' "$doc")
;;
```

Esto ya nos proporciona el resultado que buscamos:

```console
$ bash mvp_unmarshal.sh --doc customer.json 
customer: Dunder Mifflin Scranton
uuid: 3f6b0814-e923-415b-9fd8-db9407e69546
active: true
 - pam
 - jim
 - michael
```

## ¿Qué pasa con los `object`?

Si tratamos los `object` como `array`, como usamos el *iterator* para obtener los elementos del *array*, en el objeto obtenemos los valores de cada una de las *keys* en el *object* (al menos, del primer nivel):

```json
{
    "customer": "Dunder Mifflin Scranton",
    "uuid": "3f6b0814-e923-415b-9fd8-db9407e69546",
    "active": true,
    "employees": [
        "pam",
        "jim",
        "michael"
    ],
    "organization": {
        "manager": "michael",
        "branch": "scranton",
        "address": {
            "pobox": "08080",
            "street": "Fictional Street, Scranton"
        }
    }
}
```

Lo que da como resultado:

```console
bash mvp_unmarshal.sh --doc customer.json 
customer: Dunder Mifflin Scranton
uuid: 3f6b0814-e923-415b-9fd8-db9407e69546
active: true
 - pam
 - jim
 - michael

organization:
 - michael
 - scranton
 - {
 -   "pobox": "08080",
 -   "street": "Fictional Street, Scranton"
 - }
```

Para evitar introducir mayor complejidad, lo ideal sería que cualquier cosa que haya almacenada en la *key* se considere el valor de la *key*, sin evaluar su contenido.
Es decir, lo consideraremos un *string* en Bash, ya que no existe el concepto de `object`.

Para conseguirlo, eliminamos el operador `iterator` de Jq sobre la *key*:

```console
"object")
    mapfile -t "$k" < <(jq -r --arg key "$k" '.[$key]' "$doc")
;;
```

El resultado es que *todo el contenido de la key `organization` se almacena en un array de Bash*:

```console
organization:
 - {
 -   "manager": "michael",
 -   "branch": "scranton",
 -   "address": {
 -     "pobox": "08080",
 -     "street": "Fictional Street, Scranton"
 -   }
 - }
```

No es lo que queremos, pero podemos *compactar* toda la estructura del contenido de la *key* mediante la opción `-c` (`--compact-output`) de Jq:

```console
"object")
    mapfile -t "$k" < <(jq -r -c --arg key "$k" '.[$key]' "$doc")
;;
```

Esto ya proporciona la salida que buscamos:

```console
organization:
 - {"manager":"michael","branch":"scranton","address":{"pobox":"08080","street":"Fictional Street, Scranton"}}
```

Si añadimos esta misma opción para los *arrays*, podemos gestionar *arrays* de *objects*:

```json
{
    "customer": "Dunder Mifflin Scranton",
    "uuid": "3f6b0814-e923-415b-9fd8-db9407e69546",
    "active": true,
    "employees": [
        "pam",
        "jim",
        "michael"
    ],
    "organization": [
        {
            "manager": "michael",
            "branch": "scranton",
            "address": {
                "pobox": "08080",
                "street": "Fictional Street, Scranton"
            }
        },
        {
            "manager": "david",
            "branch": "slough",
            "address": {
                "pobox": "90909",
                "street": "Werhnam Street, Slough"
            }
        }
    ]
}
```

El resultado es:

```console
$ bash mvp_unmarshal.sh --doc customer.json 
customer: Dunder Mifflin Scranton
uuid: 3f6b0814-e923-415b-9fd8-db9407e69546
active: true
 - pam
 - jim
 - michael

organization:
 - {"manager":"michael","branch":"scranton","address":{"pobox":"08080","street":"Fictional Street, Scranton"}}
 - {"manager":"david","branch":"slough","address":{"pobox":"90909","street":"Werhnam Street, Slough"}}
```

Esta solución permite, si es necesario, usar Jq para procesar el contenido de estos *objetos* anidados (mediante `echo $k | jq '.'`)

## Convertirlo en una función

Lo último que voy a hacer es *empaquetar* el código en forma de función.

```console
unmarshal() {
    local document="$1"

    # If it's not a JSON object, exit
    document_type=$(jq -r '. | type' "$document")
    if [[ $document_type != "object" ]]; then
        echo "'$document' is of an unsupported type: '$document_type' (only 'object' is supported)"
        exit 1
    fi

    # Save document keys in a Bash array
    declare -a keys
    mapfile -t keys < <(jq -r 'keys[]' "$document")

    for k in "${keys[@]}"; do
        # Declare reference variable
        declare -n ref="$k"
        type="$(jq -r --arg k "$k" '.[$k] | type' "$document")"
        case $type in
            "string" | "boolean" | "number")
                # echo "type: $type"
                ref=$(jq -r --arg key "$k" '.[$key]' "$document")
            ;;
            "array")
                mapfile -t "${!ref}" < <(jq -r -c --arg key "$k" '.[$key][]' "$document")
            ;;
            "object")
                mapfile -t "$k" < <(jq -r -c --arg key "$k" '.[$key]' "$document")
            ;;
            *)
               echo "'$k' is of an unsupported type: '$type' (only 'string', 'bool', 'number' and 'null' are supported)"
               exit 1
            ;;
        esac
    done
}
```
