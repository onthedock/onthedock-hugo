+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "curl"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/linux.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/

# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}
# YouTube           {{< youtube w7Ft2ymGmfc >}}
# Gist              {{< gist username 7896402 >}}
# Highlight         {{< highligth language >}}...{{< /highlight >}}
# Twitter           {{< tweet user="SanDiegoZoo" id="1453110110599868418" >}}

title=  "Obtener respuesta y código de la petición HTTP con curl"
date = "2022-05-18T18:30:52+02:00"
+++
Llevo una temporada revisando código -MUCHO, MUCHO código- en Bash.

Como parte de uno de los *steps* de ejecución de una *pipeline*, se consulta una API para obtener o actualizar información de una base de datos y *hacer cosas* con esa información, como desplegar recursos en un proveedor cloud (usando la *cli*) o lanzando Terraform.

Uno de los patrones que me encontrado a la hora de interaccionar con la API es el siguiente:

- Generar el *payload* en JSON y guardarlo en una variable.
- Ejecutar la petición usando `curl` y guardar la respuesta en un fichero.
- Filtrar la respuesta usando `jq` leyendo el fichero.
<!--more-->

En general, algo como:

```shell
# This dummy API from reqbin.com ignores `-d` and 
#  the authorization `$token`
url='https://reqbin.com/echo/post/json'
token=$(openssl rand -hex 20) # Simulates getting the authorization token
test_query=$(cat <<-EOF
{
    "action": "query",
    "field": "name",
    "operand": "==",
    "value": "$name"
}
EOF
)
echo $test_query | curl -s $url \
    -H "Accept: application/json" \
    -H "Authorization: Bearer $token" \
    -d @- > response.json

## Do something with the response
result=$(cat response.json | jq '.success')

echo "The result obtained was: $result"
```

Hay varias cosas que pueden mejorarse, pero voy a centrarme en lo que indicaba en el título: problemas con `curl`. Ejecutando el *script*, todo funciona como se espera:

```shell
$ bash example.sh
The result obtained was: "true"
```

Hasta aquí, todo bien.

Pero ¿qué pasa si hay un problema cuando llamamos a la API mediante `curl`?

Voy a simularlo cambiando la URL a:

```shell
url='https://reqbin.com/echo/post/NOT_VALID_URL_json'
```

La salida ahora es:

```shell
$ bash example.sh
parse error: Invalid numeric literal at line 1, column 10
The result obtained was: 
```

El error no parece tener que ver nada con la URL... Así que es probable que empecemos a buscar qué pasa... En este ejemplo, está claro que hay un problema con la URL (la hemos cambiado a una incorrecta *a propósito*)... Pero ocurre lo mismo si el `$token` ha expirado o se comete un error al generar el *payload* (te olvidas una "," por ejemplo).

Parecería que revisando el *exit code* de `curl` podríamos prevenir estas situaciones...Añadimos un *echo* para revisar el *exit_code* de `curl`:

```shell
url='https://reqbin.com/echo/post/NOT_VALID_URL_json'
...
echo $test_query | curl -s $url \
    -H "Accept: application/json" \
    -H "Authorization: Bearer $token" \
    -d @- > response.json
    
echo "el resultado fue $?"
...
```

Ejecutando de nuevo el *script*:

```shell
$ bash example.sh
el resultado fue 0
parse error: Invalid numeric literal at line 1, column 10
The result obtained was: 
```

Como se observa, el comando `curl` se ha ejecutado con éxito; lo que ha "fallado" es la interacción con la API.

Revisando el contenido del fichero con la respuesta `response.json`, está claro que no recibimos un fichero JSON:

```html
<!DOCTYPE html><html lang="en"> <head><title>404 Page Not Found</title>...
```

## La solución

Idealmente lo que quiero es obtener el código HTTP devuelto por la API **además** de la respuesta al realizar la petición. De esa forma, puedo validar si todo ha ido bien **antes** de manipular la respuesta obtenida.

Revisando las opciones disponibles en la [documentación de `curl`](https://man7.org/linux/man-pages/man1/curl.1.html) y la ayuda de [StackOverflow](https://stackoverflow.com/a/55434980), vemos que podemos modificar el código a:

```shell
...
api_response=$(echo $test_query | curl $url \
    -H "Accept: application/json" \
    -H "Authorization: Bearer $token" \
    --write-out "%{http_code}" \
    --silent --output response.json \
    -d @- )
if [[ "$api_response" -eq '200' ]];then
    ## Do something with the response
    result=$(cat response.json | jq '.success')
    echo "The result obtained was: $api_response"
else
    printf "Server returned HTTP Code %s\n" "$response"
    exit $ERR_NON_SUCCESSFUL_EXIT_CODE
fi
```

En este caso, al ejecutar (todavía con la URL inválida), obtenemos un error que tiene mucho sentido:

```shell
$ bash example.sh
Server returned HTTP Code 404
```

Y por supuesto, si la llamada a la API es exitosa:

```shell
$ bash example.sh
The result obtained was: "true"
```

## Otras mejoras

### Especificar siempre el *shebang* al principio del *script*

Linux usa el [Shebang](https://en.wikipedia.org/wiki/Shebang_(Unix)) para *obtener* el intérprete con el que ejecutar el *script*.

El uso de `#!/usr/bin/env bash` favorece la portabilidad, pero lo habitual es que se haya establecido o acordado el uso de un determinado sistema operativo "homologado", tanto a nivel de servidor (físico, virtual, cloud) como para las imágenes base en contenedores... Así que a nivel práctico (al menos a nivel empresarial), es que la portabilidad **no es un factor a tener en cuenta**.

En estos casos, lo habitual es seguir -o adoptar- una "guía de estilo", como la de Google: [Shell Style Guide](https://google.github.io/styleguide/shellguide.html#s1.1-which-shell-to-use). Así, queda claro qué hacer:

> Bash is the only shell scripting language permitted for executables.
>
> Executables must start with `#!/bin/bash` and a minimum number of flags. Use `set` to set shell options so that calling your script as `bash script_name` does not break its functionality.
>
> Restricting all executable shell scripts to bash gives us a consistent shell language that’s installed on all our machines.

Al indicar el intérprete que ejecutará el *script* permite que extensiones del IDE como [ShellCheck](https://marketplace.visualstudio.com/items?itemName=timonwong.shellcheck) nos ayuden a seguir buenas prácticas al desarrollar; además, si todo el equipo usa el mismo validador, se consigue de manera automática homogeneizar la calidad del código.

### Aprovecha la potencia de los comandos: usa sólo uno -si es posible- en vez de dos

En Linux, se suele decir que los comandos hacen una cosa, pero la hacen bien.

En el siguiente bloque de código, el objetivo del `echo` es pasar el *payload* a `curl` mediante la opción `-d @-`:

```bash
test_query=$(cat <<-EOF
{
    "action": "query",
    "field": "name",
    "operand": "==",
    "value": "$name"
}
EOF
)
response=$(echo $test_query | curl $url ...)
```

Podemos lograr lo mismo sin necesidad de usar `echo`:

> `<<-EOF` permite ignorar la indentación del *HEREDOC*, pero **es obligatorio usar TABS, no espacios**.

```shell
api_response=$(curl $url \
    -H "Accept: application/json" \
    -H "Authorization: Bearer $token" \
    --write-out "%{http_code}" \
    --silent --output response.json \
    --data @- <<-QUERY 
    {
        "action": "query",
        "field": "name",
        "operand": "==",
        "value": "$name"
    }
    QUERY
    )
```

En mi humilde opinión, de esta forma tenemos todos los *ingredientes* del comando `curl` en un mismo sitio, lo que resulta más sencillo de *leer* e interpretar.

Si este tipo de *queries* se repite frecuentemente, quizás se puedan *esconder* los detalles en una función:

```shell
#!/bin/bash
HTTP_CODE_ERR=2

query_db() {
    local response
    local token
    local url
    local value

    value="$1"
    url="$2"
    token="$3"

    response=$(curl "$url" \
    -H "Accept: application/json" \
    -H "Authorization: Bearer $token" \
    --write-out "%{http_code}" \
    --silent --output response.json \
    --data @- <<-QUERY
    {
        "action": "query",
        "field": "name",
        "operand": "==",
        "value": "$value"
    }
    QUERY
    )
    echo "$response"
}

api_url='https://reqbin.com/echo/post/json'
api_token=$(openssl rand -hex 20) # Simulates getting the authorization token

api_response=$( query_db "xavi" "$api_url" "$api_token" )

if [[ "$api_response" -eq '200' ]]; then
    ## Do something with the response
    ...
```

## `jq` es capaz de leer ficheros

De nuevo, la idea es reducir el número de comandos usados.

Directamente de la ayuda que imprime `jq` al ejecutarse sin comando, vemos que puede leer un fichero como *input*:

```shell
jq - commandline JSON processor [version 1.6]

Usage:  jq [options] <jq filter> [file...]
...
```

Así que no es necesaria la combinación `cat <filename> | jq '<filter>'`; en vez de tener que combinar dos comandos, conseguimos la misma funcionalidad únicamente con uno:

```shell
result=$(jq '.success' response.json)
```

## Bonus: *megacombo* (innecesario)

Leyendo el siguiente fragmento resulta sencillo imaginar el *hilo mental* que ha seguido su autor:

> Objetivo: Leer un fichero JSON, filtrarlo para obtener, por ejemplo, el valor de un campo y asignar el resultado a una variable

- Para *leer un fichero*, uso `cat fichero.json`
- Uso la `|` para pasar el contenido a `jq` y aplicar el filtro
- Mediante `echo` paso la salida del comando `jq` a la variable
- *¡Listo!*

```shell
variable=$(echo $(cat fichero.json | jq '<filter>'))
```

Sin embargo, podemos conseguir lo mismo sencillamente con:

```shell
variable=$(jq '<filter' fichero.json)
```

## Conclusión

Cuanto más sencillo es el código, más fácil es entender qué hace y seguir la ejecución cuando falla. Al usar *pipes* (sin la opción [`set -o pipefail`](https://tldp.org/LDP/abs/html/abs-guide.html#OPTIONSREF)), es posible que los errores queden enmascarados/ocultados de manera que la ejecución del *script* continue aunque alguno de los comandos haya fallado.

Este escenario es especialmente *peligroso* cuando la ejecución de los *scripts* se realiza de manera *desatendida* a medida que las *pipelines* se disparan como respuesta a eventos, como un nuevo *commit* o un mensaje en una cola.

Por ello, el equipo debe acordar un *standard* y quizás unas *implementaciones de referencia* para las tareas comunes (como la consultas a las API o el procesado de las respuestas con `jq`, por ejemplo). Esto permite homogeneizar el código y reducir el tiempo necesario para que **todo el equipo** *entienda* el funcionamiento de los componentes, lo que puede resultar crítico cuando se produce un fallo.
