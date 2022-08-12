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

title=  " Mejora al tutorial 'Building a Web App with Go and SQLite': Devolver los registros posteriores al especificado"
date = "2022-08-12T12:00:52+02:00"
+++
En la entrada [Mejora al tutorial 'Building a Web App with Go and SQLite': limitar el número de registros devueltos por defecto](< ref "220812-mejora-al-tutorial-limitar-el-numero-de-registros-devueltos-por-defecto.md">) modificamos el código original del tutorial de Jeremy Morgan [Building a Web App with Go and SQLite](https://www.allhandsontech.com/programming/golang/web-app-sqlite-go/) para que el usuario pudiera especificar el número de resultados devueltos al consultar la API a través del parámetro `count`: `http://<URL>/api/v1/person?count=15`.

El problema es que siempre se devuelven las entradas empezando por la de Id más bajo (habitualmente, `1`).

En esta entrada, modificamos la función `getPersonById` para introducir también el parámetro `count` y que se devuelvan `count` resultados **a partir del Id especificado**.
<!--more-->

Como comentaba en la entrada [Mejora al tutorial 'Building a Web App with Go and SQLite': limitar el número de registros devueltos por defecto](< ref "220812-mejora-al-tutorial-limitar-el-numero-de-registros-devueltos-por-defecto.md">), en el mundo real las APIs devuelven un determinado número de resultados y un índice (o un *paginador*) que permite solicitar el *siguiente* conjunto de resultados... Podemos repetir el proceso hasta que la API nos informe que no hay más resultados disponibles.

El problema es que `models.GetPersons(count int)` sólo acepta el número de resultados a retornar, y no *desde qué entrada*, por lo que siempre devuelve el mismo conjunto de resultados.

Una forma de solucionar este problema sería modificando la función `GetPersons(count int)` para que admita un parámetro adicional: el número de registro desde el que empezar a retornar los resultados... Pero eso es precisamente lo que hace la función `GetPersonById` (aunque sólo devuelve 1 registro).

Modificaremos el comportamiento de `GetPersonById` para aceptar también un parámetro `count`, que será el número de registros a devolver (incluyendo al especificado por el `Id`).

El resultado final es que el usuario pueda solicitar mediante `http://<URL>/api/v1/person/5?count=10` los siguientes 10 registros al indicado por el `Id=5`.

> En cierto modo, con esta modificación, la función `GetPersons` sería un caso particular de `GetPersonById`, en el que siempre especificamos `Id=1`.

## Modificación del código

Como antes, definimos unos valores por defecto; en este caso, el valor por defecto de `count` es `1` (devolver sólo el registro con el `Id` solicitado):

```go
 // Limit the number of records returned
 var max_count int = 10
 // Default value
 var count int = 1
```

El resto del código es igual al de la entrada anterior; en primer lugar, validamos si el usuario ha especificado un valor para el parámetro `count`; si es así, lo convertimos de `string` en `int` (mediante `strconv.Atoi`).

```go
 // If no "count" parameter is provided, we return the count value
 if c.Query("count") != "" {
  var conv_err error
  count, conv_err = strconv.Atoi(c.Query("count"))
  if conv_err != nil {
   log.Printf("[error] error getting count from queryString (default to %d). error: %s", count, conv_err.Error())
   return
  }
 }
```

El siguiente paso es validar que el valor de `count` no sea superior al máximo que hemos especificado:

```go
 // Return max_count (at most)
 if count > max_count {
  log.Printf("[warning] requested %d records (returning max: %d)", count, max_count)
  count = max_count
 }
```

El resto del código de la función es igual al original.

El resultado final es:

```go
func GetPersonById(c *gin.Context) {
 // Limit the number of records returned
 var max_count int = 10
 // Default value
 var count int = 1

 // If no "count" parameter is provided, we return the count value
 if c.Query("count") != "" {
  var conv_err error
  count, conv_err = strconv.Atoi(c.Query("count"))
  if conv_err != nil {
   log.Printf("[error] error getting count from queryString (default to %d). error: %s", count, conv_err.Error())
   return
  }
 }

 // Return max_count (at most)
 if count > max_count {
  log.Printf("[warning] requested %d records (returning max: %d)", count, max_count)
  count = max_count
 }
 id := c.Param("id")

 results, err := models.GetPersonById(id, count)
 if err != nil {
  log.Printf("[error] retrieving record from database: %s", err.Error())
 }
 if results[0].FirstName == "" {
  c.JSON(http.StatusBadRequest, gin.H{"error": "not records found"})
  return
 } else {
  c.JSON(http.StatusOK, gin.H{"data": results})
 }
}
```

## Resultado del cambio

Por defecto, si no se especifica el parámetro `count` en la petición, sólo se devuelve un resultado:

```shell
$ curl "localhost:8080/api/v1/person/3"
{"data":[
  {"id":3,"first_name":"Gaven","last_name":"Allanby","email":"gallanby2@cloudflare.com","ip_address":"33.223.203.230"}
]}
```

Este es el mismo comportamiento que la función del tutorial.

Sin embargo ahora, podemos especificar `count` para devolver resultados adicionales:

```shell
$ curl "localhost:8080/api/v1/person/3?count=5"
{"data":[
  {"id":3,"first_name":"Gaven","last_name":"Allanby","email":"gallanby2@cloudflare.com","ip_address":"33.223.203.230"},
  {"id":4,"first_name":"Clara","last_name":"Vince","email":"cvince3@cloudflare.com","ip_address":"179.132.154.90"},
  {"id":5,"first_name":"Rozalie","last_name":"Stein","email":"rstein4@sitemeter.com","ip_address":"43.208.221.109"},
  {"id":6,"first_name":"Britni","last_name":"Pacquet","email":"bpacquet5@paypal.com","ip_address":"232.111.115.116"},
  {"id":7,"first_name":"Roselin","last_name":"Aleso","email":"raleso6@a8.net","ip_address":"0.219.112.14"}
]}
```

Como vemos, se devuelven el número de resultados especificados en el parámetro `count` (`5`) a partir del `Id=3`.

Si especificamos un valor para `count` superior al máximo definido, sólo se devuelven `max_count` resultados:

```shell
curl "localhost:8080/api/v1/person/3?count=500"
{"data":[
  {"id":3,"first_name":"Gaven","last_name":"Allanby","email":"gallanby2@cloudflare.com","ip_address":"33.223.203.230"},
  {"id":4,"first_name":"Clara","last_name":"Vince","email":"cvince3@cloudflare.com","ip_address":"179.132.154.90"},
  {"id":5,"first_name":"Rozalie","last_name":"Stein","email":"rstein4@sitemeter.com","ip_address":"43.208.221.109"},
  {"id":6,"first_name":"Britni","last_name":"Pacquet","email":"bpacquet5@paypal.com","ip_address":"232.111.115.116"},
  {"id":7,"first_name":"Roselin","last_name":"Aleso","email":"raleso6@a8.net","ip_address":"0.219.112.14"},
  {"id":8,"first_name":"Parrnell","last_name":"Castellaccio","email":"pcastellaccio7@woothemes.com","ip_address":"156.168.236.20"},
  {"id":9,"first_name":"Jobie","last_name":"McGiveen","email":"jmcgiveen8@tinyurl.com","ip_address":"124.84.5.0"},
  {"id":10,"first_name":"Lyn","last_name":"Kupper","email":"lkupper9@adobe.com","ip_address":"10.173.222.145"},
  {"id":11,"first_name":"Flossy","last_name":"Wareham","email":"fwarehama@google.ru","ip_address":"44.136.94.10"},
  {"id":12,"first_name":"Clemens","last_name":"Vail","email":"cvailb@admin.ch","ip_address":"77.176.26.76"}
]}
```

Y se registra en los logs del servidor:

```shell
2022/08/12 12:42:18 [warning] requested 500 records (returning max: 10)
[GIN] 2022/08/12 - 12:42:18 | 200 |     486.665µs |             ::1 | GET      "/api/v1/person/3?count=500
```

## Casos límite

Sabiendo que en nuestra base de datos de pruebas tenemos mil registros, podemos observar qué pasa cuando se *llega al final* de los registros existentes:

```shell
$ curl "localhost:8080/api/v1/person/999?count=5"  
{"data":[
  {"id":999,"first_name":"Maxim","last_name":"Heake","email":"mheakerq@seesaa.net","ip_address":"13.228.167.253"},
  {"id":1001,"first_name":"Xavier","last_name":"Aznar","email":"onthedock@example.cat","ip_address":"127.0.0.1"}
]}
```

Si solicita un registro con un `Id` que no existe en la base de datos, no se devuelve nada:

```shell
$ curl "localhost:8080/api/v1/person/2000?count=5"
$
```

En el servidor, se genera un **panic**, aunque el *framework* Gin se recupera y el servidor continua funcionando con normalidad:

```shell
runtime error: index out of range [0] with length 0
```

## Autocrítica

La función `GetPersons` deja de tener mucho sentido, ya que obtenemos los mismos resultados con `http://<URL>/api/v1/person/?count=10` que con `http://<URL>/api/v1/person/1?count=10`, por lo que quizás sería mejor usar un enfoque diferente basado en *páginas*: `http://<URL>/api/v1/person/?page=12`. Estableciendo un valor de resultados por página (por ejemplo, 10), esta petición devolvería los resultados con `Id` desde 12*10=120 hasta 129.

Otra posible mejora sería devolver algún mensaje indicando que no se han encontrado resultados, y si es posible, evitar el *panic* en el lado del servidor.

## Conclusión

Al introducir el parámetro `count` para `GetPersonById` es posible retornar un conjunto de resultados al realizar la petición a la API desde cualquier registro dado. De esta forma, el usuario podría iterar sobre los registros en la base de datos de forma parecida a como sucede en las APIs *reales*.
