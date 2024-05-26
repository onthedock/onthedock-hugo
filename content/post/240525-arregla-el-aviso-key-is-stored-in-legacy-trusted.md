+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "ubuntu"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/linux.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/
# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}

title=  "Arregla el aviso 'key is stored in legacy trusted.gpg keyring'"
date = "2024-05-25T10:58:33+02:00"
+++
Al intentar actualizar la máquina en la que el otro día instalé Docker (usando Ansible), me he encontrado con el error `key is stored in legacy trusted.gpg keyring`.

En este artículo explico cómo lo he solucionado.
<!--more-->

En primer lugar, el problema aparece porque parece que ahora, lo recomendado es usar un fichero para cada `key` en `/etc/apt/trusted.gpg.d/`, y resulta que la `key` para autenticar el repositorio de Docker está guardada en `/etc/apt/trusted.gpg`.

Aunque sólo es un *warning*, el proceso de actualización de paquetes se detiene, por lo que no podía actualizar el sistema.

En mi caso, estaba claro que el problema era el respositorio de paquetes de Docker.
De todas formas, puedes usar:

```console
$ sudo apt-key list
Warning: apt-key is deprecated. Manage keyring files in trusted.gpg.d instead (see apt-key(8)).
/etc/apt/trusted.gpg
---------------------------------
pub   rsa4096 2017-02-22 [SCEA]
      9DC8 5822 9FC7 DD38 854A  E2D8 8D81 803C 0EBF CD88
uid           [ unknown] Docker Release (CE deb) <docker@docker.com>
sub   rsa4096 2017-02-22 [S]
```

En la salida del comando verás las claves que tienes instaladas en el sistema.

En mi caso, la `key` de Docker es la única que se encuentra en `/etc/apt/trusted.gpg` (omito las otras *keys* que ya se encuentran en la carpeta `/etc/apt/trusted.gpg.d/`).

## Exporta la *key*

El primer paso es *exportar* la *key*; para ello, usamos los últimos 8 caracteres que identifican la *key* (eliminando el espacio): `0EBFCD88`.

```console
sudo apt-key export 0EBFCD88 | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/docker.gpg
```

Como ves, el comando anterior exporta la *key* desde el `keyring` `trusted.gpg` y la guarda en el fichero `docker.gpg` en `/etc/apt/trusted.gpg.d/`.

## Elimina la *key* en `/etc/apt/trusted.gpg`

Ahora tenemos la clave (para Docker, en mi caso) en dos *keyrings*: `/etc/apt/trusted.gpg` y en `/etc/apt/trusted.gpg.d/docker.gpg`. Por tanto, si intentas ejecutar la actualización de paquetes, vuelves a recibir el *warning*.

En mi caso, como sólo tengo la clave de Docker en `trusted.gpg`, elimino el fichero.

## Actualiza el sistema

Una vez eliminada la clave en el *keyring* "deprecado", podemos actualizar el sistema sin problemas:

```console
sudo apt update && sudo apt upgrade -y
```
