+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["devcontainer", "go"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/devcontainer.svg"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/
# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/260426/process.png" width="100%" >}}

title=  "devc: Cómo un MVP soluciona el 99% de mis problemas"
date = "2026-05-16T18:24:47+02:00"
+++
La entrada de hoy es sobre algo que, por mucho que me repita día a día, sigue siendo extremadamente difícil de conseguir: centrarse en hacer que las cosas funcionen  **antes** de intentar hacer las cosas *bien*.

Éso es el secreto que, una vez más, me ha llevado a finalizar en unas cuantas horas uno de esos proyectos a los que llevaba días, sino semanas, encallado y dándole vueltas: `devc`.
<!--more-->
Mi fondo de pantalla, como recordatorio diario de ese *mantra*, es la frase de [Addy Osmani](https://addyo.substack.com/p/first-do-it-then-do-it-right-then):

{{< figure src="/images/260516/addy-osmani.jpg" width="100%" >}}

## *copy & paste*: los principios

Soy un gran fan de los *devcontainers*; los uso cada día, tanto para mi trabajo como para mis proyectos personales. Cada nuevo proyecto empieza con la creación de un *devcontainer*.

Al principio, para no crear el *devcontainer* desde cero, buscaba un proyecto similar y copiaba y pegaba la configuración del *devcontainer*.
A medida que iba *refinando* la configuración de los diferentes *devcontainers*, me encontraba con que quizás el repositorio del que iba a copiar la configuración del *devcontainer* no tenía la *última versión*, algún ajuste, la versión correcta de alguna herramienta auxiliar...

De manera que perdía mucho más tiempo del necesario, simplemente, en *empezar* a trabajar.

## `devcontainer.sh`: el *script*

El siguiente paso fue, naturalmente, desarrollar un *script* para automatizar el proceso. La idea germinal ya estaba ahí: tengo apenas un par de configuraciones de *devcontainer* que uso el 99% del tiempo: una basada en una imagen proporcionada por Google y la otra, la imagen de *devcontainer* incluída en VS Code para desarrollar en Go.

Poco a poco, también fui ajustando mi manera de trabajar con *devcontainers*: usar la versión `:latest` de la imagen, un conjunto *básico* de extensiones para VS Code, algunas herramientas extras relacionadas con mi trabajo...

El problema nunca fue que el *script* hiciera lo que quería que hiciese, sino la forma en la que tenía que hacerlo. El problema está en que, en MacOS, la versión instalada de Bash es 3.2.57. Y esta versión tan *antigua* no soporta algunas características de Bash que permiten hacer las cosas de manera más sencilla...

Por tanto, el *script* era, simplemente, demasiado complicado de mantener, ya que cualquier modificación suponía encontrarse con un montón de problemas relacionados con la versión de Bash en MacOS...

## `devc`: una herramienta para gestionar *devcontainers*

El siguiente paso era, como no podía ser de otra manera, desarrollar una herramienta en Go.

El problema es que estoy en proceso de aprendizaje de Go, así que, cada vez que volvía al proyecto, había aprendido algo más e intentaba hacer las cosas "mejor".
El resultado: no era que cayera en la *parálisis por análisis*, sino más bien que empezaba a desarrollar *pasito a pasito* y, en algún momento, me daba con un problema de diseño que me hacía volver a plantearme toda la arquitectura de la aplicación, la manera en cómo se gestionaban las configuraciones de los *devcontainers*...

Además, siendo una *herramienta de apoyo*, siempre ha tenido una *prioridad baja* en mi lista de "cosas que hacer", así que el desarrollo se ha alargado en el tiempo, estando muchas veces al borde del abandono... Éste, imagino, es uno de los peligros de esos *pet projects* que emprendemos en nuestro tiempo libre...

## Primero, hacer que funcione

Ayer estaba dándole vueltas al último problema que había encontrado: cómo gestionar de manera sencilla los *scripts* que se pueden ejecutar como respuesta a los eventos del ciclo de vida del contenedor, por ejemplo, en el  `postpostCreateCommand`... Y no sólo el *script* asociado, sino también los ficheros auxiliares que puede necesitar el *devcontainer*, los *mounts*, etc...

Analizando mis casos de uso, como he dicho, el 99% de mis necesidades las puedo cubrir con **dos** configuraciones de `devcontainer`. Así que me centré en hacer que la aplicación cubriera ésos dos casos de uso (y nada más). Si el problema era cómo gestionar esos ficheros auxiliares, ¿cómo podría evitarlo? Y la respuesta fue incrustándolos en la propia aplicación.

Inicialmente había pensado en copiar el contenido de los ficheros, tal cual, en un `string` (o en `[]byte`) para poder crear los ficheros con el comando `init` de la aplicación... Después recordé que, desde Go 1.16 si no recuerdo mal, Go incluye el paquete [embed](https://pkg.go.dev/embed), que permite hacer exactamente lo que estaba pensado.

No es la mejor solución, por supuesto; cualquier cambio en esos ficheros "de referencia" requeriría recompilar la aplicación de nuevo... Pero guiado por esa idea de *primero, hacer que funcione*, seguí adelante...

Empecé con un repositorio nuevo, sin aprovechar nada de lo que había estado desarrollando en versiones -inacabadas- anteriores. Primero, pruebas de concepto para entender cómo funciona el paquete `embed`; luego, poco a poco, avanzando hacia esa idea de tener las configuraciones de referencia *incrustadas* directamente en el binario de la aplicación.

## Prueba de concepto en un par de horas

Casi sin darme cuenta fui capaz de obtener el contenido de los ficheros de una de las configuraciones de referencia y sacarlo por pantalla. Después, volcarlo a un fichero. El siguiente paso, asegurarse de crear la carpeta `.devcontainer` y colocar los ficheros en ella.

En ese momento, ¡ya podía crear un *devcontainer*! Todo estaba *hardcodeado* en el código, pero los siguientes cambios eran sencillos. Añadir un *flag* para especificar cuál de las dos configuraciones de *devcontainer* quería usar... De nuevo, foco en hacer que funcione (usando el paquete `flag`, nada de `cobra`).

Y antes de volver a casa de la biblioteca ya tenía resuelto el problema con el que me he estado *peleando* durante semanas.

A partir de ahí, cambios menores: mejor gestión de errores, crear un `Makefile` para que sea sencillo *reconstruir* la aplicación si necesito hacer cambios en alguno de los ficheros *incrustados* en el código... Y la inclusión de un número de versión para poder controlar los cambios que sin duda iré introduciendo.

## Funciona

Después de la cantidad de *re-escrituras* por los que ha pasado la aplicación durante las semanas anteriores, me ha sorprendido que, en cuestión de horas, haya conseguido una aplicación funcional. Una aplicación que me permite generar las dos configuraciones de *devcontainer* que utilizo el 99% del tiempo.

Y sí, no es flexible, tiene muchas carencias... pero ¡funciona!

Y si estoy escribiendo este artículo es porque, como funciona, porque como hace lo que necesito que haga, no tengo que invertir más tiempo en *refinar* la aplicación si no quiero, si no tengo una nueva necesidad que no cubra ahora mismo. Tengo la libertar de probar cosas: modularizar la aplicación, usar Cobra... lo que quiera. Y si el experimento no sale adelante, no pasa nada; porque sé que, si necesito crear un nuevo *devcontainer*, seré capaz de crearlo con la aplicación tal y como está ahora. Aunque no sea perfecta.

Podré usar `devc` para crear *devcontainers* **precisamente**, porque no es perfecta; pero **funciona**.

Y eso es lo más importante.
