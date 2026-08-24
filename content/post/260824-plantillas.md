+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["golang"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/go.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/
# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/260426/process.png" width="100%" >}}

title=  "Plantillas para problemas recurrentes"
date = "2026-08-24T04:58:05+02:00"
+++
Uno de los motivos por los que el blog ha estado en un estado de semi-abandono durante este tiempo es porque estoy dedicando mucho tiempo a aprender Go.

Voy desarrollando pequeños proyectos que resuelven problemas concretos de mi día a día o relacionados con mi trabajo; así, como tengo un buen conocimiento del problema a resolver, también sé cómo espero que sea "la solución" a desarrollar. De esta forma, aprendo lo que necesito en vez de intentar aprender cosas "porque sí" (como temas de concurrencia).

A medida que voy aprendiendo, *revisito* los proyectos y así, poco a poco, los voy mejorando.
<!--more-->

## Programar es fácil, la arquitectura del software no lo es tanto

Con Go, una de las cosas que he aprendido es que, en cierto modo, es como jugar a ajedrez; aprender los movimientos de las piezas es sencillo, pero **saber jugar** es mucho más complicado.

Aunque mis aplicaciones son todavía bastante sencillas, veo cómo están compuestas de diferentes *bloques*, con funciones específicas, que interaccionan entre sí. El reto que estoy encontrando es cómo mantener esas *partes* independientes entre sí y, a la vez, lograr que se comuniquen de manera "orquestada".

Recientemente, por ejemplo, un compañero del trabajo nos introdujo a la *arquitectura hexagonal* (también llamada de *puertos y adaptadores*), por lo que estuve aprendiendo algo al respecto e intentando aplicar esos conceptos a mis aplicaciones...

## Los mismos problemas, una y otra vez

Mis aplicaciones tienden a ser, en general, aplicaciones de línea de comandos. En ese caso concreto, un problema recurrente es la gestión y *parseo* de los *flags*. La opción más habitual en este caso suele ser usar la biblioteca estándar, con el paquete `flag` o [Cobra](https://cobra.dev/). En el primer caso, si se trata de una aplicación sencilla, es ideal; pero en cuanto quieres introducir subcomandos, flags *cortas* y *largas*, autocompletado en Bash/Zsh, etc, tú eres responsable de desarrollar esas funcionalidades. En el otro extremo tienes Cobra, que incluye todo éso y mucho más *out of the box*, incluída la integración con Viper para gestionar configuraciones en ficheros... Pero a cambio, Cobra impone *su manera de hacer las cosas*, como IMO, el abuso de la función `init()`...

He probado soluciones intermedias, como [urfave/cli](https://cli.urfave.org/), [alecthomas/kong](https://github.com/alecthomas/kong) o [flaggy](https://github.com/integrii/flaggy), pero el problema siempre es el mismo: cada biblioteca viene con su propio *modelo mental* y su forma de hacer las cosas, por lo que al final pierdo más tiempo entiendiendo cómo se supone que hay que hacer algo que no haciéndolo...

## La solución definitiva (?)

He pensado que, como al final el objetivo es aprender, lo que debo hacer es plantear cada una de esas situaciones con las que me encuentro como un *problema*, como cuando iba al colegio.

En el enunciado del problema, se describe qué es lo que se quiere conseguir; la solución del problema describe cómo se ha hecho.

El objetivo es que, todas esas *pruebas* de usar y tirar en las que estoy invirtiendo el tiempo queden recogidas en algún lugar (este blog) y así me sirvan para seguir mi avance (y quizás ayudar a otros).
