/*
 * ingles-abas.js — seções da página da Biblioteca (pedido do autor, 2026-11-22).
 *
 * O MENU LATERAL do site escolhe a seção (BIBLIOTECA, LEITOR / SUBIR PDF, PROGRESSO, VOCABULÁRIO, CONFIGURAÇÕES);
 * esta página só mostra a escolhida e troca o título, o selo e o subtítulo. A seção vem:
 *   - da URL do quadro (ingles.html#up), quando o site abre a página;
 *   - da mensagem `lab-pane` (leitor.js), quando a página já está aberta (um livro aberto é fechado antes).
 *
 *   lib   BIBLIOTECA          livros guardados + Livro da semana
 *   up    LEITOR / SUBIR PDF  área de envio (PDF, TXT, EPUB)
 *   prog  PROGRESSO           Sessão do dia + estatísticas
 *   vocab VOCABULÁRIO         palavras salvas e revisão
 *   cfg   CONFIGURAÇÕES       tradução, voz, voz neural, conta/nuvem e backup (o que não está no menu superior)
 *
 * Os blocos continuam sendo criados pelos próprios módulos (cada um acha a sua âncora `lb-a-*` na seção certa).
 */
(function () {
    'use strict';
    const D = window.DDLab;
    if (!D) return;
    const NAMES = ['lib', 'up', 'prog', 'vocab', 'cfg'];
    const L = {
        pt: {
            lib: ['Biblioteca', 'Seus livros e o livro da semana.'],
            up: ['Leitor / Subir PDF', 'Traga um texto para ler em um idioma e ouvir no outro.'],
            prog: ['Progresso', 'O seu dia de estudo e a sua evolução.'],
            vocab: ['Vocabulário', 'As palavras que você salvou e a revisão.'],
            cfg: ['Configurações', 'Tradução, voz, conta e backup: o que não está no menu superior.']
        },
        en: {
            lib: ['Library', 'Your books and the book of the week.'],
            up: ['Reader / Upload PDF', 'Bring a text to read in one language and listen in the other.'],
            prog: ['Progress', 'Your study day and your progress.'],
            vocab: ['Vocabulary', 'The words you saved, and review.'],
            cfg: ['Settings', 'Translation, voice, account and backup: what is not in the top menu.']
        }
    };
    const panes = {};
    NAMES.forEach((n) => { panes[n] = D.$('lb-pane-' + n); });
    if (NAMES.some((n) => !panes[n])) return;

    let cur = 'lib';
    function fromHash() { const v = (location.hash || '').replace('#', ''); return NAMES.indexOf(v) >= 0 ? v : 'lib'; }
    function paint() {
        const t = (L[D.state.readLang] || L.pt)[cur];
        D.$('lb-title').textContent = t[0];
        D.$('lb-lead').textContent = t[1];
        D.$('lb-meta').textContent = (D.state.readLang === 'en' ? 'ENGLISH STUDY // ' : 'ESTUDO DE INGLÊS // ') + t[0].toUpperCase();
        // o texto de apresentação do núcleo só faz sentido na seção de envio
        document.documentElement.dataset.pane = cur;
    }
    function show(n) {
        if (NAMES.indexOf(n) < 0) n = 'lib';
        cur = n;
        NAMES.forEach((k) => { panes[k].hidden = k !== n; });
        paint();
        if (D.emit) D.emit('tab', n);
    }
    function go(n) {
        if (D.doc && !D.$('lb-reader').hidden) D.$('lb-back').click();      // fecha o livro aberto (grava a posição)
        show(n);
        window.scrollTo(0, 0);
    }
    window.addEventListener('message', (e) => { const d = e.data || {}; if (d.type === 'lab-pane') go(d.value); });
    window.addEventListener('hashchange', () => go(fromHash()));
    D.on('lang', paint);
    D.on('close', () => { setTimeout(paint, 0); });      // ao fechar o livro o núcleo volta a escrever o cabeçalho padrão
    show(fromHash());
    D.tabs = { show: go, current: () => cur };
})();
