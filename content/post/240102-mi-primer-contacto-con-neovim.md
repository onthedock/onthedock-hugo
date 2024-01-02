+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["neovim", "vscode"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/vscode.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/
# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}

title=  "Mi primer contacto con Neovim"
date = "2024-01-02T18:58:02+01:00"
+++
Durante estos pasados días de vacaciones por Navidad han confluido varias *casualidades* que me han hecho probar, por primera vez, [Neovim](https://neovim.io/).

Neovim es un *refactor* de Vim, en el que se han dejado las partes que más le gustan a la comunidad y se han añadido capacidades que lo convierten en un editor moderno, como la *extensibilidad* a través de *plugins*.
<!--more-->
Soy un gran fan de la tendencia a aprender a **exprimir** las herramientas que usas. En cuando a editar texto, Vim siempre ha tenido ese aura de "herramienta avanzada", de concentrar la esencia de Linux de hacer una cosa y hacerla extremadamente bien... El problema es que, parodiando la mítica frase, *con un gran poder, llega una empinada curva de aprendizaje*...

En el pasado he intentado varias veces mejorar en mis conocimientos de Vim... Pero siempre acabo dejándolo porque **todo** resulta *artificioso*. El uso de las teclas `hjkl` proviene de un tiempo en que [los teclados no tenían teclas de cursores](https://catonmat.net/why-vim-uses-hjkl-as-arrow-keys). Pero aunque mayor, no soy tan viejo. Lo mismo sucede con muchas otras teclas: algunas tienen sentido (si piensas en inglés), pero otras son absolutamente *marcianas* y poco coherentes. Por ejemplo, el hecho de que para *copiar* tengas que pensar en [*yank*](https://dictionary.cambridge.org/dictionary/english/yank), cuando tengo grabadas a fuego las combinaciones *Crtl+c, Crtl+v* (o su equivalente en Mac, a las que ya me costó acostumbrarme y a las que me sigo refiriendo como *Ctrl*, aunque se use la tecla *Cmd*)... No sólo es necesario **pensar** en inglés; además, el *layout* del teclado también contribuye a *empinar* todavía un poquito más esa curva de aprendizaje...

Finalmente, no considero que escribir más rápido te convierta en una persona más productiva, o en mejor programador, o lo que sea.. Creo que la diferencia está en la *profundidad* del análisis que se realiza de una situación. Llegar a una solución *simple* no es sencillo, por lo que la mayor parte del esfuerzo se realiza **antes** de empezar a escribir código. Una vez tienes el diseño, el resto es -relativamente- fácil (o se puede encontrar en Google). Y la diferencia entre escribir, moverse por el código más o menos rápido no creo que resulte significativa en cuanto a la calidad del producto final. Ni, tampoco, en la cantidad de tiempo de desarrollo. Al final, depende del grado de *familiaridad* con el editor (y sus combinaciones de teclas, etc).

Pese a todo, seguía sintiendo ese *canto de sirena* de Vim (o su encarnación moderna, Neovim), ya no tanto por el argumento de la *productividad* sino más bien por el de la *velocidad*.

Porque sí que es cierto que, con el Mac del trabajo, abrir VSCode y *hacer cosas* -incluso cuando uso un *devcontainer*- es **muy rápido**. Pero no puedo decir lo mismo cuando hago lo mismo en mi MacBook Air del 2013 (sin *devcontainers*) o en un portátil todavía más antiguo, con Linux, y en el que me gusta *picar código* de vez en cuando.

Como varios de los YouTubers que sigo por temas relacionados con Go usan NeoVim, estos días he notado que me fijaba, con cierta envidia, en lo *rápido* que se abre NeoVim, en lo *rápido* que se mueven entre ficheros, etc...

Cosas del algoritmo de YouTube, han aparecido entre mis *vídeos recomendados* algunos sobre "cómo configurar NeoVim"... Supongo que el "culpable" fue [Neovim configuration for Golang Development (2023)](https://www.youtube.com/watch?v=LbsILONOaiE).

En cualquier caso, he aprovechado estos días de descanso para seguir el tutorial del canal *typecraft*: [Neovim for Newbs. FREE NEOVIM COURSE](https://www.youtube.com/playlist?list=PLsz00TDipIffreIaUNk64KxTIkQaGguqn).

Del curso, debo decir que pese a lo histriónico que puede ser el prensentador/YouTuber en algunos momentos, empieza con una configuración desde cero y va avanzando paso a paso, explicando de manera *lógica* el porqué se necesita -y para qué- cada uno de los *plugins* que va instalando. Empieza con una configuración *monolítica*, en un único archivo, hasta llegar al punto en el que instala un *explorador de ficheros* y entonces, cuando es posible cambiar entre ficheros desde NeoVim, crea un fichero de configuración específico para cada módulo instalado.

Todo iba más o menos bien hasta llegar al momento de tener que instalar el *lsp*, el servidor de lenguajes. Tras instalar a modo de ejemplo el de Lua (el lenguaje usado por NeoVim), decidí apartarme del tutorial oficial para instalar el *lsp* para Go (*gopls*) en vez de el de Javascript, que es el que él instala en el vídeo.

En resumen, *gopls* no se instalaba; el *plugin* que tenía que hacer la instalación (`Mason`, o `mason-lspconfig`) daba un error... Unas búsquedas en Google después encontraba el motivo: en el *devcontainer* donde estaba configurando NeoVim (para no *guarrear* el equipo) no estaba instalado Go.

Así que instalé Go y volví a intentarlo. Esta vez, sí que funcionó y creé un fichero *hello world*. El *lsp* funcionaba correctamente, indicándome que `fmt` era desconocido. Busqué cómo hacer que NeoVim añadiera automáticamente el `import "fmt"` y no fui capaz de encontrarlo. Buscando de nuevo en internet, resultó que es necesario instalar `goimports`, lo que supongo que tiene sentido... Pero al añadirlo a la lista de `ensure_installed` de Mason, se quejaba de que `goimports` no es un *lsp*.

Hoy he vuelto al trabajo y he usado VSCode; de pronto he sido consiciente de que para guardar cambios, sólo tenía que pulsar la *familiar* combinación *Cmd+s*, en vez de `ESC, :w`. Al guardar, el código se formatea automáticamente, sin necesidad de pulsar `ggVG, =`.

Ésto me ha hecho pensar en cómo, editando Go en VSCode, se autoimportan los paquetes necesarios... Instalas la extensión de Go (que instala *gopls*) y desde VSCode se pueden instalar las herramientas auxiliares.

Después de dedicar horas a ver los diferentes vídeos de la *playlist*, de ir documentando el porqué se requiere éste o aquel módulo, probar las diferentes configuraciones, implementarlas, al crear un simple programa del tipo `hello world`, NeoVim no *importa* los paquetes necesarios. Tampoco formatea el código automáticamente (aunque puedo hacerlo *manualmente*) ni muestra documentación de los *símbolos* (al menos en Go; sí que funcionaba para Lua)...

Sí, NeoVim sigue siendo más rápido que VSCode. Pero aprovechando la funcionalidad que ofrece la *command palette* y las combinaciones de teclas, mi sensación es que puedo hacer lo mismo que me gustaría conseguir en NeoVim sin tener que cambiar de editor, sin tener que instalar mil plugins... Y sí, seguro que VSCode tarda más de los [40 o 50ms](https://www.reddit.com/r/neovim/comments/qn1cci/is_your_neovim_still_fast_after_adding_plugins/) que por lo visto, tarda en abrir NeoVim con 50 plugins... Pero probablmente, también es cierto que mi cerebro tarda más que 50ms en recordar que tengo que pulsar `yy` para copiar la línea, en vez de *Ctrl+c* (sí, VSCode copia la línea completa sin tener que seleccionarla antes).

Usar NeoVim ha sido interesante; he practicado y he aprendido algunas cosas nuevas, como el uso de *tabs*, abrir un fichero en un *split panel*, cambiar el *foco* de un panel a otro, etc.

No digo que no vuelva a darle una oportunidad en el futuro a NeoVim pero por ahora, me siento más cómodo con VSCode.

P.S: He colocado el icono de VSCode y no el de NeoVim para la entrada como metáfora de la experiencia NeoVim: ya tenía el icono de VSCode, mientras que el NeoVim tenía que buscarlo, descargarlo y añadirlo al blog para acabar consiguiendo lo mismo ;)
