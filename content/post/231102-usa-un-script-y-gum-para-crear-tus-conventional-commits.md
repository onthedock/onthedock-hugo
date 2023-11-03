+++
# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["git", "conventional commits"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/git.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/
# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}

title=  "Usa un script (y Gum) para crear tus Conventional Commits"
date = "2023-11-02T20:46:08+01:00"
+++
En la [entrada anterior]({{< ref "231101-plantilla-para-commits.md" >}}) mencionaba cómo usar una *plantilla* para homogeneizar los *commits*.

Además de la plantilla, usar [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) permite dotar de un *formato standard* a los commits. La buena gente de [Charm](https://charm.sh/) ofrece como parte del [tutorial para aprender a usar Gum](https://github.com/charmbracelet/gum) un *script* con el que redactar *conventional commits*.

En esta entrada, ofrezco una versión ampliada que incluye la descripción para cambios que rompen la *retrocompatibilidad*.
<!--more-->

## El código

```console
#!/bin/sh
TYPE=$(gum choose "test" "feat" "refactor" "fix" "docs" "style" "chore" "revert")
SCOPE=$(gum input --placeholder "scope")

# Since the scope is optional, wrap it in parentheses if it has a value.
test -n "$SCOPE" && SCOPE="($SCOPE)"
gum confirm "Is breaking change?" && breaking_change="true"

[ "$breaking_change" = "true" ] && SCOPE="$SCOPE!" && BREAKING_CHG=$(gum write --placeholder "What does it break (CRTL+D to finish)")

# Pre-populate the input with the type(scope): so that the user may change it
SUMMARY=$(gum input --value "$TYPE$SCOPE: " --placeholder "Summary of this change")

DESCRIPTION=$(gum write --placeholder "Details of this change (CTRL+D to finish)")

test -n "$BREAKING_CHG" && BREAKING_CHG="BREAKING CHANGE: $BREAKING_CHG"

# Commit these changes
gum confirm "Commit changes?" && git commit -m "$SUMMARY" -m "$DESCRIPTION" -m "$BREAKING_CHG"
```

Al *script* original de la gente de Charm, uso `gum confirm` para preguntar si el cambio rompe la retrocompatibilidad, y si es así, se solicita una descripción de qué es lo que lo provoca.

El resto del script es original del equipo de Charm.
