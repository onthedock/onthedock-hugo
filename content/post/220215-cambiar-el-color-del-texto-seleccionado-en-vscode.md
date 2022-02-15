+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["vscode"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/vscode.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/

# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}
# YouTube           {{< youtube w7Ft2ymGmfc >}}
# Gist              {{< gist username 7896402 >}}
# Highlight         {{< highligth language >}}...{{< /highlight >}}
# Twitter           {{< tweet user="SanDiegoZoo" id="1453110110599868418" >}}

title=  "Cambiar el color del texto seleccionado en Visual Studio Code"
date = "2022-02-15T18:37:47+01:00"
+++
En VSCode, cuando colocas el cursor sobre una palabra o para ser más exactos, sobre un "bloque de texto delimitado por espacios", toda la palabra se *destaca* con un fondo de color más claro (en un tema oscuro).

El color del fondo es el mismo tanto si el todo el texto de la palabra está seleccionado como si *simplemente* el cursor está en alguna posición entre el principio y el final de la palbra, lo que **no es lo mismo**.

En esta entrada, indico cómo modificar el texto del *resaltado* que hace Visual Studio Code cuando **seleccionamos** una palabra o bloque de texto.
<!--more-->
## TL;DR

Para mi yo futuro, cuando reinstale VSCode y sólo venga a esta entrada en busca de la configuración:

1. Abre la configuración de VSCode (`Ctrl/Cmd` + `,`)
1. Busca `color`
1. En la sección `Editor: Semantic Token Color Customizations`, pulsa sobre el enlace que abre el fichero de configuración `settings.json`
1. Añade al final de la configuración el bloque:

```json
  ...
  "workbench.colorCustomizations": {
      "editor.selectionBackground": "#224422"
  }
```

Esta configuración permite modificar el color del resaltado para el texto seleccionado; en mi caso, un color *verde-amarillento* que combina bien con mi tema preferido del momento en VSCode [Night Owl](https://marketplace.visualstudio.com/items?itemName=sdras.night-owl).

## Motivación

En general, los colores de casi todos los temas que he probado en VSCode proporcionan poco contraste para el texto seleccionado. Y aunque no puedo afirmarlo con seguridad, diría que todos tienen el mismo problema que comentaba: el color de resaltado es el mismo cuando el cursor está *en el texto* que cuando el texto está seleccionado.

En mi caso, como suelo usar VSCode para escribir (por ejemplo, artículos como éste) pero también documentación y otras cosas por el estilo, suelo pasar mucho tiempo *leyendo* lo que he escrito. Esto me permite revisar si lo que *yo tenía en la cabeza* es lo que está finalmente escrito en el texto. A veces, quiero cambiar una palabra, o un párrafo... Suelo hacer *doble click* para seleccionar la palabra completa, de manera que al comenzar a escribir se reemplaza completamente con lo *nuevo* que estoy escribiendo. Sin embargo, a veces no *doble-clickeo* correctamente, o hago un *click* de más... lo que resulta en que la palabra (o línea completa) no se seleccione, sino que el cursor se posicione donde he hecho *click*.

Al final, en vez de sustituirse la palabra, lo que pasa es que escribo la *nueva palabra* "dentro" de la palabra que quería reemplazar. Lo que es un fastidio...

Es la típica cosa que molesta, pero *no lo suficiente* como para dedicar energía a buscar una solución... Hasta que un día te molesta más de lo habitual y entonces sí, te lanzas a Google a buscar cómo acabar con ello de una vez por todas.

Y así, vía Google, di con la solución en [Change highlight text color in Visual Studio Code](https://stackoverflow.com/questions/35926381/change-highlight-text-color-in-visual-studio-code).

La respuesta de Jakub Zawiślak indica cómo modificar ambos colores: el del texto destacado automáticamente cuando el cursor se encuentra en la palabra y el color del texto **seleccionado**, que es el que me interesa.

En la respuesta también se incluye un enlace a la documentación oficial de Visual Studio Code donde tienes todas las opciones de configuración de **todas** las propiedades del editor para la que puedes definir *colorines*: [Editor colors](https://code.visualstudio.com/api/references/theme-color#_editor-colors)

## Otras personalizaciones relacionadas con los colores

### Colorear pares de paréntesis

Desde hace algunas versiones, Visual Studio Code incorpora *de serie* lo que antes requería una extensión: colorear los paréntesis por parejas (cada pareja con un color).

Para ello, busca la opción `Editor > Bracket Pair Colorization` y marca la casilla que habilita el coloreado de los pares de paréntesis, claudátors, etc.

{{< figure src="/images/220215/bracket-colorization.png" width="100%" caption="No hagas caso del 'código' ;)" >}}

Puedes leer sobre las mejoras introducidas en Visual Studio Code 1.60 y los retos relacionados con lo de *emparejar* paréntesis en el blog de Visual Studio Code [Bracket pair colorization 10,000x faster](https://code.visualstudio.com/blogs/2021/09/29/bracket-pair-colorization).

### Guías (horizontales y verticales)

Otra ayuda visual son las *guías* (horizontales y/o verticales) que puede mostrar Visual Studio Code para indicar dentro de qué bloque de código estamos.

Las guías se muestran -atenuadas- indicando dónde empieza y acaba el bloque, y de un color más intenso cuando el cursor se encuentra *dentro* del bloque.

Como en el caso de los paréntesis y otros delimitadores, las guías de los diferentes bloques se muestran en colores diferentes.

Para activarlo, abre la configuración de usuario (`Crtl`/`Cmd` + `,`) y busca "editor guides" para activar las diferentes opciones existentes:

- Activar guías horizontales
- Activar guías verticales
- Resaltar el par de delimitadores *activo*
- Resaltar el nivel de indentación
- Resaltar el nivel de indentación *activo*

{{< figure src="/images/220215/guides.png" width="100%" caption="No hagas caso del 'código' ;)" >}}

## Resumen

En esta entrada has visto cómo modificar el color del texto (seleccionado) en Visual Studio Code.

Además, se muestra cómo configurar otras *ayudas visuales* -como el coloreado de los paréntesis y otros delimitadores- o las *guías* que indican los bloques de código o la indentación de cada bloque.
