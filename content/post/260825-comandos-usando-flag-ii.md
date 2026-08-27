+++
draft = true

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

title=  "Comandos Usando el paquete Flag (II)"
date = "2026-08-25T20:22:12+02:00"
+++
Una de las limitaciones del paquete `flag` es que no proporciona soporte para comandos o subcomandos. Sin embargo, podemos simularlos de manera sencilla.
<!--more-->
Lo primero que debemos tener en cuenta con respecto al paquete `flag`, es que el *parser* deja de buscar *flags* en cuanto encuentra un parámetro que no empieza por `-`. Por tanto, el primer paso a la hora de pensar en el diseño de la CLI es decidir la estructura que van a seguir los comandos y subcomandos que quieres proporcionar.

Imaginamos una aplicación que permite leer y escribir ficheros:

```console
$ myapp -h
$ myapp read -h
$ myapp read --file somefile
$ myapp write --text "hola que tal" --file somefile
```

Es decir, en este ejemplo, el primer parámetro posicional (es decir, lo primero que no es un *flag*) siempre es un comando; si no hay ningún comando, entonces lo único que puede haber es el *flag* para mostrar la ayuda (y quizás, la versión de la aplicación).

```go
func mainFlags(args []string) error {
    fs := flag.NewFlagSet("myapp", flag.ExitOnError)
    if err := fs.Parse(args); err != nil {
        return err
    }
    return nil
}

func main() {
    if err := mainFlags(os.Args[1:]); err != nil {
        log.Fatalln(err)
    }
}
```

Ésta sería una implementación mínima que permite mostrar ayuda en el caso de que la aplicación se ejecute con el *flag* `-h`, pero que (todavía) no "sabe nada" de comandos:

```console
$ go run main.go -h
Usage of myapp:

$ go run main.go patata -h
$
```

Como no hemos definido ningún *flag*, el paquete `flag` no puede proporcionar mucha ayuda sobre cómo debe usarse la aplicación.

## Usage

El paquete `flag` permite definir la propiedad `Usage` para un *FlagSet*.

> // Usage is the function called when an error occurs while parsing flags.  
> // The field is a function (not a method) that may be changed to point to  
> // a custom error handler. What happens after Usage is called depends  
> // on the ErrorHandling setting; for the command line, this defaults  
> // to ExitOnError, which exits the program after calling Usage.  
> Usage func()

En nuestro caso:

```go
func usage() {
    fmt.Println(`Usage of 'myapp':
    myapp read --file <path/to/file>
    myapp write --text "<text>" --file <path/to/file>`)
}
```

Y actualizamos la función `mainFlags`:

```go
func mainFlags(args []string) error {
    fs := flag.NewFlagSet("myapp", flag.ExitOnError)
    fs.Usage = usage
    if err := fs.Parse(args); err != nil {
        return err
    }
    return nil
}
```

Ahora, si se ejecuta la aplicación con el *flag* `-h`:

```console
$ go run main.go -h
Usage of 'myapp':
    myapp read --file <path/to/file>
    myapp write --text "<text>" --file <path/to/file>
```

## Comandos

Nuestra aplicación de ejemplo va a tener dos comandos: `read` y `write`. Como estos parámetros no empiezan por `-`, `flag` no los reconoce como *flags* y los ignora al procesar los *flags*.

Podemos saber cuántos de estos argumentos hay después de haber procesado todos los flags mediante `NArg()`. En nuestro caso, el primer argumento será un *comando*, mientras que el resto pueden ser parámetros para este comando.

Para poder extender más adelante éste mismo patrón con más subcomandos, modificamos la función `mainFlags` de manera que devuelva el nombre del comando y el resto de parámetros como *argumentos* del comando.

Definimos un *struct*:

```go
type Command struct {
    Name string
    Args []string
}
```

Y modificamos la función `mainFlags`:

```go
    fs := flag.NewFlagSet("myapp", flag.ExitOnError)
    fs.Usage = usage
    if err := fs.Parse(args); err != nil {
        return nil, err
    }
    if fs.NArg() >= 1 {
        return &Command{
            Name: fs.Arg(0),
            Args: fs.Args()[1:],
        }, nil
    }
    fs.Usage()
    return nil, fmt.Errorf("No command provided")
```

Ahora, en `main`:

```go
func main() {
    cmd, err := mainFlags(os.Args[1:])
    if err != nil {
        log.Fatalln(err)
    }
    switch cmd.Name {
    case "read":
        fmt.Println("command 'read'")
        fmt.Printf("arguments for command: %v\n", cmd.Args)
    case "write":
        fmt.Println("command 'write'")
        fmt.Printf("arguments for command: %v\n", cmd.Args)
    default:
        log.Fatalf("Unknown command: %s", cmd.Name)
    }
}
```

Ahora, si se ejecuta la aplicación sin ningún comando:

```console
$ go run main.go 
Usage of 'myapp':
        myapp read --file <path/to/file>
        myapp write --text "<text>" --file <path/to/file>
2026/08/27 05:49:57 No command provided
exit status 1
```

Pero si se proporciona un comando:

```console
$ go run main.go read --foo bar
command 'read'
arguments for command: [--foo bar]

$ go run main.go patata --foo bar
2026/08/27 05:51:16 Unknown command: patata
exit status 1
```

Es decir, vemos que hemos implementado los comandos, pero los comandos todavía no hacen nada.

## *Parseando* *flags* para los comandos

Como hemos devuelto los argumentos que siguen al *comando* proporcionado por el usuario, podemos aplicar el mismo proceso para definir qué *flags* aplican a cada comando, o si alguno de los comandos tiene *subcomandos*, etc...

Definimos una función que procese los *flags* para el *comando* **write**:

```go
func writeFlags(args []string) error {
    fs := flag.NewFlagSet("write", flag.ExitOnError)
    text := fs.String("text", "", "Text to write to file")
    filename := fs.String("file", "", "Name of the file to write to")
    if err := fs.Parse(args); err != nil {
        return err
    }
    if *filename == "" {
        return fmt.Errorf("--file cannot be empty")
    }
    fmt.Printf("writing %q to file %q\n", *text, *filename)
    return nil
}
```

Finalmente, actualizamos la función `main` para que llame a la función `writeFlags`:

```go
func main() {
    cmd, err := mainFlags(os.Args[1:])
    if err != nil {
        log.Fatalln(err)
    }
    switch cmd.Name {
    case "read":
        fmt.Println("command 'read'")
        fmt.Printf("arguments for command: %v\n", cmd.Args)
    case "write":
        if err := writeFlags(cmd.Args); err != nil {
            log.Fatal(err)
        }
    default:
        log.Fatalf("Unknown command: %s", cmd.Name)
    }
}
```

Como se trata de una aplicación de ejemplo, desde `writeFlags` mostramos un mensaje de texto en *stdOut* y finalizamos; en una aplicación más realista, podríamos devolver un *struct* con las opciones para la función encargada de escribir en el fichero.

```go

type WriteOptions struct {
    Text     string
    Filename string
}

func writeFlags(args []string) (*WriteOptions, error) {
    fs := flag.NewFlagSet("write", flag.ExitOnError)
    text := fs.String("text", "", "Text to write to file")
    filename := fs.String("file", "", "Name of the file to write to")
    if err := fs.Parse(args); err != nil {
        return nil, err
    }
    // validate values
    if *filename == "" {
        return nil, fmt.Errorf("--file cannot be empty")
    }
    return &WriteOptions{
        Text:     *text,
        Filename: *filename,
    }, nil
}

func main() {
    cmd, err := mainFlags(os.Args[1:])
    if err != nil {
        log.Fatalln(err)
    }
    switch cmd.Name {
    case "read":
        fmt.Println("command 'read'")
        fmt.Printf("arguments for command: %v\n", cmd.Args)
    case "write":
        wflags, err := writeFlags(cmd.Args)
        if err != nil {
            log.Fatal(err)
        }
        // call function to write text to file
        fmt.Printf("writing text %q to file %q\n", wflags.Text, wflags.Filename)
    default:
        log.Fatalf("Unknown command: %s", cmd.Name)
    }
}
```

Lo importante del ejemplo es ver cómo, usando el paquete `flag`, podemos implementar comandos (y subcomandos) de manera relativamente sencilla.

Aplicando éste patrón, seguimos disfrutando de todas las ventajas que proporciona el paquete `flag`, como la generación automática de mensajes de ayuda:

```console
$ go run main.go write --help
Usage of write:
  -file string
        Name of the file to write to
  -text string
        Text to write to file
```
