// Da incollare nella Console di DevTools (http://<TV_IP>:9998 -> inspect su RaiPlay).

// 1) Prima di avviare il video:
performance.setResourceTimingBufferSize(5000); performance.clearResourceTimings();

// 2) A video partito: richieste verso gli host pubblicitari
performance.getEntriesByType('resource')
  .filter(r => /smartclip|doubleclick/i.test(r.name))
  .map(r => r.name.slice(0, 120));

// 3) Tutti gli host contattati (per scoprire eventuali nuovi ad server)
[...new Set(performance.getEntriesByType('resource').map(r => { try { return new URL(r.name).hostname } catch (e) { return r.name } }))];

// 4) SSAI attivo per la tua piattaforma? (nel nostro caso: tutto false)
RPConfig.player.enabled_SSAI;

// 5) Host pubblicitari presenti nel config remoto
[...new Set((JSON.stringify(RPConfig).match(/https?:[^"\\]*/g) || []).filter(u => /adv|smartclip|vmap|ads|doubleclick|fwmrm|freewheel|yospace/i.test(u)))];
