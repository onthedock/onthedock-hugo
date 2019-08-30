+++
draft = false

categories = ["dev", "ops"]
tags = ["aws", "aws-cli"]
thumbnail = "images/aws.png"

title=  "Configuración de awscli-login"
date = "2019-08-30T23:07:34+02:00"
+++
Uno de los problemas de usar usuarios IAM con acceso programático a los recursos en AWS es la seguridad de la _secret key_ (incluso habilitando la seguridad con varios factores de autenticación (MFA)).

Cuando un trabajador deja de estar vinculado a la empresa, existen procesos que se encargan de _decomisionar_ los elementos asociados al ex-trabajador; en particular, se elimina el acceso a los sistemas a los que tuviera acceso mediante la desactivación de las cuentas del usuario.

El problema es que los usuarios IAM tienen claves de acceso programático que permiten el acceso a los recursos de manera independiente a los sistemas de gestión de identidad corporativa (generalmente un LDAP) sin necesidad de estar conectados a la red de la empresa.

Aunque la solución más directa parece la modificación del proceso de baja para incluir anulación de los usuarios IAM, lo ideal es conseguir acceso programático a AWS con **credenciales federadas**, es decir, centralizando la autenticación en el sistema de gestión de identidades de la empresa.
<!--more-->

El acceso mediante credenciales federadas implica que el usuario no accede directamente a AWS; primero se valida en el Active Directory de la compañía, donde obtiene _token_. AWS valida el _token_ y entonces concede el acceso a los recursos.

Al usar las credenciales de Active Directory para acceder a AWS, no es necesario gestionar un nuevo conjunto de usuarios y contraseñas ni modificar los procesos implantados en la compañía.

Desgraciadamente, la herramienta `aws-cli` no soporta el acceso usando este tipo de credenciales de manera directa, por lo que es necesario usar algún tipo de _plugin_ para realizar el envío de las credenciales al IdP, obtener el _token_ y después autenticarse en AWS.

Aquí es donde entra en juego `awscli-login`.

> `awscli-login` es un _plugin_ para usar SAML ECP (échale un vistazo a [este artículo](https://medium.com/@winma.15/saml-ecp-enhanced-client-or-proxy-profile-97f8fd051c6) en Medium, por ejemplo).
>
> **ADFS no es compatible con ECP**, por lo que no es posible usar este _plugin_ para autenticar usuarios en AWS validándolos en AD (aunque lo he descubierto tarde, en StackOverflow: [Using ECP SAML with ADFS](https://stackoverflow.com/questions/34745820/using-ecp-saml-with-adfs))
>
> La instalación de `awscli-login` me ha dado algunos problemas que he conseguido solucionar, por lo que he decidido documentar cómo.

## AWSCLI-LOGIN

`awscli-login` es un _plugin_ de autenticación para AWS. Está desarrollado por el servicio técnico de la Universidad de Illinois y publicado en GitHub [techservicesillinois/awscli-login
](https://github.com/techservicesillinois/awscli-login). Información relativa a la configuración también puede encontrarse en la página de soporte de la Universidad de Iowa  [How to install the Federated Login tool for the AWS CLI](https://cloudservices.its.uiowa.edu/article/how-install-federated-login-tool-aws-cli).

> A partir de este punto doy por supuesto que tienes instalado Python 3.x, `pip` y `aws`.

  ```bash
  $ pip3 --version
  pip 19.2.3 from /home/operador/.local/lib/python3.5/site-packages/pip (python 3.5)
  $ aws --version
  aws-cli/1.16.230 Python/3.5.3 Linux/4.9.0-9-amd64 botocore/1.12.220
  ```

## Instalación de `awscli-login`

Siguiendo las instrucciones del [soporte de la Universidad de Iowa](https://cloudservices.its.uiowa.edu/article/how-install-federated-login-tool-aws-cli), la instalación debe realizarse mediante:

```bash
pip3 install awscli-login
```

Sin embargo, la instalación falla con el error:

```bash
ERROR: Could not install packages due to an EnvironmentError: [Errno 13] Permission denied: '/usr/local/lib/python3.5/dist-packages/daemoniker-0.2.3.dist-info'
Consider using the `--user` option or check the permissions.
```

Probamos con la opción `--user` como recomienda el mensaje:

```bash
pip3 install awscli-login --user
```

La instalación falla de nuevo, esta vez con:

```bash
ERROR: Command errored out with exit status 1: /usr/bin/python -u -c 'import sys, setuptools, tokenize; sys.argv[0] = '"'"'/tmp/pip-install-42_wpbjn/psutil/setup.py'"'"'; __file__='"'"'/tmp/pip-install-42_wpbjn/psutil/setup.py'"'"';f=getattr(tokenize, '"'"'open'"'"', open)(__file__);code=f.read().replace('"'"'\r\n'"'"', '"'"'\n'"'"');f.close();exec(compile(code, __file__, '"'"'exec'"'"'))' install --record /tmp/pip-record-zaq0cya5/install-record.txt --single-version-externally-managed --compile --user --prefix= Check the logs for full command output.
```

Antes del mensaje de error propiamente dicho, aparece:

```bash
x86_64-linux-gnu-gcc -pthread -DNDEBUG -g -fwrapv -O2 -Wall -Wstrict-prototypes -g -fdebug-prefix-map=/build/python3.5-3.5.3=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -fPIC -DPSUTIL_POSIX=1 -DPSUTIL_VERSION=563 -DPSUTIL_LINUX=1 -DPSUTIL_ETHTOOL_MISSING_TYPES=1 -I/usr/include/python3.5m -c psutil/_psutil_common.c -o build/temp.linux-x86_64-3.5/psutil/_psutil_common.o
    unable to execute 'x86_64-linux-gnu-gcc': No such file or directory
    error: command 'x86_64-linux-gnu-gcc' failed with exit status 1
```

Esto me ha dado la pista para encontrar la solución: parece que el _script_ tiene que realizar algún tipo de compilación, para lo que utiliza GNU-GCC.

Después de unas pruebas, la solución pasa por instalar `build-essential` y `python3-dev`:

> **Solucionado** con `sudo apt install build-essential python3-dev`

```bash
pip3 install awscli-login --user
...
Successfully built psutil
Installing collected packages: psutil, awscli-login, colorama, rsa
  Found existing installation: colorama 0.4.1
    Uninstalling colorama-0.4.1:
      Successfully uninstalled colorama-0.4.1
  Found existing installation: rsa 4.0
    Uninstalling rsa-4.0:
      Successfully uninstalled rsa-4.0
  WARNING: The scripts pyrsa-decrypt, pyrsa-decrypt-bigfile, pyrsa-encrypt, pyrsa-encrypt-bigfile, pyrsa-keygen, pyrsa-priv2pub, pyrsa-sign and pyrsa-verify are installed in '/home/operador/.local/bin' which is not on PATH.
  Consider adding this directory to PATH or, if you prefer to suppress this warning, use --no-warn-script-location.
Successfully installed awscli-login-0.1.0a5 colorama-0.3.9 psutil-5.6.3 rsa-3.4.2
```

Una vez solucionada la instalación, pasamos a configurarlo.

## Configuración del _plugin_ `awscli_login`

Referencia: [How to install the Federated Login tool for the AWS CLI](https://cloudservices.its.uiowa.edu/article/how-install-federated-login-tool-aws-cli)

```bash
aws configure set plugins.login awscli_login
```

Ahora configuramos el _profile_ en AWS (el _default_).

> OJO! Estaba pasando la URL del ADFS como _endpoint ECP_, así que no cometas el mismo error.

```bash
$ aws login configure
ECP Endpoint URL [None]: https://<fqdn-idp>/adfs/ls/IdpInitiatedSignOn.aspx
Username [None]: <username>
Enable Keyring [False]:
Duo Factor [None]:
Role ARN [None]:
```

El intento de acceso falla:

```bash
$ aws login
Password:
Factor:
Authentication failed!
```

Buscando información sobre ECP y ADFS he llegado a [Using ECP SAML with ADFS](https://stackoverflow.com/questions/34745820/using-ecp-saml-with-adfs):

```text
Question: Is there any workaround to use ECP with ADFS? ADFS doesn't support ECP. ADFS uses HTTP based redirection which doesn't make sense in our non-web desktop client.

Answer: No - it's not supported.

What version of ADFS?

If 3.0, could you use OAuth? - there is limited support.
```

"No, no está soportado"; ¡ojalá lo hubiera sabido antes!

¯\\\_(ツ)_/¯
