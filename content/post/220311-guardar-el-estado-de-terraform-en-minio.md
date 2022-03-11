+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "docker", "minio", "terraform"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/terraform.svg"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/

# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}
# YouTube           {{< youtube w7Ft2ymGmfc >}}
# Gist              {{< gist username 7896402 >}}
# Highlight         {{< highligth language >}}...{{< /highlight >}}
# Twitter           {{< tweet user="SanDiegoZoo" id="1453110110599868418" >}}

title=  "Guardar el estado de Terraform en MinIO"
date = "2022-03-11T18:59:41+01:00"
+++
Terraform almacena el *estado* de la configuración en un fichero. Este fichero es **crítico** para que Terraform pueda mantener la coherencia entre el estado definido en los ficheros de configuración y el estado *real* de la infraestructura desplegada.

Por defecto, Terraform almacena el *estado* de forma local; para facilitar la colaboración entre diferentes miembros de un equipo -entre otros casos de uso-, Terraform ofrece la posibilidad de usar otras ubicaciones para guardar el estado. Estas *ubicaciones* reciben el nombre de *backends* en Terraform (y hay unos cuantos disponibles, como puedes observar desplegando la entrada [Available Backends](https://www.terraform.io/language/settings/backends) en la web de Terraform).

Una opción habitual es la de usar un *bucket* en un servicio como [S3](https://www.terraform.io/language/settings/backends/s3) de AWS como *remote backend*. Pero si no tienes acceso a una cuenta de AWS, puedes usar [MinIO](https://docs.min.io/docs/MinIO-docker-quickstart-guide.html) para trabajar con un *backend* de tipo S3 de forma completamente *offline* (por ejemplo, para aprender cómo funciona Terraform ;-D )
<!--more-->

Para realizar las pruebas de este tutorial, he creado una máquina con Ubuntu Server 20.04 y Terraform instalado:

> Tienes las instrucciones para instalar Terraform en [Install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)

```bash
$ terraform -version
Terraform v1.1.7
on linux_amd64
```

Para desplegar MinIO, usaremos Docker; instalamos Docker siguiendo las instrucciones de la documentacion oficial: [Install Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/).

Una vez instalado (y añadido el usuario al grupo `docker`, para poder ejecutar los comandos sin *sudo*):

```bash
$ docker --version
Docker version 20.10.13, build a224086
```

## Desplegar MinIO

MinIO se puede desplegar en modo *standalone* o *distribuido* (con replicación). Para nuestro caso de uso, será más que suficiente usar el modo *standalone* siguiendo las instrucciones de la documentación oficial [MinIO Docker Quickstart Guide](https://docs.min.io/docs/minio-docker-quickstart-guide.html).

Voy a crear un volumen que montaré en el contenedor en `/data`.

```bash
$ docker volume create minio-data
minio-data
```

> Podría montar una carpeta local como volumen para MinIO, pero usando un volumen se *dificulta* el acceso al fichero *tfstate* y evitamos la tentación de modificarlo directamente (o borrarlo por error).

Al inicializar MinIO, debes definir el nombre y la contraseña para el usuario `root`; como MinIO es compatible con la API de S3, es habitual definirlos *como si fueran* una pareja de *access y secret key* de acceso a AWS (pero pueden tener cualquier formato)...

En mi caso, aunque se trata de una demo, voy a usar una contraseña bastante segura (también podemos dejar que MinIO las genere al azar al arrancar por primera vez):

```bash
ROOTSECRET=AKIADEVROOTSECRETKEY
ROOTPASSWD=$(openssl rand -hex 20) // 94587c851f9caea663bfda680abade510296fbce
```

Esta es clave del usuario `root` de MinIO, que tiene permisos totales; para el acceso al *bucket*, crearemos una claves restringidas (es importante seguir buenas prácticas incluso en los entornos de desarrollo y las demos).

Una vez creado el volumen y las claves del usuario `root`, lanzamos el contenedor:

```bash
$ docker run -d \
    -p 9000:9000 \
    -p 9001:9001 \
    --name minio \
    -e "MINIO_ROOT_USER=$ROOTSECRET" \
    -e "MINIO_ROOT_PASSWORD=$ROOTPASSWD" \
    -v minio-data:/data \
    quay.io/minio/minio server /data --console-address ":9001"
6bc564ad8de3c44596acff6cf928bdc37caf3e2a3ac75f5905cb16d1f7f55ef2
```

Revisando los *logs* del contenedor, vemos que se *publica* la consola en el puerto 9001:

```bash
$ docker logs minio
API: http://172.17.0.2:9000  http://127.0.0.1:9000 

Console: http://172.17.0.2:9001 http://127.0.0.1:9001 

Documentation: https://docs.min.io
```

En mi caso, la IP de la máquina virtual donde estoy realizando las pruebas tiene IP `192.168.1.112` por lo que acceso a la consola a través de `http://192.168.1.112:9001/` usando los valores de `$ROOTSECRET` y `$ROOTPASSWD`.

> Todas las acciones que se describen a continuación se pueden realizar desde la consola de MinIO, pero para creo que es fácil de documentar proporcionando los comandos necesario usando el cliente `mc`.

## Creación de un usuario con permisos restringidos

Definimos un usuario `AKIATERRAFORMUSER` y generamos una contraseña, que apuntamos temporalmente en algún sitio:

```bash
USERSECRET=AKIATERRAFORMUSER
USERPASSSWD=$(openssl rand -hex 20) // d4dfaa5b380b115cc2a2a94695b14ddd9f527fdf
```

Como no tengo el cliente de MinIO instalado (ni la AWS CLI, con la que MinIO es compatible), descargo el cliente `mc` en el contenedor de MinIO.

```bash
$ docker exec -it minio bash
[root@6bc564ad8de3 /]# cd /bin/
[root@6bc564ad8de3 /]# curl -JLO https://dl.min.io/client/mc/release/linux-amd64/mc
[root@6bc564ad8de3 /]# chmod +x /bin/mc
```

Como el cliente `mc` puede trabajar con múltiples servicios (AWS, Azure, GCP y servidores de MinIO), el primer paso consiste en definir un *alias* para cada uno de los *endpoints* con los que trabajaremos; en nuestro caso, definimos un *alias* llamado `tfminio`, al que nos conectamos con el usuario `root`:

> El acceso al *bucket* en MinIO lo realizará Terraform usando el *plugin* del *backend* de S3, por lo que no es necesario disponer del cliente `mc` (o de AWS CLI) instalado.

```bash
[root@6bc564ad8de3 /]# mc alias set tfminio http://localhost:9000 AKIADEVROOTSECRETKEY 94587c851f9caea663bfda680abade510296fbce
Added `tfminio` successfully.
```

Añadimos un nuevo usuario (diferente al `root` de MinIO) al que llamo `AKIATERRAFORMUSER` (de nuevo, he generado la constraseña del usuario mediante `openssl rand -hex 20`):

```bash
[root@6bc564ad8de3 /]# mc admin user add tfminio AKIATERRAFORMUSER d4dfaa5b380b115cc2a2a94695b14ddd9f527fdf
Added user `AKIATERRAFORMUSER` successfully.
```

Creamos el *bucket* donde almacenaremos el estado de Terraform:

```bash
[root@6bc564ad8de3 /]# mc mb tfminio/terraform-dev
Bucket created successfully `tfminio/terraform-dev`.
```

MinIO proporciona unas políticas predefinidas, pero en mi opinión, son demasiado *generales*: `consoleAdmin`, `diagnostics`, `readonly`, `readwrite` y `writeonly`. Todas las políticas proporcionan permisos (o los restringen) a todos los *buckets* (en MinIO) a través del campo *resource*: `arn:aws:s3:::*`.

De nuevo, siguiendo buenas prácticas -aunque se trate de un entorno *demo*- definimos una política más restrictiva (aunque todavía demasiado permisiva, al contener `s3:*`), llamada `tf-dev`:

```bash
[root@6bc564ad8de3 /]# cat > bucket_terraform_dev.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::terraform-dev/*"
      ],
      "Sid": ""
    }
  ]
}
EOF
[root@6bc564ad8de3 /]# mc admin policy add tfminio tf-dev bucket_terraform_dev.json 
Added policy `tf-dev` successfully.
```

Aplicamos esta política al usuario `AKIATERRAFORMUSER` para que sólo puede escribir sobre el *bucket* indicado `"arn:aws:s3:::terraform-dev/*"`:

```bash
[root@6bc564ad8de3 /]# mc admin policy set tfminio tf-dev user=AKIATERRAFORMUSER
Policy `tf-dev` is set on user `AKIATERRAFORMUSER`
```

Todavía como `root`, creamos un segundo *bucket*:

```bash
[root@6bc564ad8de3 /]# mc mb tfminio/terraform-prod
Bucket created successfully `tfminio/terraform-prod`.
```

Listamos los *buckets*:

```bash
[root@6bc564ad8de3 /]# mc ls tfminio
[2022-03-11 19:24:11 UTC]     0B terraform-dev/
[2022-03-11 19:54:54 UTC]     0B terraform-prod/
```

Usaremos este *bucket* para validar que el usuario `AKIATERRAFORMUSER` sólo tiene acceso al *bucket* indicado en la política que hemos aplicado.

Nos convertimos en el usuario `AKIATERRAFORMUSER` y definimos un *alias* con sus credenciales:

```bash
[root@6bc564ad8de3 /]# mc alias set tfdev http://localhost:9000 AKIATERRAFORMUSER d4dfaa5b380b115cc2a2a94695b14ddd9f527fdf
Added `tfdev` successfully.
```

Y si listamos todos los *buckets* en este *endpoint* de MinIO:

```bash
[root@6bc564ad8de3 /]# mc ls tfdev
[2022-03-11 19:24:11 UTC]     0B terraform-dev/
```

En este punto, ya tenemos el servidor de MinIO con un usuario y un *bucket* creado (con el acceso restringido a través de la política que hemos creado) que podemos usar en Terraform como *backend* de tipo S3, sin tener que estar conectados a internet o tener una cuenta en AWS.

## Configurar Terraform para usar MinIO como *backend*

Creamos un fichero de configuración de Terraform para definir la configuración del *backend*:

```bash
operador@terraform:~/repos/minio-backend$ touch backend.tf
```

En el fichero `backend.tf` definimos:

> Todas las entradas de `skip_*` son para evitar que Terraform de error al intentar validar *cosas* con AWS, cuando está conectando con MinIO.

```hcl
terraform {
  backend "s3" {
    bucket = "terraform-dev"
    key    = "terraform.tfstate"

    endpoint = "http://localhost:9000"

    access_key = "AKIATERRAFORMUSER"
    secret_key = "d4dfaa5b380b115cc2a2a94695b14ddd9f527fdf"

    region                      = var.region
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    force_path_style            = true
  }
}
```

Lanzamos el comando `terraform init` para inicializar el *backend*:

```bash
$ terraform init

Initializing the backend...

Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.

Initializing provider plugins...

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

Para validar que el estado se almacena en el *backend*, usamos el `null_resource` (creamos el fichero `resources.tf`):

```bash
resource "null_resource" "test" {
}
```

Inicializamos de nuevo el *backend* (necesitamos el *provider* `hashicorp/null`):

```bash
$ terraform init

Initializing the backend...

Initializing provider plugins...
- Finding latest version of hashicorp/null...
- Installing hashicorp/null v3.1.0...
- Installed hashicorp/null v3.1.0 (signed by HashiCorp)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

El siguiente paso es ejecutar `terraform plan`:

```bash
$ terraform plan -out null.tfplan

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following
symbols:
  + create

Terraform will perform the following actions:

  # null_resource.test will be created
  + resource "null_resource" "test" {
      + id = (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.

────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Saved the plan to: null.tfplan

To perform exactly these actions, run the following command to apply:
    terraform apply "null.tfplan"
```

Vemos que, efectivamente, se va a crear el *null_resource*; así que *aplicamos* la configuración:

```bash
$ terraform apply "null.tfplan"
null_resource.test: Creating...
null_resource.test: Creation complete after 0s [id=2160002988493378089]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

Para validar que el estado se encuentra en el *bucket* de MinIO, inspeccionamos el fichero `tfstate`:

```bash
$ cat .terraform/terraform.tfstate 
{
    "version": 3,
    "serial": 6,
    "lineage": "f746310a-f840-318f-0a4f-efd22599435d",
    "backend": {
        "type": "s3",
        "config": {
            "access_key": "AKIATERRAFORMUSER",
            ...
            "bucket": "terraform-dev",
            ...
            "endpoint": "http://localhost:9000",
            ...
            "key": "terraform.tfstate",
            ...
            "region": "eu-central-1",
            ...
            "secret_key": "d4dfaa5b380b115cc2a2a94695b14ddd9f527fdf",
            ...
```

Mientras que en el *bucket* (descargamos el fichero usando la consola de MinIO), el fichero `terraform.tfstate` contiene el estado del *null_resource*:

```bash
{
  "version": 4,
  "terraform_version": "1.1.7",
  "serial": 0,
  "lineage": "421b8f25-732d-15a0-f2f9-43e36da91bc9",
  "outputs": {},
  "resources": [
    {
      "mode": "managed",
      "type": "null_resource",
      "name": "test",
      "provider": "provider[\"registry.terraform.io/hashicorp/null\"]",
      "instances": [
        {
          "schema_version": 0,
          "attributes": {
            "id": "2160002988493378089",
            "triggers": null
          },
          "sensitive_attributes": [],
          "private": "bnVsbA=="
        }
      ]
    }
  ]
}
```

## Mejorando la configuración

En el fichero de configuración del *backend* estamos incluyendo las credenciales de acceso a MinIO, lo que no es una buena idea.

Podemos eliminar las credenciales *hardcodeadas* usando las variables de entorno:

```bash
export MINIO_ACCESS_KEY="AKIATERRAFORMUSER"
export MINIO_SECRET_KEY="d4dfaa5b380b115cc2a2a94695b14ddd9f527fdf"
```

En este caso, tenemos que pasar las variables al comando `terraform init`:

> Como hemos inicializado anteriormente el *backend*, tenemos que pasar el *flag* `-reconfigure`:

```bash
$ terraform init \
   -backend-config="access_key=$MINIO_ACCESS_KEY" \
   -backend-config="secret_key=$MINIO_SECRET_KEY" \
   -reconfigure

Initializing the backend...

Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.

Initializing provider plugins...
- Reusing previous version of hashicorp/null from the dependency lock file
- Using previously-installed hashicorp/null v3.1.0

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

## Conclusión

Gracias a MinIO podemos usar *buckets* compatibles con S3 sin necesidad de pagar por recursos cloud. De esta forma podemos usar un *backend* remoto de Terraform para disponer de un entorno de desarrollo *offline*, en nuestra máquina o bien usando un servidor de MinIO en red interna/local.

Obviamente, no tiene mucho sentido trabajar *offline* si queremos desplegar recursos en el cloud.

Sin embargo, hay otros casos de uso -como por ejemplo, gestionar recursos de [Kubernetes](https://registry.terraform.io/providers/hashicorp/kubernetes/latest), por ejemplo- en los que disponer de un entorno *remoto* sin necesidad de estar *online* puede ser interesante, si tu intención es la de usar la misma herramienta para provisionar la infraestructura sobre la que correrá Kubernetes y los elementos que se desplieguen en el clúster.
