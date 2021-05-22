+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["dhcp", "virtualbox"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/virtualbox.png"

# SHORTCODES (for reference)

title=  "Modificar el rango del DHCP de Virtualbox"
date = "2020-07-25T20:14:05+02:00"
+++
Virtualbox proporciona diferentes formas para conectar las máquinas virtuales a la red. En función del tipo de conectividad elegida, las máquinas virtuales tienen conexión con la máquina anfitriona, acceso a internet, conectividad entre ellas, etc, como se indica en la tabla al final de la sección [6.2. Introduction to Networking Modes](https://www.virtualbox.org/manual/ch06.html#networkingmodes)
<!--more-->

No voy a entrar en detalles porque tanto en la documentación oficial como en infinidad de páginas se explica con todo detalle (como por ejemplo, [VirtualBox Network Settings: Complete Guide](https://www.nakivo.com/blog/virtualbox-network-setting-guide/) de donde obtuve la imagen de más abajo).

Habitualmente, en casa, suelo configurar las máquinas con un adaptador de tipo *bridged*, que permite que las VMs compartan el adaptador físico del portátil y se conecten a la red como cualquier otra máquina física.

Sin embargo, este fin de semana he estado conectado a una red que sólo permite una máquina conectada por usuario. Usando el modo *bridged*, el sistema detecta que hay múltiples equipos conectados desde la misma sesión, cosa que no está permitida y finaliza la sesión que proporciona acceso a la red.

Para mantenerme dentro de los términos de servicio de esta red wifi, puedo usar los modos NAT o "NAT Network" (necesito que las máquinas virtuales tengan acceso a internet).

Usando NAT todas las máquinas virtuales reciben la misma dirección IP, 10.0.2.15 y están "desconectadas" entre sí. Así que la única opción viable para levantar varias máquinas conectadas entre ellas es usar el modo "NAT Network".

Aunque este modo no permite conexiones directas desde el equipo anfitrión a la red *nateada*, es posible acceder mediante *port-forwarding*.

{{< figure src="/images/200725/VirtualBox-network-settings-–-the-NAT-Network-mode.png" w="1154" h="641" >}}

Como puede observarse en la imagen (obtenida desde la página de Nakivo a la que enlazo más arriba), las máquinas virtuales obtienen una IP desde el DHCP en 10.0.2.3 del rango 10.0.2.0/24.

El problema que me he encontrado es que, al cambiar la IP de las máquinas del *control plane* de un clúster de K3s el sistema ha dejado de funcionar :( Pero como el DHCP cubre todo el rango de IPs, no hay forma de asignar una IP estática a una máquina virtual sin riesgo de que, por casualidad, el DHCP la asigne a una nueva VM en cualquier momento.

Revisando la documentación de VirtualBox he encontrado en la sección [8.42. VBoxManage dhcpserver](https://www.virtualbox.org/manual/ch08.html#vboxmanage-dhcpserver) el comando que me permite modificar el rango de IPs servidas desde el servidor DHCP.

Aunque existe la posibilidad de asignar una dirección mediante `--fixed-address=address` para una máquina virtual `--vm` o a una *mac address* (`--mac-address`), en mi caso la opción más segura es la de modificar el rango de IPs del DHCP.

Para ello, he *reservado* las direcciones por debajo de 50 para asignarlas estáticamente a través del sistema operativo de las VMs cuando lo necesite:

```bash
VBoxManage dhcpserver modify --network=${NombreNetwork} --lower-ip=10.0.2.50
```

De esta forma, tengo flexibilidad para asignar direcciones estáticas a las máquinas que me interese (asignado una IP por debajo de 50) o para que obtengan una dirección automáticamente del DHCP sin ningún riesgo de colisión.

*Problem solved!*
