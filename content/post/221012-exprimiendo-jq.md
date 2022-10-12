+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["jq"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/bash.svg"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/

# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}
# YouTube           {{< youtube w7Ft2ymGmfc >}}
# Gist              {{< gist username 7896402 >}}
# Highlight         {{< highligth language >}}...{{< /highlight >}}
# Twitter           {{< tweet user="SanDiegoZoo" id="1453110110599868418" >}}

title=  "Exprimiendo jq: cómo manipular ficheros JSON"
date = "2022-10-12T13:50:16+02:00"
+++
En esta entrada describo un caso práctico sobre cómo manipular un documento JSON (una *IAM Policy* de Google Cloud) para añadir un nuevo miembro a un rol determinado.

Las políticas pueden gestionarse directamente mediante la herramienta de línea de comandos `gcloud`, por ejemplo, sobre un [*folder*](https://cloud.google.com/sdk/gcloud/reference/projects/add-iam-policy-binding). Sin embargo puede ser interesante disponer de un registro con el *estado deseado* de los permisos de los recursos y así evitar *drift* (por ejemplo, si alguien modifica los permisos mediante `gcloud` o desde la consola).

Aunque el ejemplo se centra en un fichero de políticas de GCP, la entrada describe técnicas aplicables a la manipulación de cualquier fichero JSON.
<!--more-->

## GCP IAM Policies

Las *IAM Policies* de Google Cloud Platform define *quién puede hacer qué sobre qué recurso*.

Por un lado tenemos el ***quién***; en el caso de Google Cloud, tenemos usuarios ("seres humanos"), *Service Account* (identidades usadas por servicios o aplicaciones) y *grupos*.

Por otro lado, tenemos ***qué acciones***, es decir, lo que llamaríamos *los permisos*...

Finalmente, tenemos un objeto llamado *binding* que relaciona el *quién* con las acciones a realizar.

En la página con la documentación para las *policies* [Policy](https://cloud.google.com/iam/docs/reference/rest/v1/Policy) se indica cómo se implementan los conceptos de los párrafos anteriores.

Una *IAM Policy* en GCP tiene el siguiente aspecto:

```json
{
  "bindings": [
    {
      "role": "roles/resourcemanager.organizationAdmin",
      "members": [
        "user:mike@example.com",
        "group:admins@example.com",
        "domain:google.com",
        "serviceAccount:my-project-id@appspot.gserviceaccount.com"
      ]
    },
    {
      "role": "roles/resourcemanager.organizationViewer",
      "members": [
        "user:eve@example.com"
      ],
      "condition": {
        "title": "expirable access",
        "description": "Does not grant access after Sep 2020",
        "expression": "request.time < timestamp('2020-10-01T00:00:00.000Z')",
      }
    }
  ],
  "etag": "BwWWja0YfJA=",
  "version": 3
}
```

Al margen de un par de campos `version` y `etag`, el grueso de la *policy* se encuentra en el array `bindings`.
Cada elemento del *array* contiene un objeto con dos claves: `members` y `role`.
Es decir, el *quién* y *qué puede hacer* (los roles no son más que *conjuntos de acciones permitidas*).

El objetivo de esta entrada es describir cómo añadir un miembro a un *binding*.

Para ello, usaremos *jq*.

## *jq*

*jq* es *extremadamente* potente. *jq* suele usarse para seleccionar uno o más elementos de un documento JSON, obtenido desde la respuesta de una API.

Por ejemplo, para obtener el valor de la *key* `etag` de un documento IAM Policy de Google, usaríamos (usando la *policy* de muestra en la documentación de Google guardada en el fichero `policy.json` como *input*)

```bash
# https://jqplay.org/s/AuN-CNAUfWD
$ jq '.etag' policy.json

"BwWWja0YfJA="
```

Simple, ¿no?

En función de la estructura del documento JSON, seleccionar el/los elementos que te interesan puede ser más o menos complicado (aka, *frustante*).

## Escenario

En mi caso, quiero añadir un miembro (`user:xavi.aznar@onthedock.github.io`) al rol de `"roles/resourcemanager.organizationAdmin"`.

Nótese que, a diferencia de lo que suele encontrarse en la inmensa mayoría de los tutoriales de internet sobre *jq*, en este caso quiero **producir** un nuevo documento JSON resultado de procesar un documento de entrada.
Desgraciadamente (para mí), no he sido capaz de encontrar un tutorial que me ayudara en este caso...

## Atacando el problema por partes

Empezamos suponiendo que **el rol de destino ya existe en el fichero JSON** con la política. Esto se traduce en que existe un elemento del array `bindings` que tiene como valor de la clave `role` el rol que nos interesa. En nuestro caso, `"roles/resourcemanager.organizationAdmin"`.

En la *policy* de ejemplo de Google, esta suposición se cumple.

Como vemos, en el ejemplo, el *array* `bindings` tienen múltiples elementos; en general no sabemos cuántos ni en qué orden aparecen.

Si supiéramos que el rol que nos interesa es el primero del *array* `bindings`, haríamos referencia a él directamente (y nuestra vida sería mucho más feliz):

```json
$ jq '.bindings[0]' iam_policy.json

{
  "role": "roles/resourcemanager.organizationAdmin",
  "members": [
    "user:mike@example.com",
    "group:admins@example.com",
    "domain:google.com",
    "serviceAccount:my-project-id@appspot.gserviceaccount.com"
  ]
}
```

Antes comentaba que asumimos lo siguiente:

> ... existe un elemento del array `bindings` que tiene como valor de la clave `role` el rol que nos interesa.

Por tanto, lo que tenemos que hacer es iterar sobre las clave `role` de los elementos del *array* `bindings` y encontrar el que coincide con el que nos interesa.

El filtro `.bindings` devuelve el *array* completo; usando el *iterador* `[]` obtenemos cada uno de los elementos del *array*.

Encuentra las diferencias entre `.bindings`...

```json
$ jq '.bindings' iam_policy.json 

[
  {
    "role": "roles/resourcemanager.organizationAdmin",
    "members": [
      "user:mike@example.com",
      "group:admins@example.com",
      "domain:google.com",
      "serviceAccount:my-project-id@appspot.gserviceaccount.com"
    ]
  },
  {
    "role": "roles/resourcemanager.organizationViewer",
    "members": [
      "user:eve@example.com"
    ],
    "condition": {
      "title": "expirable access",
      "description": "Does not grant access after Sep 2020",
      "expression": "request.time < timestamp('2020-10-01T00:00:00.000Z')"
    }
  }
]
```

Y `.bindings[]`:

```json
$ jq '.bindings[]' iam_policy.json

{
  "role": "roles/resourcemanager.organizationAdmin",
  "members": [
    "user:mike@example.com",
    "group:admins@example.com",
    "domain:google.com",
    "serviceAccount:my-project-id@appspot.gserviceaccount.com"
  ]
}
{
  "role": "roles/resourcemanager.organizationViewer",
  "members": [
    "user:eve@example.com"
  ],
  "condition": {
    "title": "expirable access",
    "description": "Does not grant access after Sep 2020",
    "expression": "request.time < timestamp('2020-10-01T00:00:00.000Z')"
  }
}
```

El filtro `.bindings` devuelve **un elemento**, el *array*: `[...]` (entre corchetes).

El filtro `.bindings[]` *itera* sobre los elementos del *array* y devuelve cada uno de sus elementos; es decir, devuelve **dos objetos** (fíjate que los bloques de cada elemento `{"role": ..., "members": ... }` no están separados por comas del siguiente).

Esta diferencia es significativa para el siguiente paso: seleccionar la clave `role` de cada elemento del *array* `bindings`.

### Despotricando (aka, `rant` en inglés)

Si intentas `.bindings.role`:

```bash
$ jq '.bindings.role ' iam_policy.json

jq: error (at iam_policy.json:25): Cannot index array with string "role"
```

*jq* se queja con uno de sus típicos errores que no tienen sentido para mí; parece como si el error estuviera en usar `role` (que es un *string*) como índice del *array* `bindings`. Por tanto, usando un valor numérico (en vez de un *string*, que es de lo que se queja) debería funcionar...

```bash
$ jq '.bindings.0' iam_policy.json

jq: error: syntax error, unexpected LITERAL, expecting $end (Unix shell quoting issues?) at <top-level>, line 1:
.bindings.0
jq: 1 compile error
```

Pues tampoco 🤨.

Ya he comentado antes que la forma de especificar un elemento de un *array* es usando `.bindings[0]`, pero quería ejemplificar lo **abolutamente crípticos y sinsentido** (IMHO) de los mensajes de error de *jq*.

## *Back to work*

Una vez aprendido (a las duras) cómo usar el operador *iterador* `[]`, para seleccionar los elementos con clave `role`:

```json
$ jq '.bindings[].role' iam_policy.json

"roles/resourcemanager.organizationAdmin"
"roles/resourcemanager.organizationViewer"
```

👏👏👏

Obtenemos varios resultados (uno por cada elemento del *array* sobre el que hemos iterado).

## No es exactmente lo que queremos

El objetivo es **seleccionar** (😉) el elemento (completo) del *array* que coincide con el rol que nos interesa; para ello usamos la función `select()`.

Mediante `.bindings[]` obtenemos cada uno de los elementos del *array*. Sobre **el resultado de este filtro**, queremos seleccionar el elemento que se ajusta a nuestro criterio.

Para *encadenar* filtros en *jq*, se usa el operador `|` (*pipe*).

Con el primer filtro (`.bindings[]`) obtenemos dos resultados con la estructura:

```json
{
  "role": "...",
  "members": [...]
}
```

Este es el *input* del siguiente filtro, que en nuestro caso es la función `select()`.
Por tanto, para hacer referencia a la clave `role`, usamos `.role` (no `.bindings[].role`)
Mediante la función `select()` seleccionamos el elemento del *input* que valida el criterio, es decir, que `.role == "roles/resourcemanager.organizationAdmin"`:

> Muestro el filtro en varias líneas porque así resulta más fácil de "leer"

```json
$ jq '.bindings[]
     | select( .role == "roles/resourcemanager.organizationAdmin")' iam_policy.json

{
  "role": "roles/resourcemanager.organizationAdmin",
  "members": [
    "user:mike@example.com",
    "group:admins@example.com",
    "domain:google.com",
    "serviceAccount:my-project-id@appspot.gserviceaccount.com"
  ]
}
```

El siguiente paso es añadir un nuevo miembro al *array* `members`.

Añadimos un nuevo filtro y obtenemos el *array* con los miembros que pertencen al rol especificado:

```json
$ jq '.bindings[]
     | select( .role == "roles/resourcemanager.organizationAdmin")
     | .members' iam_policy.json

[
  "user:mike@example.com",
  "group:admins@example.com",
  "domain:google.com",
  "serviceAccount:my-project-id@appspot.gserviceaccount.com"
]
```

Finalmente, añadimos el nuevo miembro; para poder *sumar* dos elementos, deben ser del mismo tipo; como `members` es un *array*, el nuevo elemento debe ser también un *array*:

```json
$ jq '.bindings[]
     | select( .role == "roles/resourcemanager.organizationAdmin")
     | .members + [ "user:xavi.aznar@onthedock.github.io" ]' iam_policy.json

[
  "user:mike@example.com",
  "group:admins@example.com",
  "domain:google.com",
  "serviceAccount:my-project-id@appspot.gserviceaccount.com",
  "user:xavi.aznar@onthedock.github.io"
]
```

## Happy ... end?

Hemos insertado con éxito un nuevo elemento en el *array* de `members`.
Es un gran paso en la dirección en la que queremos avanzar, pero el objetivo es tener el documento de la *policy* actualizado, no sólo el *array*.

Construimos un nuevo *binding* añadiendo campos a lo que tenemos.

El *binding* es un objeto que tiene dos claves, `role` y `members`; el rol lo conocemos (es en el que hemos añadido un nuevo miembro) y `members` es el array que acabamos de construir.
Construimos el objeto en *jq* y añadimos el *array* `members` recién creado como valor de la clave `"members":`

```json
$ jq '.bindings[]
     | select( .role == "roles/resourcemanager.organizationAdmin")
     | .members + [ "user:xavi.aznar@onthedock.github.io" ]
     | { "role": "roles/resourcemanager.organizationAdmin" , "members": . }' iam_policy.json

{
  "role": "roles/resourcemanager.organizationAdmin",
  "members": [
    "user:mike@example.com",
    "group:admins@example.com",
    "domain:google.com",
    "serviceAccount:my-project-id@appspot.gserviceaccount.com",
    "user:xavi.aznar@onthedock.github.io"
  ]
}
```

> En mi caso de uso sólo estoy interesado en las claves `role` y `members` de las *policies*. Como se puede observar en el ejemplo de la política IAM de Google Cloud, también se pueden incluir `condition`s. Al construir el *binding* "manualmente" ignoro deliberadamente incluir las `condition`, por lo que al añadir un nuevo miembro a un *binding* que tuviera asociado una `condition`, ésta se eliminaría. Tenlo en cuenta si usas `condition` en tus políticas.

Repetimos el proceso para insertar el objeto *binding* en el *array* `bindings`... Solo que no podemos, porque no tenemos el resto del documento original: lo hemos ido filtrando a través de *jq* 😟.

Nos gustaría poder añadir el nuevo *binding* que hemos creado al *array* `bindings` como hemos hecho con el nuevo miembro en `members`, pero no funciona:

```json
$ jq '.bindings[]
     | select( .role == "roles/resourcemanager.organizationAdmin")
     | .members + [ "user:xavi.aznar@onthedock.github.io" ]
     | { "role": "roles/resourcemanager.organizationAdmin" , "members": . }
     | .bindings[] + .' iam_policy.json

jq: error (at iam_policy.json:25): Cannot iterate over null (null)
```

## Variables al rescate

*jq* incluye soporte para variables; podemos guardar el resultado de un filtro en una variable para usarlo más tarde en la *pipeline* de *jq*.
Para guardar el resultado de un filtro en una variable, usamos la sintaxis `as $<nombre_variable>`.

El plan consiste en guardar el resultado en una variable y añadirlo al *array* de `bindings`.

Si lo intentamos directamente:

```json
$ jq '.bindings[]
     | select( .role == "roles/resourcemanager.organizationAdmin")
     | .members + [ "user:xavi.aznar@onthedock.github.io" ]
     | { "role": "roles/resourcemanager.organizationAdmin" , "members": . } as $newbinding
     | .bindings + $newbinding' iam_policy.json

jq: error (at iam_policy.json:25): Cannot index array with string "bindings"
```

¿Qué ocurre 🤔?

Mi primera teoría ha sido que hemos construido un **objeto** (`{...}`), pero `bindings` es un *array*, y sólo podemos añadir *arrays con arrays*.

He modificado el paso previo para construir un *array* de un solo elemento. Añadimos `[ ... ]` alrededor del objeto *binding*:

```json
$ jq '.bindings[]
     | select( .role == "roles/resourcemanager.organizationAdmin")
     | .members + [ "user:xavi.aznar@onthedock.github.io" ]
     | [{ "role": "roles/resourcemanager.organizationAdmin" , "members": . }] as $newbinding
     | .bindings + $newbinding' iam_policy.json

jq: error (at iam_policy.json:25): Cannot index array with string "bindings"
```

## Agrupando filtros

La raíz del problema, si lo he entendido correctamente, es que las variables están limitadas al *scope* en el que se encuentran definidas. Aunque lo que yo esperaría es que el *array* de un solo elemento para el *binding* generado se almacene en la variable `$newbinding`, *jq* no lo interpreta del mismo modo (aunque no tengo claro porqué).

Para generar el *binding* tengo que agrupar todos los filtros que generan el *binding*, usando paréntesis `(...)`:

```json
$ jq '(
        .bindings[]
        | select( .role == "roles/resourcemanager.organizationAdmin")
        | .members + [ "user:xavi.aznar@onthedock.github.io" ]
        | [{ "role": "roles/resourcemanager.organizationAdmin" , "members": . }]
      ) as $newbinding
      | .bindings + $newbinding' iam_policy.json

[
  {
    "role": "roles/resourcemanager.organizationAdmin",
    "members": [
      "user:mike@example.com",
      "group:admins@example.com",
      "domain:google.com",
      "serviceAccount:my-project-id@appspot.gserviceaccount.com"
    ]
  },
  {
    "role": "roles/resourcemanager.organizationViewer",
    "members": [
      "user:eve@example.com"
    ],
    "condition": {
      "title": "expirable access",
      "description": "Does not grant access after Sep 2020",
      "expression": "request.time < timestamp('2020-10-01T00:00:00.000Z')"
    }
  },
  {
    "role": "roles/resourcemanager.organizationAdmin",
    "members": [
      "user:mike@example.com",
      "group:admins@example.com",
      "domain:google.com",
      "serviceAccount:my-project-id@appspot.gserviceaccount.com",
      "user:xavi.aznar@onthedock.github.io"
    ]
  }
]
```

> Al guardar el contenido de uno o más filtros sobre el *input* en una variable, la *pipeline* de procesado empieza de nuevo con el *input* **original**.

No es exactamente lo que necesito... Pero puedo *maquillarlo* un poco para conseguir que el resultado se ajuste al esquema:

```json
$ jq '(
        .bindings[]
        | select( .role == "roles/resourcemanager.organizationAdmin")
        | .members + [ "user:xavi.aznar@onthedock.github.io" ]
        | [{ "role": "roles/resourcemanager.organizationAdmin" , "members": . }]
      ) as $newbinding
      | . + { "bindings": (.bindings + $newbinding) }' iam_policy.json

{
  "bindings": [
    {
      "role": "roles/resourcemanager.organizationAdmin",
      "members": [
        "user:mike@example.com",
        "group:admins@example.com",
        "domain:google.com",
        "serviceAccount:my-project-id@appspot.gserviceaccount.com"
      ]
    },
    {
      "role": "roles/resourcemanager.organizationViewer",
      "members": [
        "user:eve@example.com"
      ],
      "condition": {
        "title": "expirable access",
        "description": "Does not grant access after Sep 2020",
        "expression": "request.time < timestamp('2020-10-01T00:00:00.000Z')"
      }
    },
    {
      "role": "roles/resourcemanager.organizationAdmin",
      "members": [
        "user:mike@example.com",
        "group:admins@example.com",
        "domain:google.com",
        "serviceAccount:my-project-id@appspot.gserviceaccount.com",
        "user:xavi.aznar@onthedock.github.io"
      ]
    }
  ],
  "etag": "BwWWja0YfJA=",
  "version": 3
}
```

## El elefante en la habitación

Aunque el documento generado se ajusta al esquema de una IAM Policy en Google Cloud, no podemos pasar por alto el hecho de que **hay dos objetos con la misma clave en el *array* `bindings`**.

*jq* tiene una función `unique`, que parece prometedora: [unique](https://stedolan.github.io/jq/manual/#unique,unique_by(path_exp)), elimina elementos duplicados de un *array*.
El problema es que nuestros elementos no son duplicados: el contenido del *array* `members` es diferente en los dos objetos con la misma clave 😞.

Tenemos que *borrar* el elemento del *array* con clave `"role": "roles/resourcemanager.organizationAdmin"` **antes** de añadir el elemento modificado (al que hemos añadido un nuevo miembro al *array* `members`).

Como al almacenar el resultado de un conjunto de filtros en una variable *jq* *reinicia* el procesado a partir del *input* original, añadimos los filtros para realizar la eliminación del objeto existente tras declarar la variable.

> Para simplificar, nos centramos en el proceso de borrado (sin el resto de filtros)

Al principio hemos visto cómo usar `select()` para seleccionar sólo el elemento que nos interesa del documento:

```json
$ jq '.bindings[]
     | select( .role == "roles/resourcemanager.organizationAdmin")' iam_policy.json

{
  "role": "roles/resourcemanager.organizationAdmin",
  "members": [
    "user:mike@example.com",
    "group:admins@example.com",
    "domain:google.com",
    "serviceAccount:my-project-id@appspot.gserviceaccount.com"
  ]
}
```

Este elemento es precisamente el que tenemos que borrar para evitar "duplicarlo" al añadir el objeto actualizado (con la misma clave).

Para borrarlo, usamos la función `del()`:

```json
$ jq 'del(  .bindings[]
            | select( .role == "roles/resourcemanager.organizationAdmin")
         )' iam_policy.json

{
  "bindings": [
    {
      "role": "roles/resourcemanager.organizationViewer",
      "members": [
        "user:eve@example.com"
      ],
      "condition": {
        "title": "expirable access",
        "description": "Does not grant access after Sep 2020",
        "expression": "request.time < timestamp('2020-10-01T00:00:00.000Z')"
      }
    }
  ],
  "etag": "BwWWja0YfJA=",
  "version": 3
```

*jq* devuelve el documento proporcionado como *input* sin la clave que hemos eliminado 👍.

## Insertar el borrado en la *pipeline* de *jq*

```json
$ jq '(
        .bindings[]
        | select( .role == "roles/resourcemanager.organizationAdmin")
        | .members + [ "user:xavi.aznar@onthedock.github.io" ]
        | [{ "role": "roles/resourcemanager.organizationAdmin" , "members": . }]
      ) as $newbinding
      | del( .bindings[]
             | select( .role == "roles/resourcemanager.organizationAdmin")
           )
      | . + { "bindings": (.bindings + $newbinding) }' iam_policy.json

{
  "bindings": [
    {
      "role": "roles/resourcemanager.organizationViewer",
      "members": [
        "user:eve@example.com"
      ],
      "condition": {
        "title": "expirable access",
        "description": "Does not grant access after Sep 2020",
        "expression": "request.time < timestamp('2020-10-01T00:00:00.000Z')"
      }
    },
    {
      "role": "roles/resourcemanager.organizationAdmin",
      "members": [
        "user:mike@example.com",
        "group:admins@example.com",
        "domain:google.com",
        "serviceAccount:my-project-id@appspot.gserviceaccount.com",
        "user:xavi.aznar@onthedock.github.io"
      ]
    }
  ],
  "etag": "BwWWja0YfJA=",
  "version": 3
}
```

{{< figure src="/images/221012/despicable-me-minions.gif" width="100%" >}}

## Inyectando variables (de Bash)

Hasta ahora hemos usado valores fijos tanto para la identidad del nuevo miembro como para el rol.

En mi caso de uso, estas acciones se realizan de forma automatizada, por lo que el valor de la identidad tanto del miembro a añadir como a qué rol se definen en Bash.

Para *asignar* los valores de variables en Bash en variables de *jq*, usamos `--arg <var_jq> <var_bash>` antes de proporcionar los filtros a *jq*.

> Para simplificar, uso el mismo nombre para la variable de *jq* que para la variable en *Bash*.

```bash
role="roles/resourcemanager.organizationAdmin"
principal="user:xavi.aznar@onthedock.github.io"
jq --arg role $role --arg principal $principal \
   '(
      .bindings[]
      | select( .role == $role )
      | .members + [ $principal ]
      | [{ "role": $role , "members": . }]
    ) as $newbinding
    | del( .bindings[]
           | select( .role == $role )
         )
    | . + { "bindings": (.bindings + $newbinding) }' iam_policy.json
```

## Conclusión

Al principio del artículo decía que *jq* es extremadamente potente. Permite hacer verdaderas *[virguerías](https://dle.rae.es/virguer%C3%ADa)* procesando ficheros JSON.

También es increíblemente frustante... Cualquier pequeña modificación sobre un filtro suele acabar en un error que no siempre es fácil de interpretar...
Parte de la frustación la causa el desconocimiento; mientras me planteaba lo útil que sería poder visualizar la entrada y/o la salida de cualquier paso intermedio, una rápida búsqueda en Google (con el consiguiente enlace a [StackOverFlow](https://stackoverflow.com/a/47764769)) me ha puesto sobre la pista de la función [debug](https://stedolan.github.io/jq/manual/#debug), que hace **exactamente** eso...

Por tanto, la próxima vez que tengas que usar *jq* para manipular un fichero JSON, dale una oportunidad a *jq*; probablemente te permitirá hacer lo que necesitas de una forma "sencilla" y compacta, aunque a primera vista no lo pueda parecer.
