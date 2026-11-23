/*
 * marcacao.js — a MARCAÇÃO em quatro camadas na tela (R2.5d; docs/10, seção 11; decisão visual aprovada em 2026-11-23).
 * Port fiel de `wrapWords`, `unwrapWords`, `curSpan`, `moveBand`, `keepInView`, `setWordAt`, `markSpan`, `setMark` e `clearMark` do
 * `ingles.js` de hoje (linhas 796–868). Gera o MESMO HTML e as MESMAS classes de hoje.
 *
 *   camada 1 · parágrafo  `.speaking` no parágrafo (barra na margem)
 *   camada 2 · linha      faixa `.lb-band` posicionada sobre a linha atual (escondida no teleprompter)
 *   camada 3 · frase      `.w.seg` na frase falada (marca-texto) e `.seg` na frase da coluna de tradução (lado a lado)
 *   camada 4 · palavra    `.wd.w.now` na palavra falada (as palavras viram `.wd` só na frase atual)
 *
 *   criar({ pagina, faixa, envoltorio, modo, mapear, eventos, rolagem }) -> marcacao
 *     pagina       a página do Leitor (paraEl, pintar)
 *     faixa / envoltorio   elemento da faixa de linha e o elemento que a contém (`lb-band`, `lb-wrap`)
 *     modo()       modo de leitura atual ('tele' esconde a faixa e troca a rolagem suave por seca)
 *     mapear(textoFalado, ci, textoDaTela, idiomaFalado) -> posição na frase da tela (alinhamento entre idiomas; padrão: proporcional)
 *     eventos      barramento do app; `ligar()` escuta `narracao-frase`, `narracao-palavra` e `narracao-estado`
 *   marcacao.frase(p, s) · marcacao.palavra(ci, len, texto, idioma) · marcacao.parou() · marcacao.reaplicar(i) · marcacao.estado()
 */
App.define('marcacao', [], function () {
    'use strict';

    function criar(o) {
        const pagina = o.pagina, faixa = o.faixa, envoltorio = o.envoltorio, modo = o.modo || (() => 'leitura'), mapear = o.mapear;
        const janela = o.janela || window;
        let marca = null, palavra = -1;
        const rolagem = o.rolagem || ((el, suave) => el.scrollIntoView({ block: 'center', behavior: suave ? 'smooth' : 'auto' }));

        function envolver(sp) {
            if (sp._w) return sp._w;
            const txt = sp.textContent;
            sp._orig = txt; sp.textContent = '';
            const palavras = [];
            let pos = 0;
            txt.split(/(\s+)/).forEach((parte) => {
                if (!parte) return;
                if (/^\s+$/.test(parte)) sp.append(parte);
                else { const w = document.createElement('span'); w.className = 'wd'; w.textContent = parte; sp.append(w); palavras.push({ el: w, s: pos, e: pos + parte.length }); }
                pos += parte.length;
            });
            sp._w = palavras;
            return palavras;
        }
        function desenvolver(sp) { if (sp && sp._w) { sp.textContent = sp._orig; sp._w = null; } }
        function spanAtual() {
            if (!marca) return null;
            const el = pagina.paraEl(marca.p);
            return el ? el.querySelector('.lb-s[data-k="' + marca.s + '"]') : null;
        }
        function moverFaixa(alvo) {
            if (!faixa) return;
            if (!alvo || modo() === 'tele') { faixa.style.display = 'none'; return; }      // teleprompter: a faixa fica escondida, nem calcula
            const c = envoltorio.getBoundingClientRect(), r = alvo.getBoundingClientRect();
            faixa.style.display = 'block';
            faixa.style.top = Math.round(r.top - c.top - 2) + 'px';
            faixa.style.height = Math.round(r.height + 4) + 'px';
        }
        function manterVisivel(el) {
            const r = el.getBoundingClientRect();
            if (r.top < 90 || r.bottom > janela.innerHeight - 110) rolagem(el, modo() !== 'tele');   // no teleprompter a rolagem suave só competiria com a animação da legenda
        }
        // posição dentro do texto falado -> palavra da frase na tela (mesma posição, ou alinhada/proporcional se o idioma da tela é outro)
        function palavraEm(ci, len, textoFalado, idiomaFalado) {
            const sp = spanAtual();
            if (!sp || !len) return;
            const palavras = envolver(sp);
            if (!palavras.length) return;
            const D = sp._orig.length;
            const pos = sp._orig === textoFalado ? ci : (mapear ? mapear(textoFalado, ci, sp._orig, idiomaFalado) : (ci / len) * D);
            let k = 0;
            while (k < palavras.length - 1 && palavras[k].e <= pos) k++;
            if (k === palavra) return;
            if (palavra >= 0 && palavras[palavra]) palavras[palavra].el.className = 'wd';
            palavra = k;
            palavras[k].el.className = 'wd w now';
            moverFaixa(palavras[k].el);
            manterVisivel(palavras[k].el);
        }
        function marcarSpan(ligado) {
            if (!marca) return;
            const el = pagina.paraEl(marca.p);
            if (!el) return;
            el.classList.toggle('speaking', ligado);
            const sp = el.querySelector('.lb-s[data-k="' + marca.s + '"]');
            if (sp) { sp.classList.toggle('w', ligado); sp.classList.toggle('seg', ligado); if (!ligado) desenvolver(sp); }
            const tsp = el.querySelector('.lb-t[data-k="' + marca.s + '"]');         // lado a lado: a mesma frase na coluna da tradução
            if (tsp) tsp.classList.toggle('seg', ligado);
            return sp;
        }
        function frase(p, s) {
            marcarSpan(false);
            const pe = pagina.paraEl(p); if (pe && !pe.firstChild) pagina.pintar(p);        // pintura em partes: garante o parágrafo falado
            marca = { p, s }; palavra = -1;
            const sp = marcarSpan(true);
            if (sp) { moverFaixa(sp); manterVisivel(sp); }
        }
        function limpar() { marcarSpan(false); marca = null; palavra = -1; moverFaixa(null); }
        // a narração parou: a marca da frase fica, a palavra e a faixa saem
        function parou() { if (marca) { marcarSpan(false); moverFaixa(null); palavra = -1; marcarSpan(true); } }
        // o parágrafo foi repintado (tradução chegou, mudou o modo): se é o falado, a marca volta
        function reaplicar(i) { if (marca && marca.p === i) { palavra = -1; marcarSpan(true); } }
        function ligar(eventos) {
            const ev = eventos || o.eventos;
            return [
                ev.on('narracao-frase', (e) => frase(e.p, e.s)),
                ev.on('narracao-palavra', (e) => palavraEm(e.ci, e.len, e.texto, e.idioma)),
                ev.on('narracao-estado', (e) => { if (e && e.tocando === false) parou(); })
            ];
        }
        return { frase, palavra: palavraEm, parou, limpar, reaplicar, ligar, estado: () => ({ marca: marca && { p: marca.p, s: marca.s }, palavra }), moverFaixa, manterVisivel };
    }
    return { criar };
});
