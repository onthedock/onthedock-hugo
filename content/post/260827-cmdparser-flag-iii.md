+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["go", "golang", "paquete-flag"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/go.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/
# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/260426/process.png" width="100%" >}}

title=  "Generalizando el concepto de comandos usando el paquete 'flag' (III)"
date = "2026-08-27T19:33:46+02:00"
+++
Ahora que tenemos un *concepto* que funciona, el siguiente paso es generalizarlo. En esta entrada el foco es "estandarizar" los conceptos de *comando* usando el paquete `flag`.
<!--more-->
Como hemos visto, la idea es tener un *flagSet* para el *comando raíz*, sin ninguna opción más allá del *flag* de ayuda `-h`.

Una forma de generalizarlo podría ser creando un paquete llamado `command` y definir una función `New()`:

```go
var ErrNoCommandProvided = errors.New("no command provided")

func New(name string, args []string, errhandling flag.ErrorHandling, usage string) (*Command, error) {
    fs := flag.NewFlagSet(name, errhandling)
    fs.Usage = func() {
        fmt.Println(usage)
    }
    if err := fs.Parse(args); err != nil {
        return nil, err
    }
    if fs.NArg() >= 1 {
        return &Command{
            Name: fs.Args()[0],
            Args: fs.Args()[1:],
        }, nil
    }
    fs.Usage()
    return nil, ErrNoCommandProvided
}
```

Como hemos visto en las entradas anteriores, el `Command` sería:

```go
type Command struct {
    Name string
    Args []string
}
```

De esta forma, podemos definir el *comando* raíz como:

```go
const usage string = `Usage of 'myapp':
    myapp read --file <path/to/file>
    myapp write --text "<text>" --file <path/to/file>`
    
func main() {
    cmd, err := command.New("myapp", os.Args[1:], flag.ExitOnError, usage)
    if err != nil {
        log.Fatal(err)
    }
    // ...
```

A continuación podemos hacer un `switch` para ejecutar cada uno de los comandos que incluya la aplicación.

Para homogeneizar, definimos un *struct* con las *opciones* de cada comando... Definimos un *interface*:

```go
type CmdParser interface {
    Parse([]string) error
}
```

Todos los *comandos* deben satisfacer esta interfaz:

```go
type Write struct {
    Text     string
    Filename string
}

func (w *Write) Parse(args []string) error {
    fs := flag.NewFlagSet("write", flag.ExitOnError)
    text := fs.String("text", "", "Text to write to file")
    filename := fs.String("file", "", "Name of the file to write to")
    if err := fs.Parse(args); err != nil {
        return err
    }
    if *filename == "" {
        return fmt.Errorf("--file cannot be empty")
    }
    w.Text = *text
    w.Filename = *filename
    return nil
}
```

De esta forma, el `switch` en `main()` queda:

```go
func main() {
    cmd, err := command.New("myapp", os.Args[1:], flag.ExitOnError, usage)
    if err != nil {
        log.Fatal(err)
    }

    switch cmd.Name {
    case "read":
        r := &cmds.Read{}
        if err := r.Parse(cmd.Args); err != nil {
            log.Fatal(err)
        }
        // call function to read from file
        fmt.Printf("reading from file %q\n", r.Filename)
    case "write":
        w := &cmds.Write{}
        if err := w.Parse(cmd.Args); err != nil {
            log.Fatal(err)
        }

        // call function to write text to file
        fmt.Printf("writing text %q to file %q\n", w.Text, w.Filename)
    default:
        log.Fatalf("Unknown command: %s", cmd.Name)
    }
}
```

## Resumen

En estas entradas se muestra cómo podemos construir *comandos* y gestionarlos sin necesidad de usar nada más que el paquete `flag` de la biblioteca estándar.

Seguimos sin tener algunas opciones que sí que proporcionan paquetes más completos, como opciones *cortas* y *largas*, autocompletado para la *shell*, *flags* globables heredadas en los comandos, etc...
