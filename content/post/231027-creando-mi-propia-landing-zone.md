+++
categories = ["dev"]

tags = [ "cloud", "landing zone"]

thumbnail = "images/roadmap.png"

# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}

title=  "Creando mi propia Landing Zone (a escala)"
date = "2023-10-28T07:10:42+02:00"
+++
Llevo aproximadamente una año y medio en un proyecto de lo más interesante, pero de esos que "nadie ve"; junto a mis compañeros, diseño, implmento y mantengo una "landing zone".

Cada uno de los principales *cloud providers* tienen su propia definición al respecto de lo que es una *landing zone*:

- [Landing zone design in Google Cloud](https://cloud.google.com/architecture/landing-zones)
- [What is a landing zone?](https://docs.aws.amazon.com/prescriptive-guidance/latest/migration-aws-environment/understanding-landing-zones.html)
- [What is an Azure landing zone?](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/)

De la definición de Google:

> A landing zone, also called a *cloud foundation*, is a modular and scalable configuration that enables organizations to adopt Google Cloud for their business needs. A landing zone is often a prerequisite to deploying enterprise workloads in a cloud environment.

Y yo me estoy montando la mía (sin tener un *cloud provider*).
<!--more-->

Un elemento común a todas las definiciones es que es un "conjunto de configuraciones". Otro aspecto destacable es que "es un prerequisito para desplegar cargas de trabajo" en el cloud.

De la definición de AWS, destacaría el párrafo:

> Building a landing zone involves technical and business decisions to be made across account structure, networking, security, and access management in accordance with your organization’s growth and business goals for the future.

Al final, se trata de un conjunto de decisiones **técnicas** y de **negocio** relacionadas con la gestión de cuentas, configuración de red, seguridad y gestión de accesos.

Al tratarse del "foundation", es decir, de los *cimientos* para el uso del proveedor cloud de turno, es un trabajo del que la gente, en general, no es conocedora. Cuando la gente piensa en usar AWS, por ejemplo, cree que lo único que necesita para empezar es disponer de una tarjeta de crédito y una dirección de correo. Obviamente, si eres un desarrollador/emprendedor independiente, seguramente es así. Pero este enfoque no "escala" cuando quieres usar un proveedor cloud en una empresa.

## ¿Cómo explicar qué es una *landing zone* sin usar un proveedor de cloud?

Usar un proveedor de cloud **cuesta dinero**. Todos los proveedores ofrecen cuotas de algunos servicios de manera gratuita, pero el *riesgo* de incurrir en costes supone una barrera para probar según qué cosas.

Además, el usar un proveedor cloud te obliga a hacer las cosas de una forma determinada manera. Cada proveedor cloud tiene su propia "nomenclatura": por ejemplo, la "unidad básica" de "porción de cloud" es una **cuenta** en AWS, un **proyecto** en Google Cloud o un **tenant** en Azure.

Pero mi objetivo no es hablar de cómo implementar una *landing zone* en éste o aquel proveedor cloud, sino **el concepto** de qué es y para qué sirve una *landing zone*.

Así que he he intentado restringirme al máximo al **concepto**, no sólo de la *landing zone*, sino al resto de elementos implicados.

### ¿Qué es lo esencial de un proveedor cloud?

Empecemos por el *proveedor cloud*; un proveedor cloud es un sistema que permite gestionar "recursos" (de computación, en un sentido amplio), en una plataforma a la que sólo se tiene acceso (limitado) a través de una API.

Un sistema que permite hacer eso mismo es Kubernetes: a través de una API puedo desplegar aplicaciones de manera *equivalente* a como lo haría en un proveedor cloud.

Un proveedor cloud es un sistema donde conviven recursos de diferentes clientes, pero que están aislados unos de otros. En AWS, a través de una "cuenta", en Google Cloud, un proyecto: el equivalente en Kubernetes es un *namespace*.

### Landing zone

En cuanto a una *landing zone*, todas las definiciones coinciden en que se trata de un conjunto de configuraciones que sirven como base para el despliegue de las cargas de trabajo.

Una configuración básica de seguridad es que sólo los usuarios autorizados pueden acceder a una determinada aplicación.

Otro requerimiento de negocio suele ser que cualquier aplicación disponga de una serie de medidas para la recuperación ante un desastre (*disaster recovery*).

Como el objetivo es el de **explicar** en qué consiste la *landing zone*, creo que con estas dos configuraciones básicas será suficiente para empezar.

Usando Kubernetes como sustituto de la plataforma cloud, otros temas como la configuración de *billing* o el *networking* serían más complicados de demostrar.

### Automatización

No forma parte de la "definición" de la *landing zone* en sí misma. Sin embargo, de forma implícita, el proceso para realizar las configuraciones necesarias para la *landing zone* **deben ser automatizadas**.

Cada vez que un equipo solicita acceso a la plataforma, todas las configuraciones que componen la *landing zone* deben aplicarse.

En función del proveedor cloud, algunas configuraciones pueden realizarse a nivel de "organización", que es como suelen denominarse un conjunto de cuentas o proyectos que pertenecen a la misma empresa. Sin embargo otros deben configurarse para cada cuenta/proyecto.

Al disponer de una API, podemos crear *scripts* o algún otro mecanismo para aplicar las mismas configuraciones, de forma homogénea, una y otra vez.

Para ello se establecen *pipelines* que se ejecutan en respuesta a eventos. La forma más básica de "evento" sería la recepción de un *ticket* solicitando un proyecto. Esto es lo que a veces se llama *ticketOps*.

Sin embargo, lo ideal es que el cliente sea autónomo y pueda solicitar un nuevo proyecto a través de un sistema de *auto-servicio* como un portal web.

### Conclusión

En siguientes artículos iré desgranando el trabajo que llevo un tiempo haciendo en este proyecto de "*landing zone* a escala".

Por ahora, lo importante es el *concepto* de *landing zone*: un conjunto de configuraciones que sirven como base para que los equipos de trabajo puedan desplegar sus aplicaciones en un sistema objetivo de forma escalable, segura y alineada con las necesidades de la empresa:

{{< figure src="/images/231028/lz-basics.svg" width="100%" >}}
