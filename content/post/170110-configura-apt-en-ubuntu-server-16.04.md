+++
tags = ["linux", "ubuntu", "apt"]
thumbnail = "images/linux.png"
categories = ["ops"]
date = "2017-01-10T15:01:55+01:00"
title = "Configura el proxy para APT en Ubuntu Server 16.04"

+++

Cómo configurar `apt` para salir a internet a través de un _proxy_ que requiere autenticación.

<!--more-->

La configuración del _proxy_ para `APT` en Ubuntu Server 16.04 se realiza a través del fichero `/etc/apt/apt.conf`.

Crea el fichero si no existe y escribe:

```sh
Acquire::http::Proxy "http://${USERNAME}:${PASSWORD}@proxy.ameisin.vwg:8080/amisin.pac";
```

A continuación, ya puedes actualizar los repositorios usando `apt-get update`.