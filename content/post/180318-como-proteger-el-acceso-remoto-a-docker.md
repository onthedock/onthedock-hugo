+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["ops"]

tags = ["linux", "debian", "docker", "portainer"]

thumbnail = "images/docker.png"

title=  "Cómo proteger el acceso remoto a Docker"
date = "2018-03-18T11:33:24+01:00"

+++
En la entrada  [Portainer: gestión de servidores Docker]({{<ref "180317-portainer.md" >}}) comentaba la necesidad de habilitar el acceso remoto al API de Docker **de manera segura**, apuntando a la documentación oficial de Docker sobre cómo realizar esta configuración.

En esta entrada indico cómo proteger el acceso remoto a un servidor de Docker a través de la API, siguiendo las indicaciones de la documentación oficial en [Protect the Docker daemon socket](https://docs.docker.com/engine/security/https/).

<!--more-->

Básicamente, esta entrada es una traducción comentada de la página oficial de Docker, por lo que en caso de duda, consulta la fuente original.

## Escenario

Vamos a habilitar el acceso remoto a un _host_ donde se ejecuta Docker de manera que otras aplicaciones puedan realizar acciones usando la API de forma segura.

En el siguiente diagrama se muestra el equipo _Docker remoto_ a la izquierda; el objetivo es conectar Portainer a través de TLS para poder gestionar los contenedores en el _host remoto_. La autenticación de la aplicación se realizará a través de los certificados que vamos a generar en esta entrada para proteger el acceso remoto a Docker.

Portainer corre en otro servidor Docker "local" (a la derecha, en el diagrama), aunque este hecho no es relevante para la protección del servidor remoto.

{{< figure src="/images/180318/docker-remote-secure-configuration.png" h="323" >}}

## Crea una entidad certificadora (CA)

> Estos comandos deben ejecutarse en la máquina con el servidor Docker, es decir, donde corre el _Docker daemon, dockerd_. Esta es la máquina "Docker remote".

Generamos las claves privadas y públicas de la entidad certificadora (CA):

```shell
$ openssl genrsa -aes256 -out ca-key.pem 4096
Generating RSA private key, 4096 bit long modulus
...........................................++
..................................................................................................................++
e is 65537 (0x10001)
Enter pass phrase for ca-key.pem:
Verifying - Enter pass phrase for ca-key.pem:
$ ls
ca-key.pem

$ openssl req -new -x509 -days 365 -key ca-key.pem -sha256 -out ca.pem
Enter pass phrase for ca-key.pem:
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [AU]:ES
State or Province Name (full name) [Some-State]:Barcelona
Locality Name (eg, city) []:
Organization Name (eg, company) [Internet Widgits Pty Ltd]:Ameisin Labs
Organizational Unit Name (eg, section) []:Development
Common Name (e.g. server FQDN or YOUR name) []:192.168.1.24
Email Address []:xavi.aznar@xxxxxxxxxxxx.xxx
operador@docker-api:~$ openssl genrsa -out server-key.pem 4096
Generating RSA private key, 4096 bit long modulus
.......................................++
..............................................................................................................................................................++
e is 65537 (0x10001)
```

## Crea una clave para el servidor y una petición de firma del certificado (CSR)

Una vez tenemos la entidad certificadora, creamos una clave para el servidor y una _certificate signing request_ (CSR). Como indica la documentación de Docker, asegúrate que el "Common Name" coincide con el _hostname_ que se usará para conectar al servidor remoto de Docker.

En este ejemplo usaremos la IP del servidor remoto para el _common name (CN)_, ya que no está dado de alta en el DNS.

```shell
$ openssl genrsa -out server-key.pem 4096
Generating RSA private key, 4096 bit long modulus
.......................................++
..............................................................................................................................................................++
e is 65537 (0x10001)
$ openssl req -subj "/CN=192.168.1.24" -sha256 -new -key server-key.pem -out server.csr
$ ls
ca-key.pem  ca.pem  server-key.pem  server.csr
```

## Firma la petición de firma del certificado (CSR)

Las conexiones TLS se pueden realizar usando la IP o el _hostname_, por lo que debemos especificar los dos métodos en la creación del certificado.

> En mi caso el equipo remoto no está dado de alta en el DNS; pero para no modificar demasiado las instrucciones de la página de Docker, he indicado la IP como "nombre" DNS del equipo.

Como direcciones IP usamos tanto la IP privada asignada al equipo, como la dirección de bucle local, _localhost_, 127.0.0.1.

```shell
$ echo subjectAltName = DNS:192.168.1.24,IP:192.168.1.24,IP:127.0.0.1 >> extfile.cnf
```

A continuación indicamos en los atributos extendidos de la clave del servidor que únicamente se usará para autenticación del servidor

```shell
$ echo extendedKeyUsage = serverAuth >> extfile.cnf
```

El contenido del fichero `extfile.cnf`  queda:

```shell
$ cat extfile.cnf
subjectAltName = DNS:192.168.1.24,IP:192.168.1.24,IP:127.0.0.1
extendedKeyUsage = serverAuth
```

Ahora, firmamos el CSR (con una validez de 1 año):

```shell
$ openssl x509 -req -days 365 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem \
>   -CAcreateserial -out server-cert.pem -extfile extfile.cnf
Signature ok
subject=/CN=192.168.1.24
Getting CA Private Key
Enter pass phrase for ca-key.pem:
```

## Crea la clave para el cliente y la petición de firma del certificado (CSR)

> Los siguientes comandos se pueden ejecutar, por comodidad, en la máquina del servidor de Docker

```shell
$ openssl genrsa -out key.pem 4096
Generating RSA private key, 4096 bit long modulus
............++
.......++
e is 65537 (0x10001)
$ openssl req -subj '/CN=client' -new -key key.pem -out client.csr
```

Para que la clave generada pueda ser usada para autenticar a un cliente, creamos un fichero de configuración de extensiones:

```shell
$ echo extendedKeyUsage = clientAuth >> extfile.cnf
```

Ahora ya podemos firmar el certificado:

```shell
$ openssl x509 -req -days 365 -sha256 -in client.csr -CA ca.pem -CAkey ca-key.pem \
>   -CAcreateserial -out cert.pem -extfile extfile.cnf
Signature ok
subject=/CN=client
Getting CA Private Key
Enter pass phrase for ca-key.pem:
```

Una vez generados los certificados `cert.pem`  y `server-cert.pem`, podemos borrarlos las peticiones de firma CSR:

```shell
$ rm -v client.csr server.csr
removed 'client.csr'
removed 'server.csr'
```

## Protege las claves secretas

Para proteger los ficheros con las claves secretas en el servidor el siguiente paso es cambiar los permisos de manera que sólo sean legibles por tu usuario:

```shell
$ chmod -v 0400 ca-key.pem key.pem server-key.pem
mode of 'ca-key.pem' changed from 0664 (rw-rw-r--) to 0400 (r--------)
mode of 'key.pem' changed from 0664 (rw-rw-r--) to 0400 (r--------)
mode of 'server-key.pem' changed from 0664 (rw-rw-r--) to 0400 (r--------)
```

# Configura el _daemon_ de Docker 

Hasta ahora hemos generado los diferentes certificados para poder proteger las conexiones con Docker.

El siguiente paso es configurar Docker para aceptar únicamente conexiones desde clientes que proporcionen certificados firmados por la CA creada al principio de este artículo.

Edita el fichero `/etc/systemd/system/docker.service.d/override.conf` de manera que a línea `ExecStart` incluya los parámetros de configuración de TLS:

```shell
ExecStart=/usr/bin/dockerd --tlsverify --tlscacert=/home/operador/ca.pem --tlscert=/home/operador/server-cert.pem  --tlskey=/home/operador/server-key.pem -H fd:// -H tcp://0.0.0.0:2376
```

* `—tlsverify` Habilita la validación de los clientes usando TLS
* `—tlscacert` y `—tlscert` certificados de la CA y del servidor
* `--tlskey` clave privada del servidor
* `-H fd://` seguimos usando escuchando conexiones a través del _socket_ de Docker (suponemos que los usuarios "locales" -o vía SSH- al servidor son de confianza)
* `-H tcp://0.0.0.0:2376` escuchamos conexiones en cualquier IP del _host_ vía TCP en el puerto 2376 (el puerto elegido por convención para las conexiones cifradas)

Después de guardar los cambios realizados en el fichero `override.conf`, recargamos la configuración del _daemon_ de Docker y reiniciamos el servicio para que tenga efecto:

```shell
$ sudo systemctl daemon-reload
$ sudo systemctl restart docker
```

## Conecta usando TLS

Para probar que Docker acepta conexiones protegidas por TLS, copia los ficheros `ca.pem`, `cert.pem` y `key.pem` al equipo desde donde deben realizarse las conexiones.

>  Disponiendo de las claves cualquier usuario puede realizar operaciones en el equipo remoto donde se ejecuta Docker. Como un usuario con permisos de ejecución de Docker tiene permisos equivalentes a los del _root_, las claves deben protegerse del mismo modo que el password de `root`. 

Para validar que todo funciona como debe, ejecuta `docker version` usando TLS:

```shell
$ docker --tlsverify --tlscacert=ca.pem --tlscert=cert.pem --tlskey=key.pem \
>   -H=192.168.1.24:2376 version
Client:
 Version:	17.12.1-ce
 API version:	1.35
 Go version:	go1.9.4
 Git commit:	7390fc6
 Built:	Tue Feb 27 22:17:40 2018
 OS/Arch:	linux/amd64

Server:
 Engine:
  Version:	17.12.1-ce
  API version:	1.35 (minimum version 1.12)
  Go version:	go1.9.4
  Git commit:	7390fc6
  Built:	Tue Feb 27 22:16:13 2018
  OS/Arch:	linux/amd64
  Experimental:	false
```

## Configura un _endpoint_ seguro desde Portainer

Si recuedas el escenario descrito al inicio de la entrada, el objetivo era utilizar las conexiones remotas **seguras** desde Portainer para gestionar los contenedores en el servidor de Docker remoto:

{{< figure src="/images/180318/docker-remote-secure-configuration.png" h="323" >}}

Después de configurar el servidor de Docker remoto para aceptar únicamente conexiones remotas protegidas por TLS, ahora creamos un nuevo _endpoint_ en Portainer. Habilitamos TLS y seleccionamos la opción _TLS with server and client verification_, para lo que tenemos que subir a la aplicación los certificados  `ca.pem`, `cert.pem` y `key.pem` :

{{< figure src="/images/180318/portainer-tls-config.png" h="834" >}}

Después de configurar el _endpoint_ seguro, validamos que podemos visualizar la información usando Portainer:

{{< figure src="/images/180318/portainer-connected-via-tls.png" h="365" >}}

# Resumen

En esta entrada se indican los pasos a seguir para configurar el acceso remoto a un servidor Docker usando la API http protegida por TLS.

La primera parte del artículo se centra en la creación de los certificados, mientras que en la segunda se configura el Docker _daemon_ para aceptar conexiones cifradas con TLS. Al final, se indica cómo configurar Portainer para conectar usando TLS con el servidor Docker.

