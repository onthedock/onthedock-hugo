+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["go", "programming", "gophercises"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/go.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/

# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}
# YouTube           {{< youtube w7Ft2ymGmfc >}}
# Gist              {{< gist username 7896402 >}}
# Highlight         {{< highligth language >}}...{{< /highlight >}}
# Twitter           {{< tweet user="SanDiegoZoo" id="1453110110599868418" >}}

title=  "Aprendiendo a programar en Go... pasito a pasito"
date = "2022-01-29T09:56:58+01:00"
+++
El *gophercise* para crear una versión en Go de los libros de *Elige tu propia aventura* de la [entrada anterior]({{< ref "220105-cyoa-gophercicio-3.md" >}}) me hizo ver que debo asentar los conocimientos básicos sobre Go.

No me refieron tanto a saber qué es una variable, la sintaxis de un bucle `for` ni nada por el estilo; me refiero a la forma en la que *debe* programarse en Go...

<!--more-->

Supongo que es algo parecido a lo que había escuchado en Python sobre la forma *pythonic* de escribir código; del blog de Udacity, [What Is Pythonic Style?](https://www.udacity.com/blog/2020/09/what-is-pythonic-style.html):

> “pythonic” describes a coding style that leverages Python’s unique features to write code that is readable and beautiful.

Debido a las características intrínsecas del lenguaje, en Go se *debe programar* de una forma determinada; en *idiomatic go* (de [Effective Go](https://go.dev/doc/effective_go)):

> ... to write Go well, it's important to understand its properties and idioms. It's also important to know the established conventions for programming in Go, such as naming, formatting, program construction, and so on, so that programs you write will be easy for other Go programmers to understand.

## De vuelta a la casilla de salida... más o menos

Buscando algún recurso entre *nivel principiante* e *intermedio*, encontré [Learn Go with Tests](https://quii.gitbook.io/learn-go-with-tests/).

En la sección *Background*, [Chris James](https://twitter.com/quii) (el autor) explica cómo ha aplicado diferentes formas de enseñar Go en el pasado. En su experiencia, la forma más exitosa ha sido a través de [Go By Example](https://gobyexample.com/).

En cuanto a *cómo aprende él mismo*, se enfoca en explorar los conceptos y solificar las ideas con tests.

Esa idea de *explorar los conceptos y solidificar las ideas con tests* resonó en mí por diferentes motivos. Por un lado, como decía, quería revisitar los conceptos básicos de Go y aprender cómo usarlos adecuadamente. Por otro lado, aprender  Go y TDD (*test driven development*) *por el mismo precio* ;) me parecía una oferta imposible de rechazar.

Así que me lancé y hubo unos cuantos detalles que me convencieron de que estaba en el lugar adecuado para mí.

## Conviertiendo "Hello World" en un programa *testeable*

Usando el clásico *Hello World*, Chris explica cómo separar el código que escribimos, y que por tanto necesitamos *testear*, de los *efectos colaterales* en el mundo exterior.

En *Hello World*, nuestro código es el que "genera" el saludo "Hello World"; el efecto sobre el mundo exterior es que se imprime por pantalla. Si en vez de mostrar el mensaje por pantalla con un `fmt.Println()` quisiéramos enviarlo a un archivo, o guardarlo en una base de datos, etc, sólo deberíamos ocuparnos de esta parte, no del código que hayamos generado para crear el mensaje "Hello World".

Este enfoque, separando las diferentes partes del código es lo mismo que Jon muestra una y otra vez en [Gophercises](https://gophercises.com/); solo que allí lo comenta sin entrar en detalle.

Esta forma de *diseñar* el código es algo que debo aprender con respecto a la programación del mismo modo que lo he aprendido con respecto a la arquitectura de sistemas (mi lado *Ops*) o la gestión de servicios IT.

## *Go modules*

Otro de estos puntos básicos en los que tropiezo una y otra vez como novato que soy: no inicializar el módulo:

```bash
$ go test
go: cannot find main module; see 'go help modules'
```

*Learn Go with tests* no asume que has inicializado el módulo, así que explica porqué se muestra el error y cómo inicializar el módulo; es un detalle minúsculo -comparado con todo lo demás- pero sin duda me hizo ver que *Learn Go with tests* está escrito cuidando al máximo todos los detalles. Es importante resaltar que en [Go Environment](https://quii.gitbook.io/learn-go-with-tests/go-fundamentals/install-go#go-environment), el apartado anterior, ya se ha explicado que deben inicializarse los módulos en Go (v.16+).

Es difícil explicar la importancia -para mí- de ese detalle tan aparentemente minúsculo; pero en vez de sentirme frustado al encontrarme con un error inesperado cuando estás siguiendo un tutorial, el tutorial te explica de nuevo cómo y porqué se deben inicializar los módulos, como un profesor paciente que entiende que, como novato, es normal que se me olvide inicializarlo (por mucho que lo haya explicado en el apartado anterior).

Quizás todo se reduzca a que el detalle en sí insufla confianza: los errores con los que pueda toparme estarán explicados, no importa lo sencillos complicados que sean...

## No explicar lo que no hace falta volver a explicar

Explicando los detalles de la función `func TestHello(t *testing.T) {...}`:

> If statements in Go are very much like other programming languages.

Pues eso; en Go cambiará la sintaxis respecto a algún otro lenguaje con el que estés más o menos familizarizado; que si es necesario poner paréntesis o no alrededor de la condición, si va seguido de `then` o no, o lo que sea, pero un `if` funciona igual en Go que en BASH o Python... No es necesario explicar *qué* es un `if`.

*Move on, nothing to see here*...

## Explicar el proceso *general*

En la sección [Discipline](https://quii.gitbook.io/learn-go-with-tests/go-fundamentals/hello-world#discipline), se explica el proceso a seguir (y porqué es una buena idea):

- Escribir un test
- Hacer que sea compilable (eliminar errores de compilación)
- Ejecutar el test, **validando que falla** y que el mensaje que se muestra proporciona suficiente información de porqué lo hace.
- Escribir **sólo el código suficiente** para hacer que el test pase.
- [Refactorizar](https://en.wikipedia.org/wiki/Code_refactoring): modificar el código (haciendo que el test siga resultando en `PASS`).

Esto suena completamente *overkill* hasta que inicias un proyecto por tu cuenta, sin la red de seguridad de un tutorial con la solución.

En mi caso, he empezado con una aplicación tipo "lista de la compra". Como el primer paso es crear un test, por ejemplo, para una función como `AddItem`, hay que empezar a preguntarse cómo gestionar esta "lista de la compra" y cómo validar si se ha añadido un elemento correctamente...

Otro punto interesante es esa idea de "el mínimo código necesario" hace que te enfoques en soluciones sencillas, sin perder de vista que el objetivo es que funcione.

Así, una vez añadido un elemento, en la siguiente iteración decido que no se deben añadir elementos ya existentes... Creo un nuevo test y repito el ciclo.

A medida que vas creando tests, éstos construyen una *red de seguridad* que te protegen de romper lo que ya has construido, lo que -al menos en mi caso- me aporta confianza. Cada pequeña modificación (refactorizando el código o introduciendo nuevas funcionalidades) está cubierta con un test; ejecutando `go test` tengo *feedback* inmediato sobre si se ha roto algo o no.

Si se *rompe* algo, el hecho de que el mensaje del test proporcione información adecuada ayuda a saber qué se ha roto y (generalmente) porqué.

## Conclusión

Como se indica al final del *primer ejercicio* `Hello World`:

> In our case we've gone from `Hello()` to `Hello("name")`, to `Hello("name", "French")` in small, easy to understand steps.

Y esa es la clave: dar pasitos pequeños, sencillos y fáciles de entender.
