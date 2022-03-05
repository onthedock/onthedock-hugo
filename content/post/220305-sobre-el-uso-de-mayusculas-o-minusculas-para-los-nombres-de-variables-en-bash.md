+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "bash"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/linux.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/

# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}
# YouTube           {{< youtube w7Ft2ymGmfc >}}
# Gist              {{< gist username 7896402 >}}
# Highlight         {{< highligth language >}}...{{< /highlight >}}
# Twitter           {{< tweet user="SanDiegoZoo" id="1453110110599868418" >}}

title=  "Sobre el uso de mayúsculas o minúsculas en los nombres de variables en Bash"
date = "2022-03-05T11:30:49+01:00"
+++
He estado buscando información sobre cuál es la manera correcta a la hora de definir los nombres de las variables en Bash... Y como en el caso de la eterna batalla entre espacios vs tabs o Vim vs Emacs, parece que no hay una solución definitiva (o seguida por todo el mundo de forma generalizada).
<!--more-->

Respecto a las variables de entorno, en [The Open Group Base Specifications Issue 7, 2018 edition
IEEE Std 1003.1-2017 (Revision of IEEE Std 1003.1-2008)](https://pubs.opengroup.org/onlinepubs/9699919799/xrat/V4_xbd_chap08.html#tag_21_08), en la sección *A.8.1 Environment Variable Definition*, indica:

> The decision to restrict conforming systems to the use of digits, uppercase letters, and underscores for environment variable names allows applications to use lowercase letters in their environment variable names without conflicting with any conforming system.

Es decir, que las variables de entorno definidas por el sistema irán en mayúsculas (pueden usar números y `_`), mientras que las variables definidas por las aplicaciones, usarán únicamente *minúsculas* (aunque también pueden usar números y `_`).

Es decir, según la especificación del IEEE, las variables en Bash deben usar **snake_case**: `proxy_url`, por ejemplo.

## ¡Caso cerrado! ¿O no?

Pues depende... Por motivos históricos, es habitual que en Bash las variables de entorno *de los scripts* se definan completamente en mayúsculas: para hacerlas destacar, por asimilación con las variables del sistema, etc.

Personalmente, no tenía ninguna preferencia, por lo que no seguía ningún patrón concreto... Hasta que empecé a interesarme en Go y encontré una directriz clara al respecto: [Effective Go: Names](https://go.dev/doc/effective_go#mixed-caps)

> Finally, the convention in Go is to use `MixedCaps` or `mixedCaps` rather than underscores to write multiword names.

Así que últimamente, que he estado trabajando en automatizar la configuración de máquinas virtuales con Bash, había seguido esta *recomendación* -importada de Go- en Bash.

## Guías de uso

Al contrario de lo que pasa en Go, que hay unas recomendaciones claras, para la *programación* en *shell* la cosa *depende*... Por un lado, al haber diferentes *shells*, cada una tiene restricciones específicas (generalmente, por motivos históricos). Un ejemplo de ello sería la recomendación de evitar [nombres de variables que empiecen por números](https://pubs.opengroup.org/onlinepubs/9699919799/xrat/V4_xbd_chap08.html):

> In addition to the obvious conflict with the shell syntax for positional parameter substitution, some historical applications (including some shells) exclude names with leading digits from the environment.

La única solución parece ser definir una *guía de estilos* propia dentro de la empresa. En el caso de Google, por ejemplom, la [Shell style guide](https://google.github.io/styleguide/shellguide.html):

- Sólo se admite el uso de Bash ([Which Shell to Use](https://google.github.io/styleguide/shellguide.html#s1.1-which-shell-to-use))
  - Interesante, especialmente teniendo en cuenta que los Mac usan Zsh por defecto en las últimas versiones del sistema operativo.
- Los *scripts* no deben tener extensión (preferentemente) o si la tienen, debe ser `.sh` ([File Extensions](https://google.github.io/styleguide/shellguide.html#s2.1-file-extensions))
  - Siempre he asociado los *scripts* a la extensión `.sh`, pero supongo que es por haber trabajado tanto tiempo en entornos *windowseros*.
- La indentación es de 2 espacios (no tabulaciones) ([Indentation](https://google.github.io/styleguide/shellguide.html#s5.1-indentation))
- La variables y los nombres de funciones deben usar *snake_case*, mientras que las constantes y las variables de entorno, usan mayúsculas (o *SNAKE_CASE*) ([Constants and Environment Variable Names](https://google.github.io/styleguide/shellguide.html#s7.3-constants-and-environment-variable-names))
  - Lo que decía, que ni sí ni no, sino todo lo contrario `¯\_(ツ)_/¯`

Quizás una de las recomendaciones que me ha *chocado* más ha sido en el caso de la definición de funciones (aunque sigue el estándar definido en el apartado [Function Definition Command](https://pubs.opengroup.org/onlinepubs/9699919799/xrat/V4_xcu_chap02.html#tag_23_02_09_18)):

Debe usarse `my_func() {...}` (el uso de `function` es opcional), aunque la sección [Function names](https://google.github.io/styleguide/shellguide.html#s7.1-function-names) indica que el uso de la palabra clave `function` ayuda a identificar las funciones.

Según la [especificación del IEEE](https://pubs.opengroup.org/onlinepubs/9699919799/xrat/V4_xcu_chap02.html#tag_23_02_09_18), se debe usar

```bash
function myfunc { ... }
```

o

```bash
myfunc() { ... }
```

> Observa que en el primer caso no hay paréntesis después del nombre de la función.

## Usar una herramienta para mantener la consistencia

Disponer de una especificación base no asegura consistencia... Google da una paso más y establece una guía de estilo... En el caso de GitLab (que también recomienda la guía de estilo de Google), se usa un enfoque más pragmático, en la [Shell scripting standards and style guidelines](https://docs.gitlab.com/ee/development/shell_scripting_guide/) se indica:  

1. [Evitar el uso de *shell scripts*](https://docs.gitlab.com/ee/development/shell_scripting_guide/#avoid-using-shell-scripts) (se usa Ruby o Go)
1. Usar [ShellCheck](https://www.shellcheck.net/) como herramienta de validación (*linting*) de la sintaxis de los *scripts*.
1. Usar [shfmt](https://github.com/mvdan/sh#shfmt) para el formato del código de acuerdo con la guía de estilo de Google mediante: `shfmt -i 2 -ci -w scripts/**/*.sh`
   - Existe también en formato *plugin* para VSCode [shell-format](https://marketplace.visualstudio.com/items?itemName=foxundermoon.shell-format)

## Conclusión

El único factor común es **ser consistente**; para ello, se puede usar una guía de estilo y, mejor todavía, herramientas que automaticen -y garanticen- que el proceso sea homogéneo y consistente para todos los integrantes de un equipo.
