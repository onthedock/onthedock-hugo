+++
draft = false

categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["git"]

thumbnail = "images/git.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" %}}

title=  "Gestionar múltiples identidades en Git"
date = "2020-05-09T18:46:35+02:00"
+++
He encontrado este artículo [Automatically keeping Git identities distinct between accounts](https://www.sep.com/sep-blog/2019/01/03/automatically-keeping-git-identities-distinct-between-accounts/) hojeando el blog de la empresa [SEP](https://www.sep.com/) después de leer un artículo sobre *testing* de plantillas de CloudFormation.

La configuración que indica Aaron Alexander en el artículo referenciado permite usar una identidad concreta para cada cuenta de Git.

Esto te permite identificarte con tu cuenta de empresa en los repositorios de la empresa, en los personales con una dirección de correo personal, etc.
<!--more-->

Una de las primeras cosas que haces al instalar Git es especificar el nombre y la dirección de correo que se asocia a los *commits* que realizas. Lo habitual es realizar la configuración a nivel global -para todos los repositorios- ya que es un poco tedioso tener que configurar en cada repositorio esta información una y otra vez.

El problema de establecer esta *identidad global* es que se aplica a todos los repositorios. En el caso de Aaron Alexander, esto es un problema ya que tiene repositorios de su empresa, repositorios personales y repositorios de diferentes clientes.

Realizar la configuración a nivel de repositorio es tedioso y repetitivo, por lo que usa la funcionalidad de [*inclusión condicional*](https://git-scm.com/docs/git-config#_includes) que ofrece Git.

De esta forma, para cada proyecto, crea un fichero específico `.gitconfig-personal`, `.gitconfig-work`, `gitconfig-client-a`, etc con la información de la *identidad* que usa en ese proyecto/cliente:

> `.gitconfig-personal`

```ini
[user]
    name = Xavi Aznar
    email = xavi.aznar@ejemplo.com
```

> `.gitconfig-work`

```ini
[user]
    name = Xavier Aznar
    email = xavier.aznar@corp.com
```

En el fichero de configuración `.gitconfig`, incluye el fichero de indentidad que corresponda mediante los *conditional includes*:

```ini
[includeIf "gitdir:~/Projects/Personal/"]  
    path = .gitconfig-personal  
  
[includeIf "gitdir:~/Projects/Work/"]  
    path = .gitconfig-work  
  
[includeIf "gitdir:~/Projects/Work/Client-A/"]  
    path = .gitconfig-client-a
```

Estos ficheros de configuración los tiene organizados por carpetas:

```text
~/Projects  
~/Projects/Personal  
~/Projects/Work  
~/Projects/Work/Client-A
```

De esta forma, cuando realiza un *commit* Git selecciona automáticamente la identidad correspondiente al proyecto en el que está trabajando.

Aunque Aaron no lo comenta explícitamente, de la documentación oficial de Git para las inclusiones condicionales:

> If the pattern ends with `/`, `**` will be automatically added. For example, the pattern `foo/` becomes `foo/**`. In other words, it matches "foo" and everything inside, recursively.

Es decir, si el patrón acaba en `/`, se añade automáticamente `**`, lo que permite aplicar el *conditional include* -y por tanto la configuración de la identidad de Git específica- **a todos los repositorios bajo esa ruta**.
