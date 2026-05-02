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

title=  "API Keys rotation checker - III"
date = "2026-04-26T06:57:57+02:00"
+++
En esta entrada vamos a explorar qué propiedades tienen las API keys y cuáles pueden interesarnos para identificar las claves que deben ser rotadas.
<!--more-->
Está claro que para idenitificar si una API key fue creada hace más de X días, la propiedad que nos interesa es [`CreateTime`](https://pkg.go.dev/cloud.google.com/go/apikeys/apiv2/apikeyspb#Key):

```console
// Output only. A timestamp identifying the time this key was originally created.  
CreateTime *timestamppb.Timestamp `protobuf:"bytes,4,opt,name=create_time,json=createTime,proto3" json:"create_time,omitempty"`
```

Pero para que el usuario pueda identificar de qué clave se trata, tendremos que obtener también, por ejemplo, su *DisplayName*.
El problema es que el *DisplayName* puede cambiarse y no identifica unívocamente a la API key, por lo que también necesitaremos su *Name* (de la forma `projects/123456867718/locations/global/keys/b7ff1f9f-8275-410a-94dd-3855ee9b5dd2`).

Para *agrupar* todos estos valores, definiremos un *struct* `Key`.

Siguiendo buenas prácticas, todo lo relacionado con las *keys* lo vamos a organizar en el paquete `keys` (así evitamos conflictos con el nombre `apikeys`, usado por Google). Creamos la subcarpeta `internal/keys` y el fichero `keys.go`:

```go
package keys

import "time"

type Key struct {
    CreateTime  time.Time `json:"create_time,omitempty"`
    DisplayName string    `json:"display_name,omitempty"`
    Name        string    `json:"name,omitempty"`
    ProjectId   string    `json:"project_id,omitempty"`
}
```

## Plan

En la aplicación de Google Professional Services, las API keys se muestran en dos grupos: las que necesitan rotarse y las que no.

Mi idea es recoger toda la información relativa a las API keys en un *slice* y proporcionar al usuario herramientas para mostrarlas de la manera que mejor le convenga; por ejemplo, mostrar sólo las N keys más antiguas, etc... También quiero proporcionar la opción de guardar los resultados en formatos como JSON o CSV...

Con esa idea en mente, la salida "por defecto" de la aplicación sería algo como:

```console
$ ./apikeycheck [flags ...]
⚠️ apikey (project-9) 2025-11-01 (93 days old)
✅ test-api-001 (project-1) 2026-02-03 (45 days old)
✅ api-001 (project-2) 2026-04-23 (3 days old)
...
```

Usando `--format json`, la salida del comando sería en formato JSON, etc...

## Guardar todas las API keys de un proyecto

Si examinamos `main.go`, vemos que, si `ListKeys.All()` no devuelve un error, recorremos todas las API keys devueltas, mostrando el *display name* de la API key antes de seguir con la siguiente...

Si queremos filtrar las API keys, o convertirlas a JSON, etc, en vez de mezclar las diferentes acciones, lo que queremos es, primero obtener una lista de proyectos; para cada proyecto, obtener todas las API keys... Finalmente, para todas las API keys obtenidas (de todos los proyectos), las mostramos (o convertimos al formato especificado):

{{< figure src="/images/260426/process.png" width="100%" >}}

Es decir, idealmente, nuestro `main.go` debería ser algo como:

```go
// get project list
var projectIds []string
projectIds = listProjects(options)

// get API key list
keys := []keys.Key{}
for _, p := range projectIds {
    kk := listKeys(p)
    keys = append(keys, kk...)
}

// filter, convert API keys
for _, k:= range keys {
    k.Display(format)
}
```

## Reorganizando el código

Siguiendo el esquema que hemos definido en la sección anterior, vamos a reescribir el fichero `main.go`.

Tras comprobar que `projectId` no está vacío, dado que únicamente tenemos un proyecto por ahora pero esperamos trabajar con múltiples proyectos en el futuro, definimos un *slice* de `string` para almacenar toda la lista de proyectos:

```go
// ... before
    if *projectId == "" {
        fmt.Println("projectId cannot be empty")
        os.Exit(1)
    }

    ctx := context.Background()
// ... after
    if *projectId == "" {
        fmt.Println("projectId cannot be empty")
        os.Exit(1)
    }

    projectIds:=[]string{*projectId}
    
    // get API key list
    ctx := context.Background()
```

El siguiente paso es reemplazar el resto del código en `main.go` por una función `keys.List(projectId)` que devuelva todas las API keys definidas en el proyecto.

Empezamos eliminado el código existente:

```go
//  ... before
    projectIds := []string{*projectId}

    ctx := context.Background()
    c, err := apikeys.NewClient(ctx)
    if err != nil {
        fmt.Printf("new client error: %s\n", err.Error())
        os.Exit(1)
    }
    defer c.Close()

    req := &apikeyspb.ListKeysRequest{
        // See https://pkg.go.dev/cloud.google.com/go/apikeys/apiv2/apikeyspb#ListKeysRequest.
        Parent: fmt.Sprintf("projects/%s/locations/global", *projectId),
    }
    for k, err := range c.ListKeys(ctx, req).All() {
        if err != nil {
            // TODO: Handle error and break/return/continue. Iteration will stop after any error.
            fmt.Printf("list keys error: %s\n", err.Error())
            os.Exit(1)
        }
        fmt.Println(k.DisplayName)
    }
}
//  ... after
    projectIds := []string{*projectId}
```

En `internal/keys/keys.go`, creamos la función:

```go
func List(projectid string) []*Key {
    ctx := context.Background()
    c, err := apikeys.NewClient(ctx)
    if err != nil {
        fmt.Printf("new client error: %s\n", err.Error())
        os.Exit(1)
    }
    defer c.Close()

    req := &apikeyspb.ListKeysRequest{
        // See https://pkg.go.dev/cloud.google.com/go/apikeys/apiv2/apikeyspb#ListKeysRequest.
        Parent: fmt.Sprintf("projects/%s/locations/global", projectid),
    }

    var keys []*Key
    for k, err := range c.ListKeys(ctx, req).All() {
        if err != nil {
            // TODO: Handle error and break/return/continue. Iteration will stop after any error.
            fmt.Printf("list keys error: %s\n", err.Error())
            os.Exit(1)
        }
        key := &Key{
            Name:        k.Name,
            DisplayName: k.DisplayName,
            CreateTime:  k.CreateTime.AsTime(),
            ProjectId:   projectid,
        }
        keys = append(keys, key)
    }

    return keys
}
```

Como puede verse, la mayor parte del código es el que teníamos en `main.go`. La principal diferencia es que creamos una `Key` y que devolvemos el *slice* de `Key` para cada proyecto, como habíamos diseñado en la sección anterior.

Volvemos ahora a `main.go` para seguir ajustándolo a nuestro `main.go` ideal...

```go
//  ... before
    projectIds := []string{*projectId}
//  ... after
    projectIds := []string{*projectId}

    // get API key list
    var keylist []*keys.Key
    for _, p := range projectIds {
        kk := keys.List(p)
        keylist = append(keylist, kk...)
    }
```

## Mostrando las API keys

Para validar que todo funcionaba habíamos mostrado el *display name* de las API keys encontradas.

Como `Key` es un *struct*, y queremos definir una función que devuelva un `string`, podemos definir un método `func (k Key) String() string`, de manera que satisfaga el interfaz [Stringer](https://pkg.go.dev/fmt#Stringer). Es una buena práctica porque, por defecto, una gran cantidad de funciones usan el método `String()` para mostrar información (logging, debugging, mensajes de cara al usuario...) Proporciona una manera consistente de representar un tipo complejo como Key.

En `internal/keys/keys.go` añadimos la implementación de `String()`:

```go
func (k Key) String() string {
    return fmt.Sprintf("%s on project %s (created: %s)", k.DisplayName, k.ProjectId, k.CreateTime.Format(time.RFC1123))
}
```

Y ahora, en `main.go`, siguiendo nuestro esquema, añadimos el *bloque* final, el encargado de mostrar todas las API keys encontradas:

```go
//  ... before
        keylist = append(keylist, kk...)
    }
}
//  ... after
        keylist = append(keylist, kk...)
    }

    // display API keys
    for _, k := range keylist {
        fmt.Println(k.String())
    }
}
```

Compilando la aplicación de nuevo, la salida de la aplicación es:

```console
$ ./apicheck --project XXXX-XXX-XXXX-XXXXXX-XXXX
test-api-key on project XXXX-XXX-XXXX-XXXXXX-XXXX (created: Sat, 18 Apr 2026 11:05:17 UTC)
```

## Mostrando cuánto tiempo hace que la API key fue creada

Aunque tenemos cuándo fue creada la API key, no sabemos **cuánto tiempo hace** que fue creada...

Modificaremos la función `String()` para calcular cuánto tiempo hace y mostrarlo también:

```go
//  ... before
func (k Key) String() string {
    return fmt.Sprintf("%s on project %s (created: %s)", k.DisplayName, k.ProjectId, k.CreateTime.Format(time.RFC1123))
}
//  ... after
func (k Key) String() string {
    const hoursDay = 24
    return fmt.Sprintf("%s on project %s (created: %s, %.0f days ago)", k.DisplayName, k.ProjectId, k.CreateTime.Format(time.RFC1123), time.Since(k.CreateTime).Hours()/hoursDay)
}
```

De esta forma, tras compilar de nuevo la aplicación, la salida que proporciona es más parecida a lo que queríamos conseguir:

```console
$ ./apicheck --project XXXX-XXX-XXXX-XXXXXX-XXXX
test-api-key on project XXXX-XXX-XXXX-XXXXXX-XXXX (created: Sat, 18 Apr 2026 11:05:17 UTC, 8 days ago)
```

## Serie completa

* [API keys rotation checker - I](({{< ref "post/260425-apikey-checker-i.md" >}}))
* [API keys rotation checker - II](({{< ref "post/260425-apikey-checker-ii.md" >}}))
* [API keys rotation checker - III](({{< ref "post/260426-apikey-checker-iii.md" >}}))
* [API keys rotation checker - IV](({{< ref "post/260426-apikey-checker-iv.md" >}}))
* [API keys rotation checker - V](({{< ref "post/260426-apikey-checker-v.md" >}}))
* [API keys rotation checker - VI](({{< ref "post/260429-apikey-checker-vi.md" >}}))
* [API keys rotation checker - VII](({{< ref "post/260501-apikey-checker-vii.md" >}}))
