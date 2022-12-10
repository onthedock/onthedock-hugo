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


title=  "Prohibido anidar código o por qué debes evitar usar cláusulas 'else' en los condicionales"
date = "2022-12-10T17:17:41+01:00"
+++
Hace unos días me topé con el vídeo [Why You Shouldn't Nest Your Code](https://www.youtube.com/watch?v=CFRhGnuXG-4) del canal **CodeAesthetic** de YouTube. Me recordó en cierto modo al artículo de Mat Ryer [Code: Align the happy path to the left edge](https://medium.com/@matryer/line-of-sight-in-code-186dd7cdea88).

Aprovechando la calma de estos días, he revisado algo del código que tenemos en algunas de nuestras *pipelines*. He aplicado las ideas explicadas en estos artículos y el incremento en la claridad del código ha sido **espectacular**.
<!--more-->

Para probar las técnicas descritas en el vídeo, elegí el código de uno de los pasos más anidadados de una de las *pipelines* que usamos en el trabajo.

Cada uno de los bloques de una *pipeline* en Cloud Build  denomina *step*; elegí unos de los *steps* que tiene mayor nivel de anidamiento en cuanto a las comprobaciones a realizar.

El *step* de la *pipeline* en cuestión obtiene diferentes propiedades de un recurso desplegado *en el mundo real* a partir de la información obtenida de la base de datos acerca del mismo. En función de los valores de las propiedades del recurso en la base de datos, la *pipeline* debe ejecutar la acción apropiada para actualizar el recurso, eliminarlo o no hacer nada al respecto.

Además de las propiedades del recurso, hay otros *meta-parámetros* que hacen referencia al comportamiento de la propia *pipeline*; en este caso, usaré como ejemplo el modo *dry-run*, que indica que no se deben realizar cambios sobre el recurso, sólo "simularlos" (como el parámetro [`--dry-run`](https://docs.harness.io/article/xthfj92dys-terraform-dry-run) en Terraform).

## Escenario

En una arquitectura basada en eventos, la ejecución de las diferentes *pipelines* se *disparan* cuando se modifica cualquier registro en la base de datos. La *pipeline* recibe el identificador del registro y el *tipo* de recurso al que hace referencia, por lo que toda la información disponible se obtiene del valor de los campos del registro modificado.

En *pseudo-código*, el *step* tenía, inicialmente, una estructura como la siguiente:

```bash
terraform init

if $dry-run == enabled then {
  terraform plan
} else {
  if $deleted == true && $dependent == false then {
    if $deleted_at != "" {
      if $dry-run == testing {
        mock terraform destroy
      } else {
        terraform destroy
        deleted_at=now()
        update record(field:deleted_at) in database
      }
    } else {
     do nothing
    }
  else {
      terraform apply
      update record in database
  }
}
```

Revisando la historia de este trozo de código en el repositorio puede observarse como se han ido añadiendo más y más condicionales, lo que explica el *barroquismo* del mismo.

La lógica de lo que **debe** hacer este bloque de código es más o menos lo siguiente:

- si la pipeline se está ejecutando en modo *dry-run*, sólo se ejecuta el comando `terraform plan`, pero no se modifica la configuración del recurso *en el mundo real*.
- si no estamos en modo *dry-run*, se revisa si el estado del recurso es *eliminado* (es decir, si la propiedad `deleted` es igual a `true`).
- en este caso, el recurso en cuestión puede tener otros recursos *dependientes*. Estos recursos *dependientes*, deben crearse **después** de que se haya creado el recurso y deben eliminarse **antes** de que pueda eliminarse el recurso del que dependen... Estos recursos *dependientes* se gestionan desde su propia *pipeline*; cuando se han creado o eliminado todos los recursos *dependientes*, se actualiza el registro del recurso del que dependen.
- comprobamos si el campo `deleted_at` está vacío; el campo se informa cuando el recurso se ha eliminado en el *mundo real* y permite evitar bucles infinitos (esto se describe con mayor detalle más adelante)
- si el recurso debe destruirse, comprobamos si estamos en modo de *testeo* de la *pipeline*; en este caso, no queremos destruir los recursos, sino únicamente validar que la *pipeline* funciona correctamente.
- si la propiedad `deleted` no es `true`, ejecutamos `terraform apply`, lo que crea o actualiza el recurso *en el mundo real*.

## Refactor

El objetivo del ejercicio de *refactor* es simplicar los *niveles de anidamiento* del código y simplificar su estructura.

### ¿Modo *dry-run*?

Lo primero que revisamos es si la *pipeline* se ejecuta en modo *dry-run*; si es así, sólo tenemos que ejecutar `terraform plan` y finalizar, por lo que podemos simplicar el (pseudo) código de la siguiente forma:

```bash
terraform init

if $dry-run == enabled then {
  terraform plan
  exit 0
}
# Refactor pending from here...
if $deleted == true && $dependent == false then {
    if $deleted_at != "" {
      if $dry-run == testing {
        mock terraform destroy
      } else {
        terraform destroy
        deleted_at=now()
        update record(field:deleted_at) in database

      }
    } else {
     do nothing
    }
else {
      terraform apply
      update record in database
}}
```

### ¿El recurso está borrado?

El siguiente bloque revisa el valor de `deleted`; invertimos la condición y comprobamos si `deleted == false`:

```bash
terraform init

if $dry-run == enabled then {
  terraform plan
  exit 0
}
# dry-run is DISABLED from here...
if $deleted == false {
  terraform apply
  update record in database
  if $dependent == true {
    update dependent-records in database
  }
  exit 0
}
# Refactor pending from here...
if $deleted == true && $dependent == false then {
  if $deleted_at != "" {
    if $dry-run == testing {
      mock terraform destroy
    } else {
      terraform destroy
      deleted_at=now()
      update record(field:deleted_at) in database
    }
  } else {
    do nothing
  }
}
```

Si el recurso tiene la propiedad `deleted = false`, significa que el recurso tiene que crearse o actualizarse; en ambos casos, el comando a ejecutar es `terrafor apply`. Tras la creación/actualización del recurso *en el mundo real*, actualizamos el registro en la base de datos.

Si el recurso tiene elementos que dependan de él, una vez creado/actualizado, actualizamos los registros de los recursos dependientes; este evento dispara la *pipeline* que gestiona los recursos dependientes (tantas veces como elementos dependientes existan); la *pipeline* que gestione el tipo concreto de recurso dependiente realizará las acciones necesarias en función de la información del registro del recurso dependiente en la base de datos.

Si `dependent = false`, no hay elementos que dependan del tipo de recurso modificado, por lo que no hay que *notificar* a ninguna otra *pipeline*.

### ¿Existen recursos dependientes?

En el bloque anterior gestionamos el caso `deleted == false`; por tanto, el siguiente condicional tiene que actuar en el caso en que `deleted` vale `true` y podemos eliminar esa verificación del siguiente bloque condicional.

Como `deleted == true`, el elemento se tiene que borrar o ya se borró anteriormente.

Validamos el valor del campo `dependent`; si tenemos recursos dependientes, no podemos hacer nada, así que finalizamos la ejecución del *step*. La eliminación de los recursos dependientes, si es necesaria, se gestiona desde la *pipeline* que gestione esos recursos, así que no tenemos que preocuparnos por ellos aquí.

Usamos el principio de inversión de la condición (y comprobamos si `dependent = true`):

```bash
terraform init

if $dry-run == enabled then {
  terraform plan
  exit 0
}
# dry-run is DISABLED from here...
if $deleted == false {
  terraform apply
  update record in database
  if $dependent == true {
    update dependent-records in database
  }
  exit 0
}
# deleted is TRUE from here...
if $dependent == true then {
  do nothing
  exit 0
}
# Refactor pending from here...
if $deleted_at != "" {
  if $dry-run == testing {
    mock terraform destroy
  } else {
    terraform destroy
    deleted_at=now()
    update record(field:deleted_at) in database
  }
}
```

### ¿Cuál es el contenido del campo `deleted_at`?

En este caso, ya hemos comprobado si hay elementos dependientes; si hemos llegado hasta aquí, `dependent` es `false`, por lo que no hay elementos dependientes y podríamos eliminar el recurso.

Sin embargo, tras eliminar el recurso actualizamos el campo `deleted_at` del registro en la base de datos con la hora a la que se ha eliminado el recurso (por ejemplo, las 00:00:00). Esta actualización dispararía de nuevo la ejecución de la pipeline; dado que el registro en la base de datos sigue indicando que `deleted=true` y `dependent=false`, volveríamos a ejecutar `terraform destroy`. El comando finaliza sin error, ya que Terraform  reconoce que no hay ningún cambio en la configuración y no hace nada. Tras la (no) destrucción del recurso, se actualizaría el campo `deleted_at` con la hora actual (por ejemplo, 00:00:05), y se iniciaría el ciclo de nuevo...

Para evitar este tipo de bucles infinitos, revisamos el valor del campo `deleted_at`; cuando el recurso se crea, el valor de este campo es nulo. Cuando el recurso se destruye, se registra la hora de la eliminación. Incluso si se modifica el registro de un recurso eliminado (por cualquier motivo), ya hemos visto que no hay problema con respecto a Terraform, que es capaz de darse cuenta de que no hay cambios en la configuración del recurso (sigue eliminado 😉). Revisando si el campo `deleted_at` ya ha sido informado, evitamos tener que actualizar de nuevo el campo en la base de datos y no caemos en el bucle infinito descrito antes.

```bash
terraform init

if $dry-run == enabled then {
  terraform plan
  exit 0
}
# dry-run is DISABLED from here...
if $deleted == false {
  terraform apply
  update record in database
  if $dependent == true {
    update dependent-records in database
  }
  exit 0
}
# deleted is TRUE from here...
if $dependent == true then {
  do nothing
  exit 0
}
# deleted is TRUE && dependent is FALSE from here...
if $deleted_at != "" {
  if $dry-run == testing {
    mock terraform destroy
  } else {
    terraform destroy
    deleted_at=now()
    update record(field:deleted_at) in database
  }
}
```

Después de esta comprobación *extra* (sobre el campo `deleted_at`) para evitar el bucle infinito, ya podemos proceder a eliminar el recurso.

Usamos el valor `testing` en la *meta-propiedad* `dry-run` y así podemos probar la *pipeline* sin tener que destruir los recursos en el *mundo real*.

## Resumen

Al evitar el anidamiento de condiciones y el uso de `else` en los condicionales, cada uno de los bloques tiene un enfoque más simple, más sencillo. No es necesario *recordar* el valor de múltiples variables, complicando el proceso de *debugging*: el análisis de cada una las casuísticas se realiza en su propio bloque de código; si aplica, sólo es necesario revisar unas pocas líneas de código. Si no aplica, descartamos el bloque completo y pasamos al siguiente...

Para simplificar todavía más *encontrar* el bloque adecuado, podemos incluir comentarios con el estado de los parámetros relevantes del recurso:

```bash
terraform init

# DRY-RUN: ENABLED
if $dry-run == enabled then {
  terraform plan
  exit 0
}
# DRY-RUN: DISABLED
if $deleted == false {
  terraform apply
  update record in database
  if $dependent == true {
    update dependent-records in database
  }
  exit 0
}
# DRY-RUN: DISABLED
# DELETED: TRUE
if $dependent == true then {
  do nothing
  exit 0
}
# DRY-RUN: DISABLED
# DELETED: TRUE
# DEPENDENT: FALSE
if $deleted_at != "" {
  if $dry-run == testing {
    mock terraform destroy
  } else {
    terraform destroy
    deleted_at=now()
    update record(field:deleted_at) in database
  }
}
```
