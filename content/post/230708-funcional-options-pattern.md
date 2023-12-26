+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["go"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/go.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/

# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}
# YouTube           {{< youtube w7Ft2ymGmfc >}}
# Gist              {{< gist username 7896402 >}}
# Highlight         {{< highligth language >}}...{{< /highlight >}}
# Twitter           {{< tweet user="SanDiegoZoo" id="1453110110599868418" >}}

title=  "Patrón de 'functional options'"
date = "2023-07-08T07:06:54+02:00"
+++
El *functional options pattern* permite crear un objeto con un número arbitrario de "opciones" manteniendo siempre la *signature* de la función que lo crea.

La idea original fue propuesta, si no estoy equivocado, por Dave Cheney allá por 2014 en el artículo [Functional options for friendly APIs](https://dave.cheney.net/2014/10/17/functional-options-for-friendly-apis). El artículo muestra múltiples maneras de *atacar* el problema y cómo las *functional options* es una de la soluciones más *sencillas*.

Imagina que quieres crear un objeto `pizza`. Pero no todo el mundo quiere la misma pizza; unos quieren masa fina, con extra de queso o con peperoni y champiñones, otros masa normal sin ningún extra o *topping* adicional, etc.

¿Cómo defines la función `NewPizza` para que puedas *satisfacer* a todos tus clientes? Tampoco quieres tener que cambiar la función cada vez que se añada una nueva opción o ingrediente a la pizza...

La solución son las *funcional options*.

> Actualización: 26/12/2023 {{< figure src="/images/exclamation-warning-round-yellow-red-icon.svg" width="100%" height="100" alt="notice" >}} Algunos aspectos de este artículo quizás no están del todo bien explicados; por ejemplo, las propiedades en `config` están en mayúsculas (exportadas), por lo que se puede establecer sin necesidad de *functional options*. La *signatura* de la función `NewClient` es incorrecta, pues no incluye que devuelve `(*DBClient, error)`... En vez de corregirla, he creado una entrada más concisa y sin errores conocidos, al menos por ahora.
>
> La nueva entrada es [Functional Options revisitadas]({{< ref "231216-funcional-options-revisadas.md" >}})

<!--more-->
## Contexto

Hace un tiempo comenté cómo había implementado el *cliente* para la herramienta de gestión del [estado de la configuración  (CMDB)](https://en.wikipedia.org/wiki/Configuration_management_database) en la entrada [Cliente en Go para la CMDB Updater Tool API]({{< ref "221126-cliente-en-go.md" >}}).

El siguiente paso es, cómo no, intentar implementar también la API con la que interacciona este cliente, la aplicación que gestiona la base de datos en la que se guarda el estado de la CMDB.

Todo lo relacionado con la interacción con la base de datos quiero que esté en su propio paquete.
Así que uno de los problemas a resolver era crear un objeto que encapsulara todo lo relacionado con la base de datos y reutilizarlo en todas las interacciones con el *backend*.

El cliente de la base de datos require un *contexto*, el identificador del proyecto, la colección... Para insertar un nuevo documento en la base de datos se require, además, el documento a insertar.

Así que en unos casos tendría que pasar tres parámetros, en otros cuatro... Demasiado complicado.

## Functional options

Las *funcional options* resuelven el problema creando un objeto adicional: un *struct* de configuración.

Empezamos por el *struct* que contiene el objeto cliente que pasaremos a las funciones que interaccionan con la base de datos.

```go
type DBClient struct {
    dbc *firestore.Client
    ctx context.Context
    config
}
```

Como vemos, insertamos el *struct* de configuración, que en mi caso es:

```go
type config struct {
    ProjectId  string
    Collection string
}
```

Para establecer cada una de estas "opciones" definimos una función (de ahí lo de *functional options*):

```go
func WithProjectId(projectid string) func(*DBClient) {
    return func(dbc *DBClient) {
        dbc.ProjectId = projectid
    }
}

func WithCollection(collection string) func(*DBClient) {
    return func(dbc *DBClient) {
        dbc.Collection = collection
    }
}
```

Finalmente, definimos la función que crea un nuevo cliente para la base de datos:

```go
func NewClient(options ...func(*DBClient)) {
    dbclient := &DBClient{}

    for _, option := range options {
        option(dbclient)
    }

    dbclient.ctx = context.Background()

    c, err := firestore.NewClient(dbclient.ctx, dbclient.ProjectId)
    if err != nil {
        return nil, err
    }
    dbclient.dbc = c

    return dbclient, nil
}
```

La función `NewClient` admite un número variable de parámetros de tipo `func(*DBClient)`, especificado por los `...`. Esto es una [función *variádica*](https://gobyexample.com/variadic-functions).

El bucle `for _, option := range options` se encarga de llamar cada una de las funciones que se han pasado como parámetros y cada una de ellas, establece una opción del cliente.

A la hora de instanciar el cliente, usamos:

```go
func main() {
    dbc, err := NewClient(
        WithProjectId("test-project"),
        WithCollection("my-collection"),
    )
    // ...
}
```

Por un lado, en una función variádica, todos los argumentos "variádicos" son opcionales. Así que podría llamar a la función `NewClient` sin pasar ninguna *opción*:

```go
func main() {
    dbc, err := NewClient()
    // ...
}
```

O sólo alguna de ellas:

```go
func main() {
    dbc, err := NewClient(
        WithCollection("backup"),
    )
    // ...
}
```

Si en el futuro quiero añadir alguna opción adicional, **no afecta al código existente**.

Imagina que quiero añadir un *timeout* para la creación del cliente (si se supera ese tiempo, consideraré que hay algún problema de conexión y lo intentaré más tarde).

Lo único que tendría que hacer es ampliar el *struct* de configuración:

```go

```go
type config struct {
    ProjectId  string
    Collection string
    Timeout    int
}
```

Y añadir la correspondiente *functional option*:

```go
func WithTimeout(timeout int) func(*DBClient) {
    return func(dbc *DBClient) {
        dbc.Timeout = timeout
    }
}
```

Como los parámetros de una función variádica son opcionales, las funciones `NewClient` existentes no generan un error porque les *falte* un parámetro; si queremos que un cliente aproveche la nueva opción de *timeout*, la añadimos como cualquier otra opción:

```go
func main() {
    dbc, err := NewClient(
        WithCollection("remote-collection"),
        WithTimeout(3),
    )
    // ...
}
```
