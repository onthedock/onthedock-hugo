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

title=  "API Keys rotation checker - IV"
date = "2026-04-26T18:42:00+02:00"
+++
Ahora que somos capaces de mostrar cuántos dias hace que se creó una API key, ha llegado el momento de comparar ése dato con el periodo de rotación y así indicar si la API key debe ser rotada o no.
<!--more-->
Hasta ahora, la parte final del proceso, la de "mostrar" las API keys en el proyecto se ha limitado a un `Println`.

```go
    // display API keys
    for _, k := range keylist {
        fmt.Println(k.String())
    }
```

En la línea de lo que hemos hecho para cada una de las fases anteriores del proceso, vamos *extraer* la acción de *mostrar* la API key a una función en el paquete `keys`.

Creamos una función `Display` en `keys.go` con el mismo contenido que tenemos en el *snippet* de código anterior:

```go
func Display(keylist []*Key) {
    for _, k := range keylist {
        fmt.Println(k.String())
    }
}
```

En `main.go`, reemplazamos el código existente por la llamada a esta nueva función:

```go
// ... before
    // display API keys
    for _, k := range keylist {
        fmt.Println(k.String())
    }
// ... after
    // display API keys
    keys.Display(keylist)
```

Esta modificación es sólo un *refactor* que no altera la funcionalidad existente, pero nos permite organizar mejor el código.

## Mostrar qué claves deben ser rotadas y cuáles no

La solución original de Google Professional Services mostraba las API keys en dos grupos: las que tenían que rotarse y las que no.

Para que la función `Display` diferencie la forma en la que muestra las API keys que deben rotarse de las que no, debe poder identificarlas. Para ello, debemos pasar el valor de `maxDays` a `Display`, e introducir la lógica necesaria para que se compruebe si la API key debe rotarse o no.

Una forma posible es añadir `maxDays` a la lista de parámetros de `Display`:

```go
func Display(keylist []*Key, maxdays int) { ... }
```

Sin embargo, también nos gustaría pasar un parámetro para especificar el formato en el que mostrar las API keys en el futuro...

```go
func Display(keylist []*Key, maxdays int, format string) { ... }
```

Como vemos, para cada nuevo parámetro que querramos introducir en el futuro, modificaríamos la *signatura* de la función... Eso significa que deberíamos actualizar también todas las referencias a la función `Display` en nuestro código... Siendo ésta una aplicación sencilla, no sería mayor problema; pero en una aplicación más compleja, éste tipo de cambios no son nada recomendables.

Personalmente, prefiero usar un *struct* de *opciones*.

En `keys.go`, añadimos:

```go
type Options struct {
    MaxDays int
}
```

En `main.go`, reemplazamos:

```go
// ... before
        fmt.Printf("error parsing flags: %s\n", err.Error())
        os.Exit(1)
    }
    _ = maxDays
// ... after
        fmt.Printf("error parsing flags: %s\n", err.Error())
        os.Exit(1)
    }

    options := keys.Options{
        MaxDays: *maxDays,
    }
```

Actualizamos la llamada a `Display` (aunque todavía no hemos actualizado su *signature*):

```go
// ... before
    // display API keys
    keys.Display(keylist)
// ... after
    // display API keys
    keys.Display(keylist, options)
```

Finalmente, en `keys.go`, actualizamos la función `Display`:

```go
// ... before
func Display(keylist []*Key) {
// ... after
func Display(keylist []*Key, options Options) {
```

Tenemos `options` disponible en `Display`, aunque todavía no lo estamos utilizando para nada.

Para saber si una API key tiene que ser rotada, debemos comparar cuánto tiempo hace desde que se creó con el valor de `maxDays`. Al tratarse de una operación central en la aplicación, vamos a crear un método `NeedsToBeRotated` que devuelva `true` o `false`.

Para facilitar el cálculo, añadimos una función privada en `keys.go`:

```go
func daysSinceCreated(c time.Time) int {
    const hoursDay = 24
    return int(time.Since(c).Hours() / hoursDay)
}
```

En `keys.go` añadimos:

```go
func (k Key) NeedsToBeRotated(options Options) bool {
    if daysSinceCreated(k.CreateTime) <= options.MaxDays {
        return false
    }
    return true
}
```

La creación de la función `daysSinceCreated` también nos permite actualizar `String()`:

```go
// ... before
func (k Key) String() string {
    const hoursDay = 24
    return fmt.Sprintf("%s on project %s (created: %s, %.0f days ago)", k.DisplayName, k.ProjectId, k.CreateTime.Format(time.RFC1123), time.Since(k.CreateTime).Hours()/hoursDay)
}
// ... after
func (k Key) String() string {
    return fmt.Sprintf("%s on project %s (created: %s, %d days ago)", k.DisplayName, k.ProjectId, k.CreateTime.Format(time.RFC1123), daysSinceCreated(k.CreateTime))
}
```

Volvemos ahora a la función `Display`; en vez de imprimir, en forma de *string* la API key, prefijamos la salida de la función con un icono dependiendo de si la API key supera o no el periodo máximo de rotación establecido en nuestra organización:

```go
// ... before
func Display(keylist []*Key, options Options) {
    for _, k := range keylist {
        fmt.Println(k.String())
    }
}
// ... after

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
        fmt.Println(icon, k.String())
    }
}
```

El resultado es:

```console
$  ./apicheck --project XXXX-XXX-XXXX-XXXXXX-XXXX
✅ test-api-key on project XXXX-XXX-XXXX-XXXXXX-XXXX (created: Sat, 18 Apr 2026 11:05:17 UTC, 8 days ago)

$ ./apicheck --project XXXX-XXX-XXXX-XXXXXX-XXXX --max-days 7
⚠️ test-api-key on project XXXX-XXX-XXXX-XXXXXX-XXXX (created: Sat, 18 Apr 2026 11:05:17 UTC, 8 days ago)
```
