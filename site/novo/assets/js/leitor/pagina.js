/*
 * pagina.js — a PÁGINA do Leitor: constrói e pinta os parágrafos do documento no DOM (R2.5d; docs/10, seção 11).
 * Port fiel de `buildText`, `paintPara`, `paintAll` e `firstVisible` do `ingles.js` de hoje (linhas 544–613). O HTML gerado é o mesmo
 * (classes `lb-para`, `lb-head`, `lb-verse`, `lb-s`, `lb-t`, `lb-col`…), então o CSS e a marcação de hoje valem sem mudança.
 *
 *   criar({ host, doc, lerIdioma, lado, aoPintar }) -> pagina
 *     host         elemento que recebe os parágrafos
 *     doc()        o documento aberto { lang, paras:[{t, s:[frases]}], tr:{ [i]: [frases] } }
 *     lerIdioma()  'pt' | 'en': idioma em que o aluno LÊ (se for o outro, mostra a tradução frase a frase)
 *     lado()       true no modo lado a lado (original à esquerda e tradução à direita)
 *     aoPintar(i)  chamado depois de pintar o parágrafo i (a marcação se reaplica se for o parágrafo falado)
 *   pagina.construir(centro) · pagina.pintar(i) · pagina.pintarTudo(centro) · pagina.paraEl(i) · pagina.primeiraVisivel()
 * Documentos com mais de 300 parágrafos pintam primeiro o que está perto da leitura e o resto aos poucos (a tela abre rápido).
 */
App.define('pagina', [], function () {
    'use strict';
    const GRANDE = 300;

    function criar(o) {
        const host = o.host, doc = o.doc, lerIdioma = o.lerIdioma, lado = o.lado || (() => false), aoPintar = o.aoPintar || (() => {});
        let corrida = 0;
        const paraEl = (i) => host.children[i];

        function pintar(i) {
            const el = paraEl(i), d = doc();
            if (!el || !d) return;
            const p = d.paras[i], tr = d.tr[i], paraOutro = lerIdioma() !== d.lang;
            el.textContent = '';
            if (lado() && p.t !== 'h') {          // lado a lado: original à esquerda (frases clicáveis e narradas) e tradução à direita
                const colL = document.createElement('span'), colR = document.createElement('span');
                colL.className = 'lb-col lb-col-src'; colR.className = 'lb-col lb-col-tr' + (tr ? '' : ' pending');
                p.s.forEach((src, k) => { const sp = document.createElement('span'); sp.className = 'lb-s'; sp.dataset.k = String(k); sp.textContent = src; colL.append(sp, ' '); });
                if (tr) tr.forEach((x, k) => { const tsp = document.createElement('span'); tsp.className = 'lb-t'; tsp.dataset.k = String(k); tsp.textContent = x; colR.append(tsp, p.t === 'v' ? '\n' : ' '); });
                el.append(colL, colR);
                aoPintar(i);
                return;
            }
            p.s.forEach((src, k) => {
                const sp = document.createElement('span');
                sp.className = 'lb-s'; sp.dataset.k = String(k);
                let t = src;
                if (paraOutro) { if (tr && tr[k] != null) t = tr[k]; else sp.classList.add('pending'); }
                sp.textContent = t;
                el.append(sp, ' ');
            });
            aoPintar(i);
        }
        // Documentos grandes: pinta primeiro o que está perto da leitura e o resto aos poucos.
        function pintarTudo(centro) {
            const d = doc(), N = d.paras.length, minha = ++corrida;
            if (N <= GRANDE) { for (let i = 0; i < N; i++) pintar(i); return; }
            const ordem = [];
            for (let k = 0; k < N; k++) { if (centro + k < N) ordem.push(centro + k); if (k && centro - k >= 0) ordem.push(centro - k); }
            let n = 0;
            const passo = (q) => { for (let j = 0; j < q && n < ordem.length; j++) pintar(ordem[n++]); };
            passo(80);
            const depois = typeof requestIdleCallback === 'function' ? (f) => requestIdleCallback(f, { timeout: 200 }) : (f) => setTimeout(f, 16);
            const laco = () => { if (minha !== corrida || doc() !== d) return; passo(40); if (n < ordem.length) depois(laco); };
            depois(laco);
        }
        function construir(centro) {
            const d = doc();
            host.textContent = '';
            const frag = document.createDocumentFragment();
            d.paras.forEach((p, i) => {
                const el = document.createElement(p.t === 'h' ? 'h2' : 'p');
                el.className = 'lb-para' + (p.t === 'h' ? ' lb-head' : '') + (p.t === 'v' ? ' lb-verse' : '');
                el.dataset.i = String(i);
                frag.appendChild(el);
            });
            host.appendChild(frag);
            host.classList.toggle('lb-big', d.paras.length > GRANDE);
            pintarTudo(Math.min(centro || 0, d.paras.length - 1));
        }
        // primeiro parágrafo cujo fim está abaixo do topo (busca binária)
        function primeiraVisivel() {
            const kids = host.children;
            let lo = 0, hi = kids.length - 1, resp = 0;
            while (lo <= hi) { const mid = (lo + hi) >> 1; if (kids[mid].getBoundingClientRect().bottom > 8) { resp = mid; hi = mid - 1; } else lo = mid + 1; }
            return resp;
        }
        return { construir, pintar, pintarTudo, paraEl, primeiraVisivel, GRANDE };
    }
    return { criar, GRANDE };
});
