+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["google-cloud", "apikey", "go"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/go.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/
# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}

title=  "API Keys rotation checker - I"
date = "2026-04-25T10:02:22+02:00"
+++
Haciendo limpieza de repositorios "viejos", me encontré con [GoogleCloudPlatform/professional-services](https://github.com/GoogleCloudPlatform/professional-services). El servicio de IPAM (IP Address Management) que empezamos usando fue el proporcionado por los Servicios Profesionales de Google Cloud, pero antes de borrar el repositorio, me entretuve mirando qué otras soluciones se ofrecían...

En particular, [GCP API key rotation checker](https://github.com/GoogleCloudPlatform/professional-services/tree/main/tools/api-key-rotation) me llamó la atención, pero tiene dos problemas fundamentales; el primero, que hace más de cinco años que no se ha actualizado 😔, y el segundo, que está en Python 😅. Afortunadamente, los dos pueden solucionarse re-escribiéndo la solución en Go 😜.

En ésta entrada, explico qué pasos he seguido...
<!--more-->

## Analizando el código existente

*Grosso modo*, la aplicación ejecutan las siguientes acciones:

* obtiene la lista de todos los proyectos a los que el usuario tiene acceso
* para cada proyecto, obtiene la lista de API keys en el proyecto y obtiene sus detalles
* para cada API key, compara la fecha de creación con el valor proporcionado de "periodo de rotación de las claves" (que por defecto es de 90 días)
* finalmente, entrega una lista de claves de rotar y claves que todavía no necesitan ser rotadas.

## Planeando la versión en Go

Revisando la documentación para el SDK de Go para las API keys ([API Keys API v2](https://docs.cloud.google.com/go/docs/reference/cloud.google.com/go/apikeys/latest/apiv2)), vemos que, como en otros casos, debemos crear un cliente y una *petición* para el recurso con el que queremos interaccionar. Tras obtener el cliente y la *request*, enviamos la petición a la API. En nuestro caso, necesitamos crear una *petición para listar API keys*, es decir, [ListKeysRequest](https://docs.cloud.google.com/go/docs/reference/cloud.google.com/go/apikeys/latest/apiv2/apikeyspb#cloud_google_com_go_apikeys_apiv2_apikeyspb_ListKeysRequest). Y como vemos, tenemos que especificar el `projectId` en el campo `Parent` de `ListKeysRequest`.

Por tanto, para empezar, sólo listaremos las API keys de un proyecto especificado; más adelante, cuando querramos listar las API keys de todos los proyectos a los que tiene acceso el usuario, sólo tendremos que iterar sobre los proyectos y listar las API keys para cada proyecto.

## Manos a la obra

Empezamos inicializando el módulo en Go:

```go
go mod init github.com/xaviatwork/api-key-checker
```

Creamos el fichero `main.go` y utilizamos el ejemplo en [Example usage](https://docs.cloud.google.com/go/docs/reference/cloud.google.com/go/apikeys/latest/apiv2#hdr-Example_usage) como punto de partida:

```go
// go get cloud.google.com/go/apikeys/apiv2@latest
ctx := context.Background()
// This snippet has been automatically generated and should be regarded as a code template only.
// It will require modifications to work:
// - It may require correct/in-range values for request initialization.
// - It may require specifying regional endpoints when creating the service client as shown in:
//   https://pkg.go.dev/cloud.google.com/go#hdr-Client_Options
c, err := apikeys.NewClient(ctx)
if err != nil {
    // TODO: Handle error.
}
defer c.Close()
```

El *linter* se queja que de `apikeys` no está definido (incluso después de ejecutar `go get...` y `go mod tidy`)... Revisando el ejemplo en [pkg.go.dev](https://pkg.go.dev/cloud.google.com/go/apikeys@v1.5.0/apiv2#NewClient) para `NewClient`, vemos que se crea un *alias* para el paquete:

```go
import (
    "context"

    apikeys "cloud.google.com/go/apikeys/apiv2"
)
```

Actualizando el código y ejecutando `go mod tidy`, el *linter* deja de quejarse.

```go
package main

import (
    "context"

    apikeys "cloud.google.com/go/apikeys/apiv2"
)

func main() {
    // go get cloud.google.com/go/apikeys/apiv2@latest
    ctx := context.Background()
    // This snippet has been automatically generated and should be regarded as a code template only.
    // It will require modifications to work:
    //   - It may require correct/in-range values for request initialization.
    //   - It may require specifying regional endpoints when creating the service client as shown in:
    //     https://pkg.go.dev/cloud.google.com/go#hdr-Client_Options
    c, err := apikeys.NewClient(ctx)
    if err != nil {
        // TODO: Handle error.
    }
    defer c.Close()
}
```

## Usando el cliente

Como queremos listar las API keys, usaremos el método `ListKeys` del cliente: [func (*Client) ListKeys](https://docs.cloud.google.com/go/docs/reference/cloud.google.com/go/apikeys/latest/apiv2#cloud_google_com_go_apikeys_apiv2_Client_ListKeys). La documentación del método `ListKeys` incluye dos ejemplos; el primero, usa un *iterator* para iterar sobre todas las API keys presentes en el proyecto, mientras que el segundo usa `.All()` para obtenerlas todas de una sola vez.

Como vemos en el ejemplo, de nuevo se usa un *alias* para el paquete `apikeyspb`, por lo que copiamos y pegamos el código del ejemplo `.All()` en nuestro `main.go`:

```go
package main

import (
    "context"

    apikeys "cloud.google.com/go/apikeys/apiv2"
    apikeyspb "cloud.google.com/go/apikeys/apiv2/apikeyspb"
)

func main() {
    ctx := context.Background()
    // This snippet has been automatically generated and should be regarded as a code template only.
    // It will require modifications to work:
    // - It may require correct/in-range values for request initialization.
    // - It may require specifying regional endpoints when creating the service client as shown in:
    //   https://pkg.go.dev/cloud.google.com/go#hdr-Client_Options
    c, err := apikeys.NewClient(ctx)
    if err != nil {
        // TODO: Handle error.
    }
    defer c.Close()

    req := &apikeyspb.ListKeysRequest{
        // TODO: Fill request struct fields.
        // See https://pkg.go.dev/cloud.google.com/go/apikeys/apiv2/apikeyspb#ListKeysRequest.
    }
    for resp, err := range c.ListKeys(ctx, req).All() {
        if err != nil {
            // TODO: Handle error and break/return/continue. Iteration will stop after any error.
        }
        // TODO: Use resp.
        _ = resp
    }
}
```

## Primeros ajustes

En primer lugar, eliminamos el comentario de aviso de que el código se ha generado automáticamente y necesita ser modificado para que funcione.

Tras crear el cliente, si se produce un error, no podemos seguir adelante, por lo que saldremos mostrando el error devuelto, sin complicarnos la vida.
Haremos lo mismo con el error devuelto por `ListKeys()`.

En cuanto a los campos que hay que proporcionar en la petición, en la documentación de [ListKeysRequest](https://pkg.go.dev/cloud.google.com/go/apikeys/apiv2/apikeyspb#ListKeysRequest) el único campo requerido es `Parent`, que indica el proyecto en el que listar las API keys. Desgraciadamente, no he podido encontrar cuál es el "formato correcto" con el que especificar el proyecto en el campo `Parent` en la documentación oficial; sin embargo, en [StackOverflow](https://stackoverflow.com/a/77452242), se indica que es `projects/<project-id>/locations/global`

Para comprobar que todo funciona hasta el momento, vamos a obtener el `projectId` de una variable de entorno para insertarlo en la *request*:

```go
// ... before
    req := &apikeyspb.ListKeysRequest{
        // TODO: Fill request struct fields.
        // See https://pkg.go.dev/cloud.google.com/go/apikeys/apiv2/apikeyspb#ListKeysRequest.
    }
// ------------- 
// ... after
    req := &apikeyspb.ListKeysRequest{
        // See https://pkg.go.dev/cloud.google.com/go/apikeys/apiv2/apikeyspb#ListKeysRequest.
        Parent: fmt.Sprintf("projects/%s/locations/global", os.Getenv("PROJECTID")),
    }
```

Como utilizamos [`All()`](https://docs.cloud.google.com/go/docs/reference/cloud.google.com/go/apikeys/latest/apiv2.html#cloud_google_com_go_apikeys_apiv2_KeyIterator_All), la respuesta es un *iterator* sobre todas las *Key*.

Como sólo queremos validar que todo funciona, mostramos el *display name* de cada *key* (también reemplazamos el genérico `resp` por `k`, de *key*):

```go
// ... before
    for resp, err := range c.ListKeys(ctx, req).All() {
        if err != nil {
            fmt.Printf("list keys error: %s\n", err.Error())
            os.Exit(1)
        }
        // TODO: Use resp.
        _ = resp
    }
// ... after
    for k, err := range c.ListKeys(ctx, req).All() {
        if err != nil {
            fmt.Printf("list keys error: %s\n", err.Error())
            os.Exit(1)
        }
        fmt.Println(k.DisplayName)
    }
```

## Validación

Sólo nos queda compilar y validar que todo funciona. Como estamos usando las *librerías* del SDK, éste se encarga de obtener las credenciales, por ejemplo, de ejecutar `gcloud auth login --update-adc`.

Antes de ejecutar la aplicación, establecemos el `projectId` como variable de entorno; el resultado es:

```console
$ ./apikeycheck
test-api-key
```
