#!/bin/sh
# Blocca gli host pubblicitari di RaiPlay tramite /etc/hosts (da eseguire SULLA TV, come root).
# Reversibile: vedi uninstall.sh

HOSTS=/etc/hosts
BACKUP=/media/developer/hosts.bak
BLOCKED="ad.sxp.smartclip.net pubads.g.doubleclick.net"

[ -f "$BACKUP" ] || cp "$HOSTS" "$BACKUP" || { echo "backup fallito"; exit 1; }

for h in $BLOCKED; do
  grep -q " $h\$" "$HOSTS" || printf '0.0.0.0 %s\n:: %s\n' "$h" "$h" >> "$HOSTS"
done

echo "Backup originale: $BACKUP"
for h in $BLOCKED; do ping -c1 "$h" 2>&1 | head -1; done
