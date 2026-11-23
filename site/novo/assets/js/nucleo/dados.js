/*
 * dados.js — o PROGRESSO do aluno como um todo: ler do aparelho (snapshot), gravar o que foi mesclado (apply), exportar e importar backup.
 *
 * Fonte dos dados (enquanto os dois apps convivem): as MESMAS do app de hoje, para um enxergar o que o outro grava:
 *   localStorage  dd-ingles-log (estatísticas por dia) · dd-ingles-dia-hist · dd-ingles-semana-hist · dd-ingles-escrita
 *   IndexedDB     dd-ingles → vocab (cartões) e meta (posição e palavras ouvidas de cada livro)
 *   localStorage  dd-ingles-pend-docs: posição/palavras de livros que vieram num backup mas ainda não estão neste aparelho
 * O TEXTO dos livros nunca entra no snapshot, no backup nem na nuvem.
 *
 * Formato do backup (v1, igual ao do app de hoje): { app: 'ingles-progresso', v: 1, exportedAt, data: snapshot }.
 * Importar = mesclar com o que já existe, nunca apagar (regras em mescla.js).
 */
App.define('dados', ['eventos', 'armazem', 'mescla'], function (deps) {
    'use strict';
    const ev = deps.eventos, ar = deps.armazem, ls = ar.ls, M = deps.mescla;
    const K = { log: 'dd-ingles-log', diaHist: 'dd-ingles-dia-hist', semHist: 'dd-ingles-semana-hist', escrita: 'dd-ingles-escrita' };
    const PK = 'dd-ingles-pend-docs', DK = 'dd-sync-device';
    const jget = (k, def) => { const v = ls.get(k, def); return v == null ? def : v; };

    // código deste aparelho (texto simples, igual ao app de hoje): serve para saber de onde veio uma gravação
    function aparelho() {
        let id = ls.getRaw(DK, '');
        if (!id) { id = 'd' + Math.random().toString(36).slice(2, 10); ls.setRaw(DK, id); }
        return id;
    }

    async function snapshot() {
        const lg = await ar.legado();
        const metas = (await lg.all('meta').catch(() => [])) || [], docs = {};
        metas.forEach((m) => { docs[M.norm(m.title) + '|' + m.lang] = { title: m.title, lang: m.lang, pos: m.pos || 0, heard: m.heard || 0, words: m.words || 0, sentences: m.sentences || 0, savedAt: m.savedAt || m.lastOpened || 0 }; });
        const vocab = (await lg.all('vocab').catch(() => [])) || [];
        const pend = jget(PK, {});
        const docsAll = Object.keys(pend).length ? M.mergeDocs(pend, docs) : docs;               // o que veio de backup e ainda não tem livro aqui também vai nos próximos backups e na nuvem
        return { v: 1, at: Date.now(), device: aparelho(), log: jget(K.log, { d: {} }), diaHist: jget(K.diaHist, null), semHist: jget(K.semHist, []), escrita: jget(K.escrita, []), vocab, docs: docsAll };
    }

    // Grava o resultado de uma mescla no aparelho. `op.abertos` = ids de livros abertos agora (não mudam por baixo do leitor).
    async function apply(m, op) {
        const abertos = new Set((op && op.abertos) || []);
        if (JSON.stringify(m.log) !== JSON.stringify(jget(K.log, { d: {} }))) ls.set(K.log, m.log);
        if (m.diaHist != null && JSON.stringify(m.diaHist) !== JSON.stringify(jget(K.diaHist, null))) ls.set(K.diaHist, m.diaHist);
        if (JSON.stringify(m.semHist) !== JSON.stringify(jget(K.semHist, []))) ls.set(K.semHist, m.semHist);
        if (JSON.stringify(m.escrita) !== JSON.stringify(jget(K.escrita, []))) ls.set(K.escrita, m.escrita);
        const lg = await ar.legado();
        const have = new Map((((await lg.all('vocab').catch(() => [])) || [])).map((c) => [c.id, c]));
        for (const c of m.vocab || []) { const o = have.get(c.id); if (!o || JSON.stringify(o) !== JSON.stringify(c)) { try { await lg.put('vocab', c); } catch (e) { /* ignora */ } } }
        const metas = (await lg.all('meta').catch(() => [])) || [];
        for (const meta of metas) {
            const r = m.docs[M.norm(meta.title) + '|' + meta.lang];
            if (!r || abertos.has(meta.id)) continue;
            if ((r.savedAt || 0) > (meta.savedAt || 0) || (r.heard || 0) > (meta.heard || 0)) {
                const upd = Object.assign({}, meta, { heard: Math.max(meta.heard || 0, r.heard || 0) });
                if ((r.savedAt || 0) > (meta.savedAt || 0)) { upd.pos = r.pos; upd.savedAt = r.savedAt; }
                try { await lg.put('meta', upd); } catch (e) { /* ignora */ }
            }
        }
        ev.emit('dados-aplicados', { origem: (op && op.origem) || 'mescla' });
    }

    /* ------------------------------------------------------------ backup em arquivo */
    async function exportar() {
        return JSON.stringify({ app: M.BK_APP, v: 1, exportedAt: new Date().toISOString(), data: await snapshot() });
    }
    // Livros que entraram depois do backup recebem a posição e as palavras ouvidas guardadas; sobra só o que ainda não tem livro.
    async function aplicarPendentes(op) {
        const pend = jget(PK, {}); if (!Object.keys(pend).length) return;
        await apply(await snapshot(), { abertos: op && op.abertos, origem: 'pendentes' });
        const metas = (await (await ar.legado()).all('meta').catch(() => [])) || [], sobra = {};
        Object.keys(pend).forEach((k) => {
            const m = metas.find((x) => M.norm(x.title) + '|' + x.lang === k), r = pend[k];
            if (!m || (r.savedAt || 0) > (m.savedAt || 0) || (r.heard || 0) > (m.heard || 0)) sobra[k] = r;
        });
        ls.set(PK, sobra);
    }
    // Chamado pelo leitor quando um livro NOVO acaba de ser importado, ANTES de abrir: se havia posição guardada num backup, o livro abre no ponto certo.
    function aplicarPendenteAoLivro(livro) {
        try {
            const pend = jget(PK, {}), k = livro && M.norm(livro.title) + '|' + livro.lang, r = k && pend[k];
            if (!r) return false;
            livro.pos = Math.max(0, Math.min(r.pos | 0, ((livro.paras || []).length || 1) - 1)); livro.heard = Math.max(livro.heard || 0, r.heard || 0);
            delete pend[k]; ls.set(PK, pend); return true;
        } catch (e) { return false; }
    }
    async function importar(raw, op) {
        const inc = M.limparBackup(raw); if (!inc) throw new Error('formato');
        const antes = await snapshot();
        const mesclado = M.merge(antes, inc, { device: aparelho() });
        const lg = await ar.legado();
        const tem = new Set((((await lg.all('meta').catch(() => [])) || [])).map((m) => M.norm(m.title) + '|' + m.lang));
        const pend = jget(PK, {}); Object.keys(mesclado.docs).forEach((k) => { if (!tem.has(k)) pend[k] = mesclado.docs[k]; });
        ls.set(PK, pend);                                                  // guarda antes de aplicar: se algo falhar no meio, nada se perde
        await apply(mesclado, { abertos: op && op.abertos, origem: 'backup' });
        await aplicarPendentes(op);
        const depois = await snapshot();
        const r = { days: Object.keys(depois.log.d || {}).length - Object.keys(antes.log.d || {}).length, cards: depois.vocab.length - antes.vocab.length, books: Object.keys(inc.docs).length, daysTotal: Object.keys(depois.log.d || {}).length };
        ev.emit('dados-importados', { dias: r.days, cartoes: r.cards, livros: r.books });
        return r;
    }

    return { snapshot, apply, exportar, importar, aplicarPendentes, aplicarPendenteAoLivro, aparelho, CHAVES: Object.assign({ pendentes: PK, aparelho: DK }, K) };
});
