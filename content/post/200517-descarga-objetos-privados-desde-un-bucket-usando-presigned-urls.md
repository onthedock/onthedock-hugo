+++
draft = false
categories = ["dev"]
tags = ["aws", "s3"]
thumbnail = "images/aws.png"
title=  "Descarga de objetos privados desde S3 usando presigned URLs"
date = "2020-05-17T19:10:08+02:00"
+++
El acceso a los objetos almacenados en *buckets* S3, como en la mayoría de recursos en AWS, está restringido a aquellos usuarios con permisos para realizar acciones sobre ellos.

Sin embargo, en algunas situaciones, puedes tener que proporcionar acceso a ficheros en un *bucket* pero no es viable asignar permisos a quien tiene que acceder (por ejemplo, son usuarios anónimos). La solución más sencilla sería proporcionar acceso público a esos ficheros, pero esta opción no siempre es posible (por ejemplo, cuando se trata de datos específicos para un usuario).

Afortunadamente, existe una solución para este aparente dilema: las URLs "pre-firmadas" (*presigned URLs*).
<!--more-->
El proceso es el siguiente:

1. El usuario que va a generar la *presigned URL* -por ejemplo, un administrador- obtiene el enlace al objeto en el *bucket* S3.
1. El *administrador* realiza una llamada a la API de AWS para validar que tiene los permisos necesarios (`s3:GetObject`) para acceder al fichero en el *bucket*. La API devuelve un token de acceso al fichero. Con el token y el nombre del *bucket* se genera el enlace firmado al objeto en el *bucket*. Este enlace es válido sólo durante el tiempo de validez del token generado (por defecto, 3600 segundos, 1h).
1. El "administrador" comunica el enlace firmado (la *presigned URL*) al usuario final. El usuario pulsa sobre el enlace y accede a la URL del bucket. Al intentar acceder al objeto en el *bucket*, S3 obtiene el token de la URL y verifica si es válido (o si ya ha expirado). Si el token es válido, se proporciona acceso al fichero, que se descarga al equipo del usuario.

{{< figure src="/images/200517/presigned-urls.svg" >}}

## Generar el enlace firmado a un objeto en S3

Para generar el enlace firmado desde línea de comandos, necesitas el nombre del bucket y la *ObjectKey* (el nombre del fichero, incluyendo la "ruta" desde la "raíz" del *bucket*). Si quieres especificar un tiempo de validez diferente a los 3600 segundos, usa el parámetro `--expires-in`.

Desde la línea de comandos, mediante AWS CLI:

> El enlace firmado de respuesta de la salida del comando lo he separado en diferentes líneas para que sea más fácil apreciar los diferentes parámetros que componen "la firma"

```bash
$ aws s3 presign --expires-in 60 s3://$BUCKETNAME/$OBJECTKEY --profile myprofile
https://${bucketname}.s3.${region}.amazonaws.com/${object-name}
    ?X-Amz-Algorithm=AWS4-HMAC-SHA256
    &X-Amz-Credential=AKIAEXAMPLEJAXLMSY%2F20200517%2F${region}%2Fs3%2Faws4_request
    &X-Amz-Date=20200517T113117Z
    &X-Amz-Expires=60
    &X-Amz-SignedHeaders=host
    &X-Amz-Signature=example123456789abcdefghiklmnopqrstuvwxyz01234567890123456789
```

Para comprobar la validez del enlace, abre un navegador en modo incógnito y pega la URL en la barra de direcciones.

Si el token es válido, el fichero se descarga a tu equipo gracias a las credenciales incluidas como parámetros en la URL.

Si el token ha expirado, la respuesta en el navegador será:

```xml
<Error>
<Code>AccessDenied</Code>
<Message>Request has expired</Message>
<X-Amz-Expires>60</X-Amz-Expires>
<Expires>2020-05-17T10:18:59Z</Expires>
<ServerTime>2020-05-17T11:45:08Z</ServerTime>
<RequestId>D44BC118ABB2F77A</RequestId>
<HostId>
example72vhGrDDIV8RW+ox6IrU2WygfP8ddy0zK2PZ3FZ3Ab5TTznjI1nUW3QfgbjrxEXAMPLE=
</HostId>
</Error>
```

**El periodo máximo de validez del enlace** que puede especificarse varía en función del tipo de credencial usadas para generarlo; consulta los tiempos en [Share an Object with Others](https://docs.aws.amazon.com/AmazonS3/latest/dev/ShareObjectPreSignedURL.html).

También es posible generar enlaces temporales para que un usuario anónimo pueda realizar otras acciones en el *bucket*, como subir un fichero por ejemplo. Para ello, deberás utilizar alguno de los SDKs de desarrollo que ofrece AWS. En [Presigned URLs](https://boto3.amazonaws.com/v1/documentation/api/latest/guide/s3-presigned-urls.html) puedes encontrar ejemplos para el caso de Python.
