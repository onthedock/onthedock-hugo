+++
draft = false

# CATEGORIES = "dev" / "ops"
categories = ["dev", "ops"]
# TAGS (HW->OS->PRODUCT->specific tag)
# Example: "raspberry pi", "hypriot os", "kubernetes"

tags = ["linux", "docker"]

# Optional, referenced at `$HUGO_ROOT/static/images/thumbnail.jpg`
thumbnail = "images/docker.png"

# SHORTCODES (for reference)

# Enlaces internos [Titulo de la entrada]({{<ref "nombre-del-fichero.md" >}})

# YouTube {{% iframe src="https://www.youtube.com/embed/XXXXXXX" w="560" h="315" %}}
# Imagenes {{% img src="images/image.jpg" w="600" h="400" class="right" caption="Referenced from wikipedia." href="https://en.wikipedia.org/wiki/Lorem_ipsum" %}}
# Clear (floats) {{% clear %}}
# Twitter {{% twitter tweetid="780599416621297xxx" %}}

title=  "De Docker Stats a un fichero CSV"
date = "2018-05-22T23:02:24+02:00"
+++

Docker proporciona el comando `docker stats` para monitorizar el uso de CPU, memoria, etc de los contenedores en ejecución:

<!--more-->

```shell
$ sudo docker stats
CONTAINER ID        NAME                CPU %               MEM USAGE / LIMIT     MEM %               NET I/O             BLOCK I/O           PIDS
51b4b11494dc        jenkins             0.21%               179.6MiB / 1.877GiB   9.35%               452kB / 1.12MB      1.27GB / 7.02MB     43
46a343a03526        sonarqube           2.65%               637.8MiB / 1.877GiB   33.19%              58.5MB / 61.4MB     8.15GB / 496MB      163
aee4587d47c1        gogs                0.00%               20.25MiB / 1.877GiB   1.05%               5.61MB / 6.55MB     961MB / 2.7MB       18
9dd9023adf46        maildev             0.00%               2.535MiB / 1.877GiB   0.13%               742kB / 1.91MB      246MB / 0B          10
4426d99884ae        mysql-gogs          0.12%               8.59MiB / 1.877GiB    0.45%               1.67MB / 6.12MB     259MB / 573MB       32
54d330316fba        portainer           0.00%               3.219MiB / 1.877GiB   0.17%               487kB / 5.8MB       65MB / 65.5kB       5
6966a54978df        mysql-sonarqube     0.37%               13.05MiB / 1.877GiB   0.68%               206MB / 142MB       998MB / 148MB       34
d3202c39fbe4        nexus               2.98%               405.7MiB / 1.877GiB   21.11%              1.51MB / 20.4MB     19.8GB / 946MB      118
```

Al ejecutar el comando _tal cual_, se muestra el consumo en tiempo real, actualizándo los valores cada dos o tres segundos aproximadamente (al estilo de `top`).

Podemos lanzar el comando para obtener el estado de manera puntual (es decir, que no se actualice automáticamente) mediante el parámetro `--no-stream`.

Podemos usar Este comando puede ser la base de un sistema de monitorización sencillo, pero para ello deberíamos poder exportar la salida de `docker stats --no-stream` a un fichero. Podemos usar la redirección de Linux para volcar la salida a un fichero `docker stats --no-stream > stats.txt`. El fichero lo podemos importar después en una herramienta que pueda _ingestar_ estos valores separados por tabulaciones... O podemos usar el parámetro `--format`,para definir el formato de la salida. Así podemos conseguir un fichero CSV:

```shell
sudo docker stats --no-stream --format "{{ .Container }}, {{ .Name }}, {{ .MemUsage }}, {{ .MemPerc }}, {{ .CPUPerc }}" >> stats.csv
```

La salida del comando sería:

```shell
$ cat stats.csv
$ 51b4b11494dc, jenkins, 180.2MiB / 1.877GiB, 9.38%, 0.19%
46a343a03526, sonarqube, 634.1MiB / 1.877GiB, 33.00%, 3.35%
aee4587d47c1, gogs, 20.88MiB / 1.877GiB, 1.09%, 0.00%
9dd9023adf46, maildev, 2.266MiB / 1.877GiB, 0.12%, 0.00%
4426d99884ae, mysql-gogs, 8.594MiB / 1.877GiB, 0.45%, 0.08%
54d330316fba, portainer, 3.219MiB / 1.877GiB, 0.17%, 0.00%
6966a54978df, mysql-sonarqube, 12.86MiB / 1.877GiB, 0.67%, 0.08%
d3202c39fbe4, nexus, 413.8MiB / 1.877GiB, 21.53%, 2.34%
$
```

Si lo ejecutamos de manera periódica -vía `cron`- tenemos una buena base para obtener monitorizar nuestros contenedores...

Quizás hay que darle una vuelta, pero teniendo la información, ahora la ¡imaginación es el límite!