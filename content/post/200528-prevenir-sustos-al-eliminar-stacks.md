+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["aws", "cloudformation"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/aws.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" %}}

title=  "Prevenir sustos al eliminar stacks de CloudFormation"
date = "2020-05-28T19:54:41+02:00"
+++
> Actualizado 24 Julio 2020.

Al eliminar un *stack* de CloudFormation **todos** los recursos creados por el *stack* se eliminan automáticamente. Esto te puede provocar un buen susto cuando eliminas uno por error...

En esta entrada indico cómo prevenir esas situaciones a diferentes niveles: aplicando *stack policies* a todo el *stack* o de forma individual en algunos recursos con *DeletionPolicy*.
<!--more-->

## DeletionPolicy: Retain

Empezamos con el [DeletionPolicy Attribute](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-deletionpolicy.html), una propiedad que puedes especificar a nivel de recurso. El valor por defecto es `Delete`, así que si quieres evitar que el recurso se elimine al borrar el *stack*, lo mejor es establecer esta propiedad a `Retain`.

Si revisas los estados asociados a los recursos en el *stack* observarás que para aquellos recursos con `DeletionPolicy: Retain` se indica `DELETE_SKIPPED`.

Esta opción evita que el recurso se elimine al borrar el *stack*, pero no evita que se elimine si se borra el recurso de la plantilla y ejecutas un *update* del *stack*; es decir, no "marca" el recurso como *no borrable*, sino que es una propiedad que indica a CloudFormation qué hacer con el recurso si se elimina el *stack*; si eliminas el recurso del fichero de CLoudFormation y lanzas un *update* del *stack*, el recurso ya no tiene la propiedad `DeletionPolicy` establecida en `Retain` y se aplica el valor por defecto, que es `Delete`.

Tampoco evita la eliminación de un recurso para aquellas actualizaciones que requieren un *reemplazo* del recurso durante una actualización del *stack*. Para este escenario debes usar la propiedad [UpdateReplacePolicy Attribute](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-updatereplacepolicy.html).

La diferencia entre `DeletionPolicy` y `UpdateReplacePolicy` es que la primera aplica cuando se intenta borrar el recurso cuando se elimina el *stack* mientras que la segunda aplica durante actualizaciones del recurso que implican un *replacement*. Si un recurso tiene especificada el atributo `UpdateReplacePolicy` en `Retain`, el recurso original que es reemplazado durante la actualización, se mantiene en vez de borrarse (acabamos con dos copias). El recurso "original" queda "fuera" del *scope* del *stack*.

Algunos recursos soportan una tercera opción (además de `Delete` o `Retain`): `Snapshot`. Los recursos que lo soportan son:

- AWS::EC2::Volume
- AWS::ElastiCache::CacheCluster
- AWS::ElastiCache::ReplicationGroup
- AWS::Neptune::DBCluster
- AWS::RDS::DBCluster
- AWS::RDS::DBInstance
- AWS::Redshift::Cluster

## Políticas de *stack*

Estableciendo el atributo `DeletionPolicy: Retain` se evita la eliminación de los recursos cuando se borra el *stack*, pero establecer el atributo para cada recurso es algo tedioso.

Mediante las *stack policies* tenemos un mecanismo que permite proteger **todo** el *stack* o sólo algunos recursos específicos: [Prevent Updates to Stack Resources](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/protect-stack-resources.html).

Una *stack policy* es un documento JSON que indica qué acciones se pueden realizar sobre qué recursos del *stack*.

Al establecer una *stack policy* se evitan las actualizaciones de **todos los recursos del *stack* por defecto**. Para permitir actualizaciones sobre recursos concretos, debes permitirlo explícitamente en la política.

Aunque sólo se puede establecer una *stack policy* por *stack*, ésta permite controlar las modificaciones sobre tantos recursos del *stack* como queramos.

Debes tener en cuenta que el *stack policy* sólo "protege" los recursos de acciones realizadas a través de **actualizaciones realizadas a través de CloudFormation**, pero no impide la modificación de los recursos directamente. Si quieres evitar que se modifique o elimine un recurso, debes restringir el acceso mediante políticas IAM. La *stack policy* es un mecanismo de protección contra modificaciones inadvertidas sobre recursos de un *stack*.

Un ejemplo de *stack policy* sería:

```json
{
  "Statement" : [
    {
      "Effect" : "Allow",
      "Action" : "Update:*",
      "Principal": "*",
      "Resource" : "*"
    },
    {
      "Effect" : "Deny",
      "Action" : "Update:*",
      "Principal": "*",
      "Resource" : "LogicalResourceId/ProductionDatabase"
    }
  ]
}
```

Esta política permite cualquier tipo de actualización sobre todos los recursos del *stack* **excepto** el llamado `ProductionDatabase`.

### Particularidades de la *stack policy*

Una *stack policy* es una especie de *resource-based policy* aplicada al *stack*; por ello debes especificar el `Principal`, aunque sólo admite el valor `*`.

Por defecto, la presencia de una *stack policy* asociada al *stack* **deniega** implícitamente la actualización de todos los recursos del *stack*. Sin embargo, AWS recomienda usar `Deny` **explícitos** si realmente queremos evitar la modificación de alguno de los recursos contenidos en el *stack*.

Los valores de `Action` también son particulares, ya que en vez de ser de la forma habitual `servicio:permiso` son `Update:*`. Esta acción permite cualquier tipo de actualización sobre el recurso mientras que `Update:Modify`, `Update:Replace` o `Update:Delete` sólo permiten las acciones especificadas. Las *stack policy* también aceptan entradas de tipo `NotAction`, pero como en el caso de las IAM policies, es mejor evitarlas si es posible.

En cuanto a los recursos, la *stack policy* permite usar condiciones del tipo `StringEquals` o `StringLike` para **clases de recursos**. Esto permite denegar el borrado de todos los recursos del tipo `AWS::EC2::Instance` e incluso, todos los recursos de tipo EC2 mediante `AWS::EC2::*`: instancias, *security groups*, *subnets*, etc.

```json
"Condition" : {
  "StringLike" : {
    "ResourceType" : ["AWS::EC2::*"]
  }
}
```

### Aplicar una *stack policy*

Sólo puedes aplicar una *stack policy* a un *stack* vía consola **durante su creación**.

Para aplicar una *stack policy* a un *stack* existente debes usar la CLI: `aws cloudformation set-stack-policy`. También puedes usar la CLI para aplicar la *stack policy* al crear el *stack* (`aws cloudformation create-stack` y especificando la *stack policy* como un parámetro).

### Actualizar recursos protegidos con una *stack policy*

Las *stack policy* están pensadas para evitar modificaciones por error de un *stack*, pero ¿cómo actualizas los recursos de un *stack* si la *stack policy* lo impide?

AWS permite especificar una *stack policy* **temporal** que permita la modificación de un recurso protegido. Desde la consola web de AWS, en la página de configuración de opciones del *stack*, en la sección `Advanced options`, selecciona `Stack policy` y sube la *stack policy* que permita la modificación del recurso.

Esta *stack policy* temporal sólo tiene validez durante la actualización del *stack*; cuando finaliza, la *stack policy* "temporal" deja de ser válida y por tanto los recursos vuelven a estar protegidos contra modificaciones.

En la documentación de AWS [More Example Stack Policies](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/protect-stack-resources.html#stack-policy-samples) tienes algunos ejemplos de *stack policies*, como ésta que evita la actualización de cualquier *stack* anidado:

```json
{
  "Statement" : [
    {
      "Effect" : "Deny",
      "Action" : "Update:*",
      "Principal": "*",
      "Resource" : "*",
      "Condition" : {
        "StringEquals" : {
          "ResourceType" : ["AWS::CloudFormation::Stack"]
        }
      }
    },
    {
      "Effect" : "Allow",
      "Action" : "Update:*",
      "Principal": "*",
      "Resource" : "*"
    }
  ]
}
```

## Bonus: Usando `DeletionPolicy` para importar recursos en *stacks*

CloudFormation permite crear y actualizar *stacks* partiendo de recursos ya existentes. Para incorporar un recurso al *stack* debemos describirlo en la plantilla de CloudFormation y **especificar** `DeletionPolicy: Retain`.

Una manera sencilla y efectiva de incluir todas las propiedades del recurso existente en CloudFormation es usando "get" o "describe" desde la CLI; por ejemplo, para un usuario IAM:

```yaml
User:
  Arn: arn:aws:iam::123456789012:user/iam-username-no-path
  CreateDate: '2020-05-28T16:40:57+00:00'
  Path: /
  Tags:
  - Key: deletable
    Value: 'true'
  - Key: owner
    Value: xavi
  UserId: AIDARZDR66FL6NEXAMPLE
  UserName: iam-username-no-path
```

De esta forma puedes obtener muchas de las propiedades del recurso "real" en un formato que puedes -casi- copiar y pegar en tus plantillas, añadir el atributo `DeletionPolicy: Retain` y crear/actualizar el *stack*.
