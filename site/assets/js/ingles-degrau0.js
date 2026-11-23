/*
 * ingles-degrau0.js — Degrau 0 · Primeiras histórias: seis fábulas curtas em inglês simples para quem começa do zero.
 * Uma história por dia (cerca de 125 palavras cada). O texto vem de assets/livros/degrau0-primeiras-historias.txt
 * (adaptação própria feita por IA, declarada e sujeita à revisão do autor) e é separado em um documento por história.
 * O progresso vem da posição de leitura do documento (meta.pos), como no Livro da semana. Nada vai à nuvem além do que
 * o núcleo já sincroniza (posição e palavras ouvidas, casadas por título + idioma).
 */
(function () {
    'use strict';
    const D = window.DDLab;
    if (!D) return;
    const URL_TXT = 'assets/livros/degrau0-primeiras-historias.txt', TAG = 'degrau0';
    const L = {
        pt: {
            h: 'DEGRAU 0 · PRIMEIRAS HISTÓRIAS',
            intro: 'Para quem está começando. Uma fábula curta por dia, em inglês simples. Siga os 4 passos em cada história e depois passe para a próxima.',
            steps: ['1. Leia com a tradução ligada.', '2. Ouça a história inteira, devagar (0,7×).', '3. Ouça de novo e repita em voz alta (modo Shadowing).', '4. Toque nas palavras novas para salvar.'],
            today: 'Hoje', done: 'lida', reading: 'em andamento', words: 'palavras',
            open: 'Começar', cont: 'Continuar', again: 'Reler', count: (d, n) => d + ' de ' + n + ' histórias lidas',
            fail: 'Não consegui carregar as histórias: ', preparing: 'Preparando a história…',
            note: 'Textos adaptados com apoio de IA a partir de fábulas de Esopo (domínio público); declarados e pendentes de revisão do autor.'
        },
        en: {
            h: 'LEVEL 0 · FIRST STORIES',
            intro: 'For beginners. One short fable a day, in simple English. Follow the 4 steps on each story, then move on to the next.',
            steps: ['1. Read with the translation on.', '2. Listen to the whole story, slowly (0.7×).', '3. Listen again and repeat aloud (Shadowing mode).', '4. Tap new words to save them.'],
            today: 'Today', done: 'read', reading: 'in progress', words: 'words',
            open: 'Start', cont: 'Continue', again: 'Read again', count: (d, n) => d + ' of ' + n + ' stories read',
            fail: 'Could not load the stories: ', preparing: 'Preparing the story…',
            note: 'Texts adapted with AI help from Aesop\'s fables (public domain); declared and pending the author\'s review.'
        }
    };
    const t = (k) => L[D.state.readLang === 'en' ? 'en' : 'pt'][k];
    const el = (tag, cls, txt) => { const e = document.createElement(tag); if (cls) e.className = cls; if (txt != null) e.textContent = txt; return e; };
    const btn = (txt, fn, cls) => { const b = el('button', 'lb-btn' + (cls ? ' ' + cls : ''), txt); b.type = 'button'; b.addEventListener('click', fn); return b; };
    const loadText = (url) => new Promise((ok, no) => { const x = new XMLHttpRequest(); x.open('GET', url); x.onload = () => ((x.status === 0 || (x.status >= 200 && x.status < 300)) && x.responseText ? ok(x.responseText) : no(new Error('http ' + x.status))); x.onerror = () => no(new Error('rede')); x.send(); });

    // separa o arquivo em histórias: cada uma começa com "N. Título"
    function parse(raw) {
        const out = [];
        raw.replace(/\r/g, '').split(/\n(?=\d+\. )/).forEach((chunk) => {
            const m = /^(\d+)\. ([^\n]+)\n+([\s\S]+)$/.exec(chunk.trim());
            if (!m) return;
            const body = m[3].trim();
            out.push({ n: +m[1], title: m[2].trim(), body, words: body.split(/\s+/).filter(Boolean).length });
        });
        return out;
    }
    let stories = null;
    const sec = el('section', 'lb-week lb-degrau0'); sec.id = 'lb-degrau0';
    const h2 = el('h2'); h2.id = 'lb-h-degrau0';
    const body = el('div', 'lb-week-body'); body.id = 'lb-degrau0-body';
    sec.append(h2, body);
    const anchor = D.$('lb-week') || D.$('lb-a-week') || D.$('lb-drop');
    if (anchor && anchor.parentNode) anchor.parentNode.insertBefore(sec, anchor);

    const docTitle = (s) => 'First Stories · ' + s.n + '. ' + s.title;
    async function openStory(s, metas) {
        const have = metas.find((m) => m.x && m.x[TAG] === s.n);
        if (have) return D.openDoc(have.id);
        await D.addText(docTitle(s), s.title + '\n\n' + s.body);   // importa e abre o leitor
        const d = D.doc; if (!d) throw new Error('não consegui ler o texto');
        d.x = Object.assign({}, d.x, { [TAG]: s.n }); D.saveMeta();
    }

    let seq = 0;
    async function render() {
        const my = ++seq;
        h2.textContent = t('h');
        let metas = [];
        try { metas = (await D.db.all('meta')).filter((m) => m.lang === 'en'); } catch (e) { /* sem banco */ }
        if (my !== seq) return;
        if (!stories) {
            try { stories = parse(await loadText(URL_TXT)); } catch (e) { body.textContent = ''; body.appendChild(el('p', 'lb-error', t('fail') + (e && e.message ? e.message : e))); return; }
            if (my !== seq) return;
        }
        const info = stories.map((s) => {
            const m = metas.find((x) => x.x && x.x[TAG] === s.n);
            const total = m ? (m.trTotal || 0) : 0, pos = m ? (m.pos || 0) : 0;
            return { s, m, done: !!m && total > 0 && pos >= total - 1, started: !!m && pos > 0 };
        });
        const nowIdx = info.findIndex((i) => !i.done);
        body.textContent = '';
        body.appendChild(el('p', 'lb-note', t('intro')));
        const ol = el('ul', 'lb-note'); t('steps').forEach((x) => ol.appendChild(el('li', null, x)));
        body.appendChild(ol);
        body.appendChild(el('p', 'lb-note lb-dg-count', t('count')(info.filter((i) => i.done).length, info.length)));
        const msg = el('p', 'lb-note'); msg.id = 'lb-degrau0-msg';
        info.forEach((it, idx) => {
            const cur = idx === nowIdx, cls = 'lb-rot-item ' + (it.done ? 'done' : cur ? 'now' : 'todo');
            const row = el('div', cls); row.dataset.story = String(it.s.n);
            const mark = el('span', 'lb-rot-mark', it.done ? '✓' : String(it.s.n)); mark.setAttribute('aria-hidden', 'true');
            const inf = el('div', 'lb-rot-info'), meta = el('div', 'lb-rot-meta');
            meta.appendChild(el('small', null, it.s.words + ' ' + t('words')));
            if (it.done) meta.appendChild(el('span', 'lb-rot-done', '✓ ' + t('done')));
            else if (it.started) meta.appendChild(el('span', 'lb-rot-now', t('reading')));
            else if (cur) meta.appendChild(el('span', 'lb-rot-now', t('today')));
            inf.append(el('strong', null, it.s.title), meta);
            const act = el('div', 'lb-rot-act');
            const b = btn(it.done ? t('again') : it.started ? t('cont') : t('open'), async () => {
                b.disabled = true; msg.textContent = t('preparing');
                try { await openStory(it.s, metas); msg.textContent = ''; } catch (e) { msg.textContent = t('fail') + (e && e.message ? e.message : e); }
                b.disabled = false;
            }, cur ? 'lb-primary' : ''); b.id = 'lb-degrau0-open-' + it.s.n;
            act.appendChild(b);
            row.append(mark, inf, act); body.appendChild(row);
        });
        body.append(msg, el('p', 'lb-note', t('note')));
    }
    D.on('close', render); D.on('lang', render); D.on('imported', render); D.on('stats-reset', render);
    render();
})();
