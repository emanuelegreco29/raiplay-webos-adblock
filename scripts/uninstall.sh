#!/bin/sh
# Ripristina /etc/hosts originale (da eseguire SULLA TV, come root).
BACKUP=/media/developer/hosts.bak
[ -f "$BACKUP" ] || { echo "nessun backup in $BACKUP"; exit 1; }
cp "$BACKUP" /etc/hosts && echo "ripristinato"
