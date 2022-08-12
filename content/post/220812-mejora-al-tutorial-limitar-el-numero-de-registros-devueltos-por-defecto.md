+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["go", "programming", "Mejora al tutorial 'Building a Web App with Go and SQLite'"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/go.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/

# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}
# YouTube           {{< youtube w7Ft2ymGmfc >}}
# Gist              {{< gist username 7896402 >}}
# Highlight         {{< highligth language >}}...{{< /highlight >}}
# Twitter           {{< tweet user="SanDiegoZoo" id="1453110110599868418" >}}

title=  "Mejora al tutorial 'Building a Web App with Go and SQLite': limitar el número de registros devueltos por defecto"
date = "2022-08-12T08:05:44+02:00"
+++
En la mayoría de tutoriales sobre cómo construir una API en Go (incluído el [tutorial](https://go.dev/doc/tutorial/web-service-gin#all_items) de la documentación oficial de Go), el primer *endpoint* que se describe es el que usa el método `GET` y que recupera **todos** los registros de la base de datos.

Sin embargo, en el mundo real, las APIs devuelven un número limitado de registros y un *índice*; en una nueva consulta, se puede obtener un nuevo conjunto de resultados  (y un nuevo índice), etc. Esto es así porque el resultado de la consulta con `GET` puede, potencialmente, devolver un número elevado de registros.

En el tutorial [Building a Web App with Go and SQLite](https://www.allhandsontech.com/programming/golang/web-app-sqlite-go/), se incluye una limitación *hardcodeada* en el código para evitar, precisamente, que se devuelvan todos los valores en la base de datos de ejemplo (1000 registros).

En este artículo, voy a mostrar cómo obtener el valor desde la *queryString* para que sea configurable desde la llamada a la API.
<!--more-->
La función que se invoca para obtener los registros de la base de datos incluye un parámetro llamado `count` que indica el número máximo de registros a devolver. El problema es que este valor está fijado en el código y no se puede cambiar.

## Situación de partida

Partimos del código del tutorial de Jeremy Morgan [Building a Web App with Go and SQLite](https://www.allhandsontech.com/programming/golang/web-app-sqlite-go/), en la parte [Part 2. Connect to our Database](https://www.allhandsontech.com/programming/golang/web-app-sqlite-go-2/).

El [código original](https://github.com/JeremyMorgan/PersonWeb/blob/main/main.go#L36) es:

```go
func getPersons(c *gin.Context) {

 persons, err := models.GetPersons(10)
 checkErr(err)

 if persons == nil {
  c.JSON(http.StatusBadRequest, gin.H{"error": "No Records Found"})
  return
 } else {
  c.JSON(http.StatusOK, gin.H{"data": persons})
 }
}
```

Como ves, se llama a `models.GetPersons(10)` especifica de forma fija 10 registros.

En la función  [`func GetPersons(count int) ([]Person, error)`](https://github.com/JeremyMorgan/PersonWeb/blob/main/models/person.go#L30) el valor de `count` se usa para limitar los registros devueltos por la consulta a la base de datos:

> Lo muestro en dos líneas por claridad

```go
rows, err := DB.Query("SELECT id, first_name, last_name, email, ip_address
                       FROM people LIMIT " + strconv.Itoa(count))
```

De esta forma, `http://<URL>/api/v1/person` devuelve siempre 10 registros (los 10 primeros, de hecho).

## Proporcionar el número de registros a devolver

Nuestro objetivo es hacer que en vez del valor fijo `10`, se pueda pasar en la llamada un número variable de registros.

La idea es que el usuario pueda especificar el valor del parámetro `count` al llamar a la API. Si el usuario especifica un valor, devolvemos ese número de registros. Si no lo especifica, devolvemos el número de registros por defecto. Para evitar un gran impacto en nuestra API, limitamos el número máximo de registros que el usuario puede solicitar en cada petición.

El usuario puede especificar el número de registros devueltos mediante el parámetro `count` de la siguiente forma:

```shell
http://<URL>/api/v1/person?count=10
```

> En mi versión del código, la función [`func getPersons(c *gin.Context)`](https://github.com/JeremyMorgan/PersonWeb/blob/main/main.go#L36) del tutorial original la he movido al paquete `handlers` y se llama `func GetPersons(c *gin.Context)` (con mayúsculas, para que se exporte).

Empezamos definiendo el número máximo de registros que devolverá la API y el número de registros devueltos por defecto.

```go
 // Limit the number of records returned
 var max_count int = 10
 // Default value
 var count int = 10
```

A continuación, comprobamos si el usuario ha indicado el parámetro `count` en la URL. El valor obtenido desde la *queryString* es de tipo `string`, por lo que lo convertimos a `int`.

```go
// If no "count" parameter is provided, we return the count value
 if c.Query("count") != "" {
  var conv_err error
  count, conv_err = strconv.Atoi(c.Query("count"))
  if conv_err != nil {
   log.Printf("[error] error getting count from queryString (default to %d). error: %s", count, conv_err.Error())
  }
 }
```

Si conseguimos convertirlo a `int` sin que se produzca un error, validamos que el valor proporcionado por el usuario no es mayor que el máximo valor que hemos establecido.

```go
// Return max_count (at most)
 if count > max_count {
  log.Printf("[warning] requested %d records (returning max: %d)", count, max_count)
  count = max_count
 }
```

Finalmente, llamamos a la función `models.GetPersons(count)` con el valor `count`, en vez de con el valor "fijo" `10`:

```go
persons, err := models.GetPersons(count)
//...
```

El resto de la función es igual que en el tutorial original.

El resultado final es:

```go
func GetPersons(c *gin.Context) {
 // Limit the number of records returned
 var max_count int = 10
 // Default value
 var count int = 10

 // If no "count" parameter is provided, we return the count value
 if c.Query("count") != "" {
  var conv_err error
  count, conv_err = strconv.Atoi(c.Query("count"))
  if conv_err != nil {
   log.Printf("[error] error getting count from queryString (default to %d). error: %s", count, conv_err.Error())
  }
 }

 // Return max_count (at most)
 if count > max_count {
  log.Printf("[warning] requested %d records (returning max: %d)", count, max_count)
  count = max_count
 }

 persons, err := models.GetPersons(count)

 if err != nil {
  log.Printf("[error] %v", err.Error())
  c.JSON(http.StatusBadRequest, gin.H{"message": "error"})
 }

 if persons == nil {
  c.JSON(http.StatusOK, gin.H{"message": "no records found"})
  return
 } else {
  // log.Printf("[info] returned %v", persons)
  c.JSON(http.StatusOK, gin.H{"message": persons})
 }
}
```

## Resultado del cambio

Si el usuario no especifica el parámetro `count` en la petición, el resultado es el mismo que con el código original del tutorial:

```shell
$ curl localhost:8080/api/v1/person     
{"message":[
  {"id":1,"first_name":"Glyn","last_name":"Quaife","email":"gquaife0@edublogs.org","ip_address":"252.74.16.5"},
  {"id":2,"first_name":"Kathrine","last_name":"Aizkovitch","email":"kaizkovitch1@bandcamp.com","ip_address":"255.1.189.50"},
  {"id":3,"first_name":"Gaven","last_name":"Allanby","email":"gallanby2@cloudflare.com","ip_address":"33.223.203.230"},
  {"id":4,"first_name":"Clara","last_name":"Vince","email":"cvince3@cloudflare.com","ip_address":"179.132.154.90"},
  {"id":5,"first_name":"Rozalie","last_name":"Stein","email":"rstein4@sitemeter.com","ip_address":"43.208.221.109"},
  {"id":6,"first_name":"Britni","last_name":"Pacquet","email":"bpacquet5@paypal.com","ip_address":"232.111.115.116"},
  {"id":7,"first_name":"Roselin","last_name":"Aleso","email":"raleso6@a8.net","ip_address":"0.219.112.14"},
  {"id":8,"first_name":"Parrnell","last_name":"Castellaccio","email":"pcastellaccio7@woothemes.com","ip_address":"156.168.236.20"},
  {"id":9,"first_name":"Jobie","last_name":"McGiveen","email":"jmcgiveen8@tinyurl.com","ip_address":"124.84.5.0"},
  {"id":10,"first_name":"Lyn","last_name":"Kupper","email":"lkupper9@adobe.com","ip_address":"10.173.222.145"}
]} 
```

Sin embargo, si se especifica un valor para `count`:

```shell
$ curl "localhost:8080/api/v1/person?count=3"                                                                                                                1 ↵
{"message":[
  {"id":1,"first_name":"Glyn","last_name":"Quaife","email":"gquaife0@edublogs.org","ip_address":"252.74.16.5"},
  {"id":2,"first_name":"Kathrine","last_name":"Aizkovitch","email":"kaizkovitch1@bandcamp.com","ip_address":"255.1.189.50"},
  {"id":3,"first_name":"Gaven","last_name":"Allanby","email":"gallanby2@cloudflare.com","ip_address":"33.223.203.230"}
]}
```

También verificamos que si el usuario indica un valor para `count` superior a lo definido en `max_count`, sólo se devuelve el número de registros especificado por defecto para `count` (que hemos establecido en `10`):

```shell
$  curl "localhost:8080/api/v1/person?count=750"
{"message":[
  {"id":1,"first_name":"Glyn","last_name":"Quaife","email":"gquaife0@edublogs.org","ip_address":"252.74.16.5"},
  {"id":2,"first_name":"Kathrine","last_name":"Aizkovitch","email":"kaizkovitch1@bandcamp.com","ip_address":"255.1.189.50"},
  {"id":3,"first_name":"Gaven","last_name":"Allanby","email":"gallanby2@cloudflare.com","ip_address":"33.223.203.230"},
  {"id":4,"first_name":"Clara","last_name":"Vince","email":"cvince3@cloudflare.com","ip_address":"179.132.154.90"},
  {"id":5,"first_name":"Rozalie","last_name":"Stein","email":"rstein4@sitemeter.com","ip_address":"43.208.221.109"},
  {"id":6,"first_name":"Britni","last_name":"Pacquet","email":"bpacquet5@paypal.com","ip_address":"232.111.115.116"},
  {"id":7,"first_name":"Roselin","last_name":"Aleso","email":"raleso6@a8.net","ip_address":"0.219.112.14"},
  {"id":8,"first_name":"Parrnell","last_name":"Castellaccio","email":"pcastellaccio7@woothemes.com","ip_address":"156.168.236.20"},
  {"id":9,"first_name":"Jobie","last_name":"McGiveen","email":"jmcgiveen8@tinyurl.com","ip_address":"124.84.5.0"},
  {"id":10,"first_name":"Lyn","last_name":"Kupper","email":"lkupper9@adobe.com","ip_address":"10.173.222.145"}
]}
```

En los logs del servidor, el intento queda registrado:

```shell
...
2022/08/12 11:30:20 [warning] requested 750 records (returning max: 10)
[GIN] 2022/08/12 - 11:30:20 | 200 |    2.869505ms |             ::1 | GET      "/api/v1/person?count=750"
```

## Conclusión

Con esta pequeña modificación del código, hemos mejorado nuestra API, permitiendo al usuario seleccionar el número de registros a devolver por defecto (dentro de unos márgenes aceptables que no comprometan la estabilidad del servidor).

Seguimos devolviendo siempre los primeros resultados de la base de datos; la siguiente modificación estará encaminada a que el usuario pueda obtener un determinado número de resultados a partir de un registro determinado. Para ello, en una futura entrada, modificaremos la función `getPersonById`.
