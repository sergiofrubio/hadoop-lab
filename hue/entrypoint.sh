#!/bin/bash
set -e

# Asegurar que el directorio de la base de datos existe y tiene permisos para el usuario hue
mkdir -p /usr/share/hue/desktop/hue-db
chown -R hue:hue /usr/share/hue/desktop/hue-db
chmod 775 /usr/share/hue/desktop/hue-db

# Ejecutar el script original de Hue bajo el usuario 'hue'
exec su -s /bin/bash hue -c "exec /usr/share/hue/startup.sh"
