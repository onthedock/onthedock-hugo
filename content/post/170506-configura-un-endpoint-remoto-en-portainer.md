+++
categories = ["ops"]
tags = ["linux", "debian", "docker", "portainer"]
draft = false
date = "2017-05-06T17:38:20+02:00"
title = "Configura un endpoint remoto en Portainer"
thumbnail = "images/portainer.png"

+++

En el artículo [Portainer para gestionar tus contenedores en Docker]({{< ref "170429-portainer-para-gestionar-tus-contenedores-en-docker.md" >}}) usamos **Portainer** para gestionar el Docker Engine local.

En el artículo [Habilita el API remoto de Docker]({{< ref "170506-habilita-el-acceso-remoto-via-api-a-docker.md">}}) habilitamos el acceso remoto al API de Docker Engine.

En este artículo configuramos **Portainer** para conectar con un _endpoint_ remoto (el API expuesta de un Docker Engine).
<!--more-->

Accede a **Portainer** y selecciona _Endpoints_ en el panel izquierdo.

Para configurar el _endopoint_ remoto (no seguro) sólo necesitas proporcionar un nombre para el _endpoint_ y la URL de acceso:

{{% img src="images/170506/1-configure-endpoint.png" w="935" h="660" caption="Configura un nuevo endpoint" %}}

Para identificar qué Docker Engine estoy viendo en cada momento, indico la IP de la máquina, seguido de la plataforma y el _host_ en el que se encuentra.

Para cambiar entre los diferentes _endpoints_ definidos en **Portainer**, selecciona el que quieres gestionar en el desplegable de la parte superior del panel lateral:

{{% img src="images/170506/2-change-endpoint.png" w="450" h="168" caption="Cambia entre los diferentes endpoints definidos" %}}