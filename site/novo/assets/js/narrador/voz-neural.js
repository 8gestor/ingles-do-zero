/*
 * voz-neural.js — adaptador da voz NEURAL LOCAL (Piper) atrás do contrato de Voz (R2.3; docs/10-r2-narrador.md, seção 3). Sem DOM, sem tela.
 *
 * Port do MOTOR do `ingles-voz.js` de hoje (linhas 56–123): carrega a biblioteca só quando a voz vai falar, sintetiza uma frase por vez numa fila
 * única, guarda as últimas frases em cache, toca o áudio e informa a posição do texto pela fração do áudio tocado. A tela de ativar/baixar a voz
 * (painel, confirmação do download, preferências no localStorage) NÃO está aqui: virá com as telas e entrega a este módulo as `prefs`.
 * O texto lido nunca sai do aparelho: só os arquivos do modelo e do motor vêm da internet (e só depois que o aluno confirma, na tela).
 *
 * Contrato da Voz (o mesmo de `voz-navegador.js`):
 *   ativa(idioma) → a voz neural vale agora? · falar(texto, idioma, { velocidade, aoProgresso }) → Promise<'end' | 'cancel' | 'fallback'>
 *   cancelar() · preparar(texto, idioma)  (sintetiza antes, para a frase seguinte soar sem pausa)
 * 'fallback' = não deu para falar (biblioteca, modelo ou áudio falharam): quem chamou usa a voz do navegador. Falhou uma vez, fica desligada
 * naquele idioma até a página recarregar (como hoje), e `aoFalhar(idioma, erro)` avisa a tela.
 *
 * Tudo que depende do mundo é injetável: `criar({ biblioteca, prefs, suportado, Audio, URL, setInterval, clearInterval, aoFalhar })`.
 *   biblioteca() → Promise<{ stored(), TtsSession: { create({ voiceId }) → { predict(texto) → Blob } } }>
 *   prefs: { ativa(idioma), voz(idioma) → id do modelo, pronta(id) → baixado?, ausente(id) → o modelo sumiu do navegador }
 */
App.define('voz-neural', ['ritmo'], function (deps) {
    'use strict';
    const R = deps.ritmo;
    const CACHE_MAX = 30;                 // frases sintetizadas guardadas (as mais antigas saem e liberam o áudio)
    const PASSO_MS = 40;                  // de quanto em quanto tempo informa a posição

    function criar(op) {
        const prefs = op.prefs, carregar = op.biblioteca;
        const suportado = op.suportado || (() => typeof WebAssembly === 'object' && !!(navigator.storage && navigator.storage.getDirectory));
        const Som = op.Audio || (typeof Audio !== 'undefined' ? Audio : null), Url = op.URL || (typeof URL !== 'undefined' ? URL : null);
        const setI = op.setInterval || ((f, ms) => setInterval(f, ms)), clrI = op.clearInterval || ((t) => clearInterval(t));
        const aoFalhar = op.aoFalhar || (() => {});
        const falhou = {};                // desligada nesta sessão por falha, por idioma
        let lib = null, libP = null;
        const sessoes = {};
        let fila = Promise.resolve();     // um modelo por vez
        const cache = new Map();
        let atual = null, ficha = 0;

        const ativa = (idioma) => !!(prefs.ativa(idioma) && prefs.pronta(prefs.voz(idioma)) && !falhou[idioma] && suportado());

        function carregarBiblioteca() {
            if (lib) return Promise.resolve(lib);
            if (!libP) libP = Promise.resolve(carregar()).then((m) => { lib = m; return m; }).catch((e) => { libP = null; throw e; });
            return libP;
        }
        function sessao(vozId) {
            if (!sessoes[vozId]) {
                sessoes[vozId] = carregarBiblioteca().then(async (m) => {
                    if (typeof m.stored === 'function') {              // modelo apagado do navegador? não baixar escondido: avisar
                        const guardados = await m.stored();
                        if (guardados.indexOf(vozId) < 0) { prefs.ausente(vozId); throw new Error('modelo ausente'); }
                    }
                    return m.TtsSession.create({ voiceId: vozId });
                }).catch((e) => { delete sessoes[vozId]; throw e; });
            }
            return sessoes[vozId];
        }
        // fila única + cache das últimas frases
        function sintetizar(texto, idioma) {
            const k = prefs.voz(idioma) + '|' + texto;
            if (cache.has(k)) return cache.get(k);
            const p = fila.then(async () => { const s = await sessao(prefs.voz(idioma)); return Url.createObjectURL(await s.predict(texto)); });
            fila = p.catch(() => {});
            cache.set(k, p);
            p.catch(() => cache.delete(k));
            if (cache.size > CACHE_MAX) { const velha = cache.keys().next().value, vp = cache.get(velha); cache.delete(velha); vp.then((u) => Url.revokeObjectURL(u)).catch(() => {}); }
            return p;
        }
        function preparar(texto, idioma) { if (ativa(idioma) && /\p{L}/u.test(texto || '')) sintetizar(texto, idioma).catch(() => {}); }

        function cancelar() {
            ficha++;
            if (atual) { const c = atual; atual = null; c.a.pause(); clrI(c.timer); c.fim('cancel'); }
        }
        function falhar(idioma, e) { falhou[idioma] = true; aoFalhar(idioma, e); }

        async function falar(texto, idioma, o) {
            o = o || {};
            const minha = ++ficha;
            let url;
            try { url = await sintetizar(texto, idioma); } catch (e) { falhar(idioma, e); return 'fallback'; }
            if (minha !== ficha) return 'cancel';
            return new Promise((resolve) => {
                const a = new Som(url);
                a.playbackRate = o.velocidade || 1; a.preservesPitch = true;
                const c = { a, timer: 0, fim: null };
                atual = c;
                const m = R.modelo(texto);          // posição no texto = fração do áudio sobre o texto PONDERADO (pausas da pontuação pesam mais)
                c.fim = (r) => { clrI(c.timer); if (atual === c) atual = null; resolve(r); };
                a.onplay = () => {
                    clrI(c.timer);
                    c.timer = setI(() => {
                        if (!o.aoProgresso || !a.duration) return;
                        o.aoProgresso(R.caractereNoAlvo(m, Math.min(1, a.currentTime / a.duration) * m.total), texto.length);
                    }, PASSO_MS);
                };
                a.onended = () => c.fim('end');
                a.onerror = () => { falhar(idioma, new Error('áudio')); c.fim('fallback'); };
                const t = a.play(); if (t && t.catch) t.catch(() => c.fim('fallback'));
            });
        }
        return { ativa, falar, cancelar, preparar };
    }

    return { criar };
});
