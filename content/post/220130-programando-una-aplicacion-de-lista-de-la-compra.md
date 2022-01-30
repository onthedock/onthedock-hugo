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

title=  "Programando en Go: Aplicación de Lista de la compra"
date = "2022-01-30T20:51:49+01:00"
+++
Como comenté hacia el final de la entrada anterior [Aprendiendo a programar en Go... pasito a pasito]({{< ref "220129-aprendiendo-a-programar-en-go-pasito-a-pasito.md" >}}), teniendo la seguridad de los tests me ha dado la confianza de empezar a desarrollar una aplicación a modo de *ejercicio de aprendizaje*.

El objetivo de la aplicación es el de gestionar una *lista de la compra*, aunque esto es sólo una excusa ;)
<!--more-->

El código de la aplicación (aviso, es un *work in pregress*) está en el repositorio [onthedock/go-shoppinglist](https://github.com/onthedock/go-shoppinglist). Voy documentando el proceso paso a paso en el [`readme.md`](https://github.com/onthedock/go-shoppinglist#readme).

La "aplicación" empezó como un ejercicio para poner a prueba el ciclo descrito en [Learn Go with tests](https://quii.gitbook.io/learn-go-with-tests/): crear un test, eliminar los errores de compilación y hacer que el test pase **escribiéndo la cantidad mínima de código** y después refactorizar, con la confianza de tener un test para saber que no rompes nada sin darte cuenta...

Empecé con las funciones para añadir y eliminar elementos de la *lista de la compra* y poco a poco he ido haciendo cambios... Creé los tipos `Item` (para los elementos de la lista) y `ShoppingList` (para la lista en sí). Estos cambios no aportan funcionalidad adicional, pero ayudan a que sea más fácil de entender la aplicación: tiene mucho más sentido `func AddItem(sl ShoppingList, item Item) int` que `func AddItem(sl []string, item string) int`.

Más adelante convertí las funciones en métodos; de nuevo, la idea es *vincular* las funciones que modifican la lista de la compra con el tipo que contiene la lista...

Al disponer de los tests es fácil requerimientos, como el de que no se deben añadir elementos a la lista que ya se encuentren presentes, etc.

Con las funciones de añadir y eliminar elementos de la lista de la compra, he movido las funciones a un *package* y he creado la aplicación que las usa (bueno, sólo imprime los elementos de una lista, de momento).

La experiencia está resultando muy positiva; ceñirme al ciclo de crear el test, hacer que pase y después modificar hace que los pasos que voy dando sean pequeños, pero seguros.

En cuanto a los siguientes pasos, la idea es seguir probando cosas nuevas: quizás usar un `struct` en vez de un *slice* de *strings*, lo que me hará usar punteros... También he pensado en usar un fichero de texto para guardar la lista de la compra y quizás más adelante, una base de datos.

¿Porqué no crear una API y un servidor web para mostrar la lista de la compra en el navegador?

Sólo la imaginación es el límite ;)
