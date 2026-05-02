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

title= "API Keys rotation checker - VII"
date = "2026-05-01T07:05:41+02:00"
+++
En la solución original de Google Professional Services, API Key Rotation Checker mostraba las API keys que deben rotarse y las que no en dos grupos diferentes.

Al mostrar por pantalla los resultados, ya incluimos un icono para diferenciar las API keys. Ahora vamos a introducir un *flag* para filtrar las API keys encontradas, no sólo cuando las mostramos por pantalla, sino también cuando las exportamos a cualquiera de los formatos soportados.
<!--more-->

Por defecto, se deben mostrar todas las API keys. Sin embargo, vemos que si se muestran por pantalla, podemos distinguir aquellas que deben rotarse de las que no, pero ésto no sucede si exportamos a JSON o CSV.

Empezamos añadiendo dos campos al *struct* que modela la `Key`:

```go
// ... before
type Key struct {
    CreateTime  time.Time `json:"create_time,omitempty"`
    DisplayName string    `json:"display_name,omitempty"`
    Name        string    `json:"name,omitempty"`
    ProjectId   string    `json:"project_id,omitempty"`
}
// ... after
type Key struct {
    CreateTime  time.Time `json:"create_time,omitempty"`
    DisplayName string    `json:"display_name,omitempty"`
    Name        string    `json:"name,omitempty"`
    ProjectId   string    `json:"project_id,omitempty"`
    AgeDays     int       `json:"age_days,omitempty"`
    Rotate      bool      `json:"rotate,omitempty"`
}
```

En la función `List`, cuando obtenemos la información de la *Key*, añadimos el valor de `AgeDays` usando la función que desarrollamos anteriormente `daysSinceCreated()`:

```go
// ... before
    key := &Key{
        Name:        k.Name,
        DisplayName: k.DisplayName,
        CreateTime:  k.CreateTime.AsTime(),
        ProjectId:   projectid,
    }
// ... after
    key := &Key{
        Name:        k.Name,
        DisplayName: k.DisplayName,
        CreateTime:  k.CreateTime.AsTime(),
        ProjectId:   projectid,
        AgeDays:     daysSinceCreated(k.CreateTime.AsTime()),
    }
```

## Nuevo *flag* `--rotate`

Si especificamos el *flag* `--rotate`, entonces sólo se mostrarán las API keys cuya antigüedad sea mayor que `--max-days`.

```go
// ... before
    format := fs.String("format", "", "Output format for displaying the API keys")
    if err := fs.Parse(os.Args[1:]); err != nil {
        // ...
// ... after
    format := fs.String("format", "", "Output format for displaying the API keys")
    rotate := fs.Bool("rotate", false, "Display only API keys older than 'max-days'")
    if err := fs.Parse(os.Args[1:]); err != nil {
        // ...
```

Añadimos el valor a `options` y el campo en la definición del *struct* `Options`:

```go
// ... before
    options := keys.Options{
        MaxDays: *maxDays,
        Redact:  *redact,
        Format:  strings.ToLower(*format),
    }
// ... after
    options := keys.Options{
        MaxDays: *maxDays,
        Redact:  *redact,
        Format:  strings.ToLower(*format),
        Rotate: *rotate,
    }
```

```go
// ... before
type Options struct {
    MaxDays int
    Redact  bool
    Format  string
}
// ... after
type Options struct {
    MaxDays int
    Redact  bool
    Format  string
    Rotate  bool
}
```

## Filtrando las API keys

Creamos una función llamada `Filter` en `internal/keys/keys.go`; la idea es que si se especifica el *flag*, sólo se deben mostrar las API keys que deben rotarse.
Por tanto, `Filter` recibe un *slice* de `Key`, los *flags* (en format de `Options`) y devuelve un *subconjunto* de `Key` en forma de *slice*.

Si no se especifica `--rotate`, significa que debemos mostrar todas las API keys; es decir, no tenemos que filtrar nada:

```go
func Filter(keylist []*Key, options Options) []*Key {
    if !options.Rotate {
        // nothing to filter
        return keylist
    }
// ...
```

Si tenemos que filtrar, entonces:

```go
// ... before
func Filter(keylist []*Key, options Options) []*Key {
    if !options.Rotate {
        // nothing to filter
        return keylist
    }
    // ... TODO
}
// ... after
func Filter(keylist []*Key, options Options) []*Key {
    if !options.Rotate {
        // nothing to filter
        return keylist
    }
    filteredKeys := []*Key{}
    for _, k := range keylist {
        if k.NeedsToBeRotated(options) {
            k.Rotate = true
            filteredKeys = append(filteredKeys, k)
        }
    }
    return filteredKeys
}
```

## Actualizando `Display`

Como, cuando filtramos las API keys añadimos la información de si deben rotarse o no, no es necesario volver a calcular si la API key tiene que rotarse o no para mostrar un icono u otro (por pantalla)

```go
// ... before
    for _, k := range keylist {
        if k.NeedsToBeRotated(options) {
            icon = warningIcon
        }
// ... after
    for _, k := range keylist {
        if k.Rotate {
            icon = warningIcon
        }
```

Finalmente, tenemos que *insertar* la función `Filter` entre la obtención de las API keys y que se muestran por pantalla (o exporten a JSON/CSV).

```go
// ... before
    // ...
    // display API keys
    keys.Display(keylist, options)
}
// ... after
    // filter API keys
    keylist = keys.Filter(keylist, options)
    // display API keys
    keys.Display(keylist, options)
}
```

Si queremos mostrar los dos nuevos campos que hemos introducido para la `Key`, debemos añadirlos a la función `ToCSV()`:

```go
// ... before
func (k Key) ToCSV(options Options) []string {
    return []string{k.DisplayName, k.Name, k.CreateTime.Format(time.RFC1123), k.ProjectId}
}
// ... after
func (k Key) ToCSV(options Options) []string {
    return []string{k.DisplayName, k.Name, k.CreateTime.Format(time.RFC1123), k.ProjectId, strconv.Itoa(k.AgeDays), strconv.FormatBool(k.Rotate)}
}
```

## Resultado final

Inspirado por el repositorio original, la aplicación comprueba las API keys para revisar si son más antiguas que el máximo de días que recomienda Google antes de rotarlas (90 días). Por defecto, la aplicación busca las API keys en todos los proyectos a los que el usuario tiene acceso, mostrando la lista de claves que encuentra en cada proyecto e identificando las API keys encontradas con un icono (en función de si superan el periodo máximo recomendado para rotas las API keys).

El usuario puede usar el *flag* `--rotate` para que la aplicación muestre únicamente las API keys que superan la antigüedad máxima definida por defecto para las API keys. El usuario también puede especificar un periodo máximo diferente a través del *flag* `--max-days`.

Además de mostrar las API keys encontradas por pantalla, ésta versión de la aplicación permite formatear la salida en JSON o en CSV.

## Serie completa

* [API keys rotation checker - I](({{< ref "post/260425-apikey-checker-i.md" >}}))
* [API keys rotation checker - II](({{< ref "post/260425-apikey-checker-ii.md" >}}))
* [API keys rotation checker - III](({{< ref "post/260426-apikey-checker-iii.md" >}}))
* [API keys rotation checker - IV](({{< ref "post/260426-apikey-checker-iv.md" >}}))
* [API keys rotation checker - V](({{< ref "post/260426-apikey-checker-v.md" >}}))
* [API keys rotation checker - VI](({{< ref "post/260429-apikey-checker-vi.md" >}}))
* [API keys rotation checker - VII](({{< ref "post/260501-apikey-checker-vii.md" >}}))
