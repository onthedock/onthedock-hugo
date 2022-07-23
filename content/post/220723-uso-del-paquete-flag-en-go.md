+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["go", "programming"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/go.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/

# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}
# YouTube           {{< youtube w7Ft2ymGmfc >}}
# Gist              {{< gist username 7896402 >}}

title=  "Uso del paquete 'flag' en Go"
date = "2022-07-23T16:08:13+02:00"
+++
Una de puntos que siempre se destacan al trabajar con Go es lo completa que es la biblioteca estándar de funciones que proporciona el propio lenguaje.

[`flag`](https://pkg.go.dev/flag) proporciona funcionalidad para gestionar las opciones de las aplicaciones sin interfaz gráfica que se ejecutan desde la *línea de comandos* (CLI).

En esta entrada reviso cómo usar el paquete para los casos de uso más habituales.
<!--more-->
> Este artículo está inspirado en el artículo [How To Use the Flag Package in Go](https://www.digitalocean.com/community/tutorials/how-to-use-the-flag-package-in-go) de Digital Ocean publicado en Noviembre del 2019.

Cuando usamos aplicaciones desde la línea de comandos, como `git`, `kubectl`, `terraform`, `helm`, etc, usamos *flags* y *arguments* para proporcionar información o modificar el comportamiento de la aplicación.

> No he encontrado una traducción aceptable para *flag* ; para *argument*, lo más cercano sería *parámetro*, pero parece más enfocado a valores que se pasan a una función (consulta la definición en [The Tech Terms Dictionary](https://techterms.com/definition/parameter)).

En general, llamamos *flag* a las opciones que modificar el comportamiento simplemente por estar presentes (`-force`), mientras que los *arguments* o *parameters* proporcionan información adicional al comando que se ejecuta (como en `-source http://www.example.org`).

El paquete `flag` nos permite gestionar estos dos tipos de forma sencilla.

## Opciones (*parameters* o *arguments*)

Creamos una carpeta e inicializamos el módulo:

> LLamamos `doflag` al módulo en referencia al artículo de Digital Ocean ;)

```shell
mkdir doflag
cd doflag
go mod init doflag
```

La primera versión de la aplicación es:

```go
package main

import (
    "flag"
    "fmt"
)

func main() {
    var message string

    flag.StringVar(&message, "msg", "", "Message string")
    flag.Parse()

    fmt.Println(message)
}
```

Para definir "opciones" usando el paquete `flag`, podemos usar `flag.String` o `flag.StringVar` para definir una *opción* de tipo `string`; en el primer caso, el *flag* es un puntero a una variable del tipo indicado (en este caso, `string`):

> Uso *opciones* como nombre genérico para no tener que distinguir entre *flags* y *arguments*

```go
var message *string = flag.String("msg", "", "Message string")
```

En el segundo caso, declaramos una variable del tipo deseado y pasamos la referencia a `flag.StringVar()`:

```go
var message string
flag.StringVar(&message, "msg", "", "Message string")
```

Prefiero usar esta segunda forma porque así `message` contiene el valor (y no un puntero al valor), lo que como *n00b* me parece más sencillo ;)

Tras definir todas las *opciones* para la aplicación, usamos `flag.Parse()`.

Al ejecutar la aplicación, `flag.Parse` asigna los valores proporcionados desde la línea de comandos a las variables indicadas; a partir de ese momento podemos usarlas en la aplicación con normalidad.

Ejecutamos la aplicación (tras compilarla):

```shell
$ ./doflag

```

La aplicación *parece* que no hace nada pero en realidad está imprimiendo la cadena almacenada en `message`, que se debe proporcionar desde la CLI (y que por defecto está vacía).

Lo vemos más claramente modificando el **valor por defecto** de la *opción* `msg`:

```go
    flag.StringVar(&message, "msg", "Hello World!", "Message string")
```

Ejecutando de nuevo (tras compilar):

```shell
$ ./doflag 
Hello World!
```

Como ya habrás deducido, al definir una *opción* de CLI, pasamos el *identificador* de la opción (`msg`), el valor por defecto (`''` inicialmente y `'Hello World!` tras actualizar la aplicación) y la *descripción* de la opción...

Al usar el paquete `flag` éste proporciona una *opción* por defecto, `-h` o `-help` que muestra información sobre las *opciones* definidas para la aplicación:

```shell
$ ./doflag -help
Usage of ./doflag:
  -msg string
        Message string (default "Hello World!")
```

Como ves, se muestra el uso de las opciones definidas y sus valores definidos por defecto.

Si ejecutamos la aplicación especificando un mensaje para la aplicación mediante `-msg`:

```shell
$ ./doflag -msg "Hola que tal"
Hola que tal
```

## Flags

Otra de las opciones que tenemos para modificar el comportamiento de la aplicación es el uso de *flags*. Las *flags* corresponden a valores de tipo *bool* (*true* o *false*).

Añadimos el *flag* `-up`, con valor por defecto `false`, asociado a la variable `uppercase`:

```go
flag.BoolVar(&uppercase, "up", false, "Convert the message to uppercase")
```

El objetivo es que, si se proporciona el *flag* `-up`, la salida de la aplicación se muestre en mayúsculas:

```go
package main

import (
    "flag"
    "fmt"
    "strings"
)

func main() {
    var message string
    var uppercase bool

    flag.StringVar(&message, "msg", "Hello World!", "Message string")
    flag.BoolVar(&uppercase, "up", false, "Convert the message to uppercase")
    flag.Parse()

    if uppercase {
        message = strings.ToUpper(message)
    }
    fmt.Println(message)
}
```

Compilamos y ejecutamos la aplicación:

```shell
$ ./doflag 
Hello World!
```

Por defecto, el mensaje (con la opción por defecto de `-msg`) se muestra en minúsculas.

Al pasar `-up`:

```shell
$ ./doflag -up
HELLO WORLD!
```

Obviamente, la opción de usar `-msg` sigue disponible:

```shell
$ ./doflag -up -msg "Hola de nuevo"
HOLA DE NUEVO
```

Y el orden de las opciones no es relevante:

```shell
./doflag  -msg "Tanto monta, monta tanto..."  -up
TANTO MONTA, MONTA TANTO...
```

Automáticamente, el paquete `flag` ha actualizado la opción `-h` para incluir la nueva opción de la aplicación:

```shell
$ ./doflag -help
Usage of ./doflag:
  -msg string
        Message string (default "Hello World!")
  -up
        Convert the message to uppercase
```

Como las opciones de tipo *flag* (con valor `bool`) sólo provocan un efecto si están presentes, se considera que su valor por defecto es `false` (y por ello no se muestra el valor por defecto al usar `-help`).

## Formato de las opciones

En la documentación oficial del paquete `flag` se indica que las siguientes formas para las opciones son válidas:

```go
-flag
-flag=x
-flag x  // non-boolean flags only
```

El *formato largo* `--option` (con dos guiones) no está oficialmente soportado (o no se menciona en la documentación), sin embargo parece que también funciona:

```shell
$ ./doflag --up --msg="Las comillas son necesarias" 
LAS COMILLAS SON NECESARIAS
```

## Resumen

El paquete `flag` permite gestionar las opciones que se pasar a la aplicación desde la línea de comando de manera sencilla.

También permite gestionar *subcomandos* (como en `git clone ...`), con opciones diferentes para cada subcomando.

Existen paquetes de terceros que proporcionan todavía más funcionalidad, como [`cobra`](https://pkg.go.dev/github.com/spf13/cobra).

Sin embargo, en un gran número de casos, el paquete `flag` cubre todas las necesidades. Además, al formar parte de la biblioteca estándar, no es necesario importar ningún paquete adicional, lo que también puede ser un factor a tener en cuenta en determinadas situaciones.
