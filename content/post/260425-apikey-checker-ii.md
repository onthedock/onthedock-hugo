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

title=  "API Keys rotation checker - II"
date = "2026-04-25T20:50:19+02:00"
+++
En esta segunda entrada, el foco va a ser usar el paquete [`flag`](https://pkg.go.dev/flag) para que el usuario pueda proporcionar, por ejemplo, el `projectId` donde listar las API keys.
<!--more-->
## Paquete `flag`: sencillo y funcional

En el apartado anterior el parámetro `projectId`, necesario para indicar en qué proyecto queremos listar las API keys, se obtenía desde una variable de entorno.
Sin embargo, queremos que el usuario puede especificar el valor del proyecto desde la línea de comando, por ejemplo, mediante `--project <projec-id>`.

Empezamos definiendo un nuevo *flagSet*, al que llamamos `apikeycheck`.

```go
// ... before
func main() {
    ctx := context.Background()
    c, err := apikeys.NewClient(ctx)
    if err != nil {
    // ...
// ... after
func main() {
    fs := flag.NewFlagSet("apikeycheck", flag.ExitOnError)
    projectId := fs.String("project", "", "Check API keys in the project identified by ProjectId")
    if err := fs.Parse(os.Args[1:]); err != nil {
        fmt.Printf("error parsing flags: %s\n", err.Error())
        os.Exit(1)
    }

    ctx := context.Background()
```

De esta forma, el usuario puede proporcionar el *projectId* a través de la línea de comando mediante `--project <projectid>`.
Lo único importante a tener en cuenta es que `projectId` es `*string`, no `string`.
Por tanto, en la `ListKeysRequest`:

```go
// ... before
    req := &apikeyspb.ListKeysRequest{
        // See https://pkg.go.dev/cloud.google.com/go/apikeys/apiv2/apikeyspb#ListKeysRequest.
        Parent: fmt.Sprintf("projects/%s/locations/global", os.Getenv("PROJECTID"),
    }
// ... after
    req := &apikeyspb.ListKeysRequest{
        // See https://pkg.go.dev/cloud.google.com/go/apikeys/apiv2/apikeyspb#ListKeysRequest.
        Parent: fmt.Sprintf("projects/%s/locations/global", *projectId),
    }
```

### Validar que el `projectId` no está vacío

El paquete `flag` genera un error si se especifica un *flag* y no se le asigna un valor, como `--project <nothing>`, pero el valor `""` es perfectamente válido: `--project ""`.
Pero si no especificamos el valor del `projectId`, la llamada a la API de las API keys fallará.

Además, como no hay ninguna forma de indicar que un *flag* es requerido, tenemos que encargarnos nosotros de realizar esas validaciones en nuestra aplicación por si el usuario no incluye `--project`.

La solución es validar que el valor de `projectId` **no está vacío**.

```go
//  ... before
        fmt.Printf("error parsing flags: %s\n", err.Error())
        os.Exit(1)
    }

    ctx := context.Background()
//  ... after
        fmt.Printf("error parsing flags: %s\n", err.Error())
        os.Exit(1)
    }

    if *projectId == "" {
        fmt.Println("projectId cannot be empty")
        os.Exit(1)
    }

    ctx := context.Background()
```

De esta forma, si el usuario no proporciona un valor para `--project`:

```console
$ ./apikeycheck
projectId cannot be empty
```

## Ayuda incorporada

Una de las ventajas de usar el paquete `flag` es que la información que proporcionamos al definir los parámetros se muestra al usuario en forma de *ayuda*:

```console
$ ./apikeycheck --help
Usage of apikeycheck:
  -project string
      Check API keys in the project identified by ProjectId
```

## Periodo de rotación

El periodo recomendado de rotación de las API keys es de 90 días. Pero puede que el criterio para tu organización sea diferente; usando el paquete `flag` añadimos una nueva *flag* para que el usuario especifique su propio valor, en días, si así lo desea. Si no, la aplicación usará el valor de 90 por defecto.

Añadimos una nueva línea tras la declaración de `projectId`:

```go
//  ... before
    fs := flag.NewFlagSet("apikeycheck", flag.ExitOnError)
    projectId := fs.String("project", "", "Check API keys in the project identified by ProjectId")
    if err := fs.Parse(os.Args[1:]); err != nil {
        // ...
//  ... after
    fs := flag.NewFlagSet("apikeycheck", flag.ExitOnError)
    projectId := fs.String("project", "", "Check API keys in the project identified by ProjectId")
    maxDays := fs.Int("max-days", 90, "Max. number of days before API keys should be rotated")
    if err := fs.Parse(os.Args[1:]); err != nil {
        // ...
```

Como hemos definido `maxDays` pero no lo usamos, el *linter* se queja; para evitarlo, asignamos *temporalmente* `maxDays` al *blank identifier*:

```go
// ... temporary fix
    if err := fs.Parse(os.Args[1:]); err != nil {
        fmt.Printf("error parsing flags: %s\n", err.Error())
        os.Exit(1)
    }
    _ = maxDays
```

En la siguiente entrada, pondremos el foco en explorar las propiedades de las API keys para identificar cuáles nos pueden interesar para identificar las que deben ser rotadas.
