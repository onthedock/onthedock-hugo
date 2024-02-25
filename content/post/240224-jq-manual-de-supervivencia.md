+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["jq"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/bash.svg"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/
# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}

title=  "Jq: Manual De Supervivencia"
date = "2024-02-24T10:00:27+01:00"
+++

El otro día [@PeladoNerd](https://www.youtube.com/@PeladoNerd) confesaba en este vídeo [SADSERVERS / Kihei, Unimak Island, Ivujivik (MEDIUM)](https://youtu.be/CWcuNti7VR8) que no entendía como funcionaba [Jq](https://jqlang.github.io/jq/).
Inmediatamente empaticé con su frustación; es, sin duda, un sentimiento generalizado.

Jq es una herramienta realmente potente; pero "con un gran poder", llega una curva de aprendizaje muy dura.

Por eso me he decidido a escribir este artículo: no porque sea un super gurú de Jq, que no lo soy; pero creo que puedo aportar algo de claridad sobre la manera de *aproximarse* a Jq evitando los problemas más habituales.

<!--more-->

> TL;DR: Al final de la entrada hay un resumen en formato *bullet points* [Resumen: manual de supervivencia para Jq](#resumen-manual-de-supervivencia-para-jq)

## Qué es Jq

Jq es una herramienta con la manipular ficheros JSON.

Una gran cantidad de APIs aceptan y devuelven datos en forma de ficheros JSON. Algunas bases de datos NoSQL también usan ficheros JSON... Así que antes o después, es **muy probable** que te encuentres en una situación en la que tengas que manipular ficheros JSON...

> @PeladoNerd es un SRE con experiencia en Kubernetes, por lo que en vez de usar un fichero JSON "inventado", he decidido usar un *manifest* de un Pod (con dos contenedores) en formato JSON para los ejemplos.
>
> El fichero en cuestión lo he copiado de la página de la documentación de Kubernetes [Creating a Pod that runs two Containers](https://kubernetes.io/docs/tasks/access-application-cluster/communicate-containers-same-pod-shared-volume/) y lo he convertido a JSON usando [éste](https://onlineyamltools.com/convert-yaml-to-json) conversor online.

## Cómo ejecutar Jq

Jq obtiene el documento JSON como entrada, lo "procesa" y produce una salida.

> Aquí sólo voy a comentar la capacidad de Jq para filtrar un fichero y obtener, a la salida, un *subconjunto* del objeto inicial.
> Jq puede hace muchas más cosas a parte de *filtrar*.

Para procesar el fichero `pod.json`, los dos comandos mostrados a continuación son equivalentes:

1. Usar como "entrada" la salida de otro comando (usando una *pipe* `|`):

   ```console
   $ cat pod.json | jq
   {
   "apiVersion": "v1",
   "kind": "Pod",
   "metadata": {
       "name": "two-containers",
       ...
   ```

1. Indicar a Jq el fichero a procesar:

   ```console
   $ jq . pod.json 
   {
   "apiVersion": "v1",
   "kind": "Pod",
   "metadata": {
       "name": "two-containers",
       ...
   ```

Personalmente, prefiero la segunda forma porque indica claramente los tres componentes necesarios para usar Jq:

- `jq`: 😉
- `.`: un **filtro** (cuando el filtro incluye espacios, debe ir entrecomillado)
- `pod.json`: el fichero que Jq usa como *input*

### Primer *gotcha!*

@PeladoNerd se topa con uno de los primero *gotchas* de Jq en este momento del vídeo: [¡completame el jq!](https://youtu.be/CWcuNti7VR8?t=492).

Jq requiere un filtro; esto no es evidente usándolo de la forma `cat ${nombre-fichero} | jq`, porque Jq asume como filtro *por defecto* `.`, que representa "todo el documento".
Si embargo, en la forma `jq . ${nombre-fichero}`, Jq está esperando como primer parámetro un *filtro*, no un nombre de fichero; y eso hace que no funcione el *autocompletar* de la *shell*.

Para evitar tropezar con este comportamiento de Jq, recomiendo usar la forma `jq '{filtro}' ${nombre-fichero}`.

Si aceptas como entrada la salida de otro comando, incluye el `.` (aunque no sea necesario) para recordarte que *Jq siempre requiere un filtro*: `cat ${nombre-fichero} | jq .`

La forma `jq '<filtro>' ${nombre-fichero}` usa únicamente Jq, mientras que usando `echo` o `cat` para *enviar* contenido a Jq dependes de la implementación de estas herramientas en el sistema operativo, así como el uso del *pipe* (`|`) de la *shell*. [`echo`](https://tldp.org/LDP/abs/html/internal.html) está implementado como un *builtin*, por lo que la implementación puede variar de un *shell* a otro.

> Yo me topé con una de estas "pequeñas" diferencias con [mktemp](https://ss64.com/bash/mktemp.html), que por algún motivo, no funciona igual en Bash que en Zsh; en particular, la opción de usar `-t` para generar ficheros temporales con un prefijo. Así que aunque creas que esas "pequeñas diferencias" no te afectarán nunca, confía en mí si te digo que aparecen cuando (y donde) menos te las esperas.

## Qué es un objeto JSON

De la página de JSON:

> JSON (JavaScript Object Notation) es un formato ligero de intercmbio de datos. Es fácil para los humanos de leer y de escribir. Es fácil para las máquinas analizarlo (*parse*) y generarlo.

El objeto [JSON](https://www.json.org/json-en.html) más simple es `{}`. Todos los objetos JSON son colecciones de pares de *clave* y *valor*.

> Como en mi día a día trabajo con objetos JSON de una base de datos NoSQL "documental", suelo llamar "documento" a los "objetos" JSON delimitados por `{` y `}`.

`[]` es una lista (vacía). Una *lista* es una colección ordenada de valores cuyos valores están separados por `,`. Esta lista de objetos JSON también se llama *array*.

> Jq proporciona el [Array/Object Iterator](https://jqlang.github.io/jq/manual/#array-object-value-iterator), que tiene la forma `.[]`; aunque está relacionados con las listas de JSON, son cosas diferentes.

### JSONPath

Quizás has usado [JSONPath Support](https://kubernetes.io/docs/reference/kubectl/jsonpath/) en Kubernetes. La sintaxis es **muy parecida** a la de Jq, pero **no son lo mismo**.

El siguiente comando obtiene el valor de `status.capacity` en todos los *pods*; fíjate que usa el asterisco (`*`) en `.items[*]` para obtener la propiedad seleccionada de *todos los pods*.

```console
# Sintaxis de JSONPath
kubectl get pods -o=jsonpath="{.items[*]['metadata.name', 'status.capacity']}"
```

En Jq el asterisco `*` es el operador para la [multiplicación](https://jqlang.github.io/jq/manual/#multiplication-division-modulo) y no tiene sentido usarlo en un *array*.

```console
# Sintaxis de Jq
$ jq '.spec.containers[*]' pod.json 
jq: error: syntax error, unexpected '*' (Unix shell quoting issues?) at <top-level>, line 1:
.spec.containers[*]
jq: 1 compile error
```

## Usando Jq

### El filtro identidad

El filtro más sencillo es la [identidad](https://jqlang.github.io/jq/manual/#identity): `.` hace que la salida sea igual a la entrada.

> Jq formatea la salida por defecto; esto hace que el objeto JSON sea más fácil de "leer":
>
> ```console
> $ echo '{"foo":"xxx","bar":"yyy"}' | jq .
> {
>     "foo": "xxx",
>     "bar": "yyy"
> }
> ```

### Claves y valores

En el objeto del ejemplo anterior, `foo` es una *key* y `xxx` es el *valor* asociado a la *key* `foo`.

Las *keys* en JSON siempre son `string`, mientras que los valores pueden ser `string`, `number`, otros objetos JSON (delimitados por `{` y `}`), `arrays` (listas de objetos), `true`, `false` o `null`.

Podemos obtener las `keys` de un objeto mediante la función [`keys`](https://jqlang.github.io/jq/manual/#keys-keys_unsorted):

```console
$ jq '. | keys' pod.json 
[
  "apiVersion",
  "kind",
  "metadata",
  "spec"
]
```

> Estos son los campos requeridos para que un *manifest* de Kubernetes sea válido: [Required fields](https://kubernetes.io/docs/concepts/overview/working-with-objects/#required-fields).

Para enlazar la salida de un filtro con una función o la salida de una función al siguiente filtro, usamos la *pipe* `|` (como en la *shell*).
En el ejemplo, pasamos la salida del filtro identidad `.` a la función de Jq `keys`, que produce un *array* con las claves del documento de entrada.

### Filtrando el valor de una clave

Empezando desde el primer nivel `.`, podemos filtrar el valor de la clave como `metadata` mediante `jq '.metadata' pod.json`.

Si el valor de una determinada clave es otro objeto JSON, podemos ir *descendiendo* por las *claves* del objeto concatenando las *keys* en el filtro, como en `jq '.spec.containers[].name' pod.json`.

Imagina que el objeto JSON es un *árbol* donde cada una de las claves es una rama.
Si queremos obtener el valor asociado a la clave `apiVersion` tenemos que *trazar un camino* desde la raíz del documento (`.`) hasta la clave; como `apiVersion` "cuelga" directamente de la raíz, filtramos su valor mediante `.apiVersion`:

```console
$ jq '.apiVersion' pod.json
"v1"
```

> Usaré esta analogía del "árbol" más adelante con imágenes generadas en el sitio web <https://jsoncrack.com/editor>
>
> Nota: <https://jsoncrack.com/editor> agrupa las *keys* que no tienen descendientes (como `apiVersion` y `kind`) y las separa de aquellas que sí los tienen (`metadata` y `spec`) en la vista *gráfica* lo que rompe un poco la analogía del "árbol".

## Comillas

En el ejemplo anterior he usado comillas simples (`'`) para delimitar el filtro. También se pueden usar comillas dobles `"`. Sin embargo, como las *keys* de los objetos JSON son cadenas delimitadas por comillas, es más cómodo usar comillas simples y no tener que *escapar* las comillas:

```console
# Usando comillas simples (recomendado)
echo '{"foo":"xxx","bar":"yyy"}' | jq .

# Usando comillas dobles
echo "{\"foo\":\"xxx\",\"bar\":\"yyy\"}" | jq .
```

### *Gotcha!* con las comillas de los valores

El valor de `.apiVersion` es `"v1"`, con las comillas incluidas.

Yo llamo a estas comillas en Jq *comillas duras*, ya que no se comportan como unas comillas "normales".

En Bash, puedo entrecomillar los valores de una variable, pero las comillas sólo son "delimitadores" (para evitar problemas con espacios en blanco y otros caracteres), pero no forman parte del valor:

```console
# Comillas normales
$ EJEMPLO="Hola mundo"; echo "$EJEMPLO"
Hola mundo
```

Aunque tanto el valor de la variable `EJEMPLO` (`Hola mundo`) está entrecomillado y que también la variable está entrecomillada en el comando `echo`, la salida no muestra las comillas.

En Jq esto no es así y suele provocar problemas.

Considera el siguiente ejemplo:

```console
$ jq '.apiVersion' pod.json 
"v1"
$ [[ $(jq '.apiVersion' pod.json) == "v1" ]] || echo "no son iguales"
no son iguales
```

Para que el *test* se verifique, necesito incluir las comillas como parte del valor de la *key* `apiVersion`:

```console
$ [[ $(jq '.apiVersion' pod.json) == "\"v1\"" ]] || echo "no son iguales"
$
```

O usando comillas simples:

```console
$ [[ $(jq '.apiVersion' pod.json) == '"v1"' ]] || echo "no son iguales"
$
```

> En Bash, las [comillas simples](https://www.gnu.org/software/bash/manual/html_node/Single-Quotes.html) *preservan el valor literal de los caracteres dentro de las comillas*. Pero eso hace que no se susituyan las variables por su valor, que es lo que quieres habitualmente:
>
> ```console
> # Se compara el resultado del comando Jq ("v1") con el valor de la variable `$EXPECTED_VALUE` (v1) (sin comillas)
> $ EXPECTED_VALUE="v1" ; [[ $(jq '.apiVersion' pod.json) == "$EXPECTED_VALUE" ]] || echo "no son iguales" 
> no son iguales
> 
> # Se compara el resultado del comando Jq ("v1") con el literal `$EXPECTED_VALUE`
> $ EXPECTED_VALUE="v1" ; [[ $(jq '.apiVersion' pod.json) == '$EXPECTED_VALUE' ]] || echo "no son iguales"
> no son iguales
>
> # Usando comillas dobles, debemos escapar las comillas en el valor esperado
> $ EXPECTED_VALUE="\"v1\"" ; [[ $(jq '.apiVersion' pod.json) == "$EXPECTED_VALUE" ]] || echo "no son iguales"
> $
> ```

Estas *comillas duras* siguen confundiéndome y haciendo que los *scripts* fallen más a menudo de lo que creerías; afortunadamente, Jq incluye la opción de eliminar las comillas en la salida; para ello, usa el *flag* `--raw-output` o `-r` en versión corta:

```console
$ jq -r '.apiVersion' pod.json
v1
```

Observa como la salida no incluye las comillas.

## Filtros más complejos

Si queremos el valor de campo `name` del Pod, tenemos que descender "dos niveles":

- la clave `metadata` (primer nivel)
- la clave `name` del objeto JSON resultante de filtrar la entrada inicial (todo el documento leído desde `pod.json`) y aplicar el filtro anterior (`.metadata`).

Así, el filtro resultante es:

```console
# (El primer filtro `. |` es opcional y normalmente, se omite)
$ jq -r '. | .metadata.name'  pod.json 
two-containers
```

## *Pipe* interna de Jq

Jq filtra una entrada y produce una salida; la salida de un filtro puede *encauzarse* a través de una *pipe* (`|`) y utilizarse como entrada del siguiente filtro.

Podemos enlazar filtros **dentro** de Jq o usar el  `|` de la *shell*; comprueba como los dos comandos siguientes son equivalentes:

> Podemos concatenar los filtros uno tras otro con `.`, enlazando las *keys* por las que *descendemos* en el objeto JSON (como en `.metadata.name`). Sólo es necesario usar una *pipe* interna cuando queremos pasar el resultado de un filtro a una función de Jq o viceversa.

```console
# Pipe interna de Jq (en este caso no es necesario usar la *pipe*)
$ jq -r '.metadata | .name'  pod.json 
two-containers

# (Opción recomendada)
$ jq -r '.metadata.name'  pod.json 
two-containers

# Pipe "externa" a Jq
$ jq '.metadata' | jq -r '.name'
two-containers
```

> Observa que para que el resultado final no contenga "comillas duras" es necesario usar `-r` en el último comando Jq.

Mi recomendación es concatenar los filtros siempre que sea necesario; si usamos funciones de Jq, usar la *pipe* interna; no sólo es más compacto, sino que además mantiene la estructura de `jq '{filtro}' ${nombre_fichero}`.

## Errores

Parte de la frustación de usar Jq es que, en mi humilde opinión, los mensajes de error son increíblemente crípticos.

Intenta adivinar qué puede haber causado el siguiente mensaje de error:

```console
jq: parse error: Invalid numeric literal at line 2, column 0
```

Y ahora la solución:

```console
$ echo '<html></html>' | jq .
jq: parse error: Invalid numeric literal at line 2, column 0
```

*Creo* que el problema lo causa que Jq interpreta `<` como un operador de comparación entre números ([x es menor que y](https://jqlang.github.io/jq/manual/#%3E-%3E=-%3C=-%3C)). Antes de `<` no hay nada, con lo que *quizás* lo interpreta como 0, pero `h` (el caracter que aparece después de `<`) no es un valor numérico, lo que causa el error de `Invalid numeric literal`...

Como ves, (si mi interpretación es correcta), el mensaje de error *tiene sentido*; el problema es que no es aparente a primera vista.

> Como muchas veces el JSON que se procesa por Jq se obtiene desde una API, es *tentador* usar algo como:
>
> ```console
> # Se espera un JSON como `{"foo" : "bar"}`
> value=$(curl -s https://$ENDPOINT/api/ | jq -r '.foo')
> ```
>
> Si el token para acceder al *endpoint* ha caducado, o hay un problema cualquiera con la petición, el *endpoint* puede devolver HTML (por ejemplo, para mostrar un error `<h1>401 - > Unauthorized</h1>`). El problema es que el mensaje de error de Jq se "guarda" en `$value` y el *script* fallará de forma inesperada más adelante, cuando vayas a usar el valor de `$value` pensando que es `bar`.
>
> La recomendación es guardar la respuesta en un fichero; verifica el código HTTP devuelto por el servidor e inspecciona el contenido del fichero para validar que contiene lo que esperas y no otra cosa.

## Seleccionando valores de una lista

He elegido el JSON de un Pod con dos contenedores para poder ilustrar un escenario común: el valor que nos interesa obtener está en un objeto JSON **dentro** de un *array*.

En el siguiente ejemplo queremos obtener la propiedad `name` de cada uno de los contenedores en el *pod*; como hemos visto, tenemos que ir descendiendo por las ramas del "árbol" del objeto JSON; hasta ahora a cada *key* le correspondía un *valor* o un objeto, con sus propias *keys*.

En este caso, cuando llegamos a `.spec.containers` tenemos una lista de objetos, cada uno con la clave `name` (en la que estamos interesados).

Para obtener la clave `name` de cada uno de los elementos del *array*, tenemos que *iterar* sobre todos ellos; Jq proporciona el operador `.[]`. Para cada uno de los elementos, seleccionamos la *key* `name`. El filtro resultante es:

```console
$ jq -r '.spec.containers.[].name' pod.json
nginx-container
debian-container
```

*Traduciendo* el filtro a castellano: selecciona la *key* `spec`; del resultado, selecciona la *key* `containers`, itera sobre todos sus elementos (con `.[]`) y selecciona para cada uno de ellos la *key* `name`. Como vemos, la salida son los dos nombres de los contenedores que contiene el *manifest* del Pod.

> En este caso, es equivalente usar `jq -r '.spec.containers[].name' pod.json`; en vez de iterar sobre cada elemento de la lista `containers`.

## Seleccionando un valor específico de una lista

### Usando el índice del *array*

Si por algún motivo sabes en qué posición se encuentra el objeto en el que estás interesado en la lista (que en JSON está ordenada), puedes acceder al elemento específico indicando su posición en el *array*:

```console
jq -r '.spec.containers.[0].name' pod.json
nginx-container
```

De esta forma puedes seleccionar más de un elemento, indicando la posición de cada elemento que quieres obtener.

En el siguiente ejemplo, obtendo el primer y segundo elemento del *arrray*:

```console
$ jq -r '.spec.containers.[0,1].name' pod.json
nginx-container
debian-container
```

### Filtrando los valores del *array* mediante `select()`

Sin embargo, no es habitual saber en qué posición se encuentra el elemento, sino el valor de alguna de sus `keys`.

Imagina que quieres obtener el `mountPath` del contenedor cuyo nombre es `debian-container`. Esta frase recuerda a una *query* SQL, ¿no?:

```console
SELECT 'mountPath' FROM pod.json WHERE name='debian-container';
```

Jq ofrece la función `select()` que permite *algo así*.

Quizás lo primero que se te ocurre probar es algo como:

```console
jq 'select( .spec.containers[].name == "debian-container" )' pod.json
```

El resultado es todo el documento... ¿?

Una de las cosas más importantes a recordar cuando trabajas con Jq es que lo único que hace Jq es **filtrar** la entrada (para producir una salida).

El *filtro* en el comando anterior es equivalente a  `'. | select( .spec.containers[].name == "debian-container" )'`; traduciendo al castellano: usando como entrada todo el objeto JSON, pasa hacia el *output* los elementos que validen la condición especificada en el `select`. Como el `select` es `true`, porque el objeto de entrada valida la condición indicada en el `select`, todo el *input* es mostrado en la salida.

El enfoque que uso es filtrar el documento inicial hasta llegar a la clave en la que hay más de una opción disponible; en este caso, la *key* `containers`.
Como `containers` es una lista (*array*), explicitamos que lo que queremos pasar al siguiente filtro es **cada uno de sus elementos de manera independiente**, aceptando únicamente aquellos para los que se valide una condición que especifiquemos.

Podemos conseguirlo mediante el filtro `.spec.containers[]` o usando el operador de iteración sobre la clave `containers`, que es un *array*, mediante `.spec.containers.[]`.

Observa la salida de `jq '.spec.containers[]' pod.json` comparándola con la de `jq '.spec.containers' pod.json`:

```console
# La salida de .spec.containers[] son dos objetos JSON independientes: '{1}' y '{2}'
$ jq '.spec.containers[]' pod.json
{
  "name": "nginx-container",
  ...
}
{
  "name": "debian-container",
  ...
}

# La salida de .spec.containers es un solo elemento, un array '[{1}, {2}]'
$ jq '.spec.containers' pod.json  
[
  {
    "name": "nginx-container",
    ...
  },
  {
    "name": "debian-container",
     ...
  }
]
```

La función [`select()`](https://jqlang.github.io/jq/manual/#select) puede actuar sobre listas de elementos *individuales*, como en el primer ejemplo de la documentación de Jq (algo como `[1,2,3]`) o con elmentos *por parejas* de `clave=valor` (que es lo que tenemos en nuestro caso).

> @PeladoNerd se encuentra con problemas al intentar hacer un `select` en [este momento](https://youtu.be/CWcuNti7VR8?t=557).

`select` filtra la entrada que recibe y sólo "deja pasar" lo que resulta en `true` en la condición:

{{< figure src="/images/240224/select-gandalf.jpg" width="100%" >}}

En nuestro caso, tras el filtro de `select()` sólo tenemos el *manifest* correspondiente al contenedor que valida la condición `name=="debian-container"`:

```console
$ jq '.spec.containers[] | select( .name == "debian-container" )' pod.json
{
  "name": "debian-container",
  "image": "debian",
  "volumeMounts": [
    {
      "name": "shared-data",
      "mountPath": "/pod-data"
    }
  ],
  "command": [
    "/bin/sh"
  ],
  "args": [
    "-c",
    "echo Hello from the debian container > /pod-data/index.html"
  ]
}
```

De forma gráfica (pulsa sobre la imagen para ampliarla):

{{< figure src="/images/240224/pod.json-spec-containers-select.png" width="100%" >}}

A continuación, podemos seguir añadiendo filtros a la salida de `select()`; el siguiente sería usando la clave `.volumeMounts` (que vuelve a ser una lista).
En este caso concreto, la lista sólo contiene un elemento, por lo que los dos comandos siguientes producen el mismo resultado:

```console
$ jq -r '.spec.containers[] | select ( .name == "debian-container" ) | .volumeMounts[].name' pod.json 
shared-data

$ jq -r '.spec.containers[] | select ( .name == "debian-container" ) | .volumeMounts.[].name' pod.json
"shared-data"
```

De nuevo, la representación visual del filtro sería (pulsa sobre la imagen para ampliarla):

{{< figure src="/images/240224/pod.json-spec-containers-select-volumemounts.png" width="100%" >}}

Si queremos estar seguros de que obtenemos el valor de la *key* `mountPath` con nombre `shared-data` y no el valor de otra *key* que pueda incluir la lista `volumeMounts`, podemos usar `select()` de nuevo:

```console
$ jq '.spec.containers[] | select( .name == "debian-container" ) | .volumeMounts[] | select( .name == "shared-data" ) | .mountPath' pod.json
"/pod-data"
```

Es decir, de todos los elementos contenidos en el *array* `volumeMounts`, **seleccionamos** el que verifica `.name == "shared-data"`; a continuación, filtramos el contenido para obtener únicamente el valor de la *key*  `mountPath`.

> `select()` puede contener cualquier expresión que se evalúe como `true` o `false`; en la [solución al reto](https://youtu.be/CWcuNti7VR8?t=688), vemos que se usa una condición en la que se evalúa el valor dos *keys* usando el operador [`and`](https://jqlang.github.io/jq/manual/#and-or-not).

## Resumen: manual de supervivencia para Jq

- Recuerda que Jq procesa una **entrada** mediante un **filtro** para producir una **salida**.
  
  Siempre que puedas, usa `jq '<filtro>' ${nombre-fichero}`.
  Si usas como entrada contenido que llega a través de una *pipe*, incluye siempre el filtro (incluso cuando no sea necesario, como en el siguiente ejemplo) para reforzar la idea de que Jq **siempre** usa un **filtro**: `cat ${nombre-fichero} | jq .`.
- Usa **siempre** comillas (simples) para delimitar el filtro (incluso cuando no sea necesario):
  
  `jq '.name.containers[].name' pod.json`. Si te acostumbras, nunca tendrás problemas si el filtro incluye espacios.

  Jq no tiene en cuenta el *espacio en blanco*, lo que te puede ayudar a formatear filtros complejos para facilitar su visualización (especialmente en *scripts*):
  
  ```console
  jq -r '.spec.containers[]
         | select ( .name == "debian-container" )
         | .volumeMounts[].name
        ' pod.json
  ```

- Cuidado con las comillas en la salida del comando Jq.
  
  Recuerda el *flag* `-r`; si no te preocupan las comillas, usa `-r` siempre para evitar problemas en aquellas situaciones en las que sí sean relevantes (como en *scripts*).
- Concatena las *keys* y usa la *pipe* **interna** de Jq para enlazar filtros.
- Recuerda que cuando enlazas filtros, la salida de un filtro se convierte en la entrada del siguiente.
- `select` filtra los valores de la entrada para los que la condición de evalúa como `true` y sólo esos pasan hacia la salida (o el siguiente filtro).
