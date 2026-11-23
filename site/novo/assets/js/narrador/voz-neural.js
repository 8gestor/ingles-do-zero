/*
 * voz-neural.js — voz NEURAL local (Piper) atrás do MESMO contrato do motor do navegador (R2.3; docs/10-r2-narrador.md, seção 3).
 * Sem DOM. Port fiel do núcleo de síntese e reprodução de `ingles-voz.js` de hoje (sessões, fila única, cache, reprodução, queda).
 * A interface de baixar/ativar/remover (painel) NÃO está aqui: é tela de configuração (R3); este módulo só LÊ as preferências
 * (`dd-ingles-neural`, mesmo formato de hoje) e fala.
 *
 *   criarNeural({ preferencias, fabrica, Audio, relogio, velocidade, urlDe, aoFalhar }) -> motor
 *     preferencias()  { en:{on,voice}, pt:{on,voice}, ready:{ [voz]: true } }      (padrão: lê `dd-ingles-neural` do armazém)
 *     fabrica()       Promise<{ stored(), TtsSession:{ create({voiceId}) -> {predict(texto) -> Blob} } }>   (a biblioteca Piper)
 *                     (padrão: window.DD_NEURAL_FACTORY, senão importa assets/vendor/piper/piper-tts-web.js; só quando uma frase é falada)
 *     Audio           construtor como `Audio`;  relogio { setInterval, clearInterval };  urlDe(blob) / revogar(url)
 *     aoFalhar(idioma, erro)   chamado quando a voz neural cai nesta sessão (a tela avisa o aluno)
 *   motor.ativa(idioma)  ligada + modelo baixado + não falhou nesta sessão
 *   motor.falar(texto, idioma, {aoProgresso}) -> 'end' | 'cancel' | 'restart' | 'fallback'   ('fallback' = use a voz do navegador)
 *   motor.cancelar() · motor.reiniciar() · motor.preparar(texto, idioma)  (sintetiza à frente, sem tocar)
 *
 *   compor({ neural, navegador }) -> voz   o contrato que o Narrador usa: neural quando ativa e funcionando; senão (ou se cair) navegador.
 *
 * Privacidade: o texto NUNCA sai do aparelho (a síntese roda local); só os arquivos do modelo/WASM vêm da internet, e só no download.
 */
App.define('voz-neural', ['ritmo', 'armazem'], function (deps) {
    'use strict';
    const R = deps.ritmo, ls = deps.armazem.ls;
    const CHAVE = 'dd-ingles-neural';
    const VOZES = { en: 'en_US-lessac-medium', pt: 'pt_BR-faber-medium' };

    function preferenciasDoArmazem() {
        const p = { en: { on: false, voice: VOZES.en }, pt: { on: false, voice: VOZES.pt }, ready: {} };
        const s = ls.get(CHAVE, null);
        if (s && typeof s === 'object') return Object.assign(p, s, { en: Object.assign(p.en, s.en), pt: Object.assign(p.pt, s.pt), ready: s.ready || {} });
        return p;
    }
    function fabricaPadrao() {
        if (window.DD_NEURAL_FACTORY) return Promise.resolve(window.DD_NEURAL_FACTORY());
        return import(new URL('../assets/vendor/piper/piper-tts-web.js', location.href).href);
    }

    function criarNeural(o) {
        o = o || {};
        const prefs = o.preferencias || preferenciasDoArmazem, fabrica = o.fabrica || fabricaPadrao;
        const AudioCtor = o.Audio || window.Audio, velocidade = o.velocidade || (() => 1);
        const rel = o.relogio || { setInterval: (f, t) => setInterval(f, t), clearInterval: (i) => clearInterval(i) };
        const urlDe = o.urlDe || ((b) => URL.createObjectURL(b)), revogar = o.revogar || ((u) => URL.revokeObjectURL(u));
        const aoFalhar = o.aoFalhar || (() => {});
        const falhou = {};                                        // idioma desligado NESTA sessão por falha
        const vozDe = (idioma) => prefs()[idioma].voice;
        const suportado = () => !!window.DD_NEURAL_FACTORY || o.suportado === true || (typeof WebAssembly === 'object' && !!(navigator.storage && navigator.storage.getDirectory));
        function ativa(idioma) { const p = prefs(); return !!(p[idioma] && p[idioma].on && p.ready[vozDe(idioma)] && !falhou[idioma] && suportado()); }

        let lib = null, libP = null; const sessoes = {};
        function carregarLib() {
            if (lib) return Promise.resolve(lib);
            if (!libP) libP = Promise.resolve().then(fabrica).then((m) => { lib = m; return m; }).catch((e) => { libP = null; throw e; });
            return libP;
        }
        function sessao(voz) {
            if (!sessoes[voz]) {
                sessoes[voz] = carregarLib().then(async (m) => {
                    const guardadas = await m.stored();       // modelo apagado do navegador? não baixar escondido: avisar
                    if (guardadas.indexOf(voz) < 0) throw new Error('modelo ausente');
                    return m.TtsSession.create({ voiceId: voz });
                }).catch((e) => { delete sessoes[voz]; throw e; });
            }
            return sessoes[voz];
        }
        // fila única (um modelo por vez) + cache das últimas 30 frases
        let cadeia = Promise.resolve(); const cache = new Map();
        function sintetizar(texto, idioma) {
            const k = vozDe(idioma) + '|' + texto;
            if (cache.has(k)) return cache.get(k);
            const p = cadeia.then(async () => { const s = await sessao(vozDe(idioma)); return urlDe(await s.predict(texto)); });
            cadeia = p.catch(() => {});
            cache.set(k, p);
            p.catch(() => cache.delete(k));
            if (cache.size > 30) { const velha = cache.keys().next().value, vp = cache.get(velha); cache.delete(velha); vp.then((u) => revogar(u)).catch(() => {}); }
            return p;
        }
        function preparar(texto, idioma) { if (ativa(idioma) && /\p{L}/u.test(texto)) sintetizar(texto, idioma).catch(() => {}); }

        let atual = null, ficha = 0, reiniciando = false;
        function parar() { ficha++; if (atual) { const c = atual; atual = null; c.a.pause(); rel.clearInterval(c.timer); c.res('cancel'); } }
        function falhar(idioma, e) { falhou[idioma] = true; aoFalhar(idioma, e); }
        const final = (r) => (reiniciando ? (reiniciando = false, 'restart') : r);

        async function falar(texto, idioma, opc) {
            const aoProgresso = (opc || {}).aoProgresso, minha = ++ficha;
            let url;
            try { url = await sintetizar(texto, idioma); } catch (e) { falhar(idioma, e); return 'fallback'; }
            if (minha !== ficha) return final('cancel');
            return new Promise((res) => {
                const a = new AudioCtor(url);
                a.playbackRate = velocidade(); a.preservesPitch = true;
                const c = { a, res: (r) => res(final(r)), timer: 0 };
                atual = c;
                const fim = (r) => { rel.clearInterval(c.timer); if (atual === c) atual = null; res(final(r)); };
                const m = R.modelo(texto);          // posição no texto = fração do áudio sobre o texto PONDERADO (pausas pesam mais)
                a.onplay = () => {
                    rel.clearInterval(c.timer);
                    c.timer = rel.setInterval(() => {
                        if (!aoProgresso || !a.duration) return;
                        aoProgresso(R.caractereNoAlvo(m, Math.min(1, a.currentTime / a.duration) * m.total), texto.length);
                    }, 40);
                };
                a.onended = () => fim('end');
                a.onerror = () => { falhar(idioma, new Error('áudio')); fim('fallback'); };
                const t = a.play(); if (t && t.catch) t.catch(() => fim('fallback'));
            });
        }
        function cancelar() { reiniciando = false; parar(); }
        function reiniciar() { reiniciando = true; parar(); }
        return { ativa, falar, cancelar, reiniciar, preparar, tipo: 'neural', falhou: (i) => !!falhou[i] };
    }

    // Contrato do Narrador: neural quando ativa; se ela não puder (ou cair), a voz do navegador fala a mesma frase.
    function compor(c) {
        const neural = c.neural, nav = c.navegador;
        let ativo = null;                                      // quem está falando agora (só ele recebe o pedido de reinício)
        return {
            async falar(texto, idioma, opc) {
                if (neural && neural.ativa(idioma)) {
                    ativo = neural; const r = await neural.falar(texto, idioma, opc);
                    if (r !== 'fallback') return r;
                }
                ativo = nav; return nav.falar(texto, idioma, opc);
            },
            cancelar() { if (neural) neural.cancelar(); nav.cancelar(); },
            reiniciar() { (ativo || nav).reiniciar(); },
            preparar(texto, idioma) { if (neural) neural.preparar(texto, idioma); },
            tipo: 'composta'
        };
    }
    return { criarNeural, compor, CHAVE, VOZES };
});
