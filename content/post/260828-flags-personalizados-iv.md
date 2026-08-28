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

title=  "Flags personalizados (Paquete 'flag' IV)"
date = "2026-08-28T08:14:00+02:00"
+++
El paquete `flag` sólo soporta unos pocos tipos de variables: `string`, `int`, `bool` y `duration`.
Sin emabargo, podemos definir nuestros propios tipos de forma sencilla; en esta entrada creamos *flags* de tipo `email` y que admitan múltiples valores separados por comas (*slice*).
<!--more-->
Para definir un nuevo tipo de *valor* para un *flag*, tenemos que implementar los siguientes interfaces:

```go
// Reference: https://pkg.go.dev/flag#Value
type Value interface {
    String() string
    Set(string) error
}
```

La función `String()` se usa para mostrar el valor por defecto del *flag*, mientras que `Set` define cómo se aplica el valor al *flag*.

## Valores de tipo `email`

Imagina que creas una aplicación que envía correos desde la CLI: `send --to john.doe@example.org --msg "Hi John!"`.

Queremos poder validar que el valor de `to` es una dirección de correo válida.

Lo primero que debemos hacer es definir un `struct`:

> El apquete [net/mail](https://pkg.go.dev/net/mail) contiene funciones para validar si una dirección de correo es válida.

```go
type EmailValue struct {
    Email mail.Address
}
```

Ahora, implementamos el método `String()`:

```go
func (v EmailValue) String() string {
    return v.Email.Address
}
```

Como el campo `Address` es un `string`, lo devolvemos tal cual.

Ahora vamos con el método `Set`:

```go
func (v *EmailValue) Set(s string) error {
    add, err := mail.ParseAddress(s)
    if err != nil {
        return err
    }
    v.Email = *add
    return nil
}
```

En este caso, aprovechamos la funcionalidad que nos ofrece el paquete `net/mail` para *parsear* una dirección de correo.

Ahora ya podemos definir un *flag* de tipo *Email*:

```go
type Send struct {
    Email mail.Address
    Msg   string
}

func (s *Send) Parse(args []string) error {
    fs := flag.NewFlagSet("send", flag.ExitOnError)
    em := &customflags.EmailValue{}
    fs.Var(em, "to", "Recipient's email")
    msg := fs.String("msg", "", "Message to send to recipient")
    if err := fs.Parse(args); err != nil {
        return err
    }
    s.Email = em.Email
    s.Msg = *msg
    return nil
}
```

Como hemos hecho con el resto de comandos de la aplicación, definimos un *struct* con el *comando* y la función asociada *Parse()* para *parsear* los argumentos para el comando.

Definmos `em` como una instancia del valor `EmailValue` y definimos una *flag* de ése tipo mediante `fs.Var(em, "email", "Recipient's email")`.

Validamos que funciona:

```console
$ go run main.go send -to john.doe@example.com
sending mail to <john.doe@example.com>

$ go run main.go send -to john.doe
invalid value "john.doe" for flag -to: mail: missing '@' or angle-addr
Usage of send:
  -msg string
        Message to send to recipient
  -to value
        Recipient's email
exit status 2
```

Como podemos comprobar, gracias a `ParseAddress()` del paquete `net/mail`, el valor de `--to` sólo se considera válido si verifica que **es una dirección de email**.

## Valores de tipo *slice*

Otro caso común es el de necesitar un *flag* de tipo *slice*, es decir, múltiples valores (de un mismo tipo). Tenemos varias formas de implementar este tipo de *flag*, pero vamos a centrarnos en uno de los más simples: múltiples valores separados por comas.

```console
myapp rm --files "one.txt, two.txt, three.txt"
```

Para definir el valor de tipo *slice*, definimos un *struct*:

```go
type SliceStringsValue struct {
    SliceStrings []string
}
```

Implementamos el método `String` (para mostrar el valor por defecto del *flag*):

```go
func (ss *SliceStringsValue) String() string {
    var s string
    for i, v := range ss.SliceStrings {
        if i == 0 {
            s = fmt.Sprintf("%s", v)
            continue
        }
        s = fmt.Sprintf("%s,%s", s, v)
    }
    return s
}
```

En el método `Set` es donde implementamos la lógica para *dividir* el valor proporcionado en el *flag* en un *slice*:

```go
func (ss *SliceStringsValue) Set(s string) error {
    sep := ","
    // if there's no separator, we have only one value
    if !strings.Contains(s, sep) {
        ss.SliceStrings = []string{s}
        return nil
    }
    // remove spaces
    sss := []string{}
    for _, x := range strings.Split(s, sep) {
        sss = append(sss, strings.TrimSpace(x))
    }
    ss.SliceStrings = sss
    return nil
}
```

Como para el caso del *flag* de tipo `Email`, definimos un comando para *eliminar* múltiples ficheros:

```go
type Rm struct {
    Files []string
}

func (r *Rm) Parse(args []string) error {
    fs := flag.NewFlagSet("rm", flag.ExitOnError)
    ss := &customflags.SliceStringsValue{}
    fs.Var(ss, "files", "List of files to remove, comma separated")
    if err := fs.Parse(args); err != nil {
        return err
    }
    r.Files = ss.SliceStrings
    return nil
}
```

Y si ejecutamos éste nuevo comando:

```console
$ go run main.go rm --files "one, two, three"
removing file "one" ...
removing file "two" ...
removing file "three" ...
```

## Resumen

Como hemos visto en estos ejemplos, podemos extender el paquete `flag` para definir nuestros propios *valores personalizados* para los *flags*.
