+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "programming", "go"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/go.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/

# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}
# YouTube           {{< youtube w7Ft2ymGmfc >}}
# Gist              {{< gist username 7896402 >}}
# Highlight         {{< highligth language >}}...{{< /highlight >}}
# Twitter           {{< tweet user="SanDiegoZoo" id="1453110110599868418" >}}

title=  "Cliente en Go para la CMDB Updater Tool API"
date = "2022-11-26T12:39:31+01:00"
+++
En entradas anteriores he escrito sobre cómo interaccionar con una API a través de *scripts* en Bash, usando `curl` y poco más... En vez de dejar en manos de los usuarios la tarea de generar el *payload* que enviar vía `curl` a la API, desarrollé un cliente en Bash: [Cliente API en Bash (con curl)]({{< ref "220617-cliente-api-en-bash.md" >}}).

Desde entonces, he estado trabajando en una versión en Go del cliente para ésta API... Y creo que ¡ya está lista 🎉!

En esta entrada, describo por encima cómo funciona, pero sobre todo cómo ha sido la experiencia de desarrollarla.
<!--more-->

Esta API acepta *comandos* que se ejecutan sobre una base de datos.

En el mensaje que se envía a la API se indica el comando a ejecutar y los parámetros requeridos por el comando.

## Rescribiendo el cliente Bash en Go

El cliente en Bash no es un "cliente" como tal; en realidad son un conjunto de *scripts*. Cada *script* implementa uno de los comandos soportados por la API, junto con otros que proporcionan funcionalidades comunes a todos los comandos, como la obtención del token de autenticación de la API, el envío de la petición al *endpoint*, la validación de la respuesta y el control de errores.

En la versión en Go, quería conseguir en **un único ejecutable** soporte para todos los comandos. Esto me hizo descartar el uso del paquete [flag](https://pkg.go.dev/flag) y recurrir a [cobra](https://pkg.go.dev/github.com/spf13/cobra).

La *solvencia* de Cobra para crear herramientas de línea de comando queda probada cuando tienes en cuenta que es la *librería* usada para `kubectl`, `terraform`, `docker` o `hugo`.

## Definiendo los comandos usando Cobra

En Cobra, se define una *jerarquía* de comandos; cuando se ejecuta el binario "a pelo", se ejecuta el `rootCmd`; si se ejecuta un *subcomando*, se ejecuta la función asociada al subcomando indicado.

En mi caso, el `rootCmd` únicamente muestra la ayuda, pues es necesario especificar un subcomando.

La estructura jerárquica en Cobra también aplica a los *flags*; los *flags* "globales" se denominan *persistent* y están disponibles para todos los subcomandos. Además de los *persistent flags* se pueden definir *flags* específicos para cada comando.

Entre los parámetros "globales", Cobra define por defecto `--help` y `--version`; para mi cliente, he añadido dos *persistent flags* adicionales: `--url` permite especificar la URL del *endpoint* de la API y `--dry-run`, que indica si el comando debe evaluarse sin ser aplicado:

```go
package cli

import (
    "os"

    "github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
    Use:   "cli",
    Short: "A CLI client for the <API_NAME> written in Go",
    Long: `<API_NAME> CLI client written in Go by Xavier Aznar for the <API_NAME>.
https://es.linkedin.com/in/xavieraznarcampos
`,
    Version: version,
}

func init() {
    rootCmd.PersistentFlags().BoolVar(&dryrun, "dry-run", false, "Run command in dry-run mode")
    rootCmd.PersistentFlags().StringVar(&url, "url", "", "<API_NAME> URL\nAlternatively, use the environment variable <API_NAME>_URL")
}

func Execute() {
    if err := rootCmd.Execute(); err != nil {
        os.Exit(errorUnknown)
    }
}
```

Para otros comandos en Cobra, la estructura es la misma, excepto que no se define la función `Execute()`: definimos el comando como un *struct* de tipo [`cobra.Command`](https://pkg.go.dev/github.com/spf13/cobra#Command) y le asociamos *flags* en la función `init()`.

```go
package cli

import (
    "github.com/spf13/cobra"
)

var getCmd = &cobra.Command{
    Use:     "get",
    Aliases: []string{"get-doc"},
    Short:   "Get document from <API_NAME>",
    Run: func(cmd *cobra.Command, args []string) {
        var params = Params{
            doc_id: id,
        }
        Response = sendCommand("get", &params, dryrun)
    },
}

func init() {
    getCmd.Flags().StringVar(&id, "id", "", "Document Id (required)")
    getCmd.MarkFlagRequired("id")
    rootCmd.AddCommand(getCmd)
}
```

El atributo `Run` de `cobra.Command` define la función que se ejecuta al invocar el subcomando desde la herramienta. En mi caso, se asigna el valor o valores proporcionados como argumento al subcomando desde la CLI y se pasan a la función `sendCommand(...)`.

## Función `sendCommand(command string, p *Params, dryrun bool) string`

La función `sendCommand` es quien hace el trabajo duro en el cliente. En primer lugar, dado que cada comando de la API acepta un número (y tipo) diferente de parámetros, la función `buildRequest` se encarga de contruir el *payload* que se enviará a la API.

Una vez construido el mensaje para la API, la función `sendRequest` instancia el cliente HTTP que realiza la petición contra el *endpoint* de la API. `sendRequest` obtiene el token para autenticar la petición de una variable de entorno (`IDENTITY_TOKEN`).

Finalmente, `processResponse` valida si se ha producido ningún error (y lo gestiona) antes de devolver al respuesta de la API.

La funcionalidad del cliente está creado como un módulo en Go, por lo que `main.go` es muy sencillo:

```go
package main

import (
    "go-client/cli"
    "fmt"
    "os"
)

func main() {
    cli.Execute()
    fmt.Fprint(os.Stdout, cli.Response)
}
```

## Mejoras (algunas implementadas, otras no 😉)

### Tomar el contenido para un documento desde un fichero

En la versión en Bash del cliente, para añadir un nuevo documento a la base de datos, el contenido del documento debe pasarse como una cadena (*string*). Dado que se trata de un objeto JSON que puede ser bastante grande, es habitual hacer algo como:

```bash
new_document=$(cat new_document.json)
add_doc --document "${new_document}"
```

El cliente en Go incluye un nuevo argumento, `--docfile` que permite especificar el nombre de un **fichero** y leer su contenido directamente:

```go
cli add --docfile path/to/new_document.json
```

### Autocompletado, ayuda, sugerencias de comandos, multiplataforma

Todas estas funcinalidades las proporciona Cobra; por un lado, permite generar un fichero de autocompletado para diferentes *shells*:

```bash
$ cli completion --help
Generate the autocompletion script for cli for the specified shell.
See each sub-command's help for details on how to use the generated script.

Usage:
  cli completion [command]

Available Commands:
  bash        Generate the autocompletion script for bash
  fish        Generate the autocompletion script for fish
  powershell  Generate the autocompletion script for powershell
  zsh         Generate the autocompletion script for zsh

Flags:
  -h, --help   help for completion

Global Flags:
      --dry-run      Run command in dry-run mode
      --url string   <API_NAME> URL
                     Alternatively, use the environment variable <API_NAME>_URL

Use "cli completion [command] --help" for more information about a command.
```

De esta manera, pulsando *Tab* dos veces, se muestran todos los comandos disponibles:

```bash
$ cli # tab, tab
add                         (Add document to <API_NAME>)
completion                  (Generate the autocompletion script for the specified shell)
delete                      (Delete document from <API_NAME>)
get                         (Get document from <API_NAME>)
help                        (Help about any command)
query                       (Query documents matching the condition)
sequence                    (Get the next identifier for the specified document type)
set                         (Set document with documentId into the <API_NAME>)
show-token-env-var-command  (Show command to set the IDENTITY_TOKEN environment variable)
show-url-env-var-command    (Show command to set the <API_NAME>_URL environment variable)
update                      (Update document with documentId)
validate                    (Validate document in the <API_NAME> (against its schema))
version                     (Get version of the <API_NAME>)
```

Si se pulsa *tab* tras escribir parte del nombre de un comando, se completa.

Cobra no sólo muestra el *usage* para el comando principal, sino que para se pued obtener ayuda específica para cada *subcomando*, como los alias definidos, los parámetros, si éstos son obligatorios o no, si tienen un valor por defecto definido...

```bash
$ cli update --help
Update document with documentId

Usage:
  cli update [flags]

Aliases:
  update, update-doc

Flags:
  -f, --docfile string    Path to a file containing an <API_NAME> document
                          (takes precedence over '--document')
  -d, --document string   Document content (default "{}")
  -h, --help              help for update
      --id string         Document Id (required)


Global Flags:
      --dry-run      Run command in dry-run mode
      --url string   <API_NAME> URL
                     Alternatively, use the environment variable <API_NAME>_URL
```

Cobra también ofrece sugerencias si esribimos un subcomando desconocido:

```bash
$ cli git --document 12345
Error: unknown command "git" for "cli"

Did you mean this?
    get
    set

Run 'cli --help' for usage.
```

Al estar escrito en Go, realizar la compilación para que el cliente se puede ejecutar en MS Windows, es tan sencillo como añadir :

```make
GOOS=windows GOARCH=amd64 go build -o ./$(binaryName).exe -ldflags="-X 'go-client/cli.version=v$(version)'" *.go
```

### Tests (todavía no, *#shameOnMe*)

Sé que los tests deben crearse primero, hacer que fallen, escribir el **mínimo** código que los haga pasar y después, *rafactorizar*...

La ventaja de tener que crear los tests **primero** y escribir el código **después** es que antes de escribir nada, tienes que *darle una vuelta* a lo que quieres que haga el código...

Esto seguramente me hubiera ahorrado tener que re-escribir algunas cosas múltiples veces... Pero he pensado que *más vale tarde que nunca* y desarrollar tests es la siguiente tarea del *backlog* 😉

### Mejora de los comandos `show-*` para obtener la URL de la API y el token de autenticación

Después de una semana usando el cliente de forma regular, la opción de mostrar los comandos para poblar las variables con el token de autenticación (y el de la URL de la API, en menor medida), son útiles pero todavía generan *cierta fricción*.

Por ejemplo, usando `gcloud config configuration activate <config_name>` cambio de configuración (para *moverme* entre el entorno de desarrollo y el de *staging*, por ejemplo). Sin embargo, las variables de entorno mantienen los valores que tuvieran, lo que provoca errores de autenticación.

Una posible mejora sería conseguir una mayor integración con `gcloud`...

## Conclusiones

Disponer de un cliente en la línea de comandos, con autocompletado me ha permitido trabajar con una mayor eficiencia y velocidad; he sido capaz de realizar las mismas tareas sin necesidad de tener que crear un *script* *ad hoc*, importar el cliente en Bash, etc...

Mi intención es presentar al resto del equipo el cliente para empezar un *testeo* más intenso antes de integrarlo, si así lo decidimos, en el *toolset* de las *pipelines*.

Y por supuesto, me ha ayudado a aprender un poquito más de Go 😉
