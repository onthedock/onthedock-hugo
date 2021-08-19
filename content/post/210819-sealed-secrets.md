+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["kubernetes", "sealed secrets"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/kubernetes.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}

title=  "Instalación de Sealed Secrets (SealedSecrets-I)"
date = "2021-08-19T20:18:20+02:00"
+++
- [Instalación de SealedSecrets (SealedSecrets - I)]({{< ref "210819-sealed-secrets.md" >}})
- [Creación de SealedSecrets (SealedSecrets - II)]({{< ref "210819-sealed-secrets-ii.md" >}})

Uno de los problemas abiertos de Kubernetes es la gestión de los *secretos*; es decir, aquella información sensible que, al menos de momento, se guarda en texto plano y cuya única medida de "seguridad" consiste en codificarla en [base64](https://es.wikipedia.org/wiki/Base64).

Tal y como se indica en el `README.md` de [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), **puedes gestionar toda la configuración de Kubernetes en Git... excepto los *Secrets***, precisamente porque los *Secrets* no son seguros...

Con el auge de metodologías como [GitOps](https://www.weave.works/technologies/gitops/), el problema es mayor, ya que los desarrolladores no tienen acceso directo al clúster y **todo** debe desplegarse automáticamente desde Git.

Una de las soluciones al problema viene del equipo de [Bitnami-Labs](https://github.com/bitnami-labs/) con **SealedSecrets**.

<!--more-->

La solución se compone de dos partes: un controlador en el clúster y una herramienta cliente `kubeseal`.

`kubeseal` usa criptografía asimétrica, de manera que el *secret* **sellado** con la clave pública sólo puede desencriptarla el controlador (que tiene la clave privada). Esos secretos *cifrados* se almacenan en un objeto llamado `SealedSecret`, que se usa como una plantilla para crear un *Secret* que las aplicaciones pueden usar con normalidad.

El *Secret* "depende" del *SealedSecret* y se actualiza (o borra) siempre que lo hace el *SealedSecret*.

## Instalación de *Sealed Secrets*

Estas son las versiones con las que he probado los *SealedSecrets*:

| Producto | Versión |
| -- | -- |
| **kubectl** (`kubectl version --short`) | Client Version: v1.19.4 |
| (**k3s**) | Server Version: v1.21.2+k3s1 |
| **Helm** (`helm version --short`) | v3.6.2+gee407bd |
| **SealedSecrets** | v0.16.0 (*Helm Chart*: 1.16.1) |

Hay diversas formas de instalar *Sealed Secrets*; usaré la *Helm Chart* oficial proporcionada por el equipo de *Sealed Secrets*.

```bash
$ helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets

"sealed-secrets" has been added to your repositories
```

Compruebo que el repositorio se ha añadido correctamente:

```bash
$ helm repo list | grep -i sealed-secrets
sealed-secrets          https://bitnami-labs.github.io/sealed-secrets
```

Actualizo el repositorio e instalo desde la *chart*:

```bash
helm repo update
```

> `kubeseal` usa como nombre por defecto `sealed-secrets-controller`, por lo que uso este nombre para desplegar *Sealed Secrets*. De esta forma no hace falta especificar `--controller-name` en cada acción que se realice con `kubeseal`. Por el mismo motivo, instalo *Sealed Secrets* en el *namespace* `kube-system`.

```bash
$ helm install sealed-secrets-controller sealed-secrets/sealed-secrets -n kube-system
NAME: sealed-secrets-controller
LAST DEPLOYED: Wed Aug 18 21:23:36 2021
NAMESPACE: kube-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
You should now be able to create sealed secrets.

1. Install client-side tool into /usr/local/bin/

GOOS=$(go env GOOS)
GOARCH=$(go env GOARCH)
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.16.0/kubeseal-$GOOS-$GOARCH
sudo install -m 755 kubeseal-$GOOS-$GOARCH /usr/local/bin/kubeseal

2. Create a sealed secret file

# note the use of `--dry-run` - this does not create a secret in your cluster
kubectl create secret generic secret-name --dry-run --from-literal=foo=bar -o [json|yaml] | \
 kubeseal \
 --controller-name=sealed-secrets-controller \
 --controller-namespace=kube-system \
 --format [json|yaml] > mysealedsecret.[json|yaml]

The file mysealedsecret.[json|yaml] is a commitable file.

If you would rather not need access to the cluster to generate the sealed secret you can run

kubeseal \
 --controller-name=sealed-secrets-controller \
 --controller-namespace=kube-system \
 --fetch-cert > mycert.pem

to retrieve the public cert used for encryption and store it locally. You can then run 'kubeseal --cert mycert.pem' instead to use the local cert e.g.

kubectl create secret generic secret-name --dry-run --from-literal=foo=bar -o [json|yaml] | \
kubeseal \
 --controller-name=sealed-secrets-controller \
 --controller-namespace=kube-system \
 --format [json|yaml] --cert mycert.pem > mysealedsecret.[json|yaml]

3. Apply the sealed secret

kubectl create -f mysealedsecret.[json|yaml]

Running 'kubectl get secret secret-name -o [json|yaml]' will show the decrypted secret that was generated from the sealed secret.

Both the SealedSecret and generated Secret must have the same name and namespace.
```

## Validación de la instalación

Reviso los logs del *pod* de *Sealed Secrets* en el *namespace* `kube-system` para verificar que ha arrancado correctamente y que se ejecuta con normalidad:

```bash
$ kubectl get pods -n kube-system \
  -l app.kubernetes.io/name=sealed-secrets
NAME                                         READY   STATUS    RESTARTS   AGE
sealed-secrets-controller-7b649d967c-7zczz   1/1     Running   0          2m47s
```

```bash
$ kubectl logs \
  $(kubectl get pods -n kube-system -l app.kubernetes.io/name=sealed-secrets -o jsonpath='{ .items[0].metadata.name }')) \
  -n kube-system

controller version: v0.16.0
2021/08/18 19:23:50 Starting sealed-secrets controller version: v0.16.0
2021/08/18 19:23:50 Searching for existing private keys
2021/08/18 19:23:54 New key written to kube-system/sealed-secrets-keylr2w9
2021/08/18 19:23:54 Certificate is 
-----BEGIN CERTIFICATE-----
MIIErTCCApWgAwIBAgIQBiQc7Z+Z8n8xtYME0Bs40jANBgkqhkiG9w0BAQsFADAA
MB4XDTIxMDgxODE5MjM1NFoXDTMxMDgxNjE5MjM1NFowADCCAiIwDQYJKoZIhvcN
AQEBBQADggIPADCCAgoCggIBANh5a5otzFHEPfMrDJPFhZIR0fQ+7HLSmZb6EOxQ
NbI4uV/L06Icq+K28deCCPQgp2GTnVO2oMJql/fMbkYCSWZMmRSIXKdBZca8dJOJ
WUxOYQ66qS1p2iLJl9NmClXZp2GMxzQbrBRRwss4TdW+Y+zj0YY5VzxbYxz3NRt6
/3fUfOEl9J5zsfJp/uY/HnfWrtHu1lZjmwj/zabd/D+Guw3cdQ07UdQ1B9FhZBzu
+/sf0DGLA/FRo0uOE8q/uTiY+l0GqyJeM3WxjrFSEF+WBgdbE26OaIeE+w9yOENq
8dsyCxqkI+Oa5xtFkBaN8T6dLJTlubdzq2ioohnlPOUQymK5Tct5/EhvFtAAczij
/Ko2nDBFIw9HFMtXOBkeDsRDyIllO+e+BOxYsmxQV8b6CzmwrfAOQ2MbaT7v/78H
E8cWu6viRwbKdrCuR8Y30JgG6LlXKTKSRyXmirAhRpTkRcbu0E8kQOA9uwkDDrmP
b6ScO7CJcnDlA4eWxvL4D6Oik7f94TpbKbpG07bSLh4HNIJ+V8gxnT3FWE8BAEtH
sR0lFBvewVeZhD6okvbN40vJFhV36Imx4suJ7DjdudGqrCVc2XyMt8ezQDRWADy+
MlNOFxpTe8xp6HUpHWohZ2yPk3biBQhTBdx5nacmwzmoI8zsxP/vk/8KV6bnsT1a
Bv5HAgMBAAGjIzAhMA4GA1UdDwEB/wQEAwIAATAPBgNVHRMBAf8EBTADAQH/MA0G
CSqGSIb3DQEBCwUAA4ICAQAou/AreNf51u9HwGoxctCdxVx6hvCjwh/7SCMQ0dJ5
zq52y6EOR0ZXOZ+ZllUkZb0PMv3jMjpVfYo4AlzpoMS9jEfsPN/AvHf2z71VzJvM
S7Qbldia6/4+MqpKjRISffW1BsAZTthAlKilDBo9+o8gioqqhMYgcvnaRduLMlYB
1dgv4X6pwTWzuASkQ6V5VrixQMa76GtRY/we/p3HfE7+af2McgpmAv8xSawUF4sV
g86ll4Hxy4U3tFjNo7iDs8upBuwc3AdvqYyBuh4l7RbxFtk1/LkZLnMhAUNI1gKr
nLS1uWiyoe+sgjip2JG9aAQoRiRXPwAN5aQgx1alQ1pLqacn78I6WC1nJENMYpYU
otSyOtxvN4oyw1ZDp3M1dEcGfiU4MT7G3ocG43QWj8lpY8UyMbZYTAU98kcmlmw5
W/xcCMuQm5YN+S3ooZcIxxO2jKJ2qNCRjfiHyMWyPRRl7aLgepozn8UmWsY7OOps
wSJXt8RFoOdXTSRQJLkXI5jtFMkkEYk9p0mYJTiRt1fpavtQ/gnSr+H7CW+II4Q6
zv3i7m2URtlkO8E348vaakjuVziJ18dJtDkyOcWKuo+fI47v57N49opvkVcoSFmP
GEQNRr+qeaJqUYguD2F5a6Mm1lIquZPI/UdmeHnfIs+CHWmcG5itvvNGhbxb8ALu
aA==
-----END CERTIFICATE-----

2021/08/18 19:23:54 HTTP server serving on :8080
```

En los logs del *pod* del controlador de *Sealed Secrets* se puede ver la clave pública del par de claves generados durante el primer arranque.

Esta es la clave pública que se usará para sellar los `SealedSecrets`.

El par de claves generados por el controlador se almacena en un *Secret* (de tipo TLS):

```bash
$ kubectl get secrets -n kube-system \
  -l sealedsecrets.bitnami.com/sealed-secrets-key=active
NAME                      TYPE                DATA   AGE
sealed-secrets-keylr2w9   kubernetes.io/tls   2      12m
```

Se puede obtener la clave pública de este *Secret*:

```bash
$ kubectl  get secret \
  $(kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key=active -o jsonpath='{ .items[0].metadata.name }') \
  -n kube-system -o jsonpath='{ .data.tls\.crt }' | base64 -d
-----BEGIN CERTIFICATE-----
MIIErTCCApWgAwIBAgIQBiQc7Z+Z8n8xtYME0Bs40jANBgkqhkiG9w0BAQsFADAA
MB4XDTIxMDgxODE5MjM1NFoXDTMxMDgxNjE5MjM1NFowADCCAiIwDQYJKoZIhvcN
AQEBBQADggIPADCCAgoCggIBANh5a5otzFHEPfMrDJPFhZIR0fQ+7HLSmZb6EOxQ
NbI4uV/L06Icq+K28deCCPQgp2GTnVO2oMJql/fMbkYCSWZMmRSIXKdBZca8dJOJ
WUxOYQ66qS1p2iLJl9NmClXZp2GMxzQbrBRRwss4TdW+Y+zj0YY5VzxbYxz3NRt6
/3fUfOEl9J5zsfJp/uY/HnfWrtHu1lZjmwj/zabd/D+Guw3cdQ07UdQ1B9FhZBzu
+/sf0DGLA/FRo0uOE8q/uTiY+l0GqyJeM3WxjrFSEF+WBgdbE26OaIeE+w9yOENq
8dsyCxqkI+Oa5xtFkBaN8T6dLJTlubdzq2ioohnlPOUQymK5Tct5/EhvFtAAczij
/Ko2nDBFIw9HFMtXOBkeDsRDyIllO+e+BOxYsmxQV8b6CzmwrfAOQ2MbaT7v/78H
E8cWu6viRwbKdrCuR8Y30JgG6LlXKTKSRyXmirAhRpTkRcbu0E8kQOA9uwkDDrmP
b6ScO7CJcnDlA4eWxvL4D6Oik7f94TpbKbpG07bSLh4HNIJ+V8gxnT3FWE8BAEtH
sR0lFBvewVeZhD6okvbN40vJFhV36Imx4suJ7DjdudGqrCVc2XyMt8ezQDRWADy+
MlNOFxpTe8xp6HUpHWohZ2yPk3biBQhTBdx5nacmwzmoI8zsxP/vk/8KV6bnsT1a
Bv5HAgMBAAGjIzAhMA4GA1UdDwEB/wQEAwIAATAPBgNVHRMBAf8EBTADAQH/MA0G
CSqGSIb3DQEBCwUAA4ICAQAou/AreNf51u9HwGoxctCdxVx6hvCjwh/7SCMQ0dJ5
zq52y6EOR0ZXOZ+ZllUkZb0PMv3jMjpVfYo4AlzpoMS9jEfsPN/AvHf2z71VzJvM
S7Qbldia6/4+MqpKjRISffW1BsAZTthAlKilDBo9+o8gioqqhMYgcvnaRduLMlYB
1dgv4X6pwTWzuASkQ6V5VrixQMa76GtRY/we/p3HfE7+af2McgpmAv8xSawUF4sV
g86ll4Hxy4U3tFjNo7iDs8upBuwc3AdvqYyBuh4l7RbxFtk1/LkZLnMhAUNI1gKr
nLS1uWiyoe+sgjip2JG9aAQoRiRXPwAN5aQgx1alQ1pLqacn78I6WC1nJENMYpYU
otSyOtxvN4oyw1ZDp3M1dEcGfiU4MT7G3ocG43QWj8lpY8UyMbZYTAU98kcmlmw5
W/xcCMuQm5YN+S3ooZcIxxO2jKJ2qNCRjfiHyMWyPRRl7aLgepozn8UmWsY7OOps
wSJXt8RFoOdXTSRQJLkXI5jtFMkkEYk9p0mYJTiRt1fpavtQ/gnSr+H7CW+II4Q6
zv3i7m2URtlkO8E348vaakjuVziJ18dJtDkyOcWKuo+fI47v57N49opvkVcoSFmP
GEQNRr+qeaJqUYguD2F5a6Mm1lIquZPI/UdmeHnfIs+CHWmcG5itvvNGhbxb8ALu
aA==
-----END CERTIFICATE-----
```

Redirigiendo la salida del comando anterior a un fichero, se puede crear *SealedSecrets* en entornos sin conectividad con el clúster.

## Reflexiones

A nivel conceptual los *SealedSecrets* son sencillos, basados en una tecnología probada (criptografía asimétrica). El despliegue no puede ser más fácil (usando, por ejemplo, la *Helm Chart*)...

Me gustaría que se integrara en `kubectl` la capacidad de obtener el certificado y firmar los *Secrets* directamente, lo que constituiría una solución al problema de la **inseguridad** de los *Secrets*.

Un punto a favor de los *SealedSecrets* es que las aplicaciones no deben modificarse y siguen consumiendo los *Secrets* de manera ordinaria, ya que el *controlador* genera un `Secret` a partir de la información contenida en el `SealedSecret`.

Los `SealedSecrets` se definen a través de un *custom resource* y se gestionan desde *dentro* del clúster, de forma completamente nativa a Kubernetes, a diferencia de otras soluciones que se basan en recursos externos.

Por todo ello, me parecen la mejor solución al problema de gestionar los *Secrets* en Kubernetes.

## Resumen

Lo mejor de los *SealedSecrets* es lo sencillo que resulta todo: como has visto, la instalación se realiza con una *Helm Chart*.

Si desde el equipo donde se van a generar los *SealedSecrets* hay conectividad con la API de Kubernetes, no necesitas hacer nada más; si no existe conectividad, un usuario con permisos debe facilitar una copia *offline* del certificado público para poder realizar el *sellado* de los certificados.

En la segunda parte sobre los *SealedSecrets*, describo cómo generar un `SealedSecret`, actualizarlo, etc.
