/*
 * telas-dados.js — tela #/dados: Backup do progresso (arquivo) e Conta e sincronização (docs/07, seção 5; áreas BK e SY da matriz).
 * Textos em português e inglês (seguem o idioma de leitura). Tudo montado com textContent, nunca innerHTML.
 * Backup funciona SEM conta e sem sincronização; em aparelhos que não baixam arquivos (e-reader, TV) o botão Baixar mostra o texto para copiar,
 * e há "Colar texto" para carregar.
 */
App.define('telas-dados', ['eventos', 'config', 'rotas', 'dados', 'nuvem'], function (deps) {
    'use strict';
    const { eventos, config, rotas, dados, nuvem } = deps;
    const h = (tag, cls, txt) => { const e = document.createElement(tag); if (cls) e.className = cls; if (txt != null) e.textContent = txt; return e; };
    const L = {
        pt: {
            titulo: 'Dados e conta', bkH: 'Backup do progresso (arquivo)', bkP: 'Leve o seu progresso de um site ou aparelho para outro, sem precisar de conta: baixe o arquivo aqui e carregue lá. Nada é apagado, os dados são somados. O texto dos livros não vai no arquivo.',
            dl: 'Baixar progresso', up: 'Carregar progresso', paste: 'Colar texto', go: 'Importar texto colado', ph: 'Cole aqui o conteúdo do arquivo de progresso', done: 'Progresso carregado', days: 'dias de estudo', cards: 'palavras salvas novas', books: 'livros com posição guardada (aplicada quando o livro entrar na biblioteca)',
            saved: 'Arquivo gerado.', copy: 'Este aparelho não baixa arquivos. Copie o texto abaixo e guarde (ou cole no outro aparelho).', bad: 'Este arquivo não é um backup de progresso deste site.', fail: 'Não foi possível ler o arquivo.',
            cH: 'Conta e sincronização', off: 'A sincronização ainda não foi ativada neste site. O progresso fica salvo neste aparelho.', out: 'Entre para levar o progresso para o celular, o tablet e outros aparelhos. Só o progresso é enviado (nunca o texto dos livros).',
            email: 'Seu e-mail', send: 'Enviar código', code: 'Código recebido por e-mail', enter: 'Entrar', sent: 'Código enviado. Digite os dígitos que chegaram no seu e-mail.', cbad: 'Código inválido ou vencido.', cfail: 'Não foi possível enviar o código. Confira o e-mail e a conexão.',
            in: 'Conectado', as: 'como', last: 'Última sincronização', never: 'ainda não', now: 'Sincronizar agora', out2: 'Sair', syncing: 'Sincronizando…', offline: 'Sem conexão: o progresso continua salvo aqui e sobe quando voltar.', session: 'A sessão venceu. Entre de novo.', ok: 'Tudo sincronizado.'
        },
        en: {
            titulo: 'Data and account', bkH: 'Progress backup (file)', bkP: 'Take your progress from one site or device to another without an account: download the file here and load it there. Nothing is deleted, data is added together. Book text is not in the file.',
            dl: 'Download progress', up: 'Load progress', paste: 'Paste text', go: 'Import pasted text', ph: 'Paste the content of the progress file here', done: 'Progress loaded', days: 'study days', cards: 'new saved words', books: 'books with a saved position (applied when the book enters the library)',
            saved: 'File created.', copy: 'This device cannot download files. Copy the text below and keep it (or paste it on the other device).', bad: 'This file is not a progress backup for this site.', fail: 'The file could not be read.',
            cH: 'Account and sync', off: 'Sync has not been turned on for this site yet. Progress stays saved on this device.', out: 'Sign in to take your progress to your phone, tablet and other devices. Only progress is sent (never the text of books).',
            email: 'Your email', send: 'Send code', code: 'Code received by email', enter: 'Sign in', sent: 'Code sent. Type the digits that arrived in your email.', cbad: 'Invalid or expired code.', cfail: 'The code could not be sent. Check the email and your connection.',
            in: 'Signed in', as: 'as', last: 'Last sync', never: 'not yet', now: 'Sync now', out2: 'Sign out', syncing: 'Syncing…', offline: 'Offline: progress stays saved here and uploads when you are back.', session: 'The session expired. Sign in again.', ok: 'Everything synced.'
        }
    };
    const t = (k) => L[config.get('readLang')][k];

    rotas.registrar('/dados', {
        titulo: 'Dados e conta',
        montar(el) {
            let desligar = [];
            el.append(h('h1', 'novo-h1', t('titulo')));
            /* ---- backup ---- */
            const bk = h('section', 'novo-card'); bk.id = 'dad-backup';
            const bkH = h('h2', 'novo-h2'), bkP = h('p'), bkForm = h('div', 'novo-linha'), bkSt = h('p', 'sis-linha'); bkSt.id = 'dad-bk-status';
            const bDl = h('button', 'novo-btn'), bUp = h('button', 'novo-btn'), bPaste = h('button', 'novo-btn'), bGo = h('button', 'novo-btn');
            const file = h('input'), txt = h('textarea', 'novo-texto');
            [bDl, bUp, bPaste, bGo].forEach((b) => { b.type = 'button'; });
            bDl.id = 'dad-down'; bUp.id = 'dad-up'; bPaste.id = 'dad-paste'; bGo.id = 'dad-go'; file.id = 'dad-file'; txt.id = 'dad-text';
            file.type = 'file'; file.accept = '.json,application/json,text/plain'; file.hidden = true; txt.hidden = true; txt.rows = 6; bGo.hidden = true;
            bkForm.append(bDl, bUp, bPaste, file, txt, bGo); bk.append(bkH, bkP, bkForm, bkSt);
            let bkMsg = null;
            const pintaBk = () => { bkH.textContent = t('bkH'); bkP.textContent = t('bkP'); bDl.textContent = t('dl'); bUp.textContent = t('up'); bPaste.textContent = t('paste'); bGo.textContent = t('go'); txt.placeholder = t('ph'); bkSt.textContent = bkMsg ? t(bkMsg.k) + (bkMsg.extra ? ': ' + bkMsg.extra : '') : ''; };
            const diz = (k, extra) => { bkMsg = { k, extra: extra || '' }; pintaBk(); };
            const importa = async (texto) => {
                try {
                    const r = await dados.importar(texto), n = (x) => (x > 0 ? '+' + x : String(x));
                    diz('done', n(r.days) + ' ' + t('days') + ', ' + n(r.cards) + ' ' + t('cards') + ', ' + r.books + ' ' + t('books'));
                } catch (e) { diz(String(e && e.message) === 'formato' ? 'bad' : 'fail'); }
            };
            bDl.addEventListener('click', async () => {
                let texto = ''; try { texto = await dados.exportar(); } catch (e) { diz('fail'); return; }
                let ok = false;
                try {
                    if (window.Blob && window.URL && URL.createObjectURL) {
                        const a = document.createElement('a'), u = URL.createObjectURL(new Blob([texto], { type: 'application/json' }));
                        a.href = u; a.download = 'progresso-ingles-' + new Date().toISOString().slice(0, 10) + '.json'; a.style.display = 'none';
                        document.body.appendChild(a); a.click(); a.remove(); setTimeout(() => URL.revokeObjectURL(u), 4000); ok = typeof a.download === 'string';
                    }
                } catch (e) { ok = false; }
                if (ok) diz('saved'); else { txt.hidden = false; txt.value = texto; if (txt.select) txt.select(); diz('copy'); }
            });
            bUp.addEventListener('click', () => { file.value = ''; file.click(); });
            file.addEventListener('change', () => {
                const f = file.files && file.files[0]; if (!f) return;
                if (f.size > 8 * 1024 * 1024) { diz('bad'); return; }
                const rd = new FileReader(); rd.onload = () => importa(String(rd.result || '')); rd.onerror = () => diz('fail'); rd.readAsText(f);
            });
            bPaste.addEventListener('click', () => { txt.hidden = !txt.hidden; bGo.hidden = txt.hidden; if (!txt.hidden) { txt.value = ''; txt.focus(); } });
            bGo.addEventListener('click', () => { const v = txt.value.trim(); if (!v) { diz('bad'); return; } importa(v); });
            el.append(bk);

            /* ---- conta e sincronização ---- */
            const ct = h('section', 'novo-card'); ct.id = 'dad-conta';
            const cH = h('h2', 'novo-h2'), linha = h('p', 'sis-linha'), form = h('div', 'novo-linha'), st = h('p', 'sis-linha'); st.id = 'dad-conta-status'; linha.id = 'dad-conta-linha';
            const inEmail = h('input', 'novo-campo'), bSend = h('button', 'novo-btn'), inCode = h('input', 'novo-campo'), bEnter = h('button', 'novo-btn'), bNow = h('button', 'novo-btn'), bOut = h('button', 'novo-btn');
            inEmail.type = 'email'; inEmail.autocomplete = 'email'; inEmail.id = 'dad-email'; inCode.inputMode = 'numeric'; inCode.autocomplete = 'one-time-code'; inCode.maxLength = 8; inCode.id = 'dad-code';
            [bSend, bEnter, bNow, bOut].forEach((b) => { b.type = 'button'; });
            bSend.id = 'dad-send'; bEnter.id = 'dad-enter'; bNow.id = 'dad-now'; bOut.id = 'dad-out';
            form.append(inEmail, bSend, inCode, bEnter, bNow, bOut); ct.append(cH, linha, form, st);
            const pintaConta = () => {
                const s = nuvem.estado(), off = !s.configurada, fora = !off && s.estado === 'out', codigo = fora && !!s.pendente && s.msg === 'sent', dentro = !off && (s.estado === 'in' || s.estado === 'sync');
                cH.textContent = t('cH'); inEmail.placeholder = t('email'); inCode.placeholder = t('code'); bSend.textContent = t('send'); bEnter.textContent = t('enter'); bNow.textContent = t('now'); bOut.textContent = t('out2');
                inEmail.hidden = bSend.hidden = !fora; inCode.hidden = bEnter.hidden = !codigo; bNow.hidden = bOut.hidden = !dentro;
                linha.textContent = off ? t('off') : fora ? t('out') : t('in') + ' ' + t('as') + ' ' + s.email + ' · ' + t('last') + ': ' + (s.ultima ? new Date(s.ultima).toLocaleString(config.get('readLang') === 'en' ? 'en-US' : 'pt-BR') : t('never'));
                st.textContent = s.estado === 'sync' ? t('syncing') : s.msg === 'sent' ? t('sent') : s.msg === 'fail' ? t('cfail') + (s.erro ? ' (' + s.erro + ')' : '') : s.msg === 'bad' ? t('cbad') : s.msg === 'offline' ? t('offline') : s.msg === 'session' ? t('session') : (dentro && s.ultima ? t('ok') : '');
                bNow.disabled = s.estado === 'sync'; ct.dataset.estado = s.estado;
            };
            bSend.addEventListener('click', async () => { bSend.disabled = true; await nuvem.enviarCodigo(inEmail.value.trim()); bSend.disabled = false; });
            bEnter.addEventListener('click', async () => { bEnter.disabled = true; const ok = await nuvem.entrar(inCode.value); bEnter.disabled = false; if (ok) inCode.value = ''; });
            bNow.addEventListener('click', () => nuvem.sincronizar('manual')); bOut.addEventListener('click', () => nuvem.sair());
            el.append(ct);

            desligar.push(eventos.on('nuvem-estado', pintaConta), eventos.on('config-mudou', (d) => { if (d.chave === 'readLang') { pintaBk(); pintaConta(); } }));
            // ao sair da tela, solta as escutas (rota-mudou dispara depois de montar a nova)
            desligar.push(eventos.on('rota-mudou', (r) => { if (r.rota !== '/dados') { desligar.forEach((f) => f()); desligar = []; } }));
            pintaBk(); pintaConta();
        }
    });
    return {};
});
