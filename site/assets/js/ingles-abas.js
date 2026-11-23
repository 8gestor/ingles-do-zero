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
            vocab: ['Vocabulário', 'Seu caderno de palavras: salve, adicione e revise.'],
            cfg: ['Configurações', 'Tradução, voz, conta e backup do seu progresso.']
        },
        en: {
            lib: ['Library', 'Your books and the book of the week.'],
            up: ['Reader / Upload PDF', 'Bring a text to read in one language and listen in the other.'],
            prog: ['Progress', 'Your study day and your progress.'],
            vocab: ['Vocabulary', 'Your word notebook: save, add and review.'],
            cfg: ['Settings', 'Translation, voice, account and backup of your progress.']
        }
    };
    const panes = {};
    NAMES.forEach((n) => { panes[n] = D.$('lb-pane-' + n); });
    if (NAMES.some((n) => !panes[n])) return;

    /* CONFIGURAÇÕES autoexplicativas: uma frase de abertura e uma explicação em linguagem simples em cada bloco.
     * O texto técnico longo (lb-note) vira a explicação da tradução; nada daqui é obrigatório para ler. */
    const H = {
        pt: {
            intro: 'Ajustes opcionais. O site funciona sem mexer em nada: aqui você escolhe como ele traduz, como ele lê em voz alta e onde o seu progresso fica guardado.',
            engine: 'Para que serve: mostrar o texto no outro idioma, frase por frase. Toque em "Ativar tradução" uma única vez em cada direção (baixa um modelo pequeno e depois funciona sem internet). Precisa do Chrome para computador, versão 138 ou superior. Sem isso você ainda lê e ouve o texto no idioma original. É tradução automática: serve para estudar.',
            voice: 'Para que serve: é a voz que lê o texto em voz alta. Vem do seu aparelho; se aparecer "—", ele não tem voz nesse idioma. Para uma voz mais natural, use a voz neural logo abaixo (opcional).'
        },
        en: {
            intro: 'Optional settings. The site works without touching anything: here you choose how it translates, how it reads aloud and where your progress is kept.',
            engine: 'What it is for: showing the text in the other language, sentence by sentence. Tap "Enable translation" once for each direction (it downloads a small model, then works offline). Needs desktop Chrome, version 138 or later. Without it you can still read and listen in the original language. It is machine translation: good for studying.',
            voice: 'What it is for: the voice that reads the text aloud. It comes from your device; if you see "—", it has no voice in that language. For a more natural voice, use the neural voice just below (optional).'
        }
    };
    const cfgIntro = document.createElement('p'); cfgIntro.className = 'lb-help'; cfgIntro.id = 'lb-cfg-intro';
    const engHelp = document.createElement('p'); engHelp.className = 'lb-help'; engHelp.id = 'lb-engine-help';
    const voiceHelp = document.createElement('p'); voiceHelp.className = 'lb-help'; voiceHelp.id = 'lb-voice-help';
    function paintHelp() {
        const x = H[D.state.readLang] || H.pt;
        cfgIntro.textContent = x.intro; engHelp.textContent = x.engine; voiceHelp.textContent = x.voice;
        const n = D.$('lb-note'); if (n) n.hidden = true;
    }
    (function placeHelp() {
        const cfg = D.$('lb-pane-cfg'), he = D.$('lb-h-engine'), hv = D.$('lb-h-voice');
        if (!cfg || !he || !hv) return;
        cfg.insertBefore(cfgIntro, cfg.firstChild);
        he.parentNode.insertBefore(engHelp, he.nextSibling);
        hv.parentNode.insertBefore(voiceHelp, hv.nextSibling);
    })();

    let cur = 'lib';
    function fromHash() { const v = (location.hash || '').replace('#', ''); return NAMES.indexOf(v) >= 0 ? v : 'lib'; }
    function paint() {
        const t = (L[D.state.readLang] || L.pt)[cur];
        D.$('lb-title').textContent = t[0];
        D.$('lb-lead').textContent = t[1];
        paintHelp();
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
