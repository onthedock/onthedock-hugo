+++
draft = false

# TAGS
# HW->OS->PRODUCT->specific tag
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "alpine", "docker", "dokuwiki"]

# CATEGORIES = "dev" / "ops"
categories = ["dev"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/docker.png"

title=  "Dokuwiki en un contenedor: notas sobre el proceso"
date = "2017-09-24T22:43:01+02:00"
+++

Antes de convertir todas las Raspberry Pi de casa en _hosts_ de Docker, usaba la Raspberry Pi B+ como wiki casero. En él documentaba todo lo que iba aprendiendo sobre las diferentes tecnologías de mi día a día.

Hoy he vuelto a instalar Dokuwiki, aunque esta vez usando un contenedor. En este artículo comento algunos de los puntos relevantes que han surgido durante el proceso.

<!--more-->

# Un poco de historia

Aquel wiki casero del que hablaba en la intro fue creciendo hasta convertirse en parte de mi _memoria extendida_: instalé [Ngrok](https://ngrok.com/) para poder acceder desde cualquier sitio a la información contenida en el wiki.

Con Ngrok sólo podía crear un túnel hacia la RPi, lo que impedía que mis compañeros de trabajo pudieran consultar el wiki. Ahí fue donde empecé mi andadura con los contenedores, replicando el wiki en Red Hat Cloud: [Wiki-Ameisin](http://wiki-ameisin.rhcloud.com/). Pero tenía dificultades para mantener mi _copia local_, en la RPi y la _copia en la nube_ (en RHCloud) sincronizadas, por lo que la versión online se fue quedando cada vez más desactualizada.

Después de un cambio de trabajo, el wiki fue perdiendo relevancia hasta que empecé a usar Docker y Kubernetes como _hobby_. Pero como he canalizado gran parte del aprendizaje hacia este blog, la necesidad de disponer de un wiki  no resultaba apremiante. Además, siempre estaba presente el problema con el almacenamiento (especialmente en Kubernetes, como he comentado en [otras]({{<ref "170819-usando-un-contenedor-sidecar.md">}}) [ocasiones]({{< ref "170817-almacenamiento-en-k8s-problema-abierto.md">}})).

## Problemas de _concepto_

### Docker o Kubernetes

Mi objetivo inicial era crear un wiki en Kubernetes. Al no tener resuelto el problema del almacenamiento nativo sobre el clúster, la única vía disponible es la del almacenamiento local (en uno de los nodos) del clúster. Pero eso significa que el _pod_ debe estar ligado al nodo donde se encuentra el almacenamiento.

Aunque se puede conseguir especificando afinidad con uno de los nodos, es más sencillo crear el contenedor en Docker, sin usar el clúster.

### Un contenedor o varios

La filosofía de los contenedores es que cada contenedor debe ejecutar un solo proceso. Así que había pensado en _conectar_ varios contenedores: uno para el servidor web, otro para el _middleware_, PHP y finalmente otro con los datos. En el caso de Dokuwiki, los datos se almacenan en ficheros de texto plano, por lo que no es necesaria una base de datos o nada por el estilo.

El problema de esta configuración es que el servidor web se ejecuta usando un usuario (por ejemplo `www-data`), mientras que el contenedor de PHP es probable que use otro usuario... Cuando he intentado esta configuración en el pasado, he acabado con muchos problemas de permisos.

Así que he seguido el camino inverso y he decidido _meterlo todo_ en un solo contenedor: servidor web, PHP y datos.

### Configuración inicial de Dokuwiki

> Puedes encontrar todos los ficheros en [Github: ontheDock/alpine-caddy-php](https://github.com/onthedock/alpine-caddy-php) y la imagen final en [DockerHub: xaviaznar/alpine-caddy-php](https://hub.docker.com/r/xaviaznar/alpine-caddy-php/)

No ha sido difícil crear una imagen base con Nginx, PHP (y PHP-FPM), pero todavía quedaba la parte difícil: configurarlo todo para que funcionase.

He realizado algunas pruebas de configuración de PHP en Nginx, sin éxito.

En cualquier caso, mirando un poco más allá, he pensado que en la primera ejecución del wiki se lanza `install.php` para configurar el wiki. Si los ficheros se encuentran en la imagen base, no pueden ser modificados, lo que significa que en cada ejecución del wiki se deberían reconfigurar de nuevo.

Sacando los ficheros del contenedor podría solucionarse el problema, por ejemplo creando un contenedor de datos o colocando los ficheros del wiki en un volumen del _host_.

También habría que apartarse de la [configuración recomendada del Dokuwiki para Nginx](https://www.dokuwiki.org/install:nginx), que entre otras cosas impide el acceso al fichero `install.php`.

Al final he decidido realizar algunos cambios:

- usar Caddy, con una [configuración de PHP específica para Dokuwiki](https://github.com/caddyserver/examples/tree/master/dokuwiki) más sencilla
- _montar_ los ficheros de Dokuwiki desde una carpeta en el _host_.

### Caddy y PHP

He empezado con un `Dockerfile` lo más sencillo posible, instalando únicamente lo esencial. He usado [este `Dockerfile`](https://bitbucket.org/yobasystems/alpine-caddy/overview) como inspiración.

Inicialmente, sólo instalo Caddy, PHP y las bibliotecas de funciones requeridas por Dokuwiki:

```Dockerfile
FROM alpine:3.6

RUN apk add --no-cache caddy php7 php7-fpm php7-gd
```

Siguiendo las buenas prácticas de Docker, he decidido usar un usuario _no-root_ llamado `caddy` (el usuario y el grupo se crear durante la instalación de Caddy).

También he optado por copiar la línea de configuración de `php-fpm`:

```Dockerfile
RUN echo "clear_env = no" >> /etc/php7/php7-fpm.conf

RUN chown -R caddy:caddy /var/www /var/log

WORKDIR /var/www
```

Aunque en el `Dockerfile` se usa la instrucción `WORKDIR` para cambiar al directorio base que usará Caddy, yo prefiero especificarlo en el fichero de configuración. Aunque en este caso es redundante, he preferido dejarlo para establecer un directorio por defecto para el servidor en la imagen (que quiero utilizar como base para otras aplicaciones basadas en PHP).

A continuación he copiado el fichero de configuración de Caddy y el fichero `info.php`, que contienen la instrucción [`phpinfo();`](http://php.net/manual/es/function.phpinfo.php).

Para acabar, exponemos el puerto en el que escucha Caddy por defecto, cambiamos al usuario `caddy` y especificamos el `ENTRYPOINT` y el `CMD`:

```Dockerfile
EXPOSE 2015
USER caddy
ENTRYPOINT ["/usr/sbin/caddy"]
CMD ["--conf", "/etc/Caddyfile"]
```

### Fichero de configuración `Caddyfile`

El fichero de configuración de Caddy es mucho más sencillo que el Nginx; sin embargo, he tenido problemas (por no leer la documentación).

```Dockerfile
0.0.0.0
root /var/www/wiki
gzip
startup php-fpm7

fastcgi / 127.0.0.1:9000 php {
  index index.php index.htm doku.php
}

log stdout
errors stdout
```

Caddy por defecto escucha en el puerto 2015, no en el 80 como suele ser habitual. Esto es fácil de detectar, porque el usuario `caddy` no tiene permisos para usar un puerto por debajo de 1024. Así que al modificar la primera línea del fichero `Caddyfile` de `0.0.0.0` a `0.0.0.0:80`, el contenedor falla.

He dudado entre usar `0.0.0.0` o `localhost`, pero no he observado ninguna diferencia al usar uno u otro -en el contenedor- y al final he dejado `0.0.0.0`.

Otro punto que me ha tenido bastante _ocupado_ ha sido la línea `startup php-fpm`. No sabía que `php-fpm` debía arrancarse, ya que pensaba que se llamaba desde el servidor web cuando hacía falta (para interpretar código php).

La configuración de los parámetros `root` y `fastcgi` también me han dado problemas, de nuevo, por no haber leído la documentación. El parámetro `root` indica a Caddy la ruta en el sistema de ficheros donde encontrar los ficheros a publicar vía web. En `fastcgi` la ruta es relativa a la URL.

Otro punto que me ha despistado es que el fichero inicial de pruebas `index.htm` incluye un fragmento de código en PHP, pero que no he conseguido que se interprete (por eso hay una copia del mismo fichero pero con extensión `php`). Finalmente he podido validar el funcionamiento de Caddy y PHP usando el fichero `info.php`.

## Ejecutando el contenedor

Una vez he conseguido crear un contenedor con Caddy y PHP funcional (verificado a partir de `$BASEURL/info.php`), el siguiente paso era _conectarlo_ con los ficheros de Dokuwiki. La manera más sencilla ha sido creando una carpeta local en la _host_ y montarla en el contenedor como un volumen.

He descargado y descomprimido la última versión estable de Dokuwiki en la carpeta `~/dokuwiki` y la he montado en el contenedor:

```shell
docker run -d --name wiki -p 8910:2015 -v /home/operador/dokuwiki:/var/www xaviaznar/alpine-caddy-php
```

### Permisos

Como el usuario con el que se ejecuta Caddy en el contenedor no existe en el sistema local, he cambiado los permisos de `~/dokuwiki` a `777` (todo el mundo tiene acceso). A diferencia del usuario `root`, el usuario `caddy` no existe en el _host_, por lo que tendría problemas para "salir" de la carpeta `dokuwiki` y acceder a otras partes del sistema más sensibles.

### Librerías adicionales

Dado que he optado por reducir al mínimo las _librerías_ de PHP incluidas en el contenedor, al arrancar Dokuwiki he encontrado algunos errores en el funcionamiento del mismo.

Al final, he tenido que añadir `php7-session php7-xm` para arrancar Dokuwiki sin errores, y `php7-openssl php7-zlib` cuando he intentado añadir _plugins_, con lo que la línea definitiva en el `Dockerfile` ha quedado:

```Dockerfile
RUN apk add --no-cache caddy php7 php7-fpm php7-gd \
    php7-session php7-xml php7-openssl php7-zlib
```

## Ficheros auxiliares

Dado que todo el proceso por el que he pasado ha sido el resultado de innumerables iteraciones, en cierto punto he decidido _automatizar_ parte del proceso.

He creado unos scripts auxiliares para construir la imagen, parar y eliminar el contenedor y para ejecutarlo de nuevo. Para poder conectar al contenedor y revisar la configuración, la correcta ubicación de los ficheros (o si el proceso `php-fpm` estaba funcionando), también he credo un script para conectar al contenedor y ejecutar una terminal.

Obviamente dista mucho de ser un _pipeline_ de integración continua, pero es un primer paso en la dirección correcta ;)

## Siguientes pasos

Todo el proceso de desarrollo lo he realizado en mi equipo de laboratorio, sobre una máquina virtual x64 para evitar añadir problemas de compatibilidad o de disponibilidad de librerías al proceso.

El paso de una imagen x64 a una ARM no debería suponer ningún problema, ya que estuve revisando que todos los paquetes estuvieran disponibles para las dos arquitecturas.

El siguiente paso es aprovechar todo lo aprendido con la imagen de prueba y crear una imagen para la Raspberry Pi.