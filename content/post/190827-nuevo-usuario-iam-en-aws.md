+++
draft = false
categories = ["dev", "ops"]
tags = ["aws", "iam"]
thumbnail = "images/aws.png"

title=  "Nuevo usuario IAM en AWS"
date = "2019-08-27T19:52:01+02:00"
+++
Al final de la [entrada anterior]({{< relref "190820-instala-aws-cli" >}}) indicaba que para empezar a usar tu cuenta de AWS necesitas un usuario.

A continuación comento cómo crear un usuario IAM.
<!--more-->

Al acceder a la consola de AWS, selecciona el servicio IAM; IAM es el acrónimo de _Identity and Access Management_ (gestión de identidades y accesos), que como indica en el _subtítulo_ es el servicio que gestiona los usuarios y las claves de encriptación:

{{% img src="images/190827/iam-service.png" h="178" w="343" %}}

En el panel lateral, selecciona _Usuarios_ (Users):

{{% img src="images/190827/users.png" h="333" %}}

En la parte superior, se muestra un gran botón azul con el texto _Add User_; púlsalo para lanzar el asistente para la creación de un usuario.

{{% img src="images/190827/add_user.png" h="192" %}}

La primera decisión que debes tomar acerca del usuario es cómo se va a llamar ;)

{{% img src="images/190827/user-name.png" h="528" %}}

En la parte inferior del asistente debes indicar cómo va a "comunicarse" el usuario con AWS. La primera opción, el acceso _programático_ es el adecuado para la interacción de aplicaciones, desde línea de comandos, etc. El acceso a través de la consola -la web de AWS- es el acceso que estamos usando en estos momentos, a través de un navegador. Este es el tipo de acceso que usará una persona, moviendo el ratón y pulsando botones.

Un usuario puede tener los dos tipos de accesos. Sin embargo, las acciones -y por tanto los permisos- que asocies a cada usuario debe ser siempre los mínimos requeridos. Como los [usuarios no tienen coste](https://aws.amazon.com/iam/faqs/#Pricing), lo más recomendable es crear un usuario programático (o varios) para tus aplicaciones o scripts con permisos ajustados a su funcionalidad, mientras que el usuario con el que interacciones a través de la consola tenga unos permisos diferentes.

En función del tipo de acceso que selecciones, aparecen opciones diferentes en cuanto a la manera de validar la identidad del usuario.

En el caso de un usuario de consola, puedes hacer que AWS genere una contraseña o puedes introducirla manualmente. Por defecto, la consola web ofrece la opción de que el usuario deba cambiar el password la primera vez que acceda a AWS. De esta forma se garantiza que sólo el usuario conoce su password.

{{% img src="images/190827/password.png" h="274" %}}

Observa que si se deja marcada esta opción, AWS automáticamente asocia al usuario una _política_ llamada `IAMUserChangePassword` que le permite cambiar el password asociado.

Si estás proporcionando acceso programático, para que el usuario pueda autenticarse en la API de AWS, deberás habilitar una clave de acceso (_Access Key_) y una _Secret Key_.

A continuación, debes seleccionar qué permisos vas a asociar al usuario.  Aquí las cosas empiezan a ponerse interesantes; tienes tres opciones:

- asignar el usuario a un grupo (de forma que heredará los permisos asociados al grupo)
- copiar los permisos de otro usuario
- asignar una política

{{% img src="images/190827/attach-policy.png" h="644" w="982" %}}

Como puedes ver en la imagen anterior, existen **un montón** de políticas gestionadas por Amazon (actualmente 472). Para empezar, lo habitual es que crees un usuario con permisos de administración total (`AdministratorAccess`).
Además de las políticas gestionadas por Amazon, puedes crear tus propias políticas, ajustando con tanto detalle como quieres **qué acciones** de **qué servicios** y sobre **qué recursos** permites o deniegas.

El tema de las políticas es un mundo en sí mismo y es quizás **uno de los temas más importantes** con el que debes familiarizarte. A _muy grandes rasgos_, en una política permite definir con muchísima granularidad qué puede hacerse dónde.

La política `AdministratorAccess` permite (`"Effect": "Allow"`), todas las acciones en cualquier servicio (`"Action": "*"`) y sobre cualquier recurso (`"Resource": "*"`):

```yaml
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "*",
            "Resource": "*"
        }
    ]
}
```

... Dicho de otro modo **un gran poder implica una gran responsabilidad**.

La política define "permisos" en bloques llamados _Statements_; cada _statement_ indica el efecto que tiene la política -`Allow` o `Deny`- sobre una o varias acciones en la forma `servicio:acción` y sobre uno o más recursos de AWS.

Un ejemplo que ha salido antes; para que que un usuario pueda cambiar su contraseña, debe tener permisos sobre el servicio IAM (que gestiona los usuarios) y la acción que indica los permisos necesarios se llama `ChangePassword`. Como un usuario sólo debe poder cambiar su contraseña, debes especificar que la acción de cambiar password se restringe únicamente al usuario al que se ha asignado la política; la forma de hacerlo es mediante un ARN (_Amazon Resource Name_), que en este caso es: `arn:aws:iam::*:user/${aws:username}`.

> En este caso el ARN incluye una variable `${{aws:username}}`; lo habitual es que el ARN sea un identificador "fijo".

La política _IAMUserChangePassword_ que se asocia al usuario al marcar la casilla de "cambiar la contraseña en el primer inicio" también permite "leer" la política de passwords (que especifica la longitud de la contraseña, cada cuanto tiene que cambiarse, etc).

```yaml
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iam:ChangePassword"
            ],
            "Resource": [
                "arn:aws:iam::*:user/${aws:username}"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:GetAccountPasswordPolicy"
            ],
            "Resource": "*"
        }
    ]
}
```

> No puedes modificar las políticas gestionadas por Amazon (que se identifican por un "cubo" naranja).

Debajo de las políticas, tienes la sección para las _permission boundaries_:

{{% img src="images/190827/boundaries.png" w="988" h="193" %}}

Las _permission boundaries_ permiten establecer un **límite máximo** de permisos que el usuario puede asumir. Se considera una [funcionalidad avanzada](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_boundaries.html), por lo que quizás debas dejarlo para más adelante.

Intento explicarlo de forma **muy simplificada** en el siguiente diagrama:

{{% img src="images/190827/effective-permissions.png" w="526" h="417" %}}

Los permisos efectivos sobre el usuario son aquellos definidos por la _permission boundary_ (el círculo rojo). Como son los permisos máximos que puede tener el usuario, aunque apliquemos las políticas `Policy1` y `Policy2` que otorgan más permisos (los círculos azul y naranja) de lo que permite la _boundary_, los **permisos efectivos** serán sólo los permisos de las políticas 1 y 2 que estén dentro de los límites de la _boundary_ (la zona con rayas de color azul y naranja).

Un ejemplo sencillo: si en la _permission boundary_ establecemos `AmazonEC2FullAccess` (acceso a todas las acciones de EC2), aunque asignemos la politica `AdministratorAccess`(acceso a todas las acciones de **todos** los servicios), las políticas resultantes para este usuario se limitarán al servicio EC2 (que es lo máximo que permite la _permission boundary_), aunque la política `AdministratorAccess` permita usar otros servicios.

Para no complicar las cosas, asigna la política que consideres oportuna y deja la sección de _permission boundaries_ por defecto (sin ningún límite).

El siguiente paso es aplicar etiquetas al usuario; es un paso opcional, de manera que no etiquetamos el usuario:

{{% img src="images/190827/tags.png" w="981" h="232" %}}

Una revisión final antes de crear el usuario; observa que tienes dos políticas aplicadas: `AdministratorAccess` y `IAMUserChangePassword`

{{% img src="images/190827/review.png" w="1000" h="642" %}}

Los permisos otorgados por `IAMUserChangePassword`están incluidos en la política `AdministratorAccess`; la evaluación de las políticas se describe en [Lógica de evaluación de políticas](https://docs.aws.amazon.com/es_es/IAM/latest/UserGuide/reference_policies_evaluation-logic.html)

Tras la creación del usuario, Amazon te ofrece la posibilidad de descargar las credenciales generadas para el usuario. También tienen un botón para "mostrar" la contraseña generada (y copiarla); en cuanto cierres esta pantalla, no es posible recuperar la contraseña (aunque podrás cambiarla por una nueva).

{{% img src="images/190827/credentials.png" w="991" h="354" %}}

Este usuario tiene permiso para acceder a la consola web de Amazon; en una entrada posterior detallaré cómo crear la _Access y Secret key_ para acceder usando AWS CLI.

## Conclusiones

La creación de un usuario es sencilla, pero requiere tomar una serie de decisiones importantes respecto a los permisos asociados al usuario. IAM permite limitar de forma extremadamente granular los permisos que se asignan a los usuarios y servicios que interaccionan con los recursos de AWS.

Incluso si eres el propietario de una cuenta que sólo tú usas, deberías conocer cómo funciona IAM y cómo limitar los permisos que asignas a los usuarios programáticos que crees para las aplicaciones que desarrolles o para aquellas aplicaciones de terceros que interaccionen con los recursos en tu cuenta.

En una empresa es fundamental tener clara la estrategia que se va a seguir con respecto a la gestión de identidades y permisos en AWS. Sin embargo, es difícil adelantarse a todos los posibles casos de uso, por lo que hay que ser flexible y trabajar con una mentalidad "agile", mejorando de forma iterativa.

Los usuarios "corporativos" suelen encontrarse en un LDAP (p.ej. _Active Directory_, de Microsoft); en algunos escenarios resulta útil usar este almacén de usuarios para controlar el acceso y permisos a AWS. Utilizar usuarios _federados_ tiene ventajas y desventajas en función de cada caso de uso, por lo que es necesario evaluar qué solución es más adecuada en cada caso.

Aunque durante la creación del usuario existe la posibilidad de usar grupos, Amazon recomienda el uso de _roles_, que son "conjuntos de políticas/permisos" y que proporcionan mucha más flexibilidad que los grupos (y que son aplicables tanto a usuarios federados como a usuarios IAM).

Como has podido ver, las políticas son objetos JSON; deberías plantearte controlar el versionado de las políticas en un repositorio Git. Por tanto, cuando se trata del _cloud_, no sólo la infraestructura es código, sino que **todo** es código.

Guardar las políticas en un repositorio es sólo el primer paso para aplicar la filosofía _DevOps_ a la gestión -en este caso- de la autenticación en AWS: se realiza un cambio sobre la política, se revisa y discute en una _pull request_, se testea y una vez validada, se pasa a producción.

Es mucho más sencillo de decir que de hacer, por supuesto, pero el potencial es claro.
