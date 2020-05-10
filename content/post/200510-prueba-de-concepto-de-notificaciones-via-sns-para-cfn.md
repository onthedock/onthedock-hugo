+++
draft = false

categories = ["dev"]
tags = ["aws", "cloudformation", "automation"]
thumbnail = "images/aws.png"

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

title=  "Prueba de Concepto de notificaciones via CloudWatch Events desde CloudFormation (sin Lambdas)"
date = "2020-05-10T00:42:51+02:00"
+++
En la entrada [Envío de eventos de CloudFormation a CloudWatch Events]({{< ref "200507-envio-de-eventos-de-cfn-a-cwevents.md" >}}) explicaba una manera alternativa -sin Lambdas- para enviar notificaciones SNS con información de ARNs de recursos generados en CloudFormation a través de CloudWatch Events.

En esta entrada explico cómo he realizado una prueba de concepto para validar que es viable.
<!--more-->

El objetivo de la prueba es ver si el concepto de usar la actualización en Parameter Store desde una plantilla de CloudFormation realmente permite disparar una regla en CloudWatch Events que lance una notificación a un *topic* SNS (configurado para enviar un correo) a través de CloudWatch Events.

El primer paso es crear una plantilla de CloudFormation que cree un recurso en AWS. Guardaremos el valor generado para ese recurso (el ARN de una policy) como parámetro en Parameter Store (también mediante CloudFormation).

Previamente debemos configurar los *servicios de soporte*, que son:

- *Topic* SNS de envío de notificaciones por correo (para recibir las notificaciones por correo, debemos validar la suscripción previamente)
- regla en CloudWatch Events

Empezamos por la plantilla de CloudFormation que genere una *política* gestionada.

## Plantilla para crear una *managed policy*

```yaml
AWSTemplateFormatVersion: 2010-09-09
Description: |
  Sample CloudFormation template
Resources:
  S3GetObjSamplePolicy:
    Type: "AWS::IAM::ManagedPolicy"
    Properties:
      Description: Simple S3 GetObject policy
      Path: /LAB/
      PolicyDocument:
        Version: 2012-10-17
        Statement:
        -
          Action: 's3:GetObject'
          Effect: 'Allow'
          Resource: '*'
  S3GetObjSamplePolicyARN:
    Type: "AWS::SSM::Parameter"
    Properties:
      Type: String
      Description: Simple S3 GetObject policy ARN
      Value: !Ref S3GetObjSamplePolicy
```

Validamos que la plantilla funciona correctamente y crea dos recursos:

- política gestionada `S3GetObjSamplePolicy` con *Physical ID* `arn:aws:iam::123456789012:policy/LAB/lab-managedpolicy-S3GetObjSamplePolicy-${random}`
- parámetro en SSM `S3GetObjSamplePolicyARN` con *Physical ID* `CFN-S3GetObjSamplePolicyARN-${random}`. El valor del parámetro es el ARN de la política creada.

Ahora configuramos los *servicios de soporte*. Empezamos creando el *el topic* que enviará las notificaciones por correo. Para ello, creamos el *topic* y la subscripción (por correo).

## Creación del *topic* SNS

Validamos que la siguiente plantilla crea el *topic* SNS con uns subscripción de envío vía correo:

> La dirección de correo **no se registra** en la traza almacenada en CloudTrail de la llamada a la API para realizar la creación de la suscripción.

```yaml
AWSTemplateFormatVersion: 2010-09-09
Parameters:
  TopicSubscriberEmail:
    Description: Email to send notifications to (requires confirming the subscription)
    Type: String
    Default: xavi.aznar@example.lab  
Resources:
  TopicForNotifications:
    Type: AWS::SNS::Topic
    Properties:
      Subscription:
        - Endpoint: !Ref TopicSubscriberEmail
          Protocol: email
      Tags:
        -
          Key:    'owner'
          Value:  'xavi'
        -
          Key:    'environment'
          Value:  'lab'
```

La suscripción envía un correo al buzón indicado y la creación de la suscripción queda en estado *Pending Validation*. Cuando se acepta la subscripción -mediante el enlace enviado- el estado cambia a *Confirmed*.

> Podemos validar el correcto funcionamiento del *topic* y la suscripción desde la consola, pulsando sobre el botón *Publish message*.

## Creación de la regla en CloudWatch Events

Añadimos una sección en la plantilla de CloudFormation de los *servicios de soporte* para crear la [regla en CloudWatch Events](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-events-rule.html).

Para obtener el `EventPattern` de manera sencilla, puedes crearlo desde la consola web de AWS (y después convertirlo a YAML):

```yaml
source:
- aws.ssm
detail-type:
- AWS API Call via CloudTrail
detail:
  eventSource:
  - ssm.amazonaws.com
  eventName:
  - PutParameter
```

> Una mejora -para la siguiente iteración- sería restringir el patrón para que sólo se *dispare* con los parámetros en un determinado *path*.  Primero creamos esta regla que *matchea* con la actualización de cualquier parámetro; cuando funcione, actualizamos la regla para *matchear* únicamente los parámetros en `/LAB/*`.

La segunda parte de la regla consiste en definir el *target* de la acción a realizar cuando se valide la regla definida.

En nuestro caso, actuaremos sobre un *topic* SNS. La propiedad `Targets` de una regla en CloudWatch Events debe contener uno o más elementos de tipo `Target`.

Un *target* requiere el ARN del recurso y un `Id` (que es el nombre que asignamos al *target*); el resto de parámetros son opcionales.

```yaml
Type: AWS::Events::Rule
Properties:
  EventPattern:
...
  Targets:
    -
      Arn: !Ref TopicForNotifications
      Id: !Ref TopicForNotifications
```

En la documentación se indica que debe facilitarse el ARN del rol que se asume cuando se ejecuta la regla. Este rol debe proporcionar permisos para que CloudWatch Events pueda enviar mensajes al *topic*.

Revisando el *topic* en la consola, vemos que tiene asociada una *access policy* que convierte en *público* para todos los *principals* de AWS en la cuenta (si lo interpreto correctamente (SPOILER: no es correcto)):

```json hl_lines="8 9"
{
  "Version": "2008-10-17",
  "Id": "__default_policy_ID",
  "Statement": [
    {
      "Sid": "__default_statement_ID",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": [
        "SNS:GetTopicAttributes",
        "SNS:SetTopicAttributes",
        "SNS:AddPermission",
        "SNS:RemovePermission",
        "SNS:DeleteTopic",
        "SNS:Subscribe",
        "SNS:ListSubscriptionsByTopic",
        "SNS:Publish",
        "SNS:Receive"
      ],
      "Resource": "arn:aws:sns:${region}:123456789012:lab-topic-TopicForNotifications-${random}",
      "Condition": {
        "StringEquals": {
          "AWS:SourceOwner": "123456789012"
        }
      }
    }
  ]
}
```

Una vez creados los *servicios de soporte*, lanzamos la plantilla original para crear los recursos (y el parámetro asociado), que debería disparar la regla de Events y enviarnos una notificación por correo vía SNS.

Aunque estoy realizando las acciones desde la consola con un rol de administrador, no recibo la notificación con el valor del ARN de la política creada.

### Troubleshooting

En CloudWatch Events se observa que al crear el parámetro vía CloudFormation, se disparan las reglas; sin embargo, vemos que además de las métricas *TriggeredRules* e *Invocation* también aumenta la cuenta de *FailedInvocations* para el *topic*.

Revisando la página de [Troubleshooting CloudWatch Events](https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/CWE_Troubleshooting.html), parece que la entrada que mejor se ajusta a mi situación es [My rule is being triggered but I don't see any messages published into my Amazon SNS topic](https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/CWE_Troubleshooting.html#NoMessagesPublishedSNS).

Siguiendo las instrucciones indicadas, lanzo desde la CLI:

```bash
aws sns get-topic-attributes --region $REGION --topic-arn $TOPICARN --profile local
```

La salida del comando -anonimizada- es:

```json
{
    "Attributes": {
        "SubscriptionsConfirmed": "1",
        "DisplayName": "",
        "SubscriptionsDeleted": "0",
        "EffectiveDeliveryPolicy": "{\"http\":{\"defaultHealthyRetryPolicy\":{\"minDelayTarget\":20,\"maxDelayTarget\":20,\"numRetries\":3,\"numMaxDelayRetries\":0,\"numNoDelayRetries\":0,\"numMinDelayRetries\":0,\"backoffFunction\":\"linear\"},\"disableSubscriptionOverrides\":false}}",
        "Owner": "123456789012",
        "Policy": "{\"Version\":\"2008-10-17\",\"Id\":\"__default_policy_ID\",\"Statement\":[{\"Sid\":\"__default_statement_ID\",\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"*\"},\"Action\":[\"SNS:GetTopicAttributes\",\"SNS:SetTopicAttributes\",\"SNS:AddPermission\",\"SNS:RemovePermission\",\"SNS:DeleteTopic\",\"SNS:Subscribe\",\"SNS:ListSubscriptionsByTopic\",\"SNS:Publish\",\"SNS:Receive\"],\"Resource\":\"arn:aws:sns:${region}:123456789012:lab-topic-TopicForNotifications-${random}\",\"Condition\":{\"StringEquals\":{\"AWS:SourceOwner\":\"123456789012\"}}}]}",
        "TopicArn": "arn:aws:sns:${region}:123456789012:lab-topic-TopicForNotifications-${random}",
        "SubscriptionsPending": "0"
    }
}
```

Formateando mejor la salida se puede observar que en la respuesta sólo aparece la politica por defecto:

```json
Policy": "{
  \"Version\":\"2008-10-17\",
  \"Id\":\"__default_policy_ID\",
  \"Statement\":[{
    \"Sid\":\"__default_statement_ID\",
    \"Effect\":\"Allow\",
    \"Principal\":{\"AWS\":\"*\"},
    \"Action\":[
        \"SNS:GetTopicAttributes\",
        \"SNS:SetTopicAttributes\",
        \"SNS:AddPermission\",
        \"SNS:RemovePermission\",
        \"SNS:DeleteTopic\",
        \"SNS:Subscribe\",
        \"SNS:ListSubscriptionsByTopic\",
        \"SNS:Publish\",
        \"SNS:Receive\"
    ],
    \"Resource\":\"arn:aws:sns:${region}:123456789012:lab-topic-TopicForNotifications-${random}\",
    \"Condition\":{
      \"StringEquals\":{
        \"AWS:SourceOwner\":\"123456789012\"
      }
    }
  }]
}",
```

La política por defecto no proporciona permisos de `Publish` a `events.amazonaws.com`, por lo que debemos establecerlo para que la regla de Events pueda publicar mensajes en el *topic* SNS.

Actualizamos la plantilla de CloudFormation para incluir la política y dar permisos a CloudWatch Events:

```yaml hl_lines="4 5 6 7 8 9 10 11 12 13 14 15"
  EventsRuleForSSMPutParameter:
    Type: "AWS::Events::Rule"
...
  EventTopicPolicy:
    Type: 'AWS::SNS::TopicPolicy'
    Properties:
      PolicyDocument:
        Statement:
          - Effect: Allow
            Principal:
              Service: events.amazonaws.com
            Action: 'sns:Publish'
            Resource: '*'
      Topics:
        - !Ref TopicForNotifications
```

Repitiendo la comprobación indicada en la página de *troubleshooting* (he formateado la salida para que sea más fácil identificar la parte resaltada):

```bash hl_lines="9 10 11 12 13 14 15 16 17"
$ aws sns get-topic-attributes --region $REGION --topic-arn $TOPICARN --profile local
{
    "Attributes": {
        "SubscriptionsConfirmed": "1",
        "DisplayName": "",
        "SubscriptionsDeleted": "0",
        "EffectiveDeliveryPolicy": "{\"http\":{\"defaultHealthyRetryPolicy\":{\"minDelayTarget\":20,\"maxDelayTarget\":20,\"numRetries\":3,\"numMaxDelayRetries\":0,\"numNoDelayRetries\":0,\"numMinDelayRetries\":0,\"backoffFunction\":\"linear\"},\"disableSubscriptionOverrides\":false}}",
        "Owner": "123456789012",
        "Policy": "{\"Version\":\"2008-10-17\",
          \"Statement\":[{
            \"Effect\":\"Allow\",
            \"Principal\":{
              \"Service\":\"events.amazonaws.com\"
            },
            \"Action\":\"sns:Publish\",
            \"Resource\":\"*\"}
          ]}",
        "TopicArn": "arn:aws:sns:${region}:123456789012:lab-topic-TopicForNotifications-${random}",
        "SubscriptionsPending": "0"
    }
}
```

Una vez actualizada la política, debería funcionar correctamente.

Borramos el *stack* anterior -correspondient a la creación del recurso y el parámetro y validamos que tras asignar los permisos, se dispara la regla y se envía la notificación vía  SNS.
