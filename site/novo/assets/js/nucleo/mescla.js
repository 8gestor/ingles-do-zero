/*
 * mescla.js — regras de MESCLA do progresso (puras: não mexem em storage, rede nem DOM). Núcleo da regra "nunca apagar":
 * serve ao backup por arquivo e à sincronização na nuvem.
 *
 * É a PORTA, linha a linha, das funções que hoje vivem dentro de `ingles-sync.js` do app atual. Como os dois apps convivem e trocam
 * arquivos de backup (formato v1), o resultado precisa ser IDÊNTICO ao do app de hoje: o teste NUD1 compara as duas mesclas com
 * os casos fixos e com centenas de pares aleatórios. Qualquer mudança aqui exige o mesmo teste verde.
 *
 *   dia/campo = maior valor · cartão = o mais revisado (empate: o que vence depois) · livro = posição mais recente e mais palavras ouvidas
 *   histórico do dia = lista em união ou mapa (o local manda) · listas = união · escrita = união, no máximo 200
 */
App.define('mescla', [], function () {
    'use strict';
    const norm = (s) => String(s || '').toLowerCase().replace(/\s+/g, ' ').trim();                       // chave de livro: título normalizado + idioma
    const hash = (s) => { let h = 5381; for (let i = 0; i < s.length; i++) h = ((h << 5) + h + s.charCodeAt(i)) | 0; return String(h >>> 0); };
    const isObj = (x) => !!x && typeof x === 'object' && !Array.isArray(x);
    const BK_APP = 'ingles-progresso';

    function mergeLog(a, b) {
        const out = { d: {} };
        [a, b].forEach((l) => Object.keys((l && l.d) || {}).forEach((day) => {
            const r = out.d[day] || (out.d[day] = {}), s = l.d[day] || {};
            Object.keys(s).forEach((f) => { if (typeof s[f] === 'number') r[f] = Math.max(r[f] || 0, s[f]); });
        }));
        return out;
    }
    function mergeList(a, b, keyOf) {
        const out = [], seen = new Set();
        (Array.isArray(a) ? a : []).concat(Array.isArray(b) ? b : []).forEach((x) => { const k = keyOf(x); if (!seen.has(k)) { seen.add(k); out.push(x); } });
        return out;
    }
    function mergeAny(a, b) {
        if (Array.isArray(a) || Array.isArray(b)) return mergeList(a, b, (x) => JSON.stringify(x));
        if (a && typeof a === 'object') return Object.assign({}, b && typeof b === 'object' ? b : {}, a);
        return b == null ? a : b;
    }
    const cardScore = (c) => (c.reps || 0) + (c.lapses || 0);
    function mergeVocab(a, b) {
        const m = new Map();
        (a || []).concat(b || []).forEach((c) => { if (!c || !c.id) return; const o = m.get(c.id); if (!o || cardScore(c) > cardScore(o) || (cardScore(c) === cardScore(o) && (c.due || 0) > (o.due || 0))) m.set(c.id, c); });
        return Array.from(m.values());
    }
    function mergeDocs(a, b) {
        const out = {};
        [a, b].forEach((o) => Object.keys(o || {}).forEach((k) => {
            const x = o[k], y = out[k];
            if (!y) { out[k] = Object.assign({}, x); return; }
            const newer = (x.savedAt || 0) > (y.savedAt || 0) ? x : y;
            out[k] = Object.assign({}, y, newer, { heard: Math.max(x.heard || 0, y.heard || 0), savedAt: Math.max(x.savedAt || 0, y.savedAt || 0) });
        }));
        return out;
    }
    // op = { device, agora } só preenchem os campos de carimbo (`device` e `at`); não mudam o resultado da mescla
    function merge(a, b, op) {
        a = a || {}; b = b || {}; op = op || {};
        return {
            v: 1, at: op.agora || Date.now(), device: op.device || '',
            log: mergeLog(a.log, b.log),
            diaHist: mergeAny(a.diaHist, b.diaHist),
            semHist: mergeList(a.semHist, b.semHist, (x) => JSON.stringify(x)),
            escrita: mergeList(a.escrita, b.escrita, (x) => (x && (x.date + '|' + (x.kind || '') + '|' + (x.title || '') + '|' + String(x.text || '').slice(0, 80)))).slice(-200),
            vocab: mergeVocab(a.vocab, b.vocab),
            docs: mergeDocs(a.docs, b.docs)
        };
    }
    // forma estável (sem carimbos e com cartões em ordem) para comparar "mudou ou não"
    const stable = (s) => JSON.stringify({ log: s.log, diaHist: s.diaHist, semHist: s.semHist, escrita: s.escrita, vocab: (s.vocab || []).slice().sort((x, y) => (x.id < y.id ? -1 : 1)), docs: s.docs });

    // Valida e normaliza um arquivo de backup v1 ({ app, v, exportedAt, data }). Devolve null se não for um backup nosso.
    function limparBackup(raw) {
        let o = raw; if (typeof o === 'string') { try { o = JSON.parse(o); } catch (e) { return null; } }
        if (!isObj(o) || o.app !== BK_APP || o.v !== 1 || !isObj(o.data)) return null;
        const d = o.data;
        return {
            v: 1, at: Date.now(), device: String(d.device || ''),
            log: isObj(d.log) && isObj(d.log.d) ? d.log : { d: {} },
            diaHist: d.diaHist == null ? null : d.diaHist,
            semHist: Array.isArray(d.semHist) ? d.semHist : [],
            escrita: Array.isArray(d.escrita) ? d.escrita : [],
            vocab: (Array.isArray(d.vocab) ? d.vocab : []).filter((c) => c && typeof c.id === 'string'),
            docs: isObj(d.docs) ? d.docs : {}
        };
    }
    return { norm, hash, isObj, BK_APP, merge, mergeLog, mergeList, mergeAny, mergeVocab, mergeDocs, stable, limparBackup };
});
