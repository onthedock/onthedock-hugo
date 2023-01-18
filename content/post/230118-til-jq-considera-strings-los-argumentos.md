+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "jq", "automation", "til"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/bash.svg"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/

# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}
# YouTube           {{< youtube w7Ft2ymGmfc >}}
# Gist              {{< gist username 7896402 >}}
# Highlight         {{< highligth language >}}...{{< /highlight >}}
# Twitter           {{< tweet user="SanDiegoZoo" id="1453110110599868418" >}}

title=  "En Jq, los valores pasados mediante '--arg' se tratan como 'strings' sea cual sea su tipo #TIL"
date = "2023-01-18T21:43:12+01:00"
+++
Al definir un documento JSON, los campos pueden tener diferentes [**tipos**](https://json-schema.org/understanding-json-schema/reference/type.html), como `string`, `number`, `boolean`, etc... Sin embargo, al crear un documento usando `--arg`, el valor siempre se trata como *string*:

> `--arg name value:`
>
> This option passes a value to the jq program as a predefined variable. If you run jq with --arg foo bar, then $foo is available in the program and has the value "bar". Note that value will be treated as a string, so --arg foo 123 will bind $foo to "123".
<!--more-->

Entonces, ¿cómo generamos un documento JSON con Jq usando `--arg` si queremos un valor con tipo numérico?

```bash
$ jq --null-input --arg userId 1234 '{ "user_id": $userId }'
{
  "user_id": "1234" # String, not a number 😟
}
```

Una posible solución pasa por usar la función `tonumber` de Jq:

```bash
$ jq --null-input --arg userId 1234 '{ "user_id": $userId | tonumber }'
{
  "user_id": 1234 # 😀 
}
```

Pero... ¿y si queremos convertir a un `boolean`? Jq no proporciona un `tobool` o similar...

La solución válida para cualquier tipo es usar `--argjson`, en vez de `--arg`:

```bash
$ jq --null-input --argjson good true '{ "good": $good }'
{
  "good": true # 👍
}
```

Esta técnica sirve para cualquier tipo; repitiendo el ejemplo anterior para un `number` :

```bash
$ jq --null-input --argjson userId 1234 '{ "user_id": $userId }'
{
  "user_id": 1234 # 😀 
}
```

Revisando la documentación de `--argjson`:

> If you run jq with --argjson foo 123, then $foo is available in the program and has the value 123.

`#TIL` `#Today_I_Learned`
