+++
draft = false

categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["go", "golang"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/go.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/
# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}

title=  "CSV Parser en Go"
date = "2026-02-24T18:25:05+01:00"
+++
Tenemos varios procesos que se basan en *parsear* datos proporcionados por los usuarios en un fichero CSV, validarlos y "hacer *algo* con ellos".

Los *scripts* que se encargan de estos procesos se pueden dividir en dos categorías: sencillos pero "delicados" y robustos pero complicados.

Uno de nuestros *scripts* de validación ha crecido y crecido para incorporar todo tipo de transformaciones y validaciones... Pero como suele pasar en estos casos, la evolución ha sido *orgánica*, es decir, sin planificación... Y aunque es perfecto para la tarea que realiza, es difícil aprovechar todo lo que hemos desarrollado para poder reutilizarlo en cualquiera de los otros procesos y así, mejorarlos.

El problema no son las funciones que implementan una u otra función de validación; el problema es que hay que hay una relación invisible entre los datos en el CSV y las funciones que deben aplicarse a cada campo... Al no estar documentada esa relación, mantener los *scripts* resulta complicado si no se está familiarizado con la tarea para la que fueron diseñados.

En vez de seguir ampliando el problema, he desarrollado una aplicación que espero que pueda aplicarse de forma "universal" en todos los procesos y acabar con el problema de una vez por todas.

Y la solución que se me ocurrió fue la de definir un *schema* para el CSV.
<!--more-->
## *Schema*

> Como estoy desarrollando el *parser* en Go, los tipos de las variables, etc hacen referencia a este lenguaje de programación.

La versión actual del *schema* define 4 propiedades para cada campo del fichero CSV; todas son opcionales, menos el campo `Name`:

- `Name`: nombre del campo; es decir, del encabezado de la columna en la que se encuentra en el fichero CSV.
- `Transformations`: es un *slice* de `map[string][]string` que actúa sobre el propio `Field` que model el campo del fichero CSV. Es decir, cada *transformation* se identifica por la *key* del *map*, que es el nombre de la función que implementa la transformación que se aplica sobre el valor del CSV. Los elementos del *slice* de *string* son parámetros para la función. Las *transformations* modifican el valor obtenido del CSV.
- `Validations`: es un *slice* de `map[string][]string`, como las *transformations*. En este caso, la función que implmenta la validación devuelve un  `error` si la validación falla.
- `Multivalued`: es un *string*; si no está vacío, el primer caracter se considera el *separador* para dividir el contenido del campo en múltiples valores.

## Leer el CSV

El proceso es siempre el mismo: leer el fichero CSV, validar/transformar los datos y exportarlos a algún tipo de formato (estructurado).

Para leer el contenido del CSV he usado el *package* [`csv`](https://pkg.go.dev/encoding/csv) de la biblioteca estándard.
Se trata de una solución más robusta que leer el fichero usando Bash y que simplifica el uso de diferentes *separadores* para los campos del fichero CSV.
El paquete modela el fichero CSV como un `[][]string`; al principio pensaba que necesitaría añadir una propiedad en el *schema*  para especificar el *tipo* de dato en cada campo... Pero para aquellos casos en los que el contenido de la *celda* es un número (o un `bool`), usando paquetes como `strconv` he podido solucionar todas las necesidades de conversión con las que me he encontrado.

La aplicación lee el fichero CSV (completamente, porque se trata de ficheros pequeños) e itera sobre cada fila en el fichero.

Cada una de las filas la modelo como un *slice* de `Field`; cada `Field` es una instancia del *struct* del que se compone el *schema*.

### Número de campos y campos vacíos

Como los ficheros [CSV](https://en.wikipedia.org/wiki/Comma-separated_values) no se ajustan a ningún standard universal, uno de los problemas habituales con los que nos encontramos es que es necesario implementar comprobaciones para validar que el número de campos en cada fila coincide con el número esperado... A veces el fichero contiene "comas" en ficheros que usan la coma como delimitador de campos, en otros casos un campo vacío se interpreta incorrectamente y todos los valores se desplazan "un columna"...

Para complicar más las cosas, MS Excel permite abrir ficheros CSV (separados por comas) pero los guarda usando como separador de los campos ";", lo que "confunde" a nuestro *script* (si estamos esperando valores separados por ','), etc...

El fichero CSV también puede contener líneas en blanco (sólo saltos de línea) o no contener una salto de línea como "final del fichero"...

MS Excel, además, incluye "líneas que incluyen sólo separadores" si se añade un valor a una fila y después se borra...

El paquete `csv` en Go simplifica muchas de esas casuísticas; convenientemente, el paquete también permite definir qué separador se usa como "," y otras modificaciones de manera sencilla.

### BOM!

Un *efecto colateral* de usar MS Excel para añadir datos al fichero CSV es que Excel  añade **caracteres invisibles** al inicio del fichero. Estos caracteres se conocen como *BOM: [Byte Order Mark](https://en.wikipedia.org/wiki/Byte_order_mark)*.

Como indica la Wikipedia, usando UTF-8 no es **necesario ni recomendado** usar estos caracteres.

Curiosamente, el equipo de Go incluye a los miembros que definieron UTF-8 y consideran el uso del BOM como una *abominación*, por lo que Go no facilitan la vida de aquellos que usan BOM:

> The Go team includes the original designers of UTF-8, and they consider BOMs an aBOMination. They are reluctant to do anything to make life easier for people who use BOMs. :-)
> <https://groups.google.com/g/golang-nuts/c/OToNIPdfkks>

En mi caso, me encontré con el problema porque la aplicación comprueba que el *nombre del campo* (el encabezado de la "columna") en el fichero CSV coincide con el valor definido en el fichero de *schema*.

Durante un gran número de pruebas, usé ficheros de texto (con diferentes separadores) para realizar las pruebas... Pero en un momento dado, abrí el fichero (¡y lo guardé!) con Excel... Y a partir de ese momento la validación de los campos en el CSV falló. Dado que el BOM es **invisible**, el mensaje de error era `'micampo' no es igual que 'micampo'`... Y claro, no entendía nada.

Afortunadamente, se me ocurrió comprobar la longitud del campo y pude identificar esos *bytes* de más...

## Estructura de la aplicación

Inicialmente pensé en escribir un comando `parsecsv` y ¡listo! Pero finalmente decidí usar [Cobra](https://cobra.dev/) y escribir una aplicación de línea de comandos con funcionalidades adicionales (como por ejemplo, generar un fichero CSV a partir de un *schema*).

Por el momento, la aplicación tiene dos *comandos*:

- `parse`: tomando como entrada un fichero CSV y un *schema*, inyecta los valores del CSV en plantillas para generar la salida
- `gencsv`: tomando un fichero de *schema* como entrada, genera un fichero CSV basado en los campos definidos

## Aplicando transformaciones y validaciones

La aplicación es un gran *loop*, que recorre cada fila en el fichero CSV y, para cada campo, lo transforma y valida...
Si cualquiera de los campos falla la validación, el error devuelto se guarda en un *slice*...

Cuando se acaba de procesar el fichero, los errores que se han encontrado se guardan en un fichero de *log* para inspeccionar e informar al cliente de los problemas.

## Inyectando los valores del CSV en plantillas

Todo el trabajo de transformación y validación de los datos del CSV es para poder generar la representación en JSON de unos objetos que enviaremos a una API. Es como en Kubernetes, donde definimos objetos de la API de Kubernetes en ficheros YAML que enviamos al clúster usando `kubectl`. Solo que en nuetro caso, de momento, nos quedamos con la generación de la representación de los objetos de la API (en formato JSON), sin enviarla a la API.

Como no controlamos la API, no tenía sentido generar un *struct* para cada uno de los objetos... Aunque éso hubiera facilitado enormemente el proceso, tenía dos problemas en mente. Por un lado, al margen de suponer una cantidad de trabajo importante, significaba que el *parser* únicamente se podría usar con ficheros CSV destinados a crear este tipo de objetos, pero no otros... Además, si el equipo responsable de la API modifica alguno de los campos de cualquiera de esos objetos, deberíamos actualizar el *parser* y recompilar la aplicación...

Pero resulta que soy la única persona del equipo (por ahora) con interés en Go... Eso significa que, en ese futuro, yo sería el único capaz de actualizar la aplicación...

Así que tomé la decisión de "esconder" el código de Go en un binario que sea aplicable a cualquier fichero CSV para generar cualquier tipo de "salida estructurada". Para ello, en vez de *volcar* *structs* en JSON con el formato esperado por la API, opté por hacer que la aplicación usara el paquete [text/template](https://pkg.go.dev/text/template) de Go para generar los ficheros resultantes.

La idea es que, una vez que la aplicación ha validado los valores de una fila del fichero CSV, *inyecta* los valores en los *templates* indicados.

## ¿No *struct*? No problem

La gran mayoría de ejemplos de uso de *plantillas* en Go usan *structs*. De hecho, el ejemplo de uso del paquete también usa un *struct*.

Sin embargo:

> Templates are executed by applying them to a data structure. Annotations in the template refer to elements of the data structure (typically a field of a struct or a key in a **map**) to control execution and derive values to be displayed.

Es decir, podemos usar un `map` en vez de un *struct* como "estructura de datos".

Un *map* se ajusta perfectamente a mi caso de uso: en general, quiero *mapear* un valor a un "campo" del CSV.

En el caso de un sólo valor en el CSV, para el campo `micampo`, la *estructura de datos* sería `map["micampo"]="mivalor"`. Y en el caso de que, tras la transformación, se haya convertido el contenido del campo CSV en múltiples valores, `map["micampo"]=[]string{"valor1", "valor2}`.

Por tanto, la *estructura de datos* que necesito es un `map[string][]string` para el caso general.

La contrapartida es que, aunque el *map* sólo contenga un valor, para poder acceder a él en el *template*, es necesario iterar sobre todos los *posibles* valores del *map*... Esto hace que el acceso a los valores en los *templates* sea menos *intuitivo* que en el caso de un *struct*:

```go
...
"spec": {
    "displayName": "{{ range $i, $v := .micampo }}{{ $v }}{{ end }}"
}
```

## Creando ficheros JSON

Como indicaba más arriba, en algunos casos, el campo sólo contiene un valor (que siempre es un *string*).

Gracias a la forma en la que JSON codifica los diferentes tipos de datos, para *convertir* un *string* a otro tipo de dato, sólo hay que poner o quitar las comillas:

- "mi valor" --> "mi valor" (string en JSON)
- "true" --> true (*bool* en JSON)
- "42" --> 42 (*number* in JSON)

Para las *arrays*, si el valor contenido en un campo contiene múltiples valores, la aplicación los separa (en Go) y se *insertan* en el *template* como un *array* mediante un bucle (en el *template*).

Un ejemplo de ésto sería:

- "jon.snow@winterfell.com sansa.stark@winterfell.com" --> `[]string{"jon.snow@winterfell.com", "sansa.stark@winterfell.com"}`

Y en el template:

```json
{
    "contacts": [ {{ range $i,$v := .contacts }}{{ if ne $i 0 }},{{ end }}"{{ $v }}"{{ end }} ]
}
```

## Generando valores (no presentes en el CSV)

En algunos de los objetos a generar, es necesario generar un identificador único. Por ejemplo, un UUID.

Podemos conseguirlo mediante [FuncMap](https://pkg.go.dev/text/template#FuncMap) o [Funcs](https://pkg.go.dev/text/template#Template.Funcs).

En Go, definimos una función como:

```go
func genUUID() string {
    return uuid.NewString()
}
```

En mi caso, como quiero usar la función en cualquiera de los *templates*, uso `FuncMap`:

```go
tpl, err := template.New("tpl").Funcs(funcMap).Parse(string(tplBytes))
```

Finalmente, en el *template*:

```json
{
    "id": "{{ uuid }}"
}
```

## Plugins

En la versión actual, las funciones de transformación y validación de los valores del CSV forman parte de la aplicación.

```go
func validationRegEx(fld Field, args []string) error {
    regex := args[0]
    re, err := regexp.Compile(regex)
    if err != nil {
        return err
    }
    if found := re.FindAllString(fld.Value, -1); found != nil {
        return nil
    }

    return fmt.Errorf("%s: '%s' does not match provided regular expression '%s'", fld.Name, fld.Value, regex)
}
```

Sin embargo, estoy trabajando en un sistema de *plugins*, de manera que pueda reducir estas funciones en el código al mínimo, y realizar validaciones (y transformaciones) a través la ejecución de aplicaciones externas (como *scripts* en Bash, por ejemplo).

La *key* del campo *Transformation* (y *Validation*) en el fichero de *schema* se interpretan como el nombre del *plugin* a ejecutar.

A continuación, enviamos el valor del campo actual, tal y como se ha leído desde el CSV.

El resto de valores, se consideran los *parámetros* para la función.

La salida en `stdout` del *plugin* se captura para poder insertar el valor *transformado*/*validado* en los *templates*.

Si el *exit code* del *plugin* es diferente a 0, se considera que el valor no es válido; el mensaje de error se obtiene de *stderr* y se guarda en el fichero de *log*.

Todavía tengo que realizar algunas pruebas más, pero los primeros *tests* han sido prometedores...

## Objetivo cumplido

El fichero de *schema* permite:

- indicar cuál es el número de campos esperado en el fichero CSV
- cómo debe llamarse cada campo
- indica si es necesario transformar el valor leído del CSV (por ejemplo, convertir el valor a minúsculas)
- indica si el valor del campo cumple determinadas condiciones (por ejemplo, es tiene formato *email*)
- indica si el valor del campo debe considerarse como *múltiples valores*; si es así, qué debe usarse como "delimitador" para *separar* los valores.

Los *templates* permiten generar ficheros de cualquier tipo a partir de los valores obtenidos del CSV.

Finalmente, usando *plugins*, la aplicación puede extenderse para incorporar nuevas validaciones/transformaciones sin necesidad de modificar la aplicación.
Por el momento, las funciones para extender los *templates* siguen estando *en el código* de la aplicación (como la generación de un UUID).

De esta forma, la aplicación puede usarse para generar ficheros estructurados a partir de datos obtenidos de cualquier fichero CSV; lo único que hay que hacer es definir el *schema* para el CSV y los *templates* para la salida.

## Siguientes pasos

Además de completar el sistema de *plugins* y realizar la presentación/formación al equipo, la idea es extender las funcionalidades de la aplicación.
Por ejemplo, añadir un nuevo comando para generar el *esqueleto* de un fichero de *schema* a partir de un CSV.

Por otro lado, también continuaré *refinando* la aplicación *cliente* que completa el proceso: una vez generados los ficheros JSON, *requester* (esta otra aplicación) lee los ficheros y lanza las peticiones a la API... Como los objetos generados son de diferentes tipos y cada uno debe *enviarse* a un *endpoint* diferente, con unos *headers* diferentes, etc, *requester* inspecciona el objeto y realiza todo el proceso de forma automática... Pero los detalles los dejo para otra entrada ;)
