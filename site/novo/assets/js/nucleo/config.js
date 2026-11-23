/*
 * config.js — preferências do aluno no app novo (docs/07, seção 4.1).
 *
 * Usa a MESMA chave do app de hoje (`dd-settings`) e os mesmos nomes de campo, então tema, fonte, velocidade, idiomas e vozes
 * escolhidos num app valem no outro. Valida e limita cada valor (um valor estranho no storage nunca quebra o app) e avisa
 * `config-mudou` quando algo muda.
 */
App.define('config', ['eventos', 'armazem'], function (deps) {
    'use strict';
    const ev = deps.eventos, ls = deps.armazem.ls;
    const CHAVE = 'dd-settings';
    const TEMAS = ['paper', 'dark', 'light', 'sepia'];
    const FONTES = ['serif', 'legible', 'mono'];
    const MARGENS = ['narrow', 'medium', 'wide'];
    const ALINHA = ['left', 'justify'];
    const IDIOMAS = ['pt', 'en'];
    const PADRAO = { theme: 'paper', font: 19, face: 'serif', margin: 'medium', align: 'left', rate: 1.0, readLang: 'pt', audioLang: 'pt', voices: { pt: '', en: '' } };

    const uma = (v, lista, def) => (lista.indexOf(v) >= 0 ? v : def);
    const num = (v, min, max, def, passo) => { let n = Number(v); if (!isFinite(n)) return def; n = Math.max(min, Math.min(max, n)); return passo ? Math.round(n / passo) * passo : n; };
    // cada chave tem a sua regra de "limpeza"
    const LIMPA = {
        theme: (v) => uma(v, TEMAS, PADRAO.theme),
        font: (v) => Math.round(num(v, 14, 28, PADRAO.font)),
        face: (v) => uma(v, FONTES, PADRAO.face),
        margin: (v) => uma(v, MARGENS, PADRAO.margin),
        align: (v) => uma(v, ALINHA, PADRAO.align),
        rate: (v) => Math.round(num(v, 0.1, 3, PADRAO.rate) * 10) / 10,         // 0,1× a 3×, de 0,1 em 0,1
        readLang: (v) => uma(v, IDIOMAS, PADRAO.readLang),
        audioLang: (v) => uma(v, IDIOMAS, PADRAO.audioLang),
        voices: (v) => ({ pt: String((v && v.pt) || ''), en: String((v && v.en) || '') })
    };

    function carregar() {
        const bruto = ls.get(CHAVE, {}), out = {};
        Object.keys(PADRAO).forEach((k) => { out[k] = LIMPA[k](bruto && bruto[k] !== undefined ? bruto[k] : PADRAO[k]); });
        return out;
    }
    let atual = carregar();

    function get(k) { if (!(k in PADRAO)) throw new Error('config.get: chave desconhecida: ' + k); return k === 'voices' ? { pt: atual.voices.pt, en: atual.voices.en } : atual[k]; }
    function set(k, v) {
        if (!(k in PADRAO)) throw new Error('config.set: chave desconhecida: ' + k);
        const limpo = LIMPA[k](v), antes = atual[k];
        if (JSON.stringify(limpo) === JSON.stringify(antes)) return limpo;
        atual[k] = limpo;
        // grava por cima do que já existe (preserva campos que só o app antigo conhece)
        const bruto = ls.get(CHAVE, {}); ls.set(CHAVE, Object.assign({}, bruto && typeof bruto === 'object' ? bruto : {}, { [k]: limpo }));
        ev.emit('config-mudou', { chave: k, valor: limpo, antes });
        return limpo;
    }
    function tudo() { return JSON.parse(JSON.stringify(atual)); }
    function recarregar() { atual = carregar(); return tudo(); }          // se outra aba/app mudou o storage

    return { get, set, tudo, recarregar, PADRAO: JSON.parse(JSON.stringify(PADRAO)), TEMAS, FONTES, MARGENS, ALINHA, IDIOMAS };
});
