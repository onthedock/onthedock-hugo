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

title=  "El paquete 'flag' (I)"
date = "2026-08-24T18:06:28+02:00"
+++
El paquete [`flag`](https://pkg.go.dev/flag) es la opción desarrollada y mantenida por el equipo de Go para la gestión de *flags*.

Como viene incluido en la biblioteca standard de Go, no requiere ninguna dependencia externa.

En esta entrada, vemos a explorar algunos ejemplos usando el paquete `flag`.
<!--more-->
## Un nuevo *flagSet*

En vez de usar el *flagSet* por defecto del paquete `flag`, vamos a crear uno nuevo. Una de las ventajas de usar nuestro propio *flagSet* es facilitar los tests.

Un *flagSet* es un conjunto de *flags*. Los *flags* deben tener nombres únicos en un *flagSet*.

> Yo estoy acostumbrado a usar *dobles guiones* para indicar los flags; `flag` admite tanto uno como dos guiones para un *flag*.

Imaginemos que nuestra aplicación es admite `--foo bar --baz`, donde `--foo` es un *flag* que admite valores de tipo `string` mientras que `--baz` es de tipo `bool`.

```go
func main() {
    fs := flag.NewFlagSet("main", flag.ExitOnError)
    foo := fs.String("foo", "", "Foo variable")
    baz := fs.Bool("baz", false, "Baz variable")
    if err := fs.Parse(os.Args[1:]); err != nil {
        log.Fatal(err)
    }
    fmt.Println("foo:", *foo)
    fmt.Println("baz:", *baz)
}
```

Podemos probar cómo ésta aplicación tan sencilla satisface nuestras necesidades básicas de dotar a la aplicación de una manera sencilla de gestionar *flags*:

De entrada, `flag` nos proprorciona un sistema de ayuda:

```console
$ go run main.go -h
Usage of main:
  -baz
        Baz variable
  -foo string
        Foo variable
```

También podemos proporcionar valores por defecto para cualquier tipo de *flag*; en nuestro caso, `--foo` es, por defecto `""` mientras que `--baz` es `false`. Y por supuesto, funciona si proporcionamos cualquier otro vvalor:

```console
$ go run main.go
foo: 
baz: false

$ go run main.go --foo hola
foo: hola
baz: false

$ go run main.go --foo hola --baz
foo: hola
baz: true
```

Aunque por defecto no tenemos ningún tipo de validación de los **valores** de los flags, para especificar si son requeridos o no, por ejemplo, sí que podemos controlar cómo queremos que se comporte la aplicación en caso de que se encuentre un *flag* que no ha sido definido:

```console
$ go run main.go --patata
flag provided but not defined: -patata
Usage of main:
  -baz
        Baz variable
  -foo string
        Foo variable
exit status 2
```

Esto lo conseguimos mediante la opción `flag.ExitOnError` que hemos usado a la hora de definir el *flagSet*.

## Sólo flags cortos o largos, pero no los dos

El paquete `flag` sólo permite definir un "nombre" para el *flag*; podemos usar `-foo` o `-f`, pero no los dos a la vez (para el mismo *flag*). Podemos usar los dos, pero se interpretan como dos flags diferentes, que no es lo que queremos el 99% de los casos.

```console
$ go run main.go -h
Usage of main:
  -baz
        Baz variable
  -f string
        Foo variable (short version)
  -foo string
        Foo variable
```

## Testing

El *FlagSet* por defecto usa `os.Args[1:]` de forma implícita; es decir, no hace falta pasarlo a la función `flag.Parse()`.

Una de las ventajas de usar un *FlagSet* *custom* es que podemos especificar, de forma explícita, qué parametros le pasamos a la función `Parse()`.

Por ejemplo, podemos refactorizar la aplicación anterior como:

```go
func FlagParser(args []string) (string, bool, error) {
    fs := flag.NewFlagSet("main", flag.ExitOnError)
    foo := fs.String("foo", "", "Foo variable")
    baz := fs.Bool("baz", false, "Baz variable")
    if err := fs.Parse(args); err != nil {
        return "", false, err
    }
    return *foo, *baz, nil
}

func main() {
    cliArgs := os.Args[1:]
    foo, baz, err := FlagParser(cliArgs)
    if err != nil {
        log.Fatal(err)
    }
    fmt.Println("foo:", foo)
    fmt.Println("baz:", baz)
}
```

A nivel funcional, nada ha cambiado:

```console
$ go run main.go -h
Usage of main:
  -baz
        Baz variable
  -foo string
        Foo variable
```

Pero ahora, la función `FlagParser` acepta un *slice de strings* como parámetro; de momento, estamos usando los valores pasados a la aplicación desde la línea de comandos. Pero, por ejemplo para testear, podemos sustituirlo por cualquier *slice*:

```go
func Test_FlagParser(t *testing.T) {
    testCases := []struct {
        Name    string
        input   []string
        wantFoo string
        wantBaz bool
    }{
        {
            Name:    "only foo",
            input:   []string{"--foo", "hola"},
            wantFoo: "hola",
            wantBaz: false,
        },
        {
            Name:    "only baz",
            input:   []string{"--baz"},
            wantFoo: "",
            wantBaz: true,
        },
    }
    for _, tc := range testCases {
        t.Run(tc.Name, func(t *testing.T) {
            foo, baz, err := flagsParser(tc.input)
            if foo != tc.wantFoo || baz != tc.wantBaz {
                t.Fatalf("test %s failed: want foo=%s, baz=%t, but got foo=%s, baz=%t", tc.Name, tc.wantFoo, tc.wantBaz, foo, baz)
            }
            if err != nil {
                t.Fatalf("test %s failed: didn't want an error, but got one", tc.Name)
            }
        })
    }
}
```

Y como vemos en los resultados, funciona sin problemas:

```console
$ go test -v ./...
=== RUN   Test_FlagParser
=== RUN   Test_FlagParser/only_foo
=== RUN   Test_FlagParser/only_baz
--- PASS: Test_FlagParser (0.00s)
    --- PASS: Test_FlagParser/only_foo (0.00s)
    --- PASS: Test_FlagParser/only_baz (0.00s)
PASS
ok      flags   0.000s
```

## Resumen

El paquete `flag` de la biblioteca estándar:

- viene incluído en la biblioteca estándar
- proporciona un sistema de ayuda (con `-h` o `--help`)
- facilita el *testing*
- puede ampliarse para definir tipos de de *flag* **custom** (como *slices* de valores)

Sin embargo, no propociona:

- nombres cortos y largos para un mismo *flag*
- validación de *flags* (p.ej, indicar que un *flag* es requerido)
- validación de valores del *flag*: p.ej. verificar que el valor no está vacío o que tiene un valor que se ajusta a un formato determinado, como un *email* o una dirección IP.
- autocompletado para Bash/Zsh/etc...

En general el paquete `flag` proporciona una solución básica, pero ampliable, para realizar la gestión de *flags* en aplicaciones Go.
No proporciona algunas funcionalidades *avanzadas*, pero permite construirlas, por lo que debes determinar si *merece la pena* desarrollar y mantener alguna (o todas) esas funcionalidades adicionales.
