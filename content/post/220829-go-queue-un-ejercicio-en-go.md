+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["go", "programming"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/go.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/

# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}
# YouTube           {{< youtube w7Ft2ymGmfc >}}
# Gist              {{< gist username 7896402 >}}
# Highlight         {{< highligth language >}}...{{< /highlight >}}
# Twitter           {{< tweet user="SanDiegoZoo" id="1453110110599868418" >}}

title=  "go-queue: Un ejercicio en Go"
date = "2022-08-29T20:05:33+02:00"
+++
Hace unos días leía en el foro de Kubernetes el caso de un usuario que no tenía claro cómo hacer que su aplicación fuera escalable, ya que al llegar a un determinado nivel de carga, la aplicación se saturaba.

El problema, por lo que entendí, es que la aplicación hacía "todo el trabajo": recibía las peticiones de los usuarios, gestionaba las acciones para procesar cada petición y devolvía el resultado a los usuarios una vez finalizado.

Una solución rápida podría ser desplegar un [*horizontal pod autoscaler*](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/), pero probablemente lo ideal sería cambiar la arquitectura de la aplicación...

Así que me puse a ello en mi lenguaje de programación favorito: Go ;)
<!--more-->

En primer lugar, lo ideal sería dividir la aplicación en varios componentes, cada uno con una responsabilidad limitada. Por un lado, un componente encargado de recibir las peticiones de los usuarios, con los datos para realizar el trabajo.

Por otro lado, una componente que pueda escalar horizontalmente, lanzando una instancia para cada "job".

En la descripción del usuario no quedaba claro si la devolución del resultado del *job* se devolvía al usuario como resultado de la petición o si se devolvía en una petición posterior.

## `go-queue` propuesta de solución

El objetivo -a parte de aprender un poco de Go- era dividir el problema en diferentes componentes, cada uno con una responsabilidad focalizada.

- `apiserver` Recibe las peticiones de los usuarios.
- `processor` Procesa las entradas de los usuarios y *hace algo* con ellas.
- `cleaner` Elimina los *jobs* completados pasado un cierto tiempo.

## Componentes

### API Server

Si los usuarios envían datos para procesar, asumo que lo que *haya que hacer con ellos* llevará un determinado tiempo o requerirá determinados recursos, que pueden no estar disponibles en un momento dado. Por tanto, creo que lo ideal es devolver un *ticket* al usuario con el número del *job*. El *job* se coloca en una cola y uno (o varios) *worker* los van procesando.  

El usuario puede usar el *ticket* para consultar el estado del *job* y descargar el resultado.

Para simplificar, el usuario envía dos números para los que quiere obtener su suma. El mismo sistema podría usarse para subir una foto y aplicarle un filtro, o [pedirle a una IA que genere una imagen a partir de un texto](https://openai.com/dall-e-2/#demos)...

Como *cola* para los trabajos, decidí usar ficheros de texto. ¿Por qué? Pues porque ya había usado SQLite con Go y no ficheros de texto :D

### Processor

Aunque inicialmente había pensado en usar *go routines* para lanzar los "jobs", he empezado por algo más simple: dado que la suma de dos números no va a llevar demasiado tiempo, no hay ningún problema en esperar a que acabe un *job* para procesar el siguiente...

### Cleaner

Inicialmente había pensado en que el resultado de un *job* se eliminara cuando el usuario lo recupere. Pero me pareció una mala idea para un escenario "real", ya que es posible que el usuario decida no recuperar nunca el resultado de su *job* o que quiera recuperarlo varias veces... Además, de alguna manera tendría que comprobar que el *job* se había completado y no que todavía estaba pendiente en la cola por algún motivo...

## API Server: *endpoints*

El API Server debe exponer dos *endpoints*:

- POST: `/api/v1/add/:num1/:num2` Envía los dos números que quiere sumar
- GET: `/api/v1/job/:jobId` Comprueba el resultado del *job*

Cuando se reciben dos números a sumar, se genera UUID para identificar el *job*. El API Server genera un fichero JSON con extensión `.pending` que contiene:

- `jobId` un identificador único para el *job*
- `num1` y `num2`: los datos de entrada
- `result` el resultado (0, inicialmente)
- la fecha de creación del *job* y cúando fue actualizado por última vez (Quería probar a usar fechas en Go)

Cuando se ha creado el fichero, se devuelve el identificador del *job* como respuesta a la petición del usuario.

Con este *jobId* el usuario puede consultar el estado del *job*. El API server obtiene el resultado del fichero `.json` y lo devuelve al usuario. Si el *job* no se ha procesado, de momento se devuelve un *Internal Server Error*; no es lo más adecuado y probablemente intente cambiarlo por algo más *amable*...

## Haciendo lo que hay que hacer

El *processor* es un bucle infinito que comprueba si hay ficheros `.pending` y los intenta procesar.

Aquí es donde se encuentra la funcionalidad de la aplicación (la suma de dos números).

Se lee el contenido del fichero, se convierte a un `struct`, se suman los números y escribe el resultado en un fichero `json` (borrando el fichero `.pending`).

Lo más interesante ha sido que he estado leyendo en cómo generar un bucle infinito que responda a las señales del sistema (un *control+C* o el apagado del *pod*).

También ha sido interesante cómo convertir el contenido de un fichero JSON en un `struct` o cómo obtener los ficheros `.pending` de una carpeta...

La idea era usar *go routines*, para que el *procesado* de un *job* no interrumpiera la de otros *jobs*, pero lo dejo para el próximo *sprint* ;)

De momento, lo que hice fue usar el paquete `flags` para personalizar cada cuántos segundos se revisan los ficheros `.pending` (por defecto, cada 2s).

## Eliminar ficheros pasado un tiempo

*Cleaner* todavía no existe; pero la idea es seguir practicando con las fechas y el acceso a los ficheros. *Cleaner* también será un bucle infinito enfocado en leer los ficheros `.json`. Comparará la fecha de `LastUpdated` en el fichero con la fecha actual y borrará el fichero si se supera un determinado periodo (definido por el administrador de la aplicación).

En el mundo real esto evitaría que se acumularan *jobs* ya finalizados o no reclamados por el usuario.

## Diagrama

El código está en el repositorio [onthedock/go-queue](https://github.com/onthedock/go-queue).

El siguiente diagrama muestra los diferentes componentes:

{{< figure src="/images/220829/go-queue.svg" width="100%" >}}

## Conclusión

Al margen de la utilidad de la aplicacion en sí, la realización de un proyecto (sin seguir una guía) me ha permitido aprender un montón de *pequeñas cosas*: cómo generar varios binarios dentro de la misma aplicación, por ejemplo, o el uso de `make` (para compilar la aplicación una y otra vez)...

El uso de la carpeta `cmd/` era una de esas cosas que no entendía para qué servía por mucho que leyera sobre ello...

También he estado leyendo sobre cómo organizar el código en el proyecto y me ha sorprendido encontrar que no hay ninguna posición oficial... La opción pragmática es empezar con todo en un mismo *package* y sólo crear paquetes adicionales cuando empieza a ser necesario reutilizar cosas...

De momento, muy contento con la experiencia.
