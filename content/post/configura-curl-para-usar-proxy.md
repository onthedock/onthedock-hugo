+++
categories = ["ops"]
tags = ["linux", "curl"]
date = "2017-01-11T08:22:56+01:00"
title = "Configura curl para usar un proxy"
thumbnail = "images/linux.png"

+++

Cómo configurar `curl` para salir a internet a través de un _proxy_ que requiere autenticación.

<!--more-->

Como la VM está detrás de un _proxy_, primero tienes que indicar a `curl` la dirección del mismo. La manera más sencilla de solucionar el problema de una vez por todas es indicar la URL del _proxy_ en el fichero `.curlrc`, en la carpeta _home_ del usuario.

Si estás trabajando con el usuario `root`, coloca el fichero en `/root/.curlrc`.

Edita el fichero y añade la dirección del _proxy_:

```bash
proxy = https://${USERNAME}:${PASSWORD}@proxy.ameisin.com:8080/proxy.pac
```

---

Referencia: [How to setup curl to permanently use a proxy? [closed]](http://stackoverflow.com/questions/7559103/how-to-setup-curl-to-permanently-use-a-proxy))