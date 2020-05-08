+++
draft = false

categories = ["dev"]
tags = ["cloud", "aws", "cloudformation"]
thumbnail = "images/aws.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" %}}

title=  "Envío de eventos de CloudFormation a CloudWatch Events"
date = "2020-05-07T19:25:58+02:00"
+++
Recientemente ha surgido la necesidad de notificar por correo valores como respuesta a la creación de recursos vía CloudFormation. En la notificación debe incluirse información relativa a los recursos creados en el *stack* (como el ARN de un rol o el ID de un *security group*).

La solución habitual/recomendada es ejecutar una Lambda que envíe un mensaje a un *topic* SNS configurado para enviar un correo con el ARN del rol recién creado, por ejemplo. En la [propuesta del Soporte Premium de AWS](https://aws.amazon.com/premiumsupport/knowledge-center/cloudformation-rollback-email/) se lanza la notificación cuando se produce un *rollback* del *stack*, pero se podría modificar el evento para lanzar la notificación con `CREATION_COMPLETE`.

En este ejemplo se envía el error que se ha producido en la notificación, pero podría modificarse para incluir alguna otra información generada en tiempo de ejecución (como el ARN o ID de algún recurso creado por el *stack*).

Sin embargo en este artículo exploro una vía alternativa que, en mi opinión, puede ser más adecuada en determinados escenarios y que permite no tener que escribir ni una línea de código (usando sólo servicios de AWS).
<!--more-->

Al provisionar recursos mediante CloudFormation, puedes "traspasar" información de un *stack* a otro mediante los [*outputs*](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/outputs-section-structure.html).

Me gustaría poder extender esta capacidad de reaccionar a la creación de recursos en CloudFormation manteniendo la capacidad de traspasar información sobre los recursos creados, sin tener que escribir código.

## La situación ideal

Lanzo una plantilla de CloudFormation y se generan unos cuantos recursos.

A medida que CloudFormation procesa la plantilla se lanzan una serie de eventos. Estos eventos está asociados al estado de creación de los diferentes recursos descritos en la plantilla. En esta página de la documentación de CloudFormation tienes un ejemplo de los eventos que se generan para una plantilla que crea un *bucket* S3: [Viewing Stack Event History](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-listing-event-history.html).

Parecería lógico que estos eventos se recogiesen en CloudWatch Events, con la información que ofrece el comando `aws cloudformation describe-stack-events --stack-name myteststack`:

```json
{
    "StackEvents": [
        {
            "StackId": "arn:aws:cloudformation:us-east-2:123456789012:stack/myteststack/466df9e0-0dff-08e3-8e2f-5088487c4896",
            "EventId": "af67ef60-0b8f-11e3-8b8a-500150b352e0",
            "ResourceStatus": "CREATE_COMPLETE",
            "ResourceType": "AWS::CloudFormation::Stack",
            "Timestamp": "2013-08-23T01:02:30.070Z",
            "StackName": "myteststack",
            "PhysicalResourceId": "arn:aws:cloudformation:us-east-2:123456789012:stack/myteststack/a69442d0-0b8f-11e3-8b8a-500150b352e0",
            "LogicalResourceId": "myteststack"
        },
        {
            "StackId": "arn:aws:cloudformation:us-east-2:123456789012:stack/myteststack/466df9e0-0dff-08e3-8e2f-5088487c4896",
            "EventId": "S3Bucket-CREATE_COMPLETE-1377219748025",
            "ResourceStatus": "CREATE_COMPLETE",
            "ResourceType": "AWS::S3::Bucket",
            "Timestamp": "2013-08-23T01:02:28.025Z",
            "StackName": "myteststack",
            "ResourceProperties": "{\"AccessControl\":\"PublicRead\"}",
            "PhysicalResourceId": "myteststack-s3bucket-jssofi1zie2w",
            "LogicalResourceId": "S3Bucket"
        },
...
```

Los diferentes eventos para todos los recursos de un *stack* se podrían agrupar de manera similar a como se agrupan los logs en un *flow log group name* en CloudWatch Logs, por ejemplo.

Pero no; **CloudFormation no envía los eventos a CloudWatch Events**, como puedes comprobar en [CloudWatch Events Event Examples From Supported Services](https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/EventTypes.html) (en Mayo 2020).

### La recomendación oficial

Suponiendo que no sigues la sugerencia de crear una función Lambda que reaccione a los eventos de CloudFormation,  Amazon recomienda [usar el registro que dejan las llamadas de CloudFormation en CloudTrail](https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/EventTypes.html#events-for-services-not-listed).

El problema de esta solución es que lo que queda registrado en CloudTrail es la llamada a la API y en un gran número de casos, esta llamada no devuelve información sobre el recurso creado. Esto es debido a que la llamada a la API devuelve un identificador de la petición. Este identificador se puede usar en llamadas posteriores -por ejemplo, desde la CLI- para revisar el estado de la petición, pero no ayuda en el caso de CloudFormation (que devuelve el *request id* para el *stack*).

## Buscando una alternativa

Del mismo modo que los valores de salida de un *stack* se encuentran disponibles para otros *stacks*, queremos que otros servicios a parte de CloudFormation puedan usarlos (como parámetros de entrada) cuando son creados o actualizados sin necesidad de escribir una Lambda.

Como decía al principio, la opción más directa es usar una función Lambda. Pero en mi opinión esto añade una nueva pieza al *workflow* que debemos mantener. Además, por un lado tendremos la plantilla de CloudFormation y por otro el código de la Lambda...

Como solución alternativa -sin necesidad de tener que escribir una línea de código- tienes otro servicio de AWS que **[sí que envía eventos a CloudWatch Events](https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/EventTypes.html#SSM-Parameter-Store-event-types)**: *Systems Manager Parameter Store*.

## Systems Manager Parameter Store

La ventaja de Systems Manager Parameter Store es que podemos introducir el valor de una referencia a un recurso de CloudFormation **directamente desde CloudFormation**, ya que el parámetro en Parameter Store es, simplemente, un recurso más gestionado por el *stack*.

Usando como base el ejemplo en la documentación sobre parámetros de Parameter Store en CloudFormation [AWS Systems Manager Parameter String Example](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ssm-parameter.html#aws-resource-ssm-parameter--examples), podemos usar como valor del parámetro una referencia a otro recurso creado en el mismo *stack* (o como *output* de otros *stacks*):

```yaml
Resources:
    BasicParameter:
        Type: AWS::SSM::Parameter
        Properties:
            Name: EC2InstanceId
            Type: String
            Value: !Ref EC2Instance
            Description: Target instance for running date command.
```

## Entrando a fondo en los detalles

Los anglosajones dicen [The devil is in the detail](https://en.wikipedia.org/wiki/The_devil_is_in_the_detail) cuando una cosa parece sencilla al principio pero que, al entrar al detalle, es mucho más complicada de lo que parece inicialmente.

Algo parecido pasa en este caso; aunque los eventos asociados a la modificación de un parámetro en Parameter Store sí que se envían a CloudWatch Events, no contienen toda la información en la que estoy interesado; en particular, **no registran el valor del parámetro**, sólo su nombre. Esto limita la información que podemos traspasar a otros servicios.

En el [evento de ejemplo que ofrece AWS](https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/EventTypes.html#SSM-Parameter-Store-event-types) para la actualización de un parámetro, vemos que en `$.detail` aparece el campo `"name": "foo"`, pero no hay un campo para `"value"`:

```json
{
  "version": "0",
  "id": "9547ef2d-3b7e-4057-b6cb-5fdf09ee7c8f",
  "detail-type": "Parameter Store Change",
  "source": "aws.ssm",
  "account": "123456789012",
  "time": "2017-05-22T16:44:48Z",
  "region": "us-east-1",
  "resources": [
    "arn:aws:ssm:us-east-1:123456789012:parameter/foo"
  ],
  "detail": {
    "operation": "Update",
    "name": "foo",
    "type": "String",
    "description": "Sample Parameter"
  }
}
```

## Volviendo -más o menos- a la recomendación oficial

Systems Manager Parameter Store envía información asociada al evento a CloudWatch Events; además, la llamada a la API de Parameter Store queda registrada en CloudTrail.

Revisando la información contenida en CloudTrail para la acción `PutParameter` realizada en Parameter Store, observamos que incluye una sección llamada `requestParameters` que contiene tanto el **nombre** del parámetro como el **valor** del parámetro:

```json
...
"requestParameters": {
    "name": "myparameter",
    "description": "Test parameter",
    "value": "LAB-test-parameter",
    "type": "String",
    "overwrite": true,
    "tier": "Standard"
},
...
```

Es decir, que usando en el evento de CloudTrail sí que tenemos la información que pasamos desde CloudFormation.

## Reaccionando a la creación del recurso (sin Lambdas!)

Recuerda que el objetivo es poder hacer "algo" con los valores "dinámicos" generados durante la creación de un recurso vía CloudFormation (como el ARN de un rol o el ID de un *security group*). Ese "algo" que queremos hacer es pasar la información a otro servicio de AWS (por ejemplo, enviando un mensaje a un *topic* SNS).

La clave de usar el registro en CloudWatch Events es que podemos definir reglas que actúen cuando se produce una modificación de un determinado recurso. Para ello, en la plantilla de CloudFormation tenemos la creación del recurso en sí, que produce un identificador en el que estamos interesados. Como CloudFormation no envía la información a CloudWatch Events, no me entero de que se ha creado un recurso concreto ni cuales son sus propiedades. Sin embargo, dentro del *stack* este valor está disponible como una *referencia*, que puedo usar en la propia plantilla en la creación de otro recurso; un parámetro de Parameter Store.

Como hemos visto hasta ahora, aunque Parameter Store envía el evento a CloudWatch Events, no contiene el valor del parámetro. La información sí que se encuentra en el registro en CloudTrail de la creación/actualización del recurso vía API desde CloudFormation.

Siguiendo las instrucciones en [Creating a CloudWatch Events Rule That Triggers on an AWS API Call Using AWS CloudTrail](https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/Create-CloudWatch-Events-CloudTrail-Rule.html), podemos definir una regla que reaccione cuando se produce un determinado evento.

En patrón del evento sería del tipo:

```json
{
  "source": [
    "aws.ssm"
  ],
  "detail-type": [
    "AWS API Call via CloudTrail"
  ],
  "detail": {
    "eventSource": [
      "ssm.amazonaws.com"
    ],
    "eventName": [
      "PutParameter"
    ]
  }
}
```

Si organizas los parámetros en Parameter Store como las "rutas" en "carpetas" de los objetos en S3 (o de los *path* para entidades en IAM), puedes crear reglas específicas para la modificación de parámetros de un determinado proyecto, incluyendo en el patrón de eventos los *resources* que debe monitorizar una regla: [Event Patterns in CloudWatch Events](https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/CloudWatchEventsandEventPatterns.html).

```json
...
"resources": [
    "arn:aws:ssm:${region}:${accountID}:parameter/${idProyecto}"
],
...
```

Con la regla configurada en CloudWatch Events, cada vez que se modifique un parámetro compatible con la lista de recursos incluidos en la regla, se dispara una acción.

## Enviando una notificación desde CloudWatch Events

Con CloudWatch Events puedes elegir (en estos momentos, en Mayo del 2020) 17 *targets* para realizar una acción en respuesta a la detección de un evento concreto. Puedes consultar la lista completa de *targets* en [What Is Amazon CloudWatch Events?](https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/WhatIsCloudWatchEvents.html).

Siguiendo con nuestro escenario inicial de notificar sobre la creación de un determinado recurso, tenemos la opción de ejecutar una Lambda, reiniciar una instancia EC2 o enviar el mensaje a un bus de eventos de otra cuenta AWS. Puedes consultar una lista de [CloudWatch Events Tutorials](https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/CloudWatch-Events-Tutorials.html).

Al configurar el *target*, podemos incluir la información del evento tal y como lo hemos recibido en CloudWatch, sólo una parte del evento e incluso transformar el contenido del evento recibido para adecuarlo a lo que espera el servicio configurado como destino.

## Diagrama de la solución (aka TL;DR)

En el siguiente diagrama se muestra el esquema de las acciones que hemos configurado para poder obtener una notificación con información de un evento creado vía CloudFormation.

{{% img src="images/200507/reacting-to-resource-creation-on-cfn-wout-lambdas.svg" %}}

La clave del mecanismo es poder enviar un evento con la información que necesitamos a CloudWatch desde CloudFormation. Usamos la capacidad de "disparar" acciones basándose en determinadas reglas como sustituto de la ejecución de una Lambda.

En cierto modo, usamos la creación/modificación de un parámetro en Parameter Store como alternativa basada en CloudFormation a la llamada a la API para [`PutEvents`](https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/AddEventsPutEvents.html), lo que nos permite crear un "evento personalizado" desde CloudFormation (más o menos).

## Conclusión y siguientes pasos

Usando Parameter Store para almacenar información de los recursos creados mediante una plantilla de CloudFormation podemos evitar el uso de Lambda para traspasar información a otros servicios.

He probado el concepto a través de la consola mientras realizaba la "investigación" del contenido de los eventos generados por los servicios y funciona. Queda pendiente realizar una prueba "real" con la creación de un recurso vía CloudFormation.
