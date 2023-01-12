+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "jq", "automation"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/bash.svg"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/

# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}
# YouTube           {{< youtube w7Ft2ymGmfc >}}
# Gist              {{< gist username 7896402 >}}
# Highlight         {{< highligth language >}}...{{< /highlight >}}
# Twitter           {{< tweet user="SanDiegoZoo" id="1453110110599868418" >}}

title=  "Convertir un fichero CSV en JSON usando Jq"
date = "2023-01-11T20:51:00+01:00"
+++
Una de las automatizaciones que hemos desarrollado consiste en un *autoservicio* para que los clientes puedan gestionar políticas en un *proxy*.

El usuario genera un fichero CSV con varios parámetros y los "sube" a un repositorio Git en su proyecto. El evento desencadena la ejecución de una *pipeline* en la que procesamos el fichero, validamos su contenido, etc. Una vez *procesados*, construimos un objeto JSON para cada una de las reglas, las agregamos y finalmente las integramos en el documento de configuración del *proxy* del cliente (que contiene otros campos que el cliente no debe editar).
<!--more-->
## Prueba de concepto

Después de la primera fase de diseño, la implementación de las acciones a realizar hay que pasarla de la pizarra al IDE...

En esta entrada, esbozo una versión simplificada de la solución.

## El fichero proporcionado por el usuario

El fichero en el que el usuario proporciona las reglas a implementar en el *proxy* puede ser algo como:

```csv
tcp,    www.ubuntu.com     , 443, allow
tcp, www.badsite.com, 80, deny
```

> En una de las reglas, hemos introducido espacios adicionales para *simular* cierta *aleatoriedad* que pueda introducir el usuario.

## Solución *quick & dirty* (pero funcional)

Como ejemplo simplificado, el siguiente *script* muestra qué hay que tareas hay que realizar (sin demasiadas *florituras*):

> El *script* no considera el caso de que haya líneas vacías en el fichero de entrada proporcionado por el usuario, que falte alguno de los parámetros requeridos, que los valores sean los apropiados...

```bash
#!/bin/bash
file_name="$1"

while read -r line; do
    # using 'xargs' to strip spaces
    protocol=$(echo "$line" | awk -F ',' '{print $1}' | xargs)
    fqdn=$(echo "$line" | awk -F ',' '{print $2}' | xargs)
    port=$(echo "$line" | awk -F ',' '{print $3}' | xargs)
    action=$(echo "$line" | awk -F ',' '{print $4}' | xargs)

    item=$(jq --null-input \
              --arg action "$action" \
              --arg fqdn "$fqdn" \
              --arg port "$port" \
              --arg protocol "$protocol" '
              {
                "action": $action,
                "fqdn": $fqdn,
                "port": $port,
                "protocol": $protocol
              }')
    ruleset+=$item
done <"$file_name"

echo "$ruleset" | jq --slurp >ruleset.json

jq --argjson rules "$(<ruleset.json)" \
    --arg now "$(date +%s)" \
    '.modified_at = $now | .rules = $rules' url_policies.json
```

El *script* lee línea a línea el fichero proporcionado por el usuario. De cada línea, extrae los diferentes elementos y los asigna a variables.

Usamos Jq para generar el documento JSON que representa la regla expresada en cada una de las líneas del documento del usuario.
Concatenamos todas las reglas, las convertimos en un *array* usando `--slurp` y lo guardamos en un fichero intermedio (`ruleset.json`).

El documento JSON construido a partir de las reglas especficadas por el usuario (`ruleset.json`) es sólo una parte del fichero de configuración del *proxy* (`url_policies.json`). Por tanto, lo que hacemos es *insertar* el *array* de reglas como valor de la propiedad `rules` del documento de configuración del *proxy*.

Para conseguirlo, usamos Jq, pasando el *array* de reglas mediante `--argjson` desde el fichero intermedio (`ruleset.json`); finalmente, insertamos el conjunto de reglas en el fichero de configuración.

Aprovechamos también para insertar el valor del momento en el que se ha modificado la configuración.

El resultado sería algo similar a:

```json
{
  "type": "url_policies",
  "rules": [
    {
      "protocol": "tcp",
      "fqdn": "www.ubuntu.com",
      "port": "443",
      "action": "allow"
    },
    {
      "protocol": "tcp",
      "fqdn": "www.badsite.com",
      "port": "80",
      "action": "deny"
    }
  ],
  "modified_at": "1673475653"
}
```

## Temas a pulir

El principal punto de mejora es la inclusión de validaciones de los datos proporcionados por el usuario... **Siempre, siempre, siempre** hay que validar y *sanitizar* los datos de usuario.

Una par de sencillas mejoras serían la eliminación de líneas duplicadas y de las líneas en blanco.

En el primer caso,  podemos usar el comando `uniq`.

Para el segundo, parace que la mejor opción (que elimina líneas que contienen espacios) es `sed '/^[[:space:]]*$/d'`.

El *script* podría generar un fichero de *log* para aquellas líneas que no contenga alguno de los valores requeridos... O aquellos cuyo valor no se encuentre entre los valores aceptados...

Todo depende de lo robusta que necesitemos que sea la automatización del proceso (o del tiempo del que dispongamos).
