+++
draft = false
categories = ["dev"]
tags = ["aws", "iam"]
thumbnail = "images/aws.png"
# Enlaces internos 

# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}

title=  "Tipos de Principals en AWS"
date = "2020-05-10T09:01:57+02:00"
+++
En la entrada anterior [Prueba de Concepto de notificaciones via CloudWatch Events desde CloudFormation (sin Lambdas)]({{< ref "200510-prueba-de-concepto-de-notificaciones-via-sns-para-cfn.md" >}}) el primer intento de enviar notificaciones al *topic* a través de CloudFormation falló, aunque estaba autenticado en AWS con un usuario Administrador y las pruebas realizadas de envío de la consola habían sido un éxito.

El problema estaba en el *Principal* con permisos sobre el *topic*, por lo que tuve que cambiar de `"Principal": {"AWS": "*" }` a `"Principal": { "Service": "events.amazonaws.com" }`.

En esta entrada intento explicar la diferencia entre estos los diferentes tipos de *Principals* y su uso en las políticas.
<!--more-->

La documentación oficial al respecto la puedes encontrar en [AWS JSON Policy Elements: Principal](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_principal.html).

Una política en AWS define **quién** puede realizar una **acción** sobre un **recurso**; un *Principal* especifica el **quién**. La clave está en que hay **diferentes tipos** de *quienes*.

Como ves más arriba en la entrada, tenemos *Principals* que son `{"AWS": "*" }` y otros `{ "Service": "${nombreServicio}.amazonaws.com" }` (hay alguno más).

Una forma de diferenciarlos podría ser pensar que los *Principals* `AWS` representan identidades asumibles por un ser humano (como un usuario IAM), mientras que los *Principals* de tipo `Service` representan la identidad de un servicio de AWS.

En cualquier caso, vamos a centrarnos sólo en el caso de los servicios. Un rol que puede ser asumido por un servicio se denomina [service role](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts.html#iam-term-service-role).

Para que un rol pueda ser asumido por una identidad, se debe establecer una *trust policy* que indique qué *principal* (pueden ser más de uno) puede asumir el rol. En el caso de que quien pueda asumir el rol sea un servicio, el *principal* de la *trust policy* para un servicio debe ser un *service principal* (un *principal* de tipo `Service`).

Las *trust policies* son *resource-based policies*, ya que están asignadas a un **recurso** y que indican quién puede asumir el rol (como indica la documentación oficial sobre los *Principal*: [AWS JSON Policy Elements: Principal](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_principal.html)). Al fin y al cabo, un rol sólo es un "paquete de permisos", que agrupan las acciones que se pueden realizar sobre determinados recursos, pero que en general, no incluyen **quién** puede realizar esas acciones. Ese **quién** se especifica en la *trust policy*.

En mi humilde opinión, en la página sobre los *Principal* en AWS falta la referencia a las **identidades**. En el caso de usuarios IAM, la "identidad" del *principal* se gestiona desde AWS (a través del servicio IAM) y el *principal* es `"Principal": { "AWS": "${ARN de un usuario IAM}" }`. Cuando la identidad es **externa** (o no es gestionada por IAM, para ser más específicos), en el *principal* se indica como `"Principal: { "Federated": "${proveedor-externo}" }`. En todos estos casos, una *identidad* es un objeto que tiene que identificarse presentando un secreto para obtener acceso. Una vez se ha validado el secreto, el sistema reconoce la identidad y le asigna unos permisos (que autorizan a la identidad a realizar acciones).

Los roles no son *identidades*, sino **recursos** (como un *bucket* o una *clave* en KMS). Para determinar **quién** puede hacer qué sobre el recurso, debemos asociar una *resource-based policy*. En esta política especificamos la *identidad* que puede realizar acciones sobre el recurso. En el caso de un *bucket*, la política que indica quién puede hacer qué en el *bucket* se denomina *bucket policy*. En el caso de un *rol*, tenemos dos políticas separadas: la *trust policy* que especifica únicamente quién puede asumir el rol (indica el *principal*), y las políticas IAM, que especifican qué acciones puede realizar el *principal* que ha asumido el rol sobre **recursos de todos los servicios**.

En una *bucket policy* los permisos gestionados son siempre relativos al propio servicio S3, es decir `s3:PutObject`, `s3:GetObject`, etc... Lo mismo para una clave en KMS: `kms:Describe*`, `kms:Get*`, etc... El tema es que los recursos que gestiona IAM son **los permisos sobre todos los servicios ofrecidos por AWS**, lo que es un poco *recursivo*.

Si entiendes que **un rol es un recurso**, como pueda lo es un *bucket*, entonces parece evidente que para que un servicio pueda asumir el rol debemos especificar la identidad del *principal* del servicio al que queremos proporcionar acceso mediante `"Principal": { "Service": "${nombreServicio}.amazonaws.com" }`.

Sin embargo, la documentación indica que **no debe especificarse** un *Principal* en una política que asignemos a un usuario o un grupo, ya que en estos casos implícitamente el *principal* se obtiene del usuario al que está asociada la política. (En el caso del grupo, el grupo **no es un _principal_**, pero contiene usuarios que sí que lo son, que son de donde se obtiene el *principal* para la *policy*).

## Volviendo a los problemas de permisos sobre el *topic*

La confusión surgió porque la política aplicada al *topic* SNS por defecto proporciona acceso al propietario del *topic* (quien lo ha creado) mediante una combinación de `"Principal": {"AWS": "*"}` y una condición que restringe al `AWS:SourceOwner`:

```json
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
       ...
      ],
      "Resource": "arn:aws:sns:${region}:123456789012:${nombreTopic}",
      "Condition": {
        "StringEquals": {
          "AWS:SourceOwner": "123456789012"
        }
      }
    }
  ]
}
```

Ese `"AWS": "*"` que aparece como *principal* me confundió al parecer que da permisos a "todo lo que hay en AWS", incluidos los servicios. Sin embargo, `"AWS": "*"` sólo proporciona acceso a identidades IAM (no a Servicios).

Como ves, es fácil olvidar que, a parte de los permisos que tiene un usuario (las *identity-based policies*), hay otras políticas que también se evalúan antes de poder realizar una acción: *Service Control Policies*, las *resource-based policies*, *boundary policies* y *session policies*.

Como un *topic* tiene asociada una *resource-based policy*, hay que indicar el *principal* de quien va a realizar acciones sobre el mismo. En este caso, el *principal* es CloudWatch Events, que es un **servicio**, por lo que el *principal* es `"Princial": { "Service": "events.amazonaws.com" }`.

## Conclusión

Debo revisar la página [Policy Evaluation Logic](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html) y estudiarla a fondo; creo que al final me imprimiré y colgaré el diagrama de [Determining Whether a Request Is Allowed or Denied Within an Account](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html#policy-eval-denyallow) en un sitio que siempre tenga a la vista:

{{< figure src="/images/200510/PolicyEvaluationHorizontal.png" w="1111" h="511" caption="Policy evaluation whitin an account" >}}
