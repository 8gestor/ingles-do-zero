/*
 * ingles-palavras.js — toque na palavra (significado, pronúncia, salvar) + vocabulário com repetição espaçada.
 *
 * Depende do núcleo (ingles.js → window.DDLab). Cartões ficam no IndexedDB (store "vocab"), só neste aparelho.
 * Intervalos: versão enxuta do SM-2 (Errei · Difícil · Bom · Fácil).
 */
(function () {
    'use strict';
    const D = window.DDLab;
    if (!D) return;
    const $ = D.$;
    const DAY = 86400000;
    const WORD = /[\p{L}\p{M}'’-]/u;

    const L = {
        pt: {
            hVocab: 'VOCABULÁRIO', none: 'Nenhuma palavra salva ainda. Toque numa palavra do texto e escolha Salvar.',
            summary: (n, d) => n + (n === 1 ? ' palavra salva' : ' palavras salvas') + ' · ' + d + ' para revisar agora',
            review: 'Revisar agora', list: 'Ver lista', hideList: 'Esconder lista', exportCsv: 'Exportar (Anki/CSV)', del: 'Excluir',
            save: '☆ Salvar', saved: '★ Salva', listen: '🔊 Ouvir', play: '▶ Ler daqui', close: 'Fechar',
            trading: 'traduzindo…', trNone: 'Tradução indisponível: ative o tradutor (aviso no topo do documento).', sentence: 'Frase', inContext: 'No contexto',
            show: 'Mostrar resposta', again: 'Errei', hard: 'Difícil', good: 'Bom', easy: 'Fácil', due: 'a revisar',
            done: 'Revisão concluída. Volte amanhã para as próximas.', left: 'restam', next: 'Próxima em', days: 'd', exit: 'Sair',
            how: 'Seu caderno de palavras. Salve palavras novas (tocando nelas durante a leitura, ou adicionando aqui). Cada palavra volta para revisão em intervalos crescentes (1, 3, 7 dias…) até você dominá-la. Revisar 5 minutos por dia vale mais do que uma hora por semana.',
            sNew: 'novas', sLearn: 'aprendendo', sMaster: 'dominadas',
            addH: 'Adicionar uma palavra', addWord: 'Palavra', addTr: 'Significado (opcional: se vazio, o tradutor preenche)', addSent: 'Frase de exemplo (opcional)', addBtn: 'Adicionar',
            addNeed: 'Digite a palavra.', addDup: 'Essa palavra já está no seu vocabulário.', addOk: 'Palavra adicionada.',
            weekH: 'Palavras do livro da semana', weekNote: 'As mais frequentes e menos comuns do livro. Salve as que quiser aprender antes de ler (a frase vem do próprio livro).', weekNone: 'Quando você começar uma semana na Biblioteca, as palavras difíceis do livro aparecem aqui.', weekAll: 'Salvar todas', weekSaved: 'salvas',
            search: 'Buscar na lista', listEmpty: 'Nenhuma palavra encontrada.', noReview: 'Nada para revisar agora. Volte quando houver palavras vencendo.'
        },
        en: {
            hVocab: 'VOCABULARY', none: 'No saved words yet. Tap a word in the text and choose Save.',
            summary: (n, d) => n + (n === 1 ? ' saved word' : ' saved words') + ' · ' + d + ' due now',
            review: 'Review now', list: 'Show list', hideList: 'Hide list', exportCsv: 'Export (Anki/CSV)', del: 'Delete',
            save: '☆ Save', saved: '★ Saved', listen: '🔊 Listen', play: '▶ Play from here', close: 'Close',
            trading: 'translating…', trNone: 'Translation unavailable: enable the translator (notice at the top of the document).', sentence: 'Sentence', inContext: 'In context',
            show: 'Show answer', again: 'Again', hard: 'Hard', good: 'Good', easy: 'Easy', due: 'due',
            done: 'Review finished. Come back tomorrow for the next ones.', left: 'left', next: 'Next in', days: 'd', exit: 'Exit',
            how: 'Your word notebook. Save new words (by tapping them while reading, or adding them here). Each word comes back for review at growing intervals (1, 3, 7 days…) until you master it. Five minutes a day beats an hour a week.',
            sNew: 'new', sLearn: 'learning', sMaster: 'mastered',
            addH: 'Add a word', addWord: 'Word', addTr: 'Meaning (optional: if empty, the translator fills it in)', addSent: 'Example sentence (optional)', addBtn: 'Add',
            addNeed: 'Type the word.', addDup: 'That word is already in your vocabulary.', addOk: 'Word added.',
            weekH: 'Words from the book of the week', weekNote: 'The most frequent and least common words in the book. Save the ones you want to learn before reading (the sentence comes from the book itself).', weekNone: 'When you start a week in the Library, the book\'s hard words show up here.', weekAll: 'Save all', weekSaved: 'saved',
            search: 'Search the list', listEmpty: 'No words found.', noReview: 'Nothing to review right now. Come back when words are due.'
        }
    };
    const t = (k) => L[D.state.readLang][k];
    const el = (tag, cls, txt) => { const e = document.createElement(tag); if (cls) e.className = cls; if (txt != null) e.textContent = txt; return e; };

    /* ------------------------------------------------------------------ cartões */
    const key = (lang, w) => lang + ':' + w;
    let cache = null;                                   // todos os cartões em memória (lista pequena)
    async function loadAll() { if (!cache) { try { cache = await D.db.all('vocab'); } catch (e) { cache = []; } } return cache; }
    async function saveCard(c) { try { await D.db.put('vocab', c); } catch (e) { /* ignora */ } }
    async function dropCard(id) { try { await D.db.del('vocab', id); } catch (e) { /* ignora */ } cache = (cache || []).filter((c) => c.id !== id); }
    const dueNow = (list) => list.filter((c) => c.due <= Date.now()).sort((a, b) => a.due - b.due);

    // SM-2 enxuto. g: 0 errei · 1 difícil · 2 bom · 3 fácil
    function grade(c, g) {
        if (g === 0) { c.reps = 0; c.lapses = (c.lapses || 0) + 1; c.ease = Math.max(1.3, c.ease - 0.2); c.ivl = 0; c.due = Date.now() + 5 * 60000; return c; }
        if (g === 1) { c.ease = Math.max(1.3, c.ease - 0.15); c.ivl = Math.max(1, Math.round((c.ivl || 1) * 1.2)); }
        if (g === 2) c.ivl = c.reps === 0 ? 1 : c.reps === 1 ? 3 : Math.round(c.ivl * c.ease);
        if (g === 3) { c.ivl = c.reps === 0 ? 3 : Math.round(Math.max(c.ivl, 1) * c.ease * 1.3); c.ease += 0.15; }
        c.reps++; c.due = Date.now() + c.ivl * DAY;
        return c;
    }

    /* ------------------------------------------------------------------ palavra tocada */
    function wordAtPoint(x, y) {
        let node, off;
        if (document.caretPositionFromPoint) { const p = document.caretPositionFromPoint(x, y); if (p) { node = p.offsetNode; off = p.offset; } }
        else if (document.caretRangeFromPoint) { const r = document.caretRangeFromPoint(x, y); if (r) { node = r.startContainer; off = r.startOffset; } }
        if (!node || node.nodeType !== 3) return null;
        const s = node.textContent;
        let a = Math.min(off, s.length), b = a;
        while (a > 0 && WORD.test(s[a - 1])) a--;
        while (b < s.length && WORD.test(s[b])) b++;
        const w = s.slice(a, b).replace(/^[-'’]+|[-'’]+$/g, '');
        return w && /\p{L}/u.test(w) ? w : null;
    }

    let pop = null;
    function closePop() { if (pop) { pop.remove(); pop = null; } }
    document.addEventListener('keydown', (e) => { if (e.key === 'Escape') closePop(); });
    document.addEventListener('click', (e) => { if (pop && !pop.contains(e.target) && !(e.target.closest && e.target.closest('.lb-s, .lg-main'))) closePop(); });
    window.addEventListener('scroll', closePop, { passive: true });

    const speakCache = {};
    const speakWord = (text, lang) => D.say(text, lang);

    async function openPopover(ev) {
        const doc = D.doc;
        const word = wordAtPoint(ev.e.clientX, ev.e.clientY);
        if (!doc || !word) return false;
        closePop();
        const sp = ev.sp, tr = doc.tr[ev.p];
        const shownOther = D.state.readLang !== doc.lang && !sp.classList.contains('pending');
        const wlang = ev.wlang || (shownOther ? D.other(doc.lang) : doc.lang);   // idioma em que a palavra aparece na tela (a legenda informa o seu)
        const olang = D.other(wlang);
        const sentHere = ev.sentHere != null ? ev.sentHere : sp.textContent.trim();
        const sentOther = ev.sentOther != null ? ev.sentOther : (tr && tr[ev.s] != null ? (shownOther ? doc.paras[ev.p].s[ev.s] : tr[ev.s]) : '');
        const lower = word.toLowerCase();

        pop = el('div', 'lb-pop');
        pop.setAttribute('role', 'dialog');
        const head = el('div', 'lb-pop-head');
        head.append(el('strong', 'lb-pop-word', word), el('span', 'lb-pop-lang', wlang.toUpperCase()));
        const wi = D.wordInfo ? D.wordInfo(word.toLowerCase(), wlang) : '';
        if (wi) head.append(el('span', 'lb-pop-lang', '· ' + wi));
        const trEl = el('div', 'lb-pop-tr', t('trading'));
        const ctx = el('div', 'lb-pop-ctx');
        ctx.append(el('small', null, t('sentence')), el('div', null, sentHere));
        if (sentOther) ctx.append(el('div', 'lb-pop-other', sentOther));
        const acts = el('div', 'lb-pop-acts');
        const bListen = el('button', 'lb-btn', t('listen')); bListen.type = 'button';
        bListen.onclick = () => speakWord(word, wlang);
        const bSave = el('button', 'lb-btn lb-primary', t('save')); bSave.type = 'button';
        const bPlay = el('button', 'lb-btn', t('play')); bPlay.type = 'button';
        bPlay.onclick = () => { closePop(); D.startTts(ev.p, ev.s); };
        const bClose = el('button', 'lb-btn', '✕'); bClose.type = 'button'; bClose.title = t('close'); bClose.onclick = closePop;
        acts.append(bListen, bSave, bPlay, bClose);
        pop.append(head, trEl, ctx, acts);
        document.body.appendChild(pop);
        placePop(ev.e.clientX, ev.e.clientY);

        const id = key(wlang, lower);
        const existing = (await loadAll()).find((c) => c.id === id);
        let tword = existing ? existing.tr : null;
        const refreshSave = () => { bSave.textContent = (cache || []).some((c) => c.id === id) ? t('saved') : t('save'); };
        refreshSave();
        bSave.onclick = async () => {
            const have = (cache || []).find((c) => c.id === id);
            if (have) { await dropCard(id); }
            else {
                const card = { id, word: lower, lang: wlang, tr: tword || '', sent: sentHere, sentTr: sentOther, doc: doc.title, added: Date.now(), due: Date.now(), ivl: 0, ease: 2.5, reps: 0, lapses: 0 };
                (cache = cache || []).push(card); await saveCard(card); D.emit('vocab-saved', card);
            }
            refreshSave(); renderVocab();
        };

        if (!tword) tword = speakCache['t:' + id] || await D.translateText(lower, wlang);
        if (!pop) return true;
        if (tword) { speakCache['t:' + id] = tword; trEl.textContent = tword; const c = (cache || []).find((x) => x.id === id); if (c && !c.tr) { c.tr = tword; saveCard(c); } }
        else trEl.textContent = t('trNone');
        trEl.title = olang;
        return true;
    }
    function placePop(x, y) {
        const w = Math.min(340, window.innerWidth - 24);
        pop.style.width = w + 'px';
        const left = Math.max(12, Math.min(x - w / 2, window.innerWidth - w - 12));
        pop.style.left = left + 'px';
        const h = pop.offsetHeight;
        pop.style.top = (y + 18 + h > window.innerHeight ? Math.max(8, y - h - 14) : y + 18) + 'px';
    }

    D.on('tap', (ev) => { if (ev.handled) return; if (wordAtPoint(ev.e.clientX, ev.e.clientY)) { ev.handled = true; openPopover(ev); } });
    D.on('close', closePop);
    D.on('open', closePop);

    /* ------------------------------------------------------------------ vocabulário (biblioteca) + revisão */
    const sec = el('section', 'lb-vocab'); sec.id = 'lb-vocab';
    const h2 = el('h2'); h2.id = 'lb-h-vocab';
    const how = el('p', 'lb-help'); how.id = 'lb-vocab-how';
    const sum = el('p', 'lb-vocab-sum'); sum.id = 'lb-vocab-sum';
    const stats = el('div', 'lb-vstats'); stats.id = 'lb-vocab-stats';
    const bar = el('div', 'lb-doc-acts');
    const bRev = el('button', 'lb-btn lb-primary'); bRev.type = 'button'; bRev.id = 'lb-vocab-review';
    const bList = el('button', 'lb-btn'); bList.type = 'button';
    const bCsv = el('button', 'lb-btn'); bCsv.type = 'button';
    bar.append(bRev, bList, bCsv);
    const listBox = el('div', 'lb-vocab-listbox'); listBox.hidden = true;
    const searchIn = el('input', 'lb-input'); searchIn.type = 'search'; searchIn.id = 'lb-vocab-search'; searchIn.autocomplete = 'off';
    const listEl = el('div', 'lb-vocab-list');
    listBox.append(searchIn, listEl);
    // adicionar palavra à mão
    const addBox = el('div', 'lb-vadd'); addBox.id = 'lb-vocab-add';
    const addH = el('h3', 'lb-group');
    const aWord = el('input', 'lb-input'), aTr = el('input', 'lb-input'), aSent = el('input', 'lb-input');
    aWord.id = 'lb-vadd-word'; aWord.autocomplete = 'off'; aWord.autocapitalize = 'none'; aTr.id = 'lb-vadd-tr'; aTr.autocomplete = 'off'; aSent.id = 'lb-vadd-sent'; aSent.autocomplete = 'off';
    const aLang = el('select', 'lb-input'); aLang.id = 'lb-vadd-lang';
    ['en', 'pt'].forEach((l) => { const o = el('option', null, D.langName ? D.langName(l) : l.toUpperCase()); o.value = l; aLang.appendChild(o); });
    const aBtn = el('button', 'lb-btn lb-primary'); aBtn.type = 'button'; aBtn.id = 'lb-vadd-go';
    const aMsg = el('p', 'lb-sync-status'); aMsg.id = 'lb-vadd-msg';
    const aRow = el('div', 'lb-sync-form'); aRow.append(aWord, aLang);
    addBox.append(addH, aRow, aTr, aSent, aBtn, aMsg);
    // palavras do livro da semana
    const weekBox = el('div', 'lb-vweek'); weekBox.id = 'lb-vocab-week';
    sec.append(h2, how, sum, stats, bar, listBox, addBox, weekBox);
    const anchorEl = $('lb-a-vocab') || $('lb-h-engine');
    if (anchorEl && anchorEl.parentNode) anchorEl.parentNode.insertBefore(sec, anchorEl);

    const stage = (c) => (c.ivl >= 21 ? 'master' : c.reps > 0 ? 'learn' : 'new');
    async function renderVocab() {
        const list = await loadAll(), due = dueNow(list);
        h2.textContent = t('hVocab');
        how.textContent = t('how');
        sum.textContent = list.length ? t('summary')(list.length, due.length) : t('none');
        const cnt = { new: 0, learn: 0, master: 0 };
        list.forEach((c) => { cnt[stage(c)]++; });
        stats.textContent = '';
        stats.hidden = !list.length;
        [['new', 'sNew'], ['learn', 'sLearn'], ['master', 'sMaster']].forEach(([k, lab]) => {
            const chip = el('span', 'lb-vchip'); chip.append(el('strong', null, String(cnt[k])), ' ' + t(lab)); stats.appendChild(chip);
        });
        bRev.textContent = t('review'); bRev.disabled = !due.length; bRev.title = due.length ? '' : t('noReview');
        bList.textContent = listBox.hidden ? t('list') : t('hideList');
        bCsv.textContent = t('exportCsv');
        searchIn.placeholder = t('search');
        bar.hidden = !list.length;
        listEl.textContent = '';
        if (!listBox.hidden) {
            const q = searchIn.value.trim().toLowerCase();
            const rows = list.slice().sort((a, b) => b.added - a.added).filter((c) => !q || (c.word + ' ' + (c.tr || '') + ' ' + (c.sent || '')).toLowerCase().indexOf(q) >= 0);
            if (!rows.length) listEl.appendChild(el('p', 'lb-note', t('listEmpty')));
            rows.forEach((c) => {
                const row = el('div', 'lb-vrow');
                const info = el('div', 'lb-vinfo');
                info.append(el('strong', null, c.word), el('span', null, c.tr || '—'), el('small', null, c.sent));
                const del = el('button', 'lb-btn', '✕'); del.type = 'button'; del.title = t('del'); del.setAttribute('aria-label', t('del'));
                del.onclick = async () => { await dropCard(c.id); renderVocab(); renderWeek(); };
                row.append(info, del); listEl.appendChild(row);
            });
        }
        addH.textContent = t('addH');
        aWord.placeholder = t('addWord'); aTr.placeholder = t('addTr'); aSent.placeholder = t('addSent'); aBtn.textContent = t('addBtn');
    }
    searchIn.addEventListener('input', renderVocab);
    bList.onclick = () => { listBox.hidden = !listBox.hidden; renderVocab(); };

    async function addCard(word, lang, tr, sent, from) {
        const lower = String(word || '').trim().toLowerCase();
        if (!lower) return 'need';
        const id = key(lang, lower);
        if ((await loadAll()).some((c) => c.id === id)) return 'dup';
        let meaning = String(tr || '').trim();
        if (!meaning && D.translateText) { try { meaning = (await D.translateText(lower, lang)) || ''; } catch (e) { meaning = ''; } }
        const card = { id, word: lower, lang, tr: meaning, sent: String(sent || '').trim(), sentTr: '', doc: from || '', added: Date.now(), due: Date.now(), ivl: 0, ease: 2.5, reps: 0, lapses: 0 };
        (cache = cache || []).push(card); await saveCard(card); D.emit('vocab-saved', card);
        return 'ok';
    }
    aBtn.onclick = async () => {
        aBtn.disabled = true;
        const r = await addCard(aWord.value, aLang.value, aTr.value, aSent.value, '');
        aBtn.disabled = false;
        aMsg.textContent = r === 'need' ? t('addNeed') : r === 'dup' ? t('addDup') : t('addOk');
        if (r === 'ok') { aWord.value = ''; aTr.value = ''; aSent.value = ''; aWord.focus(); }
        renderVocab(); renderWeek();
    };
    aWord.addEventListener('keydown', (e) => { if (e.key === 'Enter') { e.preventDefault(); aBtn.click(); } });

    // palavras do livro da semana (as mesmas de "palavras a ver antes de ler"), com a frase tirada do próprio livro
    async function sentenceFor(docId, word) {
        try {
            const d = await D.db.get('docs', docId); if (!d) return '';
            const re = new RegExp('(^|[^\\p{L}])' + word.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '([^\\p{L}]|$)', 'iu');
            for (const p of d.paras) for (const s of p.s) if (re.test(s)) return s;
        } catch (e) { /* sem frase */ }
        return '';
    }
    let weekSeq = 0;
    async function renderWeek() {
        const my = ++weekSeq;
        const W = window.__ddWeek, plan = W && W.load();
        let info = null;
        if (plan) { try { info = await W.bookInfo(plan.docId); } catch (e) { info = null; } }
        if (my !== weekSeq) return;
        weekBox.textContent = '';
        weekBox.append(el('h3', 'lb-group', t('weekH')));
        if (!plan || !info || !info.hard.length) { weekBox.append(el('p', 'lb-note', t('weekNone'))); return; }
        const have = new Set(((await loadAll()) || []).map((c) => c.id));
        if (my !== weekSeq) return;
        weekBox.append(el('p', 'lb-note', plan.title + ' — ' + t('weekNote')));
        const chips = el('div', 'lb-week-chips'); chips.id = 'lb-vweek-chips';
        const todo = [];
        info.hard.forEach((w) => {
            const saved = have.has(key('en', w));
            const b = el('button', 'lb-btn lb-vweek-chip', (saved ? '★ ' : '☆ ') + w); b.type = 'button'; b.disabled = saved;
            if (!saved) todo.push(w);
            b.onclick = async () => { b.disabled = true; await addCard(w, 'en', '', await sentenceFor(plan.docId, w), plan.title); renderVocab(); renderWeek(); };
            chips.appendChild(b);
        });
        weekBox.append(chips);
        if (todo.length > 1) {
            const all = el('button', 'lb-btn', t('weekAll') + ' (' + todo.length + ')'); all.type = 'button'; all.id = 'lb-vweek-all';
            all.onclick = async () => { all.disabled = true; for (const w of todo) await addCard(w, 'en', '', await sentenceFor(plan.docId, w), plan.title); renderVocab(); renderWeek(); };
            weekBox.append(all);
        }
    }
    bCsv.onclick = async () => {
        const rows = (await loadAll()).map((c) => [c.word, c.tr, c.sent, c.sentTr, c.lang].map((x) => String(x || '').replace(/[\t\r\n]+/g, ' ')).join('\t'));
        const url = URL.createObjectURL(new Blob(['﻿' + rows.join('\n')], { type: 'text/tab-separated-values;charset=utf-8' }));
        const a = el('a'); a.href = url; a.download = 'vocabulario.tsv'; document.body.appendChild(a); a.click(); a.remove(); setTimeout(() => URL.revokeObjectURL(url), 2000);
    };

    // revisão em tela cheia
    let ov = null;
    function highlight(sent, word) {
        const box = el('div', 'lb-card-sent');
        const i = sent.toLowerCase().indexOf(word.toLowerCase());
        if (i < 0) { box.textContent = sent; return box; }
        box.append(sent.slice(0, i), el('mark', null, sent.slice(i, i + word.length)), sent.slice(i + word.length));
        return box;
    }
    async function startReview() {
        const queue = dueNow(await loadAll()).slice(0, 20);
        if (!queue.length) return;
        ov = el('div', 'lb-review'); ov.setAttribute('role', 'dialog');
        document.body.appendChild(ov);
        const total = queue.length;
        const step = () => {
            ov.textContent = '';
            const top = el('div', 'lb-review-top');
            const ex = el('button', 'lb-btn', t('exit')); ex.type = 'button'; ex.onclick = end;
            top.append(el('span', null, (total - queue.length + 1 > total ? total : total - queue.length + 1) + '/' + total + ' · ' + queue.length + ' ' + t('left')), ex);
            ov.appendChild(top);
            if (!queue.length) { ov.append(el('p', 'lb-card-done', t('done'))); const b = el('button', 'lb-btn lb-primary', t('exit')); b.type = 'button'; b.onclick = end; ov.appendChild(b); return; }
            const c = queue[0];
            const card = el('div', 'lb-card');
            card.append(el('div', 'lb-card-word', c.word), highlight(c.sent, c.word));
            const lis = el('button', 'lb-btn', t('listen')); lis.type = 'button'; lis.onclick = () => speakWord(c.word, c.lang);
            card.appendChild(lis);
            const back = el('div', 'lb-card-back'); back.hidden = true;
            back.append(el('div', 'lb-card-tr', c.tr || '—'));
            if (c.sentTr) back.append(el('div', 'lb-pop-other', c.sentTr));
            card.appendChild(back);
            ov.appendChild(card);
            const row = el('div', 'lb-review-acts');
            const show = el('button', 'lb-btn lb-primary', t('show')); show.type = 'button';
            show.onclick = () => {
                back.hidden = false; row.textContent = '';
                [['again', 0], ['hard', 1], ['good', 2], ['easy', 3]].forEach(([k, g]) => {
                    const b = el('button', 'lb-btn', t(k)); b.type = 'button';
                    b.onclick = async () => {
                        queue.shift(); const upd = grade(c, g); await saveCard(upd);
                        if (g === 0) queue.push(upd);          // errou: volta ao fim da fila da sessão
                        D.emit('reviewed', { grade: g, card: upd });
                        step();
                    };
                    row.appendChild(b);
                });
            };
            row.appendChild(show); ov.appendChild(row);
            speakWord(c.word, c.lang);
        };
        const end = () => { if (ov) { ov.remove(); ov = null; } if (window.speechSynthesis) speechSynthesis.cancel(); renderVocab(); };
        step();
    }
    bRev.onclick = startReview;

    D.on('lang', () => { renderVocab(); renderWeek(); });
    D.on('close', () => { renderVocab(); renderWeek(); });
    D.on('tab', (n) => { if (n === 'vocab') { renderVocab(); renderWeek(); } });
    D.on('imported', () => { cache = null; renderVocab(); renderWeek(); });
    renderVocab();
    renderWeek();
    window.__ddVocab = { grade, wordAtPoint, loadAll, key, startReview };
})();
