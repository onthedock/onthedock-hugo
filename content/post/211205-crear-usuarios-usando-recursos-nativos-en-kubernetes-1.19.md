+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["kubernetes", "bash", "automation"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/kubernetes.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}

title=  "Crear usuarios (usando recursos nativos) en Kubernetes 1.19+"
date = "2021-12-05T19:57:28+01:00"
+++
Hace unas entradas, en [
Crear usuarios en Kubernetes (y en K3s)]({{< ref "211010-crear-usuarios-en-k3s.md" >}}), escribía sobre cómo generar nuevos usuarios con acceso al clúster de Kubernetes usando un fichero `kubeconfig`.

El método descrito implicaba extraer fuera del clúster el certificado privado de la entidad certificadora (CA) de Kubernetes, lo que no me parecía la mejor solución.

Desde Kubernetes 1.19 existe un nuevo recurso en la API, el `CertificateSigningRequest`, que permite firmar certificados para proporcionar acceso (por ejemplo) al clúster.

En esta entrada se describe cómo aprovechar esta nueva funcionalidad para dar acceso a un usuario usando un certificado firmado por la CA del clúster.
<!--more-->

## Generar la petición de firma del certificado (CSR) a partir de la clave privada del usuario

El usuario genera una clave privada mediante:

```bash
openssl genrsa -out ${keyName} ${keyBITS}
```

A continuación, genera una *certificate signing request* (CSR) a partir de la clave privada generada:

```bash
openssl req -new -key ${keyOwner}.key \
            -out csr_${keyOwner}.csr \
            -subj "/CN=${keyOwner}/O=${keyOwnerGroup}"
```

En la petición, es importante que se incluya, en el campo `-subj`:

- `CN` (*Common Name*): este es el nombre con el que se identifica al usuario en el clúśter
- `O` (*Organization*): indica a qué grupo (o grupos) pertenece el usuario. Lo usaremos para asignar un rol a los usuarios miembros del grupo.

## Creando el *manifest* para el `CertificateSigningRequest`

En primer lugar, codificamos el CSR en base64 (y eliminamos los saltos de línea):

```bash
base64EncodedCSR=$(cat ${csrFile} | base64 | tr -d '\n')
```

Después, generamos el *manifest*:

```bash
cat > csr_${keyOwner}_manifest.yaml << EOF
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ${keyOwner}-csr
spec:
  signerName: kubernetes.io/kube-apiserver-client
  request: ${base64EncodedCSR}
  usages:
  - client auth
EOF
```

Como vemos, estamos firmando un certificado que podrá usarse para autorizar un cliente:

```yaml
[...]
  usages:
  - client auth
```

En la documentación oficial de Kubernetes puedes consultar otros usos: [Certificate Signing Requests: Signers](https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/#signers).

> Para Kubernetes 1.22+ se puede especificar la duración del certificado expedido mediante el campo `spec.expirationSeconds`.

Creamos el objeto en la API de Kubernetes mediante:

```bash
kubectl apply -f ${csrManifestFile}
```

## Aprobando el certificado en Kubernetes con `kubectl`

El cliente `kubctl` permite realizar la aprobación (o denegación) de las peticiones de firma a través del comando `kubectl certificate approve` (o `deny`).

Las peticiones aprobadas, denegadas y fallidas, se eliminan automáticamente del clúster pasada una hora. Las peticiones pendientes, tras 24 horas.

Una vez aprobado el certificado, los clientes lo pueden obtener realizando llamdas a la API, obteniéndolo del campo `status.certificate`.

```bash
kubectl get csr -o jsonpath="{.items[?(@.metadata.name==\"${k8sUSER}-csr\")].status.certificate}" | base64 --decode | tee ${userSignedCertificate}
```

Podemos inspeccionar el certificado obtenido:

```bash
$ openssl x509 -in xavi_signed_certificate.crt -text -noout
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            ed:ea:7c:5e:3c:65:03:d4:a8:f2:b7:ef:4f:ac:2d:49
        Signature Algorithm: ecdsa-with-SHA256
        Issuer: CN = k3s-client-ca@1632676250
        Validity
            Not Before: Dec  5 17:38:21 2021 GMT
            Not After : Dec  5 17:38:21 2022 GMT
        Subject: O = managers, CN = xavi
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                RSA Public-Key: (4096 bit)
            .
            .
            .
```

## Generar el fichero `kubeconfig` para el usuario

En el fichero `kubeconfig` se define un *cluster*, un *user* y un *context*, que relaciona un *user* con un *cluster*.

La información relativa al clúster la podemos extraer el fichero `kubeconfig` del usuario con el que se han realizado las acciones anteriores; primero determinamos cuál es el *current context*:

```bash
kubectl config view -o jsonpath='{.current-context}'
```

Así podemos obtener la información relativa al clúster:

```bash
# Get cluster's name from current context
kubectl config view -o jsonpath="{.contexts[?(@.name==\"${kubeconfigCurrentContext}\")].context.cluster}"
# Get API URL from context
kubectl config view -o jsonpath="{.clusters[?(@.name==\"${clusterName}\")].cluster.server}"
```

Tambien obtenemos el certificado público de la entidad certificadora y lo guardamos en un fichero:

```bash
kubectl config view --raw -o jsonpath="{.clusters[?(@.name==\"${clusterName}\")].cluster.certificate-authority-data}" | base64 --decode | tee cluster_ca_file.cert
```

Con esta información, generamos la parte relativa al clúster del fichero `kubeconfig` personalizado para el usuario:

```bash
kubectl --kubeconfig=${k8sUSER}_kubeconfig config set-cluster ${k8sClusterName} \
        --server="${apiURL}" --certificate-authority="${clusterCAfile}" --embed-certs=true
```

Para la sección relativa al usuario en el fichero `kubeconfig`, dispondemos de toda la información de pasos anteriores:

```bash
kubectl --kubeconfig=${k8sUSER}_kubeconfig config set-credentials ${k8sUSER} \
    --client-certificate=${k8sUSER}_signed_certificate.crt \
    --client-key=${k8sUSER}.key \
    --embed-certs=true
```

Relacionamos el usuario y el clúster mediante un contexto:

```bash
kubectl --kubeconfig=${k8sUSER}_kubeconfig config set-context ${k8sUSER}@${k8sClusterName} \
        --user="${k8sUSER}" --cluster="${k8sClusterName}"
```

Finalmente, definimos el contexto recién definido como el *current context* del fichero:

```bash
 kubectl --kubeconfig=${k8sUSER}_kubeconfig config use-context ${k8sUSER}@${k8sClusterName}
```

## Validación

El usuario ya puede autenticar sus llamadas identificándose con su clave privada y el certificado firmado por la CA del clúster:

```bash
kubectl --kubconfig=${k8sUSER}_kubeconfig get pods
```

Para que el usuario pueda completar las llamadas, además de poder autenticarse, debe estar autorizado a realizar la acción incluida en la petición. Para ello, el usuario (o el grupo al que pertenece) debe tener asociado un `RoleBinding` con las acciones que puede realizar, sobre qué objetos de la API y en qué *namespaces*.

Una manera útil de revisar las acciones que puede realizar el usuario es mediante el comando `kubectl auth can-i`; por ejemplo:

```bash
$ kubectl auth can-i list pods --as=xavi --as-group=managers -n development
yes
$ # Los permisos del rol están limitados al namespace `development`
$ kubectl auth can-i list pods --as=xavi --as-group=managers -n kube-system
no
$ # Sólo permisos de lectura
$ kubectl auth can-i create pods --as=xavi --as-group=managers -n development
no
```

## Automatizando el proceso

Gracias a la incorporación de la gestión de certificados en Kubernetes, es posible incorporar la creación de accesos para usuarios dentro de un flujo desatendido: el usuario que requiere acceso (puntual) al clúster sube un CSR generado a partir de su clave privada a un portal de autoservicio.

Tras un revisión, el equipo de administradores del clúster aprueba la petición y se lanza el proceso que finaliza con la descarga por parte del usuario del fichero `kubeconfig` personalizado para conectar con el clúster.

Si el clúster es v1.22+, se puede ajustar la validez del certificado para que caduque tras un determinado periodo de tiempo (al fin y al cabo, no debería ser necesario acceder al clúster para nada, ¿no?).

Con esta idea, he creado un *script* tipo *prueba de concepto* que realiza todo el proceso.

El *script* está disponible en [onthedock/k8s-devops/.../automate.sh](https://github.com/onthedock/k8s-devops/blob/main/docs/seguridad/crear-usuarios-en-k8s/automate.sh).

Ejemplo:

```bash
./automate.sh -u xavi -g managers
[INFO] Generating xavi.key (4096 bits)...
Generating RSA private key, 4096 bit long modulus (2 primes)
................................................++++
....................................................................................................................................................................................................++++
e is 65537 (0x010001)
[INFO] Created CSR csr_xavi.csr
[INFO] Generating base64EncodedCSR
[INFO] Generating manifest csr_xavi_manifest.yaml
[INFO] Using csr_xavi_manifest.yaml
[INFO] Applying file csr_xavi_manifest.yaml
certificatesigningrequest.certificates.k8s.io/xavi-csr created
[INFO] xavi-csr is Pending for approval
[INFO] Approving xavi-csr...
certificatesigningrequest.certificates.k8s.io/xavi-csr approved
[INFO] Generating xavi_signed_certificate.crt ...
-----BEGIN CERTIFICATE-----
MIIDWTCCAv6gAwIBAgIQHuwjQI/iBPqmN5pBJ+oVdjAKBggqhkjOPQQDAjAjMSEw
HwYDVQQDDBhrM3MtY2xpZW50LWNhQDE2MzI2NzYyNTAwHhcNMjExMjA1MTcyMDU1
WhcNMjIxMjA1MTcyMDU1WjAmMRMwEQYDVQQKEwpkZXZlbG9wZXJzMQ8wDQYDVQQD
EwZwZXJpY28wggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQC0WhCUUHj6
8faURtQmdzs9jcAzXVj3C/IoK5hFn2Xf4/yse1tIAQlTRrbJpnZz3wERRlXToTj+
g4wm3UeGrWX/NG9cMTof7pqLgt5CCQHAfdvfCbRRc7pMTsDf9gzZbKwdL+8zKZQE
pcqCovmb799MELEBhrF7Psvb5xT4yAzKoRRGYg5U7CY+7TGPa3/mp0bqWM5dfOzO
hsJ2JA/y/FIhClSDiMIXYGAVZX8vvSXz4cyffSjlETwVYAFnlNE/LVn0Z78DyzIU
I+pAnN+dFPWR19bu0QBNROkOWyEVAcaKPP0DeZ3gx9OXJvyZ9PNWeYj4lWVNU95C
mmXPNpZiwVADPQfVt0gyUnjhiCxJlsHI4DlQ6FFRvVZ50WjoZLrK/EQ4fD4709J0
cJUK48AxeZSCxLHMjypTbsHKVHVhtikoP9yqAYQUe/gNSn3ApaVbA5fii2kxFXEW
+fxKaGJ/TYw68RXJ3bs3B7IpLNbdkgj78/Iw7Cr3KUM0b613VX3XWeoOlqbgwN+2
6n4K+XLfUBMWyEXMl5uwW4js0pn11yKpwM2Z6fMUHhDG6AtrGEV67USgWcfkiO6B
qf2yyg1L6tf/h5NRO1hpATOEpdrU/8qCdJx1693pjsgPfwNRBuBlHlYXQuyMdoqx
FfNyfMABV5FQXLdz0yeurP23Tkf44yonqwIDAQABo0YwRDATBgNVHSUEDDAKBggr
BgEFBQcDAjAMBgNVHRMBAf8EAjAAMB8GA1UdIwQYMBaAFF5NUrp44FW16SizbArY
cGpDhRc+MAoGCCqGSM49BAMCA0kAMEYCIQDjoxcaBYUpnwtiaXoSt9rshXZTXFhr
QS4GbFpw8IyhFAIhANS7H8K5lDHrYVxdssHdRDevoBBuH9GFXY3KuTbJDl3J
-----END CERTIFICATE-----
[INFO] [kubeconfig] Setting cluster "kubernetes"...
Cluster "kubernetes" set.
[INFO] [kubeconfig] Setting user "xavi"...
User "xavi" set.
[INFO] [kubeconfig] Setting context to "xavi@kubernetes"...
Context "xavi@kubernetes" created.
[INFO] [kubeconfig] Setting default context to "xavi@kubernetes"...
Switched to context "xavi@kubernetes".
```
