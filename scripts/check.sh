#!/bin/sh
# Verifica lo stato del blocco (da eseguire SULLA TV).
echo "--- uptime"; uptime
echo "--- righe in /etc/hosts"; grep -E 'smartclip|doubleclick' /etc/hosts || echo "NESSUNA (blocco non attivo)"
echo "--- risoluzione"
for h in ad.sxp.smartclip.net pubads.g.doubleclick.net; do ping -c1 "$h" 2>&1 | head -1; done
