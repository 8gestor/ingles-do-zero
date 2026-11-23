/*
 * leitor.js — casca do site de inglês: menu, temas, painel Aa, voz, velocidade, barra de andamento e mensagens da página aberta.
 *
 * Derivado do leitor.js do livro (voce.algoritmo), SEM o que é só do livro (capítulos, ANT/PRÓX, Raio-X e estatísticas de capítulo).
 * Tudo o mais foi mantido igual, para nenhuma função da Biblioteca mudar. Ver docs/05-separacao-do-livro.md.
 *
 * Preferências (tema, tamanho, fonte, margens, alinhamento, velocidade) ficam no navegador (localStorage "dd-settings")
 * e são reenviadas à página a cada carga. Depende de: assets/js/sumario.js (extras, TITLES_EN, CATEGORIES_EN).
 */
const THEMES = [
    { id: 'paper', label: 'Papel' },
    { id: 'dark', label: 'Terminal' },
    { id: 'light', label: 'Claro' },
    { id: 'sepia', label: 'Sépia' }
];
const DEFAULTS = {
    theme: 'paper', font: 19, face: 'serif', margin: 'medium', align: 'left', rate: 1.0,
    readLang: 'pt', audioLang: 'pt', voices: { pt: '', en: '' }
};
const SETTINGS_KEY = 'dd-settings';
const OPT_TO_MSG = {
    theme: 'theme', face: 'typeface', margin: 'margins', align: 'align',
    readLang: 'readlang', audioLang: 'audiolang'
};
const SPEEDS = Array.from({ length: 30 }, (_, i) => (i + 1) / 10);     // 0,1x a 3x, de 0,1 em 0,1
const WPM_READ = { pt: 230, en: 230 };                                 // palavras por minuto de leitura (estimativa do tempo restante)

let settings = Object.assign({}, DEFAULTS);
try { settings = Object.assign(settings, JSON.parse(localStorage.getItem(SETTINGS_KEY) || '{}')); } catch (e) { /* sem storage */ }
function saveSettings() { try { localStorage.setItem(SETTINGS_KEY, JSON.stringify(settings)); } catch (e) { /* ignora */ } }

let labHud = null;           // dados do documento aberto na Biblioteca (páginas, palavras, avanço)

const frameEl = () => document.getElementById('content-frame');

function setLegendBtn(show, on) {
    const b = document.getElementById('btn-legenda');
    if (!b) return;
    b.hidden = !show; b.classList.toggle('active', !!on); b.setAttribute('aria-pressed', String(!!on));
}

function sendMsg(type, value) {
    const win = frameEl().contentWindow;
    if (win) win.postMessage({ type, value }, '*');
}

function syncAll() {
    sendMsg('theme', settings.theme);
    sendMsg('font', settings.font);
    sendMsg('typeface', settings.face);
    sendMsg('margins', settings.margin);
    sendMsg('align', settings.align);
    sendMsg('readlang', settings.readLang);
    sendMsg('audiolang', settings.audioLang);
    sendMsg('voice', { lang: 'pt', name: settings.voices.pt });
    sendMsg('voice', { lang: 'en', name: settings.voices.en });
    sendMsg('rate', settings.rate);
}

/* ---------- interface do leitor ---------- */
function refreshControls() {
    document.body.className = settings.theme + '-mode';
    document.documentElement.dataset.face = settings.face;     // o menu lateral acompanha a fonte do texto
    document.getElementById('speed-select').value = String(SPEEDS.reduce((a, b) => (Math.abs(b - settings.rate) < Math.abs(a - settings.rate) ? b : a)));
    document.documentElement.lang = settings.readLang === 'en' ? 'en' : 'pt-BR';
    document.getElementById('font-display').innerText = settings.font + ' px';
    applyUiLang();
    document.querySelectorAll('[data-opt]').forEach((b) => {
        const on = String(settings[b.dataset.opt]) === b.dataset.val;
        b.setAttribute('aria-pressed', on ? 'true' : 'false');
        b.classList.toggle('on', on);
    });
}

function setOption(key, val) {
    settings[key] = val;
    saveSettings();
    refreshControls();
    sendMsg(OPT_TO_MSG[key], val);
}

function adjustFont(delta) {
    settings.font = Math.max(14, Math.min(28, settings.font + delta));
    saveSettings(); refreshControls(); sendMsg('font', settings.font);
}

// Só define a velocidade da voz: a narração continua na mesma palavra.
function setSpeed(v) {
    settings.rate = Number(v) || 1;
    saveSettings(); refreshControls(); sendMsg('rate', settings.rate);
}

function setVoice(lang, name) {
    settings.voices[lang] = name;
    saveSettings();
    sendMsg('voice', { lang: lang, name: name });
}

// Preenche os seletores de voz com o que o navegador oferece (a lista chega de forma assíncrona).
function populateVoices() {
    if (!('speechSynthesis' in window)) return;
    const all = speechSynthesis.getVoices();
    const enUi = settings.readLang === 'en';
    [['pt', enUi ? 'Automatic (Portuguese)' : 'Automática (português)'],
     ['en', enUi ? 'Automatic (English)' : 'Automática (inglês)']].forEach(([lang, auto]) => {
        const sel = document.getElementById('voice-' + lang);
        if (!sel) return;
        sel.textContent = '';
        const o0 = document.createElement('option'); o0.value = ''; o0.textContent = auto; sel.appendChild(o0);
        const rank = (v) => (/natural|neural/i.test(v.name) ? 10 : 0) + (/online/i.test(v.name) ? 2 : 0) + (v.lang.replace('_', '-').toLowerCase() === (lang === 'pt' ? 'pt-br' : 'en-us') ? 4 : 0) + (/google/i.test(v.name) ? 1 : 0) + (v.localService ? 0.5 : 0);
        all.filter((v) => v.lang.toLowerCase().indexOf(lang) === 0).sort((a, b) => rank(b) - rank(a)).forEach((v) => {
            const o = document.createElement('option');
            o.value = v.name; o.textContent = (/natural|neural/i.test(v.name) ? '★ ' : '') + v.name.replace(/^Microsoft /, '').replace(/ - .*$/, '') + ' (' + v.lang + ')';
            sel.appendChild(o);
        });
        sel.value = settings.voices[lang] || '';
    });
}
if ('speechSynthesis' in window) speechSynthesis.onvoiceschanged = populateVoices;

function cycleTheme() {
    const i = THEMES.findIndex((t) => t.id === settings.theme);
    setOption('theme', THEMES[(i + 1) % THEMES.length].id);
}

function togglePanel(id) {
    ['aa-panel', 'voz-panel'].forEach((x) => {
        const el = document.getElementById(x);
        if (x === id) el.classList.toggle('open'); else el.classList.remove('open');
    });
    document.getElementById('btn-aa').setAttribute('aria-expanded', String(document.getElementById('aa-panel').classList.contains('open')));
    document.getElementById('btn-voz').setAttribute('aria-expanded', String(document.getElementById('voz-panel').classList.contains('open')));
}
function closePanels() { togglePanel(null); }

/* ---------- idioma da interface (acompanha o idioma de leitura) ---------- */
const navItems = [];   // { el, pt, en } — títulos do menu lateral

function applyUiLang() {
    const en = settings.readLang === 'en';
    document.querySelectorAll('[data-en]').forEach((el) => {
        if (el.dataset.pt === undefined) el.dataset.pt = el.textContent;
        el.textContent = en ? el.dataset.en : el.dataset.pt;
    });
    navItems.forEach((n) => { n.el.innerText = en && n.en ? n.en : n.pt; });
    renderLabHud();
    populateVoices();
}

/* ---------- barra de andamento: páginas, palavras e tempo restante do documento aberto na Biblioteca ---------- */
const HUD_TXT = {
    pt: { left: 'restam', done: 'concluído', heard: 'Ouvidas' },
    en: { left: 'left', done: 'done', heard: 'Heard' }
};
const hudShown = {};
function numFmt() { return new Intl.NumberFormat(settings.readLang === 'en' ? 'en-US' : 'pt-BR'); }
function fmtMin(m) {
    if (m < 1) return '< 1 min';
    if (m < 60) return Math.round(m) + ' min';
    const h = Math.floor(m / 60), r = Math.round(m % 60);
    return h + ' h' + (r ? ' ' + r + ' min' : '');
}
// Número que "carrega": sobe até o valor novo em vez de trocar de repente.
function tweenNum(el, to) {
    const from = hudShown[el.id] != null ? hudShown[el.id] : 0;
    hudShown[el.id] = to;
    clearInterval(el._iv);
    // Aba oculta (o navegador pausa animações) ou nada a animar: mostra o valor final já.
    if (document.hidden || Math.round(from) === Math.round(to)) { el.textContent = numFmt().format(Math.round(to)); return; }
    const t0 = performance.now(), dur = 450;
    // Temporizador (não requestAnimationFrame): termina sempre, mesmo em aba em segundo plano.
    el._iv = setInterval(() => {
        const k = Math.max(0, Math.min(1, (performance.now() - t0) / dur));
        el.textContent = numFmt().format(Math.round(from + (to - from) * (1 - Math.pow(1 - k, 3))));
        if (k >= 1) clearInterval(el._iv);
    }, 40);
}

// O botão Teleprompter só aparece com um documento aberto.
function setToolBtn(tele) {
    const tl = document.getElementById('btn-tele');
    if (tl) tl.hidden = !tele;
}
function renderLabHud() {
    setToolBtn(!!labHud);
    const en = settings.readLang === 'en', h = labHud, live = document.getElementById('hud-live');
    const ind = document.getElementById('chapter-indicator'), bar = document.getElementById('p-bar'), line = document.getElementById('read-line');
    if (!h) {
        live.style.display = 'none';
        document.getElementById('hud-top').textContent = en ? 'ENGLISH STUDY' : 'ESTUDO DE INGLÊS';
        ind.innerText = '—'; bar.style.width = '0%'; line.style.width = '0%';
        return;
    }
    const lang = h.lang === 'en' ? 'en' : 'pt', T = HUD_TXT[en ? 'en' : 'pt'], n = numFmt();
    const pct = h.total ? Math.min(100, h.read / h.total * 100) : 0;
    const rd = WPM_READ[lang] || 230;
    const title = h.title.length > 34 ? h.title.slice(0, 33) + '…' : h.title;
    document.getElementById('hud-top').textContent = title + ' · ' + (h.pages ? (en ? 'PAGE ' : 'PÁG ') + n.format(h.page) + '/' + n.format(h.pages) + ' · ' : '') + pct.toFixed(1).replace('.', en ? '.' : ',') + '%';
    ind.innerText = h.pages ? (en ? 'p. ' : 'pág ') + h.page + '/' + h.pages : Math.round(pct) + '%';
    bar.style.width = pct + '%'; line.style.width = pct + '%';
    live.style.display = '';
    tweenNum(document.getElementById('hl-read'), h.read);
    document.getElementById('hl-total').textContent = n.format(h.total);
    document.getElementById('hl-lang').textContent = lang.toUpperCase();
    document.getElementById('hl-left').textContent = h.total - h.read < 1 ? '✓ ' + T.done : T.left + ' ≈ ' + fmtMin((h.total - h.read) / rd);
    live.title = T.heard + ': ' + n.format(h.heard || 0) + ' ' + (en ? 'words' : 'palavras');
}

/* ---------- navegação ---------- */
function init() {
    const nav = document.getElementById('nav-container');
    let lastCat = '';
    extras.forEach((item, k) => {
        if (item.cat !== lastCat) {
            const cat = document.createElement('div');
            cat.className = 'nav-cat';
            cat.innerText = item.cat;
            navItems.push({ el: cat, pt: item.cat, en: CATEGORIES_EN[item.cat] });
            nav.appendChild(cat);
            lastCat = item.cat;
        }
        const btn = document.createElement('a');
        btn.className = 'chapter-link';
        btn.innerText = item.t;
        navItems.push({ el: btn, pt: item.t, en: TITLES_EN[item.id || item.f] });
        btn.href = '#' + keyOf(item);
        btn.onclick = (e) => {
            e.preventDefault();
            loadPage(k);
            if (isMobile()) closeSidebarMobile();
        };
        nav.appendChild(btn);
    });

    // abre direto na página indicada na URL (#manual-biblioteca), se houver; senão, a Biblioteca
    const wanted = location.hash.replace('#', '');
    const start = extras.findIndex((s) => keyOf(s) === wanted);
    refreshControls();
    populateVoices();
    loadPage(start >= 0 ? start : 0);
}

// nome do item na URL (#ingles-progresso, #manual-biblioteca)
const keyOf = (item) => item.id || item.f.replace('.html', '');
let frameFile = '';      // arquivo que está no quadro (para trocar de seção da Biblioteca sem recarregar a página)

// Abre uma página do site no quadro do leitor. Itens com pane são seções da mesma página (ingles.html):
// se ela já está aberta, só troca a seção (um livro aberto é fechado), sem recarregar nem perder o estado.
function loadPage(k) {
    const it = extras[k];
    if (it.pane && frameFile === it.f) {
        closePanels();
        sendMsg('lab-pane', it.pane);
        try { history.replaceState(null, '', '#' + keyOf(it)); } catch (e) { /* file:// */ }
        document.querySelectorAll('.chapter-link').forEach((el, i) => {
            el.classList.toggle('active', i === k);
            if (i === k) el.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
        });
        return;
    }
    frameFile = it.f;
    setToolBtn(false);
    setLegendBtn(false, false);       // o botão Legenda só aparece quando a página (ingles-legenda.js) avisa que tem legenda
    labHud = null;
    const frame = frameEl();
    const btnTts = document.getElementById('btn-tts');
    btnTts.innerText = '▶';
    btnTts.classList.remove('active');
    closePanels();
    frame.src = it.f + (it.pane ? '#' + it.pane : '');
    try { history.replaceState(null, '', '#' + keyOf(it)); } catch (e) { /* file:// */ }
    document.getElementById('p-bar').style.width = '0%';
    document.getElementById('chapter-indicator').innerText = '—';
    document.querySelectorAll('.chapter-link').forEach((el, i) => {
        el.classList.toggle('active', i === k);
        if (i === k) el.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    });
    renderLabHud();
    frame.onload = () => { syncAll(); };
}

function toggleFullScreen() {
    if (!document.fullscreenElement) {
        document.documentElement.requestFullscreen().catch((err) => console.log(err));
    } else if (document.exitFullscreen) {
        document.exitFullscreen();
    }
}

// "celular" = mesmo critério do leitor.css (bloco CELULAR E TELAS BAIXAS): mantenha os dois iguais
const MOBILE_MQ = window.matchMedia('(max-width: 900px), (max-height: 500px) and (pointer: coarse)');
function isMobile() { return MOBILE_MQ.matches; }
function closeSidebarMobile() {
    document.getElementById('sidebar').classList.remove('open');
    document.getElementById('backdrop').classList.remove('active');
}
// girar a tela ou redimensionar: nunca deixar a cortina escura ou o menu preso no modo errado
MOBILE_MQ.addEventListener('change', () => { closeSidebarMobile(); closePanels(); });

function toggleSidebar() {
    const sb = document.getElementById('sidebar');
    const bd = document.getElementById('backdrop');
    if (isMobile()) {
        sb.classList.toggle('open');
        bd.classList.toggle('active');
    } else {
        sb.classList.toggle('collapsed');
    }
}

window.addEventListener('message', (e) => {
    if (e.data && e.data.type === 'dd-lab-sidebar' && !isMobile()) document.getElementById('sidebar').classList.toggle('collapsed', !!e.data.hide);   // modo foco da Biblioteca
    if (e.data && e.data.type === 'dd-fullscreen') toggleFullScreen();      // F11 apertado dentro da página
    if (e.data && e.data.type === 'dd-lab-immersive') document.body.classList.toggle('imersivo', !!e.data.on);   // teleprompter: só a legenda na tela
    if (e.data && e.data.type === 'dd-set-option' && (e.data.key === 'readLang' || e.data.key === 'audioLang') && (e.data.value === 'pt' || e.data.value === 'en')) setOption(e.data.key, e.data.value);
    if (e.data && e.data.type === 'dd-lab-hud') { labHud = e.data.hud || null; renderLabHud(); }
    if (e.data && e.data.type === 'legend-swap') {
        const r = settings.readLang, a = settings.audioLang, opp = (l) => (l === 'en' ? 'pt' : 'en');
        if (e.data.ifEqual) { if (r === a) setOption('audioLang', opp(r)); }
        else if (r === a) setOption('audioLang', opp(r));
        else { setOption('readLang', a); setOption('audioLang', r); }
    }
    if (e.data && e.data.type === 'legend-state' && (!e.data.page || (frameEl().src || '').split('?')[0].split('#')[0].endsWith(e.data.page))) setLegendBtn(true, e.data.on);   // ignora aviso atrasado de página anterior
    if (e.data && e.data.type === 'tts-state') {
        const btn = document.getElementById('btn-tts');
        if (e.data.isPlaying) { btn.innerText = '■'; btn.classList.add('active'); }
        else { btn.innerText = '▶'; btn.classList.remove('active'); }
    }
});

window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') { closePanels(); if (isMobile()) closeSidebarMobile(); }
    // setas: acompanham o texto frase a frase (a página aberta decide o que fazer); fora de campos de escolha e de digitação
    if ((e.key === 'ArrowLeft' || e.key === 'ArrowRight') && !e.altKey && !e.ctrlKey && !e.metaKey && !/^(input|textarea|select)$/i.test((e.target && e.target.tagName) || '') && !(e.target && e.target.isContentEditable)) { e.preventDefault(); sendMsg(e.shiftKey ? 'step-sentence' : 'step', e.key === 'ArrowRight' ? 1 : -1); }
    if (e.key === 'F11') { e.preventDefault(); toggleFullScreen(); }      // tela inteira ligada e desligada no F11
});

init();
