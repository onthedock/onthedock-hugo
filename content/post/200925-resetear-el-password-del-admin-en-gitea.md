+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev", "ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "docker", "gitea"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/gitea.jpg"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}

title=  "Resetear el password de administrador en Gitea"
date = "2020-09-25T21:31:30+02:00"
+++
Uno de los problemas de los entornos de laboratorio es que son *fungibles*, casi de "usar y tirar". Un efecto colateral es que cosas como las credenciales no se gestionan correctamente, se pone la primera que se nos ocurre y después... pues no hay manera de volver a acceder.

En mi caso me he encontrado en esta situación con Gitea y en esta entrada voy a documentar cómo establecer una nueva contraseña para el usuario *administrador*.
<!--more-->

La solución se apunta, sin demasiado detalle, en la entrada [Change admin password in Gitea](https://stackoverflow.com/questions/49057558/change-admin-password-in-gitea) de StackOverflow.

El cambio de la contraseña de un usuario en Gitea se puede realizar usando comando `gitea` desde la línea de comando. Puedes obtener más información de la [documentación oficial](https://docs.gitea.io/en-us/command-line/). Esta herramienta está orientada a la gestión de Gitea desde cli, cosa que en un entorno *containerizado* no es habitual.

En este caso, sin embargo, es la solución a nuestro problema.

## TL;DR

> **UPDATE** En Gitea v1.14 he verificado que la sintaxis del comando para cambiar el password es `gitea admin user change-password`, no `gitea admin change-password`; he actualizado la entrada con los comandos actualizados.

- Conectar al contenedor de Gitea (abrir una *shell* interactiva)

[OPCIONAL] Si no conoces el nombre del usuario administrador:

- Conecta a la base de datos del backend de Gitea (en mi caso, SQLite) `sqlite3 /data/gitea/gitea.db`
- Muestra las tablas para obtener dónde se guardan los usuarios `sqlite> .tables`
- Muestra todos los usuarios `select * from user;`
- Finaliza el cliente de la base de datos `.exit`

Realiza el cambio de password:

- Usar `gitea admin user change-password --username $GITEA_FIRST_USER --password $COMPLEX_PASSWORD`

## Acceso al contenedor de Gitea

El primer paso para acceder a la herramienta `gitea` es conectar al contenedor de Gitea. En mi caso Gitea está corriendo en un contenedor sobre Docker.

Para iniciar una sesión interactiva en el contenedor:

```bash
docker exec -it gitea /bin/sh
```

El comando `docker exec` inicia el proceso como `root`. Si lanzamos el comando `gitea` como `root`:

```bash
/ # gitea change-password
2020/09/25 19:21:19 cmd/web.go:107:runWeb() [I] Starting Gitea on PID: 67
2020/09/25 19:21:19 ...s/setting/setting.go:898:NewContext() [F] Expect user 'git' but current user is: root
```

Como vemos en el mensaje de error, el proceso de `gitea` se ejecuta como `git`, no como `root`.

## Cambiar al usuario `git`

Cambiamos al usuario `git` mediante `su git`:

```bash
/ # su git
bash-5.0$ gitea change-password --username admin
2020/09/25 19:22:15 cmd/web.go:107:runWeb() [I] Starting Gitea on PID: 82
2020/09/25 19:22:15 ...dules/setting/git.go:93:newGit() [I] Git Version: 2.26.2, Wire Protocol Version 2 Enabled
2020/09/25 19:22:15 routers/init.go:119:GlobalInit() [T] AppPath: /usr/local/bin/gitea
2020/09/25 19:22:15 routers/init.go:120:GlobalInit() [T] AppWorkPath: /usr/local/bin
2020/09/25 19:22:15 routers/init.go:121:GlobalInit() [T] Custom path: /data/gitea
2020/09/25 19:22:15 routers/init.go:122:GlobalInit() [T] Log path: /data/gitea/log
bash-5.0$
```

En primer lugar, el comando que intento ejecutar es incorrecto; debería ser `gitea admin user change-password ...`, y no `gitea change-password ...`. `gitea` no devuelve ningún error, por lo que no me he dado cuenta al momento :(

## Lanzar el comando con la sintaxis correcta

Una vez identificado el error, he lanzado el comando *correcto*:

```bash
bash-5.0$ gitea admin user change-password --username admin --password admin
2020/09/25 19:25:36 ...dules/setting/git.go:93:newGit() [I] Git Version: 2.26.2, Wire Protocol Version 2 Enabled
2020/09/25 19:25:36 main.go:111:main() [F] Failed to run app with [gitea admin change-password --username admin --password admin]: Password does not meet complexity requirements
```

Ok, vamos avanzando; ahora la contraseña no verifica los requerimientos de complejidad... Solo que no **sólo** se trata de eso :( (Drama... Supense... Misterio!)

## Complejidad del password

El password de Gitea debe cumplir la siguiente política de complejidad:

- Longitud mínima de 6 caracteres
- Como mínimo, una mayúscula
- Como mínimo, una minúscula
- Como mínimo, un dígito
- Como mínimo, un caracter especial (puntuación, paréntesis, comillas, etc)

## El usuario `admin` no existe

Si intentamos establecer una contraseña que cumpla con la política de complejidad:

```bash
bash-5.0$ gitea admin user change-password --username admin --password Gitea@dm1n
2020/09/25 19:26:06 ...dules/setting/git.go:93:newGit() [I] Git Version: 2.26.2, Wire Protocol Version 2 Enabled
2020/09/25 19:26:06 ...m.io/xorm/core/db.go:286:afterProcess() [I] [SQL] SELECT `id`, `lower_name`, `name`, `full_name`, `email`, `keep_email_private`, `email_notifications_preference`, `passwd`, `passwd_hash_algo`, `must_change_password`, `login_type`, `login_source`, `login_name`, `type`, `location`, `website`, `rands`, `salt`, `language`, `description`, `created_unix`, `updated_unix`, `last_login_unix`, `last_repo_visibility`, `max_repo_creation`, `is_active`, `is_admin`, `is_restricted`, `allow_git_hook`, `allow_import_local`, `allow_create_organization`, `prohibit_login`, `avatar`, `avatar_email`, `use_custom_avatar`, `num_followers`, `num_following`, `num_stars`, `num_repos`, `num_teams`, `num_members`, `visibility`, `repo_admin_change_team_access`, `diff_view_style`, `theme`, `keep_activity_private` FROM `user` WHERE `lower_name`=? LIMIT 1 [admin] - 4.073239ms
2020/09/25 19:26:06 main.go:111:main() [F] Failed to run app with [gitea admin change-password --username admin --password Gitea@dm1n]: user does not exist [uid: 0, name: admin, keyid: 0]
```

Como se ve en la última línea: `user does not exist` 0_0.

## Averiguando el nombre del administrador de Gitea

El primer usuario creado en Gitea se considera el administrador de la aplicación. Podemos elegir el nombre que más nos guste para este "primer usuario", al que se le asigna el perfil de *administrador* de Gitea.

El nombre del usuario se guarda en la base de datos usada por Gitea; en esta instalación *de laboratorio* usé SQLite (la opción por defecto). Afortunadamente, el contenedor dispone del cliente `sqlite3` para poder gestionar la base de datos por defecto.

La base de datos de SQLite para Gitea se encuentra en `/data/gitea/gitea.db`:

```bash
bash-5.0$ cd /data/gitea
bash-5.0$ ls
avatars   conf      gitea.db  indexers  log       queues    sessions
```

Usamos el cliente para *conectar* con la base de datos `gitea.bd`:

```bash
bash-5.0$ sqlite3 gitea.db
SQLite version 3.32.1 2020-05-25 16:19:56
Enter ".help" for usage hints.
sqlite>
```

Es recomendable usar el comando `.help` para revisar los comandos del `sqlite3` o consultar la documentación oficial de la *cli* en [Command Line Shell For SQLite](https://sqlite.org/cli.html).

Listamos las tablas existentes:

```bash
codesqlite> .tables
access                     oauth2_authorization_code
access_token               oauth2_grant
action                     oauth2_session
attachment                 org_user
collaboration              protected_branch
comment                    public_key
commit_status              pull_request
deleted_branch             reaction
deploy_key                 release
email_address              repo_indexer_status
email_hash                 repo_redirect
external_login_user        repo_topic
follow                     repo_unit
gpg_key                    repository
gpg_key_import             review
hook_task                  star
issue                      stopwatch
issue_assignees            task
issue_dependency           team
issue_label                team_repo
issue_user                 team_unit
issue_watch                team_user
label                      topic
language_stat              tracked_time
lfs_lock                   two_factor
lfs_meta_object            u2f_registration
login_source               upload
milestone                  user  <------ Esta es la tabla que nos interesa
mirror                     user_open_id
notice                     version
notification               watch
oauth2_application         webhook
sqlite>
```

Una vez identificada la tabla:

```bash
sqlite> select * from user;
1|operador|operador||xavi.aznar@lab.home|0|enabled|d8917a3943346bf5e1a7c1cf6fca30416e4ec7216f3deb0ee6ed0e4053d1379e1e359fb11d234e876ed45991d6d58b2deec2|pbkdf2|0|0|0||0|||IW49lxdyrg|K6VRG0hkTv|en-US||1594831480|1601062014|1601062014|0|-1|1|1|0|0|0|1|0|085ce2e18edda712bc2b4ebcd2ae2134|xavi.aznar@lab.home|0|0|0|0|1|0|0|0|0||gitea|0
sqlite>
```

Ahora ya tenemos el nombre del usuario creado; en mi caso, `operador`.

Salimos del cliente `sqlite3` con `.exit`.

## Cambiando el password (ahora sí)

Finalmente, lanzamos el comando de cambio de password para el usuario `operador` (con una contraseña que verifica la política de complejidad):

```bash
bash-5.0$ gitea admin user change-password --username operador --password Gitea@dm1n
2020/09/25 19:26:19 ...dules/setting/git.go:93:newGit() [I] Git Version: 2.26.2, Wire Protocol Version 2 Enabled
2020/09/25 19:26:19 ...m.io/xorm/core/db.go:286:afterProcess() [I] [SQL] SELECT `id`, `lower_name`, `name`, `full_name`, `email`, `keep_email_private`, `email_notifications_preference`, `passwd`, `passwd_hash_algo`, `must_change_password`, `login_type`, `login_source`, `login_name`, `type`, `location`, `website`, `rands`, `salt`, `language`, `description`, `created_unix`, `updated_unix`, `last_login_unix`, `last_repo_visibility`, `max_repo_creation`, `is_active`, `is_admin`, `is_restricted`, `allow_git_hook`, `allow_import_local`, `allow_create_organization`, `prohibit_login`, `avatar`, `avatar_email`, `use_custom_avatar`, `num_followers`, `num_following`, `num_stars`, `num_repos`, `num_teams`, `num_members`, `visibility`, `repo_admin_change_team_access`, `diff_view_style`, `theme`, `keep_activity_private` FROM `user` WHERE `lower_name`=? LIMIT 1 [operador] - 4.473739ms
operador's password has been successfully updated!
```

## Conclusión

Aunque se trata de un entorno de laboratorio, es esencial **documentar** todos los detalles (usuarios, contraseñas, permisos, etc).
