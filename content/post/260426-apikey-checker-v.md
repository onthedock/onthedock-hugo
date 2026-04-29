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
# Imagenes          {{< figure src="/images/260426/process.png" width="100%" >}}

title=  "API Keys rotation checker - V"
date = "2026-04-26T21:37:28+02:00"
+++
En esta entrada voy a mostrar cómo, gracias a una buena organización del código previa, podemos añadir nuevas maneras de mostrar las API keys sin tener que realizar modificaciones importantes.
<!--more-->
## Convertir a otros formatos

Mostrar la información por pantalla suele ser la opción por defecto... Pero quizás queremos obtener la información acerca de la API key de forma estructurada en JSON...

Añadiremos un nuevo *flag* `--format` mediante el cual se pueda especificar el formato de salida de las API keys.

> En algunos ejemplos puedes ver referencias a un *flag* llamado `redact` que se introduce más adelante en esta misma entrada.

```go
// ... before
    maxDays := fs.Int("max-days", 90, "Max. number of days before API keys should be rotated")
    redact := fs.Bool("redact", false, "Obfuscate information when displaying the Key")
    if err := fs.Parse(os.Args[1:]); err != nil {
        // ...
// ... after
    maxDays := fs.Int("max-days", 90, "Max. number of days before API keys should be rotated")
    redact := fs.Bool("redact", false, "Obfuscate information when displaying the Key")
    format := fs.String("format", "", "Output format for displaying the API keys")
    if err := fs.Parse(os.Args[1:]); err != nil {
        // ...
```

En función del valor de `format`, en vez de mostrar una *lista* de API keys por pantalla, mostraremos las API keys en el formato especificado.

Empezamos con JSON.

### Refactor

Cuando definimos el *struct* para representar una API key, añadimos una serie de *etiquetas* `json:"..."`:

```go
type Key struct {
    CreateTime  time.Time `json:"create_time,omitempty"`
    DisplayName string    `json:"display_name,omitempty"`
    Name        string    `json:"name,omitempty"`
    ProjectId   string    `json:"project_id,omitempty"`
}
```

Estas etiquetas las usa el paquete `encoding/json` para determinar el nombre de las claves en el JSON generado, entre otras cosas.

Siguiendo con la idea de que `Display` se encargue de mostrar las API keys por pantalla, lo que vamos a hacer es añadir un `switch`. Así, en función del *formato* especificado, se mostrará la información de las API keys de una forma u otra.

Añdimos `Format` a las `Options`.

```go
// ... before
    options := keys.Options{
        MaxDays: *maxDays,
        Redact:  *redact,
    }
// ...after
    options := keys.Options{
        MaxDays: *maxDays,
        Redact:  *redact,
        Format:  strings.ToLower(*format),
    }
```

También tenemos que añadirlo a la definición del *struct*:

```go
// ... before
type Options struct {
    MaxDays int
    Redact  bool
}
// ... after
type Options struct {
    MaxDays int
    Redact  bool
    Format  string
}
```

Y ahora, en `Display`:

```go
// ... before
func Display(keylist []*Key, options Options) {
    const (
        warningIcon string = "⚠️"
        okIcon      string = "✅"
    )
    icon := okIcon
    for _, k := range keylist {
        if k.NeedsToBeRotated(options) {
            icon = warningIcon
        }
        // Redact as many fields as we want from the API Key
        if options.Redact {
            k.ProjectId = redact(k.ProjectId, "[a-zA-Z]", "░")
        }
        fmt.Println(icon, k.String())
    }
}
// ... after
func Display(keylist []*Key, options Options) {
    const (
        warningIcon string = "⚠️"
        okIcon      string = "✅"
    )
    switch options.Format {
    default:
        icon := okIcon
        for _, k := range keylist {
            if k.NeedsToBeRotated(options) {
                icon = warningIcon
            }
            // Redact as many fields as we want from the API Key
            if options.Redact {
                k.ProjectId = redact(k.ProjectId, "[a-zA-Z]", "░")
            }
            fmt.Println(icon, k.String())
        }
    }
}
```

De momento, no ha cambiado nada; tanto si no se especifica un formato como si el formato especificado es desconocido, las API keys se muestran como las hemos mostrado por pantalla hasta ahora.

Sin embargo, ahora podemos introducir otros *formatos*.

### Convertir a JSON

Lo único que tenemos que hacer es añadir un *case*:

```go
// ... before
    switch options.Format {
    default:
    // ...
// ... after
    switch options.Format {
    case "json":
        buf := new(bytes.Buffer)
        if err := json.NewEncoder(buf).Encode(&keylist); err != nil {
            log.Println("json encoding", err.Error())
            os.Exit(1)
        }
        fmt.Println(buf.String())
    default:
    // ...
```

Tras compilar, comprobamos que la salida del comando es en formato JSON:

```console
$ ./apikeycheck --project XXXX-XXXXX-XXXXXX-XXX-XXX --format json | jq
[
  {
    "create_time": "2026-04-18T11:05:17.574173Z",
    "display_name": "test-api-key",
    "name": "projects/XXXXXXXXXXXX/locations/global/keys/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXX",
    "project_id": "XXXX-XXXXX-XXXXXX-XXX-XXX"
  }
]
```

### Convertir a CSV

Empezamos añadiendo un nuevo método `ToCSV()`:

```go
func (k Key) ToCSV(options Options) []string {
    return []string{k.DisplayName, k.Name, k.CreateTime.Format(time.RFC1123), k.ProjectId}
}
```

En el `switch` de la función `Display`, añadimos un nuevo *case*.

```go
    case "csv":
        output := os.Stdout
        w := csv.NewWriter(output)
        for _, k := range keylist {
            w.Write(k.ToCSV(options))
        }
        w.Flush()
```

Tras compilar, ahora también podemos obtener el listado de API keys en formato CSV:

```console
$ ./apikeycheck --project XXXX-XXXXX-XXXXXX-XXX-XXX --format csv
test-api-key,"projects/XXXXXXXXXXXX/locations/global/keys/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXX","Sat, 18 Apr 2026 11:05:17 UTC", XXXX-XXXXX-XXXXXX-XXX-XXX
```

## Ocultar información sensible

Como has visto en los entradas anteriores, tengo la costumbre de *redactar* (aunque en castellano, probablmente es más correcto decir *censurar*) información potencialmente sensible como el nombre del proyecto utilizado para probar la aplicación.

Vamos a añadir esta funcionalidad a la aplicación a través de un *flag* opcional llamado `redact`.

En `main.go`, añadimos el nuevo *flag*:

```go
// ... before
func main() {
    fs := flag.NewFlagSet("apikeycheck", flag.ExitOnError)
    projectId := fs.String("project", "", "Check API keys in the project identified by ProjectId")
    maxDays := fs.Int("max-days", 90, "Max. number of days before API keys should be rotated")
    if err := fs.Parse(os.Args[1:]); err != nil {
        // ...
// ... after
func main() {
    fs := flag.NewFlagSet("apikeycheck", flag.ExitOnError)
    projectId := fs.String("project", "", "Check API keys in the project identified by ProjectId")
    maxDays := fs.Int("max-days", 90, "Max. number of days before API keys should be rotated")
    redact := fs.Bool("redact", false, "Obfuscate information when displaying the Key")
    if err := fs.Parse(os.Args[1:]); err != nil {
        // ...
```

Añadimos el nuevo *flag* a `Options`:

```go
// ... before
    options := keys.Options{
        MaxDays: *maxDays,
    }
// ... after
    options := keys.Options{
        MaxDays: *maxDays,
        Redact: *redact,
    }
```

El campo no está definido en `Options`, así que actualizamos `keys.go`:

```go
// ... before
type Options struct {
    MaxDays int
}
// ... after
type Options struct {
    MaxDays int
    Redact  bool
}
```

Ahora ya podemos usar el valor en `options.Redact` para decidir si *ofuscar* o no la salida de `Display`.

Añadimos una nueva función privada en `keys.go`:

```go
func redact(s string, restr string, mask string) string {
    re, err := regexp.Compile(restr)
    if err != nil {
        log.Println("redact", err.Error())
    }
    return re.ReplaceAllString(s, mask)
}
```

Esta función usa una cadena, que se interpreta como una expresión regular, para reemplazar todas las coincidencias con el patrón con el valor de *mask*.

Ahora, en la función `Display`:

```go
    for _, k := range keylist {
        if k.NeedsToBeRotated(options) {
            icon = warningIcon
        }
        // Redact as many fields as we want from the API Key
        if options.Redact {
            k.ProjectId = redact(k.ProjectId, "[a-zA-Z]", "░")
        }
        fmt.Println(icon, k.String())
    }
```

Como vemos, hemos elegido *redactar* el ProjectId, pero podríamos seleccionar cualquier campo de la API key:

```console
./apikeycheck --project XXXX-XXX-XXXX-XXXXX-XXXX --redact
✅ test-api-key on project ░░░░-░░░-░░░░-░░░░░░-░░░░ (created: Sat, 18 Apr 2026 11:05:17 UTC, 10 days ago)
```

> Esta opción es sólo un ejemplo de cómo podemos modificar la forma en la que se muestra la información de las API keys aplicando algún tipo de transformación a cualquiera de los campos de la API key; no es quizás una función muy útil ;)
