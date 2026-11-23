/*
 * posicao.js — POSIÇÃO de leitura ESTÁVEL quando o layout muda (R2.5f; docs/10, seção 12; matriz `R1–R6`).
 * Port fiel do trecho de `ingles.js` de hoje (linhas 601–662): `settleAndKeep`, `keepPlace`, e os ouvintes de `resize` e `scroll`.
 *
 * O problema: a rolagem em pixels não acompanha o refluxo do texto. Quando a largura muda (o menu recolhe no modo foco, a janela é
 * redimensionada, o modo de leitura troca) o texto continua refluindo por algumas centenas de milissegundos, o parágrafo visível muda
 * sozinho e o app gravaria a posição errada por cima da certa. Então: enquanto o layout não assenta, NENHUMA posição é gravada; quando a
 * altura do documento fica estável, volta ao parágrafo que estava em leitura.
 *
 *   criar({ janela, doc, aberto, pagina, aoPosicao, largura, altura }) -> posicao
 *     doc()          documento aberto ({ pos, paras })    ·  aberto()  true se o leitor está na tela
 *     pagina         a página do Leitor (paraEl, primeiraVisivel)
 *     aoPosicao(i)   o aluno rolou até o parágrafo i e o layout está assentado: gravar e atualizar (progresso, tradução à frente, painel)
 *     largura()      largura da página (padrão: largura da janela)  ·  altura()  altura do documento (padrão: scrollHeight da página)
 *   posicao.ligar() -> desligar     liga `resize` e `scroll` da janela
 *   posicao.assentar(i)             espera o layout assentar e volta ao parágrafo i (troca de modo, abertura do livro)
 *   posicao.aoRedimensionar()       o mesmo que a janela redimensionada (útil quando a largura muda por CSS)
 *   posicao.aceitar()               a posição atual vale como referência (chamar ao abrir o livro)  ·  posicao.assentando()
 */
App.define('posicao', [], function () {
    'use strict';

    function criar(o) {
        const janela = o.janela || window, doc = o.doc, aberto = o.aberto || (() => true), pagina = o.pagina, aoPosicao = o.aoPosicao || (() => {});
        const largura = o.largura || (() => janela.document.documentElement.clientWidth);
        const altura = o.altura || (() => janela.document.documentElement.scrollHeight);
        let larguraAceita = 0, assentando = false, tAssentar = null, tRolagem = null, manterPos = 0;

        function manterLugar(i) {
            const d = doc(), el = d && pagina.paraEl(Math.max(0, Math.min(i | 0, d.paras.length - 1)));
            if (el) el.scrollIntoView({ block: 'start' });
        }
        function assentar(manter) {
            assentando = true; janela.clearTimeout(tAssentar); janela.clearTimeout(tRolagem);
            let ultima = -1, parado = 0, tentativas = 0;
            const passo = () => {
                if (!doc() || !aberto()) { assentando = false; return; }
                const h = altura();
                if (h === ultima) parado++; else { parado = 0; ultima = h; }
                if (parado >= 3 || ++tentativas > 30) { manterLugar(manter); larguraAceita = largura(); assentando = false; return; }
                tAssentar = janela.setTimeout(passo, 80);
            };
            passo();
        }
        function aoRedimensionar() {
            if (!doc() || !aberto()) return;
            if (!assentando) manterPos = doc().pos || 0;
            assentar(manterPos);
        }
        function aoRolar() {
            if (!doc() || !aberto() || assentando) return;
            janela.clearTimeout(tRolagem);
            tRolagem = janela.setTimeout(() => {
                // a largura mudou desde a última posição aceita: o texto refluiu e o parágrafo visível mudou sozinho. Não grava esse parágrafo.
                if (larguraAceita && Math.abs(largura() - larguraAceita) > 1) { manterPos = doc().pos || 0; assentar(manterPos); return; }
                const i = pagina.primeiraVisivel();
                larguraAceita = largura();
                doc().pos = i;
                aoPosicao(i);
            }, 250);
        }
        function ligar() {
            janela.addEventListener('resize', aoRedimensionar);
            janela.addEventListener('scroll', aoRolar, { passive: true });
            return () => { janela.removeEventListener('resize', aoRedimensionar); janela.removeEventListener('scroll', aoRolar); janela.clearTimeout(tAssentar); janela.clearTimeout(tRolagem); };
        }
        return {
            ligar, aoRedimensionar, aoRolar,
            assentar(i) { manterPos = i; assentar(i); },
            aceitar() { larguraAceita = largura(); },
            assentando: () => assentando
        };
    }
    return { criar };
});
