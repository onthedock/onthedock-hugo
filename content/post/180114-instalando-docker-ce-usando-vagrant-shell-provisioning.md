+++
draft = false

categories = ["dev"]
tags = ["vagrant", "automation", "docker"]
thumbnail = "images/vagrant.png"

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

title=  "Instalando Docker-CE usando Vagrant shell provisioning"
date = "2018-01-14T21:11:00+01:00"
+++

A raíz de las pruebas realizadas en la [segunda toma de contacto]({{<ref "180114-vagrant-segunda-oportunidad.md">}}) con <a href="/tags/vagrant/">Vagrant</a>, he creado un script para instalar Docker-CE como **prueba de concepto** de _shell provisioning_ sobre Vagrant.

> En vez de instalar una y otra vez Docker desde los repositorios, es mucho más eficiente crear una [_box_ personalizada](https://www.vagrantup.com/docs/boxes/base.html) con el software que necesitamos.

<!--more-->

El fichero `Vagrantfile` usa la imagen base `generic/debian9` para crear una máquina virtual con 2 vCPUs y 2GB de RAM conectada al _vSwitch_ de la red externa (con acceso a internet).

# Fichero `Vagrantfile`

```Vagrantfile
Vagrant.configure("2") do |config|
   config.vm.box = "generic/debian9"
   config.vm.network "public_network", bridge: "EXTERNAL-vSwitch"

   config.vm.hostname = "vagrant-debian-9"

   # Configuración de recursos de la VM
   config.vm.provider "hyperv" do |v, override|
      v.vmname = "vagrant-debian-9"
      
      v.cpus = 2
      v.memory = 2048
      v.maxmemory = 2048
      
      v.enable_virtualization_extensions = true
      v.differencing_disk = true
   end

   config.vm.provision "shell" do |s|
      s.path= "bootstrap-docker.sh"
   end
end
```

# Fichero `bootstrap-docker.sh`

El fichero `bootstrap-docker.sh` recoge las instrucciones de la [guía de instalación para Docker sobre Debian](https://docs.docker.com/engine/installation/linux/docker-ce/debian/).

```sh
# Remove older versions of Docker
echo "Removing older versions of Docker"
sudo apt-get remove docker docker-engine docker.io

# Kernel version must be over 3.2
echo "[INFO] Keep in mind that kernel version must be at least 3.2"
echo "[INFO] Current version is " $(uname -r)

# Update and install

echo "\nUpdate and install pre-requisites"
sudo apt-get update
sudo apt-get install \
      apt-transport-https \
      ca-certificates \
      curl \
      gnupg2 \
      software-properties-common -y

# Docker's official GPG key
echo "\nAdding Docker's official GPG key"
curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg -o docker-ce.gpgkey
sudo apt-key add docker-ce.gpgkey

# Add stable branch repository
echo "\nAdd Docker-CE repository"
sudo echo "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
   $(lsb_release -cs) \
   stable" >> /etc/apt/sources.list

# Update repository info and install Docker-CE
echo "\nUpdate repository info and installing Docker-CE"
sudo apt-get update
sudo apt-get install docker-ce -y
```

Las diferencias en algunos pasos con respecto a la documentación oficial han sido necesarias debido a que el script no se ejecuta en un terminal, por lo que algunas instrucciones generaban un error.