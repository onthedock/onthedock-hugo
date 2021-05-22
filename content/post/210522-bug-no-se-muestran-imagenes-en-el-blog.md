+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["hugo", "blog"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/hugo.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" %}}

title=  "No se muestran imágenes en el blog"
date = "2021-05-22T11:05:22+02:00"
+++
No soy muy fan de insertar imágenes con capturas de pantalla en las entradas que escribo, excepto cuando es estrictamente necesario. Además, por la naturaleza de este blog y los temas que trato, para *ilustrar* es suficiente con copiar y pegar el texto de la consola o del editor de texto. Pero de vez en cuando, es necesario insertar una imagen... Y de pronto, **las imágenes han desaparecido del blog**.

<!--more-->

Hugo, que es el *generador de páginas estáticas* que uso para crear este blog, permite previsualizar las entradas en las que estás trabajando a través de un servidor web local (con el comando `hugo serve -D`, y la opción `-D` para *renderizar* aquellas entradas marcadas como *draft*).

Estaba redactando una entrada acerca de la *Helm Chart* para Gitea y quería mostrar, con una captura de pantalla, el hilo de comentarios del que "surgió" la idea de esa entrada... Sin embargo, la imagen no se mostraba en la previsualización generada por Hugo. Revisando el código web de la página generada, en el lugar donde debería aparecer la etiqueta HTML para insertar la imagen, se muestra:

```html
  <div class="article-body">[... texto de la entrda ...]
<!-- raw HTML omitted -->
<!-- raw HTML omitted -->
<!-- raw HTML omitted -->
<!-- raw HTML omitted -->
<!-- raw HTML omitted -->
<!-- raw HTML omitted --></div>
```

He validado que el [*shortcode*](https://gohugo.io/content-management/shortcodes/) para insertar imágenes fuera correcto, que lo es, y entonces he comparado con entradas anteriores en las que hubiera insertado el *shortcode* para las imágenes... Todo correcto. Sin embargo, las imágenes no aparecen (ni en la previsualización ni, como he comprobado después, en el sitio publicado en GitHub Pages).

## [*Whodunnit?*](https://es.wikipedia.org/wiki/Whodunit)

Como indica la documentación oficial de Hugo, los [Shortcodes](https://gohugo.io/content-management/shortcodes/) son pequeños fragmentos de código que permiten suplir las carencias de Markdown. En el caso del tema "Aglaus", se proporciona un *shortcode* para insertar imágenes.

### Primer sospechoso: AMP (*accelerated mobile pages*)

Al revisar el *shortcode*, como el tema soporta AMP, la etiqueta usada para insertar la imagen es [`<amp-img>`](https://amp.dev/es/documentation/components/amp-img/). Justo esta mañana he leído la noticia de que [Se acabó el yugo de AMP: Google ya no exige su uso para darle trato preferencial en su buscador a las webs que lo implementan](https://www.genbeta.com/actualidad/se-acabo-yugo-amp-google-no-exige-su-uso-para-darle-trato-preferencial-su-buscador-a-webs-que-usan) y he pensado que, quizás, tenía algo que ver...

He modificado el *snippet*, sustituyendo `<amp-img>` por una etiqueta `<img>`, pero el resultado ha sido el mismo: `<!-- raw HTML omitted -->`.

Si el navegador hubiera dejado de soportar la etiqueta, el código fuente de la página mostraría la etiqueta `<amp-img>`, pero el navegador no sabría cómo interpretarla y la omitiría al *renderizar* la página. El hecho de que en el código de la página se muestre `<!-- raw HTML omitted -->`, significa que al generar el HTML, Hugo inserta este texto... ¿Por qué?

## *¡Desenmascarado!*

La respuesta la he encontrado en el foro de soporte de Hugo: [Raw HTML getting omitted in 0.60.0](https://discourse.gohugo.io/t/raw-html-getting-omitted-in-0-60-0/22032). Tal y como se apunta en la respuesta, se realizó un cambio en Hugo que **elimina por defecto la inserción de HTML directamente en Markdown**.

Como se puede ver en la discusión, el problema no es tanto que se modificara esta opción por defecto para mejorar la seguridad, sino que no se muestra ningún tipo de *warning* en la salida de Hugo...

Esto hace que sea difícil identificar que se ha producido un cambio o alteración del código de la página web y que no se detecte el cambio de comportamiento hasta mucho (en mi caso, *muuuuuucho*) después (la discusión es de Noviembre 2019, en la versión 0.60.0 de Hugo). En algún momento actualicé a la versión 0.60.0 y las imágenes dejaron de mostrarse, pero como no las utilizo mucho, parece que nadie se había dado cuenta (incluído yo)...

## Siguientes pasos

Por lo que he visto en la documentación de Hugo, parece que se proporciona un *shortcode* "nativo" para insertar imágenes usando [`figure`](https://gohugo.io/content-management/shortcodes/#figure). Creo que esta es la mejor opción pero tendré que hacer algunas pruebas y después revisar **todas** las entradas del blog.

Otra opción sería la inserción de imágenes diretamente usando Markdown (`![alternative text](/path/to/image)`), que quizás es *más manual* pero también más *portable*.

En cualquier caso, más allá de la correción del *bug* relacionado con las imágenes, quizás sea el momento de revisar a fondo la plantilla del tema [Aglaus](https://github.com/dim0627/hugo_theme_aglaus), que ya no está mantenido y que por tanto puede dar lugar a más problemas como este en el futuro.
