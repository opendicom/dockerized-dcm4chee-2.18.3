# Descripción

dockerized-dcm4chee2.18.3 es una imagen de contenedor Docker creada para ejecutar [dcm4chee2.18.3](https://dcm4che.atlassian.net/wiki/spaces/ee2/overview) con persistencia para almacenar la configuración y los archivos dicom. La base de datos se asume instanciada en otro lugar.

Tiene [pre-instalado el visualizador Weasis](https://nroduit.github.io/en/old/dcm4chee/) de manera que se puede observar el estudio desde el acceso web.

Se actualizó el plugin libclib_jiio a su ultima versión (1.2.0-b04) que mejora el bug de memory leak al comprimir en jpeg2000 aunque no lo soluciona de manera definitiva. Mas información sobre esto [aquí](https://groups.google.com/g/dcm4che/c/tFnyGVAttEU).

Se equipó esta imagen con el demonio cron ejecutado en segundo plano, pues es posible realizar tareas de mantenimiento sobre el contenedor de manera automática, como puede ser eliminación de logs o reinicio de servicio como por ejemplo por los problemas de memory leak al usar compresión de imágenes.


# Funcionamiento

## Iniciar un nuevo contenedor sin persistencia

Esta instancia es absolutamente de prueba, pues cualquier configuración o archivo enviado será eliminado al finalizar el contenedor. 
```bash
docker run --rm --name nombre_contenedor -d dockerized-dcm4chee2.18.3:v1.0
```

# Persistencia

Esta imagen admite persistir varios componentes. Se utilizan los volúmenes de docker para ello. La elección del tipo de volumen (bind, named) depende de cada instalación y/o preferencia de uso.

 ### Configuración de dcm4chee

 El directorio `/opt/dcm4chee/server/default` es donde se guarda la configuración de dcm4chee-2.18.3. Para persistir estos datos, es necesario utilizar un volumen de tipo Named Volume ya que al iniciar el contenedor por primera vez se deben copiar los datos de configuración al nuevo volumen. Esta "copia" NO funciona con un volumen de tipo Bind.

 ### Repositorio DICOM

 Por defecto dcm4chee configura el repositorio de archivos dicom en el directorio `/opt/dcm4chee/server/default/archive`. Utilizando un volumen en este directorio se persiste el repositorio.

## Iniciar un nuevo contenedor con persistencia

Este ejemplo asume tener 1 directorio creado previamente para repositorio dicom.
```bash
/data/archive/
```
```bash
docker run --name nombre_contenedor -d \
	-v /data/archive:/opt/dcm4chee/server/default/archive/ \
	-v dcm4chee_vol:/opt/dcm4chee/server/default/ \
	dockerized-dcm4chee2.18.3:v1.0
```

Nótese la diferencia entre los volúmenes. El primer volumen es de tipo Bind y el segundo Named volume.

# Cron
Cron por defecto busca cambios en  `/etc/crontab`y `/etc/cron.d/*`  cuando detecta un cambio en alguno de los archivos actualiza su lista de tareas a memoria para ejecutar las mismas cuando corresponda. Este comportamiento funciona a la perfección desde un sistema operativo completo, pero puede fallar desde algunos contenedores, es decir cuándo hay un cambio en un archivo de configuración cron no lo detecta y por lo tanto no instala la nueva tarea en memoria.

Por tal motivo dockerized-dcm4chee2.18.3 maneja cron con cierta peculiaridad. Existe un archivo `/crontab_file` quien contiene la configuración de cron deseada. Cada vez que el contenedor es creado carga la configuración de este archivo a memoria. Si este archivo es cambiado luego de que el contenedor inició será necesario cargar manualmente a memoria la configuración o reiniciar el contenedor.

## Cargar la configuración de cron de forma manual

Para cargar de forma manual la configuración de cron luego que modificó el archivos /crontab_file

```bash
docker exec -it nombre_contenedor bash
crontab /crontab_file
```

## Log de tareas

Para ver la salida de las tareas es necesario redirigir stdin y stdout hacia el proceso con pid 1. De esta forma podremos observar los logs con el comando de Docker

```bash
docker logs nombre_contenedor
```

Para redirigir las salidas, en el archivo `/crontab_file` debemos agregar la tarea programada de la siguiente forma:

```bash
0 1 * * * /scripts/s1.sh > /proc/1/fd/1 2>/proc/1/fd/2
```

Nótese en este caso la salida de las tareas quedaran mezcladas con la salida de dcm4chee

# Iniciar un nuevo contenedor con persistencia y cron

Asumimos que existe el archivo `/host/path/crontab_file` en el host docker y que tiene una configuración de cron adecuada.

```bash
docker run --name nombre_contenedor -d \
    -v /data/archive:/opt/dcm4chee/server/default/archive/ \
	-v dcm4chee_vol:/opt/dcm4chee/server/default/ \
    -v /host/path/crontab_file:/crontab_file
	dockerized-dcm4chee2.18.3:v1.0
```

# Variables de Entorno
Se puede ajustar la conexión a la base de datos desde variables de entorno. Cada vez que el contenedor inicia comprueba estas variables y ajusta la configuración.

## `MYSQL_HOST` 
Variable opcional. Valor por defecto: `localhost`.
Especifica el nombre/ip del servidor de base de datos. En caso que sea otro contenedor deber ser el nombre de éste. Si se instancia desde un docker-compose.yml puede ser tanto el nombre del servicio o el del contenedor.

## `MYSQL_PORT`
Variable opcional. Valor por defecto `3306`
Especifica el puerto donde corre el motor de base de datos mysql.

## `MYSQL_DATABASE`
Variable opcional. Valor por defecto `pacsdb`
Especifica el nombre de la base de datos que utilizará dcm4chee-2.18.3

## `MYSQL_USER`
Variable opcional. Valor por defecto `pacs`
Especifica el nombre de usuario que utiliza dcm4chee-2.18.3 para la conexión a la base de datos
## `MYSQL_PASSWORD`
Variable opcional. Valor por defecto `pacs`
Especifica la contraseña que utiliza dcm4chee-2.18.3 para la conexión a la base de datos

## `MYSQL_CONNECT_RETRY`
Variable opcional. Valor por defecto `30`
Cuando el contenedor inicia y antes de arrancar dcm4chee-2.18.3 comprueba la conexión a la base de datos, si falla repite la comprobación cada `MYSQL_CONNECT_RETRY` segundos hasta que se establezca la conexión.


# Tags Soportados

- `1.0` 