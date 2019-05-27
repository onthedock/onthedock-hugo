+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["aws", "cloud", "instance scheduler"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/aws.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}


title=  "AWS Instance Scheduler"
date = "2019-05-26T14:07:10+02:00"
+++
[AWS Instance Scheduler](https://docs.aws.amazon.com/solutions/latest/instance-scheduler/welcome.html) permite gestionar el arranque y parada automáticos de instancias EC2 y bases de datos del servicio AWS RDS de forma programada.
Esta es una de las formas más sencillas de ahorrar en el uso de estos servicios de AWS: apagándolos cuando no se necesitan (por ejemplo en entornos de desarrollo o de test).
<!--more-->
Amazon proporciona una plantilla de _AWS CloudFormation_ que permite desplegar todos los recursos necesarios de forma automática.

## Cómo funciona AWS Instance Scheduler

{{% img src="images/190526/instance-scheduler-architecture.png" w="822" h="460" class="center" caption="AWS Instance Scheduler Architecture" href="https://docs.aws.amazon.com/solutions/latest/instance-scheduler/architecture.html" %}}

La plantilla de CloudFormation configura eventos en Amazon CloudWatch de manera que se ejecute una acción -la ejecución de una función Lambda- con la frecuencia que especifiquemos.

La función _NombreDelStack-InstanceSchedulerMain_ lee la configuración de una tabla de DynamoDB con los periodos en los que las instancias tienen que estar en ejecución.

Cuando se ejecuta la _lambda_, se comprueban las etiquetas aplicadas a las instancias y se encienden o apagan según corresponda.

## Definir _schedules_ y _periods_

En mi opinión este es uno de los puntos mejorables de la documentación de AWS Instance Scheduler.

En la documentación no se indica -en mi opinión- con suficiente detalle cómo crear estos periodos o programaciones. Se indica, eso sí, que se pueden crear desde la consola de DynamoDB, desde un [_custom resource_](https://docs.aws.amazon.com/solutions/latest/instance-scheduler/appendix-d.html) o desde el _AWS Instance Scheduler CLI_ (un script en Python), pero no cómo hacerlo.

Curiosamente, si revisas los elementos que contiene la tabla `<NombreDelStack>-ConfigTable-...`, verás que sí que contiene algunas entradas (tanto para definir periodos como _schedules_):

{{% img src="images/190526/rds-config-table-default-items.png" w="833" h="483" class="center" %}}

Estos valores no aparcen en el fichero de CloudFormation, por lo que no tengo claro desde dónde se introducen en la base de datos.

### Definiciones

Tienes la información de qué es un [_schedule_](https://docs.aws.amazon.com/solutions/latest/instance-scheduler/components.html#schedules) y un [_period_](https://docs.aws.amazon.com/solutions/latest/instance-scheduler/components.html#period-rules) en la documentación.

Un _period_ especifica el tiempo en el que la máquina debe arrancar y apagarse. Un _schedule_ puede contener más de un _period_. Por ejemplo, podríamos crear un _schedule_ que contenga dos periodos, uno de mañana y otro de tarde (de manera que las máquinas estarían apagadas durante el mediodía).

También puedes _reutilizar_ un _period_ en diferentes _schedules_, ya que la **zona horaria** se define en el _schedule_.

El periodo de "horas de oficina" podría ser el mismo en dos ubicaciones, por ejemplo, de 09h a 17h. Sin embargo, la hora "global" de arranque de las máquinas no sucede a la vez si la zona horaria es `Europe/London` que si es `America/Barbados`, por ejemplo. En este caso, tendríamos que crear dos _schedules_ diferentes, uno llamado `london-office-hours` y `barbados-office-hours`, por ejemplo.

### Paso a paso

A la práctica, la forma más rápida para poder crear tus propios periodos de actividad para las instancias es a través de la consola de DynamoDB.

Selecciona la tabla `...-ConfigTable-...` y la pestaña _Items_ para ver las entradas de esta tabla (los de la imagen superior).

Selecciona un _period_ y en el desplegable _Actions_, selecciona _Duplicate_. A partir de ahí edita el nuevo ítem para ajustarlo al periodo que quieres definir.

Por ejemplo, el siguiente periodo define como hora de inicio (arranque de las máquinas) las 06h, apagándolas a las 18h de lunes a viernes.

```json
{
  "begintime": {
    "S": "06:00"
  },
  "description": {
    "S": "06-18"
  },
  "endtime": {
    "S": "18:00"
  },
  "name": {
    "S": "06-18"
  },
  "type": {
    "S": "period"
  },
  "weekdays": {
    "SS": [
      "mon-fri"
    ]
  }
}
```

A continuación, repito el proceso para duplicar un _schedule_ y lo "asocio" al periodo definido mediante el uso de la propiedad `name`:

```json
{
  "description": {
    "S": "Schedule for 06h-18h"
  },
  "name": {
    "S": "schedule-06-18"
  },
  "periods": {
    "SS": [
      "06-18"
    ]
  },
  "timezone": {
    "S": "Europe/Madrid"
  },
  "type": {
    "S": "schedule"
  }
}
```

## Aplicando la etiqueta a las instancias (o RDS)

Para que AWS Instance Scheduler identifique qué recursos debe gestionar, en la configuración del CloudFormation indicamos la etiqueta que la función Lambda buscará al inspeccionar las instancias EC2 o bases de datos RDS.

Esta etiqueta, por defecto, es `Schedule`. El valor de la etiqueta debe ser uno de los _schedule_ definidos en la base de datos DynamoDB.

Un detalle importante que debes considerar es que **las etiquetas distinguen entre mayúsculas y minúsculas** (ver [Tag Restrictions](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html#tag-restrictions)), por lo que `Schedule` y `schedule` no son iguales.

## Etiquetado automático de las instancias arrancadas/paradas por AWS Instance Scheduler

Un detalle muy interesante de AWS Instance Scheduler es que permite etiquetar automáticamente las instancias iniciadas/detenidas. En la documentación se indica, por ejemplo:

Example Parameter Input | Instance Scheduler Tag
------------------------|---------------------
`ScheduleMessage=Started on {year}/{month}/{day} at {hour}:{minute} {timezone}` | `ScheduleMessage=Started on 2017/07/06 at 09:00 UTC`

Esto puede ayudar en aquipos en los que la administración de las instancias (o el control de costes) está separado de los usuarios finales de las instancias, de manera que sepan porqué motivo la instancia se encuentra parada, por ejemplo.

## Otros parámetros interesantes de los _schedules_

Revisa los parámetros de los _schedules_ porque hay algunos que permiten implementar medidas interesantes, como el `enforced`, el `override_status` o el `use_maintenance_window` para RDS.

Por ejemplo, estableciendo el `enforced` a `true`, AWS Instance Scheduler detendrá una instancia incluso si se arranca manualmente fuera del periodo definido. Debes recordarlo si algún día ves quieres arrancar una máquina fuera del _schedule_ configurado y ésta se apaga una y otra vez ;)

Otra medida interesante puede ser establecer un periodo que sólo tenga _endtime_  -desde el punto de vista de recortar gastos-, de manera que las instancias se apaguen siempre a una determinada hora, pero que no arranquen automáticamente. Esto puede ser útil en entornos de desarrollo o de test en los que las instancias se usen sólo de forma esporádica, arrancándose de forma manual o como respuesta a algún evento, para evitar que se queden arrancadas indefinidamente.

## Soporte multicuenta

Hacia el final de la página sobre AWS Instance Scheduler se menciona lo que es, para mí, una de las mejores características de esta solución: **¡soporte multicuenta!**

{{% img src="images/190526/aws-instance-scheduler-features.png" w="934" h="471" class="center" %}}

Gracias a esta característica puedes definir una serie de _schedules_ en una cuenta y aplicarlos sobre el resto de cuentas en las que tienes instancias/RDS.

Si tienes una cuenta por equipo de desarrollo, por ejemplo, imagina el tiempo que tendrías que dedicar a configurar una y otra vez los mismos _schedules_...

Después de haber tenido que lidiar con los problemas de dar permisos de ejecución sobre Lambdas entre diferentes cuentas, el hecho de poder contar con un CloudFormation que simplifique el proceso para AWS Instance Scheduler me parece espectacular.

Tengo todavía pendiente probarlo para ver cómo de sencillo es _en la práctica_, pero al revisar el fichero de CloudFormation, parece que en la cuenta secundaria sólo es necesario proporcionar el ARN del Role definido por el CloudFormation en la cuenta "principal".

Si has elegido que el CloudFormation genere el role automáticamente, el ARN, éste tendrá la siguiente forma: `arn:aws:iam::<Account>:role/<NombreStack>-SchedulerRole-<RandomAlphaNumeric>`.

## Resumen

AWS Instance Scheduler es una solución que permite reducir los costes -e incluso la seguridad de tu entorno- asegurando que las máquinas sólo se usan dentro de los horarios definidos.

Si buscas en YouTube, esta era una función que antes de la existencia de esta solución la gente estaba implementando de forma más o menos "casera", por lo que disponer de un producto tan práctico y bien ejecutado es un gustazo.

¡Pruébalo y dime qué te parece!