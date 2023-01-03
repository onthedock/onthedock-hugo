+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["ops"]
# TAGS (HW->OS->PRODUCT->specific tag)

tags = ["cloud", "aws", "session manager", "ssm"]

thumbnail = "images/aws.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/

# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}
# YouTube           {{< youtube w7Ft2ymGmfc >}}
# Gist              {{< gist username 7896402 >}}
# Highlight         {{< highligth language >}}...{{< /highlight >}}
# Twitter           {{< tweet user="SanDiegoZoo" id="1453110110599868418" >}}

title=  "Conectar a Instancia EC2 usando SSM Session Manager"
date = "2022-12-16T20:12:02+01:00"
+++
He intentado añadir un comentario al artículo [How to Connect to EC2 with SSM (Session Manager)?](https://faun.pub/how-to-connect-to-ec2-with-ssm-session-manager-ef0500835949) pero no ha habido manera...

El autor indica que es necesario configurar la instancia para aceptar tráfico de entrada HTTPS 443 desde **cualquier origen**...

<!--more-->

{{< figure src="/images/221216/20221216_1.png" width="100%" height="351" >}}

Sin embargo, una de las ventajas de AWS SSM Session Manager es que no requiere abrir **ningún puerto** para permitir tráfico entrante; sólo requiere tráfico **de salida** HTTPS a los *endpoints* de los siguientes servicios, como indica la documentación oficial: [Step 1: Complete Session Manager prerequisites](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-prerequisites.html)

{{< figure src="/images/221216/20221216_0.png" width="100%" height="201" >}}

## No se vayan todavía, que aún hay más

No sólo no es necesario permitir tráfico de entrada; AWS Session Manager también puede configurarse de forma que el tráfico entre el agente instalado en las instancias y el *backend* de SSM no salga hacia internet.

Para ello, pueden configurarse los *enlaces privados* (traducción libre de *AWS PrivateLink*) de manera que el tráfico sea *interno* hacia los servicios de AWS relacionados con el servicio de AWS Session Manager. Usando AWS PrivateLink los *endpoints* de AWS Session Manager reciben una IP privada de los rangos configurados en la VPC, por lo que el todo el tráfico entre el agente y AWS Session Manager es "interno" a la VPC.

Como se indica en la documentación oficial, de esta forma los nodos no sólo no requieren ningún tipo de acceso entrante desde el exterior, sino que además tampoco requieren acceso *de salida* hacia internet:

{{< figure src="/images/221216/20221216_2.png" width="100%" height="200" >}}

La documentación oficial indica cómo configurar los *PrivateLinks* para obtener este grado adicional de seguridad: [Step 6: (Optional) Use AWS PrivateLink to set up a VPC endpoint for Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-getting-started-privatelink.html).

## Conclusión

Siempre, siempre: [RTFM](https://en.wikipedia.org/wiki/RTFM); la documentación de los proveedores cloud en mi humilde opinión es **excelente**, al menos siempre que no tengas unos requerimientos demasiado especiales... Y para esos casos "raritos", generalmente puedes contactar con el fantástico soporte que ofrecen.

{{< figure src="/images/221216/RTFM.png" width="100%" height="473" >}}

Pero sobretodo, aplica siempre tu sentido común y no te creas todo lo que se publica en internet:

{{< figure src="/images/221216/truth_and_internet.jpeg" width="100%" height="429" >}}

P.S. Esta entrada debería haberse publicado el 16/12/2022 pero se quedó en el disco duro por error.
