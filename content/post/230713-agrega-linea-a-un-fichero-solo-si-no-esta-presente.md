+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev","ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "bash", "grep", "til"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/linux.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/

# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}
# YouTube           {{< youtube w7Ft2ymGmfc >}}
# Gist              {{< gist username 7896402 >}}
# Highlight         {{< highligth language >}}...{{< /highlight >}}
# Twitter           {{< tweet user="SanDiegoZoo" id="1453110110599868418" >}}

title=  "Agrega una línea a un fichero sólo si no está presente #TIL"
date = "2023-07-13T23:27:08+02:00"
+++
Ayer estaba revisando un *script* desarrollado por un compañero y me llamó la atención la manera en la que solucionaba un problema "habitual": ¿cómo añadir una línea a un fichero *sólo si no está ya presente*?
<!--more-->

La solución de mi compañero es muy *ad hoc* para el tipo de fichero en el que debe añadir la línea... Sin embargo, me hizo pensar en que hace tiempo había "leído por ahí" una solución mucho más genérica.

Ese "por ahí", era en Stack Overflow, en esta pregunta [Appending a line to a file only if it does not already exist](https://stackoverflow.com/a/3557165) (¡de hace 12 años!).

La solución es sencilla conceptualmente, a la par que elegante (nada de magia negra con expresiones regulares o algo por el estilo).

## El *concepto*

`grep` busca una cadena en un fichero. Así que es la herramienta perfecta para la primera parte del problema: averiguar si una determinada línea está presente en el fichero objetivo (al que voy a llamar `config.yaml`).

Para ejemplificar la solución, usaré el fichero:

```yaml
---
config:
  name: myapp
  path: /path/to/some/myapp.conf
```

Por defecto, `grep` devuelve (todo el contenido) de la línea en la que se encuentra coincidencias. Es decir, si buscamos `path`, obtenemos:

```bash
$ grep path config.yaml 
  path: /path/to/some/myapp.conf
```

Pero si buscamos `myapp`:

```bash
$ grep myapp config.yaml
  name: myapp
  path: /path/to/some/myapp.conf
```

En este segundo caso tenemos varias concidencias, lo que es un problema si queremos actualizar, por ejemplo, el *path* a la configuración de la aplicación.

Por suerte, una de las opciones de `grep` es `-x` (o en versión larga, `--line-regexp`), que selecciona sólo aquellas coincidencias de la *línea completa*. Esto es justo lo que queremos.

Por tanto, ahora podemos seleccionar sólo la línea que contiene la ruta al fichero de configuración mediante:

```bash
$ grep --line-regexp '  path: /path/to/some/myapp.conf' config.yaml 
  path: /path/to/some/myapp.conf
```

Observa como es necesario incluir los espacios al principio de la línea para que el **match** funcione.

Como vemos, en este caso usamos como *patrón* una cadena (no es una expresión regular); podemos indicárselo a `grep` mediante la opción `-F` (o en versión larga, `--fixed-strings`).

Finalmente, no es necesario que se muestre la coincidencia, así que añadimos `-q` (o `--quiet`).

Hasta ahora hemos "configurado" el comando `grep` para que nos indique si la línea (completa) se encuentra en el fichero.

A continuación, vemos cómo añadirla si no está presente.

## `echo` al rescate

La manera más sencilla de añadir una línea a un fichero es mediante el *humilde* `echo`:

```bash
echo '  path: /path/to/some/myapp.conf' >> config.yaml
```

El problema es que de esta forma, cada vez que ejecutemos el *script*, `echo` añade la línea al fichero.

¿Cómo lo combinamos con el comando `grep` anterior?

En Bash, cuando un comando tiene éxito devuelve `0`; si falla, devuelve `1` (o cualquier otro código numérico, hasta 255).

En Bash, el `0` también se interpreta como el valor "lógico" `true`, y por tanto, `1` (o cualquier otro valor), se considera `false`.

El operador `OR` (representado en Bash por `||`), es `true` si uno (o los dos) operandos son `true`.

Usamos esta propiedad de manera para conseguir el resultado que queremos:

```bash
grep --quiet --fixed-strings --line-regexp '  path: /path/to/some/myapp.conf' config.yaml || echo '  path: /path/to/some/myapp.conf' config.yaml
```

Si `grep` devuelve `0` (todo Ok), significa que se ha encontrado la línea en el fichero.
Como el operador || (`or`) ya tiene un operando con valor `true`, se evalúa como `true` (sin necesidad de evaluar el valor del segundo operando).

Si el primero operando devuelve `1` (`false`), significa que `grep` no ha encontrado la línea completa. En este caso, Bash debe evaluar el segundo operando (el `echo`) para determinar el resultado de operar los dos lados del `OR`.

`echo` imprime la cadena a `stdout`, pero mediante `>>` se redirige al fichero (al que se *añade* (*append*)). El resultado es (a no ser que pase algo raro) exitoso, por lo que `echo` devuelve `0`, que se considera `true` por el operador `||`, y el resultado es `true`.

Es decir, que el `echo` que añade la línea que queremos al fichero **sólo se añade si no está previamente en el fichero**.

Y eso, precisamente, lo que queríamos.

¡Aplausos! (como suele cerrar su sección Rodrigo Cortés en el *podcast* [Aquí hay dragones](https://www.podiumpodcast.com/podcasts/aqui-hay-dragones-podium-os/))
