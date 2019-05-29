+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["cloud", "aws", "instance scheduler"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/aws.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" %}}

title=  "Instance Scheduler Cross Account"
date = "2019-05-29T19:47:29+02:00"
+++
En la entrada [AWS Instance Scheduler]({{<ref "190526-aws-instance-scheduler.md" >}}) indicaba cómo configurar AWS Instance Scheduler en una cuenta. Sin embargo, una de las capacidades más interesantes de esta solución de Amazon es la posibilidad de programar el encendido (y/o apagado) de instancias en diferentes cuentas.
<!--more-->

Esto permite configurar la programación en una cuenta -que llamaremos primaria- y gestionar instancias de otras cuentas _secundarias_.

## Configuración en la cuenta primaria

La configuración de AWS Instance Scheduler consiste en aplicar el fichero _CloudFormation_ y dejar que la automatización haga su magia.

Si estás interesado en algo más de detalle, revisa la entrada [AWS Instance Scheduler]({{<ref "190526-aws-instance-scheduler.md" >}}).

A grandes rasgos, Instance Scheduler realiza las siguientes acciones:

1. El fichero _cloudformation_ genera una regla en CloudWatch de manera que se dispare un evento cada 5 minutos (este es el intervalo por defecto).

1. Como respuesta al evento, se lanza una función lambda.

1. La función lambda conecta a una base de datos DynamoDB, de donde obtiene la configuración.

1. La función lambda consulta las etiquetas aplicadas a las instancias; si coincide con la definida en la configuración, arranca (o detiene) la instancia de acuerdo con el periodo y la programación almacenada en la tabla de DynamoDB.

1. La función lambda aplica una etiqueta informativa en la instancia (opcionalmente) y guarda el resultado en la base de datos.

La función lambda requiere permisos para poder consultar la base de datos y para actuar sobre las instancias EC2.

La plantilla de CloudFormation permite crear las políticas y roles de forma automática, lo que resulta muy conveniente.

## Configuración en la cuenta secundaria

Amazon proporciona un fichero cloudformation específico para la configuración de Instance Scheduler en cuentas secundarias.

Cuando ejecutas CloudFormation en una cuenta secundaria, lo único que debes proporcionar es el ID de la cuenta primaria.

Esto permite a CloudFormation crear una _relación de confianza_ con la cuenta primaria en el rol con permisos para actuar sobre las instancias EC2 en la cuenta secundaria.

## Actualización del _stack_ en la cuenta primaria

En IAM de la cuenta secundaria, anota el ARN del rol `Scheduler`.

Cambia a la cuenta primaria y en CloudFormation, actualiza el _stack_ usando la plantilla existente.

Revisa los diferentes campos hasta encontrar uno en el que debes indicar el ARN en la cuenta secundaria.

Al informar del ARN del rol con permisos para arrancar las instancias, se modifica la política asociada a la lambda en la cuenta primaria de manera que pueda asumir el rol en la cuenta secundaria.

De esta forma, _extendemos_ la capacidad de gestionar instancias EC2 de la lambda a la cuenta secundaria.

## Ventajas de la configuración multi-cuenta

Puedes repetir el proceso indicado para la cuenta secundaria en tantas cuentas como quieras.

De esta forma puedes tener toda la gestión de arrancada y parada de máquinas centralizada, almacenada en una única tabla de DynamoDB y aplicar diferentes _schedules_ en tantas cuentas como quieras, simplificando el mantenimiento.