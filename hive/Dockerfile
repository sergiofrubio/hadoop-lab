FROM apache/hive:4.0.0

# El driver JDBC de PostgreSQL no viene en la imagen; el metastore lo necesita.
ADD --chmod=644 https://jdbc.postgresql.org/download/postgresql-42.7.3.jar /opt/hive/lib/postgres.jar
