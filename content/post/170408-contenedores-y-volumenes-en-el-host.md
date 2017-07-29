+++
date = "2017-04-08T05:53:59+02:00"
title = "Contenedores y volúmenes de datos en el host"
thumbnail = "images/docker.png"
categories = ["docker"]
tags = ["ops"]

+++

Ayer leía el artículo [Containers and Storage: Why We Aren’t There Yet](https://thenewstack.io/containers-storage-arent-yet/) y recordaba los _quebraderos de cabeza_ que tuve intentado crear una serie de contenedores accediendo a un volumen de datos.

<!--more-->

El problema, como bien indica el artículo, es que _a día de hoy_, no es posible hacer que el acceso a un volumen de datos sea a la vez **_portable_ y _seguro_**.

Los detalles son muy técnicos, pero revelan la manera en la que trabajan Linux y Docker. Tener claros estos conceptos es interesante para enteneder cómo funciona Docker y cómo afrontar los problemas que puedan surgir creando contenedores.

Dentro de un contenedor, por defecto, sólo tenemos el usuario `root`, por lo que todos los procesos **dentro** del contenedor se ejecutan con permisos de _superadministrador_ (`root`).

Desde el punto de vista de la seguridad, ejecutar procesos con permisos de `root` si no es necesario, es una mala práctica; en caso de que el sistema se vea comprometido, un atacante dispondría de todos los permisos y podría causar mucho daño. 

En Docker, este riesgo se encuentra _aislado_ **dentro** del contenedor. Pese a todo, se recomienda cambiar a un usuario con menos privilegios siempre que sea posible.

Si le echas un vistazo a la [configuración del contenedor oficial de Nginx](https://github.com/nginxinc/docker-nginx/blob/0c7611139f2ce7c5a6b1febbfd5b436c8c7d2d53/mainline/alpine/nginx.conf) verás que la primera instrucción es:

```sh
user nginx;
```

Es decir, que lo primero que hace Nginx es cambiar a un usuario _no-root_ cuando se ejecuta.

El proceso es el siguiente: el contenedor arranca con el usuario `root` y cuando se lanza el proceso `nginx`, se cambia al usuario _nginx_ (eliminando los privilegios del usuario _root_).

Desde el punto de vista de la seguridad, si alguien compromete el contenedor, el proceso se ejecuta con un usuario con permisos restringidos, por lo que el atacante puede causar **daño limitado**.

_So far, so good_ (hasta aquí todo bien, que dicen los anglosajones).

¿Qué pasa cuando se _monta_ una carpeta una carpeta del _host_ en el contenedor?

En caso de que el contenedor se vea comprometido, el atacante ya no está restringido al contenedor, sino que tiene una _vía de entrada_ al _host_. 

A día de hoy Docker requiere permisos de `root` en el _host_ para ejecutarse. En particular, en el caso del _montaje_ de carpetas del _host_ en el contenedor, Docker puede montar **cualquier** carpeta (o fichero) en un contenedor (mira la sección [Docker deamon attack surface](https://docs.docker.com/engine/security/security/) en la documentación oficial de Docker). Así que si un atacante se hiciera con el control del proceso Docker, podría lanzar un contenedor, montar la carpeta `/` y modificar el sistema desde el contenedor.

Esto sería **muy malo**.

Pero ya hemos dicho antes que podemos minimizar el riesgo usando usuarios no privilegiados dentro del contenedor, como `nginx`, ¿no?

Desde el punto de vista de la seguridad, siguiendo las buenas prácticas, en cuanto lancemos el proceso dentro del contenedor, cambiamos a un usuario sin privilegios y ¡problema resuelto!

Ojalá las cosas fueran tan sencillas...

Considera el siguiente caso; hemos creado una imagen con Dokuwiki, por ejemplo, usando como base la imagen de Nginx siguiendo las buenas prácticas de seguridad. Hemos minimizado el riesgo ante un eventual ataque usando un usuario sin privilegios llamado _nginx_. Como estamos muy orgullosos de nuestra imagen, la subimos a DockerHub: `xaviaznar/nginx-dokuwiki-seguro`.

Un usuario se descarga esta imagen y lanza un contenedor, montando una carpeta local de su _host_ desde la que quiere servir su propia wiki. Para ello lanza un comando como:

```sh
docker run -d --name miwiki -p 80:80 -v /wiki:/dokuwiki/data/pages xaviaznar/nginx-dokuwiki-seguro 
```

(Es sólo un ejemplo ilustrativo, este _montaje_ de [carpetas](https://www.dokuwiki.org/devel:dirlayout) no es una buena idea).

El contenedor arranca sin problemas, pero cuando quiere crear o modificar una página en el wiki, no funciona.

¿Qué pasa?

El problema es que ahora estamos relacionando **dos** sistemas Linux, con usuarios diferentes.

Por un lado tenemos el usuario `nginx` dentro del contenedor, sin privilegios, que hemos creado siguiendo las buenas prácticas de seguridad.

En el sistema _host_, Docker se ejecuta con permisos de `root`, por lo que puede realizar el montaje de la carpeta `/wiki` en el contenedor sin problemas.

Cuando el usuario `nginx` (del contenedor) intenta escribir en la carpeta del _host_, el sistema comprueba si el usuario `nginx` tiene permisos para escribir en esa carpeta. Como el usuario `nginx` solo existe **dentro** del contenedor, el sistema del _host_ no lo reconoce y se le deniega el acceso.

Aquí es donde surge el dilema entre seguridad y portabilidad: si ejecutamos los procesos en el contenedor como `root`, no tenemos problemas para acceder a carpetas locales en el _host_, pero nos enfrentamos a un problema de seguridad potencialmente grave. Si minimizamos el riesgo usando un usuario sin privilegios, tenemos problemas de permisos al intentar acceder a carpetas locales.

Como indica [James Bottomley](https://twitter.com/jejb_), evangelista de contendores para IBM en la [conferencia Vault](http://events.linuxfoundation.org/events/vault) sobre almacenamiento de la Linux Foundation en Boston el mes pasado:

> "This is a significant problem for running unprivileged containers alongside standard images. If we’ve all written out container images for different values of root, it’ll be a horrible nasty mess somewhere."

Traducción:

> Este es un problema significativo de cara a ejecutar contenedores sin privilegios junto a imágenes estándar. Si hemos creado imágenes de contenedores para diferentes valores de `root`, en algún sitio habrá un lío tremendo.

El artículo comenta algunas soluciones que se están desarrollando para solventar el problema, pero por ahora, el dilema entre seguridad y el acceso al _host_ sigue estando sobre la mesa.
