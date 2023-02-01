+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "go"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/go.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/

# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}
# YouTube           {{< youtube w7Ft2ymGmfc >}}
# Gist              {{< gist username 7896402 >}}
# Highlight         {{< highligth language >}}...{{< /highlight >}}
# Twitter           {{< tweet user="SanDiegoZoo" id="1453110110599868418" >}}

title=  "CSV Parser en Go (work in progress)"
date = "2023-02-01T20:08:55+01:00"
+++
En la entrada [Convertir CSV en JSON con Jq]({{< ref "230111-convertir-csv-en-json.md" >}}) comentaba cómo realizar la conversión de un fichero CSV en JSON usando Jq.

En esta entrada repito (parcialmente) el ejercicio, pero usando Go.
<!--more-->
> Estoy pasando por uno de esos momentos de la vida en que todo pasa **de golpe** y tengo múltiples *frentes abiertos* tanto en el personal como en lo laboral... Así que tengo poco tiempo libre... que prefiero pasar con mi pareja o, simplemente, descansando y/o escuchando música o viendo alguna serie... De ahí lo de "parcialmente".

Como indicaba en la otra entrada, el *ejercicio* de conversión era una especie de *versión reducida a nivel de **prueba de concepto*** del desarrollo que hemos realizado en el trabajo. El fichero CSV contiene los elementos que definen una regla en el *proxy*, que el usuario puede *autogestionar* a través de un automatismo.

Como entrada, usamos las reglas definidas en el fichero CSV, las validamos y si son correctas, las aplicamos al *proxy*.

## Leyendo un fichero CSV

En Go, la biblioteca *standar* contiene funciones específicas para gestionar ficheros CSV en el módulo [enconding/csv](https://pkg.go.dev/encoding/csv).

Para leer el fichero CSV, abrimos el fichero y creamos un `Reader` mediante `csv.NewReader`. El método `ReadAll()` del `reader` lee todo el contenido del fichero y lo *parsea*.
Si no se produce ningún error, obtenemos `[][]string`, es decir, un *slice* de "líneas" en el que cada línea es un *slice* de *strings*...

```go
func readCsvFile(filePath string, separator rune) [][]string {
  f, err := os.Open(filePath)
  if err != nil {
    log.Fatalf("Unable to read input file: '%s': '%v'\n", filePath, err)
  }
  defer f.Close()

  csvReader := csv.NewReader(f)
  csvReader.Comma = separator

  lines, err := csvReader.ReadAll()
  if err != nil {
    log.Fatalf("Unable to parse '%s' as a CSV file\n", filePath)
  }
  return lines
}
```

## Separador de campos en el fichero CSV

En nuestro caso, el usuario puede proporcionar un fichero CSV que puede tener como delimitador de campos un "punto y coma" `;`, en vez de una "coma" `,`.

> Esto es culpa de MS Excel, que por defecto guarda los ficheros CSV usando `;` por algún motivo que se me escapa...

Para tener flexibilidad a la hora de procesar ficheros CSV que usen como separador `,` tanto como `;` (o cualquier otro caracter), al invocar la aplicación en Go podemos especificar el delimitador usado en el fichero mediante el *flag* `-delimiter`.

El nombre del fichero se proporciona mediante el *flag* `-input`:

```go
func main() {
  var delimiter string
  var fileName = flag.String("input", "", "rules points to a file containing the rules to parse")
  flag.StringVar(&delimiter, "delimiter", ",", "field delimiter")
  flag.Parse()
  //...
```

## Procesado de "reglas"

Cada línea del fichero CSV corresponde a una regla, que está compuesta por varios campos. En este ejemplo definimos cuatro campos:

- protocolo
- url (*fully qualified domain name*)
- puerto
- acción

El módulo `enconding/csv` realiza algunas validaciones sobre el contenido del fichero CSV, ignorando líneas (completamente) vacías, por ejemplo.

Sin embargo, las líneas que sólo contienen espacios (o tabuladores) no se consideran "vacías" y se procesan.

Para mantener el nivel de simplicidad del ejercicio, en mi caso no compruebo si hay líneas que sólo contengan caracteres en blanco.

Tampoco se contempla que haya líneas duplicadas.

El espacio en blanco entre los delimitadores de campo se conserva, por lo que tengo que *limpiar* los espacios sobrantes.

## Procesando las *reglas*

Cada línea en el fichero CSV (que mediante el módulo `encondig/csv` se ha transformado en `[][]string`) es una *regla*.

Una vez hemos leído el fichero CSV y lo tenemos en un objeto con el que trabajar en Go (`[][]string`), empezamos a analizar el contenido.

El primer paso es recorrer cada una de las *líneas* y eliminar los espacios sobrantes; para ello, usamos la función `strings.Trim(r, " ")` para cada uno de los elementos de `rules`, que es el `[][]string`:

```go
// 'main' function
// ...
  for _, rule := range rules {
    // trim extra spaces from each field in the line
    for i, r := range rule {
      rule[i] = strings.Trim(r, " ")
    }
    // ...
```

El primer bucle recorre el *slice* "línea a línea"; el segundo, recorre los campos de cada línea, eliminando espacios en blanco *alrededor* del valor de cada campo.

## El tipo `Rule`

Los diferentes campos que forman una *regla* están relacionados, por lo que para trabajar con ellos como un *bloque*, defino el tipo `Rule`:

```go
type Rule struct {
 Protocol string
 Url      string
 Port     string
 Action   string
}
```

De momento, en la función `main` construyo cada una de las *regla*s dentro del bucle principal, asignando los valores de cada *línea* a cada uno de los campos de la `Rule`:

```go
  rule := Rule{
   Protocol: rule[0],
   Url:      rule[1],
   Port:     rule[2],
   Action:   rule[3],
  }
```

Para los *tests* he creado una función `func NewRule(rule []string) (*Rule, error)`; la idea es que esta función asigne los valores de una línea del fichero (una *regla*) y construya un objeto `Rule` con ellos. Si alguno de los campos es inválido, devolverá una `Rule` vacía y un *slice* de errores `[]error`.

La idea es que este *slice* de errores contenga un elemento para cada uno de los campos que hayan fallado la valicación para la línea/regla actual de la iteración del bucle, aunque por ahora **siempre** devuelve el objeto `Rule` y el *slice* de errores siempre está vacío.

```go
// Work in progress
func NewRule(rule []string) (*Rule, []error) {
 r := &Rule{
  Protocol: rule[0],
  Url:      rule[1],
  Port:     rule[2],
  Action:   rule[3],
 }

 return r, []error{}
}
```

## Validación de los campos de la `Rule`

La idea de la función `func NewRule(rule []string) (*Rule, []error)` es que le pasemos un conjunto de *strings* y que nos devuelva una `Rule`, si todo va bien. Esta función también tiene que encargarse de *validar* que los valores proporcionados son aceptables para crear la `Rule`; si no lo son, debe devolver un *slice* con todos los errores encontrados.

El método `func (r *Rule) Validate() []error` se encarga de hacer esto mismo:

> De nuevo, he simplificado las validaciones; lo ideal es usar `regex` para filtrar los valores aceptables de cada campo, de acuerdo con las limitaciones que el fabricante del *proxy* indica en su documentación. En este artículo, priorizo la simplicidad.

```go
func (r *Rule) Validate() []error {
 var validationErrors = []error{}

 if r.Protocol != "tcp" && r.Protocol != "udp" {
  validationErrors = append(validationErrors, fmt.Errorf("invalid protocol %q. Accepted values are 'tcp' or 'udp'", r.Protocol))
 }

 port, err := strconv.Atoi(r.Port)
 if err != nil {
  validationErrors = append(validationErrors, fmt.Errorf("failed to convert port %q to a valid number", r.Port))
 }

 if port < 0 || port > 65532 {
  validationErrors = append(validationErrors, fmt.Errorf("invalid port %s: Port must be greater than 0 and lower than 65532", r.Port))
 }

 if r.Action != "allow" && r.Action != "deny" {
  validationErrors = append(validationErrors, fmt.Errorf("invalid action %q: Accepted values are 'allow' or 'deny'", r.Action))
 }

 return validationErrors
}
```

La función *acumula* todos los errores que se producen para una *regla*, que se devuelven como el *slice* `validationErrors`.

Para saber si se han producido errores de validación, comprobamos cuántos elementos contiene el *slice* de errores usando la función `len()`:

> De nuevo, por el momento sólo muestro la regla "inválida" seguida de todas las validaciones fallidas.
> El objetivo es generar un fichero estructurado -como JSON o YAML- con el que proporcionar *feedback* al usuario.

```go
  // ...
  errs := rule.Validate()
  if len(errs) > 0 {
   log.Printf("[RULE] '%s ; %s ; %s ; %s' failed one or more validations:", rule.Protocol, rule.Url, rule.Port, rule.Action)
   for _, e := range errs {
    log.Printf("\t%v", e)
   }
   continue
  }
  fmt.Printf("[ OK ] '%s ; %s ; %s ; %s' is valid\n", rule.Protocol, rule.Url, rule.Port, rule.Action)
 }
```

Si la regla es inválida, se registran (en un *log*, en este caso por `stdout`) todos los campos de la línea y a continuación qué validación (o validaciones) han fallado.

Si la regla es válida, se muestra la regla por `stdout`.

## Testing

A diferencia de lo que hice con el [cliente en Go]({{< ref "221126-cliente-en-go.md" >}}), esta vez estoy escribiendo *tests* **antes** de escribir el código (o lo intento). No me atrevo a llamarlo TDD (*test driven development*), pero la idea de fondo **está ahí** 😉.

```bash
$ go test *.go -v
=== RUN   Test_matchAcceptedValues
=== RUN   Test_matchAcceptedValues/invalid_value
=== RUN   Test_matchAcceptedValues/valid_value
--- PASS: Test_matchAcceptedValues (0.00s)
    --- PASS: Test_matchAcceptedValues/invalid_value (0.00s)
    --- PASS: Test_matchAcceptedValues/valid_value (0.00s)
=== RUN   Test_hasValue
=== RUN   Test_hasValue/parameter_empty
=== RUN   Test_hasValue/parameter_all_whitespace
=== RUN   Test_hasValue/non_empty_parameter
--- PASS: Test_hasValue (0.00s)
    --- PASS: Test_hasValue/parameter_empty (0.00s)
    --- PASS: Test_hasValue/parameter_all_whitespace (0.00s)
    --- PASS: Test_hasValue/non_empty_parameter (0.00s)
=== RUN   Test_NewRule
=== RUN   Test_NewRule/parameter_empty
--- PASS: Test_NewRule (0.00s)
    --- PASS: Test_NewRule/parameter_empty (0.00s)
PASS
ok      command-line-arguments  0.362s
```

## Siguientes pasos

Considero que para acabar el ejercicio me quedan un par de puntos por completar; por un lado, *integrar* la validación de los *strings* obtenidos del CSV al construir una nueva regla a través de la función `NewRule`.

Por otro lado, la salida hacia un fichero en formato JSON o YAML.

Si todo va como está previsto, en dos o tres semanas muchos de los temas *ongoing* estarán resueltos. Habrán acabado de pintar el piso y de poner *parquet*, así que tendré que dejar cosas de un lado a otro al llegar a casa del trabajo... Como le comentaba a un compañero hace unos días, es como hacer una mudanza pero sin ir a ningún lado.

En lo laboral, varias cosas están moviéndose a la vez (en varias direcciones diferentes). De nuevo, en cuestión de un par de semanas algunas cosas (espero) se habrán aclarado 🤞...

Así que podré dedicar más tiempo a seguir aprendiendo Go y otros proyectos personales.
