+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"
tags = ["linux", "go"]

thumbnail = "images/go.png"

# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}

title=  "CSV Parser (II)"
date = "2023-02-26T12:11:54+01:00"
+++
Hace unas semanas comentaba que estaba trabajando en un proyecto personal para implementar un *parseador* de reglas para el *proxy*, en Go.

Después de leer los artículos [Write packages, not programs](https://bitfieldconsulting.com/golang/packages) y [From packages to commands](https://bitfieldconsulting.com/golang/commands) de John Arundel (así como los artículos a los que enlaza), decidí enfocar de manera diferente el *parseador* de reglas del proxy.

Empecé a escribir un nuevo módulo `rules` guiado por tests...

El resultado se encuentra disponible en [ontehdock/proxy-rules](https://github.com/onthedock/proxy-rules) en Github, pero aquí apunto algunas pinceladas (a modo de notas personales).
<!--more-->

## Contexto

Una de las automatizaciones en las que hemos estado trabajando consiste en desplegar un *proxy* para que el tráfico hacia internet desde los proyectos de los clientes salga *filtrado*.

El *proxy* actúa **denegando** cualquier petición hacia una URL que no haya sido previamente incluída en una *allow list*. Para que los clientes puedan ser autónomos en la gestión de las reglas de las aplicaciones en sus proyectos pero sin acceder a la configuración del *proxy*, hemos establecido un automatismo que se enacarga de ello.

Los usuarios introducen las reglas en un fichero (en formato CSV) y la automatización lee su contenido, valida la sintaxis de las reglas y las convierte a un formato que puede ser aplicado al proxy.

## Ejercicio

La idea del ejercicio era realizar el proceso de lectura del fichero CSV, validar las reglas y guardar el resultado en formato JSON, pero esta vez en Go.

## Diferencias con la primera versión

En la entrada [CSV Parser en Go (work in progress)]({{< ref "230201-csv-parser-en-go.md" >}}) explicaba pasao a paso cómo había ido construyendo la primera versión de este *parser*... De alguna manera, estaba pasando del *proceso mental* o *workflow* de la aplicación **al código**.

La lectura de los artículos de John Arundel y [William Kennedy](https://www.ardanlabs.com/blog/2017/02/design-philosophy-on-packaging.html) me hicieron reflexionar en algo que comentaba con un compañero de trabajo hace apenas unos días: Go es un lenguaje simple; sin embargo, lo complicado es hacer *las cosas bien*.

Por supuesto, lo que signigica "bien" está abierto a debate, sea cual sea el contexto en el que se aplique este "criterio". Pero en el caso de Go, como se indica en los artículos referenciados, parte de ese "buen hacer" es construir módulos que sean reutilizables.

Con este enfoque en mente, lo primero que hice fue crear un módulo llamado `rules`. Y para seguir con las buenas prácticas, empecé a crear los tests antes de escribir el código...

En este caso, todo resulta un poco redundante, ya que la mayor parte de la funcionalidad de este módulo `rules` se basa en validar si cada uno de los campos que componen la regla del proxy es válido...

En cualquier caso, este enfoque de primero crear el test, después escribir el código, me hizo introducir los primeros cambios con respecto a la versión anterior.

En las primeras versiones, se realizaba la validación del contenido de cada uno de los campos de la futura regla **antes** de crearla... Eso significaba que la función `NewRule` no tenía que devolver un error, pues todos los campos para crear la regla ya habían pasado la validación previa.

Pero eso separaba la validación de la creación de la regla, así que finalmente absorví en `NewRule` tanto la validación como la creación de la regla en sí.

Dado que cada uno de los campos obtenido del CSV puede no cumplir los requisitos para formar parte de una regla, era posible que se generaran varios errores para una misma línea del CSV, o lo que es lo mismo, para una `Rule`. Así que `NewRule()` pasó a devolver un *slice* de errores.

La idea era convertir este *slice* de errores a JSON o algún formato similar... Pero descubrí que estaba dedicando mucho esfuerzo a una tema que, finalmente, un ser humano debería revisar y corregir...

Así que al final abandoné la idea de devolver los errores como JSON.

## Validación de cada campo de la regla y errores *custom*

Con el enfoque de escribir los tests **antes** de escribir el código, resultó obvio que la validación de cada uno de los campos obtenidos del fichero CSV o bien era válido, o no lo era. Esto significaba que las funciones de validación de cada uno de los campos sólo devolvieran un `bool`.

Inicialmente me atrajo la idea de que, para verificar si la regla era válida o no, sólo tenía que validar que todos los campos lo fueran... Y esto resultaba de los más sencillo si cada una de las funciones de validación de los camops devolvían `bool`.

```go
func (r *Rule) IsValid() bool {
    return rule.ValidateAction() && rule.ValidatePort() && rule.ValidateProtocol() && rule.ValidateUrl()
}
```

Sin embargo, de cara al usuario, la única infomración que se proporcionaría sería que "alguno" de los camos de la regla no es válido, pero no se indicaría qué campo o porqué no es válido...

No es la mejor experiencia, así que finalmente introduje un segundo valor de retorno, un `error`, que indicaría qué es lo que había fallado en la validación.

De nuevo, el problema era que para una sola regla, varios camos pueden no ser válidos...

La solución la encontré usando la función `Join`, del paquete `errors`, que une varios errores (descartando aquellos que sean `nil`) y los devuelve como un solo error.

De esta forma:

```go
func (rule *Rule) IsValid() (bool, error) {
    var err error

    if !rule.ValidateAction() {
        err = errors.Join(err, fmt.Errorf("%v: %q", ErrInvalidAction, rule.Action))
    }

    if !rule.ValidatePort() {
        err = errors.Join(err, fmt.Errorf("%v: %d", ErrInvalidPort, rule.Port))
    }

    if !rule.ValidateProtocol() {
        err = errors.Join(err, fmt.Errorf("%v: %q", ErrInvalidProtocol, rule.Protocol))
    }

    if !rule.ValidateUrl() {
        err = errors.Join(err, fmt.Errorf("%v: %q", ErrInvalidUrl, rule.Url))
    }

    return rule.ValidateAction() && rule.ValidatePort() && rule.ValidateProtocol() && rule.ValidateUrl(), err
}
```

Es decir, si se produce uno o más errores, estos se van *acumulando* y finalmente se devuelve un solo error por regla, idenpendientemente del número de campos inválidos que contenga.

```text
...
2023/02/26 12:25:16 error processing line [http  spam.com]:
CSV parse error on line 3, column 20: bare " in non-quoted-field. Ignoring line.
2023/02/26 12:25:16 error processing line [http p0rn.com 6969 block].
invalid action: "block"
invalid protocol: "http"
2023/02/26 12:25:16 error processing line [ ]:
CSV record on line 5: wrong number of fields. Ignoring line.
...
```

En esta segunda versión también se comunican los errores derivados de la propia estructura del fichero CSV, como por ejemplo, que haya campos delimitados con comillas que no estén emparejadas o líneas con campos de más (o de menos).

Aunque los errores no se convierten a JSON, es posible guardarlos en un fichero usando el *flag* `-log`; por defecto, se guardan en el fichero `errors.log`, pero si se prefiere otro nombre, se puede especificar mediante la opción `-logfile`:

```bash
$ go run main.go -log
$ cat errors.log 
2023/02/26 12:32:11 error processing line [http  spam.com]:
CSV parse error on line 3, column 20: bare " in non-quoted-field. Ignoring line.
2023/02/26 12:32:11 error processing line [http p0rn.com 6969 block].
invalid action: "block"
invalid protocol: "http"
2023/02/26 12:32:11 error processing line [ ]:
CSV record on line 5: wrong number of fields. Ignoring line.
```

```bash
$ go run main.go -log -logfile custom_error.log
$ cat custom_error.log 
2023/02/26 12:33:31 error processing line [http  spam.com]:
CSV parse error on line 3, column 20: bare " in non-quoted-field. Ignoring line.
2023/02/26 12:33:31 error processing line [http p0rn.com 6969 block].
invalid action: "block"
invalid protocol: "http"
2023/02/26 12:33:31 error processing line [ ]:
CSV record on line 5: wrong number of fields. Ignoring line.
```

## Testing

Como comentaba al principio, **esta vez sí** he empezado escribiendo el test antes que el código. Eso me ha ayudado a **pensar más** en qué es lo que cada una de las funciones debería hacer y cómo comprobar que lo estaban haciendo...

En algunos casos me ha llevado a hacer más tests de los que debería...

Inicialmente, por ejemplo, no validaba el campo `Url`, más allá de validar que tuviera algún valor:

```go
func Test_ValidateUrl(t *testing.T) {
    t.Run("empty not allowed", func(t *testing.T) {
        rule := new(Rule)

        got := rule.ValidateUrl()
        want := false
        assertValidation(t, got, want)
    })
}
```

Más adelante decidí probar a usar expresiones regulates en Go, así que busqué añadí los tests:

```go
    t.Run("regex for RFC 123 fqdn", func(t *testing.T) {
        for _, url := range []string{"ubuntu.com", "packages.ubuntu.com", "www.google.com", "vm01.compute.aws.com"} {
            rule := new(Rule)
            rule.Url = url

            got := rule.ValidateUrl()
            want := true
            assertValidation(t, got, want)
        }
    })
```

La expresión regular falla si el campo `Url` está vacío, así que el test `empty not allowed` en realidad es redundante; si incluyo `""` en la lista de casos de prueba para el test `regex for RFC 123 fqdn`

```bash
Running tool: /usr/local/go/bin/go test -timeout 30s -run ^\QTest_ValidateUrl\E$/^\Qregex_for_RFC_123_fqdn\E$ rules/rules

--- FAIL: Test_ValidateUrl (0.00s)
    --- FAIL: Test_ValidateUrl/regex_for_RFC_123_fqdn (0.00s)
        /home/operador/repos/proxy-rules/rules/rules_test.go:117: got 'false' but wanted 'true'
FAIL
FAIL rules/rules 0.002s
FAIL
```

He preferido dejarlo para que sea más *visible* en los resultados de los tests, si falla:

```bash
$ go test -v -run "Test_ValidateUrl" rules/*.go
=== RUN   Test_ValidateUrl
=== RUN   Test_ValidateUrl/empty_not_allowed
=== RUN   Test_ValidateUrl/regex_for_RFC_123_fqdn
--- PASS: Test_ValidateUrl (0.00s)
    --- PASS: Test_ValidateUrl/empty_not_allowed (0.00s)
    --- PASS: Test_ValidateUrl/regex_for_RFC_123_fqdn (0.00s)
PASS
ok      command-line-arguments  0.002s
```

Observando la salida de los tests ejecutados desde VSCode, se observa que la *cobertura* es de casi el 95% del código (del módulo `rules`):

```bash
Running tool: /usr/local/go/bin/go test -timeout 30s -coverprofile=/tmp/vscode-gosqNBTR/go-code-cover rules/rules

ok   rules/rules 0.003s coverage: 94.7% of statements
```

No está nada mal ;)
