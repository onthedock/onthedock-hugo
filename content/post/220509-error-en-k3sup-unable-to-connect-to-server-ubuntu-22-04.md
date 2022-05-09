+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "ubuntu", "k3sup", "kubernetes"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/kubernetes.png"

# SHORTCODES (for reference) https://gohugo.io/content-management/shortcodes/

# Enlaces internos  [Titulo de la entrada]({{< ref "nombre-del-fichero.md" >}})
# Imagenes          {{< figure src="/images/image.jpg" width="600" height="480" >}}
# YouTube           {{< youtube w7Ft2ymGmfc >}}
# Gist              {{< gist username 7896402 >}}
# Highlight         {{< highligth language >}}...{{< /highlight >}}
# Twitter           {{< tweet user="SanDiegoZoo" id="1453110110599868418" >}}

title=  "Error en k3sup: Unable to Connect to Server over SSH (Ubuntu 22.04)"
date = "2022-05-09T21:43:30+02:00"
+++
Tras solucionar los problemas con Vagrant al actualizar a PoP_OS! 22.04 (basada en Ubuntu 22.04), encuentro otro problema relacionado también con SSH :(

[k3sup](https://github.com/alexellis/k3sup), el instalador de clústers de Kubernetes usando [k3s](https://k3s.io/), no puede conectar con las máquinas virtuales basadas en la imagen [ubuntu/jammy64](https://app.vagrantup.com/ubuntu/boxes/jammy64) (la nueva versión de Ubuntu 22.04).
<!--more-->
El mensaje de error de **k3sup** indica que no se puede conectar vía SSH porque falla el *handshake*:

```shell
Running: k3sup install
2022/05/09 21:38:01 192.168.1.101
Public IP: 192.168.1.101
Error: unable to connect to 192.168.1.101:22 over ssh: ssh: handshake failed: ssh: unable to authenticate, attempted methods [none publickey], no supported methods remain
Running: k3sup join
Server IP: 192.168.1.101
Error: unable to connect to (server) 192.168.1.101:22 over ssh: ssh: handshake failed: ssh: unable to authenticate, attempted methods [none publickey], no supported methods remain
```

Sin embargo, es posible conectar a las VMs vía SSH con normalidad:

```shell
$ ssh operador@192.168.1.101
Warning: Permanently added '192.168.1.101' (ED25519) to the list of known hosts.
Welcome to Ubuntu 22.04 LTS (GNU/Linux 5.15.0-27-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

  System information as of Mon May  9 19:55:23 UTC 2022

  System load:  0.0107421875      Processes:               93
  Usage of /:   3.5% of 38.71GB   Users logged in:         0
  Memory usage: 9%                IPv4 address for enp0s3: 10.0.2.15
  Swap usage:   0%                IPv4 address for enp0s8: 192.168.1.101


0 updates can be applied immediately.


Last login: Mon May  9 19:55:23 2022 from 192.168.1.139
To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.

operador@k3s-1:~$
```

Hay un *issue* abierto [SSH key format deprecated in Ubuntu 22.04](https://github.com/alexellis/k3sup/issues/377) al respecto.

Leyendo los diferentes comentarios no me queda claro dónde está la causa del error. Parece que está relacionado con la eliminación del soporte para SHA-1...

Pero en la documentación de OpenSSH para el último *release* [OpenSSH 8.2](https://www.openssh.com/txt/release-8.2) se indica cómo comprobar si este cambio nos impacta:

> To check whether a server is using the weak ssh-rsa public key
> algorithm for host authentication, try to connect to it after
> removing the ssh-rsa algorithm from ssh(1)'s allowed list:
>
> ```shell
>  ssh -oHostKeyAlgorithms=-ssh-rsa user@host
> ```
>
> If the host key verification fails and no other supported host key
> types are available, the server software on that host should be
> upgraded.

Es decir, si ejecutas el comando indicado y no puedes conectar, es necesario actualizar el servidor.

En el caso de los nodos del clúster, no hay ningún problema usando SSH:

```shell
$ ssh -oHostKeyAlgorithms=-ssh-rsa operador@192.168.1.101
Welcome to Ubuntu 22.04 LTS (GNU/Linux 5.15.0-27-generic x86_64)
...
```

Así que la causa parece estar en alguna de las bibliotecas de criptografía usadas por Go al compilar **k3sup**...

Una [solución alternativa](https://github.com/alexellis/k3sup/issues/377#issuecomment-1117683647) es la de generar nuevas claves **sin usar el algoritmo RSA**:

```shell
# Generate new (non-RSA) key
$ ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519
Generating public/private ed25519 key pair.
...
# Transfer the key to target server
$ ssh-copy-id -i ./id_ed25519.pub ${USER}@${IP}
...
# Enjoy k3sup again
$ k3sup install --ip ${IP} --user ${USER} --ssh-key ~/.ssh/id_ed25519
Running: k3sup install
2022/05/04 19:36:31 <IP_ADDRESS>
Public IP: <IP_ADDRESS>
[INFO]  Finding release for channel stable
[INFO]  Using v1.23.6+k3s1 as release
...
```

Podría modificar el `Vagrantfile` para incorporar una nueva clave sin demasiados problemas:

```ruby
$accessUsingSSHkey = <<-SCRIPT
#!/bin/bash
echo "Configuring passwordless SSH access for #{NonRootUser} ..."
sudo su #{NonRootUser}
sudo mkdir -p /home/#{NonRootUser}/.ssh/
cat /tmp/tmp_id_rsa.pub >> /home/#{NonRootUser}/.ssh/authorized_keys
SCRIPT
```

Sin embargo, dado que no tengo ninguna urgencia para actualizar el SO de las VMs del clúster, esperaré a que se solucione el problema con **k3sup** antes de realizar la actualización a Ubuntu 22.04.
