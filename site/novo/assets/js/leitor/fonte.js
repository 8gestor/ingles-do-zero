/*
 * fonte.js — a FONTE de texto do Narrador, feita a partir de um documento aberto e do Tradutor (R2.5c; docs/10, seção 10).
 * Port fiel de `textFor` e `nextPiece` do `ingles.js` de hoje (linhas 712–722 e 870–882) e dos ganchos de `runTts` que mantêm a tradução à
 * frente da voz (linhas 879–883). Sem DOM.
 *
 *   doDocumento({ doc, tradutor, idiomaAudio, aoOcupado }) -> fonte   (o contrato do Narrador; ver narrador.js)
 *     doc          { id, lang, paras:[{ s:[frases] }], tr:{ [i]: [frases] } }
 *     tradutor     serviço `tradutor` já aberto neste documento
 *     idiomaAudio  () -> 'pt' | 'en'   (o idioma em que o aluno quer OUVIR)
 *     aoOcupado    (true) quando a narração está esperando o parágrafo traduzir (a tela mostra "traduzindo…")
 *
 * texto(): no idioma do livro devolve a frase; em outro idioma traduz SÓ essa frase (o resto traduz atrás); se não há tradução devolve o
 * original e a voz acompanha o idioma do texto realmente falado. jaPronta(): a frase seguinte sem esperar tradução (fila à frente).
 */
App.define('fonte', [], function () {
    'use strict';
    const TEM_LETRA = /\p{L}/u;
    function doDocumento(c) {
        const doc = c.doc, tr = c.tradutor, audio = c.idiomaAudio, ocupado = c.aoOcupado || (() => {});
        return {
            idiomaOriginal: doc.lang,
            paragrafos: () => doc.paras.length,
            frases: (p) => doc.paras[p].s.length,
            idiomaAudio: audio,
            primeiraVisivel: c.primeiraVisivel,
            async texto(p, s, idioma, ativo) {
                if (idioma === doc.lang) return { text: doc.paras[p].s[s], lang: idioma };
                if (!(doc.tr[p] && doc.tr[p][s] != null)) {          // caminho rápido: só esta frase, enquanto o resto traduz atrás
                    tr.ancora(p);
                    const q = await tr.frase(p, s);
                    if (!ativo()) return null;
                    if (q != null) { tr.bombear(); return { text: q, lang: idioma }; }
                }
                if (!doc.tr[p]) { ocupado(true); await tr.garantir(p); }
                if (!ativo()) return null;
                const t = doc.tr[p] && doc.tr[p][s];
                return t != null ? { text: t, lang: idioma } : { text: doc.paras[p].s[s], lang: doc.lang };
            },
            jaPronta(p, s, idioma) {
                const x = idioma === doc.lang ? doc.paras[p].s[s] : (doc.tr[p] && doc.tr[p][s]);
                return x == null ? null : { text: x, lang: idioma };
            },
            // mantém a tradução à frente da voz: o parágrafo ao começar e ao terminar, e já traduz a próxima frase enquanto esta toca
            antes(p, s) {
                tr.ancora(p);
                if (s === 0 || s === doc.paras[p].s.length - 1) tr.bombear();
                if (audio() !== doc.lang) {
                    const nx = s + 1 < doc.paras[p].s.length ? [p, s + 1] : (p + 1 < doc.paras.length ? [p + 1, 0] : null);
                    if (nx) tr.frase(nx[0], nx[1]);
                }
            }
        };
    }
    return { doDocumento, TEM_LETRA };
});
