+++
draft = false
categories = ["ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"
tags = ["linux", "proxmox", "ansible"]
thumbnail = "images/ansible.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" >}}
# Imagenes {{< figure src="/images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" >}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" >}}

title=  "Automatizando la gestion de máquinas virtuales con Ansible en Proxmox VE (spoiler, no me ha funcionado)"
date = "2019-04-28T20:11:52+02:00"
+++
Sigo dando pasos en el [_roadmap_ que me marqué ya hace un tiempo]({{< ref "181124-roadmap.md" >}}), aunque mucho más lentamente de lo que había previsto.

Después de decidir montar todo el laboratorio sobre KVM -y conseguirlo-, a nivel operativo no me resultaba cómodo.
Podía usar VirtManager (una solución gráfica), pero que sólo tenía instalada en un desktop con Linux que no suelo usar habitualmente, o hacer SSH contra el equipo de laboratorio y usar la línea de comandos para generar la máquina desde cero...

Al final, manteniéndome fiel al _objetivo final_ de automatizar la solución, decidí usar Proxmox VE (que usa Debian y KVM "bajo el capó") y que además se integra con Ansible.

<!--more-->
## Requerimientos previos

Para poder contectar Ansible con Proxmox VE, es necesario instalar [proxmoxer](https://pypi.org/project/proxmoxer/) en el equipo _host_.

> En la página de requerimientos del módulo proxmox en Ansible [proxmox – management of instances in Proxmox VE cluster](https://docs.ansible.com/ansible/latest/modules/proxmox_module.html) además de Python y `proxmoxer` verás listado el paquete `requests`, pero parece que se instala automáticamente al instalar `proxmoxer`.

La instalación del módulo se realiza usando `pip`, el instalador de paquetes de Python (y que ha propiciado la entrada anterior [Cómo instalar pip]({{< ref "190428-como-instalar-pip.md" >}})).
Con `pip` instalado, lanza `sudo pip install proxmoxer` para instalar `proxmoxer`.

## Play de prueba en Ansible

En la máquina de control de Ansible, he creado un _playbook_ sencillo para detener una máquina virtual en el equipo con Proxmox VE (el equipo se llama **lab**).

```yaml
---
- hosts: lab
  tasks:
  - proxmox:
      api_user: root@pam
      api_password: *************
      api_host: 192.168.1.2
      vmid: 102
      state: stopped
```

Sin embargo, al lanzar el _playbook_, obtengo un error 500:

```bash
$ ansible-playbook proxmox-stop-vm.yml

PLAY [lab] *************************************************************************

TASK [Gathering Facts] *************************************************************
ok: [lab]

TASK [proxmox] *********************************************************************
fatal: [lab]: FAILED! => {"changed": false, "msg": "stopping of VM 102 failed with
exception: 500 Internal Server Error: b'{\"data\":null}'"}
   to retry, use: --limit @/home/ansible-service-account/proxmox-stop-vm.retry

PLAY RECAP *************************************************************************
lab                        : ok=1    changed=0    unreachable=0    failed=1
```

### Troubleshooting

El error 500 es un error genérico del tipo "algo ha ido mal", sin especificar el qué.

En primer lugar, intento averiguar si la API está levantada (o si hay un error 500 "de verdad").
Una manera sencilla de comprobarlo es usando el comando `pvesh`, que permite conectar con la API REST:

```bash
# pvesh get /nodes
┌──────┬────────┬───────┬───────┬────────┬───────────┬──────────┬───────────────────
│ node │ status │   cpu │ level │ maxcpu │    maxmem │ mem      │ ssl_fingerprint
├──────┼────────┼───────┼───────┼────────┼───────────┼──────────┼───────────────────
│ lab  │ online │ 9.96% │       │      4 │ 30.68 GiB │ 3.25 GiB │ C5:DA:5F:99:87:5C:
└──────┴────────┴───────┴───────┴────────┴───────────┴──────────┴───────────────────
```

Parece que el API funciona...

El siguiente paso es ver si podemos conectar (es decir, si se trata un error de autenticación):

Modifico el _play_ cambiando el _password_ por la variable de entorno `$PROXMOX_PASSWORD` (que no está establecida):

```yaml
++ api_password: $PROXMOX_PASSWORD
-- api_password: ************
```

La salida del _playbook_ es clara en este caso:

```bash
...
TASK [proxmox] *********************************************************************
fatal: [lab]: FAILED! => {"changed": false, "msg": "authorization on proxmox cluster
failed with exception: Couldn't authenticate user: root@pam to
https://192.168.1.2:8006/api2/json/access/ticket"}
   to retry, use: --limit @/home/ansible-service-account/proxmox-stop-vm.retry
...
```

Es decir, sí que el módulo de Ansible puede autenticarse, pero a partir de ahí "algo va mal".

Siguiendo con `pvesh`, puedo parar la VM -usando la API- mediante el comando:

```bash
root@lab:~# pvesh create /nodes/lab/qemu/102/status/stop
UPID:lab:000063FA:001DEA8B:5CC5CF00:qmstop:102:root@pam:
root@lab:~# pvesh get /nodes/lab/qemu/102/status/current
┌───────────┬───────────────┐
│ key       │ value         │
├───────────┼───────────────┤
│ agent     │ 1             │
├───────────┼───────────────┤
│ cpus      │ 1             │
├───────────┼───────────────┤
│ ha        │ {"managed":0} │
├───────────┼───────────────┤
│ maxdisk   │ 32.00 GiB     │
├───────────┼───────────────┤
│ maxmem    │ 1.00 GiB      │
├───────────┼───────────────┤
│ name      │ wiki          │
├───────────┼───────────────┤
│ qmpstatus │ stopped       │
├───────────┼───────────────┤
│ status    │ stopped       │
├───────────┼───────────────┤
│ uptime    │               │
├───────────┼───────────────┤
│ vmid      │ 102           │
└───────────┴───────────────┘
root@lab:~# pvesh create /nodes/lab/qemu/102/status/start
UPID:lab:0000649C:001E203E:5CC5CF89:qmstart:102:root@pam:
```

He vuelto a arrancar la VM, ya que esto demuestra que puedo apagar la VM usando la API -al menos localmente.

He ejecutado el _playbook_ usando `-v` para obtener información adicional, pero no se muestra nada más relacionado con el error 500.

En `/var/log/auth.log` queda registrada la conexión del usuario `ansible-service-account`:

```bash
Apr 28 18:48:13 lab sshd[29663]: Accepted publickey for ansible-service-account from 192.168.1.219 port 55070 ssh2: ED25519 SHA256:4Zp/sQr0n3wvwMkQaUt3aqnGvnfIWdicuYEFCW7WFes
Apr 28 18:48:13 lab sshd[29663]: pam_unix(sshd:session): session opened for user ansible-service-account by (uid=0)
Apr 28 18:48:13 lab systemd-logind[621]: New session 49 of user ansible-service-account.
Apr 28 18:48:13 lab systemd: pam_unix(systemd-user:session): session opened for user ansible-service-account by (uid=0)
```

Después de revisar los logs del sistema con Proxmox, he encontrado dentro del `/var/log/syslog` (hay información similar en `/var/log/messages` y `/var/log/user.log`):

```bash
Apr 28 18:38:42 lab ansible-setup: Invoked with gather_subset=['all'] fact_path=/etc/ansible/facts.d gather_timeout=10 filter=*
Apr 28 18:38:43 lab ansible-proxmox: Invoked with api_user= validate_certs=False node=None password=NOT_LOGGING_PARAMETER mounts=None api_host=192.168.1.2 ip_address=None nameserver=None pubkey=None onboot=False disk=3 storage=local swap=0 cpuunits=1000 cores=1 memory=512 state=stopped pool=None searchdomain=None vmid=102 force=False unprivileged=False ostemplate=None api_password=NOT_LOGGING_PARAMETER timeout=30 netif=None hostname=None cpus=1
Apr 28 18:38:43 lab pvedaemon[1186]: <root@pam> successful auth for user 'root@pam'
```

Es decir, que efectivamente, Ansible se autentica correctamente con el usuario `root` en Proxmox y se pasan todos los parámetros de la instucción: vemos el `vmid=102`, `state=stopped`...
Pero la instrucción no se procesa correctamente y la máquina no se apaga.

He probado si cambiando el estado de la VM de `stopped` a `started` suponía alguna diferencia (la máquina está arrancada), pero en la salida de Ansible obtengo el mismo error 500:

```bash
...
TASK [proxmox] ********************************************************************************************************************************************************
fatal: [lab]: FAILED! => {"changed": false, "msg": "starting of VM 102 failed with exception: 500 Internal Server Error: b'{\"data\":null}'"}
```

Y en los logs, en la máquina LAB (en `/var/log/user.log`, por ejemplo):

```bash
Apr 28 18:55:35 lab ansible-setup: Invoked with gather_subset=['all'] gather_timeout=10 filter=* fact_path=/etc/ansible/facts.d
Apr 28 18:55:35 lab ansible-proxmox: Invoked with timeout=30 validate_certs=False node=None state=started cpus=1 api_host=192.168.1.2 pubkey=None storage=local cores=1 unprivileged=False ostemplate=None ip_address=None cpuunits=1000 api_password=NOT_LOGGING_PARAMETER netif=None pool=None swap=0 searchdomain=None nameserver=None password=NOT_LOGGING_PARAMETER disk=3 vmid=102 memory=512 force=False onboot=False mounts=None hostname=None api_user=
```