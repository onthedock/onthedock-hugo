+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["cloud", "aws", "session manager"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/aws.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" %}}

title=  "Session Manager como herramienta de control de acceso a instancias EC2 en AWS"
date = "2019-05-27T19:33:13+02:00"
+++
Uno de los problemas habituales en un entorno cloud es cómo gestionar el acceso a las instancias del cloud de forma controlada y segura. Session Manager es un servicio de AWS que resuelve este problema y que además es gratuito.
<!--more-->

[Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html) forma parte de [AWS System Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/what-is-systems-manager.html). Systems Manager anteriormente se llamaba _Simple Systems Manager_, por lo que verás múltiples referencias a las siglas SSM (por ejemplo, en el nombre del usuario que el sistema crea en las máquinas Linux gestionadas).

Aunque Systems Manager incluye múltiples funcionalidades, voy a centrarme únicamente en la función de gestión de sesiones, _Session Manager_.

Session Manager permite conectar a las instancias en AWS sin necesidad de abrir los puertos para SSH o RDP, lo que puede considerarse una mejora de la seguridad de las máquinas. El acceso, además, se realiza a través del propio navegador, lo que simplifica enormemente la conexión remota desde prácticamente cualquier dispositivo.

{{% img src="images/190527/no-open-ports.png" w="883" h="346" class="center" caption="El grupo de seguridad no permite tráfico entrante." %}}

{{% img src="images/190527/security-group.png" w="882" h="431" class="center" caption="Detalle de las reglas del security group." %}}

La conexión está cifrada usando TLS 1.2, por lo que además de proporcionar una vía conveniente para acceder a las instancias EC2, también es segura.

A diferencia del acceso SSH (o vía RDP en sistemas Windows), el uso de Session Manager (en realidad, de AWS Systems Manager) requiere la instalación de un agente en las máquinas gestionadas. Este agente viene instalado _de fábrica_ en las AMIs que proporciona Amazon.

Si usas una imagen _custom_, puedes instalar el agente siguiendo las instrucciones proporcionadas en [Step 2: Practice Installing or Updating SSM Agent on an Instance](https://docs.aws.amazon.com/systems-manager/latest/userguide/getting-started-agent.html).

En mi caso, la imagen que he usado para crear la instancia para esta entrada ya tiene el agente instalado.

El agente crea un usuario local con permisos de administrador/root llamado `ssm-user`. Este es el usuario "local" que se usa para ejecutar los comandos a través de la sessión gestionada por Session Manager.

## Permisos asociados a Systems Manager

Para que Systems Manager pueda acceder a las instancias en las que se encuentra el agente, debemos asociar un rol a las instancias; asignaremos permisos a este rol mediante una política que especifique los permisos asociados.

Amazon facilita la política `AmazonEC2RoleforSSM` que proporciona una amplio rango de permisos para que Systems Manager pueda ejecutar todas las tareas que debe realizar. Si quieres restringir los permisos asignados, debes crear una política personalizada que proporcione únicamente aquello que necesites (por ejemplo [Create a Custom IAM Instance Profile for Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/getting-started-create-iam-instance-profile.html)).

He utilizado el imaginativo nombre `EC2SSM-SessionManager`, al que he asociado la política gestionada por Amazon `AmazonEC2RoleforSSM` y lo he asociado a una instancia.

En mi caso, la instancia estaba apagada cuando he aplicado el rol; el usuario remoto y la "activación" del agente se ha realizado durante el arranque.

Para poder iniciar una sesión de Session Manager, es necesario que el usuario tenga los permisos necesarios. Aunque puedes restringir los accesos en función de tus necesidades, lo más sencillo es usar la política gestionada por Amazon `AmazonEC2RoleforSSM`.

En la consola de AWS, he buscado el servicio de Systems Manager y en el panel lateral, he pulsado sobre _Managed Instances_. Tal y como era de esperar, la instancia aparece listada.

{{% img src="images/190527/managed-instances.png" w="1080" h="192" class="center" %}}

Para iniciar una sesión, selecciona la instancia y en el menú _Actions_, selecciona _Start session_.

A continuación se abre una nueva pestaña del navegador con una sesión iniciada en la instancia EC2.

{{% img src="images/190527/session.png" w="557" h="278" class="center" %}}

## Consideraciones a tener en cuenta

### Usuario `ssm-user`

El usuario `ssm-user` creado en la instancia remota forma parte del grupo de administradores. Puedes comprobarlo revisando el fichero `/etc/sudoers.d/ssm-agent-users`:

```bash
$ sudo cat /etc/sudoers.d/ssm-agent-users
# User rules for ssm-user
ssm-user ALL=(ALL) NOPASSWD:ALL
```

Como puedes ver, el usuario tiene la capacidad de elevar privilegios sin restricción de comandos (y sin facilitar un password), lo que lo convierte en un usuario equivalente a `root`.

Puedes modificar este comportamiento siguiendo las instrucciones de la documentación [Step 6: (Optional) Disable or Enable ssm-user Account Administrative Permissions](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-getting-started-ssm-user-permissions.html).

### Registro de actividad

Puedes configurar Session Manager para guardar un registro de todos los comandos que se ejecutan en la instancia remota. Esta información se puede almacenar tanto en CloudWatch logs como en un bucket S3. Esta información se guarda en texto plano por defecto, por lo que deberías considerar encriptar el bucket.

{{% img src="images/190527/preferences.png" w="1100" h="141" class="center" %}}

### Encriptación adicional

Aunque la conexión está encriptada usando TLS 1.2, puedes añadir una capa extra de seguridad usando una clave gestionada por KMS. En este caso, debes proporcionar permisos al usuario para poder acceder a esta clave concreta en KMS, además de los permisos para usar Session Manager.

### Restringiendo el acceso

Tal y como hemos configurado la política de acceso, cualquier usuario que asuma este rol puede gestionar cualquier instancia. Sin embargo, se me ocurren varios escenarios en los que esta no es la situación deseada.

La solución más flexible es incluir una _condition_ en la política de manera que restrinja sobre qué recursos aplica, por ejemplo en función de una determinada etiqueta aplicada.

En [Simplify granting access to your AWS resources by using tags on AWS IAM users and roles](https://aws.amazon.com/blogs/security/simplify-granting-access-to-your-aws-resources-by-using-tags-on-aws-iam-users-and-roles/) tienes algunas sugerencias, como restringir el acceso sólo a aquellas instancias en función de una etiqueta que indique el centro de coste o proyecto del que forme parte un usuario concreto, por ejemplo.

## Instancias Windows

Hasta ahora sólo he hablado de instancias Linux. Session Manager también soporta máquinas Windows (2008 o superior), pero estableciendo sesiones mediante PowerShell.

Esto puede ser una limitación si tu equipo de administradores está acostumbrado a la gestión usando herramientas gráficas... Aunque deberían considerarlo una oportunidad de aprender ;)

Una recomendación, en The DevOps Collective tienen [unos cuantos libros interesantes publicados en LeanPub](https://leanpub.com/u/devopscollective), como  [Secrets of PowerShell Remoting](https://leanpub.com/secretsofpowershellremoting).

## Resumen

Session Manager es una forma sencilla y cómoda de acceder a las instancias EC2 sin necesidad de usar _jumpservers_ (o bastiones), directamente a través del navegador.

El acceso se realiza de forma segura sin necesidad de herramientas externas y de forma completamente integrada con los servicios de AWS. Esto permite restringir con la granularidad que queramos los accesos y así mantener a los amigos de seguridad contentos.
