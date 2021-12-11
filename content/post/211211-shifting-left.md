+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["go", "programming"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/roadmap.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}

title=  "Shifting Left - Aprendiendo a programar en Go"
date = "2021-12-11T21:10:44+01:00"
+++
Dentro del *mundillo* de DevOps, cada vez más y más cosas se definen "**como código**"; *infraestructura como código*, *configuración como código*, *seguridad como código*, etc...

Mi interpretación de esta "filosofía" de "*\* como código*", no sólo se refiere a la **definición** de la infraestructura, seguridad, etc, sino también a la aplicación las mismas herramientas y metodologías que se usan para el código **código**: repositorios de control de versiones, *testing*, integración continua, etc.
<!--more-->
Hasta ahora, me he enfocado principalmente en el despliegue de aplicaciones desarrolladas *por otros*. O dicho de otro modo, los procesos de CI/CD en las que me he enfocado han sido siempre de la parte de infraestructura, tanto a nivel "físico": despliegue de infraestructura cloud, de clústers de Kubernetes o de la capa de definición de aplicaciones sobre Kubernetes (los *manifests*/ficheros YAML).

No es que no se pueda *testear* un fichero YAML, o analizar la definición de las aplicaciones en busca de políticas o configuraciones inseguras de forma automatizada en una *pipeline* de CI/CD; pero mi sensación es que el ecosistema de herramientas y procesos no es tan rico ni maduro como para los lenguajes de programación (Java, NodeJS, etc).

Para desplegar una aplicación *a lo GitOps*, con un repositorio Git para los ficheros YAML o Helm Charts y Flux/ArgoCD, es suficiente. Para una aplicación en Java, es necesario realizar análisis estático de calidad de código, de seguridad, compilar, realizar tests unitarios y funcionales... Y después *containerizarlo* todo para poder desplegar en Kubernetes.

No soy un desarrollador, pero sí que he escrito "código" (no me atrevo a llamarlo aplicaciones): funciones Lambda (en Python), scripts (Python/BASH)...

Python no requiere compilación; además, los scripts que he desarrollado generalmente no tienen la complejidad necesaria para organizar el código en módulos o paquetes reutilizables.

Mi "yo perfeccionista" siempre lo ha considerado una *espinita clavada*, pero cuando he intentado aprender cómo organizar o testear el código , me he perdido entre un mar de opciones y tutoriales sesgados...

Como muestra (del sitio [Real Python](https://realpython.com/), en [Getting Started with Testing in Python](https://realpython.com/python-testing/)):

> Choosing the best test runner for your requirements and level of experience is important.

Pero ahí está precisamente el problema, que debido a mi falta de experiencia, no dispongo de los conocimientos para elegir cuál es el sistema de *testing* adecuado...

Lo mismo sucede (en mi opinión) con la organización del código; hasta donde sé, hay **tres** formas de importar un módulo, y hacerlo de una manera u otra parece un tema de preferencias personales...

Al margen de estos problemas, que pueden ser consecuencia de mi desconocimiento, Python es un lenguaje interpretado y de cara a conocer las herramientas de una *pipeline* de CI/CD, considero que no es la mejor opción.

## ¿Porqué Go?

La mayoría de las herramientas del ecosistema de Kubernetes (incluído Kubernetes) se desarrollan en Go. Esa es sin duda la razón de mayor peso a la hora de lanzarme a aprender Go.

Una de las primeras cosas que he notado, especialmente viniendo de Python o Bash, es el tema de tener que definir el tipo de las variables. La falta de *flexibilidad* (en Python el propio intérprete selecciona el tipo conveniente) que al principio me irritaba, se está convirtiendo en una de las cosas que más valoro **como novato**: el IDE -con las correspondientes extensiones/*plugins*- se encarga de resaltar el código, proporciona información de los tipos requeridos para las funciones, de los errores en las asignaciones, etc.

Al usar por primera vez una funcionalidad de un *package*, se importa automáticamente; y si se modifica el código y se prescinde de la utilidad que lo requiere, el *import* se elimina. Y sólo hay una manera (hasta donde sé) de importar y usar los paquetes.

Algo parecido pasa con el formateo del código; en Go hay una forma *estándar* de formatear el código, se usan *tabs* (y no espacios), se alinean verticalmente los `=` en un *struct*, etc...

La biblioteca estándar incluye todo lo que necesito (al menos, de momento). La gestión de *flags* para aplicaciones de línea de comandos, el paquete `net/http`, etc...

En general, la sensación que tengo es que hay cierta *homogeneidad* que facilita, una vez revisados los conceptos básicos, progresar - no diré que rápidamente- , pero sí con confianza de que los pasos son en la dirección correcta; no dependen de que un determinado paquete o *framework* haga las cosas de cierta manera que sólo son válidas para ese paquete o *framework* concreto.

## Formación, documentación y tutoriales

Uno de los problemas - de nuevo, es una opinión personal - que tengo con los tutoriales e incluso con los cursos de plataformas como PluralSight o Coursera es que o son muy sencillos/básicos, o se enfocan en un resolver un escenario muy concreto.

Por ser justo **todo lo contrario**, quiero destacar **muy positivamente** [Gophercises](https://gophercises.com/) de Jon Calhoun.

{{< figure src="/images/211211/gophercises_logo.png" width="100%" >}}

De momento sólo he realizado el primer *gophercicio*, pero debo decir que es **el primer curso de programación que he realizado en el que siento que aprendo**.

Los vídeos están disponibles en YouTube [*playlist* de Gophercises](https://www.youtube.com/watch?v=s1wC1IvwvxE&list=PLVEltXlEeWglGINo25GxVfvSSylLVg4r1), si no quieres registrarte en [Gophercises](https://gophercises.com/) (es gratuito).

A diferencia de otros cursos, en los que el autor hace las cosas y no queda muy claro porqué se hace de esa manera y no de otra, en el caso de Jon el enfoque es completamente diferente: se plantea un problema y se va resolviendo *sobre la marcha*, por decirlo de alguna manera. Él mismo reconoce que seguramente, el código resultante no es el más refinado, sino que se concentra en hacer que funcione. Más adelante, se puede *refactorizar*, *puliendo* progresivamente más adelante.

Este es el proceso habitual en el mundo del desarrollo de software; sin embargo, en los cursos generalmente se presenta una forma *final*, saltándose todos los pasos (y decisiones) intermedias, como en el famoso *meme*:

{{< figure src="/images/211211/how_to_draw_an_owl.jpg" width="100%" >}}

Otro punto **excepcional** es que en el repositorio en GitHub [Gophercises](https://github.com/gophercises) se incluye una carpeta `students/` con las soluciones de los alumnos que realizaron el curso. Esto permite **ver y comparar diferentes maneras de resolver el mismo problema**.  

La idea de Jon era realizar vídeos adicionales revisando el código y comentando esas diferentes soluciones (aunque no se si llegó a hacerlo).

En las próximas entradas espero comentar los avances con mi incursión en el mundo de la programación en Go.
