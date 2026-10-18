FROM quay.io/jupyter/scipy-notebook:latest

# Clientes para hablar con Hive (PyHive) y HDFS (WebHDFS).
# thrift_sasl + pure-sasl: necesarios para conectar a HiveServer2 con auth NONE
# sin compilar la librería C "sasl".
RUN pip install --no-cache-dir pyhive thrift thrift_sasl pure-sasl hdfs pyarrow
