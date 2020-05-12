+++
draft = false

categories = ["dev", "ops"]
tags = ["docker", "git", "gitea"]
thumbnail = "images/gitea.jpg"

title=  "Gitea: la versión mejorada de Gogs"
date = "2018-07-13T20:04:36+02:00"
+++

Gogs es un servidor web de repositorios Git (a lo GitHub). He hablado otras veces de lo sencillo que es montarlo usando Docker, de manera independiente ([usando SQLite]({{< ref "171106-gogs-como-crear-tu-propio-servicio-de-hospedaje-de-repos-git.md">}}) como base de datos o [con MySQL]({{< ref "180520-pipeline-gogs-el-repositorio-de-codigo.md">}})).

A través de este artículo [6 Github alternatives that are open source and self-hosted](https://www.cyberciti.biz/open-source/github-alternatives-open-source-seflt-hosted/) descubrí hace unos días [Gitea](https://gitea.io) y a continuación te explico porqué creo que es todavía mejor que Gogs.
<!--more-->

Gitea es un _fork_ de Gogs. Los autores explican en [Welcome to Gitea](https://blog.gitea.io/2016/12/welcome-to-gitea/) los motivos por los que crearon este producto de forma paralela a Gogs. Básicamente, Gogs es un proyecto gestionado y mantenido por una única persona, @Unknwon. Los autores de Gitea contactaron con @Unknwon e intentaron que diera permisos de escritura sobre el repositorio a otros desarrolladores, para colaborar en el desarrollo de Gogs. @Unknwon considera Gogs como su creación y quiere seguir trabajando en su proyecto de forma autónoma... Y así surgió Gitea, gracias a la magia del _open source_.

Desde entonces los dos proyectos avanzan de forma separada, aunque todavía comparten muchos aspectos en común. El modelo de gestión abierto a la participación de la comunidad de Gitea le ha permitido avanzar de forma más ágil.

Las diferencias entre Gitea, Gogs y otros (Github, Bitbucket, RhodeCode) las puedes encontrar en [Gitea compared to other Git hosting options](https://docs.gitea.io/en-us/comparison/); Gitea soporta autenticación de doble factor (_two factor authentication_), más funcionalidades relativas a la gestión del código, granularidad en los roles, firma de _commits_ con GPG, restricción de _push_ y _merge_ a usuarios específicos, estado de integración con _pipelines_ CI/CD externas, etc...

En un entorno empresarial, características como la firma de _commits_ o la autenticación de doble factor pueden ser aspectos decisivos en la adopció de Gitea frente a Gogs. Aunque también son relevantes la integración con LDAP o la mayor granularidad en los permisos.

Una comunidad más amplia da lugar a una [documentación más exhaustiva](https://docs.gitea.io/en-us/), [blog](https://blog.gitea.io/), [foro](https://discourse.gitea.io/), [canal de chat](https://discord.gg/NsatcWJ) y una [API](https://try.gitea.io/api/swagger)...

A medida que exploro las funcionalidades de Gitea, descubro pequeños detalles que lo hacen más amigable, como la posibilidad de personalizar las páginas, la funcionalidad para crear un [backup completo](https://docs.gitea.io/en-us/backup-and-restore/) o [generar automáticamente certificados](https://docs.gitea.io/en-us/https-setup/) para el acceso vía HTTPS.

¡Échale un vistazo por tí mismo y enamórate de [Gitea](https://gitea.io)!
