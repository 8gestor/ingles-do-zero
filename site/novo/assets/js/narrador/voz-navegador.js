/*
 * voz-navegador.js — motor de VOZ do navegador (R2.2; docs/10-r2-narrador.md, seção 3). Não toca no DOM nem no livro.
 *
 * Port fiel de `speakBrowser`, `newUtt`, `canQueueAhead` e `pickVoice` do `ingles.js` de hoje (linhas 667–769). Contrato da Voz:
 *   falar(texto, idioma, { velocidade, aoProgresso(ci, len), proxima() }) → Promise<'end' | 'cancel' | 'error' | 'restart'>
 *   cancelar() · pedirReinicio() · disponivel() · filaAFrente()
 * O Narrador só conhece esse contrato (não sabe se a voz é a do navegador, o Piper local ou, no futuro, áudio gravado).
 *
 * O que este motor garante (cada item é testado por uma `speechSynthesis` FALSA e um relógio FALSO, em `test_novo_narrador.ps1`):
 *   · fila à frente: a frase seguinte entra na fila do motor enquanto a atual toca (sem a lacuna entre frases), só com motor que informa
 *     `speaking`/`pending` e fora dos modos de treino; se o fluxo mudou, a fila que sobrou é limpa;
 *   · posição da palavra: usa o evento de palavra da voz; sem ele (ou quando atrasa) segue a ESTIMATIVA por tempo (ritmo.js), sem correr à
 *     frente do evento nem voltar atrás; aprende a velocidade da voz a cada frase terminada bem;
 *   · vigia de partida: o motor engoliu o speak() → tenta a mesma frase de novo uma vez (7 s); se repetir, devolve 'error';
 *   · vigia de mudez: a voz começou e emudeceu (voz de rede que morre no meio) → cancela, e a leitura segue.
 * Tudo que depende do mundo (speechSynthesis, relógio, timers) é injetável: `criar({ synth, Utterance, agora, setInterval, ... })`.
 */
App.define('voz-navegador', ['ritmo', 'vozes'], function (deps) {
    'use strict';
    const R = deps.ritmo, V = deps.vozes;

    function criar(op) {
        op = op || {};
        const synth = op.synth !== undefined ? op.synth : (typeof speechSynthesis !== 'undefined' ? speechSynthesis : null);
        const Fala = op.Utterance || (typeof SpeechSynthesisUtterance !== 'undefined' ? SpeechSynthesisUtterance : null);
        const agora = op.agora || (() => performance.now());
        const setI = op.setInterval || ((f, ms) => setInterval(f, ms)), clrI = op.clearInterval || ((t) => clearInterval(t));
        const setT = op.setTimeout || ((f, ms) => setTimeout(f, ms)), clrT = op.clearTimeout || ((t) => clearTimeout(t));
        const nomePreferido = op.nomePreferido || (() => null);          // (idioma) -> nome da voz que o aluno escolheu
        const modoNormal = op.modoNormal || (() => true);                // false nos modos de treino (repetir, shadowing, ditado)
        const tabela = R.novaTabela();                                    // velocidade aprendida por idioma e voz (reaprende a cada abertura, como hoje)
        let pre = null;                                                   // fala já enfileirada no motor para a frase seguinte
        let reiniciar = false;                                            // pediram para recomeçar a fala atual (velocidade/voz mudou)
        let chaveVigia = '';                                              // frase que o vigia de partida já tentou de novo

        const disponivel = () => !!synth && !!Fala;
        const escolherVoz = (idioma) => synth ? V.escolher(idioma, nomePreferido(idioma), synth.getVoices()) : null;

        // Uma fala com ganchos (começou, palavra, terminou) que podem ser ligados DEPOIS de criada: é isso que permite enfileirar a frase seguinte.
        function novaFala(texto, idioma, velocidade) {
            const u = new Fala(texto), v = escolherVoz(idioma);
            u.lang = V.TAG[idioma]; u.rate = velocidade; if (v) { u.voice = v; u.lang = v.lang; }
            const h = { u, v, texto, idioma, velocidade, comecou: false, t0: 0, fim: null, aoComecar: null, aoPalavra: null, aoTerminar: null };
            u.onstart = () => { h.comecou = true; h.t0 = agora(); if (h.aoComecar) h.aoComecar(); };
            u.onboundary = (e) => { if (h.aoPalavra) h.aoPalavra(e); };
            u.onend = () => { h.fim = 'end'; if (h.aoTerminar) h.aoTerminar('end'); };
            u.onerror = (e) => { h.fim = e && (e.error === 'canceled' || e.error === 'interrupted') ? 'cancel' : 'error'; if (h.aoTerminar) h.aoTerminar(h.fim); };
            return h;
        }
        // só com motor que informa fila (speaking/pending) e fora dos modos de treino
        function filaAFrente() { return !!synth && synth.speaking === true && synth.pending === false && modoNormal(); }

        function falar(texto, idioma, o) {
            o = o || {};
            const velocidade = o.velocidade || 1, aoProgresso = o.aoProgresso, proxima = o.proxima;
            return new Promise((resolve) => {
                if (!disponivel()) { resolve('error'); return; }
                let h = pre && pre.texto === texto && pre.idioma === idioma && pre.velocidade === velocidade ? pre : null;
                if (pre && !h) synth.cancel();                          // sobrou frase enfileirada que não é esta (o fluxo mudou): limpa a fila
                pre = null;                                             // a frase já estava na fila do motor: só assume os ganchos
                const nova = !h; if (!h) h = novaFala(texto, idioma, velocidade);
                const nomeVoz = h.v ? h.v.name : '';
                let resolvida = false, t0 = 0, teveEvento = false, timer = null, vigia = null;
                let ultimoEv = 0, ultimoCi = 0, passoC = 6, dtMedio = 0;         // evento de palavra: instante, posição, distância média (caracteres) e intervalo médio (ms)
                const m = R.modelo(texto), cps = tabela.cpsDe(idioma, nomeVoz);
                const fim = (r) => {
                    if (resolvida) return; resolvida = true; clrI(timer); clrT(vigia);
                    if (r === 'end') chaveVigia = '';
                    if (r === 'end' && t0) tabela.aprender(idioma, nomeVoz, m, cps, (agora() - t0) / 1000, velocidade);
                    resolve(reiniciar ? (reiniciar = false, 'restart') : r);
                };
                const comecar = () => {
                    t0 = h.t0 || agora();
                    timer = setI(() => {       // segue pelo tempo estimado: sozinho sem evento de palavra; com evento, só cobre o que ele atrasou
                        const agoraMs = agora(), el = (agoraMs - t0) / 1000;
                        // vigia de mudez: a voz começou e emudeceu: cancela e a leitura segue para a frase seguinte
                        if (agoraMs - t0 > (m.total / (cps * velocidade) * 2.2 + 6) * 1000 && agoraMs - (ultimoEv || t0) > 6000) { pre = null; synth.cancel(); return; }
                        if (!aoProgresso) return;
                        let lo = R.posicaoEm(m, el, cps, velocidade);
                        if (teveEvento) {
                            if (agoraMs - ultimoEv <= Math.max(350, dtMedio * 1.6)) return;      // o evento da voz está em dia: ele manda, a estimativa não corre à frente
                            lo = Math.min(lo, ultimoCi + Math.max(8, Math.round(passoC * 1.2)));
                            if (lo <= ultimoCi) return;
                        }
                        aoProgresso(lo, texto.length);
                    }, 60);
                    if (proxima && !pre && filaAFrente()) {                              // buffer: a próxima frase entra na fila agora e o motor a fala sem lacuna
                        const nx = proxima();
                        if (nx) { pre = novaFala(nx.text, nx.lang, velocidade); synth.speak(pre.u); }
                    }
                };
                h.aoComecar = comecar;
                h.aoPalavra = (e) => {
                    if (e && e.name && e.name !== 'word') return;
                    const agoraMs = agora(), ci = (e && e.charIndex) || 0;
                    if (teveEvento) { dtMedio = dtMedio ? dtMedio * 0.7 + (agoraMs - ultimoEv) * 0.3 : agoraMs - ultimoEv; if (ci > ultimoCi) passoC = passoC * 0.7 + (ci - ultimoCi) * 0.3; }
                    teveEvento = true; ultimoEv = agoraMs; ultimoCi = Math.max(ultimoCi, ci);
                    if (aoProgresso) aoProgresso(ci, texto.length);
                };
                // vigia de partida: o motor engoliu o speak() (ou a voz não carregou): tenta a mesma frase de novo uma vez; se repetir, devolve erro
                vigia = setT(() => {
                    if (resolvida || h.comecou) return;
                    synth.cancel(); pre = null;
                    const chave = idioma + '|' + texto;
                    const outraVez = chaveVigia !== chave; chaveVigia = chave;
                    fim(outraVez ? 'restart' : 'error');
                }, 7000);
                h.aoTerminar = (r) => fim(r);
                if (h.comecou) comecar();
                if (h.fim) fim(h.fim); else if (nova) synth.speak(h.u);
            });
        }

        function cancelar() { pre = null; if (synth) synth.cancel(); }
        // pede para recomeçar a fala atual (o laço do Narrador a retoma da palavra falada); só vale com fala em andamento
        function pedirReinicio() { if (!synth) return; reiniciar = true; pre = null; synth.cancel(); }
        function limparReinicio() { reiniciar = false; }

        return { disponivel, falar, cancelar, pedirReinicio, limparReinicio, filaAFrente, tabela, escolherVoz };
    }

    return { criar };
});
