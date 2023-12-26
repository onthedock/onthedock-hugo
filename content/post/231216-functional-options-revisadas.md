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

title=  "Functional Options revisitadas"
date = "2023-12-26T18:30:56+01:00"
+++
Hace un tiempo escribí una artículo sobre el patrón de *functional options*: [Patrón de 'functional options']({{< ref "230708-funcional-options-pattern.md" >}}).

En este entrada reviso alguno de los errores que cometí al redactarla.
<!--more-->
## Refrescando la memoria: qué son las "functional options" y porqué deberías conocerlas

El patrón de *functional options* fue descrito inicialmente por Dave Cheney; puedes consultar el artículo original en [Functional options for friendly APIs](https://dave.cheney.net/2014/10/17/functional-options-for-friendly-apis).

Este patrón permite resolver el problema de definir una función con una [signatura](https://es.wikipedia.org/wiki/Signatura_(inform%C3%A1tica)) con un número variable de parámetros sin que éstos del mismo tipo. (Si fueran del mismo tipo, podríamos usar una función  [variádica](https://gobyexample.com/variadic-functions)).

El caso típico es tener que definir una función para definir un servidor (mira [net/http](https://pkg.go.dev/net/http#Server)); la lista de parámetros es enorme, lo que hace que sea inconveniente tener que pasar una lista larguísima de parámetros (ya que Go no permite omitir ningún parámetro al llamar a una función). Además, añadir (o eliminar) un nuevo parámetro cambiaría la *signatura* y rompería la retrocompatibilidad.

Las *functional options* resuelven los dos problemas mencionados en el párrafo anterior.

## *Functional options*

Siguiendo con el ejemplo del servidor web, definimos el `type Server` como:

```go
type Server struct {
    hostname string
    port     int
}
```

Inicialmente, sólo consideramos incluir el *host* y el *puerto*, pero más adelate sabemos que tendremos que incluir la opción de configurar TLS, por ejemplo.

En Go, las funciones son un tipo más; por tanto, podemos definir una función variádica que acepte un número variable de funciones como parámetros:

```go
func NewServer(...func(*Server)) *Server {
    // Do something
    return s
}
```

Las *opciones* para el *constructor* del `Server` son funciones; de ahí el nombre de *functional options*.

## Funciones de las *functional option*

Cada una de las *functional options* es una función que se ocupa de establecer una de las propiedades de nuestro tipo `Server`:

> Convencionalmente, se nombra a las *functional options* con `With` seguido del *parámetro* que configuran.

```go
func WithHostname(h string) func(*Server) {
    return func(s *Server) {
        s.hostname = h
    }
}
```

Del mismo modo, para configurar el puerto en el que escucha el servidor:

```go
func WithPort(p int) func(*Server) {
    return func(s *Server) {
        s.port = p
    }
}
```

## Constructor del `Server`

Ahora, cuando queremos crear una nueva instancia de `Server`, usamos el constructor:

```go
func NewServer(options ...func(*Server)) *Server {
    s := &Server{}

    for _, opt:= range options {
        opt(s)
    }

    return s
}
```

Creamos una nueva instancia de `Server` y a continuación, ejecutamos todas las funciones recibidas para configurar alguna de sus propiedades. Finalmente, devolvemos la instancia configurada.

## Ventajas de las *functional options*

### Valores por defecto

Al crear la instancia del `Server`, podemos proporcionar valores por defecto. Por ejemplo, `localhost` y puerto `80`; en este caso, aunque el usuario no establezca ninguna opción, el servidor se crea con unos valores *razonables*:

```go
func NewServer(options ...func(*Server)) *Server {
    s := &Server{
        hostname: "localhost",
        port:     80,
    }

    for _, opt:= range options {
        opt(s)
    }

    return s
}
```

### Ampliar las opciones disponibles

Si queremos incluir una nueva opción para `Server`, por ejemplo, activar TLS, podemos hacerlo sin modificar la *signatura* de la función `NewServer( ...func(*Server)) *Server`.

Actualizamos el tipo que describe el servidor:

```go
type Server struct {
    hostname string
    port     int
    tls      bool
}
```

Añadimos la *functional option* correspondiente:

```go
func WithTls(tls bool) func(*Server) {
    return func(s *Server) {
        s.tls = tls
    }
}
```

## Creando el nuevo servidor

Imaginemos que el paquete encargado de la creación y configuración del servidor `Server` se encuentra en el paquete `server`.

Para realizar la creación del servidor en `main`:

```go
package main

import "github.com/xaviatwork/funcopts/server"

func main() {
    srv := server.NewServer(
        server.WithPort(8080),
        server.WithTls(false),
    )

    // Do something with 'srv' to stop the IDE from
    // complaining that srv has been declared but not used
    _ = srv
}
```

Como no hemos especificado nada para `srv.hostname`, se asignará el valor por defecto, por ejemplo, `localhost`.

Si teníamos una aplicación que instanciaba otra versión de `Server`, seguirá funcionando sin problemas (en la versión anterior no usamos para nada la (entonces inexistente) nueva opción).

## Conclusión

El patrón de *functional options* permiten solucionar un problema habitual en Go, y lo hace de una manera relativamente sencilla y extremadamente potente a la vez que flexible.
