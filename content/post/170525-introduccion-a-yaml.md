+++
tags = ["yaml"]
draft = false
date = "2017-05-25T18:34:11+02:00"
title = "Introduccion a YAML"
thumbnail = "images/yaml.png"
categories = ["dev", "ops"]

+++

YAML es el lenguaje en el que se definen los _pods_, los _deployments_ y demás estructuras en Kubernetes. Todos los artículos que he leído sobre cómo crear un fichero de definición del _pod_ (_deployment_, etc) se centran en el **contenido** del fichero.

Pero en mi caso, echaba de menos una explicación de **cómo** se crea el fichero, qué reglas se siguen a la hora de _describir_ la configuración en formato YAML.

Afortunadamente el lenguaje YAML es muy sencillo y basta con conocer un par de estructuras para crear los ficheros de configuración de Kubernetes.

<!--more-->

YAML es un lenguaje de marcado muy simple, basado en ficheros de texto plano legible por los humanos. Este formato se utiliza dentro del mundillo del software para almacenar información de tipo configuración.

YAML son las siglas de _Yet Another Markup Language_ (Otro lenguaje de marcado más) o _YAML Ain't Markup Language_ (YAML no es un lenguaje de marcado), depende de a quién preguntes.

Usar YAML para las definiciones de Kubernetes proporciona las siguientes ventajas:

* **Conveniencia** No es necesario especificar todos los parámetros en la línea de comandos.
* **Mantenimiento** Los ficheros YAML puede ser gestionados por un sistema de control de versiones, de manera que se pueden registrar los cambios.
* **Flexibilidad** Es posible crear estructuras mucho más complejas usando YAML de lo que puede conseguirse desde la línea de comandos.

YAML es un superconjunto de JSON, lo que significa que cualquier fichero JSON válido también es un fichero YAML válido.


Como consejos generales a la hora de crear un fichero YAML:

* Usa siempre la codificación UTF-8 para evitar errores.
* No uses **nunca** tabulaciones
* Usa una fuente monoespaciada para visualizar/editar el contenido de los ficheros YAML.

Sólo necesitas conocer dos tipos de estructuras en YAML:

* Listas
* Mapas

A parte de los mapas y las listas, también te puede resultar útil saber que cualquier línea que comience con un `#` se considera un comentario y es ignorada.

## Mapas YAML

Los mapas te permiten asociar parejas de nombres y valores, lo que es conveniente cuando estás tratando con información relativa a configuraciones. Por ejemplo, puedes tener una configuración que empiece como:

```yml
---
apiVersion: v1
kind: Pod
```

La primera línea es un separador, y es opcional a no ser que trates de definir múltiples estructuras en un solo fichero. En el fichero puedes ver que tenemos dos valores, `v1` y `Pod`, asociados a dos claves, `apiVersion` y `kind`.

No es necesario que los valores estén entrecomillados (con comillas simples o dobles), excepto para asegurarte de que no se interpreta algún caracter especial con un significado diferente a su valor literal.

Las parejas clave-valor contenidas en un mapa se almacenan sin orden, por lo que puedes especificarlas en el orden que quieras.

El fichero YAML anterior es equivalente a:

```yml
---
kind: Pod
apiVersion: v1
```

Podemos anidar mapas dentro de mapas para crear estructuras más complejas, como:

```yml
---
apiVersion: v1
kind: Pod
metadata:
   name: rss-site
   labels:
      app: web
```

En este caso tenemos un mapa llamado `metadata` que contiene otros dos mapas; el primero `name: rss-site` y el segundo, `labels`, contiene como valor otro mapa `app: web`.

Puedes anidar tantos mapas dentro de mapas como quieras.

Para indicar que un mapa está contenido en otro, se usa la indentación. En el ejemplo anterior hemos usado una indentación de 3 espacios, pero el número de espacios no importa, siempre que sea **consistente** en el fichero. El procesador de YAML interpreta las claves y valores en la misma profundidad de indentación como al mismo nivel (por ejemplo, `name` y `labels`), mientras que si están indentadas, interpreta que están _contenidas_ unos en otros (como en el caso de `labels` y `app: web`).

## Listas en YAML

Una lista, en YAML, es una secuencia de objetos, o lo que es lo mismo, una colección ordenada de valores. En este caso los valores no están asociados con una clave, sino con un índice posicional obtenido del orden en el que están especificados en la lista. Por ejemplo:

```yml
args
   - sleep
   - 1000
   - message
   - "Hello World!"
```

Puede haber cualquier número de elementos en una lista.

Como en el caso de las parejas clave-valor, los elementos de una lista se encuentran indentados con el mismo número de espacios bajo el identificador (la clave) de la lista; cada elemento de la lista va precedido por un `-`.

Del mismo modo que podemos anidar mapas en mapas, podemos anidar listas en listas, mapas en listas y cualquier combinación imaginable. Un ejemplo de mapas y listas anidados:


```yml
# Configuracion ficticia
spec:
   containers:
      - name: front-end
        image: nginx
        ports:
           - containerPort: 80
      - name: rss-reader
        image: xavi/rss-reader
        ports:
           - containerPort: 80
```

En resumen, tenemos:

* **Mapas**, que son grupos no ordenados de parejas de clave y valor
* **Listas**, que son colecciones ordenadas de elementos individuales
* Mapas de mapas
* Mapas de listas
* Listas de mapas
* Listas de listas
* etc

Básicamente, cualquier estructura que puedas imaginar, se puede construir a partir de estos dos elementos.

Con estos conocimientos básicos, espero que ahora te resulte mucho más sencillo interpretar los ficheros de configuración de _pods_, _deployments_, etc. Y no sólo en Kubernetes; las configuraciones en formato YAML son usadas por un montón de productos diferentes.
