/*
 * narrador.js — LAÇO DE REPRODUÇÃO da narração (R2.2; docs/10-r2-narrador.md, seções 2 e 3). Não toca no DOM, no livro nem no navegador:
 * recebe uma FONTE de texto e uma VOZ, e avisa o resto do app por eventos tipados.
 *
 * Port fiel de `runTts`, `startTts`, `stopTts`, `restartCurrent`, `stepSentence` e `nextPiece` do `ingles.js` de hoje (linhas 846–949).
 *
 *   criar({ fonte, voz, velocidade, idiomaAudio, ganchos })  →  { tocar(p, s), parar(), passo(dir), posicionar(p, s), reiniciarFala(), estado() }
 *
 *   FONTE (quem tem o texto; o Leitor implementa):
 *     paragrafos() → quantos parágrafos · frases(p) → quantas frases tem o parágrafo p
 *     texto(p, s, idioma, vale) → Promise<{ text, lang } | null>   texto no idioma pedido; traduz só esta frase ou cai no original (e a voz
 *                                  acompanha o idioma de `lang`); `vale()` diz se a fala ainda é a mesma (devolva null se não for)
 *     jaPronta(p, s, idioma) → { text, lang } | null               texto já disponível AGORA, sem esperar tradução (alimenta a fila à frente)
 *     antecipar(p, s, idioma)  (opcional)                           pedido para já ir traduzindo a frase (p, s)
 *     primeiraVisivel() (opcional)                                  de onde começar quando não há posição
 *   VOZ: o contrato de `voz-navegador.js` / `voz.js` (falar, cancelar, pedirReinicio, limparReinicio; `preparar(texto, idioma)` opcional, da voz neural).
 *   GANCHOS (opcionais): escala() → fator de velocidade (a repetição pode ser desacelerada) · aoTerminarFrase({ p, s, texto, idioma, ms }) →
 *     Promise<'repeat' | qualquer outra coisa> (modos de treino).
 *
 * EVENTOS (declarados aqui): narracao-estado { tocando } · narracao-frase { p, s, texto, idioma } · narracao-palavra { ci, len, texto, idioma } ·
 *   narracao-parou · narracao-retomou { p, s } · e o já existente frase-ouvida { palavras, p, s } (só quando a frase termina bem).
 */
App.define('narrador', ['eventos'], function (deps) {
    'use strict';
    const ev = deps.eventos;
    ev.declarar('narracao-estado', 'a narração começou ou parou: { tocando }');
    ev.declarar('narracao-frase', 'a frase falada mudou (ou a marca andou com a narração parada): { p, s, texto, idioma }');
    ev.declarar('narracao-palavra', 'posição da voz dentro da frase falada (evento da voz ou estimativa): { ci, len, texto, idioma }');
    ev.declarar('narracao-parou', 'a narração parou, ou vai recomeçar de outro ponto: limpar a marcação de palavra');
    ev.declarar('narracao-retomou', 'a fala foi recomeçada (velocidade ou voz mudou) e continua da palavra falada: { p, s }');

    const temLetra = (t) => /\p{L}|\p{N}/u.test(t);
    const contaPalavras = (t) => String(t).split(/\s+/).length;

    function criar(op) {
        const fonte = op.fonte, voz = op.voz;
        const velocidade = op.velocidade || (() => 1), idiomaAudio = op.idiomaAudio || (() => 'pt');
        const ganchos = op.ganchos || {};
        const agora = op.agora || (() => performance.now());
        let token = 0, tocando = false, cursor = null, marca = null;

        const escala = () => (ganchos.escala && ganchos.escala()) || 1;

        // Frase seguinte já pronta para falar (sem esperar tradução), pulando as que não têm letra (até 4), ou null
        function proximaPeca(p, s) {
            let q = p, k = s;
            for (let guarda = 0; guarda < 4; guarda++) {
                k++;
                if (k >= fonte.frases(q)) { q++; k = 0; if (q >= fonte.paragrafos()) return null; }
                const x = fonte.jaPronta(q, k, idiomaAudio());
                if (x == null) return null;
                if (temLetra(x.text)) return { text: x.text, lang: x.lang };
            }
            return null;
        }

        function marcar(p, s, texto, idioma) { marca = { p, s }; ev.emit('narracao-frase', { p, s, texto, idioma }); }

        async function laco(meu) {
            let erros = 0, retomar = null;
            const vale = () => meu === token;
            while (vale()) {
                const c = cursor;
                if (c.p >= fonte.paragrafos()) break;
                if (c.s >= fonte.frases(c.p)) { cursor = { p: c.p + 1, s: 0 }; continue; }
                const idioma = idiomaAudio();
                const peca = await fonte.texto(c.p, c.s, idioma, vale);
                if (!peca || !vale()) return;
                marcar(c.p, c.s, peca.text, peca.lang);                                   // texto exato que será falado (a legenda usa)
                if (!temLetra(peca.text)) { cursor = { p: c.p, s: c.s + 1 }; continue; }
                if (fonte.antecipar) {                                                      // mantém a tradução à frente da voz
                    if (c.s === 0 || c.s === fonte.frases(c.p) - 1) fonte.antecipar(c.p, c.s, idioma);
                    const nx = c.s + 1 < fonte.frases(c.p) ? [c.p, c.s + 1] : (c.p + 1 < fonte.paragrafos() ? [c.p + 1, 0] : null);   // já traduz a próxima frase enquanto esta toca
                    if (nx) fonte.antecipar(nx[0], nx[1], idioma);                         // (a Fonte decide se há o que traduzir)
                }
                const t0 = agora();
                let desvio = 0;                                                             // trocou velocidade/voz no meio da frase: continua da palavra falada
                if (retomar && retomar.p === c.p && retomar.s === c.s && retomar.text === peca.text) desvio = peca.text.lastIndexOf(' ', Math.max(0, retomar.ci - 1)) + 1;
                retomar = null;
                let ultimoCi = desvio;
                const falando = voz.falar(desvio ? peca.text.slice(desvio) : peca.text, peca.lang, {
                    velocidade: velocidade() * escala(),
                    aoProgresso: (ci) => {
                        if (!vale()) return;
                        ultimoCi = ci + desvio;
                        ev.emit('narracao-palavra', { ci: ultimoCi, len: peca.text.length, texto: peca.text, idioma: peca.lang });
                    },
                    proxima: () => proximaPeca(c.p, c.s)
                });
                if (voz.preparar) {                  // voz neural: DEPOIS de pedir a fala atual (ela entra primeiro na fila de síntese), já sintetiza as 2 seguintes
                    let n = 0, pp = c.p, ss = c.s + 1;
                    while (n < 2 && pp < fonte.paragrafos()) {
                        if (ss >= fonte.frases(pp)) { pp++; ss = 0; continue; }
                        const x = fonte.jaPronta(pp, ss, idioma);
                        if (x && x.text) voz.preparar(x.text, x.lang);
                        n++; ss++;
                    }
                }
                const r = await falando;
                if (!vale()) return;
                if (r === 'end') ev.emit('frase-ouvida', { palavras: contaPalavras(peca.text), p: c.p, s: c.s });
                if (r === 'restart') { retomar = { p: c.p, s: c.s, text: peca.text, ci: ultimoCi }; continue; }
                if (r === 'end' && ganchos.aoTerminarFrase) {                                // modos de treino: repetir, shadowing, ditado
                    const acao = await ganchos.aoTerminarFrase({ p: c.p, s: c.s, texto: peca.text, idioma: peca.lang, ms: agora() - t0 });
                    if (!vale()) return;
                    if (acao === 'repeat') continue;
                }
                if (r === 'error' && ++erros > 3) break;
                cursor = { p: c.p, s: c.s + 1 };
            }
            if (vale()) parar();
        }

        function tocar(p, s) {
            if (!fonte) return;
            voz.cancelar();
            token++;
            ev.emit('narracao-parou');
            voz.limparReinicio();
            if (p == null) {
                const c = cursor;
                if (c && c.p < fonte.paragrafos()) { p = c.p; s = c.s; } else { p = fonte.primeiraVisivel ? fonte.primeiraVisivel() : 0; s = 0; }
            }
            cursor = { p, s: s || 0 };
            tocando = true;
            ev.emit('narracao-estado', { tocando: true });
            laco(token);
        }
        function parar() {
            token++;
            ev.emit('narracao-parou');
            voz.cancelar();
            if (tocando) { tocando = false; ev.emit('narracao-estado', { tocando: false }); }
        }
        // velocidade ou voz mudou com a fala em andamento: recomeça e o laço continua da palavra falada
        function reiniciarFala() { if (tocando) { voz.pedirReinicio(); ev.emit('narracao-retomou', { p: cursor && cursor.p, s: cursor && cursor.s }); } }
        // Posiciona a marca e o cursor sem falar (parado): ▶ continua dali
        function posicionar(p, s) {
            cursor = { p, s };
            const x = fonte.jaPronta(p, s, idiomaAudio());
            marcar(p, s, x ? x.text : null, x ? x.lang : idiomaAudio());
        }
        // Setas: frase anterior/próxima, atravessando parágrafos. Tocando, a voz segue da nova frase; parado, só a marca anda.
        function passo(dir) {
            if (!fonte) return false;
            const atual = marca || cursor || { p: fonte.primeiraVisivel ? fonte.primeiraVisivel() : 0, s: 0 };
            let p = atual.p, s = atual.s + dir, achou = false;
            for (let guarda = 0; guarda < 4; guarda++) {
                if (s < 0) { p--; if (p < 0) return false; s = fonte.frases(p) - 1; }
                else if (s >= fonte.frases(p)) { p++; if (p >= fonte.paragrafos()) return false; s = 0; }
                if (s >= 0 && s < fonte.frases(p)) { achou = true; break; }
            }
            if (!achou) return false;
            if (tocando) tocar(p, s); else posicionar(p, s);
            return true;
        }
        const estado = () => ({ tocando, cursor: cursor && { p: cursor.p, s: cursor.s }, marca: marca && { p: marca.p, s: marca.s } });

        return { tocar, parar, passo, posicionar, reiniciarFala, estado };
    }

    return { criar };
});
