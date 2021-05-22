+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev", "ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "jenkins", "docker", "integracion continua", "devops"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/jenkins.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}

title=  "Pipeline: Consideraciones Generales"
date = "2018-05-19T20:12:47+02:00"
+++

El principal objetivo de esta serie de artículos es aprender a construir un _pipeline_ siguiendo, en la medida de lo posible, las mejores prácticas de cada producto.

En esta guía, se muestran los pasos a seguir de principio a fin sin que falle nada; sin embargo, el proceso real es **muy diferente**, con multitud de errores a lo largo del camino.

En esta entrada quiero exponer algunos de los cambios que he realizado, a nivel de diseño de la arquitectura durante la creación del _pipeline_.
<!--more-->

# Una base de datos por aplicación

De las aplicaciones consideradas, Gogs y SonarQube requieren una base de datos. Inicialmente había pensado en usar un solo servidor de MySQL para las dos aplicaciones, pero hay varios motivos que me han hecho cambiar de opinión:

- El uso de "redes puente" para conectar los contenedores de aplicación y de base de datos.
- Consideraciones de seguridad.
- Diferencias en el ciclo de actualización de las aplicaciones.

## Uso de una red puente para conectar dos contenedores

En internet hay multitud de tutoriales que usan el parámetro `--link` para enlazar dos contenedores. El caso más común es el de enlazar la aplicación con el servidor de datos.

El problema de la opción `--link` es que parámetro está considerado [_legacy_](https://docs.docker.com/network/links/) y **puede ser eliminado en cualquier versión de Docker**, por lo que no es conveniente usarlo.

La alternativa es usar una red puente definida por el usuario (_user-defined bridge network_). Esta es la forma recomendada en la documentación de MySQL para desplegar MySQL en Linux con Docker: [Connect to MySQL from an Application in Another Docker Container](https://dev.mysql.com/doc/mysql-installation-excerpt/5.7/en/docker-mysql-more-topics.html#docker-app-in-another-container).

### Red puente definida por el usuario

Una [_user-defined bridge network_](https://docs.docker.com/network/bridge/) es una red virtual adicional a la red a la que están conectados los contenedores. Con esta red puente conseguimos los mismos resultados que con el parámetro `--link`: los contenedores conectados a la misma red puente automáticamente exponen **todos los puertos** entre sí, pero no exponen ningún puerto al exterior. Los contenedores conectados a la misma red puente pueden contactar con el resto de contenedores mediante la resolución del nombre o el alias del contenedor.

Podemos conectar un contenedor a una _user-defined bridge network_ tanto al crear el contenedor como una vez el contenedor está en marcha.

## Consideraciones de seguridad

Al exponer todos los puertos entre las aplicaciones conectadas a la misma red, a medida que conectamos más contenedores, también aumenta el riesgo de que un fallo de seguridad en un contenedor afecte al resto de contenedores conectados.

## Diferentes ritmos de actualización

Usar el mismo servidor de base de datos para dos aplicaciones independientes supone que una nueva versión de cualquiera de las aplicaciones puede requerir una actualización de la base de datos que no sea compatible con el resto de aplicaciones.

Imagina el escenario en el que la nueva versión 2.0 de la aplicación 1 requiere que la versión de base de datos sea la 4.5 mientras que la versión soportada para la aplicación para la aplicación 2 es la 3.0, por ejemplo. Esto supone tener que quedarse con una versión desactualizada de la aplicación 1 o usar una configuración no soportada por el proveedor de la aplicación 2.

Para evitar este tipo de problemas, es mejor disponer de dos bases de datos diferentes, una para cada aplicación.

## Filosofía de los contenedores

Finalmente, otro argumento a favor de la separación de las bases de datos es la filosofía de "un proceso por contenedor"; por eso también parece más adecuado usar una base de datos para cada aplicación en su propio contenedor.

# Usuario diferente a root en la base de datos

En las primeras versiones del documento, al lanzar del contenedor para MySQL sólo creaba el usuario `root`. Por tanto, al conectar desde la aplicación, se usaba el usuario `root` en la cadena de conexión con MySQL.

Esto es una mala práctica, por lo que he eliminado las bases de datos creadas y he lanzado los contenedores con un usuario _no root_. Para ello, he usado las variables de entornos `-e MYSQL_USER` y `-e MYSQL_PASSWORD` como se indica en la [página de MySQL en Docker Hub](https://hub.docker.com/_/mysql/).

El usuario especificado de esta manera durante la creación del contenedor se le asignan permisos completos sobre la base de datos especificada mediante `-e MYSQL_DATABASE`.

La base de datos indicada en la variable de entorno `MYSQL_DATABASE` se crea automáticamente durante la inicialización del contenedor y no es necesario crearla manualmente. También evitamos usar el usuario `root` en la cadena de conexión desde la aplicación y mejoramos la seguridad de nuestro entorno.

# Volúmenes de datos

Los [volúmenes](https://docs.docker.com/storage/volumes/) son el mecanismo preferido para persistir los datos generados y usados por los contenedores. Los volúmenes montados directamente sobre el _host_ dependen de la estructura de ficheros del sistema, mientras que los volúmenes son gestionados directamente por Docker.

En la versión 18.03.1-ce de Docker, todavía no hay comandos para renombrar volúmenes o para copiar el contenido de un volumen a otro. Para migrar el contenido de la base de datos de Gogs del volumen de base de datos compartida a la base de datos específica, he tenido que montar el volumen inicial y el de destino en un contenedor intermedio.

```shell
docker volume create data-mysql-gogs
docker run --rm -it
   --mount source=data-mysql,target=/in \
   --mount source=data-mysql-gogs,target=/out \
   mysql:5.7 /bin/sh
```

Una vez montados los contenedores, he lanzado una copia del contenido de un volumen a otro:

```shell
# cd /in
# cp -a . /out
# exit
```

(Referencia: [How can I copy the contents of a folder to another folder in a different directory using terminal?](https://askubuntu.com/questions/86822/how-can-i-copy-the-contents-of-a-folder-to-another-folder-in-a-different-directo))

Finalmente, montamos el volumen de datos en el nuevo contenedor de la base de datos.

# Resumen

En el proceso de creación de cualquier solución compleja hay que valorar otros enfoques diferentes al puramente técnico. Deben tenerse en cuenta factores como la seguridad o el ciclo de vida de las aplicaciones. El coste de operar una solución en la que se han considerado estas variables será significativamente menor.

En los tutoriales todo funciona a la perfección siguiendo las instrucciones; en el mundo real no tenemos una guía de los pasos a seguir y tan importante como documentar el procedimiento final es documentar las decisiones tomadas y las soluciones aplicadas en el procedimiento de ensayo y error.