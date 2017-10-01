+++
draft = false

# TAGS
# HW->OS->PRODUCT->specific tag
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["raspberry pi", "linux", "docker"]

# CATEGORIES = "dev" / "ops"
categories = ["dev"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/docker.png"

title=  "Cómo crear una imagen con Caddy y PHP"
date = "2017-09-30T21:36:58+02:00"
+++

En las entradas anteriores he descrito los problemas -tanto conceptuales como técnicos- que he encontrado al intentar llevar Dokuwiki a un contenedor.

En este artículo explico los pasos a seguir para construir una imagen con [Caddy server](https://caddyserver.com/) y PHP, de manera que puedas servir tus aplicaciones PHP usando contenedores.

<!--more-->

Me voy a centrar primero en la creación de una imagen para un equipo con arquitectura x64 y después para una Raspberry Pi (o cualquier otro dispositivo ARM).

> Todos los ficheros están disponibles en el repositorio [onthedock/alpine-caddy-php](https://github.com/onthedock/alpine-caddy-php)

# El fichero Dockerfile

```Dockerfile
FROM alpine:3.6

RUN apk add --no-cache caddy php7 php7-fpm php7-gd \
    php7-session php7-xml php7-openssl php7-zlib

RUN echo "clear_env = no" >> /etc/php7/php7-fpm.conf

RUN chown -R caddy:caddy /var/www /var/log

WORKDIR /var/www

COPY files/Caddyfile /etc/Caddyfile
COPY files/index.html /var/www
COPY files/phpinfo.php /var/www

EXPOSE 2015
USER caddy
ENTRYPOINT ["/usr/sbin/caddy"]
CMD ["--conf", "/etc/Caddyfile"]
```

1. `FROM alpine:3`: indica la imagen base que usaremos para construir nuestra imagen.
1. `RUN apk add ...` comando de instalación de Caddy, PHP7 y las _librerías_ que necesitemos. Para mantener al mínimo el número de librerías, deberías realizar un estudio para cada una de las aplicaciones con las que querrás usar esta imagen para poder incluir todas las que necesitarás. En mi caso, el listado incluye las que he identificado para [Dokuwiki](https://www.dokuwiki.org).
1. `RUN echo "clear_env = no" >> /etc/php7/php7-fpm.con` Permite que PHP-FPM pueda acceder a las variables de entorno.
1. `RUN chown -R caddy:caddy /var/www /var/log` Modificación de los permisos para las carpetas a las que Caddy Server tiene que acceder (usando el usuario `caddy`).
   * El usuario y el grupo `caddy` se crean durante la instalación del paquete de Caddy Server.
1. `WORKDIR /var/www` Se cambia el directorio de trabajo a la carpeta `/var/www`. Caddy Server sirve la carpeta actual si no se especifica ninguna en el fichero `Caddyfile`. Puede omitirse del `Dockerfile` si se especifica en el `Caddyfile`.
1. `COPY files/Caddyfile /etc/Caddyfile` Copia el fichero de configuración de Caddy a contenedor.
1. `COPY files/index.html /var/www` y `COPY files/phpinfo.php /var/www` El fichero `index.html` es el típico fichero indicando que el servidor funciona. En cuanto a `phpinfo.php`, permite validar que PHP funciona; también muestra qué versión se ha instalado y las librerías incluídas. Sólo se muestran si no se _monta_ un volumen sobre `/var/www`.
1. `EXPOSE 2015` El puerto por defecto de Caddy es el 2015, y no el 80 como es habitual en otros servidores web.
1. `USER caddy` Nos deshacemos de los privilegios de `root` y cambiamos al usuario `caddy` (siguiendo las buenas prácticas de seguridad).
1. `ENTRYPOINT ["/usr/sbin/caddy"]` Especificamos el comando por defecto al ejecutar el contenedor.
1. `CMD ["--conf", "/etc/Caddyfile"]` Especificamos el fichero de configuración como un parámetro durante el lanzamiento, por lo que es posible pasar un fichero alternativo u otros parámetros desde `docker run`.

## Fichero Caddyfile

```Dockerfile
0.0.0.0
root /var/www/
gzip
startup php-fpm7

fastcgi / 127.0.0.1:9000 php {
  index index.php
}

log stdout
errors stdout
```

1. `0.0.0.0` Indica en qué dirección IP escucha el servidor; indicamos todas las existentes. Ésta es la opción por defecto desde este _commit_:  [Default host is now 0.0.0.0 (wildcard)](https://github.com/mholt/caddy/commit/3bc4e84ed3b2adcedd71e661e305c2394d41fc86), después de ver que es más [_docker friendly_](https://github.com/mholt/caddy/issues/28).
1. `root /var/www` [root](https://caddyserver.com/docs/root) indica cuál es la raíz del _site_ para Caddy.
1. `gzip` Habilita la compresión si el cliente lo soporta. [Ver gzip doc](https://caddyserver.com/docs/gzip)
1. `startup php-fpm` [startup](https://caddyserver.com/docs/startup) ejecuta un comando cuando Caddy arranca. En este caso, arranca `php-fpm` para que se procesen las páginas con código PHP.
1. `fastcgi / 127.0.0.1:9000 php {...}` [fastcgi](https://caddyserver.com/docs/fastcgi) hace de intermediario (_proxy_) y pasa las peticiones a la ruta indicada a PHP (en este caso).
1. `log stdout` y `errors stdout` redirigen la salida de los [log](https://caddyserver.com/docs/log)s y de los [error](https://caddyserver.com/docs/errors)es hacia `stdout`. Esto permite que Docker muestre los logs (y los errores) mediante [`docker logs`](https://docs.docker.com/engine/admin/logging/view_container_logs/).

## Cómo usar la imagen para servir Dokuwiki en un contenedor

Puedes lanzar un contenedor _vacío_ para verificar que la configuración de Caddy y PHP es correcta. Si no montas ningún volumen, Caddy servirá el fichero `index.html` que hemos copiado en la imagen. En el fichero de bienvenida hay un enlace que llama a `phpinfo.php`, que muestra la salida del comando [`phpinfo()`](http://php.net/manual/es/function.phpinfo.php).

Por ejemplo:

```shell
docker run --rm -d --name test -p 8911:2015 xaviaznar/alpine-caddy-php
```

{{% img src="images/170930/it_works.png" %}}

### Caddy+PHP para Dokuwiki

Para usar la imagen con Dokuwiki:

1. Creo una carpeta en el _host_ llamada `/shared/wiki/www`, donde **wiki** es el nombre del contenedor (esto es sólo por tener organizados los volúmenes compartidos entre _host_ y contenedor).
1. Descargo Dokuwiki y lo descomprimo en esta carpeta.
1. Asigno permisos a todo el mundo sobre la carpeta del `www` y sus subcarpetas. Esto es necesario porque el usuario `caddy` en el contenedor no existe en el _host_ `sudo chmod  -R 777 /shared/wiki/www`
1. Monto la carpeta en el contenedor mediante: `docker run -d --name wiki -p 8001:2015 -v /shared/wiki/www:/var/www xaviaznar/alpine-caddy-php`

### Errores

Si al intentar acceder a la URL obtienes una página en blanco o un error 404, revisa los logs mediante `docker logs wiki`.

Si observas errores del tipo `[ERROR 0 /index.php] Primary script unknow`, lo más probable es que se trate de un problema de permisos sobre la carpeta `/shared/wiki/www/`.

Otro indicador de que puede haber problemas de acceso a alguna de las subcarpetas del Dokuwiki es:

{{% img src="images/170930/dokuwiki_setup_error.png" %}}

Para solucionarlo, ejecuta:

```shell
sudo chown -R 777 /shared/wiki/www
```

Si todo está correctamente configurado, pulsando el enlace _run the installer_ podrás configurar tu nuevo wiki:

{{% img src="images/170930/dokuwiki_installer.png" %}}

## Versión para Raspberry Pi

La única diferencia para contruir la imagen para Raspberry Pi consiste en modificar la imagen base. ARM32v6 y ARM32v7 ofrecen versiones _semioficiales_ de algunas imágenes; en particular, para Alpine Linux.

Si tu aplicación PHP va a ejecutarse en una Raspberry Pi "1", debes usar la imagen [arm32v6/alpine](https://hub.docker.com/r/arm32v6/alpine/) mientras que para Raspberry Pi 2 y 3 debes usar [arm32v7/alpine](https://hub.docker.com/r/arm32v7/alpine/).

Modifica el fichero `Dockerfile` según convenga:

```Dockerfile
FROM arm32v6/alpine:3.6 # Para RPi 1
FROM arm32v7/alpine:3.6 # Para RPi 2,3
```