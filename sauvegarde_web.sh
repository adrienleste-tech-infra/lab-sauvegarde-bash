#!/bin/bash
SOURCE="/var/www"
DESTINATION="/home/adri/sauvegardes"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
RETENTION=7
mkdir -p "$DESTINATION"
tar -czf "$DESTINATION/backup_www_$DATE.tar.gz" "$SOURCE"
if [ $? -eq 0 ]; then
    echo "Sauvegarde réussie : backup_www_$DATE.tar.gz"
    find "$DESTINATION" -name "backup_www_*.tar.gz" -mtime +$RETENTION -delete
else
    echo "ERREUR : la sauvegarde a échoué"
fi
