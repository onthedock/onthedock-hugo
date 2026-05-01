+++
draft = true

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["google-cloud", "apikey", "go"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/go.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/
# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/260426/process.png" width="100%" >}}

title=  "API Keys rotation checker - VI"
date = "2026-04-29T19:00:14+02:00"
+++
Hasta ahora hemos estado examinando las API keys en un solo proyecto. Ahora vamos a obtener la lista de proyectos a los que el usuario tiene acceso, para poder examinar API keys en todos ellos.
<!--more-->
Si examinamos la API para Resource Manager, vemos que tenemos un método para *listar* proyectos y otro para *buscar* proyectos. Pese a que la intuición indicaría lo contrario, como podemos ver en la documentación para la [ListProjectsRequest](https://pkg.go.dev/cloud.google.com/go/resourcemanager/apiv3/resourcemanagerpb#ListProjectsRequest), sólo se devuelven proyectos que son *descendientes directos* del recurso indicado, que puede ser un *folder* o una *organization*.

Sin embargo, en la documentación de [SearchProjectsRequest](https://pkg.go.dev/cloud.google.com/go/resourcemanager/apiv3/resourcemanagerpb#SearchProjectsRequest), esta petición obtiene la lista de todos los proyectos a los que el usuario tiene acceso, que es lo que queremos. La *request* acepta un parámetro con el que *filtrar* los proyectos resultantes, pero en una primera iteración, dejamos la *query* vacía.

## Paquete `projects`

Para mantener el código organizado, vamos a colocar todas las funciones relativas a obtención de la lista de proyectos en un *package* separado llamado `projects`.

Creamos el fichero `internal/projects/projects.go` y usamos el código de ejemplo para el método `SearchProjects` del [`ProjectsClient`](https://docs.cloud.google.com/go/docs/reference/cloud.google.com/go/resourcemanager/latest/apiv3#cloud_google_com_go_resourcemanager_apiv3_ProjectsClient_SearchProjects):

> Como en el caso de las API keys, vamos a obtener todos los proyectos a los que el usuario tiene acceso de una sola vez.

```go
func Search() {
    ctx := context.Background()
    //   https://pkg.go.dev/cloud.google.com/go#hdr-Client_Options
    c, err := resourcemanager.NewProjectsClient(ctx)
    if err != nil {
        fmt.Println("resourcemanager client", err.Error())
        os.Exit(1)
    }
    defer c.Close()

    req := &resourcemanagerpb.SearchProjectsRequest{
        // See https://pkg.go.dev/cloud.google.com/go/resourcemanager/apiv3/resourcemanagerpb#SearchProjectsRequest.
        // Leaving empty for now
    }
    for project, err := range c.SearchProjects(ctx, req).All() {
        if err != nil {
            fmt.Println("resource manager search project:", err.Error())
            os.Exit(1)
        }
        fmt.Println(project.Name)
    }
}
```

Se deberían añadir a los *import* los siguientes paquetes; ejecuta `go mod tidy` para que se descarguen localmente:

```go
    resourcemanager "cloud.google.com/go/resourcemanager/apiv3"
    "cloud.google.com/go/resourcemanager/apiv3/resourcemanagerpb"
```

## Si se proporciona un *projectId*, usarlo; sino, buscar API keys en todos

Actualmente, validamos que el `projectId` no esté vacío, ya que lo necesitamos para poder buscar API keys en un proyecto.

Ahora, no será necesario, ya que si no se especifica un `projectId`, buscaremos en todos aquellos proyectos en los que el usuario tenga acceso.

Eliminamos en `main.go`:

```go
// ... before
    if *projectId == "" {
        fmt.Println("projectId cannot be empty")
        os.Exit(1)
    }

    projectIds := []string{*projectId}
// ... after
    projectIds := []string{*projectId}
```

Y ahora:

```go
// ... before
    projectIds := []string{*projectId}
// ... after
    var projectList []string
    if *projectId != "" {
        projectList = []string{*projectId}
    }
    projectList = projects.Search()
```

También tenemos que reemplazar `projectIds` por `projectList` en:

```go
// ... before
    for _, p := range projectIds {
        kk := keys.List(p)
        keylist = append(keylist, kk...)
    }
// ... after
    for _, p := range projectList {
        kk := keys.List(p)
        keylist = append(keylist, kk...)
    }
```

El problema que tenemos es que en la *signatura* de `Search()`, ésta no devuelve nada.

Vamos a corregirlo; de nuevo en `intenal/projects/projects.go`:

```go
// ... before
func Search() {
    // ...
// ... after
func Search() []string {
    // ...
```

Antes de realizar la petición `SearchProjects`, definimos una variable `projectList`, donde acumularemos todos los *projectId* devueltos:

```go
// ... before
        // ...
    for project, err := range c.SearchProjects(ctx, req).All() {
        if err != nil {
            fmt.Println("resource manager search project:", err.Error())
            os.Exit(1)
        }
        fmt.Println(project.Name)
    }
    return projectLIst
}
// ... after
    var projectLIst []string
    for project, err := range c.SearchProjects(ctx, req).All() {
        if err != nil {
            fmt.Println("resource manager search project:", err.Error())
            os.Exit(1)
        }
        projectLIst = append(projectLIst, project.ProjectId)
    }
    return projectLIst
```

## Feedback

En función de los permisos que tenga el usuario, es posible que la lista de proyectos sea extensa. La aplicación los irá comprobando uno a uno en busca de API keys, pero si no se encuentran API keys en los proyectos, no se muestra nada por pantalla y el usuario no sabe qué está pasando.

Imprimiremos un mensaje por pantalla indicando el proyecto en el que se están comprobando las API keys. Para evitar *contaminar* la salida de la aplicación, imprimiremos estos mensajes en `stderr`, no en `stdout`.

```go
// ... before
    for _, p := range projectList {
        kk := keys.List(p)
        keylist = append(keylist, kk...)
    }
// ... after
    for _, p := range projectList {
        fmt.Fprintf(os.Stderr, "🕵️‍♂️ checking API keys on project %s ...", p)
        kk := keys.List(p)
        if len(kk) == 0 {
            fmt.Fprintf(os.Stderr, " found 0.\n")
        } else {
            fmt.Fprintf(os.Stderr, " found %d 🔑.\n", len(kk))
        }

        keylist = append(keylist, kk...)
    }
```

De esta forma, el usuario tiene *feedback* de qué es lo que está haciendo la aplicación en todo momento:

```console
./apikeycheck
🕵️‍♂️ checking API keys on project XX-XXX-XXXXXXX-XXXXXXXXXX-XXX ... found 0.
🕵️‍♂️ checking API keys on project XX-XXX-XXXXXXXX-XXXXXXXXX-X ... found 0.
🕵️‍♂️ checking API keys on project XX-XXX-XXXXXXXX-XXXXXX-X-XXX ... found 0.
🕵️‍♂️ checking API keys on project XX-XXX-XXXXXXXX-XXXX-XXX ... found 0.
🕵️‍♂️ checking API keys on project XXXX-XXX-XXXX-XXXXXX-XXXX ... found 1 🔑.
🕵️‍♂️ checking API keys on project XXXX-XXXXX-XXXXXXXXX-X-XXXX ... found 0.
🕵️‍♂️ checking API keys on project XX-XXX-XXXXXXXX-XX-XXX ... found 0.
🕵️‍♂️ checking API keys on project XX-XXX-XXXXXXXX-XXXX-XX-XXX ... found 0.
...
```

## Ignorando errores

Si en alguno de los proyectos la API de API Keys no está habilitada, la aplicación se para.
Esto es un *efecto colateral* de usar `.All()`, según se indica en el comentario del ejemplo:

> // TODO: Handle error and break/return/continue. Iteration will stop after any error.

Aunque la iteración se pare (punto a mejorar), queremos, como mínimo, explorar las API keys que se hayan encontrado hasta el momento.

Así que sustituimos el `os.Exit(1)` por un `continue` en `internal/keys/keys.go`:

```go
// ... before
    for k, err := range c.ListKeys(ctx, req).All() {
        if err != nil {
            // TODO: Handle error and break/return/continue. Iteration will stop after any error.
            fmt.Printf("list keys error: %s\n", err.Error())
            os.Exit(1)
        }
// ... after
    for k, err := range c.ListKeys(ctx, req).All() {
        if err != nil {
            // TODO: Handle error and break/return/continue. Iteration will stop after any error.
            fmt.Printf("list keys error: %s\n", err.Error())
            continue
        }
```

## Más *feedback*

Además de indicar en qué proyecto está comprobando si existen API keys, podemos indicar si las hay.

Para ello, podemos añadir:

```go
// ... before
    for _, p := range projectList {
        fmt.Fprintf(os.Stderr, "🕵️‍♂️ checking API keys on project %s ...\n",  p)
        kk := keys.List(p)
        keylist = append(keylist, kk...)
    }
// ... after
    for _, p := range projectList {
        fmt.Fprintf(os.Stderr, "🕵️‍♂️ checking API keys on project %s ...", p)
        kk := keys.List(p)
        if len(kk) == 0 {
            fmt.Fprintf(os.Stderr, " found 0.\n")
        } else {
            fmt.Fprintf(os.Stderr, " found %d 🔑.\n", len(kk))
        }

        keylist = append(keylist, kk...)
    }
```
