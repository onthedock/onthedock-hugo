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

title=  "Define parámetros para tus scripts en Bash 3 con argparse-sh"
date = "2025-01-21T18:04:22+01:00"
+++
Hace un tiempo encontré el repositorio [yaacov/argparse-sh](https://github.com/yaacov/argparse-sh), del autor del artículo [argparse.sh: Simple Yet Powerful Bash argument parsing](https://medium.com/@kobi.zamir/argparse-sh-simple-yet-powerful-bash-argument-parsing-124bad97d926).
Como indica en el *post*, `argparse-sh` es una forma sencilla y potente de gestionar parámetros en Bash.

La idea en la que se basa, creando un *array asociativo* (un `dictionary` en Python), me recordó a [Cobra](https://cobra.dev/), en Go.
Pese a ser una *library* pequeña, permite definir parámetros obligatorios y opcionales, un mensaje de ayuda para cada parámetro, diferentes tipos de parámetros...

La "*única pega*" es que, debido a que usa *arrays asociativos*, require Bash 4 o superior.

Así que me puse *manos a la obra* para hacer un *backport* y hacerlo compatible con Bash 3 (la que hay *por defecto* en los Mac).
<!--more-->
## Objetivo

`argparse` permite:

- definir parámetros
- asignar un valor por defecto a los parámetros
- especificar el *tipo* de parámetro
- configurar un mensaje de ayuda específico para cada parámetro
- indicar si el parámetro es *requerido* u *opcional*

*Grosso modo*, `argparse` define dos funciones `define_arg` y `parse_args`.

Empezamos creando la versión **mínima** compatible con Bash 3 de `define_arg`:

```console
define_arg() {
    arg_name=$1
    arg_value=${2:-""}
    export "$arg_name"="$arg_value"
}
```

Para ir probando el desarrollo, creamos un *script* de prueba:

```console
#!/usr/bin/env bash

source argsparse3.sh

define_arg "name" "xavi"
define_arg "branch"

echo "my name is $name"
echo "branch is: $branch"
```

Si ejecutamos el *script* de prueba, el resultado es:

```console
my name is xavi
branch is:  # <-- el valor por defecto es ''
```

De momento, podemos definir parámetros para el *script* y darles un valor por defecto.

## `parse_args`

El objetivo de `parse_args` es procesar los parámetros pasados desde la línea de comandos.

Como antes, definimos una función mínima:

```console
parse_args() {
    while [[ $# -gt 0 ]]; do
        key="${1#--}" # remove '--' prefix
        if [[ -z "$2" || "$2" == --* ]]; then
            echo "Missing value for argument --$key"
            exit 1
        else
            export "$key"="$2"
            shift 2
        fi
    done
}
```

La incluimos en el *script* de prueba:

```console
#!/usr/bin/env bash

source argsparse3.sh

define_arg "name" "xavi"
define_arg "branch"

parse_args "$@"

echo "my name is $name"
echo "branch is: $branch"
```

Vemos que funciona correctamente:

```console
$ bash test_argparse3.sh --name federico --branch main
my name is federico
branch is: main
```

## Tipos de parámetros

En `argsparse.sh`, una de las propiedades de los *parámetros* es la llamada `action`.
IMO, sería mejor llamarlo `type`, por ejemplo, pues define el **tipo** del parámetro, teniendo sólo dos opciones: `string` y `store_true`. Ésta segunda opción es para *arguments* de tipo `bool`; por defecto, su valor es `false` y si se explicita el `flag`, entonces su valor es `true`.
Por ese motivo, llamaré a esta propiedad `type` (en vez de mantener `action`).

A nivel funcional, un parámetro de tipo `string` tiene que ir seguido del valor que se quiere asignar a ese parámetro. Por ejemplo `--name xavi`.

En el segundo caso, de tipo `bool`, el valor de un parámetro `force` es `false` por defecto. Cuando se explicita el parámetro, entonces el valor asociado es `true`. Como la mera presencia del parámetro -que este caso suele llamarse `flag`- indica el valor, no va seguido del valor. Como ejemplo, `<cmd> --name xavi` (por omisión, el valor de `force` es `false`), mientras que `<cmd> --name xavi --force` indica que `force` es `true`.

### Comunicando `define_arg` y  `parse_args`

Las propiedades de los parámetros se definen en `define_arg` pero se *consumen* en `parse_args`.
Por tanto, necesito poder comunicar las propiedades de un parámetro definido en una función en otra.

Siguiendo con la idea de `argsparse.sh`, defino una *list* global `ARGS_PROPERTIES`:

```console
ARGS_PROPERTIES=()
```

Ahora, actualizamos `define_arg` para añadir las propiedades que se definan a esta lista global.

```console
define_arg() {
    arg_name=$1
    arg_value=${2:-""}
    arg_type=${3:-"string"}
    ARGS_PROPERTIES+=("$arg_name" "$arg_value" "$arg_type")
        echo "DEBUG: ${ARGS_PROPERTIES[*]}, ${#ARGS_PROPERTIES[@]}"
        for a in ${ARGS_PROPERTIES[@]}; do echo "this is item: '$a'"; done
    export "$arg_name"="$arg_value"
}
```

El problema que tenemos ahora es que si el valor por defecto de una variable es "", no podemos identificar el valor de un "espacio" normal (incluso si definimos el valor como " ", con un *espacio explícito*).

```console
$ bash test_argparse3.sh --branch main
DEBUG: name xavi string, 3
this is item: 'name'
this is item: 'xavi'
this is item: 'string'
DEBUG: name xavi string branch   string, 6
this is item: 'name'
this is item: 'xavi'
this is item: 'string'
this is item: 'branch'
this is item: 'string'
my name is xavi
branch is: main
```

Por tanto, tendremos que usar algún tipo de *placeholder* para indicar que el valor de un argumento es la cadena "vacía".

> Esto sólo tiene sentido para parámetros de tipo `string`; el valor por defecto de un parámetro de tipo `bool` siempre será `true` o `false`, pero no puede estar "vacío".

En vez de usar una cadena fija, definimos una variable `_NULL_VALUE_` de manera que se pueda *personalizar* el valor del *placeholder*.

También actualizamos la asignación del valor por defecto a esta variable:

```console
arg_value=${2:-"$_NULL_VALUE_"}
```

De esta forma, el valor *vacío* sí que se almacena correctamente en `ARGS_PROPERTIES`.

```console
$ bash test_argparse3.sh --branch main
DEBUG: name xavi string, 3
this is item: 'name'
this is item: 'xavi'
this is item: 'string'
DEBUG: name xavi string branch null string, 6
this is item: 'name'
this is item: 'xavi'
this is item: 'string'
this is item: 'branch'
this is item: 'null'
this is item: 'string'
my name is xavi
branch is: main
```

Ahora que tenemos un *tipo* para cada parámetro, tenemos que usarlo en `parse_args`.

Como `ARGS_PROPERTIES` es una *lista* y no un *array asociativo*, no podemos acceder a un elemento concreto a través del nombre del parámetro.

Tenemos que buscar en qué posición se encuentra el parámetro pasado desde la CLI en la lista de `ARGS_PROPERTIES`, y así poder identificar de qué tipo es.

Iteramos sobre los elementos de `ARGS_PROPERTIES` y comparamos con el parámetro pasado desde la CLI; si lo encontramos, miramos el *type*, que se encuentra dos posiciones más allá (si no lo encontramos, salimos del bucle con `break`).

En función del tipo del *argument*, asignamos el siguiente valor en `$@` o `true`, si se trata de un parámetro de tipo `bool`.

### Valores "nulos"

Hemos decidido utilizar un *placeholder* para indicar valores vacíos por defecto en `ARGS_PROPERTIES`.
Pero eso significa que si usamos `null` para **indicar** que el valor por defecto de una variable es la cadena vacía (`""`), tenemos que asignar el valor `""` a la variable, no el *placeholder*, como sucede ahora:

```console
$ bash test_argparse3.sh --branch main --force --patata
my name is null # <-- Should not show the 'placeholder' for empty value
branch is: main
force is: true
```

Lo solucionamos añadiendo el siguiente condicional en `define_arg`:

```console
#   ...
    if [[ "$arg_value" == "$_NULL_VALUE_" ]]; then
        arg_value=""
    fi
    export "$arg_name"="$arg_value"
}
```

Así, el `ARGS_PROPERTIES` usamos el *placeholder*, pero asignamos a la variable el valor correcto, la cadena vacía.

```console
$ bash test_argparse3.sh --branch main --force --patata
my name is 
branch is: main
force is: true
```

## Parámetros **requeridos**

La idea de que un parámetro sea requerido implica que el usuario tiene que incluirlo al llamar al *script*.
Pero cuando se define un parámetro, se puede especificar un valor por defecto, por lo que incluso si no se proporciona, el valor está definido (y tiene un valor).

Por tanto, para un parámetro requerido, debe ignorarse el valor por defecto proporcionado, cualquiera que sea, al definirlo.

```console
define_arg() {
    arg_name=$1
    arg_value=${2:-"$_NULL_VALUE_"}
    arg_type=${3:-"string"}
    arg_required=${4:-"no"}
    if [[ "$arg_required" == "required" ]]; then
        arg_value="$_NULL_VALUE_"
    fi
    ARGS_PROPERTIES+=("$arg_name" "$arg_value" "$arg_type" "$arg_required")
    if [[ "$arg_value" == "$_NULL_VALUE_" ]]; then
        arg_value=""
    fi
    
    export "$arg_name"="$arg_value"
}
```

Verificando si el parámetro es requerido en `define_arg`, establecemos su valor como el valor nulo, sobrescribiendo el valor que se pueda haber indicado al definir el parámetro.

```console
# define_arg "name" "xavi" "string" "required"
$ bash test_argpars3.sh                 
my name is # <-- Aunque se define el valor por defecto 'xavi', se ignora al ser requerido
branch is: 
force is: false
```

### ¿Cómo indicar que el valor es requerido?

Usamos parámetros posicionales para indicar las diferentes propiedades de un parámetro en `define_arg`, por lo que prefiero usar `required` para indicar que un parámetro es *requerido*. Para aquellos parámetros que no lo son, usamos el valor (por defecto) `optional`.

Si no se proporciona alguno de los valores requeridos, el *script* debe finalizar.
Por tanto, obtenemos la lista de valores definidos que son requeridos y examinamos los pasados desde la CLI para identificar si hay alguno que no está presente; en ese caso, el *script* finaliza.

```console
parse_args() {
    # Check for missing required arguments
    for ((i=0; i<${#ARGS_PROPERTIES[@]}; i+=4)); do
        if [[ "${ARGS_PROPERTIES[i+_REQUIRED_]}" == "required" ]]; then
            if ! (echo "$@" | grep "${ARGS_PROPERTIES[i]}") >/dev/null ; then
                echo "'${ARGS_PROPERTIES[i]}' is required"
                exit 1
            fi
        fi
    done
#   ...
```

Así, ahora:

```console
$ bash test_argparse3.sh
'name' is required
```

> El *script* finaliza en cuanto se identifica un parámetro que requerido que no se ha proporcionado, en vez de analizar todos los parámetros requeridos que faltan.

## Ayuda

`argsparse.sh` incluye una función `show_help` que muestra la cadena de ayuda asociada a cada parámetro cuando se ejecuta el *script* añadiendo el *flag* `-h` o `--help`.

Empezamos por añadir la propiedad de ayuda a cada parámetro actualizando la función `define_arg`:

```console
define_arg() {
    arg_name=$1
    arg_value=${2:-"$_NULL_VALUE_"}
    arg_type=${3:-"string"}
    arg_required=${4:-"no"}
    arg_help=${5:-""}
    if [[ "$arg_required" == "required" ]]; then
        arg_value="$_NULL_VALUE_"
    fi
    ARGS_PROPERTIES+=("$arg_name" "$arg_value" "$arg_type" "$arg_required" "$arg_help")
    if [[ "$arg_value" == "$_NULL_VALUE_" ]]; then
        arg_value=""
    fi
    
    export "$arg_name"="$arg_value"
}
```

Si el usuario del *script* pasa el *flag* de ayuda, no está interesado en ejecutarlo, por lo que haremos la comprobación de si se ha pasado `-h` o `--help` antes de hacer cualquier otra cosa (por ejemplo, de si falta alguno de los parámetros requeridos).

Empezamos probado la idea con:

```console
show_help() {
    if (echo "$@" | grep -- "-h" > /dev/null) || (echo "$@" | grep -- "--help" > /dev/null); then
        echo "Help!"
        exit 0
    fi
}
```

Y vemos que, efectivamente, funciona:

```console
$ bash test_argparse3.sh --help
Help!
$ bash test_argparse3.sh -h
Help!
```

Ahora lo único que tenemos que hacer es sustituir `echo "Help!"` por un bucle que muestre información asociada a los diferentes parámetros definidos para el *script*.

```console
show_help() {
    local args=( "${ARGS_PROPERTIES[@]}" )
    local prefix="   "
    if (echo "$@" | grep -- "-h" > /dev/null) || (echo "$@" | grep -- "--help" > /dev/null); then
        echo "usage: $0 [arguments...]"
        echo "$SCRIPT_DESCRIPTION"
        echo ""
        echo "arguments:"
        for ((i=0; i<${#args[@]}; i+=5)); do
            [[ ${args[i+_DEFAULT_]} == "$_NULL_VALUE_" ]] &&  args[i+_DEFAULT_]=''
            if [[ ${args[i+_TYPE_]} == "bool" ]]; then args[i+_TYPE_]=''; args[i+_HELP_]="${args[i+_HELP_]} $FLAG_BEHAVIOUR"; else args[i+_TYPE_]="<${args[i+_TYPE_]}>" ; fi
            printf "%s %-20s: (%8s) %s\n" "$prefix" "--${args[i]} ${args[i+_TYPE_]}" "${args[i+_REQUIRED_]}" "${args[i+_HELP_]} (defaults to '${args[i+_DEFAULT_]}')"
        done
        printf "\n%s %-20s: Display this help\n"  "$prefix" "-h | --help"
        exit 0
    fi
}
```

Tal y como hemos definido la función `show_help`, sólo se muestra el mensaje si el usuario añade `-h` o `--help`.
Para poder mostrar el menjaje de ayuda también si se produce un error (por ejemplo, que no se encuentra un parámetro *required*), separamos la comprobación de la acción de mostrar el mensaje de ayuda:

```console
parse_args() {
    # Check for 'help' flags
    if (echo "$@" | grep -- "-h" > /dev/null) || (echo "$@" | grep -- "--help" > /dev/null); then
        show_help
        exit 0
    fi
    # ...
```

Y la función `show_help`:

```console
show_help() {
    local args=( "${ARGS_PROPERTIES[@]}" )
    local prefix="   "
    
    echo -e "\nusage: $0 [arguments...]"
    echo "$SCRIPT_DESCRIPTION"
    echo ""
    echo "arguments:"
    for ((i=0; i<${#args[@]}; i+=5)); do
        [[ ${args[i+_DEFAULT_]} == "$_NULL_VALUE_" ]] &&  args[i+_DEFAULT_]=''
        if [[ ${args[i+_TYPE_]} == "bool" ]]; then args[i+_TYPE_]=''; args[i+_HELP_]="${args[i+_HELP_]} $FLAG_BEHAVIOUR"; else args[i+_TYPE_]="<${args[i+_TYPE_]}>" ; fi
        printf "%s %-20s: (%8s) %s\n" "$prefix" "--${args[i]} ${args[i+_TYPE_]}" "${args[i+_REQUIRED_]}" "${args[i+_HELP_]} (defaults to '${args[i+_DEFAULT_]}')"
    done
    printf "\n%s %-20s: Display this help\n"  "$prefix" "-h | --help"
}
```

Finalmente, en la función `check_required`:

```console
check_required() {
    for ((i=0; i<${#ARGS_PROPERTIES[@]}; i+=5)); do
        if [[ "${ARGS_PROPERTIES[i+_REQUIRED_]}" == "required" ]]; then
            if ! (echo "$@" | grep "${ARGS_PROPERTIES[i]}") >/dev/null ; then
                echo "'${ARGS_PROPERTIES[i]}' is required"
                show_help
                exit 1
            fi
        fi
    done
}
```

Ahora, si el usuario no proporciona uno de los parámetros requeridos:

```console
$ bash test_argparse3.sh --branch main
'--name' is required

usage: test_argparse3.sh [arguments...]
argsparse3.sh is a Bash 3 library for defining script arguments

arguments:
    --name <string>     : (required) Provides the name of the person executing the script. (defaults to '')
    --branch <string>   : (optional) Name of the repository branch. (defaults to '')
    --force             : (optional) Always push changes. Add the flag to set the argument to 'true' (don't use '--flag true') (defaults to 'false')

    -h | --help         : Display this help
```

## Conclusión

Con `argparse3.sh` he podido implementar la misma funcionalidad incluida en `argparse.sh`, pero haciéndola *retro-compatible* con Bash 3.
