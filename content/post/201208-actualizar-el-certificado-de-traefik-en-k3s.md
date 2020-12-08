+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["kubernetes", "k3os", "k3s", "traefik", "tls", "devtoolbox"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/traefik.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" %}}

title=  "Actualizar el certificado de Traefik en K3s"
date = "2020-12-08T09:09:23+01:00"
+++
K3OS (y K3s) despliega Traefik como Ingress. Pero el problema es que el certificado autofirmado configurado por defecto caducó en 2017.

Probablemente se trata de una *feature* y no de un *bug*, para "animar" a cambiar el certificado desplegado por defecto por uno válido; en este artículo explico cómo hacerlo.
<!--more-->
> En las pruebas, estoy usando K3os con K3s versión v1.18.9+k3s1 (630bebf9).

El certificado usado por Traefik se encuentra en el secreto `traefik-default-cert` del *namespace* `kube-system`. Puedes exportarlo mediante:

```bash
kubectl get secret traefik-default-cert -n kube-system -o jsonpath='{.data.tls\.crt}' | base64 --decode - > traefik-certificate.txt
```

El contenido del fichero `traefik-certificate.txt` será algo como:

```text
-----BEGIN CERTIFICATE-----
MIIEmzCCA4OgAwIBAgIJAJAGQlMmC0kyMA0GCSqGSIb3DQEBBQUAMIGPMQswCQYD
VQQGEwJVUzERMA8GA1UECBMIQ29sb3JhZG8xEDAOBgNVBAcTB0JvdWxkZXIxFDAS
BgNVBAoTC0V4YW1wbGVDb3JwMQswCQYDVQQLEwJJVDEWMBQGA1UEAxQNKi5leGFt
cGxlLmNvbTEgMB4GCSqGSIb3DQEJARYRYWRtaW5AZXhhbXBsZS5jb20wHhcNMTYx
MDI0MjEwOTUyWhcNMTcxMDI0MjEwOTUyWjCBjzELMAkGA1UEBhMCVVMxETAPBgNV
BAgTCENvbG9yYWRvMRAwDgYDVQQHEwdCb3VsZGVyMRQwEgYDVQQKEwtFeGFtcGxl
Q29ycDELMAkGA1UECxMCSVQxFjAUBgNVBAMUDSouZXhhbXBsZS5jb20xIDAeBgkq
hkiG9w0BCQEWEWFkbWluQGV4YW1wbGUuY29tMIIBIjANBgkqhkiG9w0BAQEFAAOC
AQ8AMIIBCgKCAQEAtuJ9mww9Bap6H4NuHXLPzwSUdZi4bra1d7VbEBZYfCI+Y64C
2uu8pu3aU5sauMbD97jQaoyW6G98OPreWo8oyfndIctErlnxjqzU2UTV7qDTy4nA
5OZeoReLfeqRxllJ14Via5QdgywGLhE9jg/c7e4YJznh9KWY2qcVxDuGD3iehsDn
aNzV4WF9cIfms8zwPvONNLfsAmw7uHT+3bK13IIhx27fevquVpCs41P6psu+VLn2
5HDy41thBCwOL+N+albtfKSqs7LAs3nQN1ltzHLvy0a5DhdjJTwkPrT+UxpoKB9H
4ZYk1+EDt7OPlhyo3741QhN/JCY+dJnALBsUjQIDAQABo4H3MIH0MB0GA1UdDgQW
BBRpeW5tXLtxwMroAs9wdMm53UUILDCBxAYDVR0jBIG8MIG5gBRpeW5tXLtxwMro
As9wdMm53UUILKGBlaSBkjCBjzELMAkGA1UEBhMCVVMxETAPBgNVBAgTCENvbG9y
YWRvMRAwDgYDVQQHEwdCb3VsZGVyMRQwEgYDVQQKEwtFeGFtcGxlQ29ycDELMAkG
A1UECxMCSVQxFjAUBgNVBAMUDSouZXhhbXBsZS5jb20xIDAeBgkqhkiG9w0BCQEW
EWFkbWluQGV4YW1wbGUuY29tggkAkAZCUyYLSTIwDAYDVR0TBAUwAwEB/zANBgkq
hkiG9w0BAQUFAAOCAQEAcGXMfk8NZsB+t9KBzl1Fl6yIjEkjHO0PVUlEcSD2B4b7
PxnMOjdmgPrauHb9unXEaL7zyAqaD6tbXWU6RxCAmgLajVJNZHOw45N0hrDkWgB8
EvZtQ56ammwC1qIhAiA6390D3Csex7gL6nJo7kbr1YWUG3zIvoxdz8YDrZNeWKLD
pRvWen0lMbpjIRP4XZsnC45C9gVXdh3LRe1+wyQq6h9QPiloxmD6NpE9imTOn2A5
/bJ3VKIzAMudeU6kpyYlJBzdG1uaHTjQOWosGiweCKVUXF6UtisVddrxQth6ENyW
vIFqaZx84+DlSCc93yfk/GlBt+SKG46zEHMB9hqPbA==
-----END CERTIFICATE-----
```

Revisa los datos del certificado usando *openssl*:

```bash
$ openssl x509 -in traefik-certificate.txt -text -noout
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            90:06:42:53:26:0b:49:32
        Signature Algorithm: sha1WithRSAEncryption
        Issuer: C = US, ST = Colorado, L = Boulder, O = ExampleCorp, OU = IT, CN = *.example.com, emailAddress = admin@example.com
        Validity
            Not Before: Oct 24 21:09:52 2016 GMT
            Not After : Oct 24 21:09:52 2017 GMT
        Subject: C = US, ST = Colorado, L = Boulder, O = ExampleCorp, OU = IT, CN = *.example.com, emailAddress = admin@example.com
        Subject Public Key Info:
...
```

Así se observa claramente, en la sección *Validity*, que el certificado expiró el 24 de Octubre del 2017. El certificado es de tipo *wildcard* para cualquier subdominio de `example.com`.

## Configuración de TLS en Traefik

> Usamos como referencia el artículo [Create development certificates the easy way!](https://github.com/BenMorel/dev-certificates)

Puedes usar una entidad certificadora comercial, gratuita ([Let's Encrypt](https://letsencrypt.org/)) o una CA privada.

En mi caso, para un entorno de Laboratorio privado, voy a usar una entidad certificadora propia.

### Crear la entidad certificadora (*Certificate Authority*)

Generamos la clave privada para la CA:

```bash
# Generate private key
openssl genrsa -out ca.key 2048
```

Usando la clave privada recién creada, generamos el certificado raíz de la CA; en esta caso, le damos una validez de 10 años:

```bash
# Generate root certificate
openssl req -x509 -new -nodes -subj "/C=ES/O=Internal Development CA/CN=Development certificates" -key ca.key -sha256 -days 3650 -out ca.crt
```

### Configurar los navegadores

Los navegadores traen *de fábrica* los certificados raíz de las entidades certificadores comerciales o de confianza. De esta forma pueden validar los certificados de sitios web firmados por estas CAs.

En nuestro caso deberemos añadir manualmente el certificado de la CA (`ca.crt`) al navegador.

Este proceso es específico para cada Navegador.

#### Importar certificado en Firefox

> Validado en Firefox v83.0

1. *Menu > Preferences*
1. En el panel lateral, *Privacy & Security*
1. En la seccion *Security > Certificates*, pulsa el botón *View Certificates*...
1. En la ventana *Certificate Manager*, selecciona la pestaña *Authorities*
1. Pulsa el botón *Import...* en la parte inferior de la ventana
1. Selecciona el certificado de la entidad certificadora `ca.crt`

### Generar un certificado *wildcard*

Ben Morel proporciona un [script](https://raw.githubusercontent.com/BenMorel/dev-certificates/main/create-certificate.sh) para generar el certificado de forma automática.

Para generar el certificado *wildcard* autofirmado para tu dominio `dev.lab`, usa `DOMAIN=dev.lab`.

Genera la clave privada:

```bash
# Generate a private key
openssl genrsa -out "$DOMAIN.key" 2048
```

Genera la petición de firma del certificado (*certificate signing request, CSR*)

```bash
# Create a certificate signing request
openssl req -new -subj "/C=ES/O=Local Development/CN=$DOMAIN" -key "$DOMAIN.key" -out "$DOMAIN.csr"
```

El *script* también genera un fichero de extensiones:

```bash
# Create a config file for the extensions
>"$DOMAIN.ext" cat <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = $DOMAIN
DNS.2 = *.$DOMAIN
EOF
```

Finalmente, creamos el certificado firmado por la CA (este paso lo realizará el proveedor de la CA en el caso de una CA pública):

> El *script* asume que todos los fichero se encuentran en la misma carpeta.

```bash
# Create the signed certificate
openssl x509 -req \
    -in "$DOMAIN.csr" \
    -extfile "$DOMAIN.ext" \
    -CA ca.crt \
    -CAkey ca.key \
    -CAcreateserial \
    -out "$DOMAIN.crt" \
    -days 3650 \
    -sha256
```

## Configurar la aplicación con los certificados generados

Este proceso es específico para cada aplicación; en el caso de Trafik en Kubernetes,los certificados `dev.lab.crt` y `dev.lab.key` pueden proporcionarse a través de un *secret* en el *namespace*  `kube-system`.

Recuerda que los *secrets* en Kubernetes deben codificarse en **base64**. Puedes codificar en base64 un fichero mediante `base64 ${nombre-fichero}`, p.ej `base64 somefile.txt > base64-somefile.txt`. Para descodificar el fichero, `base64 -d ${nombre-fichero}`.

> No es buena idea usar `echo ${string} | base64` para secretos; `echo` añade un retorno de línea al final de la cadena (man page para [`echo`](http://linuxcommand.org/lc3_man_pages/echoh.html)).

### Agregar los certificados al *secret*

Para configurar los certificados generados en Traefik, primero exporta el secret desde Kubernetes:

```bash
kubectl get secret -n kube-system traefik-default-cert -o yaml > secret-traefik-default-cert.yaml
cp secret-traefik-default-cert.yaml secret-traefik-custom-cert.yaml
```

Modifica los valores de los campos `tls.cert` y `tls.key` con el certificado **en base64** generado en el paso anterior.

> El valor en base64 debes copiarlo en una sola línea:

```yaml
apiVersion: v1
data:
    tls.cert: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS...
    tls.key: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRV...
...
```

Una vez modificado el *secret*, actualízalo en Kubernetes mediante:

```bash
kubectl -n kube-system apply -f secret-traefik-custom-cert.yaml
```

Una vez actualizado, haz un rollout de Traefik (requiere Kubernetes 1.15+):

```bash
$ kubectl -n kube-system rollout restart deployment traefik
deployment.apps/traefik restarted
```

Así podemos publicar vía HTTPS una aplicación por subdominio (`git.dev.lab`, `cd.dev.lab`, etc...) usando un único certificado *wildcard*.
