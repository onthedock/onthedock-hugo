+++
draft = false
tags = ["linux", "docker", "minio"]
categories = ["dev", "ops"]
thumbnail = "images/minio.jpg"

# SHORTCODES (for reference)

# YouTube
# {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Imagenes
# {{% img src="images/image.jpg" w="600" h="400" %}}
# {{% img src="images/image.jpg" w="600" h="400" class="right" %}}
# {{% img src="images/image.jpg" w="600" h="400" class="left" %}}
# {{% img src="images/image.jpg" w="600" h="400" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# Clear (floats)
# {{% clear %}}
# Twitter
# {{% twitter tweetid="780599416621297xxx" %}}

title=  "Probando Minio"
date = "2017-08-20T21:28:20+02:00"
+++

Minio proporciona un servidor de almacenamiento distribuido compatible con el API de Amazon AWS S3.

En esta entrada comento las pruebas que he estado realizando usando Minio tanto el cliente como el servidor en contenedores Docker.

<!--more-->

En la [entrada anterior]( {{< ref "170817-almacenamiento-en-k8s-problema-abierto.md" >}} ) comentaba cómo, después de darle unas cuantas vueltas, había decidido probar el patrón de _contenedor sidecar_ para dar solución al problema al almacenamiento en los _pods_ del clúster de Kubernetes.

# Minio Server

Una de las ventajas de Minio es que puede desplegarse como un contenedor. Minio requiere dos carpetas del _host_ donde almacenar, por un lado, los ficheros de configuración y por el otro, los datos propiamente dichos.

En primer lugar, creo las carpetas:

```shell
mkdir /tmp/minio/config /tmp/minio/data -p
```

El siguiente paso es crear el contenedor para Minio server, siguiendo las instrucciones de la [guía de Minio para Docker](https://docs.minio.io/docs/minio-docker-quickstart-guide): 

```shell
$ docker run -d -p 9000:9000 --name minio-server \
  -v /tmp/minio/data:/data \
  -v /tmp/minio/config:/root/.minio \
  minio/minio server /data
b1d73ba7f787d34df1fd931c3bc9af4af2dfb4eeb899f96104a20eb85a5aa616
```

Minio Server crea una `AccessKey` y una `SecretKey` al arrancar. Puedes consultar estas claves a través de los logs del contenedor:

```shell
$ docker logs minio-server
Endpoint:  http://172.17.0.2:9000  http://127.0.0.1:9000
AccessKey: LKHN4QADGFDM411KYYB8
SecretKey: o1fTtQhurjLnwrH9rF+hhSACWSX12Xpf4lxTu6Kq

Browser Access:
   http://172.17.0.2:9000  http://127.0.0.1:9000

Command-line Access: https://docs.minio.io/docs/minio-client-quickstart-guide
   $ mc config host add myminio http://172.17.0.2:9000 LKHN4QADGFDM411KYYB8 o1fTtQhurjLnwrH9rF+hhSACWSX12Xpf4lxTu6Kq

Object API (Amazon S3 compatible):
   Go:         https://docs.minio.io/docs/golang-client-quickstart-guide
   Java:       https://docs.minio.io/docs/java-client-quickstart-guide
   Python:     https://docs.minio.io/docs/python-client-quickstart-guide
   JavaScript: https://docs.minio.io/docs/javascript-client-quickstart-guide
   .NET:       https://docs.minio.io/docs/dotnet-client-quickstart-guide

Drive Capacity: 41 GiB Free, 48 GiB Total
$
```

Verifica que el servidor de Minio funciona correctamente accediendo al cliente web, accesible a través de `http://<IP_NODO>:9000/minio`.

## Claves de acceso personalizadas

Puedes pasar las claves `AccessKey` y `SecretKey` como variables de entorno durante la creación del contenedor del servidor de Minio:

```shell
docker run -d --name minio-server -p 9000:9000 \
  -e "MINIO_ACCESS_KEY=MINIO.ACCESSKEY-WZtjrjMMxPM7Nwf" \
  -e "MINIO_SECRET_KEY=MINIO.SECRETKEY-4Mg8ZMwwPuhINf6" \
  -v /tmp/minio/data:/data \
  -v /tmp/minio/config:/root/.minio \
  minio/minio server /data
```

Minio Server también es compatible con los _Secrets_ de Docker (v.13 o superior).

> En Ubuntu 16.04.3 LTS (Xenial Xerus)) la última versión disponible en estos momentos (20/08/2017) es 1.12.6.

En primer lugar, crea los _secrets_ mediante:

```shell
echo "MINIOACCESSKEY-WZtjrjMMxPM7Nwf" | docker secret create minio_access_key -
echo "MINIOSECRETKEY-4Mg8ZMwwPuhINf6" | docker secret create minio_secret_key -
```

En combinación con los _services_ de Docker Swarm:

```shell
docker service create --name="minio-service" --secret="minio_access_key" --secret="minio_secret_key" minio/minio server /data
```

El objetivo final de las pruebas con Minio es poder lanzar clientes como contenedores. Para poder conectar con el servidor de Minio es necesario que el `AccessKey` y el `SecretKey` coincidan. El hecho de poder _inyectar_ las claves al ejecutar el contenedor asegura que no tendremos problemas para conectar con el servidor.

## Ejecución de Minio Server

Ejecutamos Minio Server y comprobamos que se ha lanzado con las claves especificadas:

```shell
$ docker run -d --name minio-server -p 9000:9000 \
  -e "MINIO_ACCESS_KEY=MINIO.ACCESSKEY-WZtjrjMMxPM7Nwf" \
  -e "MINIO_SECRET_KEY=MINIO.SECRETKEY-4Mg8ZMwwPuhINf6" \
  -v /tmp/minio/data:/data \
  -v /tmp/minio/config:/root/.minio \
  minio/minio server /data
d1202a93911ea355517c3c1f4778262f17f224e68d51a343129842f7f887b965
$ docker logs minio-server
Endpoint:  http://172.17.0.2:9000  http://127.0.0.1:9000
AccessKey: MINIO.ACCESSKEY-WZtjrjMMxPM7Nwf
SecretKey: MINIO.SECRETKEY-4Mg8ZMwwPuhINf6

Browser Access:
   http://172.17.0.2:9000  http://127.0.0.1:9000

Command-line Access: https://docs.minio.io/docs/minio-client-quickstart-guide
   $ mc config host add myminio http://172.17.0.2:9000 MINIO.ACCESSKEY-WZtjrjMMxPM7Nwf MINIO.SECRETKEY-4Mg8ZMwwPuhINf6

Object API (Amazon S3 compatible):
   Go:         https://docs.minio.io/docs/golang-client-quickstart-guide
   Java:       https://docs.minio.io/docs/java-client-quickstart-guide
   Python:     https://docs.minio.io/docs/python-client-quickstart-guide
   JavaScript: https://docs.minio.io/docs/javascript-client-quickstart-guide
   .NET:       https://docs.minio.io/docs/dotnet-client-quickstart-guide

Drive Capacity: 41 GiB Free, 48 GiB Total
$
```

También podemos probar el acceso a través de la URL: `http://<IP_NODO>:9000/minio` usando las `AccessKey` y la `SecretKey` especificadas.

## Creación del contenedor con Minio Client

El cliente de Minio puede desplegarse como un contenedor. El objetivo final de estas pruebas es usar un contenedor sidecar con el cliente de Minio y replicar el contenido del volumen local (en el _pod_) con un _bucket_ "remoto" (en el servidor de Minio desplegado en el clúster).

Descargamos la imagen del cliente de Minio:

```shell
$ docker pull minio/mc
Using default tag: latest
latest: Pulling from minio/mc
6f821164d5b7: Pull complete
884e952fb0b8: Pull complete
Digest: sha256:7094c3cff3bb82d42bd4a5b212c467be1238db65a47a707038e562acf9f72a15
Status: Downloaded newer image for minio/mc:latest
```

## Configuración de Minio Client

Por defecto `mc` viene configurado para apuntar contra `https://play.minio.io:9000` (usando el alias `play`). Para realizar la configuración del cliente para apuntar contra el servidor local, usamos:

```shell
docker run -d --name minio-client -v /home/operador/minio-client-config/:/root/.mc/ minio/mc config host add minio http://192.168.1.10/minio:9000 MINIO.ACCESSKEY-WZtjrjMMxPM7Nwf MINIO.SECRETKEY-4Mg8ZMwwPuhINf6"
```

He creado una carpeta en el _host_ donde almacenar la configuración del cliente y así poder compartirla entre los diferentes contenedores con el cliente de Minio.

El contenedor se crea, finaliza con éxito, pero no parece realizarse la configuración.

Revisando el contenido de la carpeta `/home/operador/minio-client-config/` observo que sí se han creado los ficheros de configuración.

Revisando el fichero de configuración `config.json` veo que no se ha creado la configuración del servidor con el alias "minio".

Después de varios intentos fallidos, opté abrir una sesión interactiva en un contenedor con el cliente `mc` y lanzar el comando de configuración desde ahí.

```shell
# mc config host add minio http://192.168.1.10 MINIO.ACCESSKEY-WZtjrjMMxPM7Nwf MINIO.SECRETKEY-4Mg8
ZMwwPuhINf6 S3v4
mc: <ERROR> Invalid access key `MINIO.ACCESSKEY-WZtjrjMMxPM7Nwf`. Invalid arguments provided, cannot proceed
#
```

Por algún motivo, el comando `mc config host add` da un error al intentar añadir las `AccessKey` y la `SecretKey`.

Para descartar que el "." o el "-" tengan algún significado especial que esté interfiriendo, he probado a eliminarlos, pero he seguido obteniendo el mismo error de _Invalid arguments provided_.

La solución ha sido modificar directamente el fichero `/root/.mc/config.json` desde una sesión interactiva en el contendor.

Para probar que el cliente puede conectar con el servidor después de haber realizado la configuración del las claves, genero un fichero de prueba desde el contenedor mediante:

```shell
# yes >> yes.txt
# # mc cp yes.txt local/test
yes.txt:           171.14 MB / 171.14 MB ┃▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓┃ 100.00% 44.24 MB/s 3s/
#
```

Desde el cliente en el navegador, compruebo que el fichero se ha copiado correctamente al _bucket_ de prueba llamado _test_.

Finalizamos la sesión interactiva.

Probamos una nueva sesión interactiva a ver qué pasa con la configuración modificada en el otro contenedor temporal.

```shell
$ docker run --rm -it -v /home/operador/config:/root/.mc/ --entrypoint=/bin/sh minio/mc
/ # mc config host ls
gcs  :  https://storage.googleapis.com  YOUR-ACCESS-KEY-HERE  YOUR-SECRET-KEY-HERE                      S3v2
local:  http://192.168.1.10:9000        MINIO.ACCESSKEY-W...  MINIO.SECRETKEY-4Mg8ZMwwPuhINf6           S3v4
play :  https://play.minio.io:9000      Q3AM3UQ867SPQQA43P2F  zuf+tfteSlswRu7BJ86wekitnifILbZam1KYY3TG  S3v4
s3   :  https://s3.amazonaws.com        YOUR-ACCESS-KEY-HERE  YOUR-SECRET-KEY-HERE                      S3v4
/ #
```

Verificamos que las claves de acceso se mantienen (quizás haya modificado el fichero `config.json` después de haber lanzado el contenedor temporal).

> En un primer intento de solucionar el error de _Invalid arguments provided_ he conseguido configurar la `AccessKey` y la `SecretKey` usando sólo minúsculas. He modificado el fichero `config.json` desde el _host_, pero en el contenedor seguía viendo las credenciales de la prueba (sólo en minúsculas).

Después de configurar el servidor con alias `local`, creo un _bucket_ llamado `test` a través del interfaz web.

## Copia de ficheros

Creamos un nuevo fichero y lo copiamos al _bucket_ `local/test`:

```shell
# for i in [0..10]; do  echo "Hello world" >>  hello.txt; done
# mc cp hello.txt local/test
hello.txt:         11.85 KB / 11.85 KB ┃▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓┃ 100.00% 771.76 KB/s 0s/
#
```

## Sincronizando carpetas

La siguiente prueba es la de sincronizar una carpeta usando `mc mirror`.

El primer paso es conseguir pasar los comandos a `mc` en el contenedor para que ejecute las acciones como si estuviera instalado.

Un rápido repaso a cómo funciona el [`ENTRYPOINT`](https://docs.docker.com/engine/reference/run/#entrypoint-default-command-to-execute-at-runtime) me ha llevado a la solución. El `ENTRYPOINT` hace que el contenedor se ejecute como si fuera un el binario especificado. Si no se especifica nada en `CMD` en el _Dockerfile_, se ejecuta únicamente lo especificado en `ENTRYPOINT`. Al lanzar el contenedor lo que especifiquemos tras el nombre de la imagen se pasa como parámetros al binario especificado en el `ENTRYPOINT`. Así, por ejemplo:

```shell
$ docker run --rm -v /home/operador/config:/root/.mc/ minio/mc rm  local/test/deploying-containers-kubernetes-concepts.png
Removing `local/test/deploying-containers-kubernetes-concepts.png`.
```

Si queremos probar el comando `mc mirror`, creamos una carpeta local en el _host_ que vamos a sincronizar con el _bucket_. Tendré que montar esta carpeta _local_ para que `mc` tenga acceso a ella desde el contenedor.

He creado una carpeta local en el nodo llamada `/home/operador/mirror`.

He lanzado un contenedor con el comando `mirror`:

```shell
docker run -d --name minio-mirror  \
  -v /home/operador/config:/root/.mc/ \
  -v /home/operador/mirror:/tmp/mirror \
  minio/mc mirror --watch /tmp/mirror local/test
```

En la carpeta `~/mirror/` he creado dos ficheros de texto:

```shell
for i in `seq 1 10000`; do echo "Hello World!" >> /home/operador/mirror/10khello.txt; done
for i in `seq 1 100000`; do echo "Hello World!" >> /home/operador/mirror/100khello.txt; done
```

Inicialmente el _bucket_ está vacío.

Arranco el cliente de Minio `mc` en forma de contenedor:

```shell
docker run -d --name minio-client  \
  -v /home/operador/config:/root/.mc/ \
  -v /home/operador/mirror:/tmp/mirror \
  minio/mc mirror --watch /tmp/mirror local/test
```

Vigilo en dos ventanas adicionales de terminal:

```shell
watch ls /home/operador/mirror/ # Carpeta "origen"
watch ls /tmp/minio/data/test/  # Bucket
```

Al lanzar el contenedor `mc mirror`, instantáneamente aparecen en la ventana de _watch_ del _bucket_. El cliente web no se actualiza automáticamente, pero cuando realizo la actualización manual, aparecen los dos ficheros (1.24MB y 127Kb).

Añado un fichero de la carpeta `/home/operador/mirror/`:

```shell
for i in `seq 1 15000`; do echo "Barcelona t'estimo!" >> /home/operador/mirror/bcn.txt; done
```

Después de un segundo, aprox, se sincroniza el fichero automáticamente a la carpeta del _bucket_.

Elimimino un fichero de la carpeta `mirror`:

```shell
rm 100khello.txt
```

No se actualiza automáticamente el contenido del bucket (ni en el carpeta ni a través del interfaz web). Paro el contenedor `minio-client`. Vuelvo a arrancarlo pero no se borra el fichero `100khello.txt`. Al editar el fichero `bcn.txt` en Vim, el cliente de Minio detecta dos ficheros nuevos: `.bcn.txt.swp` y `bcn.txt~`.

Revisando los logs del cliente:

```shell
$ docker logs minio-client
`/tmp/mirror/100khello.txt` -> `local/test/100khello.txt`
`/tmp/mirror/10khello.txt` -> `local/test/10khello.txt`
`/tmp/mirror/bcn.txt` -> `local/test/bcn.txt`
Total: 1.36 MB, Transferred: 1.37 MB, Speed: 1.70 KB/s
mc: <ERROR> Unable to prepare URL for copying. Overwrite not allowed for `http://192.168.1.10:9000/test/bcn.txt`. Use `--force` to override this behavior.
`/tmp/mirror/.bcn.txt.swp` -> `local/test/.bcn.txt.swp`
`/tmp/mirror/bcn.txt~` -> `local/test/bcn.txt~`
$
```

Paro de nuevo el contenedor y vuelvo a arrancarlo, pero no se actualiza ningún fichero. Tampoco hay modificaciones en los logs.

En la carpeta `/home/operador/mirror/` tengo:

```shell
10khello.txt
bcn.txt
```

En la carpeta `/tmp/minio/data/test/`, sin embargo:

```shell
.bcn.txt.swp
100khello.txt
10khello.txt
bcn.txt
bcn.txt~
```

Al eliminar cualquier fichero desde el cliente web, desaparece automáticamente de la carpeta del _bucket_, pero el cliente no actualiza el cambio en `/mirror`.

La creación de ficheros sí que funciona, pero no funciona en sentido contrario:

```txt
~/mirror --> /tmp/minio/data/test OK
/tmp/minio/data/test --> ~/mirror KO
​````

Revisando la documentación de [`mc mirror`](https://docs.minio.io/docs/minio-client-complete-guide#mirror) puede interpretarse que `mirror` no realiza una copia bidireccional, sino únicamente **from a single source to a single destination**, lo que parece significar que sólo se realiza la replicación de los ficheros en un sentido. Lo que no entiendo es porqué no se borran en el _bucket_ los ficheros eliminados en la carpeta "origen".

Para eliminar un fichero del bucket, parece que la única vía es hacerlo de forma explícita usando el cliente `mc` con el comando `rm`:

​```shell
$ docker run --rm -v /home/operador/config:/root/.mc/   -v /home/operador/mirror:/tmp/mirror minio/mc rm local/test/test.txt
Removing `local/test/test.txt`.
```

## Cliente Minio como sidecar

Si el comportamiento correcto es éste, es decir, que se _suben_ los nuevos ficheros pero no se eliminan los que se borran, no es viable usar el _bucket_ en Minio como almacenamiento, ya que el _bucket_ siempre tendería a llenarse, pero nunca se eliminarían los ficheros borrados (que se volverían a descargar en los nuevos _pods_).

Revisando la documentación de Minio me he dado cuenta de que no hay ningún comando para "descargar" un fichero del _bucket_ al equipo local (lo he intentado invirtiendo el orden de los argumentos de `mc cp`, pero no funciona.)

El siguiente paso será revisar el artículo [Minio, simple storage for your cluster](http://larmog.github.io/2017/03/16/minio-simple-storage-for-your-cluster/) a fondo.