+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev", "ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "integracion continua", "jenkins"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/jenkins.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}

title=  "Pipeline - Creacion del job en Jenkins"
date = "2018-05-21T12:03:50+02:00"
+++

Una vez tenemos código en el repositorio de [Gogs]({{< ref "180521-subiendo-el-codigo-a-gogs.md" >}}), para poder avanzar tenemos que definir y configurar el _pipeline_ en Jenkins.
<!--more-->

1. Accedemos a Jenkins y pulsamos sobre el enlace _New item_ en el panel lateral.
1. Especificamos un nombre para el nuevo _job_; por ejemplo `Hello World`.
1. Seleccionamos _Pipeline_ en la lista de tipos de proyectos.
1. Pulsamos _Ok_ para crear el _job_.

No configuramos nada y pulsamos _Save_.

Hemos creado un _job_ en Jenkins, aunque todavía no hace nada.

# Configuración de credenciales

Primero configuramos las credenciales que necesitamos para conectar con Gogs (se trata de un repositorio _privado_).

1. Desde la página principal de Jenkins, pulsamos sobre _Credentials_ en el panel lateral.
1. Pulsamos sobre el almacén global de credencials (llamado _Jenkins_).
1. Pulsamos sobre _Global credentials (unrestricted)_ y seleccionamos la opción _Add credentials_.
    1. En el desplegable para el tipo de credencial, seleccionamos _Username with password_ (es la opción por defecto).
    1. En el _scope_, seleccionamos _Global_.
    1. En el campo _Username_, especificamos el usuario con permisos de acceso al repositorio donde se encuentra el código. En nuestro caso, el usuario `operador`.
    1. En el campo _Password_, introducimos la contraseña del usuario.
    1. Podemos dejar el campo _ID_ en blanco; Jenkins genera un ID aleatorio. Para facilitarnos la tarea de identificar las credenciales guardadas -para su uso en scripts, por ejemplo, podemos especificar un _ID_ específico (siempre que sea **único** en Jenkins).
    1. En el campo _Description_ podemos dar una descripción detallada de las credenciales, normas de uso, etc.
1. Tras especificar los campos necesarios para definir las credenciales, pulsamos el botón _Ok_. Esta descripción se muestra junto al nombre de usuario de las credenciales guardadas.

# Borrador del pipeline

En el job, pulsamos sobre _Configure_ en el panel lateral y vamos a la sección _Pipeline_.

Para empezar con un armazón de _pipeline_ como referencia, usamos el ejemplo de la página de Jenkins [Using a Jenkinsfile](https://jenkins.io/doc/book/pipeline/jenkinsfile/#creating-a-jenkinsfile):

```shell
pipeline {
    agent any

    stages {
        stage('Build') {
            steps {
                echo 'Building..'
            }
        }
        stage('Test') {
            steps {
                echo 'Testing..'
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying....'
            }
        }
    }
}
```

Copiamos esta _pipeline_ en el apartado _Pipeline_ del job _Hello World_ y pulsamos _Apply_ para guardar los cambios.

Puedes ejecutar este job para comprobar que funciona mediante la opción _Build Now_:

{{< figure src="/images/180521/jenkins-pipeline-first-run.png" w="1042" h="714" caption="Job - First run" >}}

## Checkout del código desde Jenkins

Para generar el artefacto a partir del código, el primer paso es que Jenkins descargue el código desde el repositorio. Para ello, definimos el primer paso en el _pipeline_ como _checkout: General SCM_.

> Seleccionamos el job _Hello World_ y pulsamos sobre el enlace _Pipeline Syntax_ en el panel lateral. Usaremos la herramienta _Snipper Generator_ de Jenkins para ayudarnos a construir el _pipeline_.

Como _SCM_ (_source control method_) especificamos _Git_. En el campo _Repository URL_ indicamos la URL al repositorio en Gogs: `http://192.168.1.209:10080/operador/gs-maven.git`. En _Credentials_, seleccionamos las credenciales definidas en el apartado anterior para el usuario _operador_.

Al pulsar sobre _Generate Pipeline Script_, se genera el código a incluir en el _pipeline_:

```shell
checkout([$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[credentialsId: 'e49daa75-9d6a-4f7b-8ccc-d85288708053', url: 'http://192.168.1.209:10080/operador/gs-maven.git']]])
```

En nuestro _pipeline_, incluimos un nuevo _stage_ para hacer el _checkout_ del código. También podríamos haberlo añadido como un _step_ adicional en el _stage_ **_Build_**.

```shell
pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout([$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[credentialsId: 'e49daa75-9d6a-4f7b-8ccc-d85288708053', url: 'http://192.168.1.209:10080/operador/gs-maven.git']]])
            }
        }
        stage('Build') {
            steps {
                echo 'Building..'
            }
        }
        stage('Test') {
            steps {
                echo 'Testing..'
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying....'
            }
        }
    }
}
```

# Fichero `Jenkinsfile``

En vez de editar el _pipeline_ directamente desde Jenkins, es una buena práctica crear el fichero `Jenkinsfile` y tenerlo controlado en un  repositorio; en nuestro caso, lo colocamos en la raíz del repositorio de código Java.

Accedemos a la máquina de desarrollo y creamos el fichero `Jenkinsfile` con el contenido del campo `Pipeline` del job en Jenkins:

```shell
vi Jenkinsfile
```

Pegamos el contenido en el fichero y lo guardamos.

> Para obtener el _pipeline_ contenido en el fichero `Jenkinsfile`, Jenkins hace un _checkout_ del repositorio, por lo que eliminamos del `Jenkinsfile` el paso de _checkout_ introducido anteriormente.

Finalmente, lo guardamos en el repositorio:

```shell
$ git add Jenkinsfile
$ git commit Jenkinsfile -m "Añadido Jenkinsfile al repositorio."
$ git commit -m "Añadido Jenkinsfile al repositorio."
On branch master
Your branch is ahead of 'origin/master' by 1 commit.
  (use "git push" to publish your local commits)
nothing to commit, working tree clean
$ git push gogs-origin master
Counting objects: 3, done.
Delta compression using up to 2 threads.
Compressing objects: 100% (3/3), done.
Writing objects: 100% (3/3), 598 bytes | 0 bytes/s, done.
Total 3 (delta 1), reused 0 (delta 0)
Username for 'http://192.168.1.209:10080': operador
Password for 'http://operador@192.168.1.209:10080':
To http://192.168.1.209:10080/operador/gs-maven.git
   c2bf553..ec7fc8e  master -> master
$
```

Una vez modificado el `Jenkinsfile` y subido a Gogs, debemos modificar la configuración del job para indicar la ubicación del fichero.

En la sección de _Pipeline_ del job, en el desplegable seleccionamos _Pipeline script from SCM_.

Indicamos que el SCM usado es Git y especificamos la URL y credenciales de acceso. En el campo _Script Path_, como hemos guardado el `Jenkinsfile` en la raíz del repositorio, dejamos `Jenkinsfile`.

Guardamos los cambios y comprobamos que el job se sigue ejecutando con éxito.