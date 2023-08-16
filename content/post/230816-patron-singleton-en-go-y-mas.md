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

title=  "Patrón *singleton* en Go (y alguna cosa más)"
date = "2023-08-16T20:25:52+02:00"
+++
Uno de los problemas que he encontrado en mi *reinterpretación* de la API que uso en el trabajo ha sido la conexión con la base de datos.

Siguiendo las buenas prácticas, mi intención era reutilizar el cliente a la base de datos. En vez de usar una variable global, que suele ser la aproximación *recomendada*, guardaba la *struct* en el *contexto* de Gin.

Sin embargo, el contexto se propaga para una misma petición, pero no se mantiene entre peticiones... Así que para cada nueva petición que recibía la API se creaba un nuevo *client* 😞.

Todo lo relacionado con la base de datos se encuentra en su propio paquete, por lo que tendría sentido crear una variable "global" dentro del paquete...

Sin embargo, seguía quedando pendiente el tema de cerrar la conexión con la base de datos al finalizar la aplicación...

En esta entrada explico la solución que quiero probar (ya veremos si funciona 😉, parece que sí).
<!--more-->

## Una sola variable "global"

En el paquete `dbclient`, defino:

```go
type DB struct {
    myConnectionString string
}
```

También defino una variable ("global" en el paquete `dbclient`):

```go
var db *DB
```

Sólo quiero que haya una variable `db`; para éso sirve exactamente el patrón *singleton* (como referencia, [Singleton in Go](https://refactoring.guru/design-patterns/singleton/go/example#example-1)), de [Refactoring Guru](https://refactoring.guru/).

La manera *idiomática* de implementarlo en Go es usando el paquete `sync`:

```go
var once sync.Once

func GetDB() *DB {
    if db == nil {
        once.Do(
            func() {
                db = &DB{
                    myConnectionString: "start",
                }
                log.Printf("initializing database connection to %s\n", db.myConnectionString)
            })
    } else {
        log.Printf("database connection already initialized to %s\n", db.myConnectionString)
    }
    return db
}
```

Si existe una instancia de `db`, la devuelvo; si no, la inicializo.

Para comprobar que funciona:

```go
package main

import (
    "math/rand"

    "github.com/xaviatwork/db/db"
)

func main() {
    for i := 1; i < 10; i++ {
        db.GetDB()
    }
}
```

Ejecutando la aplicación:

```console
$ go run main.go 
2023/08/16 18:48:43 initializing database connection to start
2023/08/16 18:48:43 database connection already initialized to start
2023/08/16 18:48:43 database connection already initialized to start
2023/08/16 18:48:43 database connection already initialized to start
2023/08/16 18:48:43 database connection already initialized to start
2023/08/16 18:48:43 database connection already initialized to start
2023/08/16 18:48:43 database connection already initialized to start
2023/08/16 18:48:43 database connection already initialized to start
2023/08/16 18:48:43 database connection already initialized to start
```

Como vemos de la salida de la ejecución, gracias a `sync.Once()`, la primera vez se inicializa `db["myConnectionString]="start"`, pero en las siguientes ejecuciones no se vuelve a inicializar.

## Cerrando la conexión al salir de la aplicación

Otro de los puntos que quería tratar era el de cerrar la conexión al finalizar la aplicación.
Esto generalmente se consigue con un `defer` en `main`.

Anteriormente no sabía cómo afrontar este escenario, ya que la variable se definía en `dbclient`, no en `main`...

Ahora, simplemente:

```go
func main() {
    for i := 1; i < 10; i++ {
        db.GetDB()
    }
    defer db.GetDB().Close()
}
```

Y en el paquete `dbclient`:

```go
func (db *DB) Close() {
    log.Println("closing database connection")
    db = nil
}
```

Al ejecutar la aplicación:

```console
$ go run main.go 
2023/08/16 19:25:38 initializing database connection to start
2023/08/16 19:25:38 database connection already initialized to start
2023/08/16 19:25:38 database connection already initialized to start
2023/08/16 19:25:38 database connection already initialized to start
2023/08/16 19:25:38 database connection already initialized to start
2023/08/16 19:25:38 database connection already initialized to start
2023/08/16 19:25:38 database connection already initialized to start
2023/08/16 19:25:38 database connection already initialized to start
2023/08/16 19:25:38 database connection already initialized to start
2023/08/16 19:25:38 database connection already initialized to start
2023/08/16 19:25:38 closing database connection
```

Finalmente, como validación final, quiero comprobar que puedo modificar la propiedad `myConnectionString` (privada) desde `main`; para ello, he definido un *setter*:

```go
func (db *DB) SetString(connectionString string) {
    db.myConnectionString = connectionString
}
```

Y para validarlo:

```go
func main() {
    s := []string{"s7hobd7hAs", "cXnLvQm3hg", "o7LqFOeH9K", "xfO09Rk6EF", "Tx20FPFHX1", "KICv5ci9K9", "BrdlL0IPLw", "rNBLzzXj8S", "hb2AozseHH", "aIMnLjr2dU"}
    for i := 1; i < 10; i++ {
        db.GetDB().SetString(s[rand.Intn(len(s))])
    }
    defer db.GetDB().Close()
}
```

La ejecución muestra que, efectivamente, no hay problema en establecer `myConnectionString` a través de:

```console
$ go run main.go 
2023/08/16 19:31:35 initializing database connection to start
2023/08/16 19:31:35 database connection already initialized to BrdlL0IPLw
2023/08/16 19:31:35 database connection already initialized to o7LqFOeH9K
2023/08/16 19:31:35 database connection already initialized to BrdlL0IPLw
2023/08/16 19:31:35 database connection already initialized to hb2AozseHH
2023/08/16 19:31:35 database connection already initialized to rNBLzzXj8S
2023/08/16 19:31:35 database connection already initialized to KICv5ci9K9
2023/08/16 19:31:35 database connection already initialized to hb2AozseHH
2023/08/16 19:31:35 database connection already initialized to xfO09Rk6EF
2023/08/16 19:31:35 database connection already initialized to KICv5ci9K9
2023/08/16 19:31:35 closing database connection
```
