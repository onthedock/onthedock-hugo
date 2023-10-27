+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["mac", "apple", "os", "sonoma"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/apple.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/

# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}
# YouTube           {{< youtube w7Ft2ymGmfc >}}
# Gist              {{< gist username 7896402 >}}
# Highlight         {{< highligth language >}}...{{< /highlight >}}
# Twitter           {{< tweet user="SanDiegoZoo" id="1453110110599868418" >}}

title=  "Apple: la decepcionante actualización a Sonoma"
date = "2023-10-27T18:46:34+02:00"
+++
Ayer en el trabajo, *de alguna manera* se nos notificó que teníamos disponible la actualización a Sonoma para el Mac.

He ido actualizando mi Mac personal desde hace más de diez años (sí, todavía uso mi Macbook Air Mid 2013) **sin ningún problema**. Así que que no creía que esta vez fuera diferente. Lo que sí es diferente es que ésta vez el Mac a actualizar el mi "equipo de empresa".

De la actualización en sí fue, como esperaba, no hay nada que destacar... Le di a actualizar y al volver de comer ya estaba todo listo.

A partir de ahí, ha empezado la pesadilla.
<!--more-->

En primer lugar, el sistema se queda "congelado" cada dos por tres sin motivo aparente. Firefox no arranca (y era, hasta ayer, mi navegador predefenido). Después de ir probando diferentes soluciones y encontrar una impresionante cantidad de gente quejándose de los mismos problemas, "refrescar" la instalación de Firefox, etc, me doy por vencido e intento restablecer el equipo a la configuración de fábrica.

Al tratarse de un equipo profesional, las *recovery options* están protegidas por contraseña. Cuando consigo el código del equipo de soporte, la única opción que tengo es la de reinstalar Sonoma, no la de volver a Ventura...

Obviamente, esto no soluciona ninguno de los problemas, ni con Firefox, ni con Finder...

Finder parece que ha vuelto a funcionar de forma relativamente estable al deshabilitar la sincronización de ficheros Outlook en iCloud Drive... Pero no he encontrado solución para los problemas con Firefox.

El problema de Firefox va más allá del uso de la extensión [Multi-Account Containers](https://addons.mozilla.org/en-US/firefox/addon/multi-account-containers/) que me permite cambiar entre diferentes identidades relacionadas con el trabajo con sólo abrir una nueva pestaña; Firefox es el único navegador compatible con el lector de tarjetas que necesito como MFA para acceder a la inmensa totalidad de aplicaciones que uso en mi día a día.

Afortunadamente, además de la "tarjeta física", puedo usar códigos de acceso mediante Google Authenticator. Es un proceso manual, por lo que es más lento y engorroso, pero me permite seguir trabajando.

Para el tema de las identidades, la única solución que he encontrado es la de generar "profiles" en Google Chrome. De nuevo, es mucho más lento que *abrir una nueva pestaña*, pero me permite seguir trabajando. Para distinguir rápidamente qué identidad uso en cada una de las ventanas uso "temas" de colores diferentes.

De momento llevo perdido día y medio. El lunes contactaré con el equipo de soporte para borrar el disco del Mac y realizar el proceso de *enrollment* desde cero, si es posible, y eliminar Sonoma de una vez por todas del equipo.

De lo que me costará más tiempo deshacerme es de la pérdida de confianza en el *buen hacer* de Apple.
