+++
# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "bash", "script"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/bash.svg"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/
# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}

title=  "Encadena funciones en tus scripts de Bash usando pipes"
date = "2025-07-31T22:35:09+02:00"
+++
Uno de los pilares de Linux es que es un sistema compuesto por pequeñas utilizadades que hacen una cosa, pero la hacen extremadamente bien.
Podemos combinar la salida de un comando y enviarla, como *input*, a otro comando usando la `pipe` (`|`).

Por ejemplo, podemos usar `cat $filename | grep 'hello'` para filtrar el contenido del fichero `$filename` y quedarnos únicamente con las líneas que contengan `hello`.

¿Cómo podemos conseguir lo mismo en nuestras scripts en Bash?
<!--more-->
Imagina que necesitas una función como `to_lowercase`, que convierte a minúsculas un texto. La función podría ser algo como:

```shell
to_lowercase() {
    local input_string
    input_string="$1"
    echo "${input_string,,}"
}
```

Ahora, en un script en el que esté disponible está función `to_lowercase`, podemos usarla de la siguiente manera:

```shell
#!/usr/bin/env bash
source to_lowercase.sh

to_lowercase "My MIXed UPPERcase TEXT"
```

Puedes llamar a la función en el script como `to_lowercase "My MIXed UPPERcase TEXT"` y el resultado es el esperado `my mixed uppercase text`.

¿Pero qué pasa si intantas hacer algo como `echo "My MIXed UPPERcase TEXT" | to_lowercase`?

No obtenemos nada a la salida. La explicación es que `to_lowercase` espera un parámetro, pero no le pasamos ninguno, de manera que `input_string` está vacío (y eso es lo que muestra el comando `echo`).

## Aceptando *input* desde `stdin`

Transformar la función en nuestro script para que se comporte como esperamos, aceptando como entrada la salida de otro comando o función de nuestro script, es realmente sencillo.

```shell
to_lowercase() {
    local input_string
    input_string="$1"
    if [[ "$input_string" == "" ]]; then
        read -r input_string
    fi
    echo "${input_string,,}"
}
```

Ahora la ejecución de `echo "My MIXed UPPERcase TEXT" | to_lowercase` en nuestro script:

```shell
#!/usr/bin/bash
source to_lowercase

echo "My MIXed UPPERcase TEXT" | to_lowercase
```

proporciona el resultado esperado.

Como puede verse, la modificación que hemos hecho en la función es usar `read` para leer *input* desde `stdin`; pero en este caso, en vez de que sea el usuario el que proporcione el texto, el comando `read` lo lee desde la salida del comando anterior, a través de la *pipe* `|`, ya que ahí es donde escribe el comando `echo`.

## Encdenando múltiples funciones

Si incorporamos el mecanismo de *leer desde `stdin`* en todas nuestras funciones, podemos encadenarlas como queremos.

Añadimos otra función que reemplaza espacios por guiones, por ejemplo:

```shell
space_to_dash() {
    local input_string
    input_string="$1"
    if [[ "$input_string" == "" ]]; then
        read -r input_string
    fi
    echo "${input_string// /-}"
}
```

Ahora, podemos encadenar las dos funciones usando `|`:

```console
echo "My MIXed UPPERcase TEXT" | to_lowercase | space_to_dash
```

Y el resultado es:

```console
my-mixed-uppercase-text
```

Como vemos, usando *pipes*, la solución es mucho más fácil de leer que algo como:

```console
input_string="My MIXed UPPERcase TEXT"

lowercase_string=$(to_lowercase "$input_string")
echo "$(space_to_dash "$lowercase_string")"
```

O incluso, si sobreescribimos el valor de `input_string`:

```console
input_string="My MIXed UPPERcase TEXT"

input_string=$(to_lowercase "$input_string")
echo "$(space_to_dash "$input_string")"
```
