+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "bitwarden"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/bitwarden.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/

# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}
# YouTube           {{< youtube w7Ft2ymGmfc >}}
# Gist              {{< gist username 7896402 >}}
# Highlight         {{< highligth language >}}...{{< /highlight >}}
# Twitter           {{< tweet user="SanDiegoZoo" id="1453110110599868418" >}}

title=  "Bitwarden Cli"
date = "2022-03-20T19:44:20+01:00"
+++
Hoy en día es **obligatorio** usar un gestor de contraseñas. En mi caso, uso [Bitwarden](https://bitwarden.com/) (la [edición *Personal*](https://bitwarden.com/pricing/)).

Como cada vez paso más tiempo en la línea de comando, he decido probar la [versión CLI](https://bitwarden.com/help/cli/) de Bitwarden.
<!--more-->

## Instalación

`bw` (el nombre del *cliente* para línea de comandos de Bitwarden) es un binario sin dependencias external. La *instalación* es tan sencilla como seleccionar la plataforma, descargar el paquete comprimido y extraer `bw` a una carpeta incluida en el `PATH`.

```bash
$ wget https://vault.bitwarden.com/download/\?app\=cli\&platform\=linux -O bw.zip
--2022-03-20 19:56:06--  https://vault.bitwarden.com/download/?app=cli&platform=linux
Resolving vault.bitwarden.com (vault.bitwarden.com)... 104.18.12.33, 104.18.13.33, 2606:4700::6812:d21, ...
Connecting to vault.bitwarden.com (vault.bitwarden.com)|104.18.12.33|:443... connected.
HTTP request sent, awaiting response... 302 Found
Location: https://github.com/bitwarden/cli/releases/download/v1.22.0/bw-linux-1.22.0.zip [following]
--2022-03-20 19:56:06--  https://github.com/bitwarden/cli/releases/download/v1.22.0/bw-linux-1.22.0.zip
Resolving github.com (github.com)... 140.82.121.4
Connecting to github.com (github.com)|140.82.121.4|:443... connected.
HTTP request sent, awaiting response... 302 Found
Location: https://objects.githubusercontent.com/... [following]
--2022-03-20 19:56:06--  https://objects.githubusercontent.com/...
Resolving objects.githubusercontent.com (objects.githubusercontent.com)... 185.199.111.133, 185.199.108.133, 185.199.110.133, ...
Connecting to objects.githubusercontent.com (objects.githubusercontent.com)|185.199.111.133|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 24459063 (23M) [application/octet-stream]
Saving to: ‘bw.zip’

bw.zip                    100%[====================================>]  23,33M  2,93MB/s    in 8,4s    

2022-03-20 19:56:15 (2,77 MB/s) - ‘bw.zip’ saved [24459063/24459063]
```

Extraemos:

```bash
$ unzip bw.zip 
Archive:  bw.zip
  inflating: bw
```

Lo convertimos en ejecutable:

```bash
chmod +x bw
```

Finalmente, lo movemos a `/usr/local/bin/`:

```bash
sudo mv bw /usr/local/bin
```

Y validamos que se ha instalado correctamente:

```bash
$ bw --version
1.22.0
```

## Inicio de sesión y desbloqueo del *vault*

Lo más *directo* es iniciar sesión usando la dirección de correo y la contraseña de acceso a `vault.bitwarden.com`. Esta suele ser la opción elegida al usar `bw` de forma *interactiva*, pero échale un vistazo a [Log in - Using an API Key](https://bitwarden.com/help/cli/#using-an-api-key) si quieres usar Bitwarden como *backend* desde el que obtener información sensible en tus *scripts* o aplicaciones.

```bash
$ bw login 
? Email address: username@example.org
? Master password: [hidden]
You are logged in!

To unlock your vault, set your session key to the `BW_SESSION` environment variable. ex:
$ export BW_SESSION="EXAMPLE_eDxBGxfPR[ ... ]dQT8XJomwd52Upg3iXcBcdqyW1w=="
> $env:BW_SESSION="EXAMPLE_eDxBGxfPR[ ... ]dQT8XJomwd52Upg3iXcBcdqyW1w=="

You can also pass the session key to any command with the `--session` option. ex:
$ bw list items --session EXAMPLE_eDxBGxfPR[ ... ]dQT8XJomwd52Upg3iXcBcdqyW1w==
```

Como ves, al iniciar sesión con éxito, se te proporciona información sobre cómo *desbloquear* tu *vault* para poder consultar tus contraseñas.

## Obtención de una contraseña

En principio, este es el principal caso de uso de un gestor de contraseñas, obtener el *password* asociado a un *login*.

El comando es:

```bash
$ bw get password NOMBRE_USUARIO
Sup3rS3cr3tP@55w0rD # Not my actual password ;)
```

*So far, so good*...

¿Qué pasa si el *login* está asociado a más de un servicio/cuenta? Como es muy habitual que el nombre de usuario de los servicios sea la dirección de correo, en este caso:

```bash
$ bw get password multiple@example.org
More than one result was found. Try getting a specific object by `id` instead. The following objects were found:
8de07a94-3d83-1234-1234-ac9701043a14
1223daea-8fbd-1234-1234-adf4005bf251
222b59c6-10ac-1234-1234-ac9701615366
3ef030a0-805a-1234-1234-ac9700e76b85
d675b1ef-a075-1234-1234-ae4f006ef572
56ba10e6-dfa7-1234-1234-aca200a8837c
2e1dc1e0-b999-1234-1234-ac9700dcaa3a
```

*WTF?!*

Curiosamente, no podemos filtrar -por lo que sé- usando el valor el campo `Name`, que sería lo que nos podría ayudar a identificar fácilmente en qué servicio, al menos directamente...

La "solución" que he encontrado es un poco *macgyvera*; aunque funciona.

En primer lugar, usamos el subcomando [`list`](https://bitwarden.com/help/cli/#list) para buscar *items* mediante `--search` con el contenido del nombre definido para el elemento en el que estamos interesados. Siguiendo con el ejemplo anterior:

> `bw list` devuelve un objeto JSON.

```bash
$ bw list items --search multiple@example.org | jq '. | length'
7
```

Sin embargo, cada una de estas entradas -que comparte el nombre de usuario- las identifico mediante un **nombre** único en Bitwarden. Por tanto, en el argumento `--search`, uso el contenido del campo **nombre** (de forma completa o parcial):

```bash
$ bw list items --search 'NOMBRE_ENTRADA' | jq '. | length'
1
```

Afortunadamente, `bw` busca el contenido especificado en `--search` ignorando si se trata de mayúsculas o minúsculas y aunque la coincidencia sea parcial.

El resultado devuelto por `bw list items` es un *array*, por lo que para obtener el contenido del campo `id`, debemos referencia el primer elemento del array:

```bash
$ bw list items --search 'NOMBRE_ENTRADA' | jq '.[0].id'
"2e1dc1e0-b999-1234-1234-ac9700dcaa3a"
```

El resultado, como se observa, está *entrecomillado*; si intentamos usar este valor directamente en `bw get password`:

```bash
$ bw get password $(bw list items --search 'NOMBRE_ENTRADA' | jq '.[0].id')        
Not found.
```

*WTF?! (again)*.

La solución es pasar el resultado en formato `raw`, pasando la opción `-r` a `jq`:

```bash
$ bw get password $(bw list items --search 'NOMBRE_ENTRADA' | jq -r '.[0].id')        
Sup3rS3cr3tP@55w0rD # Not my actual password ;)
```

## *Workaround*: crear una *function*

Podemos definir una función en la línea de comando:

```bash
function bwpass { bw get password $(bw list items --search "$1" | jq -r '.[0].id'); }
```

Y después llamarla como si fuera un comando nativo más:

```bash
$ bwpass 'NOMBRE_ENTRADA'
Sup3rS3cr3tP@55w0rD # Not my actual password ;)
```

## Conclusión

Disponer de acceso a un almacén de información sensible desde la línea de comando (tanto de forma interactiva como desde un *script* o aplicación) es la mejor forma de evitar *hardcodear* contraseñas en el código. Esto puede llevar a exponer la contraseña de forma inadvertida al subir código a un repositorio público, comprometiendo la seguridad de la aplicación.

En el caso de BitWarden, la utilidad de la aplicación en uno de los casos de uso más habituales está limitada al no poder filtrar para obtener (`bw get`) la contraseña asociada a un *login*. Es especialmente sorprendente cuando la funcionalidad sí que está disponible para otros comandos (como `bw list`).

Se puede *apañar* mediante una solución alternativa -por ejemplo, usando una función en Bash-, pero no dejo de pensar que debería ser una función integrada en la propia aplicación.
