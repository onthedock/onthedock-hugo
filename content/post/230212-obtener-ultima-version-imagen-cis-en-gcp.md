+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["cloud", "google cloud platform", "gcp"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/google-cloud.svg"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/

# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}
# YouTube           {{< youtube w7Ft2ymGmfc >}}
# Gist              {{< gist username 7896402 >}}
# Highlight         {{< highligth language >}}...{{< /highlight >}}
# Twitter           {{< tweet user="SanDiegoZoo" id="1453110110599868418" >}}

title=  "Obtén la última versión de imágenes publicadas por el CIS en Google Cloud Platform"
date = "2023-02-12T21:23:23+01:00"
+++
El CIS publica imágenes *hardenizadas* en el Marketplace público de Google Cloud Platform (GCP). Estas imágenes se actualizan de vez en cuando, por lo que es importante usar siempre la versión más actualizada.
<!--more-->
## ¿Dónde están las imágenes?

Para obtener una lista de las imágenes disponibles, es necesario indicar el proyecto en el comando `gcloud compute list`.

Para obtener el proyecto en el que se encuentra la imagen que nos interesa, buscamos a través de la consola de GCP, en Marketplace.

Al pulsar sobre la imagen en cuestión, se muestra información general (*Overview*), precio (estimado), etc... Observando la URL identificamos en qué proyecto se encuentra.

Por ejemplo, para la imagen del CIS para Debian 10, la URL sobre esta imagen es:

```bash
https://console.cloud.google.com/marketplace/product/cis-public/cis-debian-linux-10-level-1
```

El nombre del proyecto se encuentra *antes* del nombre de la imagen; así pues, `cis-public`.

Usando la herramienta de CLI `gcloud`, obtenemos la lista de todas las imágenes ofrecidas por el CIS:

```bash
gcloud compute images list --project=cis-public
```

Como el objetivo es usar la imagen en Terraform para desplegar instancias, nos interesa únicamente el nombre de las imágenes... En el caso del CIS, todas las imágenes *hardenizadas* van prefijadas por `cis-*`.

En el caso de Debian 10, tenemos varias versiones:

```bash
$ gcloud compute images list --project=cis-public --format="value(NAME)" --filter="name:cis-debian-linux-10-level-1-*"
cis-debian-linux-10-level1-v1-1-0-0-26
cis-debian-linux-10-level1-v1-1-0-0-27
cis-debian-linux-10-level1-v1-1-0-0-28
cis-debian-linux-10-level1-v1-1-0-0-29
```

El siguiente paso es obtener la última disponible...

```bash
latest_version() {
  local image_name="$1"
  local filter="name:${image_name}-*"
  available_versions=$(gcloud compute images list --project=cis-public --format="value(NAME) --filter="${filter}")
  latest=0
  for v in $available_versions; do
    version=$(awk -F '-v' '{ print $2 }' <<< "${v}")
    if [[ "${version}" -gt "${latest}" ]];then
      latest="${version}"
    fi
  fone
  echo "projects/cis-public/global/images/${image_name}-v${latest}"
}
```

Una vez obtenemos la última versión disponible para las imágenes que nos interesan, pasamos los resultados a un *map* de Terraform:

```bash
debian10="cis-debian-linux-10-level1"

tee "cis_images.auto.tfvars" <<LATEST_CIS_IMAGES
cis_level1_images = {
  "${!debian10*}" = "$(latest_version ${debian10})"
  ...
}
LATEST_CIS_IMAGES
```

En Terraform, consumimos esta información mediante el [meta-argumento `for_each`](https://developer.hashicorp.com/terraform/language/meta-arguments/for_each):

```json
resource "google_compute_instance" "cis_vm" {
  for_each var.cis_level1_images

  name = "vm-${each.key}-cislevel1"
  ...
  boot_disk {
    initialize_params {
      image = each.value
      ...
    }
  }
  ...
}
```

De esta forma podemos lanzar una instancia a partir de cada una de las imágenes del CIS que hayamos indicado.
