# Come ci siamo arrivati

Log tecnico dell'analisi, utile se Rai cambia qualcosa e bisogna rifare il percorso.

## 1. Trovare e copiare l'app

```sh
ls /media/cryptofs/apps/usr/palm/applications/ | grep -i rai    # it.rainet.raiplay
APP=/media/cryptofs/apps/usr/palm/applications/it.rainet.raiplay
tar czf /media/developer/raiplay.tgz -C $APP .
```
Backup sempre prima di toccare qualcosa, e copia sul PC con `scp`.

`appinfo.json`: `type: web`, `main: index.html`, ma **399 file su 402 sono cifrati** con header `NCGFILE_HEADER` (cifratura LG/Nagra, decifrata dal runtime). Dal dump non si legge nulla.

## 2. DevTools remoto

1. In `appinfo.json` si aggiunge `"inspectable": true` (`sed -i 's/^{/{"inspectable":true,/' appinfo.json`, dopo backup).
2. `getAppInfo` continua a dire `false` finché non si **riavvia la TV**: l'application manager rilegge `appinfo` solo al boot (`rescan` non esiste).
3. Con l'app aperta compare la porta `9998` in ascolto. Si apre `http://<TV_IP>:9998` in Chrome e si clicca *inspect*.
4. Il debugger si stacca a ogni riavvio dell'app.

`ares-inspect` ha fallito per autenticazione, ma non serve.

## 3. Il codice in chiaro e il file in chiaro accettato

Dalla Console `fetch('Source/Core/Bundle/Core.Bundle.js')` restituisce JS leggibile: la decifratura avviene a livello di lettura file. Con un piccolo ricevitore HTTP sul PC si esportano i file decifrati.

Test di accettazione: sostituire `Env.js` (cifrato) con la copia in chiaro identica → l'app parte. Quindi il loader accetta file non cifrati (utile in teoria, poi non necessario).

## 4. La scoperta decisiva: il codice non è sul disco

`performance.getEntriesByType('resource')` mostra che i file caricati (`PlayerSmart.js`, `smartclip-rai-connector.js`, `hls.js`, `dash.js`...) arrivano da:

```
https://www.raiplay.it/appTv/rp2020SmartTV/prod/Source/...
```

In `Init.js`:
```js
CDNBaseUrl = ENV.enableCDN ? RPConfig.SmartTVUtils.CDNBaseUrl : ENV.overrideCDNBaseUrl ? ENV.overrideCDNBaseUrl : "./"
```
`Env.js` ha `enableCDN:!0`, quindi la copia locale (gen 2024) non viene usata. Una patch locale è inutile; in teoria `Env.js` in chiaro con `overrideCDNBaseUrl` potrebbe puntare a un proxy, ma non serve.

## 5. Dove nascono gli annunci

Dal config (`RPConfig`) e da `PlayerSmart.js`:

- URL ads nel config: `ad.sxp.smartclip.net/select?...` (Smartclip) e `pubads.g.doubleclick.net/gampad/ads?...` (Google Ad Manager).
- `RPConfig.player.enabled_SSAI` = `{smarttv:false, vega:false, android:false, ios:false}` → SSAI (Yospace) spento.
- In `PlayerSmart.Start`: `var adv = playerInfo.ADV.Url;` e `smartclip.start(adv).catch(tryAgainWithouAdv)`; se `adv` è vuoto: `'Nessun ADV presente, si parte senza ADV'`.

Conclusione: se Smartclip non risponde, il player riparte senza annunci. Basta far fallire la richiesta.

## 6. Il blocco

`/etc/hosts` sulla TV (c'è già un resolver locale su `127.0.0.1:53`, e l'app usa l'hosts di sistema, confermato dal `ERR_CONNECTION_REFUSED` in console).

Patch di riserva, **non usata**: forzare `var adv = null;` in una copia di `PlayerSmart.js` servita da proxy. Fragile: il file è di Rai e cambia.

## 7. Ripristino delle modifiche di debug

Il blocco non richiede `Env.js` in chiaro né `inspectable`. Per tornare agli originali:
```sh
APP=/media/cryptofs/apps/usr/palm/applications/it.rainet.raiplay
cp /media/developer/Env.js.ncg.bak $APP/Env.js          # deve iniziare con NCGFILE_HEAD
cp /media/developer/appinfo.json.bak $APP/appinfo.json  # effetto al prossimo boot
```
