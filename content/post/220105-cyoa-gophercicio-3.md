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

title=  "Elige tu propia aventura (Ejercicios en Go) #gophercises (teaser)"
date = "2022-01-05T11:31:21+01:00"
+++
Ayer dediqué una buena parte del día al tercer ejercicio de [Gophercises](https://gophercises.com/) (puedes ver el vídeo de Jon en YouTube: [Gophercises #3 - Choose Your Own Adventure Book (via website)](https://www.youtube.com/watch?v=DPCGXJLFlPU)).

Estuve tomando notas sobre el vídeo de solución de Jon al ejercicio, pausando el vídeo, reflexionando en cómo atacaba cada parte del problema, etc...

Hoy he vuelto a revisar las notas con la intención de publicarlas, como hice con el ejercicio anterior ([Quiz Game, 1a parte]({{< ref "211212-gophercicio-1-the-quiz-parte-1.md" >}}) y [Quiz Game, 2a parte]({{< ref "211212-gophercicio-1-the-quiz-parte-2.md" >}})). Sin embargo, quiero aprovechar el *flow* (y el tiempo libre) para repasar con calma la documentación de los diferentes paquetes usados en el ejercicio, revisar el tema de los *constructores* y otros aspectos más teóricos que Jon usa con total naturalidad y que a mí me resultan completamente marcianos...

<--more-->

## Ejercicio: Contruir una versión web *Elige tu propia aventura*

El ejercicio consiste en construir una versión web de los libros de [Elige tu propia aventura](https://es.wikipedia.org/wiki/Elige_tu_propia_aventura).

Jon proporciona un fichero JSON (`gopher.json`) con los diferentes capítulos de la historia y las opciones para ir al siguiente punto del *libro* tras cada capítulo (en función de lo que elije el lector).

El primer reto consiste en convertir el fichero JSON en algo manipulable desde la aplicación. Para ello, Jon define un par de [*struct*](https://gobyexample.com/structs), en vez de uns *struct* con una estructura complicada:

```go
type Chapter struct {
    Title      string   `json:"title"`
    Paragraphs []string `json:"paragraphs"`
    Options    []Option `json:"options"`
}

type Option struct {
    Text    string `json:"text"`
    Chapter string `json:"chapter"`
}
```

### Debugging

En el fichero `gopher.json` los campos del fichero JSON **no corresponden** con los definidos en estos *struct*. Jon inicialmente llamó `arc` a los `chapter` y `story` a los `paragraphs`...

Esto provocó que, aunque durante todo el desarrollo inicial del *parser* del fichero JSON se mostrara por consola la *struct*, **no me fijé** en que algunos de los campos estaba vacíos. En realidad, no le di importancia porque, en la definición del ejercicio se comentaba que `Options` podía estar vacío (al final de una historia, por ejemplo).

El caso es que no fue hasta *mucho* después, al empezar a mostrar la *aventura* en el navegador, que descubrí que había algo que fallaba: el título y las opciones tras cada capítulo se mostraban, pero no el contenido del capítulo en sí (el contenido de `Paragraphs`).

{{< figure src="/images/220105/debugging.jpg" width="100%" >}}

La parte buena fue que estuve haciendo mucho *debugging*, empezando desde la publicación web, hacia atrás, hasta dar con el problema (a base de paciencia y `log.Println()`), revisando los vídeos de Jon, las soluciones de otros estudiantes... Hasta descubrir dónde estaba la causa raíz y solucionarla.

## El momento *wtf*: `NewHandler`

Cuando llegamos al momento de *publicar* en la web la historia de *elige tu propia aventura*, la proposición es aparentemente sencilla: tenemos que construir una función que acepte una *Story* como entrada y que devuelva algo que pueda ser *servido* vía web, un `http.Handler`.

Así que cuando Jon empieza a crear primero, la función `func NewHandler (s Story) http.Handler`, parece que tiene sentido... Pero a continuación crea un nuevo tipo: `handler`

```go
type handler struct {
    s Story
}
```

Y no contendo con ello, un *método* asociado al *handler* `func (h handler) ServeHTTP(w http.ResponseWriter, r *http.Request)`.

En este punto me dejé llevar; por un lado, era consciente *grosso modo* de lo que estaba haciendo Jon, pero sin los conocimientos/experiencia necesarios para poder entenderlo *a fondo*.

Justo tras la publicación vía web descubrí el problema de que el cuerpo de cada capítulo no se mostraba en el navegador, aunque el resto funcionaba correctamente (y no se mostraba ningún error por consola)... Mi primera idea era que había cometigo algún error con todo el tema del *handler*; pero el sin errores y fallando únicamente en el *cuerpo* del capítulo, no parecía probable.

Como comentaba más arriba, estuve un rato buscando qué pasaba hasta dar con la solución (y descubrir que no tenía nada que ver con el *handler*).

{{< figure src="/images/220105/ihateprogramming.png" width="100%" >}}

Revisando la documentación, un [`http.Handler`](https://pkg.go.dev/net/http#Handler) responde a una petición HTTP. `http.Handler` es un *interface*, que define el *método* (¿?) `ServeHTTP(ResponseWriter, *Request)`, que es justo lo que Jon implementa en `func (h handler) ServeHTTP(w http.ResponseWriter, r *http.Request)`

## Siguientes pasos

Como apuntaba al principio, creo que lo mejor es asentar las bases antes de seguir adelante con nuevos ejercicios, repasando los puntos que más me costaron ayer y consultando la documentación (y el resto de fuentes) para entender mejor el ejercicio de ayer.

Algunos temas introducidos por Jon hacia el final del vídeo son *de nivel*, como las *functional options*, pero sin duda siempre es mejor aprender los patrones *correctos* desde el principio que no tener que deshacerse de *malos hábitos* más adelante...

Probablemente siga el ejemplo de Jon y divida las notas en cada uno de los pasos que llevan a la solución del problema. En YouTube el [vídeo sobre este ejercicio](https://youtu.be/DPCGXJLFlPU) dura algo más de una hora; en el sitio Gophercises.com, Jon lo ha dividio en *secciones*, en las que se trata cada uno de los puntos de manera individual: *Overview, Parging th JSON, Refactoring, Building the http.Handler, Parsing Paths, Styling the HTML, Custom Templates, Funcional Options, Custom Paths y Wrap UP*.

En cualquier caso, ahora toca repasar.
