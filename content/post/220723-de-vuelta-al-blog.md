+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["blog"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/MabelAmber-mini.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/

# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}
# YouTube           {{< youtube w7Ft2ymGmfc >}}
# Gist              {{< gist username 7896402 >}}
# Highlight         {{< highligth language >}}...{{< /highlight >}}
# Twitter           {{< tweet user="SanDiegoZoo" id="1453110110599868418" >}}

title=  "De vuelta al Blog"
date = "2022-07-23T11:33:09+02:00"
+++
Ha pasado algo más de un mes desde la última entrada en el blog... Así que en vez de escribir una entrada como si no hubiera pasado nada, he decidido crear ésta entrada para comentar qué he estado haciendo...
<!--more-->
En estas semanas ha habido un poco de todo; pasé un fin de semana con una fiebre muy alta, como si fuera un resfriado fuerte que resultó ser COVID... Estuve teletrabajando desde casa hasta que mi pareja y yo volvimos a dar negativo en los tests...

El *aislamiento* en casa hizo que me perdiera la fiesta de cumpleaños de mi madre, pero no ha habido otros efectos colaterales, así que en resumen, bien.

Hace un par de semanas estuve de vacaciones, haciendo alguna salida en bici y tomando el sol en la playa o para ser más precisos, refugiado bajo la sombrilla ;)

## Go

Sigo aprendiendo Go; he *ojeado* alguno de los múltiples libros gratuitos que se pueden encontrar sobre Go (échale un vistazo a la [Free Ebook Foundation](https://ebookfoundation.org/), por ejemplo)...

> Disclaimer: rant is coming next ...

La situación es parecida a lo que sucede con Kubernetes; libros desactualizados y que sólo cubren o los conceptos básicos o un "proyecto" específico.

En general, los libros dedican una cantidad de páginas desorbitada -IMHO- a explicar cómo instalar Go en Linux, Mac y Windows...Además, muchos son anteriores a la introducción o *popularización* de los *módulos* (v1.11), por lo que a continuación se explica cómo crear la estructura de carpetas, configurar la variable `$GOPATH`, etc...

En función del libro, algunos empiezan explicando qué es una variable y otros conceptos que es probable que el lector ya conozca, al menos a nivel conceptual. Otros se enfocan en detallar, incluso con ejemplos, **cada uno** de los tipos disponibles en Go, los condicionales, los bucles... Algunos consideran los punteros, las interfaces y las *go routines* conceptos avanzados y no los cubren en absoluto.

Otros libros usan un *proyecto* como hilo conductor para *guiar* el aprendizaje. En este caso, en mi opinión, el problema suele ser que sólo se muestra cómo resolver un determinado requerimiento (que en general no se describe). El fin didáctico del proyecto se pierde rápidamente; en vez de aprender *sobre el lenguaje*, se muestra *cómo se resuelve* un problema concreto...

Mi crítica es la falta de razonamiento, la ausencia de explicaciónes del **porqué** se ha decidido usar un enfoque y no otro, la elección de un paquete como [Cobra](https://github.com/spf13/cobra) en vez de usar [flag](https://pkg.go.dev/flag), de la biblioteca *standard*, [Mux](https://github.com/gorilla/mux) en vez de [Gin](https://gin-gonic.com/) (o viceversa), etc.

No hay revisión de *pros* y *contras*, buenas prácticas que guíen la toma de decisiones o motivaciones didácticas orientadas a facilitar el aprendizaje de forma incremental...

En entradas anteriores ya alabé los [ejercicios](https://onthedock.github.io/tags/gophercises/) de [John Calhoun](https://www.calhoun.io/building-gophercises/), precisamente, por explicar porqué resolvía un ejercicio de una manera y no otra o [Learn Go with Tests](https://quii.gitbook.io/learn-go-with-tests/) por no explicar explicar de nuevo lo que no hace falta explicar; para muestra, una frase que lo deja claro:

> `if` statements in Go are very much like other programming languages.

En cualquier caso, he estado *repasando* las bases (gracias a [golangbot.com](https://golangbot.com/)), en particular el tema de `structs` y los punteros, así como con el *framework* Gin para algunas ideas que tengo...

## Kubernetes

Aunque sigo *tocando* Kubernetes e intento mantenerme al día de las nuevas funcionalidades que se presentan en cada versión, dedicar más tiempo a Go ha significado reducir el tiempo que paso *cacharreando* con Kubernetes...

Mantengo *viva la llama* respondiendo alguna que otra pregunta en el foro oficial de Kubernetes; mi perfil es <https://discuss.kubernetes.io/u/xavi/>.

Justo antes de la pandemia planeaba empezar a asistir a algún *meet up* y quizás sea una buena forma de "re-engancharme" al *mundillo*...

Ya iré contando ;)
