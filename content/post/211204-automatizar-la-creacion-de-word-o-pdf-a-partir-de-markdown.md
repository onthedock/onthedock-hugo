+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["documentación", "markdown"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/markdown.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}

title=  "Automatizar la creación de ficheros en formato MS Word o PDF a partir de markdown"
date = "2021-12-04T17:50:30+01:00"
+++
El objetivo inicial del *formato* markdown era simplificar la creación de ficheros HTML, como puede verse en la página [Markdown](https://daringfireball.net/projects/markdown/) del creador del formato:

> Markdown is a text-to-HTML conversion tool for web writers. Markdown allows you to write using an easy-to-read, easy-to-write plain text format, then convert it to structurally valid XHTML (or HTML).

La realidad es que en muchos entornos, sobretodo el empresarial, los entregables deben realizarse en formatos propietarios como MS Word (`.docx`) o en PDF, que no permite la edición.

Gracias a la versatilidad de herramientas como [pandoc](https://pandoc.org/), podemos desarrollar la documentación en un formato *git-friendly* como markdown y generar documentos finales en formato MS Word o PDF.
<!--more-->

## Escenario

Un equipo de proyecto trabaja en implementar un producto o una nueva funcionalidad para un cliente.

Uno de los requisitos contractuales es la entrega de documentación en un formato como MS Word (`.docx`) o PDF.

El equipo de proyecto no quiere renunciar a la posibilidad de trabajar de forma ágil en la generación de la documentación, incluyendo una tarea de validación de la documentación en el *definition of done* de cada una de las historias de usuario en las que trabaja.

El equipo decide usar un formato ligero como markdown para la documentación del proyecto. Esta documentación se compondrá de uno o múltiples ficheros en formato markdown.

Toda la documentación se encuentra en una carpeta llamada `documentation/` (por ejemplo) dentro del repositorio; para simplificar, suponemos que la documentación se encuentra en la misma carpeta (no hay subcarpetas). Los documentos se nombran de acuerdo con las diferentes secciones del documento de referencia entregado por el cliente final; un ejemplo sería:

```bash
documentation/
    |
    ├── 000-cover.md
    ├── 010-section-1.md
    ├── 011-subsection-1.1.md
    └── 020-section-2.md
```

Cómo se organice la documentación no es relevante siempre que los ficheros se ordenen del mismo modo en como deben ser *ensamblados* en el documento final.

El objetivo es disponer de un sistema que permita trabajar en modo *documentación como código*, de forma ágil, sin necesidad de tener que disponer de una *pipeline* dedicada de construcción de la documentación final.

Esta sistema puede ser la solución para un proyecto medio, que deba entregar unos pocos documentos entregables.

## Implementación

> El código del *script* se encuentra en el repositorio de GitHub [`onthedock/build_doc_output`](https://github.com/onthedock/build_doc_output).

La base del *script* es la capacidad de *pandoc* para concatenar diversos ficheros markdown y convertir el resultado al formato deseado.

El *script* lista todos los ficheros con extensión `*.md` en una carpeta dada, los pasa a *pandoc* y genera el fichero final.

```bash
get_source_files(){
       sourceDir="${1}"
       declare -a arrMarkdownFiles
       for mdFile in ${sourceDir}*.md
       do
              arrMarkdownFiles=("${arrMarkdownFiles[@]}" "$mdFile")
       done

       echo "${arrMarkdownFiles[*]}"
}
```

En el *script* de ejemplo, se puede elegir entre generar un fichero en formato MS Word o en formato PDF.

### Documento generado en formato MS Word

En el primer caso (`.docx`), se puede pasar al *script* un fichero de referencia mediante el parámetro `--template-file`. *pandoc* extrae los estilos definidos en el documento de referencia para cada estilo (*Título 1*, *Párrafo*, etc...) y los aplica en el fichero en formato MS Word generado a partir de los ficheros en formato markdown.

Esta capacidad permite generar un documento entregable que se ajuste a la identidad corporativa del cliente final.

*pandoc* permite generar una *tabla de contenidos* de forma automática en base a los títulos de cada sección, subsección, etc.

> Existe un *bug* por el que, aunque la tabla de contenidos se genera, no se encuentra actualizada y es necesario *refrescarla* manualmente al abrir el documento MS Word resultante.

### Documento generado en formato PDF

Para generar un documento PDF en Linux usando pandoc, es necesario tener instalado un *LaTeX engine* (como [TeX live](https://www.tug.org/texlive/)).

Las opciones para configurar el PDF resultante se pueden consultar en el manual de pandoc [Variables for LaTeX](https://pandoc.org/MANUAL.html#variables-for-latex).

En el *script*, como prueba de concepto, se ha configurado la tabla de contenidos para generar enlaces a las secciones del PDF resultante (coloreando [los enlaces de azul](https://blog.mozilla.org/en/internet-culture/deep-dives/why-are-hyperlinks-blue/) ;) ).

También se incluye una opción que evita que el *LaTeX engine* interprete las *contrabarras* `\` [como caracteres de escape](https://en.wikibooks.org/wiki/LaTeX/Special_Characters), lo que puede generar errores al procesar los ficheros en formato markdown (en los que las `\` no tienen ningún sinificado especial):

```bash
pdfOptions="... -f markdown-raw_tex"
```

## Inclusión del *script* en un proyecto existente

Si la documentación de proyecto (los ficheros en formato markdown) están en un repositorio git, se puede incluir el repositorio [onthedock/build_doc_output](https://github.com/onthedock/build_doc_output) como un [submódulo](https://git-scm.com/book/en/v2/Git-Tools-Submodules) de Git:

```bash
git submodule add https://github.com/onthedock/build_doc_output build
```

Con lo que el proyecto quedaría:

```bash
documentation/
    .
    ├── build
    │   ├── build_ouput.sh
    │   └── readme.md
    ├── 000-cover.md
    ├── 010-section-1.md
    ├── 011-subsection-1.1.md
    └── 020-section-2.md
```

Se puede crear un [*githook*](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks) de manera que tras cada *push* al repositorio, se genere una nueva versión del documento final, por ejemplo.

### Usar *git log* para generar una *tabla de control de cambios*

Al disponer de un sistema de control de cambios usando por todo el equipo de proyecto, podemos usar la información contenida en la historia del repositorio como base de la sección de *Control de cambios* de la documentación generada.

En el *script*, como prueba de concepto, se genera una tabla que contiene los últimos diez cambios en el repositorio en forma de tabla, junto con el *commitID* y el autor del *commit*.

```bash
create_changelog(){
       changeLogFileName="${1}"
       echo "## Changelog (last 10 changes)" > ${changeLogFileName}
       echo "" >> ${changeLogFileName}
       echo "| CommitID | Author | Commit Msg |" >> ${changeLogFileName}
       echo "| --- | --- | --- |" >> ${changeLogFileName}
       git log -10 --pretty=format:'| %h | %an | %s |' >> ${changeLogFileName}
}
```

Las opciones de configuración de la salida de *git log* pueden consultarse en [Pretty formats](https://git-scm.com/docs/pretty-formats) o en [git log](https://git-scm.com/docs/git-log) en la documentación oficial de Git.

## Conclusión

Para usar *documentación como código* no es necesario disponer de una *pipeline* compleja con la que automatizar el proceso de generación de la documentación con cada *commit*.

Incluso en los escenarios más sencillos, con un número de personas y herramientas reducido, es posible beneficiarse del concepto de *documentación cómo código*, generando documentación de manera ágil, de acuerdo con los requerimientos de prácticamente cualquier cliente, sin necesidad de alterar el flujo de trabajo habitual del equipo de desarrollo.
