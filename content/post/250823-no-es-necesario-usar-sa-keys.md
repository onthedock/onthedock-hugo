+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["cloud", "google-cloud", "service-accounts"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/google-cloud.svg"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/
# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}

title=  "En Google Cloud no es necesario usar Service Account Keys"
date = "2025-08-23T19:37:23+02:00"
+++
El otro día uno de nuestros clientes nos solicitó crear Service Account Keys para poder automatizar unas tareas en Google Cloud.
El cliente tenía experiencia anterior en AWS, donde es necesario crear Access Keys para que, durante el desarrollo de la aplicación, pudieran probarla como si se ejecutara en el cloud.

Sin embargo, en Google Cloud, las cosas funcionan de otra forma, y usar Service Account Keys es la última opción, por ser la menos segura. Personalmente, soy *muy fan* del diagrama de esta página [Choose the right authentication method for your use case](https://cloud.google.com/docs/authentication#auth-decision-tree).
Parte de la *magia* que hace innecesario generar Service Account Keys el cómo funcionan las *Application Default Credentials* ([How Application Default Credentials works](https://cloud.google.com/docs/authentication/application-default-credentials)).

A continuación, un ejemplo de la *magia* de usar ADC y así no tener que generar Service Account Keys.
<!--more-->
## Fases del desarrollo

Queremos proporcionar el mínimo nivel de privilegio que la Service Account requiera para hacer su trabajo.
Pero quizás durante las primeras fases del desarrollo, queremos utilizar las credenciales de nuestro usuario para "validar" que todo funciona como debe.
En esta fase, usamos nuestras credenciales, no las de la Service Account. Por tanto, no es necesario usar Service Account Keys.

Es completamente válido saltarse el paso anterior y empezar a trabajar directamente usando la Service Account "final". En mi opinión, esto ralentiza el desarrollo, ya que cuando falla algo, primero hay que discernir si se trata de un error de "desarrollo" o un error de "permisos" y se *rompe* el flujo de desarrollo...

La Service Account se autentica mediante la Service Account Key, por lo que aquí es donde los clientes, en general, solicitan poder crearlas.

Pero podemos usar la identidad de la Service Account sin *autenticarnos* usando la Service Account; aquí es donde entra el concepto de *Service Account impersonation*. Como se indica en [Use service account impersonation](https://cloud.google.com/docs/authentication/use-service-account-impersonation), la idea es que nuestro usuario *asume la identidad* de la Service Account, por lo que la interacción con las APIs de Google Cloud se realiza *como si fuéramos* la Service Account.

Como vemos, en este caso, tampoco es necesario usar Service Account Keys, aunque es necesario asignar los permisos adecuados para poder *impersonar* la Service Account por parte de nuestro usuario.

Una vez pasamos la *fase de desarrollo local*, empezamos a probar la aplicación en Google Cloud, por ejemplo, desplegando en Cloud Run.
En este caso, asignamos la Service Account al servicio de Cloud Run. Google Cloud realiza la autenticación de la Service Account "internamente", facilitando el token y poniéndolo a disposición de la aplicación, de manera que la aplicación que corre en Cloud Run, interacciona con las APIs gracias al token.

Desplegar en "producción" tenemos el mismo escenario, con una Service Account asignada al servicio de Cloud Run, por lo que, de nuevo, no es necesario usar Service Account Keys.

{{< figure src="/images/250823/mic_drop.jpg" width="400" height="480">}}

## Configurar Application Default Credentials

Mediante `gcloud auth login`, nos validamos en Google Cloud y recibimos un token, con una validez determinada.
Para generar las Application Default Credentials seguimos el mismo proceso, pero esta vez mediante el comando `gcloud auth application-default login`.

Del mismo modo que configuramos el proyecto para nuestra identidad, hacemos lo mismo para las ADC:

```console
gcloud auth application-default set-quota-project <PROJECT_ID>
```

A partir de este momento, ya podemos *olvidarnos* de cómo autenticar la aplicación para interaccionar con Google Cloud, ya que las *bibliotecas* que Google proporciona para diversos lenguajes de programación se encargan de buscar las credenciales automáticamente.

## Ejemplo práctico: Simple Scrapper

Imaginemos que estamos desarrollando una aplicación que va a visitar una URL, descargar su contenido y copiarlo a un *bucket*. Este contenido se usará para entrenar un modelo de IA.

La aplicación se desplegará en [Cloud Run](https://cloud.google.com/run), la plataforma *serverless* de gestión de contenedores de Google Cloud.

> Las Application Default Credentials (ADC) funcionan con cualquier servicio de *Compute* al que podamos asociar una Service Account, no sólo Cloud Run.

Uno de los requerimientos para desplegar una aplicación en Cloud Run es que escuche peticiones (vía HTTP) ([Developing your service](https://cloud.google.com/run/docs/developing)).

Para *Simple Scrapper*, construiré una aplicación en Go que escuche peticiones en el puerto 8910.
La URL del sitio a *scrapear* vendrá dada por el parámetro `website`:

```console
<cloud-run-url>/?website=<URL_TO_SCRAPE>
```

> Para simplificar, únicamente descargo el HTML de la página objetivo.

### Show me the code

La aplicación en sí no es relevante, ya que el objetivo es mostrar cómo desarrollar y desplegar sin necesidad de usar Service Account Keys.

La estructura general de la aplicación es (para este ejemplo):

* `func main()`: establece el *handler* para la ruta `/` y ejectuta `http.ListenAndServe(":"+port")` para escuchar peticiones en el puerto indicado.
* `func saveWebsite(web string) error`: realiza una petición `GET` a la URL y descarga la respuesta (HTML) en el fichero `/tmp/output.html`
* `func copyToBucket(bucketName string, fileName string) error`: copia el fichero con el HTML al bucket objetivo.
* `func handler(w http.ResponseWriter, r *http.Request)`: el *handler* de las peticiones. Comprueba si hay un parámetro `website` como parte de la URL, valida que se trate de una URL válida y si es así, llama a `saveWebsite`.
  Si `saveWebsite` no devuelve un error, llama a `copyToBucket`.
  Si `copyToBucket` no devuelve un error, se muestra el mensaje `<websiteURL> saved!`.
  Si en cualquier caso se produce un error, se devuelve un mensaje indicando qué tipo de error se ha producido.

La función `copyToBucket` es la que interacciona con la API de Google Cloud Storage, por lo que necesita que esta petición esté autenticada.

El *cliente* de Go para la API de Google Cloud Storage es el que se encarga de buscar las credenciales para interaccionar con las APIs de Google. De la página [Cloud Storage (GCS) - Package cloud.google.com/go/storage (v1.51.0)](https://cloud.google.com/go/docs/reference/cloud.google.com/go/storage/latest):

> The client will use your default application credentials. Clients should be reused instead of created as needed. The methods of Client are safe for concurrent use by multiple goroutines.

Si estamos desarrollando en local, puede usar las Application Default Credentials, mientras que si la aplicación corre en Cloud Run, por ejemplo, buscará las credenciales (obtenidas automáticamente) de la Service Account asociada al servicio de Cloud Run.

La *magia* es que no es necesario modificar el código de la aplicación y lo único que necesitamos es *instanciar* un *cliente* mediante:

```go
client, err := storage.NewClient(ctx) // Connect to bucket
```

El código de [storage.NewClient(ctx)](https://github.com/googleapis/google-cloud-go/blob/storage/v1.56.1/storage/storage.go#L151) se encarga de buscar las credenciales por nosotros.

> Si lo tuyo es Python: [Python Client for Google Cloud Storage](https://cloud.google.com/python/docs/reference/storage/latest)

El código completo de la función es:

> El contenido de la web *scrapeada* se guarda siempre con el mismo nombre en el bucket de destino, por lo que múltiples peticiones al servicio sobreescriben el fichero.

```go
func copyToBucket(bucketName string, fileName string) error {
    ctx := context.Background()
    client, err := storage.NewClient(ctx) // Connect to bucket
    if err != nil {
        log.Printf("error creating Google Cloud Storage client: %s\n", err)
        return err
    }
    defer client.Close()

    gsw := client.Bucket(bucketName).Object("website/output.html").NewWriter(ctx)

    f, err := os.Open(fileName)
    if err != nil {
        log.Printf("error opening file for reading %s:\n", err)
        return err
    }
    defer f.Close()

    if _, err := io.Copy(gsw, f); err != nil {
        log.Printf("error copying file to bucket %s: %s\n", bucketName, err)
        return err
    }

    if err := gsw.Close(); err != nil {
        return fmt.Errorf("Writer.Close: %w", err)
    }

    log.Printf("website saved to bucket %s\n", bucketName)
    return nil
}
```

Compilando la aplicación, podemos ejecutarla desde nuestro equipo local usando mis credenciales y validar que se genera el fichero con el contenido de la web objetivo en el bucket.

El siguiente paso ha sido *containerizar* la aplicación:

> Ha sido necesario instalar el paquete `ca-certificates` para evitar errores tanto *scrapeando* webs con HTTPS como para interaccionar con las API de Google Cloud.

```Dockerfile
FROM bitnami/minideb

EXPOSE 8910

RUN install_packages ca-certificates
COPY ./simplescrapper /app/
ENTRYPOINT ["/app/simplescrapper"]
```

Después de construir la imagen, la he etiquetado y subido a Artifact Registry.

Desde ahí, he desplegado la aplicación en Cloud Run, asignando una Service Account creada para la aplicación.

La Service Account **no tiene ningún permiso asociado** en el proyecto:

```console
$ gcloud iam service-accounts get-iam-policy scrapper-saver@<PROJECT_ID>.iam.gserviceaccount.com
etag: ACAB
```

Los únicos permisos asignados a la Service Account son sobre el bucket donde debe guardar el fichero HTML de la web objetivo:

```console
$  gcloud storage buckets get-iam-policy gs://<BUCKET_NAME>
bindings:
- members:
  - serviceAccount:scrapper-saver@<PROJECT_ID>.iam.gserviceaccount.com
  role: roles/storage.objectCreator
etag: CAQ=
```

## Resumen

La autenticación en Google se basa en *tokens* que tienen una validez limitada en el tiempo.
El proceso de autenticación permite generar los tokens en ubicaciones predefinidas.
De esta forma, las aplicaciones pueden encontrarlas independientemente del entorno en el que se ejecutan.
Ésto permite que el mismo código se pueda ejecutar en un entorno de desarrollo local o en Google Cloud sin modificar la aplicación.

Las *librerías* proporcionadas por Google para los lenguajes de programación como Go, Python, etc, se encargan de buscar las credenciales en las ubicaciones predeterminadas, por lo que el desarrollador no tiene que preocuparse de desarrollar código específico para que la aplicación se autentique contra Google Cloud.

Durante la fase de desarrollo, se pueden configurar Application Default Credentials a partir de las credenciales de un usuario. Cuando la aplicación se despliega en Google Cloud, servicios como Cloud Run o Compute Engine interaccionan con los sistemas de autenticación de Google Cloud *internamente*, obteniendo tokens que permiten a las Service Accounts autenticar sus peticiones contra las APIs de Google Cloud.

En ningún caso, es necesario usar Service Account Keys.
