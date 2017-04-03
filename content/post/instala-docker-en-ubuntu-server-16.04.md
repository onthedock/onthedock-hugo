+++

thumbnail = "images/linux.png"
categories = ["ops"]
tags = ["linux", "docker", "ubuntu"]
date = "2017-01-10T15:12:46+01:00"
title = "Instala Docker en Ubuntu Server 16.04"

+++

Cómo instalar Docker en Ubuntu Server 16.04.

<!--more-->

Para instalar la última versión de Docker, usamos las instrucciones [¿Cómo instalar y usar Docker en Ubuntu 16.04?](https://www.digitalocean.com/community/tutorials/como-instalar-y-usar-docker-en-ubuntu-16-04-es)

```bash
$ sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
```

> No funciona por algún motivo, probablemente por el _proxy_

Para instalar la clave GPG de Docker, el método que funciona es (<small>ref: [Docker website encourages users to import GPG key for apt repository in unsafe ways #17436](https://github.com/docker/docker/issues/17436#issuecomment-151870782)</small>):

```bash
# curl -s  https://get.docker.com/gpg | apt-key add -
OK
```

Agregamos el repositorio de Docker a APT

```bash
sudo apt-add-repository 'deb https://apt.dockerproject.org/repo ubuntu-xenial main'
```

Actualizamos:

```bash
sudo apt-get update
```

Una vez añadido, comprobamos mediante:

```bash
apt-cache policy docker-engine
```

Finalmente, instalamos:

```bash
sudo apt-get install -y docker-engine
```

Si ha habido problemas para validar la autenticidad del paquete de Docker, la instalación debe hacerse sin la aceptación automática (es decir, sin el parámetro `-y`) o añadiendo `--allow-authenticate`.

Verificamos que tenemos docker funcionando:

```bash
# docker version
```
