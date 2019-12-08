+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["aws", "sdk", "parameterstore"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/aws.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" %}}

title=  "Cómo leer parámetros de Systems Manager Parameter Store usando Boto3"
date = "2019-12-06T08:36:22+01:00"
+++
AWS ofrece, como parte del servicio Systems Manager (y [¡**gratis**!](https://aws.amazon.com/systems-manager/pricing/#Parameter_Store)) [Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html). Como su nombre indica, es un almacén de parámetros que podemos usar para evitar *hardcodear* valores de configuración de aplicaciones o scripts.

La documentación de Boto3, el SDK de AWS para Python es muy buena, pero es tedioso tener que ir consultándola a cada momento.

> Esta entrada es una especie de recordatorio personal sencillo sobre cómo acceder a Parameter Store para leer el valor de un parámetro.
<!--more-->
Parameter Store ofrece tres tipos de parámetros: *String*, *StringList* y *SecureString*.

En los tres casos el proceso es el mismo:

1. instancias un *client* para `ssm`
1. consultas el parámetro con el método [`get_parameter()`](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/ssm.html#SSM.Client.get_parameter)
1. obtienes el valor

## Parámetros de tipo *String*

Los valores de tipo *String* son cadenas que se suelen usar y que no contienen información sensible (aunque el límite de *sensible* en cada caso probablemente lo determine el equipo de seguridad).

La respuesta de `get_parameter()` es de la forma:

```json
    'Parameter': {
        'Name': 'string',
        'Type': 'String'|'StringList'|'SecureString',
        'Value': 'string',
        'Version': 123,
        'Selector': 'string',
        'SourceResult': 'string',
        'LastModifiedDate': datetime(2015, 1, 1),
        'ARN': 'string'
    }
}
```

En general, sólo nos interesa obtener el valor del parámetro, por lo que nos concentramos en obtener el valor contenido en `Value`.

> Como el valor del parámetro puede cambiar, `get_parameter()` devuelve **siempre** la última versión del parámetro. En la respuesta puedes consultar la *versión* del valor del parametro, pero no puedes obtener un valor anterior. Si estás interesado en obtener la lista de todos los valores que ha tenido un parámetro -y quién los ha modificado-, usa el método `get_parameter_history()`.

En el ejemplo, tenemos un parámetro llamado `parameter1` en Parameter Store que vamos a consultar para obtener su valor.

```python
import boto3
ssm_client = boto3.client('ssm')
miparametro = ssm_client.get_parameter(Name='parameter1')
valor_de_miparametro = miparametro['Parameter']['Value']
print(valor_de_miparametro)
```

Si ejecutamos este fragmento de código, el resultado es:

```bash
$ python parameter_store_string.py
test-parameter-value
```

> Debes tener permisos para poder leer el parámetro en Parameter Store

## Parámetros de tipo *SecureString*

En este caso, el valor del parámetro se encuentra encriptado. Puedes usar el servicio KMS (*Key management service*) para gestionar las claves usadas para encriptar los parámetros.

> [KMS no es gratis](https://aws.amazon.com/kms/pricing/), pero tiene un *free tier* que permite 20000 peticiones/mes sin coste.

Aunque los pasos para leer el parámetro son los mismos que en el caso anterior, debes tener en cuenta que el valor del parámetro está encriptado.

Si ejecutas el mismo código sobre un parámetro *SecureString*:

```bash
$ python parameter_store_securestring.py
AQICAHhIerV5N6Z6vXFmNd+nLmcALZwYyWLGXw7bxLkAshH6HQH8z8MfIx3LfILqfqlc5FDSAAAAaDBmBgkqhkiG9w0BBwagWTBXAgEAMFIGCSqGSIb3DQEHATAeBglghkgBZQMEAS4wEQQMWnlSalVYxWZ0hRClAgEQgCUdjEnBYX2THX6kWC+8hrWxPkUM4vAx+ErKMt/47gyDHwHkjFuL
```

Probablemente te interesa obtener el valor *desencriptado*; para ello debes añadir el parámetro `WithDecryption=True` en la llamada de `get_parameter()`:

```python
import boto3
ssm_client = boto3.client('ssm')
securestringpassword = ssm_client.get_parameter(
    Name='supersecret', WithDecryption=True)
secretvalue = securestringpassword['Parameter']['Value']
```

Tras modificar el código, el resultado es el esperado:

```bash
$ python parameter_store_securestring.py
D3m0$3cr3t
```
