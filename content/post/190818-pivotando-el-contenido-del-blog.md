+++
draft = false

categories = ["dev", "ops"]
tags = ["blog"]
thumbnail = "images/roadmap.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}

title=  "Pivotando el contenido del blog"
date = "2019-08-18T18:28:01+02:00"
+++
En las metodologías ágiles, se habla de _pivotar_ cuando se cambia el modelo de negocio de una empresa -normalmente una _start up_- para adaptarse a las necesidades de los usuarios y potenciales clientes.

<!--more-->
En mi caso, el _pivotaje_ ha sido motivado por un "giro hacia la nube" de mi trabajo. He tenido que centrar mis esfuerzos en los detalles de desplegar una _landing zone_ alrededor de la cual poder desplegar la estrategia empresarial de la empresa para la que trabajo.

Aunque una de los _selling points_ de la nube es la agilidad para abrir una cuenta y empezar a lanzar desplegar elementos, este enfoque sólo es asumible por un desarrollador independiente.

A nivel empresarial es necesario planificar cómo se va a integrar esta nueva plataforma dentro de los sistemas y procesos establecidos en la empresa. Y con "sistemas y procesos" me refiero a **TODOS** los sistemas y procesos: la creación de las cuentas, la gestión de usuarios y políticas, la facturación, la seguridad, el acceso remoto, las políticas de backup, etc, etc, etc.

E incluso después de haber dedicado un tiempo a pensar en la mejor manera de dar respuesta a todas estas cuestiones, es importante tener la suficiente flexibilidad para poder adaptarse a nuevos escenarios que -en su momento- no fuimos capaces de anticipar o para aquellos casos de uso que todavía no se nos han presentado.

Además de unas nececidades cambiantes por parte de nuestros usuarios, el mundo _cloud_ se mueve de forma mucho más rápida que la "IT tradicional", con la aparición de nuevos productos y servicios cada pocos meses.

La cantidad de tiempo que tengo es limitada; tras reflexionar he decidido priorizar todavía más la parte de infraestructura, centrándome en este caso en la plataforma cloud en sí.

En un futuro cercano tendré una mayor exposición a [OpenShift](https://www.openshift.com/) (de RedHat), por lo que es probable que las entradas sobre Kubernetes tengan cierta influencia de este producto.

Sigo usando Docker (especialmente Docker Compose) para realizar pruebas de cosas como [Concourse CI](https://concourse-ci.org/) (un servidor de CI/CD realmente interesante) en la línea de contenidos DevOps, aunque probablemente volveré a centrarme en [Jenkins](https://jenkins.io/) (de nuevo, debido a la "integración" entre OpenShift).

He intentado combinarlo con Hugo para "matar dos pájaros de un tiro": revisar el uso este servidor de CI/CD y promocionar el uso de Markdown como formato base de la documentación del nuevo departamento.

Esta revisión me ha servido para aprender mucho sobre la configuración de Hugo y para revisar nuevos temas -me ha gustado mucho [Learn](https://themes.gohugo.io/hugo-theme-learn/)- así como para probar las opciones de internacionalización (que finalmente no usaré).

En las Rapsberry he estado testeando [K3S](https://k3s.io/) de RancherLabs...

Como ves, sigo interesado -y aprendiendo- en los grandes ejes que articulan el blog... solo que no tengo apenas tiempo de escribir nuevos artículos.
