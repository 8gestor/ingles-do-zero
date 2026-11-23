/*
 * narrador.js — laço de REPRODUÇÃO da narração (R2.2; docs/10-r2-narrador.md, seção 3). Sem DOM, sem livro, sem motor de voz específico.
 *
 * Port fiel de `runTts`, `startTts`, `stopTts`, `stepSentence`, `restartCurrent` e `nextPiece` do `ingles.js` de hoje (linhas 860–949).
 * Quem fornece o texto é a FONTE (o Leitor, na R2.5); quem fala é a VOZ (voz-navegador, depois voz-neural). O Narrador só decide
 * "qual frase, quando, e o que fazer se a voz parar, errar ou for reiniciada".
 *
 *   criar({ voz, fonte, eventos, ganchos }) -> narrador
 *
 *   FONTE: { paragrafos() -> n,  frases(p) -> n,  idiomaOriginal,  idiomaAudio() -> 'pt'|'en',
 *            texto(p, s, idioma, ativo) -> Promise<{text, lang} | null>   (traduz ou cai no original; null se `ativo()` ficou falso)
 *            jaPronta(p, s, idioma) -> {text, lang} | null                (sem esperar: usada pela fila à frente)
 *            primeiraVisivel?() -> p,  antes?(p, s, peca)                  (opcionais: onde começar; preparar tradução à frente) }
 *   VOZ:   { falar(texto, idioma, { aoProgresso, proxima }) -> Promise<'end'|'cancel'|'error'|'restart'>, cancelar(), reiniciar() }
 *   GANCHOS (opcionais): aoTerminarFrase({p, s, text, lang, ms}) -> Promise<'repeat'|undefined>   (modos de treino)
 *
 * Eventos emitidos (declarados aqui; mapa dos de hoje em docs/10, seção 3.2):
 *   narracao-estado {tocando} · narracao-frase {p, s, texto, idioma} (texto = null quando só a marca andou) ·
 *   narracao-palavra {ci, len, texto, idioma} · narracao-parou · narracao-retomou · frase-ouvida {palavras, p, s}
 *
 * Comportamentos que garante (doc 10, seção 2): 1 token cancela fala antiga · 3 retoma da palavra falada · 5 voz acompanha o idioma do
 * texto realmente falado · 6 pula frase sem letra e para após 3 erros (contagem total, como hoje) · 7 palavras ouvidas só quando a
 * frase termina bem · 8 passo atravessa parágrafos (tocando segue da nova frase; parado só a marca anda) · 9 gancho de treino.
 */
App.define('narrador', ['eventos'], function (deps) {
    'use strict';
    const ev = deps.eventos;
    ev.declarar('narracao-estado', 'a narração começou ou parou: { tocando }');
    ev.declarar('narracao-frase', 'a narração está numa frase: { p, s, texto, idioma } (texto = null quando só a marca andou)');
    ev.declarar('narracao-palavra', 'posição da voz dentro da frase: { ci, len, texto, idioma }');
    ev.declarar('narracao-parou', 'a narração parou ou vai recomeçar (cancela o que dependia da fala anterior)');
    ev.declarar('narracao-retomou', 'a fala recomeça da palavra atual (trocou velocidade ou voz)');

    const TEM_LETRA = /\p{L}|\p{N}/u;

    function criar(o) {
        const voz = o.voz, gan = o.ganchos || {}, emitir = o.eventos || ev;
        let fonte = null, token = 0, tocando = false, cursor = null, marca = null;

        const palavras = (t) => t.split(/\s+/).length;
        const ativoDe = (t) => () => t === token;

        // Frase seguinte já pronta para falar (no idioma de áudio disponível agora, sem esperar tradução), ou null
        function proxima(p, s) {
            if (!fonte) return null;
            let q = p, k = s;
            for (let guarda = 0; guarda < 4; guarda++) {
                k++;
                if (k >= fonte.frases(q)) { q++; k = 0; if (q >= fonte.paragrafos()) return null; }
                const x = fonte.jaPronta(q, k, fonte.idiomaAudio());
                if (x == null) return null;
                if (TEM_LETRA.test(x.text)) return { text: x.text, lang: x.lang };
            }
            return null;
        }

        async function laco(t) {
            let erros = 0, retomar = null;
            while (t === token && fonte) {
                const c = cursor;
                if (c.p >= fonte.paragrafos()) break;
                if (c.s >= fonte.frases(c.p)) { cursor = { p: c.p + 1, s: 0 }; continue; }
                const peca = await fonte.texto(c.p, c.s, fonte.idiomaAudio(), ativoDe(t));
                if (!peca || t !== token) return;
                marca = { p: c.p, s: c.s };
                emitir.emit('narracao-frase', { p: c.p, s: c.s, texto: peca.text, idioma: peca.lang });      // texto exato que será falado (a legenda usa)
                if (!TEM_LETRA.test(peca.text)) { cursor = { p: c.p, s: c.s + 1 }; continue; }
                if (fonte.antes) fonte.antes(c.p, c.s, peca);
                const inicio = o.agora ? o.agora() : performance.now();
                let desloca = 0;                                       // trocou velocidade/voz no meio da frase: continua da palavra falada
                if (retomar && retomar.p === c.p && retomar.s === c.s && retomar.text === peca.text) desloca = peca.text.lastIndexOf(' ', Math.max(0, retomar.ci - 1)) + 1;
                retomar = null;
                let ultimoCi = desloca;
                const r = await voz.falar(desloca ? peca.text.slice(desloca) : peca.text, peca.lang, {
                    aoProgresso: (ci) => { if (t === token) { ultimoCi = ci + desloca; emitir.emit('narracao-palavra', { ci: ultimoCi, len: peca.text.length, texto: peca.text, idioma: peca.lang }); } },
                    proxima: () => proxima(c.p, c.s)
                });
                if (t !== token) return;
                if (r === 'end') emitir.emit('frase-ouvida', { palavras: palavras(peca.text), p: c.p, s: c.s });
                if (r === 'restart') { retomar = { p: c.p, s: c.s, text: peca.text, ci: ultimoCi }; continue; }
                if (r === 'end' && gan.aoTerminarFrase) {              // modos de treino: repetir, shadowing, ditado
                    const acao = await gan.aoTerminarFrase({ p: c.p, s: c.s, text: peca.text, lang: peca.lang, ms: (o.agora ? o.agora() : performance.now()) - inicio });
                    if (t !== token) return;
                    if (acao === 'repeat') continue;
                }
                if (r === 'error' && ++erros > 3) break;
                cursor = { p: c.p, s: c.s + 1 };
            }
            if (t === token) parar();
        }

        function abrir(f) { parar(); fonte = f; cursor = null; marca = null; }
        function fechar() { parar(); fonte = null; cursor = null; marca = null; }

        function tocar(p, s) {
            if (!fonte) return;
            voz.cancelar();
            token++;
            emitir.emit('narracao-parou');
            if (p == null) {
                const c = cursor;
                if (c && c.p < fonte.paragrafos()) { p = c.p; s = c.s; } else { p = fonte.primeiraVisivel ? fonte.primeiraVisivel() : 0; s = 0; }
            }
            cursor = { p, s: s || 0 };
            tocando = true;
            emitir.emit('narracao-estado', { tocando: true });
            laco(token);
        }
        function parar() {
            token++;
            emitir.emit('narracao-parou');
            voz.cancelar();
            if (tocando) { tocando = false; emitir.emit('narracao-estado', { tocando: false }); }
        }
        // trocou velocidade ou voz: a fala em curso termina com 'restart' e o laço continua da palavra falada
        function reiniciar() { if (tocando) { voz.reiniciar(); emitir.emit('narracao-retomou'); } }
        // Setas: frase anterior/próxima. Tocando, a voz segue de lá; parado, só a marca e a posição andam.
        function passo(dir) {
            if (!fonte) return;
            const cur = marca || cursor || { p: fonte.primeiraVisivel ? fonte.primeiraVisivel() : 0, s: 0 };
            let p = cur.p, s = cur.s + dir;
            for (let guarda = 0; guarda < 4; guarda++) {
                if (s < 0) { p--; if (p < 0) return; s = fonte.frases(p) - 1; }
                else if (s >= fonte.frases(p)) { p++; if (p >= fonte.paragrafos()) return; s = 0; }
                if (s >= 0 && s < fonte.frases(p)) break;
            }
            if (tocando) tocar(p, s);
            else { cursor = { p, s }; marca = { p, s }; emitir.emit('narracao-frase', { p, s, texto: null, idioma: null }); }
        }
        return { abrir, fechar, tocar, parar, reiniciar, passo, estado: () => ({ tocando, cursor: cursor && { p: cursor.p, s: cursor.s }, marca: marca && { p: marca.p, s: marca.s } }) };
    }
    return { criar };
});
