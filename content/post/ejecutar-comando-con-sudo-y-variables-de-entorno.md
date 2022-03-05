+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/linux.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/

# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}
# YouTube           {{< youtube w7Ft2ymGmfc >}}
# Gist              {{< gist username 7896402 >}}
# Highlight         {{< highligth language >}}...{{< /highlight >}}
# Twitter           {{< tweet user="SanDiegoZoo" id="1453110110599868418" >}}

title=  "Ejecutar comando con `sudo` manteniendo las variables de entorno del usuario"
date = "2022-03-05T07:51:02+01:00"
+++
Las variables de entorno se definen para cada usuario; por tanto, para mi usuario `xavi`, puedo configurar la variable `https_proxy` mediante:
<!--more-->
```bash
export https_proxy="https://proxy.ejemplo.org:8080"
```

Sin embargo, cuando ejecuto un comando mediante `sudo`, en realidad lo estoy lanzando como el usuario `root`, y por tanto, este usuario no tiene definidas las mismas variables de entorno que el usuario `xavi`.

Para que al *cambiar de usuario* a `root` el comando tenga acceso a las variables de entornos definidas para el usuario *no-root*, debe usarse el argumento `-E` o `--preserve-env` de `sudo`.

También es posible pasar sólo *algunas* de las variables de entorno al ejecutar el comando con `sudo`; puedes consultar todas las opciones en el manual de [`sudo`](](https://www.sudo.ws/docs/man/1.8.22/sudo.man/#E)).
