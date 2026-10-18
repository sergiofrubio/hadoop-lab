# Hadoop Lab: HDFS + YARN + Hive + Hue + Jupyter

Entorno local con Docker Compose para aprender Big Data con el ecosistema Hadoop.

## Requisitos

- Docker y Docker Compose v2
- Al menos **8 GB de RAM** asignados a Docker (10 GB es lo ideal) y ~10 GB de disco

## Arranque

```bash
docker compose up -d --build
docker compose ps          # espera a que todo esté "running"/"healthy"
docker compose logs -f hive-server   # opcional: seguir el arranque de Hive
```

La primera vez tarda varios minutos (descarga de imágenes y creación del esquema del metastore).
`hdfs-init` aparece como `Exited (0)`: es normal, es una tarea puntual que crea los directorios en HDFS.

## Servicios y puertos

| Servicio | URL / puerto | Notas |
|---|---|---|
| NameNode (HDFS) | http://localhost:9870 | Explorador: *Utilities → Browse the file system* |
| DataNode | http://localhost:9864 | |
| YARN ResourceManager | http://localhost:8088 | Aplicaciones en ejecución |
| NodeManager | http://localhost:8042 | |
| HiveServer2 | `jdbc:hive2://localhost:10000` | UI en http://localhost:10002 |
| Hue | http://localhost:8888 | La primera vez pide crear usuario/contraseña (cualquiera) |
| Jupyter | http://localhost:8889 | Token: `hadoop` |

## Primeros pasos

### HDFS

```bash
docker exec -it namenode bash
hdfs dfs -ls /
hdfs dfs -put /data/ventas.csv /datasets/
hdfs dfs -cat /datasets/ventas.csv | head
hdfs fsck /datasets -files -blocks
```

### MapReduce sobre YARN (wordcount)

```bash
docker exec -it namenode bash
hdfs dfs -mkdir -p /datasets/texto
hdfs dfs -put -f /data/texto.txt /datasets/texto/
hadoop jar /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar \
  wordcount /datasets/texto /datasets/texto_out
hdfs dfs -cat /datasets/texto_out/part-r-00000
```

Mientras se ejecuta, míralo en http://localhost:8088.

### Hive (beeline)

```bash
docker exec -it hive-server beeline -u jdbc:hive2://localhost:10000
```

```sql
CREATE DATABASE tienda;
CREATE EXTERNAL TABLE tienda.ventas (
  id INT, fecha DATE, tienda STRING, categoria STRING,
  producto STRING, unidades INT, precio DOUBLE)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/datasets/ventas'
TBLPROPERTIES ('skip.header.line.count'='1');

SELECT categoria, SUM(unidades * precio) AS ingresos
FROM tienda.ventas GROUP BY categoria ORDER BY ingresos DESC;
```

(Antes sube el CSV: `hdfs dfs -mkdir -p /datasets/ventas && hdfs dfs -put /data/ventas.csv /datasets/ventas/` desde el contenedor `namenode`, o ejecuta el notebook de Jupyter, que lo hace por ti.)

### Hue

Entra en http://localhost:8888, crea tu usuario (recomiendo admin/admin) y usa:

- **Editor → Hive** para lanzar SQL
- **Files** para navegar por HDFS y subir ficheros
- **Jobs** para ver las aplicaciones de YARN

### Jupyter

Abre http://localhost:8889 (sin contraseña ni token) y ejecuta `work/00_hadoop_hive_intro.ipynb`. Sube datos con WebHDFS, crea una tabla en Hive con PyHive y dibuja un gráfico con pandas.

## Estructura

```
.
├── docker-compose.yml
├── hadoop.env              # configuración de HDFS/YARN/MapReduce
├── hive/                   # Dockerfile (driver Postgres) + hive-site.xml
├── hue/
│   ├── entrypoint.sh       # inicio automático y ajuste de permisos
│   └── hue.ini
├── jupyter/Dockerfile      # PyHive, hdfs, pandas...
├── notebooks/              # tus cuadernos (se guardan en tu disco)
└── data/                   # datos de ejemplo (visibles en los contenedores en /data)
```

## Notas

- **Motor de Hive**: por defecto usa MapReduce en modo *local* (dentro de HiveServer2) porque arranca rápido y es estable en un portátil. Para enviar las consultas a YARN, edita `hive/hive-site.xml` (`mapreduce.framework.name=yarn` y descomenta el bloque `yarn.resourcemanager.hostname`) y ejecuta `docker compose restart hive-server`.
- **Seguridad**: no hay autenticación ni Kerberos y los permisos de HDFS están desactivados. Es solo para aprendizaje local, no lo expongas a la red.
- **Persistencia**: HDFS, el metastore y Hue guardan sus datos en volúmenes Docker.

## Problemas frecuentes

| Síntoma | Solución |
|---|---|
| Contenedores que se reinician o mueren (código 137) | Falta memoria: sube la RAM de Docker o baja `yarn.nodemanager.resource.memory-mb` en `hadoop.env` |
| Hive/Hue dan error de conexión al principio | HiveServer2 tarda 1-2 min en estar listo: `docker compose logs hive-server` |
| Puerto ocupado | Cambia el mapeo en `docker-compose.yml` (por ejemplo `"8890:8888"`) |
| Hue no muestra las tablas | Refresca el panel de la izquierda del editor |

## Parar y limpiar

```bash
docker compose down          # para los servicios, conserva los datos
docker compose down -v       # además borra HDFS, metastore y Hue (empezar de cero)
```
