/*
 * ingles-alinhar.js — alinhamento de palavras entre o idioma falado e o idioma mostrado.
 *
 * Os idiomas não seguem a mesma ordem: "laborious diligence" (EN) é "diligência laboriosa" (PT). A posição proporcional errava essas
 * palavras (destacava "laboriosa" quando a voz dizia "diligence"). Aqui cada palavra falada é ligada à palavra certa do texto mostrado:
 *   1. parentesco de grafia (laborious ~ laboriosa, diligence ~ diligência: prefixo comum e distância de edição);
 *   2. tradução da palavra solta pelo Tradutor local do navegador (cache; ex.: house = casa), comparada com as palavras do texto mostrado;
 *   3. posição relativa na frase (desempata e cobre palavras funcionais: the, of, a, de);
 *   4. programação dinâmica que prefere a ordem direta, aceita a troca de duas palavras vizinhas (substantivo e adjetivo) e penaliza saltos.
 * API: DDLab.mapPos(textoFalado, charIndex, textoMostrado, idiomaFalado) -> índice de caractere no texto mostrado (início da palavra alinhada)
 *      DDLab.alignWarm(falado, mostrado, idioma) -> calcula o alinhamento em tempo ocioso (frase curta: custo desprezível; longa: faixa em torno da diagonal)
 *      DDLab.alignPrepare(texto, idioma) -> Promise: traduz as palavras ainda sem tradução (o alinhamento melhora sozinho quando elas chegam)
 * Uso: núcleo (texto corrido, lado a lado, foco) e teleprompter. O cache de palavras fica em localStorage dd-ingles-pal-tr (até 3000).
 */
(function () {
    'use strict';
    const D = window.DDLab;
    if (!D) return;
    const WORD = /[\p{L}\p{M}\p{N}][\p{L}\p{M}\p{N}'’-]*/gu, KEY = 'dd-ingles-pal-tr', CAP = 3000;
    let ver = 0, wt = {}, saveT = null;
    try { wt = JSON.parse(localStorage.getItem(KEY) || '{}') || {}; } catch (e) { wt = {}; }
    const save = () => { clearTimeout(saveT); saveT = setTimeout(() => { try { const ks = Object.keys(wt); if (ks.length > CAP) ks.slice(0, ks.length - CAP).forEach((k) => delete wt[k]); localStorage.setItem(KEY, JSON.stringify(wt)); } catch (e) { /* sem storage */ } }, 1500); };

    const norm = (w) => w.toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/['’-]/g, '');
    function tokens(text) {
        const out = []; let m; WORD.lastIndex = 0;
        while ((m = WORD.exec(text))) out.push({ s: m.index, e: m.index + m[0].length, w: norm(m[0]), raw: m[0] });
        return out;
    }
    function lev(a, b) {
        const m = a.length, n = b.length; if (!m) return n; if (!n) return m;
        let prev = new Array(n + 1), cur = new Array(n + 1);
        for (let j = 0; j <= n; j++) prev[j] = j;
        for (let i = 1; i <= m; i++) { cur[0] = i; for (let j = 1; j <= n; j++) cur[j] = Math.min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1)); const t = prev; prev = cur; cur = t; }
        return prev[n];
    }
    // semelhança de grafia 0..1 (cognatos: prefixo comum longo ou poucas edições)
    function sim(a, b) {
        if (!a || !b) return 0;
        if (a === b) return a.length < 3 ? 0.6 : 1;                    // palavras curtas iguais (a, de) não provam nada
        if (a.length < 4 || b.length < 4) return 0;
        let p = 0; const mx = Math.min(a.length, b.length); while (p < mx && a[p] === b[p]) p++;
        const byPrefix = p >= 4 ? Math.min(1, (p / Math.max(a.length, b.length)) * 1.15) : 0;
        const byEdit = 1 - lev(a, b) / Math.max(a.length, b.length);
        return Math.max(byPrefix, byEdit >= 0.6 ? byEdit * 0.95 : 0);
    }
    const tkey = (lang, w) => lang + '|' + w;
    // melhor semelhança entre a palavra falada (ou a tradução dela) e uma palavra do texto mostrado
    function score(sp, tg, lang) {
        let best = sim(sp.w, tg.w);
        const tr = wt[tkey(lang, sp.w)];
        if (tr) tokens(tr).forEach((t) => { const x = sim(t.w, tg.w); if (x > best) best = x; });
        return best;
    }
    // Frases curtas: programação dinâmica completa. Frases longas (n*m > FULL): só uma faixa em torno da diagonal (custo linear),
    // porque a palavra certa fica perto da posição relativa; a faixa acompanha a diferença de tamanho entre os idiomas.
    const FULL = 1600, BAND = 16;
    function align(spoken, target, lang) {
        const A = tokens(spoken), B = tokens(target), n = A.length, m = B.length;
        if (!n || !m) return { A, B, map: [] };
        const NEG = -1e9, best = [], from = [], banded = n * m > FULL;
        const lo = new Array(n), hi = new Array(n);
        for (let i = 0; i < n; i++) {
            const c = n > 1 ? Math.round(i * (m - 1) / (n - 1)) : 0;
            lo[i] = banded ? Math.max(0, c - BAND) : 0; hi[i] = banded ? Math.min(m - 1, c + BAND) : m - 1;
            best.push(new Array(m).fill(NEG)); from.push(new Array(m).fill(-1));
            for (let j = lo[i]; j <= hi[i]; j++) {
                const prior = 1 - Math.abs((n > 1 ? i / (n - 1) : 0) - (m > 1 ? j / (m - 1) : 0));
                const s = 2 * score(A[i], B[j], lang) + 0.8 * prior;
                if (i === 0) { best[i][j] = s - 0.15 * j; continue; }
                let bv = NEG, bj = -1;
                for (let k = lo[i - 1]; k <= hi[i - 1]; k++) {
                    const d = j - k, pen = d === 1 ? 0 : d > 1 ? 0.25 * (d - 1) : d === 0 ? 0.5 : d === -1 ? 0.6 : 3;   // ordem direta, salto, repetir, troca de vizinhas, volta
                    const v = best[i - 1][k] - pen;
                    if (v > bv) { bv = v; bj = k; }
                }
                best[i][j] = s + bv; from[i][j] = bj;
            }
        }
        let j = lo[n - 1], bv = NEG; for (let k = lo[n - 1]; k <= hi[n - 1]; k++) if (best[n - 1][k] > bv) { bv = best[n - 1][k]; j = k; }
        const map = new Array(n);
        for (let i = n - 1; i >= 0; i--) { map[i] = j; j = from[i][j]; if (j < 0) j = 0; }
        return { A, B, map };
    }
    const cache = new Map();
    const idle = window.requestIdleCallback ? (fn) => window.requestIdleCallback(fn, { timeout: 400 }) : (fn) => setTimeout(fn, 30);
    const big = (c) => c.A.length * c.B.length > FULL;
    function build(key, spoken, target, lang) {
        const c = align(spoken, target, lang); c.ver = ver; cache.set(key, c);
        if (cache.size > 80) cache.delete(cache.keys().next().value);
        return c;
    }
    // Aquece o alinhamento fora do momento da animação (tempo ocioso): a frase falada e a seguinte já chegam calculadas.
    function warm(spoken, target, lang) {
        if (!spoken || !target) return;
        const key = lang + '\u0001' + spoken + '\u0001' + target, c = cache.get(key);
        if (c && c.ver === ver) return;
        idle(() => { const k = cache.get(key); if (!k || k.ver !== ver) build(key, spoken, target, lang); });
    }
    function mapPos(spoken, ci, target, lang) {
        if (!spoken || !target) return 0;
        const key = lang + '\u0001' + spoken + '\u0001' + target;
        let c = cache.get(key);
        if (!c) c = build(key, spoken, target, lang);
        else if (c.ver !== ver) {
            // traduções novas chegaram: frase curta recalcula na hora (barato); frase longa mantém o cálculo anterior e refaz em tempo ocioso
            if (big(c)) warm(spoken, target, lang); else c = build(key, spoken, target, lang);
        }
        if (!c.A.length || !c.B.length) return Math.min(target.length - 1, Math.round(ci / Math.max(1, spoken.length) * target.length));
        let i = 0; while (i < c.A.length - 1 && c.A[i].e <= ci) i++;
        return c.B[c.map[i]].s;
    }
    // traduz as palavras da frase que ainda não estão no cache (Tradutor local; até 6 ao mesmo tempo)
    const inflight = new Map();
    async function prepare(text, lang) {
        if (!text || !D.translateText) return;
        const todo = [];
        tokens(text).forEach((t) => { const k = tkey(lang, t.w); if (t.w.length >= 3 && !(k in wt) && !inflight.has(k) && todo.findIndex((x) => x.k === k) < 0) todo.push({ k, raw: t.raw.toLowerCase() }); });
        if (!todo.length) return;
        let got = 0;
        const run = async () => {
            while (todo.length) {
                const it = todo.shift();
                const p = D.translateText(it.raw, lang).then((r) => { if (r) { wt[it.k] = r.toLowerCase(); got++; } }).catch(() => {});
                inflight.set(it.k, p); await p; inflight.delete(it.k);
            }
        };
        await Promise.all([run(), run(), run(), run(), run(), run()]);
        if (got) { ver++; save(); }
    }
    D.mapPos = mapPos;
    D.alignWarm = warm;
    D.alignPrepare = prepare;

    // já prepara a frase falada e a seguinte (no idioma falado) para o alinhamento nunca esperar a tradução das palavras
    const textAt = (p, s, lang) => { const doc = D.doc; if (!doc || !doc.paras[p] || doc.paras[p].s[s] == null) return null; return lang === doc.lang ? doc.paras[p].s[s] : (doc.tr[p] && doc.tr[p][s]); };
    D.on('piece', (ev) => {
        prepare(ev.text, ev.lang);
        const doc = D.doc; if (!doc) return;
        let p = ev.p, s = ev.s + 1; if (s >= doc.paras[p].s.length) { p++; s = 0; }
        const nx = p < doc.paras.length ? textAt(p, s, ev.lang) : null;
        if (nx) prepare(nx, ev.lang);
    });
    D.on('stats-reset', () => { /* o cache de palavras não é estatística: fica */ });
})();
