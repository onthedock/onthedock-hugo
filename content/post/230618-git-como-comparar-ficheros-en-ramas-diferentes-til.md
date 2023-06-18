+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["git", "til"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/git.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/

# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}
# YouTube           {{< youtube w7Ft2ymGmfc >}}
# Gist              {{< gist username 7896402 >}}
# Highlight         {{< highligth language >}}...{{< /highlight >}}
# Twitter           {{< tweet user="SanDiegoZoo" id="1453110110599868418" >}}

title=  "Git: Cómo comparar ficheros en ramas diferentes #til"
date = "2023-06-18T07:06:08+02:00"
+++
Imagina que te encuentras en el siguiente escenario: creas un rama y haces cambios en un fichero.

¿Cómo puedes ver qué diferencias hay en el fichero en dos ramas distintas?

La solución es mi #TIL (*today I learn*) de hoy.
<!--more-->

He creado un repositorio; en la rama `main` tengo un fichero `main.go`.

Tengo una segunda rama llamada `dev` en la que el fichero `main.go` ha sido modificado.

```bash
$ git branch
* dev
  main
```

Para ver los cambios en el fichero `main.go` entre las ramas `main` y `dev`:

```bash
$ git diff main dev -- main.go
diff --git a/main.go b/main.go
index 0a1490f..12f25fc 100644
--- a/main.go
+++ b/main.go
@@ -3,5 +3,5 @@ package main
 import "fmt"

 func main(){
-  fmt.Println("Hello World!")
+  fmt.Println("Hello World from On The Dock")
 }
```

No es necesario estar en una de las ramas implicadas en la comparación; podemos realizar la comparación desde cualquier rama.

He creado una rama adicional `experimental`:

```bash
$ git branch
  dev
  experimental
* main
```

En esa rama, se han realizado cambios sobre el fichero `main.go`. Desde la rama `main`, puedo ver qué cambios hay entre el fichero en la rama `dev` y la rama `experimental`:

```bash
$  git diff dev experimental -- main.go
diff --git a/main.go b/main.go
index 12f25fc..319c415 100644
--- a/main.go
+++ b/main.go
@@ -2,6 +2,14 @@ package main

 import "fmt"

+func Greeting(s string) {
+  if s == "" {
+    s = "World!"
+  }
+  fmt.Printf("Hello %s", s)
+}
+
 func main(){
-  fmt.Println("Hello World from On The Dock")
+  Greeting("from the Dock!")
 }
+
```
