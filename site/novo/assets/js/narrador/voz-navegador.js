/*
 * voz-navegador.js — motor de voz do NAVEGADOR (R2.2; docs/10-r2-narrador.md, seções 3 e 5). Sem DOM, sem livro.
 *
 * Port fiel de `newUtt`, `speakBrowser`, `canQueueAhead` e `restartCurrent` do `ingles.js` de hoje (linhas 689–769 e 944), com tudo
 * que era global injetado, para testar com uma `speechSynthesis` FALSA e um relógio simulado:
 *   criar({ synth, Utterance, relogio, voz, velocidade, podeEnfileirar }) -> motor
 *     synth           objeto como `speechSynthesis` (speak, cancel, getVoices, speaking, pending)
 *     Utterance       construtor como `SpeechSynthesisUtterance`
 *     relogio         { agora, setInterval, clearInterval, setTimeout, clearTimeout }  (padrão: o da janela)
 *     voz(idioma)     devolve a voz a usar (objeto do navegador) ou null            (padrão: vozes.escolher com a lista do synth)
 *     velocidade()    fator de velocidade efetivo (já com a escala dos modos de treino)   (padrão: 1)
 *     podeEnfileirar() false nos modos de treino (repetir/shadowing/ditado): a fila à frente fica desligada   (padrão: true)
 *
 *   motor.falar(texto, idioma, { aoProgresso(ci, len), proxima() }) -> Promise<'end' | 'cancel' | 'error' | 'restart'>
 *   motor.cancelar()     para tudo e limpa a fila
 *   motor.reiniciar()    pede ao motor para recomeçar a frase atual (trocou velocidade/voz): a fala em curso termina com 'restart'
 *   motor.ativa(idioma)  sempre true (o contrato com a voz neural; esta é a voz de reserva)
 *
 * O que o motor garante (comportamentos 2, 3, 4 e 6 do doc 10):
 *   · fila à frente: com motor que informa `speaking`/`pending`, a frase seguinte entra na fila enquanto a atual toca (sem lacuna);
 *     se o fluxo mudou e sobrou frase enfileirada que não é a pedida, a fila é limpa;
 *   · evento de palavra da voz manda; sem ele (ou atrasado) a posição vem da ESTIMATIVA por tempo (`ritmo`), sem correr à frente do evento;
 *   · vigia contra a voz que emudece no meio e vigia de partida (o motor engoliu o speak): tenta de novo uma vez, depois pula;
 *   · a velocidade média da voz é aprendida a cada frase terminada bem, por idioma e por voz (não é guardada entre sessões: melhoria
 *     decidida para DEPOIS da paridade).
 */
App.define('voz-navegador', ['ritmo', 'vozes'], function (deps) {
    'use strict';
    const R = deps.ritmo, V = deps.vozes;

    function criar(o) {
        o = o || {};
        const synth = o.synth, Utterance = o.Utterance;
        if (!synth || !Utterance) throw new Error('voz-navegador: faltam synth e Utterance');
        const rel = o.relogio || { agora: () => performance.now(), setInterval: (f, t) => setInterval(f, t), clearInterval: (i) => clearInterval(i), setTimeout: (f, t) => setTimeout(f, t), clearTimeout: (i) => clearTimeout(i) };
        const escolherVoz = o.voz || ((idioma) => V.escolher(idioma, '', synth.getVoices()));
        const velocidade = o.velocidade || (() => 1);
        const podeEnfileirar = o.podeEnfileirar || (() => true);
        const tabela = R.novaTabela();
        let pre = null;                  // frase já enfileirada no motor (fala criada, com ganchos ainda sem dono)
        let reiniciando = false;         // pediram para recomeçar a frase atual
        let chaveVigia = '';             // frase que a vigia de partida já tentou de novo (não repete sem fim)

        // Uma fala com ganchos (começou, palavra, terminou) que podem ser ligados DEPOIS de criada: é isso que permite enfileirar a frase
        // seguinte enquanto a atual ainda toca (sem a lacuna entre frases).
        function novaFala(texto, idioma, taxa) {
            const u = new Utterance(texto), v = escolherVoz(idioma);
            u.lang = V.TAG[idioma]; u.rate = taxa; if (v) { u.voice = v; u.lang = v.lang; }
            const h = { u, v, text: texto, lang: idioma, rate: taxa, started: false, t0: 0, ended: null, onstart: null, onboundary: null, onend: null };
            u.onstart = () => { h.started = true; h.t0 = rel.agora(); if (h.onstart) h.onstart(); };
            u.onboundary = (e) => { if (h.onboundary) h.onboundary(e); };
            u.onend = () => { h.ended = 'end'; if (h.onend) h.onend('end'); };
            u.onerror = (e) => { h.ended = e && (e.error === 'canceled' || e.error === 'interrupted') ? 'cancel' : 'error'; if (h.onend) h.onend(h.ended); };
            return h;
        }
        // só com motor que informa a fila (speaking/pending) e fora dos modos de treino
        const filaLivre = () => synth.speaking === true && synth.pending === false && podeEnfileirar();

        function falar(texto, idioma, opc) {
            opc = opc || {};
            const aoProgresso = opc.aoProgresso, proxima = opc.proxima;
            return new Promise((resolve) => {
                const taxa = velocidade();
                let h = pre && pre.text === texto && pre.lang === idioma && pre.rate === taxa ? pre : null;
                if (pre && !h) synth.cancel();                          // sobrou frase enfileirada que não é esta (o fluxo mudou): limpa a fila
                pre = null;                                              // a frase já estava na fila do motor: só assume os ganchos
                const nova = !h; if (!h) h = novaFala(texto, idioma, taxa);
                const v = h.v;
                let resolvida = false, t0 = 0, temEvento = false, tic = null, vigia = null;
                let ultimoEv = 0, ultimoCi = 0, distMedia = 6, dtMedio = 0;      // eventos de palavra: instante, posição, distância média (caracteres) e intervalo médio (ms)
                const nomeVoz = v ? v.name : '', cps = tabela.cpsDe(idioma, nomeVoz), m = R.modelo(texto);
                const acabou = (r) => {
                    if (resolvida) return; resolvida = true; rel.clearInterval(tic); rel.clearTimeout(vigia);
                    if (r === 'end') chaveVigia = '';
                    if (r === 'end' && t0) tabela.aprender(idioma, nomeVoz, m, cps, (rel.agora() - t0) / 1000, taxa);
                    if (reiniciando) { reiniciando = false; resolve('restart'); } else resolve(r);
                };
                const comecar = () => {
                    t0 = h.t0 || rel.agora();
                    tic = rel.setInterval(() => {      // segue pelo tempo estimado: sozinho sem evento de palavra; com evento, só cobre o que ele atrasou
                        const agora = rel.agora(), el = (agora - t0) / 1000;
                        // vigia: a voz começou e emudeceu (voz de rede que morre no meio): cancela e a leitura segue para a frase seguinte
                        if (agora - t0 > (m.total / (cps * taxa) * 2.2 + 6) * 1000 && agora - (ultimoEv || t0) > 6000) { pre = null; synth.cancel(); return; }
                        if (!aoProgresso) return;
                        let ci = R.posicaoEm(m, el, cps, taxa);
                        if (temEvento) {
                            if (agora - ultimoEv <= Math.max(350, dtMedio * 1.6)) return;    // o evento da voz está em dia: ele manda, a estimativa não corre à frente
                            ci = Math.min(ci, ultimoCi + Math.max(8, Math.round(distMedia * 1.2)));
                            if (ci <= ultimoCi) return;
                        }
                        aoProgresso(ci, texto.length);
                    }, 60);
                    if (proxima && !pre && filaLivre()) {                  // buffer: a próxima frase entra na fila agora e o motor a fala sem lacuna
                        const nx = proxima();
                        if (nx) { pre = novaFala(nx.text, nx.lang, taxa); synth.speak(pre.u); }
                    }
                };
                h.onstart = comecar;
                h.onboundary = (e) => {
                    if (e && e.name && e.name !== 'word') return;
                    const agora = rel.agora(), ci = (e && e.charIndex) || 0;
                    if (temEvento) { dtMedio = dtMedio ? dtMedio * 0.7 + (agora - ultimoEv) * 0.3 : agora - ultimoEv; if (ci > ultimoCi) distMedia = distMedia * 0.7 + (ci - ultimoCi) * 0.3; }
                    temEvento = true; ultimoEv = agora; ultimoCi = Math.max(ultimoCi, ci);
                    if (aoProgresso) aoProgresso(ci, texto.length);
                };
                // vigia de partida: o motor engoliu o speak() (ou a voz não carregou): tenta a mesma frase de novo uma vez; se repetir, pula
                vigia = rel.setTimeout(() => {
                    if (resolvida || h.started) return;
                    synth.cancel(); pre = null;
                    const chave = idioma + '|' + texto, denovo = chaveVigia !== chave; chaveVigia = chave;
                    acabou(denovo ? 'restart' : 'error');
                }, 7000);
                h.onend = (r) => acabou(r);
                if (h.started) comecar();
                if (h.ended) acabou(h.ended); else if (nova) synth.speak(h.u);
            });
        }
        function cancelar() { pre = null; reiniciando = false; synth.cancel(); }
        function reiniciar() { reiniciando = true; pre = null; synth.cancel(); }
        return { falar, cancelar, reiniciar, ativa: () => true, velocidadeMedia: (idioma, voz) => tabela.cpsDe(idioma, voz), tipo: 'navegador' };
    }
    return { criar };
});
