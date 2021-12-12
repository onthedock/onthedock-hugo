+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["go", "programming", "gophercises"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/go.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# {{< youtube FjxK1KJ7iq4 >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}

title=  "Quiz Game, 1a parte (Ejercicios en Go) #gophercises"
date = "2021-12-12T09:59:29+01:00"
+++
El primer ejercicio consiste en crear un programa que haga un "examen" o prueba de conocimientos al usuario.

El programa debe cargar las preguntas y respuestas de un fichero CSV, presentarlas al usuario y mostrar la puntuación de preguntas respondidas correctamente sobre el total al finalizar la prueba.

En la segunda parte, además, estableceremos un límite de tiempo.
<!--more-->

> Puedes revisar el vídeo de Jon Calhoun en YouTube: [Gophercises #1 - Quiz Game](https://youtu.be/FjxK1KJ7iq4)

## Mi solución (parte 1)

Visualizo el vídeo de Jon para hacerme una idea de los paquetes a usar y tomar sus indicaciones como punto de partida. A partir de las ideas expresadas sobre cómo o porqué hacer algo, elijo cómo solucionar el problema por mi cuenta, por lo que la solución que describo aquí es realmente **mi solución**. En GitHub puedes encontrar soluciones propuestas por [otros alumnos](https://github.com/gophercises/quiz/tree/master/students) que han realizado estos mismos gophercises.

## Opciones de la línea de comandos

Uno de los requerimientos del problema es que el usuario puede especificar el fichero de problemas con el que realizará la prueba.

Para ello, debemos aceptar un parámetro de la forma: `-csv customquiz.csv`.

Usaremos el paquete [`flag`](https://pkg.go.dev/flag) de la biblioteca estándar de Go.

```go
package main

import (
    "flag"
    "fmt"
)

func main() {
    csvFile := flag.String("csv", "problems.csv", "especifica un fichero de problemas en formato CSV")
    flag.Parse()
    fmt.Println("Fichero especificado", *csvFile)
}
```

Definimos un *argumento*, con valor por defecto `problems.csv` seguido de un pequeño texto de ayuda.

Para que el paquete `flag` procese todas las opciones definidas, ejecutamos `flag.Parse()`.

Al usar el paquete `flag` automáticamente obtenemos la opción de "ayuda"o *usage*, usando `-h` o `-help`:

```bash
$ ./quiz -help
Usage of ./quiz:
  -csv string
        especifica un fichero de problemas en formato CSV (default "problems.csv")
```

De esta forma, el usuario puede obtener ayuda sobre cómo usar el programa.

Validamos que si el usuario especifica un fichero, se usa el proporcionado por el usuario:

```bash
$ ./quiz -csv hola.csv
Fichero especificado hola.csv
$ # Si no se especifica un fichero, se usa el definido por defecto
$ ./quiz
Fichero especificado problems.csv
```

## Abrir el fichero CSV

Una vez especificado el fichero de problemas, ahora tenemos que abrirlo para leer su contenido. Para ello, usamos el paquete [`os`](https://pkg.go.dev/os).

```go
package main

import (
    "flag"
    "fmt"
    "os"
)

func main() {

    csvFile := flag.String("csv", "problems.csv", "especifica un fichero de problemas en formato CSV")
    flag.Parse()
    fmt.Println("Fichero especificado", *csvFile)

    file, err := os.Open(*csvFile)
    if err != nil {
        fmt.Printf("No se ha podido abrir el fichero %s.\nError %s\n", *csvFile, err.Error())
        os.Exit(1)
    }
    _ = file
}
```

Abrimos el fichero especificado o mostramos un error si no puede abrirse (y finalizamos el programa con un código de error).

> Para que el programa compile, asignamos `file` a `_` (para evitar el error del compilador de que la variable `file` no se usa).

```bash
$ ./quiz -csv custom.csv
Fichero especificado custom.csv
No se ha podido abrir el fichero custom.csv.
Error open custom.csv: no such file or directory
$ echo $?
1
```

Ya hemos visto que si no se encuentra el fichero, se muestra un error. Ahora vamos a abrirlo y leer su contenido.

## Leer el fichero CSV

Sabemos que es un fichero CSV, por lo que usamos el paquete [`csv`](https://pkg.go.dev/encoding/csv).

Para abrir el fichero, creamos un nuevo *Reader* usando `csv.NewReader`, que devuelve un *slice* bidimensional de *slices* y un error; comprobamos si se ha producido un error antes de seguir y mostrar el resultado de leer el fichero:

> Hemos aprovechado para introducir constantes para los *exit codes*:

```go
package main

import (
    "encoding/csv"
    "flag"
    "fmt"
    "os"
)

const (
    QUIZ_FILE_NOT_FOUND         int = 1
    ERROR_READING_QUIZ_CSV_FILE int = 2
)

func main() {

    csvFile := flag.String("csv", "problems.csv", "Fichero de problemas en formato 'pregunta,respuesta' (CSV)")
    flag.Parse()

    file, err := os.Open(*csvFile)
    if err != nil {
        fmt.Printf("Error al abrir el fichero %s.\n%s\n", *csvFile, err.Error())
        os.Exit(QUIZ_FILE_NOT_FOUND)
    }

    r := csv.NewReader(file)
    problems, err := r.ReadAll()
    if err != nil {
        fmt.Printf("Error al leer el archivo %s.\n%s\n", *csvFile, err.Error())
        os.Exit(ERROR_READING_QUIZ_CSV_FILE)
    }
    fmt.Println(problems)
}
```

La salida del programa muestra cómo se ha importado el fichero `problems.csv`:

```bash
./quiz
[[5+5 10] [7+3 10] [1+1 2] [8+3 11] [1+2 3] [8+6 14] [3+1 4] [1+4 5] [5+1 6] [2+3 5] [3+3 6] [2+4 6] [5+2 7]]
```

> Jon explica que la opción de leer todo el contenido del fichero CSV *de golpe* (`problems, err := r.ReadAll()`) es válida para este tipo de problema porque difícilmente el fichero será tan grande que pueda causar problemas de memoria.

## Crear un nuevo tipo de variable `problem`

Jon indica en el vídeo que en este punto es una buena idea crear un nuevo tipo de variable para los *problemas* (a la que llama `problem`).

El motivo es hacer el programa más mantenible; al convertir el conjunto *pregunta,respuesta* en un tipo específico, desacoplamos la entrada de los datos del procesado posterior que se realice. Es decir, si en el futuro en vez de usar un CSV usamos un fichero en JSON, sólo tendremos que modificar el `csv.NewReader` por un nuevo *reader*; las funciones que trabajen con el tipo `problem` no deberán modificarse, porque siempre esperarán `problem.question` y `problem.answer`. Si siguiéramos trabajando con `[][]string`, deberíamos modificar todas las funciones para ajustarlas al nuevo *formato* del fichero de entrada de preguntas.

En nuestro caso, definimos:

```go
type pregunta struct {
    enunciado  string
    respuesta string
}
```

A continuación, creamos una función que *parsea* las preguntas contenidas en el fichero de problemas y las convierte a este nuevo tipo:

```go
func parselines(lines [][]string) []pregunta {
    var res []pregunta
    res = make([]pregunta, len(lines))
    for i, problema := range lines {
        res[i] = pregunta{
            enunciado: problema[0],
            respuesta: strings.Trim(problema[1], " "),
        }
    }
    return res
}
```

Tenemos un *slice* de *problemas* (cada una de las líneas del CSV). La función `parselines` toma el *slice* de *slices* y devuelve un *slice* de `pregunta` (el nuevo tipo creado).

Creamos el *slice* de `pregunta`, con el tamaño del número de líneas del fichero:

```go
res := make([]pregunta, len(lines))
```

Recorremos el *slice* de *slices* con un bucle `for` y asignamos el primer valor a `pregunta.enunciado` y el segundo a `pregunta.respuesta`. De esta forma, pasamos de un *slice* de *slices* a un *slice* de `pregunta` (`res []pregunta`).

> Para evitar que se *cuelen* espacios extras en el campo de *respuesta* del fichero CSV, usamos la función `strings.Trim()`.

Llamamos a la función `parselines(lines)` después de leer el contenido del fichero CSV y mostramos su contenido:

```go
problemas := parselines(lines)
fmt.Println(problemas)
```

El resultado es similar a la salida anterior, pero ahora `problemas` es un *slice* de tipo `pregunta`:

```go
[{5+5 10} {7+3 10} ...]
```

## Mostrar las preguntas al usuario

Empezamos mostrando todas las preguntas *del tirón*, iterando sobre todos los problemas importados del CSV:

```go
...
problemas := parselines(lines)

for i := range problemas {
    fmt.Printf("Pregunta %d:\t %s =\n", i+1, problemas[i].enunciado)
}
```

Como los *slices* están indexados empezando por el 0 y lo normal es que las preguntas estén numeradas a partir del 1, sumamos 1 al índice `i`.

El resultado es:

```bash
$ ./quiz
Pregunta 1:      5+5 =
Pregunta 2:      7+3 =
Pregunta 3:      1+1 =
Pregunta 4:      8+3 =
Pregunta 5:      1+2 =
Pregunta 6:      8+6 =
Pregunta 7:      3+1 =
Pregunta 8:      1+4 =
Pregunta 9:      5+1 =
Pregunta 10:     2+3 =
Pregunta 11:     3+3 =
Pregunta 12:     2+4 =
Pregunta 13:     5+2 =
```

## Esperar la respuesta del usuario

Antes de pasar a la siguiente pregunta, debemos solicitar al usuario su respuesta.

Hay varias formas de hacerlo; la más sencilla, es con alguna de las variantess del paquete `fmt` : `Scan`, `Scanf` o `Scanln`. Otra opción (más robusta, pero también más complicada) es usando un *reader*, del paquete `bufio`.

```go
for i := range problemas {
    fmt.Printf("Pregunta %d:\t %s =\n", i+1, problemas[i].enunciado)

    r := bufio.NewReader(os.Stdin)
    res, err := r.ReadString('\n')
    if err != nil {
        fmt.Printf("Error al leer la respuesta %d.\n%s", i+1, err.Error())
        os.Exit(ERROR_NO_ENTIENDO_RESPUESTA)
    }
    if problemas[i].respuesta == strings.Trim(res, "\n ") {
        fmt.Println("Respuesta correcta")
    }
}
```

Declaramos un nuevo *reader* y usamos el método `r.ReadString('\n')` para leer la entrada del usuario (cuando pulsta `Enter`).

Esta opción nos permite leer respuestas que incluyen espacios, o comas, si las respuestas los contienen.

Una vez leída la respuesta por parte del usuario, debemos compararla con la respuesta contenida en el fichero CSV.

> ¡Ojo! La respuesta leída por el *reader* incluye el caracter final `\n`.

Podemos usar la función `strings.Trim(res, "\n ")` para eliminar espacios sobrantes y el propio caracter `\n` (tal como habíamos hecho para filtrar los espacios extras en el fichero CSV).

## Registro de preguntas acertadas (puntuación)

Antes de empezar el bucle con el que recorremos todas las preguntas en el fichero CSV, inicializamos la puntuación de la prueba a 0.

Después de que el usuario proporcione su respuesta, la comparamos con el valor procedente del fichero CSV; si coinciden, incrementamos la puntuación.

Tras el bucle, mostramos la puntuación acumulada:

> He movido la obtención de la respuesta del usuario a una función independiente llamada `getUserAnswer() string {}`.

```go
var puntuacion int = 0
for i := range problemas {
    fmt.Printf("Pregunta %d:\t %s =\n", i+1, problemas[i].enunciado)

    if problemas[i].respuesta == getUserAnswer() {
        puntuacion++
    }
}
fmt.Printf("Ha respondido %d respuestas correctas de %d preguntas.\n", puntuacion, len(problemas))
```

## ¡Objetivo conseguido! (+ *refactor*)

Una vez conseguido el objetivo primario descrito por Jon (importar las preguntas y respuestas del fichero CSV, presentarlas al usuario, obtener sus respuestas y calcular la puntuación final), movemos a funciones específicas las diferentes partes del código.

De esta forma podríamos definir tests para cada una de las funciones, comprobando que no se ven afectadas por modificaciones posteriores que realicemos sobre el código.

El código lo he subido a [onthedock/gophercicios/01-quiz](https://github.com/onthedock/gophercicios/tree/main/01-quiz) en GitHub.

P.S. También hay un fichero de problemas adicionales (`capitals.csv`) para validar que el programa también funciona con respuestas que contienen múltiples espacios.

Ahora, a por la segunda parte del ejercicio: [Quiz Game, 2a parte (Ejercicios en Go) #gophercises]({{< ref "211212-gophercicio-1-the-quiz-parte-2.md" >}})
