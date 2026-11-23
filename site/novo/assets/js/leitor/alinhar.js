/*
 * alinhar.js — ALINHAMENTO de palavras entre o idioma falado e o idioma mostrado (R2.5e; docs/10, seção 11; matriz `AL`).
 * Port fiel de `ingles-alinhar.js` de hoje. Os idiomas não seguem a mesma ordem: "laborious diligence" (EN) é "diligência laboriosa" (PT);
 * a posição proporcional errava essas palavras. Cada palavra falada é ligada à palavra certa do texto mostrado:
 *   1. parentesco de grafia (laborious ~ laboriosa: prefixo comum e distância de edição);
 *   2. tradução da palavra solta pelo Tradutor local (cache; ex.: house = casa), comparada com as palavras do texto mostrado;
 *   3. posição relativa na frase (desempata e cobre palavras funcionais: the, of, a, de);
 *   4. programação dinâmica que prefere a ordem direta, aceita a troca de duas palavras vizinhas e penaliza saltos.
 *
 *   criar({ traduzirPalavra, armazenar, palavras }) -> { mapPos(falado, ci, mostrado, idiomaFalado), preparar(texto, idioma), versao(), palavras() }
 *     traduzirPalavra(palavra, idioma) -> Promise<string | null>   (padrão: nenhuma; o alinhamento então usa só grafia e posição)
 *     armazenar   true (padrão) guarda o cache de palavras em `dd-ingles-pal-tr` (até 3000), o mesmo do app de hoje
 *   mapPos devolve o índice de caractere, no texto mostrado, do início da palavra alinhada.
 */
App.define('alinhar', ['armazem'], function (deps) {
    'use strict';
    const ls = deps.armazem.ls;
    const PALAVRA = /[\p{L}\p{M}\p{N}][\p{L}\p{M}\p{N}'’-]*/gu, CHAVE = 'dd-ingles-pal-tr', LIMITE = 3000;
    const norm = (w) => w.toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/['’-]/g, '');
    function tokens(texto) {
        const out = []; let m; PALAVRA.lastIndex = 0;
        while ((m = PALAVRA.exec(texto))) out.push({ s: m.index, e: m.index + m[0].length, w: norm(m[0]), raw: m[0] });
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
        const porPrefixo = p >= 4 ? Math.min(1, (p / Math.max(a.length, b.length)) * 1.15) : 0;
        const porEdicao = 1 - lev(a, b) / Math.max(a.length, b.length);
        return Math.max(porPrefixo, porEdicao >= 0.6 ? porEdicao * 0.95 : 0);
    }
    const chave = (idioma, w) => idioma + '|' + w;

    function criar(o) {
        o = o || {};
        let ver = 0, wt = {}, salvarT = null;
        const guardar = o.armazenar !== false;
        if (o.palavras) wt = JSON.parse(JSON.stringify(o.palavras));
        else if (guardar) { const s = ls.get(CHAVE, null); if (s && typeof s === 'object') wt = s; }
        const salvar = () => { if (!guardar) return; clearTimeout(salvarT); salvarT = setTimeout(() => { const ks = Object.keys(wt); if (ks.length > LIMITE) ks.slice(0, ks.length - LIMITE).forEach((k) => delete wt[k]); ls.set(CHAVE, wt); }, 400); };

        // melhor semelhança entre a palavra falada (ou a tradução dela) e uma palavra do texto mostrado
        function pontuar(sp, tg, idioma) {
            let melhor = sim(sp.w, tg.w);
            const tr = wt[chave(idioma, sp.w)];
            if (tr) tokens(tr).forEach((t) => { const x = sim(t.w, tg.w); if (x > melhor) melhor = x; });
            return melhor;
        }
        function alinhar(falado, alvo, idioma) {
            const A = tokens(falado), B = tokens(alvo), n = A.length, m = B.length;
            if (!n || !m) return { A, B, map: [] };
            const NEG = -1e9, best = [], de = [];
            for (let i = 0; i < n; i++) {
                best.push(new Array(m).fill(NEG)); de.push(new Array(m).fill(-1));
                for (let j = 0; j < m; j++) {
                    const prior = 1 - Math.abs((n > 1 ? i / (n - 1) : 0) - (m > 1 ? j / (m - 1) : 0));
                    const s = 2 * pontuar(A[i], B[j], idioma) + 0.8 * prior;
                    if (i === 0) { best[i][j] = s - 0.15 * j; continue; }
                    let bv = NEG, bj = -1;
                    for (let k = 0; k < m; k++) {
                        const d = j - k, pen = d === 1 ? 0 : d > 1 ? 0.25 * (d - 1) : d === 0 ? 0.5 : d === -1 ? 0.6 : 3;   // ordem direta, salto, repetir, troca de vizinhas, volta
                        const v = best[i - 1][k] - pen;
                        if (v > bv) { bv = v; bj = k; }
                    }
                    best[i][j] = s + bv; de[i][j] = bj;
                }
            }
            let j = 0, bv = NEG; for (let k = 0; k < m; k++) if (best[n - 1][k] > bv) { bv = best[n - 1][k]; j = k; }
            const map = new Array(n);
            for (let i = n - 1; i >= 0; i--) { map[i] = j; j = de[i][j]; if (j < 0) j = 0; }
            return { A, B, map };
        }
        const cache = new Map();
        function mapPos(falado, ci, alvo, idioma) {
            if (!falado || !alvo) return 0;
            const k = idioma + '\u0001' + falado + '\u0001' + alvo;
            let c = cache.get(k);
            if (!c || c.ver !== ver) {
                c = alinhar(falado, alvo, idioma); c.ver = ver; cache.set(k, c);
                if (cache.size > 80) cache.delete(cache.keys().next().value);
            }
            if (!c.A.length || !c.B.length) return Math.min(alvo.length - 1, Math.round(ci / Math.max(1, falado.length) * alvo.length));
            let i = 0; while (i < c.A.length - 1 && c.A[i].e <= ci) i++;
            return c.B[c.map[i]].s;
        }
        // traduz as palavras da frase que ainda não estão no cache (até 6 ao mesmo tempo); o alinhamento melhora sozinho quando chegam
        const emVoo = new Map();
        async function preparar(texto, idioma) {
            if (!texto || !o.traduzirPalavra) return;
            const falta = [];
            tokens(texto).forEach((t) => { const k = chave(idioma, t.w); if (t.w.length >= 3 && !(k in wt) && !emVoo.has(k) && falta.findIndex((x) => x.k === k) < 0) falta.push({ k, raw: t.raw.toLowerCase() }); });
            if (!falta.length) return;
            let obteve = 0;
            const rodar = async () => {
                while (falta.length) {
                    const it = falta.shift();
                    const p = Promise.resolve(o.traduzirPalavra(it.raw, idioma)).then((r) => { if (r) { wt[it.k] = r.toLowerCase(); obteve++; } }).catch(() => {});
                    emVoo.set(it.k, p); await p; emVoo.delete(it.k);
                }
            };
            await Promise.all([rodar(), rodar(), rodar(), rodar(), rodar(), rodar()]);
            if (obteve) { ver++; salvar(); }
        }
        return { mapPos, preparar, versao: () => ver, palavras: () => wt };
    }
    return { criar, tokens, sim, lev };
});
