+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["kubernetes", "helm", "gitea"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/helm.svg"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

title=  "Revisión de la Helm chart oficial de Gitea"
date = "2021-05-29T20:34:40+02:00"
+++

Iba a escribir sobre las *lecciones aprendidas* al intentar crear una *Helm Chart* desde cero en una entrada cuando descubrí que [las imágenes habían dejado de mostrarse en el blog]({{< ref "210522-bug-no-se-muestran-imagenes-en-el-blog.md" >}}). Eso me hizo reconducir mis esfuerzos en corregir el problema y dió al traste con la entrada que tenía a medias...

Desde entonces he enfocado los esfuerzos en entender cómo funciona la *chart* oficial para Gitea y en instalarla para ver qué posibilidades de personalización ofrece.

En esta entrada me enfoco en la primera parte: analizar las elecciones realizadas por el equipo de Gitea a la hora de crear la *chart* oficial.
<!--more-->

## Lecciones aprendidas

Escribir una *chart* no es difícil; de hecho, es sorprendentemente sencillo. Sin embargo, hay una gran diferencia entre una *chart* que funciona y otra que además, es lo suficientemente flexible para ajustarse a cualquier entorno o necesidad.

Por eso, en respuesta a los comentarios de Arturo E.S. me mostraba tan optimista:

{{< figure src="/images/210529/gitea-helm-chart.png" width="800" >}}

Avanzaba sin problemas con la creación de las plantillas para los diferentes recursos necesarios para desplegar Gitea usando mi *chart* "custom", pero el *pod* entraba en *CrashLoopBackOff* por lo que parecía un problema con la configuración.

> Como nota al margen, parece que la causa de que los *crasheos* del *pod* aplicando la configuración del artículo del 12/2020 podían estar causados por cambios introducidos en la versión 1.14.x de Gitea.

Para crear el *ConfigMap* en el que guardaba el fichero `app.ini` de la configuración de Gitea había usado los valores de la entrada [Desplegar Gitea en Kubernetes]({{< ref "201212-desplegar-gitea-en-kubernetes.md" >}}), así que no entendía que podía estar pasando...

Acudí a la [*chart* oficial de Gitea](https://gitea.com/gitea/helm-chart) y empecé a ver **muchas** diferencias con mi aproximación al despliegue de la aplicación.

Así que me concentré en revisar la *chart* oficial y aprender de ella.

## Análisis de la *chart* oficial de Gitea (desde el punto de vista de un novato en Helm)

Al revisar la *chart* oficial, una de las cosas que me llamó la atención es que en vez de usar un *Deployment* para el despliegue, se usara un *StatefulSet*. Al ver los motivos tras esta decisión (entre otras), me di cuenta de quizás sería mucho más útil revisar cómo se construye una *chart* "productiva" y aprender de ella, en vez de partir de cero y cometer errores que otros ya solventaron en su día...

## Dependencias y elementos opcionales

Una de las cosas que proporciona la *chart* de Gitea es la posibilidad de habilitar o deshabilitar la instalación de dependencias a través de la configuración.

> Al habilitar algunas de las dependencias, como las bases de datos o la cache, la *chart* las instala y configura automáticamente. Las *charts* usadas para instalar las dependencias se pueden ver en el fichero [`Chart.yaml`](https://gitea.com/gitea/helm-chart/src/branch/master/Chart.yaml).
>
> Este sistema sigue las *best practices* descritas en la documentación oficial de Helm: [Conditions and Tags](https://helm.sh/docs/chart_best_practices/dependencies/)

Así, en función de si el componente está habilitado o no, se incluye en la configuración el objeto o los parámetros correspondientes; por ejemplo, el *Ingress* (`ingress.enabled: false`) o las métricas para Prometheus:

```yaml
gitea:
  <...>
    {{- if not (hasKey .Values.gitea.config "metrics") -}}
    {{- $_ := set .Values.gitea.config "metrics" dict -}}
    {{- end -}}
  <...>
```

La configuración de Gitea está dividida en dos; por un lado, la configuración a través del fichero `app.ini`, definido en un *configMap* en el fichero `helm-chart/templates/gitea/config.yaml`; por otro, un *secret*  en el que encontramos un *script* de inicialización.

## Creación del primer usuario en Gitea

Para la configuración de valores *sensibles*, como contraseñas de conexión con la base de datos o con los *identity providers* se realiza a través de un fichero de inicialización que se monta en el contenedor a través del *secret* `helm-chart/templates/gitea/init.yaml`.

Gitea guarda la configuración del usuario con permisos de administrador en la base de datos. Al instalar Gitea, no hay ningún usuario dado de alta; el primer usuario creado asume permisos de administrador. Este usuario se puede crear en el *wizard* de instalación o mediante la función de registro en la web de Gitea.

Para que la instalación sea completa, el *script* de instalación permite crear ese usuario usando la herramienta de línea de comandos `gitea`.

Como los valores de configuración se guardan en la base de datos y no en el fichero `app.ini` ni en un *ConfigMap* o *Secret*, sólo con la creación de objetos de Kubernetes vía Helm no podría proporcionarse una solución funcional tras la instalación (todavía sería necesario crear el primer usuario en la base de datos). Así que para generar ese primer usuario se usa el *script* definido en el *Secret* y se lanza al arrancar Gitea.

## Componentes opcionales

El uso de un parámetro como `enabled: true|false` permite habilitar (o deshabilitar) secciones en un cualquier fichero que se procese dentro de la carpeta `templates/`. Esto proporciona la flexibilidad de incluir o eliminar objetos del esquema de arquitectura de la aplicación (como el *Ingress*, por ejemplo) o permitir el uso de diferentes *backends*. Para facilitar la tarea de configuración, los valores *configurables* para aquellos elementos deshabilitados también se incluyen en el fichero `values.yaml`, como *referencia* y/o documentación (aunque a veces están comentados).

## Contraseñas

El uso de un parámetro de configuración en el que se especifica la contraseña del administrador (en `gitea.admin.password`) me parece un punto mejorable; siguiendo el mismo patrón que para aquellas partes opcionales, quizás se podría mejorar introduciendo un parámetro `autogeneratedPassword: true|false` :

```yaml hl_lines="3"
gitea:
  admin:
    autogeneratedPassword: false
    username: gitea_admin
    password: r8sA8CPHD9!bt6d
    email: "gitea@local.domain"
```

Si se quiere un *password* autogenerado, se puede usar algunas de las funciones disponibles en Helm para generarlo. El problema con este sistema, es que las funciones en Helm se evalúan tanto al crear la *release* como al *actualizarla*... Sin embargo, desde la versión 3.1 de Helm la función `Lookup` permite consultar si un recurso existe en la API de Kubernetes y devolver su valor; esto nos permitiría guardar el valor autogenerado en un *Secret* y consultarlo antes de autogenerar una nueva contraseña; sólo lo generamos si el *Secret* no existe [^helm_secret].

En el caso concreto de Gitea, en el que el *password* del usuario administrador no se guarda en un *secret* sino que se almacena en la base de datos, este método no es aplicable.

Sin embargo, la solución de autogenerar el *password* de forma segura (resistente a las  actualizaciones) como indica el artículo, debe considerarse para aquellos casos en los que la contraseña se almacene en un *Secret*.

El valor de la contraseña autogenerada puede incluirse en el fichero `NOTES.txt` que se muestra tras la instalación de la aplicación usando Helm.

El uso de un *script* de inicialización cargado desde un *Secret* o un *ConfigMap* también es una idea interesante para aquellas aplicaciones que requieran una configuración inicial (generalmente, a nivel de base de datos, como creación de tablas o carga de valores).

## *StatefulSet* vs *Deployment*

A la hora de desplegar la aplicación la primera opción en la que habría pensado es la de usar un *Deployment*. El equipo de Gitea usa un *StatefulSet* para conservar los volúmenes en los que se almacenan los repositorios de código ante la eventual eliminación de la aplicación.

Como se indica en la documentación oficial de Kubernetes para los *StatefulSets*, en la sección [Limitations](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#limitations): al borrar y/o escalar (hacia abajo) un *StatefulSet* **no se borran los volúmenes asociados**. Se prefiere priorizar la conservación de los datos ante el borrado de volúmenes que puedan quedar huérfanos (y que será necesario purgar manualmente).

> El uso de un *StatefulSet* para Gitea también influye en el tipo de *Service* generado.

## Servicios

Es posible acceder a Gitea usando HTTP(s) o SSH. Para cada uno de estos métodos de acceso se proporciona un fichero de plantilla para generar un *service*.

En el fichero `values.yaml` hay una sección `service` en la que especificar los puertos de acceso para cada uno de los servicios:

```yaml
service:
  http: 
    port: 3000
  ssh:
    port: 22
```

Por defecto, para los dos servicios se especifica `ClusterIP: None`, lo que genera un *headless service* [^headless_service]. Los *headless services* no proporcionan balanceo de carga entre los *pods* gestionados por el servicio.

> El número de réplicas está configurado en 1 para Gitea. Al desplegarse como *StatefulSet*, cada réplica tiene una identidad estable, lo que incluye los volúmenes. Supongo que ese es el motivo para no balancear las peticiones entre los diferentes integrantes del *StatefulSet* (pero no lo tengo muy claro).

Si se usan *Ingress*, hay que tener en cuenta que no se reenvían los puertos usados para SSH, por lo que hay que usar una solución como un balanceador externo (p.ej, MetalLB).

## Ingress

En la plantilla para el *Ingress* la *chart* usa la capacidad de Helm para detectar la versión de la API del clúster y así determinar el valor de `apiVersion` a configurar en el fichero de definición del *Ingress*.

```yaml
...
{{- if .Capabilities.APIVersions.Has "networking.k8s.io/v1/Ingress" -}}
apiVersion: networking.k8s.io/v1
{{- else if .Capabilities.APIVersions.Has "networking.k8s.io/v1beta1/Ingress" -}}
apiVersion: networking.k8s.io/v1beta1
{{- else -}}
apiVersion: extensions/v1beta1
{{- end }}
kind: Ingress
...
```

El mismo *truco* se usa en la sección de las `rules`para usar `serviceName` o la forma anidada de  (`service.name`)

## ServiceMonitor

El *ServiceMonitor* sólo se crea si se quieren obtener métricas de Gitea para Prometheus, que por lo que parece es un *resource* necesario para que las instancias de Prometheus desplegadas por el operador sepan qué deben monitorizar [^prometheus_operador]. En la documentación de la *chart* se indica que antes de desplegar el objeto *ServiceMonitor* hay que validar que se ha desplegado el operador de Prometheus.

## Tests

En la carpeta `tests/` se incluye el fichero de definición de un *Job* que se conecta usando `wget` a la URL de Gitea, validando si funciona. Usa la anotación `"helm.sh/hook": test-success` que permite validar si Gitea se ha desplegado correctamente (el contenedor debe finalizar sin error (`exit code 0`)).

La anotación actualizada en Helm 3 es `"helm.sh/hook": test`, aunque todavía se acepta `test-success` para mantener compatibilidad con versiones anteriores [^helm_test].

## Resumen

Analizando la *chart* oficial de Gitea he aprendido sobre buenas prácticas, algunos trucos interesantes y tećnicas avanzadas como la gestión de dependencias en las *charts* de Helm.

También he refrescado algunos detalles sobre cómo funciona Gitea que hacía tiempo que no instalaba.

En la siguiente entrada pasaré de la teoría a la práctica, instalando la *chart*, modificando la configuración para cambiar de *backend* y habilitando el *Ingress*, por ejemplo.

[^helm_secret]: La solución procede de este artículo [Auto-Generated Helm Secrets](https://wanderingdeveloper.medium.com/reusing-auto-generated-helm-secrets-a7426403d4bb).

[^headless_service]: [Headless Services](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services)

[^prometheus_operador]: [Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator/blob/master/Documentation/user-guides/getting-started.md).

[^helm_test]: [Chart Tests](https://helm.sh/docs/topics/chart_tests/).
