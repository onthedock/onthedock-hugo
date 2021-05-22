+++
draft = false
categories = ["dev"]
tags = ["aws", "iam"]
thumbnail = "images/aws.png"

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}

title=  "Cambio de rol en AWS"
date = "2019-11-23T06:49:30+01:00"
+++
IAM es el servicio de gestión de identidades y accesos de AWS.

Como **todo** lo que coloques en el cloud está, por definición, expuesto a internet, la gestión de los permisos es uno de los puntos críticos que debes tener en cuenta.

A la hora de asignar permisos, siempre hay que aplicar el principio de **least privilege**, es decir, sólo proporcionar los **mínimos** permisos necesarios para realizar la tarea a realizar.

Sin embargo, esto es más sencillo de decir que de hacer, así que muchas veces se trata de un proceso iterativo: asignas permisos a un rol, intentas realizar alguna acción, la acción falla porque falta algún permiso... Como sólo puedes tener asignado un rol en cada momento, tienes que buscar una forma en la que cambiar entre el rol con permisos y el rol que estás creando de manera sencilla y ágil.

En esta entrada, creamos un rol *de laboratorio* asumible desde la misma cuenta en el que ir asignando políticas para realizar el *refinado* de las políticas de la manera más cómoda posible.

También puedes crear roles específicos para tareas de administración, etc y así usar un rol con permisos acotados en cada momento, cambiando al rol adecuado para realizar cada tarea.
<!--more-->

En este escenario tenemos dos roles, uno con permisos con el que puedes editar otros roles y políticas y el nuevo rol cuyos permisos estamos refinando. Al rol *con permisos* le llamaré *administrador*, aunque no tiene porqué tener permisos de administrador. Al rol que estamos creando, le llamo *rol de laboratorio*.

La clave para poder cambiar entre uno y otro es usar [`AssumeRole`](https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.html).

> No puedes usar `AssumeRole` desde el usuario `root` de la cuenta... Pero es que, en general, **no debes** usar el usuario `root` de la cuenta.

Mediante `AssumeRole` se obtienen unas credenciales temporales que proporcionan acceso a recursos a los que normalmente no se tiene acceso. Esto permite, por ejemplo, que servicios como EC2 o Lambda puedan ganar acceso a nuestras cuentas para poder ejecutar acciones.

Sin embargo, en este caso, lo que vamos a hacer es justo lo contrario: partiendo de un usuario que tiene permisos "de administrador" vamos a asumir menos permisos para realizar pruebas.

Para que un rol (o servicio) pueda asumir el rol de laboratorio:

- el rol/servicio que *asume* el rol de laboratorio debe tener el permiso `sts:AssumeRole`.
  - Si usar un rol con `AdministratorAccess`, ya dispones del permiso para asumir un rol.
- el rol *asumible* debe tener una *relación de confianza* (*trust relationship*) con el rol/servicio que puede asumir el rol.

Vamos a crear un rol "vacío", sin ninguna política asociada a través de CloudFormation. También puedes crearlo directamente a través de la consola web de AWS.

> No especificamos el nombre del rol en la plantilla, por lo que el nombre del rol resultante será `<nombre-del-stack>`-`<nombredelrecurso ("LabRole", en nuestro caso)>`-`<cadena-random>`:

```json
{
    "AWSTemplateFormatVersion": "2010-09-09",
    "Resources": {
        "LabRole": {
            "Type": "AWS::IAM::Role",
            "Properties": {
                "AssumeRolePolicyDocument": {
                    "Version": "2012-10-17",
                    "Statement": [
                        {
                            "Effect": "Allow",
                            "Principal": {
                                "AWS": [
                                    "arn:aws:iam::123456789012:root"
                                ]
                            },
                            "Action": [
                                "sts:AssumeRole"
                            ]
                        }
                    ]
                },
                "Path": "/"
            }
        }
    }
}
```

> Si usas esta plantilla de CloudFormation debes modificar el número de cuenta del ejemplo por uno válido.

El número de cuenta especificado indica desde dónde se puede asumir este rol. Si indicas `root`, cualquier rol con los permisos necesarios en esa cuenta especificada puede asumir este rol. Si quieres restringir quién puede asumir los permisos, puedes indicar el ARN de un usuario o rol como `Principal` en la relación de confianza.

Si revisas el rol recién creado, observarás que se proporciona un enlace poder acceder a la consola *asumiendo* el rol:

{{< figure src="/images/191123/link-to-switch-role.png" w="931" h="239" >}}

A nosotros nos interesa poder cambiar entre el rol *admin* y el *rol de laboratorio* sin tener que estar entrando y saliendo de la cuenta.

## Cambio de rol

Si pulsas sobre el desplegable que indica con qué usuario estás *logado* en la cuenta de AWS observarás que existe la opción de *switch role*, que es justo lo que necesitamos:

{{< figure src="/images/191123/switch-role-menu.png" w="523" h="419" >}}

Al pulsar sobre esta opción se presenta una pantalla con isntrucciones sobre el proceso de cambio de rol:

{{< figure src="/images/191123/switch-role-screen.png" w="1110" h="625" >}}

Pulsa sobre el botón *Switch role* y proporciona la información que se solicita:

- Número de cuenta de AWS donde reside el rol al que quieres cambiar (obligatorio)
- Nombre del rol al que quieres cambiar (obligatorio)
- Nombre para mostrar cuando asumas el rol
- Color con el que quieres que se resalte el rol asumido

{{< figure src="/images/191123/switch-role-form.png" w="1092" h="423" >}}

Una vez proporcionada la información, podemos cambiar al rol de laboratorio a través del desplegable del menú de *login*:

{{< figure src="/images/191123/switch-role-info-on-dropdown.png" w="629" h="438" >}}

Como ves, el rol **activo** se indica en la parte superior con el nombre y color elegido; además, en el desplegable, ahora se muestra con qué usuario (recuadro amiarillo) y en qué cuenta (en azul claro) se ha realizado el login, así como el rol y cuenta **activo** en este momento.

En este caso, tanto la cuenta del rol asumido al hacer login como el rol asumido a través del *switch role* están en la misma cuenta, pero podemos cambiar entre roles de diferentes cuentas del mismo modo.

Para facilitar el cambio de roles, se muestra una lista con los roles a los que se ha cambiado más recientemente, así como un enlace de retorno al rol inicial: *"Back to `<original-rol>`"*.

## Cambio de rol en AWS CLI

Para cambiar de rol en AWS CLI, debes crear/configurar un `profile` donde indicar el `ARN` del rol al que quieres cambiar. Tienes más información en la documentación oficial de AWS en [Using an IAM Role in the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-role.html) y en en [AWS CLI Configuration Variables](https://docs.aws.amazon.com/cli/latest/topic/config-vars.html).

Básicamente, lanzas `aws configure --profile rolelab --role_arn` indicando el ARN del rol de destino. A continuación debes repetir el proceso para especificar el `source_profile` (en caso de que no sea el `default`).

En el fichero de perfiles (`~/.aws/configuration`) puedes comprobar que tienes:

```ini
[rolelab]
role_arn = arn:aws:iam::123456789012:role/iam-role-lab-LabRole-LKOF93LP1BEN
source_profile = <usuarioIAMOriginal>
```

## Resumen

En esta entrada he hablado del uso de cambio de roles para realizar *refinamiento* de políticas IAM, asignando únicamente los permisos necesarios para realizar una tarea. Puedes usar este mismo método para crear roles específicos para diferentes tareas y así minimizar en todo momento los permisos a los que tienes acceso.
