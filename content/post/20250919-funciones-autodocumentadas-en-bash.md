+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["bash"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/bash.svg"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/
# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}

title=  "Funciones auto-documentadas en Bash"
date = "2025-09-19T21:07:24+02:00"
+++
Me gustaría poder generar aplicaciones en Bash en las que pudiera añadir el *flag* `--help` (o `-h`) y que me mostraran la *ayuda* o *documentación* para la función. Es decir, me gustaría que mis *scripts* de Bash se comportaran como otras aplicaciones, p.ej. `git`, `terraform`, `kubectl`, etc.

`git --help` proporciona una descripción de lo que hace `git`, qué comandos tiene, etc... Si quiero obtener ayuda de alguno de los comandos de `git`, como `git add`, sólo tengo que ejecutar `git add --help` para obtener ayuda específica sobre el comando en cuestión.

En esta entrada muestro cómo he logrado lo mismo en Bash.
<!--more-->
## "Aplicación" de test

Imagina que quires desarrollar una aplicación/*script* llamada `saludo.sh`, que tiene dos *comandos*: `bienvenida` y `despedida`.
Cada uno de los comandos puede tener sus propios parámetros.

Me gustaría poder utilizar el *flag* `--help` para mostrar la *ayuda* para el comando (o subcomando).
El texto de *ayuda* es la descripción de la función (en el propio código, mediante comentarios).

## Ejemplo

Ejecutando la aplicación/*script* sin ningún comando:

```console
$ ./saludo.sh
No subcommand provided.
Try to run './saludo.sh --help'
```

Mientras que si añado el *flag* `--help`:

```console
$ ./saludo.sh --help
Help for 'saludo':
    saludo es una aplicación que permite imprimir
    un saludo de bienvenida o de despedida
    
    Comandos:
    - bienvenida
    - despedida
```

El texto que se muestra con el *flag* `--help` proviene de los comentarios de la función `saludo`:

```bash
saludo() {
    # saludo es una aplicación que permite imprimir
    # un saludo de bienvenida o de despedida
    # 
    # Comandos:
    # - bienvenida
    # - despedida
    saludo_args $@
}
```

La función `saludo_args` *parsea* los parámetros y los asigna a las variables que se usan en la función.

## Comandos

El primer parámetro para `saludo` es un *comando* o el *flag* `--help`:

```bash
saludo_args() {
    # saludo_args solo puede tener comandos o --help
    local arg cmd
    if [[ $# -eq 0 ]]; then
        echo "No subcommand provided."
        echo "Try to run '$0 --help'"
        exit 0
     fi

    cmd=$1
    shift
    case $cmd in
        -h | --help)
            print-help ${FUNCNAME[1]}
            shift
        ;;
        'bienvenida')
            bienvenida $@
        ;;
        'despedida')
            despedida $@
        ;;
        *)
            echo "error: unrecognized parameter '$cmd'"
            exit 1
        ;;
    esac
}
```

Como vemos, primero comprobamos el número de argumentos que pasamos a la función de *parseo*; si no hay ninguno, mostramos un mensaje y finalizamos la ejecución.

Como `saludo` espera un *comando*, extraemos el primer argumento pasado y miramos si coincide con alguno de los *comandos* definidos o si es el *flag* `--help`.

En el caso de ser uno de los comandos, llamamos a la función que implementa el comando con el resto de parámetros.

Para el caso en el que se proporciona `--help`, llamamos a la función `print-help` pasando `${FUNCNAME[1]}`.

## Qué es `${FUNCNAME[@]}`

`${FUNCNAME[@]}` es un *array* en Bash que contiene el *stack* de funciones en ejecución ([documentación de Bash](https://www.gnu.org/software/bash/manual/html_node/Bash-Variables.html#index-FUNCNAME)).

Esto significa que, cuando la ejecución del *script* se encuentra ejecutando la función `saludos_arg`, que se ha llamado desde la función `saludo`. Todas las funciones que se van ejecutando durante la ejecución se van añadiendo o eliminando del *stack*, aka, el *array* `${FUNCNAME[@]}`. Por tanto, `${FUNCNAME[0]}=saludo_args` y `${FUNCNAME[1]}=saludo`.

En el caso de ejecutar un comando, por ejemplo `saludo.sh bienvenida --help`, la última función llamada es `bienvenida_args` (`${FUNCNAME[0]}`), llamada desde `bienvenida`, `${FUNCNAME[1]}` (que a su vez fue llamada desde `saludos_args` (`${FUNCNAME[2]}`)), etc... El caso es que, siempre tenemos el nombre de la función que corresponde al *comando* en ejecución en la variable `${FUNCNAME[1]}`, en la *penúltima* posición en el *stack* `${FUNCNAME[@]}` (Bash inserta la última función en ejecutarse al principio del *array* `${FUNCNAME[@]}`).

## De qué sirve saber el nombre de la función

La "ayuda" o documentación de la función se encuentra, en comentarios, tras la definición de la función, un poco como los [docstring](https://peps.python.org/pep-0257/#what-is-a-docstring) en Python:

> Google coloca la documentación de la función **antes** de la declaración: [Guía de estilo para Bash (EN)](https://google.github.io/styleguide/shellguide.html#function-comments), pero para la prueba de concepto, resulta más sencillo que se encuentre **después**.
> Usando las mismas técnicas descritas más adelante, podemos mostrar la ayuda también si se encuentra **antes** de la delcaración de la función.

```bash
my-func() {
    # my-func is a dummy function in Bash
    # to illustrate how to document functions
    do_something
    ...
}
```

Por tanto, la *ayuda* (o *documentación*) que queremos mostrar para la función, se encuentra **a continuación** del nombre de la función en el código.

De forma *naive*, podría obtener la "documentación" de la función haciendo un `grep '#' <filename>` para obtener las líneas que contienen la documentación de la función...
Siguiendo esa línea de pensamiento, para poder hacer ese *grep*, necesito el nombre del **fichero** en el que se encuentra definida la función...

Afortunadamente, Bash gestionar internamente el *array* [`${BASH_SOURCE[@]}`](https://www.gnu.org/software/bash/manual/html_node/Bash-Variables.html#index-BASH_005fSOURCE). Este *array* contiene los nombres de los ficheros en el que se encuentran las funciones del *array* `${FUNCNAME[@]}`. Para simplificar la *prueba de concepto*, en este caso todas las funciones se encuentran en el mismo fichero, por lo que sólo tenemos un elemento: `${BASH_SOURCE[0]}`.

Un detalle a tener en cuenta es que `${BASH_SOURCE[@]}` contiene **sólo** el **nombre del fichero**; para conseguir la ruta **absoluta** al fichero en el que se encuentra la función, usamos el comando `realpath`:

```console
realpath=$(realpath ${BASH_SOURCE[0]})
```

Ahora podría hacer un `grep` de `#` en el fichero que contiene la función para extraer la documentación...

El problema es que con `grep` obtendríamos todos los comentarios en el fichero, no sólo los que *documentan* la función en la que estamos interesados...

## Refinando la idea

Por un lado, tenemos el nombre de la función para la que queremos obtener la ayuda, en `${FUNCNAME[@]}`.
Por otro lado, tenemos la ruta al fichero donde se encuentra la función en `${BASH_SOURCE[@]}` (con `realpath`).

Si buscamos el nombre de la función -de nuevo, usando `grep`-, obtenemos la línea en la que se encuentra.
En la documentación de `grep` vemos que podemos usar [`-n`](https://www.gnu.org/software/grep/manual/grep.html#index-_002dn) (o la versión larga, `--line-number`) para obtener el *número de línea* en el que se se produce *match*.

Por ejemplo:

```bash
$ grep -n 'saludo' saludo.sh
3:saludo() {
4:    # saludo es una aplicación que permite imprimir
5:    # un saludo de bienvenida o de despedida
10:    saludo_args $@
83:saludo_args() {
84:    # saludo_args solo puede tener subcomandos o --help
114:saludo $@
```

Tenemos que refinar el patrón de búsqueda para `grep`; al definir la función en Bash, usamos su nombre seguido de `()`:

```bash
$ grep -n 'saludo()' saludo.sh 
3:saludo() {
```

Y ahora, filtramos la salida de `grep` para quedarnos sólo con el número de línea donde se produce la coincidencia:

```bash
$ grep -n 'saludo()' saludo.sh | cut -d ':' -f1
3
```

> El fichero podría contener otras *copias* de la cadena 'saludo()', por ejemplo, como parte de la documentación.
> Por simplificar, suponemos que no es así.

## Mostrar el contenido de un fichero a partir de una línea

La documentación o ayuda de la función se encuentra tras la definición de la misma.
Podemos usar [`tail -n`](https://man7.org/linux/man-pages/man1/tail.1.html) para especificar el número de líneas desde el inicio del fichero; si empezamos desde la *siguiente línea* a la devuelta por `grep`:

```console
$ ❯ tail -n +4 saludo.sh 
    # saludo es una aplicación que permite imprimir
    # un saludo de bienvenida o de despedida
    # 
    # Subcomandos:
    # - bienvenida
    # - despedida
    saludo_args $@
}

bienvenida() {
    ...
```

Bien, en el sentido de que se muestran las líneas que queremos... Mal, porque se muestra hasta el final del fichero, que no es lo que queremos...

## Limitar la salida sólo a las líneas de documentación de la función

En un primer momento, pensé en usar `grep #` de nuevo, pero el problema es que `grep` encuentra **todas** las coincidencias en lo que queda de fichero (desde la línea en la que se encuentra la definición de la función hasta el final del fichero).

Si usamos `tail -n +4 saludo.sh | grep -n '#'`, obtenemos una lista de todas las líneas en las que se producen coincidencias con '#':

```console
$ ❯ tail -n +4 saludo.sh | grep -n '#'                 
1:    # saludo es una aplicación que permite imprimir
2:    # un saludo de bienvenida o de despedida
3:    # 
4:    # Subcomandos:
5:    # - bienvenida
6:    # - despedida
11:    # Muestra el mensaje de bienvenida: 'Hello World!'
12:    # Parametros:
...
```

Observando la salida, vemos que los números de línea en los que se encuentran los `#` que documentan la función son consecutivos hasta la línea 6, y que después **saltan** hasta la línea 11, donde empieza la documentación de otra función... Podemos usar ese *salto* en los números como indicador del final de las líneas que *documentan* la función.

> Si hay una o más líneas en blanco entre la definición de la función y la documentación, ésta no empezará en la línea 1, sino en la 2 ó la 3... Para simplificar, asumo que es 1.
> En cualquier caso, los números de línea de la documentación de una función son consecutivos... Del mismo modo, si hay líneas en blanco tras las líneas de la *documentación*, igualmente se produce un salto en los números de línea en los que `grep` encuentra `#`.

## Almacenando los números de línea en un *array*

Para poder analizar los números de línea y encontrar dónde se produce *el salto*, tenemos que almacenarlos en un *array*.
Sin embargo, la aproximación directa:

```console
$ read -a doc <<< $(tail -n +4 saludo.sh | grep -n '#' | cut -d ':' -f1)
$ echo ${doc[*]}
1
```

... no funciona :(

Tenmos que usar `xargs`:

```console
$ read -a doc <<< $(tail -n +4 saludo.sh | grep -n '#' | cut -d ':' -f1 | xargs echo)
$echo ${doc[*]}
1 2 3 4 5 6 11 12 13 14 22 31 33 35 39 42 43 52 53 60 81 83 109
```

## Detectando el *salto* en los números de línea

Recorremos el *array* comparando cada elemento del *array* con el *siguiente* elemento en la lista:

```console
help_line=${doc[0]}
for match in ${doc[@]:1}; do
    if [[ $match != $((help_line+1)) ]]; then
        help_ends=$help_line
        break
    fi
    help_line=$match
done
```

Si el *siguiente* elemento del *array* no es el *elemento anterior `+1`*, tenemos *el salto*.

Así, hemos conseguido identificar la última línea que corresponde a la *documentación*, en nuestro caso, la línea 6 tras la definición de la función.

Lo único que queda pendiente ahora es imprimir las líneas de la documentación, entre el número siguiente a donde se encuentra la definición de la función (donde empieza la documentación) y la última línea de *documentación* de la función.

Usamos una combinación de `tail` y `head`, para quedarnos sólo con las primeras *n* líneas de la salida de `tail`:

```console
$ tail -n +4 saludo.sh | head -n 6
    # saludo es una aplicación que permite imprimir
    # un saludo de bienvenida o de despedida
    # 
    # Subcomandos:
    # - bienvenida
    # - despedida
```

## Retoques finales

Ya sólo queda hacer que la salida tenga mejor aspecto; al llamar a la función `print-help`, como tenemos el nombre la función, podemos añadir un *encabezado* como `Documentation for 'saludo':`, y filtrar los `#` con `sed` para obtener:

```console
$ ./saludo.sh --help
Help for 'saludo':
    saludo es una aplicación que permite imprimir
    un saludo de bienvenida o de despedida
    
    Subcomandos:
    - bienvenida
    - despedida
```

## Resumen

Podemos emular el comportamiento de aplicaciones como `git`, `kubectl`, etc en Bash, de manera que se muestre *ayuda* general para la aplicación o específica para cualquiera de sus *comandos* en Bash.

Usamos `${FUNCNAME[@]}` para obtener el nombre de la función que implementa el *comando* para el que se ha añadido el *flag* `--help`.
Usamos también `${BASH_SOURCE[@]}` para obtener el nombre del fichero en el que se encuentra la función.

Usando `grep`, `tail` y `head`, extraemos las líneas correspndientes a la *documentación* de la función.

El único requisito es que la *documentación* de la función esté en un *bloque continuo* de comentarios.
