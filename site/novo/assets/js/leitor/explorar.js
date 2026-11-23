/*
 * explorar.js — explorar o texto PALAVRA A PALAVRA com as setas ← → (Shift + seta = frase a frase) (R2.5e; docs/10, seção 11; matriz `EX`).
 * Port fiel de `ingles-explorar.js` de hoje. A palavra explorada recebe o destaque principal (a mesma marca da palavra falada) e a palavra
 * equivalente no outro idioma recebe outro destaque: no lado a lado, na coluna da tradução (`.wd2`); nos demais modos, numa etiqueta logo
 * abaixo (`.lb-gloss`). O alinhamento liga as duas palavras mesmo quando a ordem muda. Tocando, a seta pausa a narração e passa a explorar;
 * atravessar o fim de uma frase segue para a primeira palavra da próxima.
 *
 *   criar({ host, envoltorio, doc, lerIdioma, pagina, marcacao, narrador, tradutor, alinhar, eventos }) -> explorar
 *   explorar.passo(dir) · explorar.equivalente(p, s, texto, idioma, ci) · explorar.reiniciar()  (ao trocar de livro, modo ou frase por fora)
 *   explorar.idioma()  repinta ao trocar o idioma de leitura  ·  explorar.ligar(eventos): reinicia quando a narração muda de frase
 * Evento emitido: `explorar-palavra` { p, s, k, ci, text, lang }.
 */
App.define('explorar', ['eventos'], function (deps) {
    'use strict';
    deps.eventos.declarar('explorar-palavra', 'o aluno explorou uma palavra com as setas: { p, s, k, ci, text, lang }');
    const PALAVRA = /[\p{L}\p{M}\p{N}][\p{L}\p{M}\p{N}'’-]*/gu;
    const palavras = (texto) => { const out = []; let m; PALAVRA.lastIndex = 0; while ((m = PALAVRA.exec(texto))) out.push({ s: m.index, e: m.index + m[0].length }); return out; };
    const outro = (l) => (l === 'en' ? 'pt' : 'en');

    function criar(o) {
        const host = o.host, wrap = o.envoltorio, doc = o.doc, lerIdioma = o.lerIdioma, pagina = o.pagina, marc = o.marcacao, nar = o.narrador, tr = o.tradutor, al = o.alinhar;
        const eventos = o.eventos || deps.eventos;
        let ex = null, gloss = null;

        function textoEm(p, s, idioma) {
            const d = doc();
            if (!d || !d.paras[p] || d.paras[p].s[s] == null) return null;
            if (idioma === d.lang) return d.paras[p].s[s];
            const t = d.tr[p];
            return t && t[s] != null ? t[s] : null;
        }
        // o texto como aparece na tela (idioma de leitura; se a tradução ainda não chegou, o original)
        function mostrado(p, s) {
            const rl = lerIdioma(), t = textoEm(p, s, rl);
            return t != null ? { text: t, lang: rl } : { text: textoEm(p, s, doc().lang), lang: doc().lang };
        }
        function vizinha(p, s, d) {
            const dc = doc(); let q = p, k = s + d;
            for (let guarda = 0; guarda < 4; guarda++) {
                if (k < 0) { q--; if (q < 0) return null; k = dc.paras[q].s.length - 1; }
                else if (k >= dc.paras[q].s.length) { q++; if (q >= dc.paras.length) return null; k = 0; }
                if (k >= 0 && dc.paras[q] && dc.paras[q].s[k] != null) return { p: q, s: k };
            }
            return null;
        }
        // a palavra equivalente no outro idioma
        function equivalente(p, s, texto, idioma, ci) {
            const ol = outro(idioma), ot = textoEm(p, s, ol);
            if (ot == null || !texto) return null;
            const ws = palavras(ot); if (!ws.length) return null;
            const pos = al ? al.mapPos(texto, ci, ot, idioma) : Math.round(ci / Math.max(1, texto.length) * ot.length);
            let w = ws[0]; ws.forEach((x) => { if (x.s <= pos) w = x; });
            return { text: ot, lang: ol, s: w.s, e: w.e };
        }
        function limparEquivalente() {
            host.querySelectorAll('.lb-t .wd2').forEach((n) => { const par = n.parentNode; if (par && par._ot != null) { par.textContent = par._ot; par._ot = null; } });
            if (gloss) gloss.hidden = true;
        }
        function pintarEquivalente(p, s, c) {
            limparEquivalente();
            if (!c) return;
            const pe = pagina.paraEl(p), tsp = pe && pe.querySelector('.lb-t[data-k="' + s + '"]');
            if (tsp) {                                                   // lado a lado: marca a palavra na coluna da tradução
                tsp._ot = tsp.textContent; tsp.textContent = '';
                const tx = tsp._ot; let ultimo = 0;
                palavras(tx).forEach((w) => { if (w.s > ultimo) tsp.append(tx.slice(ultimo, w.s)); const n = document.createElement('span'); n.className = 'wd2' + (w.s === c.s ? ' now2' : ''); n.textContent = tx.slice(w.s, w.e); tsp.append(n); ultimo = w.e; });
                if (ultimo < tx.length) tsp.append(tx.slice(ultimo));
                return;
            }
            const agora = host.querySelector('.wd.now');
            if (!agora || !wrap) return;
            if (!gloss) { gloss = document.createElement('div'); gloss.id = 'lb-gloss'; gloss.className = 'lb-gloss'; wrap.appendChild(gloss); }
            const wr = wrap.getBoundingClientRect(), r = agora.getBoundingClientRect();
            gloss.textContent = c.text.slice(c.s, c.e); gloss.lang = c.lang; gloss.hidden = false;
            gloss.style.top = Math.round(r.bottom - wr.top + 3) + 'px';
            gloss.style.left = Math.max(0, Math.round(r.left - wr.left)) + 'px';
        }
        function aplicar() {
            const { p, s, k } = ex, d = mostrado(p, s), ws = palavras(d.text), w = ws[k];
            if (!w) return;
            const m = marc.estado().marca;
            if (!m || m.p !== p || m.s !== s) marc.frase(p, s);
            nar.posicionar(p, s);
            marc.palavra(w.s, d.text.length, d.text, d.lang);                        // destaque principal (a mesma marca da palavra falada)
            const c = equivalente(p, s, d.text, d.lang, w.s);
            pintarEquivalente(p, s, c);
            if (!c && tr) tr.frase(p, s).then(() => { if (ex && ex.p === p && ex.s === s && ex.k === k) aplicar(); });   // traduz esta frase e repinta
            eventos.emit('explorar-palavra', { p, s, k, ci: w.s, text: d.text, lang: d.lang });
        }
        function passo(dir) {
            const dc = doc();
            if (!dc) return;
            if (nar.estado().tocando) nar.parar();                                   // a seta pausa e passa a explorar
            let cur = ex;
            if (!cur) { const m = marc.estado().marca || (nar.estado().cursor && nar.estado().cursor.p < dc.paras.length ? nar.estado().cursor : null) || { p: Math.min(pagina.primeiraVisivel(), dc.paras.length - 1), s: 0 }; cur = { p: m.p, s: m.s, k: dir > 0 ? -1 : 1e9 }; }
            let { p, s, k } = cur, d = mostrado(p, s), ws = palavras(d.text);
            k = Math.min(k, ws.length) + dir;
            if (k < 0) { const n = vizinha(p, s, -1); if (!n) k = 0; else { p = n.p; s = n.s; ws = palavras(mostrado(p, s).text); k = ws.length - 1; } }
            else if (k >= ws.length) { const n = vizinha(p, s, 1); if (!n) k = ws.length - 1; else { p = n.p; s = n.s; k = 0; } }
            ex = { p, s, k: Math.max(0, k) };
            aplicar();
        }
        const reiniciar = () => { ex = null; limparEquivalente(); };
        function ligar(ev) {
            const e = ev || eventos;
            return [e.on('narracao-frase', (d) => {
                if (d.texto != null) { reiniciar(); return; }                                 // a narração tocou uma frase: sai da exploração
                if (ex && (d.p !== ex.p || d.s !== ex.s)) reiniciar();                         // a marca mudou por outro caminho (Shift + seta)
            })];
        }
        return { passo, equivalente, reiniciar, ligar, idioma() { if (ex) aplicar(); }, estado: () => ex && { p: ex.p, s: ex.s, k: ex.k } };
    }
    return { criar, palavras };
});
