# raiplay-webos-adblock

Come disabilitare la pubblicità client-side di **RaiPlay** sull'app **LG webOS** (TV già rootata), senza modificare l'app e senza un server DNS: basta bloccare due host in `/etc/hosts`.

> **Stato:** testato su una TV LG webOS con RaiPlay `3.2.2`, contenuti **on-demand**. Live e midroll **non verificati** (vedi [Limiti](#limiti-e-cosa-non-è-stato-verificato)).

## TL;DR

Sulla TV, via SSH come root:

```sh
sh install.sh      # aggiunge 4 righe a /etc/hosts, con backup
```

Poi chiudi e riapri RaiPlay. Lo spot viene saltato e il video parte (il player ha un fallback "senza ADV" quando Smartclip non risponde).

## Come funziona

Le pubblicità di RaiPlay su smarttv sono **client-side**: il player chiede gli annunci a due servizi.

| Host | Ruolo |
|---|---|
| `ad.sxp.smartclip.net` | Smartclip, richiesta VAST/VMAP |
| `pubads.g.doubleclick.net` | Google Ad Manager (non sempre interpellato) |

Quando la richiesta a Smartclip fallisce, `PlayerSmart.js` scrive in console *"Errore durante l'inizializzazione di Smartclip, si prova senza ADV"* e poi *"Nessun ADV presente, si parte senza ADV"*: è un percorso previsto dagli sviluppatori Rai (`tryAgainWithouAdv`). Il rifiuto di connessione è immediato (`net::ERR_CONNECTION_REFUSED`), quindi non c'è attesa percepibile nel nostro test.

SSAI (annunci cuciti nel flusso, Yospace) per la piattaforma `smarttv` è **disattivato** nel config remoto (`RPConfig.player.enabled_SSAI`), quindi il blocco DNS è sufficiente.

## Requisiti

- TV LG con webOS **rootata** (es. [rootmy.tv](https://rootmy.tv)) e accesso SSH come root.
- Nessun server DNS, nessun reverse proxy.
- Facoltativo, solo per investigare: PC con Chrome, e (non necessario) Homebrew Channel.

## Installazione passo passo

1. **Entra via SSH**
   ```sh
   ssh root@<TV_IP>
   ```
2. **Copia gli script sulla TV** (dal PC)
   ```sh
   scp scripts/*.sh root@<TV_IP>:/media/developer/
   ```
3. **Esegui l'installazione** (sulla TV)
   ```sh
   sh /media/developer/install.sh
   ```
   Lo script salva l'originale in `/media/developer/hosts.bak` e aggiunge:
   ```
   0.0.0.0 ad.sxp.smartclip.net
   0.0.0.0 pubads.g.doubleclick.net
   :: ad.sxp.smartclip.net
   :: pubads.g.doubleclick.net
   ```
   Il `ping` mostrerà `127.0.0.1`: è normale, la richiesta non esce dalla TV.
4. **Riavvia RaiPlay**
   ```sh
   luna-send -n 1 luna://com.webos.applicationManager/closeByAppId '{"id":"it.rainet.raiplay"}'
   ```
   Riaprila dal telecomando e avvia un contenuto on-demand con pubblicità.
5. **Verifica la persistenza**: `reboot`, poi `sh /media/developer/check.sh`. Nel nostro test le righe sono sopravvissute al riavvio, ma non è garantito su altri firmware.

## Verifica con DevTools (facoltativo)

L'app è ispezionabile solo se `appinfo.json` ha `"inspectable": true` (vedi [docs/investigation.md](docs/investigation.md)). Poi apri `http://<TV_IP>:9998` e usa `scripts/devtools-checks.js`. Se il blocco funziona vedrai:

```
GET https://ad.sxp.smartclip.net/select?... net::ERR_CONNECTION_REFUSED
Errore durante l'inizializzazione di Smartclip, si prova senza ADV
Nessun ADV presente, si parte senza ADV
```

## Disinstallazione

```sh
sh /media/developer/uninstall.sh
```

## Se le righe spariscono dopo il riavvio

Nel nostro caso non è successo. Se succede, serve uno script di avvio. Su TV con Homebrew Channel si usa di solito `/var/lib/webosbrew/init.d/`, ma **non l'abbiamo verificato** su questa TV: controlla prima `ls -la /var/lib/webosbrew/init.d/` e adatta. Esempio, da testare:

```sh
cp /media/developer/install.sh /var/lib/webosbrew/init.d/50-adblock
chmod +x /var/lib/webosbrew/init.d/50-adblock
```

## Limiti e cosa non è stato verificato

- **Live** e contenuti con **midroll**: non provati. Con SSAI spento dovrebbero seguire lo stesso percorso client-side, ma è un'ipotesi.
- `pubads.g.doubleclick.net` non è stato interpellato nel contenuto testato: è bloccato per precauzione.
- Il **codice dell'app lo scarica la TV da `raiplay.it`** (non dal disco): Rai può cambiare host, formato o fallback in qualsiasi momento e il blocco potrebbe smettere di funzionare o rompere la riproduzione.
- Un **aggiornamento firmware** potrebbe ripristinare `/etc/hosts`.
- Altre app o altri contenuti che usano gli stessi domini (Google Ad Manager è molto diffuso) saranno bloccati sulla TV.
- Il blocco riguarda solo questa TV, nessun altro dispositivo.

## Cose che NON funzionano (risparmia tempo)

- **Patch dei file locali dell'app:** 399 file su 402 sono cifrati NCG (LG) e, soprattutto, con `enableCDN: true` l'app carica il codice da `https://www.raiplay.it/appTv/rp2020SmartTV/prod/`, non dal disco. Modificare i file locali non ha effetto.
- **`ares-inspect` con password:** nella nostra configurazione `ares-cli` non autenticava con la password; il debugger è raggiungibile direttamente sulla porta `9998` quando l'app gira.

## Note di sicurezza

- Le TV rootate con strumenti standard hanno una **password SSH di default**: cambiala (`passwd`) o usa una chiave in `/home/root/.ssh/authorized_keys`.
- Usa questo progetto solo sulla tua TV. Bloccare la pubblicità può violare i termini d'uso del servizio: la responsabilità è tua.

## Documentazione tecnica

Il percorso completo di analisi (dump dell'app, cifratura NCG, DevTools, scoperta del CDN, lettura di `PlayerSmart.js`) è in [docs/investigation.md](docs/investigation.md).

## Licenza

MIT, vedi [LICENSE](LICENSE).
