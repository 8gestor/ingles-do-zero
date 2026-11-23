/*
 * registro.js — registro de ESTUDO por dia e espelho da leitura à prova de fechamento da aba (docs/07; áreas S e N da matriz de paridade).
 *
 * Registro (`dd-ingles-log`, mesmo formato do app de hoje): um item por dia { sec, heard, saved, rev, dict, rd, ls }.
 *   · EVENTOS (palavras ouvidas, salvas, revisões, ditados) são gravados NA HORA: se a aba cair, nada se perde.
 *   · TEMPOS (sec = estudando, rd = lendo, ls = ouvindo) entram a cada segundo e são gravados a cada 2 s (perda máxima ≈ 2 s)
 *     e sempre que a aba esconde, fecha ou é suspensa (pagehide, beforeunload, visibilitychange).
 *   · Cada gravação LÊ o que está no storage, soma o pendente e grava: assim uma mesclagem (backup/nuvem) feita no meio NUNCA é
 *     sobrescrita por um valor antigo guardado na memória (o app de hoje tem essa fragilidade; aqui não).
 *
 * Espelho (`dd-ingles-sessao` = { id, pos, heard, t }): o IndexedDB grava de forma assíncrona e pode ser cortado se a aba fechar; o
 * localStorage grava na hora. Ao reabrir o livro vale o mais recente entre o banco (meta.savedAt) e o espelho.
 *
 * Tempo de estudo só conta com livro aberto, aba visível e atividade recente (ou narração tocando):
 *   estudando = narração tocando OU atividade nos últimos 60 s · lendo = atividade nos últimos 30 s · ouvindo = narração tocando
 */
App.define('registro', ['eventos', 'armazem'], function (deps) {
    'use strict';
    const ev = deps.eventos, ls = deps.armazem.ls;
    const KEY = 'dd-ingles-log', MIRROR = 'dd-ingles-sessao';
    const TEMPOS = { sec: 1, rd: 1, ls: 1 };
    const pend = {};                                     // dia -> { campo: n } ainda não gravado
    let sujo = false;

    const chaveDia = (d) => { const x = d || new Date(); return x.getFullYear() + '-' + String(x.getMonth() + 1).padStart(2, '0') + '-' + String(x.getDate()).padStart(2, '0'); };
    const vazio = () => ({ sec: 0, heard: 0, saved: 0, rev: 0, dict: 0, rd: 0, ls: 0 });
    const lerLog = () => { const s = ls.get(KEY, null); return s && s.d ? s : { d: {} }; };

    function salvar() {
        if (!sujo) return false;
        const log = lerLog();
        Object.keys(pend).forEach((dia) => {
            const r = log.d[dia] || (log.d[dia] = vazio());
            Object.keys(pend[dia]).forEach((f) => { r[f] = (r[f] || 0) + pend[dia][f]; });
            delete pend[dia];
        });
        sujo = false; ls.set(KEY, log); return true;
    }
    function somar(campo, n, dia) {
        const k = dia || chaveDia();
        (pend[k] || (pend[k] = {}))[campo] = ((pend[k] || {})[campo] || 0) + n; sujo = true;
        if (!TEMPOS[campo]) salvar();                     // evento: grava na hora; tempo: junta e grava a cada 2 s
    }
    // visão atual = o que está gravado + o que ainda está pendente
    function ler() {
        const log = JSON.parse(JSON.stringify(lerLog()));
        Object.keys(pend).forEach((dia) => { const r = log.d[dia] || (log.d[dia] = vazio()); Object.keys(pend[dia]).forEach((f) => { r[f] = (r[f] || 0) + pend[dia][f]; }); });
        return log;
    }
    const ativo = (r) => !!r && (r.sec >= 30 || r.heard > 0 || r.rev > 0 || r.saved > 0 || r.dict > 0);
    function sequencia(hoje) {                           // dias seguidos com estudo; hoje ainda vazio não quebra a sequência
        const log = ler(); let n = 0; const d = hoje ? new Date(hoje) : new Date();
        if (!ativo(log.d[chaveDia(d)])) d.setDate(d.getDate() - 1);
        while (ativo(log.d[chaveDia(d)])) { n++; d.setDate(d.getDate() - 1); }
        return n;
    }

    /* ------------------------------------------------------------ tempo de estudo */
    let ultimaAtividade = 0, fonte = null, relogios = [];
    function atividade(agora) { ultimaAtividade = agora || Date.now(); }
    // fonte() devolve { aberto, ouvindo } (o leitor informa; ainda não existe na R1)
    function tick(agora) {
        const f = fonte && fonte(); agora = agora || Date.now();
        if (!f || !f.aberto || document.visibilityState !== 'visible') return;
        if (f.ouvindo || agora - ultimaAtividade < 60000) somar('sec', 1);
        if (f.ouvindo) somar('ls', 1);
        if (agora - ultimaAtividade < 30000) somar('rd', 1);
    }
    function iniciarRelogio(fn) {
        fonte = fn; pararRelogio();
        relogios.push(setInterval(() => tick(), 1000), setInterval(salvar, 2000));
    }
    function pararRelogio() { relogios.forEach(clearInterval); relogios = []; }
    ['pointerdown', 'keydown', 'wheel', 'touchstart', 'scroll'].forEach((e) => window.addEventListener(e, () => atividade(), { passive: true }));
    window.addEventListener('pagehide', salvar); window.addEventListener('beforeunload', salvar); document.addEventListener('visibilitychange', salvar);

    ev.on('frase-ouvida', (e) => somar('heard', (e && e.palavras) || 0));
    ev.on('palavra-salva', () => somar('saved', 1));
    ev.on('revisao-feita', () => somar('rev', 1));
    ev.on('ditado-feito', () => somar('dict', 1));

    /* ------------------------------------------------------------ espelho da leitura em andamento */
    const espelho = {
        gravar(livro) {
            if (!livro) return false;
            return ls.set(MIRROR, { id: livro.id, pos: livro.pos || 0, heard: livro.heard || 0, t: Date.now() });
        },
        // meta = o que o banco tem do livro; nParas = quantos parágrafos o livro tem. Devolve a posição e as palavras a usar.
        melhor(meta, nParas) {
            let pos = meta.pos || 0, heard = meta.heard || 0, restaurado = false;
            const s = ls.get(MIRROR, null);
            if (s && s.id === meta.id && s.t > (meta.savedAt || 0)) {
                pos = Math.max(0, Math.min(s.pos | 0, Math.max(0, (nParas || 1) - 1))); heard = Math.max(heard, s.heard || 0);
                restaurado = pos !== (meta.pos || 0) || heard !== (meta.heard || 0);
            }
            return { pos, heard, restaurado };
        },
        ler: () => ls.get(MIRROR, null),
        limpar: () => ls.remove(MIRROR)
    };

    return { somar, salvar, ler, sequencia, chaveDia, atividade, tick, iniciarRelogio, pararRelogio, espelho, KEY, MIRROR };
});
