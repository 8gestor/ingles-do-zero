/*
 * armazem.js — armazenamento local do app novo (docs/07, seções 4.2 e 4.8). Dois bancos, regras diferentes:
 *
 *  1. `legado()`  = o banco `dd-ingles` do app de hoje (stores meta, docs, tr, vocab). O app antigo o abre FIXO na versão 2
 *                   (`indexedDB.open('dd-ingles', 2)`). Se este código subisse a versão, o app de hoje PARARIA de abrir o banco
 *                   (VersionError). Por isso: aqui o banco antigo é aberto na versão 2 com o mesmo desenho e NUNCA é migrado,
 *                   enquanto os dois apps convivem. A migração do banco antigo é decidida só na fase R8 (troca).
 *  2. `novo()`    = `dd-ingles-novo`, com as entidades novas (registro, cartões cloze, escrita, posições, plano). Este tem migração
 *                   de versão de verdade: ANTES de subir a versão, tudo é copiado para `dd-ingles-novo-backup` (as 3 últimas cópias
 *                   ficam guardadas) e, se a cópia não for possível, a migração é CANCELADA. `restaurarCopia` desfaz.
 *
 * Também: localStorage "seguro" (cai para a memória se o navegador bloquear) e pedido de armazenamento persistente.
 * Nada daqui depende de rede nem de conta.
 */
App.define('armazem', ['eventos'], function (deps) {
    'use strict';
    const ev = deps.eventos;

    /* ------------------------------------------------------------ localStorage seguro */
    const mem = {};
    let lsOk = true;
    try { localStorage.setItem('__dd_t', '1'); localStorage.removeItem('__dd_t'); } catch (e) { lsOk = false; }
    const ls = {
        disponivel: () => lsOk,
        get(k, def) {
            try { const raw = lsOk ? localStorage.getItem(k) : (k in mem ? mem[k] : null); if (raw == null) return def; return JSON.parse(raw); } catch (e) { return def; }
        },
        set(k, v) {
            const raw = JSON.stringify(v);
            try { if (lsOk) localStorage.setItem(k, raw); else mem[k] = raw; return true; } catch (e) { mem[k] = raw; return false; }
        },
        remove(k) { try { if (lsOk) localStorage.removeItem(k); } catch (e) { /* ignora */ } delete mem[k]; }
    };

    /* ------------------------------------------------------------ IndexedDB: peças básicas */
    const req = (r) => new Promise((ok, err) => { r.onsuccess = () => ok(r.result); r.onerror = () => err(r.error); });
    const fimTx = (tx) => new Promise((ok, err) => { tx.oncomplete = () => ok(); tx.onerror = () => err(tx.error); tx.onabort = () => err(tx.error || new Error('transação cancelada')); });

    function abrirRaw(nome, versao, sobe) {
        return new Promise((ok, err) => {
            if (!window.indexedDB) return err(new Error('sem IndexedDB'));
            const rq = versao ? indexedDB.open(nome, versao) : indexedDB.open(nome);
            if (sobe) rq.onupgradeneeded = (e) => { try { sobe(rq.result, rq.transaction, e.oldVersion); } catch (x) { try { rq.transaction.abort(); } catch (y) { /* ignora */ } err(x); } };
            rq.onsuccess = () => { const db = rq.result; db.onversionchange = () => db.close(); ok(db); };
            rq.onerror = () => err(rq.error);
        });
    }

    // Versão atual de um banco, ou 0 se ele não existe (sem criar nada: abre sem versão e cancela se for novo).
    function lerVersao(nome) {
        return new Promise((ok) => {
            if (!window.indexedDB) return ok(0);
            const rq = indexedDB.open(nome);
            rq.onupgradeneeded = () => { try { rq.transaction.abort(); } catch (e) { /* ignora */ } };
            rq.onsuccess = () => { const v = rq.result.version; rq.result.close(); ok(v); };
            rq.onerror = () => ok(0);
        });
    }

    // Copia TUDO de um banco aberto: { store: { keyPath, autoIncrement, itens: [{ k, v }] } }
    async function despejar(db) {
        const out = {}, nomes = Array.from(db.objectStoreNames);
        if (!nomes.length) return out;
        const tx = db.transaction(nomes, 'readonly');
        for (const n of nomes) {
            const st = tx.objectStore(n);
            const [vals, keys] = await Promise.all([req(st.getAll()), req(st.getAllKeys())]);
            out[n] = { keyPath: st.keyPath, autoIncrement: st.autoIncrement, itens: vals.map((v, i) => ({ k: keys[i], v })) };
        }
        return out;
    }

    function envolver(db, nome) {
        const rw = (s) => db.transaction(s, 'readwrite');
        return {
            nome, versao: db.version,
            stores: () => Array.from(db.objectStoreNames),
            async get(s, k) { return req(db.transaction(s, 'readonly').objectStore(s).get(k)); },
            async all(s) { return req(db.transaction(s, 'readonly').objectStore(s).getAll()); },
            async contar(s) { return req(db.transaction(s, 'readonly').objectStore(s).count()); },
            async put(s, v, k) { const tx = rw(s), st = tx.objectStore(s); if (k !== undefined) st.put(v, k); else st.put(v); return fimTx(tx); },
            async del(s, k) { const tx = rw(s); tx.objectStore(s).delete(k); return fimTx(tx); },
            async limpar(s) { const tx = rw(s); tx.objectStore(s).clear(); return fimTx(tx); },
            tudo: () => despejar(db),
            fechar: () => db.close()
        };
    }

    /* ------------------------------------------------------------ cópias de segurança (antes de migrar) */
    const COPIAS = 3;
    const nomeCopia = (banco) => banco + '-backup';
    function abrirCopias(banco) {
        return abrirRaw(nomeCopia(banco), 1, (d) => { if (!Array.from(d.objectStoreNames).includes('copias')) d.createObjectStore('copias', { keyPath: 'id' }); });
    }
    async function gravarCopia(banco, de, dados) {
        const cdb = await abrirCopias(banco);
        try {
            const id = Date.now().toString(36) + Math.random().toString(36).slice(2, 6);
            let tx = cdb.transaction('copias', 'readwrite'); tx.objectStore('copias').put({ id, banco, de, em: Date.now(), dados }); await fimTx(tx);
            const todas = await req(cdb.transaction('copias', 'readonly').objectStore('copias').getAll());
            todas.sort((a, b) => b.em - a.em);
            tx = cdb.transaction('copias', 'readwrite'); todas.slice(COPIAS).forEach((c) => tx.objectStore('copias').delete(c.id)); await fimTx(tx);
            return id;
        } finally { cdb.close(); }
    }
    async function copias(banco) {
        if (!(await lerVersao(nomeCopia(banco)))) return [];
        const cdb = await abrirCopias(banco);
        try {
            const todas = await req(cdb.transaction('copias', 'readonly').objectStore('copias').getAll());
            return todas.sort((a, b) => b.em - a.em).map((c) => ({ id: c.id, de: c.de, em: c.em, stores: Object.keys(c.dados), itens: Object.keys(c.dados).reduce((n, s) => n + c.dados[s].itens.length, 0) }));
        } finally { cdb.close(); }
    }
    // Volta o banco ao conteúdo de uma cópia (apaga o que há hoje em cada store da cópia e regrava). Devolve quantos itens voltaram.
    async function restaurarCopia(banco, id) {
        const cdb = await abrirCopias(banco); let c;
        try { c = await req(cdb.transaction('copias', 'readonly').objectStore('copias').get(id)); } finally { cdb.close(); }
        if (!c) throw new Error('cópia não encontrada: ' + id);
        const db = await abrirRaw(banco);
        let n = 0;
        try {
            const nomes = Object.keys(c.dados).filter((s) => db.objectStoreNames.contains(s));
            if (!nomes.length) return 0;
            const tx = db.transaction(nomes, 'readwrite');
            nomes.forEach((s) => {
                const st = tx.objectStore(s); st.clear();
                c.dados[s].itens.forEach((it) => { if (st.keyPath != null) st.put(it.v); else st.put(it.v, it.k); n++; });
            });
            await fimTx(tx);
        } finally { db.close(); }
        return n;
    }

    /* ------------------------------------------------------------ abrir com migração e cópia automática */
    // versoes: [{ v: 1, sobe(db, tx, antiga) }, { v: 2, sobe(...) }]; cada `sobe` roda uma vez, em ordem, só se a versão for maior que a existente.
    async function abrirBanco(nome, versoes, op) {
        op = op || {};
        const lista = versoes.slice().sort((a, b) => a.v - b.v), alvo = lista[lista.length - 1].v;
        try {
            const antes = await lerVersao(nome);
            if (antes > alvo) return envolver(await abrirRaw(nome), nome);              // banco de uma versão MAIS NOVA (ex.: outro aparelho/abas): usa como está, sem tocar
            let copia = null;
            if (antes > 0 && antes < alvo && op.backup !== false) {
                const velho = await abrirRaw(nome, antes);
                try { copia = await gravarCopia(nome, antes, await despejar(velho)); }
                catch (e) { throw new Error('não foi possível guardar a cópia de segurança; migração cancelada (' + ((e && e.message) || e) + ')'); }
                finally { velho.close(); }
            }
            const db = await abrirRaw(nome, alvo, (d, tx, antiga) => { lista.forEach((s) => { if (s.v > antiga) s.sobe(d, tx, antiga); }); });
            if (antes > 0 && antes < alvo) ev.emit('armazem-migrado', { banco: nome, de: antes, para: alvo, copia });
            return envolver(db, nome);
        } catch (e) {
            ev.emit('armazem-erro', { banco: nome, erro: String((e && e.message) || e) });
            throw e;
        }
    }

    /* ------------------------------------------------------------ os dois bancos do app */
    const temStore = (d, n) => Array.from(d.objectStoreNames).includes(n);
    const BANCO_NOVO = {
        nome: 'dd-ingles-novo',
        versoes: [{
            v: 1,
            sobe(d) {
                if (!temStore(d, 'kv')) d.createObjectStore('kv');                                          // pares chave → valor (preferências extras, marcas)
                if (!temStore(d, 'registro')) d.createObjectStore('registro', { keyPath: 'dia' });          // um item por dia: tempos e contadores
                if (!temStore(d, 'escrita')) d.createObjectStore('escrita', { keyPath: 'id', autoIncrement: true });
                if (!temStore(d, 'cartoes')) d.createObjectStore('cartoes', { keyPath: 'id' });             // cartões (palavra/cloze) com repetição espaçada
                if (!temStore(d, 'posicoes')) d.createObjectStore('posicoes', { keyPath: 'chave' });        // livro+idioma → posição e palavras ouvidas
                if (!temStore(d, 'plano')) d.createObjectStore('plano', { keyPath: 'id' });                 // plano da semana e histórico
            }
        }]
    };
    let pNovo = null, pLegado = null;
    const novo = () => pNovo || (pNovo = abrirBanco(BANCO_NOVO.nome, BANCO_NOVO.versoes).catch((e) => { pNovo = null; throw e; }));
    // ATENÇÃO: versão 2 e o desenho das stores são os do app de hoje. NÃO mudar enquanto os dois apps existirem (ver o cabeçalho).
    const legado = () => pLegado || (pLegado = (async () => {
        const antes = await lerVersao('dd-ingles');
        const sobe = (d) => {
            if (!temStore(d, 'meta')) d.createObjectStore('meta', { keyPath: 'id' });
            if (!temStore(d, 'docs')) d.createObjectStore('docs', { keyPath: 'id' });
            if (!temStore(d, 'tr')) d.createObjectStore('tr');
            if (!temStore(d, 'vocab')) d.createObjectStore('vocab', { keyPath: 'id' });
        };
        const db = antes > 2 ? await abrirRaw('dd-ingles') : await abrirRaw('dd-ingles', 2, sobe);
        return envolver(db, 'dd-ingles');
    })().catch((e) => { pLegado = null; ev.emit('armazem-erro', { banco: 'dd-ingles', erro: String((e && e.message) || e) }); throw e; }));

    /* ------------------------------------------------------------ armazenamento persistente */
    async function persistir() { try { if (navigator.storage && navigator.storage.persist) return !!(await navigator.storage.persist()); } catch (e) { /* ignora */ } return false; }
    async function estimar() { try { if (navigator.storage && navigator.storage.estimate) { const e = await navigator.storage.estimate(); return { uso: e.usage || 0, cota: e.quota || 0 }; } } catch (e) { /* ignora */ } return null; }
    async function diagnostico() {
        let persistente = null; try { if (navigator.storage && navigator.storage.persisted) persistente = !!(await navigator.storage.persisted()); } catch (e) { /* ignora */ }
        return { indexedDB: !!window.indexedDB, localStorage: lsOk, persistente, estimativa: await estimar(), versaoLegado: await lerVersao('dd-ingles'), versaoNovo: await lerVersao(BANCO_NOVO.nome) };
    }

    return { ls, abrirBanco, novo, legado, copias, restaurarCopia, persistir, estimar, diagnostico, lerVersao, BANCO_NOVO };
});
