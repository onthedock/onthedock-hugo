+++
date = "2017-05-20T19:59:44+02:00"
title = "Normas para estructurar ficheros implicados en la creación de contenedores"
thumbnail = "images/docker.png"
categories = ["dev", "ops"]
tags = ["git", "docker", "enterprise"]
draft = false

+++
El proceso desde la creación a la ejecución del contenedor se puede separar en varias fases:

1. Creación de la imagen (mediante la redacción de un fichero `Dockerfile`)
1. Construcción de la imagen
1. Ejecución del contenedores

Para tener los diferentes ficheros implicados en el proceso organizados de forma homogénea, me he autoimpuesto las siguientes reglas a la hora de estructurar los repositorios.

<!--more-->

# Dockerfile

El primero paso para ejecutar un contenedor es crear la imagen en la que está basado. Para ello debes crear un fichero `Dockerfile` en el que se indica la imagen base usada y los diferentes pasos de instalación de paquetes, configuración de usuarios, volúmenes y puertos expuestos.

En la creación de la imagen intervienen, además del fichero `Dockerfile`, ficheros de configuración, etc que se copian a la imagen desde la carpeta donde se encuentra el fichero `Dockerfile` (el llamado _contexto_, ver [Documentación oficial de `docker build`](https://docs.docker.com/engine/reference/commandline/build/#options)).

Para gestionar los cambios sobre estos ficheros, lo más sencillo es guardarlos en un repositorio y tener un registro de todos los cambios que se van introduciendo a lo largo del tiempo.

Todos los ficheros relacionados con la _creación_ de la imagen se colocan en una carpeta llamada `build`, con el `Dockerfile` y los ficheros de configuración, etc, agrupados en sus correspondientes carpetas.

En esta carpeta también se incluyen un fichero con instrucciones para la creación de la imagen (condiciones en las que reutilizar la cache, puntos a tener en cuenta, etc) y un _script_ para lanzar la creación de la imagen de forma siempre igual (quizás el script borra ficheros temporales o descargados en ejecuciones anteriores, por ejemplo).

# Construcción de la imagen

Una vez creado el `Dockerfile`, _construyes_ la imagen mediante `docker build`. Aunque en general la construcción se realiza mediante un sólo comando de la forma `docker build -t {repositorio/etiqueta} .`, puede ser interesante disponer de documentación con indicaciones sobre las reglas de etiquetado de la imagen definidas por la empresa o similar.

# Ejecución del contenedor

Finalmente la creación de contenedores basados en la imagen se realiza mediante un comando `docker run`.

A la hora de ejecutar el contenedor la instrucción puede incluir el nombre del contenedor final, la relación entre puertos del _host_ y el contenedor, el montaje de volúmenes, etc. En algunos casos, el contenedor admite parámetros que se pasan al comando definido en la instrucción `CMD`.

Para evitar errores o simplemente para no teclear una y otra vez comandos larguísimos para ejecutar el contenedor, podemos crear un _script_ que lance el contenedor con los parámetros necesarios, así como documentación de la funcionalidad proporcionada por el contenedor, etc.

Estos ficheros se guardan en el carpeta llamada `run`; básicamente el comando para lanzar la creación del contenedor de forma homogénea y las instrucciones con información sobre el uso del contenedor, volúmenes, etc.

# Carpetas

Para estructurar todos los ficheros implicados en el proceso de creación de un contenedor he definido la siguiente estructura de carpetas:

```sh
./nombre-contenedor/
 |
 ├─Readme.md
 ├─build/
 | ├─Dockerfile
 | ├─build.sh
 | ├─Build-Instructions.md
 | ├─{context-files}/
 | ├─...
 | ├─{context-files}/
 ├─run/
 | ├─run.sh
 | ├─Run-Instructions.md
```

# Motivación

No he encontrado ningún artículo sobre la organización de los ficheros implicados en el creación de imágenes o de los flujos de trabajo asociados a estos procesos. Tampoco sobre las normas a la hora de etiquetar las imágenes o si se realizan validaciones a la hora de obtener/subir imágenes de repositorios públicos.

Incluso en una empresa en la que el proceso de desarrollo y operación de las aplicaciones gire alrededor del concepto _DevOp_, puede haber otros implicados en el proceso _administrativo_ del ciclo de vida de la aplicación: decisiones estratégicas, a nivel de seguridad, de _compliance_ con leyes como la protección de datos, etc.

En los artículos/conferencias lo habitual es explicar soluciones técnicas sin entrar nunca en estos procesos que relacionan IT con el resto de departamentos de la empresa.
