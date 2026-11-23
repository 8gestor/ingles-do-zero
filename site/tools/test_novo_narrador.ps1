<#
  test_novo_narrador.ps1 — confere, no Chrome, o Narrador do app novo (site/novo/assets/js/narrador/; fase R2; ver docs/10-r2-narrador.md).

  R2.1 (ritmo e vozes). A prova é feita de duas formas, as duas SEM relógio real nem fala real (por isso não sofrem com a carga da máquina):
    · ORÁCULO: uma cópia LITERAL do código antigo (`ingles.js`, linhas 667–680 e 736–757) roda ao lado do módulo novo, com centenas de entradas
      aleatórias (semente fixa); o resultado tem de ser idêntico.
    · SIMULAÇÃO de voz: os cenários do `test_sync.ps1` do livro (voz lenta e voz rápida, SEM evento de palavra) com o tempo SIMULADO; mede o erro
      entre a palavra destacada pela estimativa e a palavra realmente falada. Critério herdado: erro médio <= 1,5 palavra.
  NR1 tempo acumulado · NR2 posição estimada · NR3 aprendizado da velocidade por idioma e voz · NR4 escolha da voz · NR5 ordenação do menu de vozes ·
  NR6 sincronia por estimativa (lenta e rápida, em 3 velocidades) · NR7 sem voltar atrás e chegando ao fim da frase
  Uso: pwsh tools\test_novo_narrador.ps1 [-Chrome <caminho>]    (sai com 1 se alguma verificação falhar)
#>
param([string]$Chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe')
$ErrorActionPreference = 'Stop'
$enc = New-Object System.Text.UTF8Encoding($false)
$repo = Split-Path -Parent $PSScriptRoot
$tmp = Join-Path ([IO.Path]::GetTempPath()) ('dd-nar-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory $tmp | Out-Null
robocopy $repo $tmp /E /XD .git .github /NFL /NDL /NJH /NJS /NP | Out-Null

$test = @'
<script>
(function () {
  var out = [], fails = 0;
  function live() { var p = document.getElementById('result'); if (!p) { p = document.createElement('pre'); p.id = 'result'; p.style.cssText = 'position:fixed;left:-99999px;top:0;width:10px;height:10px;overflow:hidden'; document.body.appendChild(p); } p.textContent = out.join(String.fromCharCode(10)); }
  function ok(name, cond, extra) { if (!cond) fails++; out.push((cond ? 'PASS ' : 'FAIL ') + name + (extra ? '  [' + extra + ']' : '')); live(); }
  function wait(ms) { return new Promise(function (r) { setTimeout(r, ms); }); }
  var hb = setInterval(function () {}, 4);
  async function until(fn) { var t = Date.now(); while (Date.now() - t < 900000) { try { if (fn()) return true; } catch (e) {} await wait(100); } return false; }
  function rnd(seed) { return function () { seed |= 0; seed = seed + 0x6D2B79F5 | 0; var t = Math.imul(seed ^ seed >>> 15, 1 | seed); t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t; return ((t ^ t >>> 14) >>> 0) / 4294967296; }; }

  /* ---------- ORÁCULOS: cópia literal do código antigo (ingles.js) ---------- */
  var PAUSE = { ',': 4, ';': 4, ':': 4, '—': 4, '–': 4, '.': 8, '!': 8, '?': 8, '…': 8 };
  function oCum(text) { var cum = new Float32Array(text.length + 1); for (var i = 0; i < text.length; i++) cum[i + 1] = cum[i] + 1 + (PAUSE[text[i]] || 0); return cum; }
  function oPos(cum, len, WT, el, cps, rate) { var target = Math.min(WT, el * cps * rate); var lo = 0, hi = len - 1; while (lo < hi) { var mid = (lo + hi) >> 1; if (cum[mid + 1] > target) hi = mid; else lo = mid + 1; } return lo; }
  function oAprende(cps, WT, dur, rate, len) { if (len > 25 && dur > 0.5) return Math.max(6, Math.min(40, cps * 0.7 + (WT / (dur * rate)) * 0.3)); return null; }
  var LANG_TAG = { pt: 'pt-BR', en: 'en-US' };
  function oRank(v, lang) { var l = v.lang.replace('_', '-').toLowerCase(); return (/natural|neural/i.test(v.name) ? 10 : 0) + (/online/i.test(v.name) ? 2 : 0) + (l === LANG_TAG[lang].toLowerCase() ? 4 : 0) + (/google/i.test(v.name) ? 1 : 0) + (v.localService ? 0.5 : 0); }
  function oPick(lang, name, vs) { var chosen = name && vs.find(function (x) { return x.name === name; }); if (chosen) return chosen; return vs.filter(function (x) { return x.lang.toLowerCase().indexOf(lang) === 0; }).sort(function (a, b) { return oRank(b, lang) - oRank(a, lang); })[0] || null; }
  // regra do menu de vozes da casca (leitor.js, populateVoices)
  function oMenu(lang, all) { var rank = function (v) { return (/natural|neural/i.test(v.name) ? 10 : 0) + (/online/i.test(v.name) ? 2 : 0) + (v.lang.replace('_', '-').toLowerCase() === (lang === 'pt' ? 'pt-br' : 'en-us') ? 4 : 0) + (/google/i.test(v.name) ? 1 : 0) + (v.localService ? 0.5 : 0); }; return all.filter(function (v) { return v.lang.toLowerCase().indexOf(lang) === 0; }).sort(function (a, b) { return rank(b) - rank(a); }); }

  window.addEventListener('load', async function () {
    try {
      await until(function () { return window.__appPronto; });
      var rel = window.__appPronto;
      ok('NR0 o app liga com os módulos ritmo e vozes prontos', rel.ok === true && App.tem('ritmo') && App.tem('vozes') && App.tem('voz-navegador') && App.tem('voz-neural') && App.tem('narrador'), rel.modulos.filter(function (m) { return m.estado !== 'pronto'; }).map(function (m) { return m.nome + ':' + m.erro; }).join(' '));
      var R = App.get('ritmo'), V = App.get('vozes'), r = rnd(20261122);
      function pick(a) { return a[Math.floor(r() * a.length)]; }
      var PALAVRAS = ['the', 'merchant', 'laborious', 'diligence', 'casa', 'grande', 'não', 'é', 'tempo', 'vida', 'a', 'of', 'Seneca', 'said'];
      var SINAIS = [' ', ' ', ' ', ', ', '; ', ': ', ' — ', ' – ', '. ', '! ', '? ', '… ', '...'];
      function texto() { var n = 1 + Math.floor(r() * 30), s = ''; for (var i = 0; i < n; i++) s += pick(PALAVRAS) + pick(SINAIS); return s.trim(); }

      // ===== NR1 · tempo acumulado =====
      var dif1 = 0, N1 = 300; for (var i = 0; i < N1; i++) { var tx = texto(), m = R.modelo(tx), c = oCum(tx), mesmo = m.cum.length === c.length && m.total === c[tx.length]; for (var k = 0; mesmo && k < c.length; k++) if (m.cum[k] !== c[k]) mesmo = false; if (!mesmo) dif1++; }
      var m0 = R.modelo(''), m1 = R.modelo('Oi, tudo bem?');
      ok('NR1 o tempo acumulado por caractere (com as pausas da pontuação) é IDÊNTICO ao do código antigo em 300 textos aleatórios; texto vazio não quebra; a vírgula custa 4 e o "?" custa 8', dif1 === 0 && m0.total === 0 && m0.tamanho === 0 && m1.cum[3] - m1.cum[2] === 1 + 4 && m1.cum[13] - m1.cum[12] === 1 + 8, dif1 + ' diferentes');

      // ===== NR2 · posição estimada =====
      var dif2 = 0, N2 = 600; for (var j = 0; j < N2; j++) { var t2 = texto(), mm = R.modelo(t2), cc = oCum(t2), cps = 8 + r() * 25, rate = Math.round((0.1 + r() * 2.9) * 10) / 10, el = r() * 40; if (R.posicaoEm(mm, el, cps, rate) !== oPos(cc, t2.length, cc[t2.length], el, cps, rate)) dif2++; }
      var mp = R.modelo('um dois tres quatro');
      ok('NR2 a posição estimada para 600 combinações de texto, velocidade média, fator 0,1–3× e tempo é IDÊNTICA à do código antigo; no tempo 0 está no início e passado o fim fica no último caractere', dif2 === 0 && R.posicaoEm(mp, 0, 16, 1) === 0 && R.posicaoEm(mp, 9999, 16, 1) === mp.tamanho - 1 && R.posicaoEm(R.modelo(''), 5, 16, 1) === 0, dif2 + ' diferentes');

      // ===== NR3 · aprendizado da velocidade por idioma e por voz =====
      var dif3 = 0, N3 = 600; for (var q = 0; q < N3; q++) { var t3 = texto(), m3 = R.modelo(t3), tab = R.novaTabela(), idioma = pick(['pt', 'en']), voz = pick(['Voz A', 'Voz B', '']), cpsU = 6 + r() * 34, dur = r() * 12, rate3 = Math.round((0.1 + r() * 2.9) * 10) / 10; var esperado = oAprende(cpsU, m3.total, dur, rate3, t3.length), obtido = tab.aprender(idioma, voz, m3, cpsU, dur, rate3); if (!(esperado === obtido || (esperado !== null && obtido !== null && Math.abs(esperado - obtido) < 1e-12))) dif3++; }
      var tb = R.novaTabela(), long = R.modelo('This is a sentence long enough to teach the voice speed well.');
      var padrao = [tb.cpsDe('pt', 'X'), tb.cpsDe('en', 'X')]; tb.aprender('en', 'Voz A', long, 17, 6, 1);
      var curtaNaoEnsina = tb.aprender('en', 'Voz B', R.modelo('Too short'), 17, 5, 1) === null && tb.aprender('en', 'Voz B', long, 17, 0.3, 1) === null;
      ok('NR3a o aprendizado da velocidade é IDÊNTICO ao do código antigo em 600 casos (frase de até 25 caracteres ou fala de até 0,5 s não ensina; resultado limitado a 6–40)', dif3 === 0 && curtaNaoEnsina, dif3 + ' diferentes');
      ok('NR3b a velocidade é aprendida POR IDIOMA E POR VOZ: começa em 16 (pt) e 17 (en); aprender na "Voz A" em inglês não muda a "Voz B" nem o português; voz desconhecida usa o valor do idioma', padrao[0] === 16 && padrao[1] === 17 && tb.cpsDe('en', 'Voz A') !== 17 && tb.cpsDe('en', 'Voz B') === 17 && tb.cpsDe('pt', 'Voz A') === 16 && tb.cpsDe('en', 'Nunca vista') === 17 && R.novaTabela().cpsDe('en', 'Voz A') === 17, 'en/Voz A=' + tb.cpsDe('en', 'Voz A').toFixed(2));
      var ext = R.novaTabela(); for (var z = 0; z < 80; z++) ext.aprender('en', 'V', R.modelo('A fairly long sentence to push the speed to the limits, again and again.'), ext.cpsDe('en', 'V'), 0.6, 1);
      var ext2 = R.novaTabela(); for (var z2 = 0; z2 < 80; z2++) ext2.aprender('en', 'V', R.modelo('A fairly long sentence to push the speed to the limits, again and again.'), ext2.cpsDe('en', 'V'), 300, 1);
      ok('NR3c a velocidade aprendida nunca passa de 40 nem fica abaixo de 6, mesmo com fala absurdamente rápida ou lenta repetida', ext.cpsDe('en', 'V') <= 40 && ext.cpsDe('en', 'V') >= 6 && ext2.cpsDe('en', 'V') >= 6 && ext2.cpsDe('en', 'V') <= 40, ext.cpsDe('en', 'V').toFixed(1) + ' / ' + ext2.cpsDe('en', 'V').toFixed(1));

      // ===== NR4 e NR5 · vozes =====
      var NOMES = ['Microsoft Aria Online (Natural) - English', 'Google português do Brasil', 'Google US English', 'Fake PT', 'Fake EN', 'Microsoft Maria - Portuguese (Brazil)', 'eSpeak', 'Neural Voz Local', 'Online Voz', 'Zira'], LANGS = ['pt-BR', 'pt_PT', 'en-US', 'en_GB', 'es-ES', 'EN-us', 'pt-br', 'en'];
      function listaVozes() { var n = Math.floor(r() * 9), l = []; for (var i = 0; i < n; i++) l.push({ name: pick(NOMES) + (r() < 0.3 ? ' ' + i : ''), lang: pick(LANGS), localService: r() < 0.5 }); return l; }
      var dif4 = 0, dif5 = 0, N4 = 600;
      for (var a = 0; a < N4; a++) { var lista = listaVozes(), idi = pick(['pt', 'en']), pref = r() < 0.4 && lista.length ? lista[Math.floor(r() * lista.length)].name : (r() < 0.2 ? 'Voz que sumiu' : ''); if (V.escolher(idi, pref, lista) !== oPick(idi, pref, lista)) dif4++; var o1 = V.ordenar(idi, lista), o2 = oMenu(idi, lista); if (o1.length !== o2.length || o1.some(function (x, i2) { return x !== o2[i2]; })) dif5++; }
      ok('NR4 a escolha da voz é IDÊNTICA à do código antigo em 600 listas aleatórias (voz do aluno vence se existir; senão neural > rede > local; idioma exato desempata; lista vazia dá nulo)', dif4 === 0 && V.escolher('pt', '', []) === null, dif4 + ' diferentes');
      ok('NR5 a ordenação das vozes do idioma é IDÊNTICA à do menu de vozes da casca (leitor.js) em 600 listas aleatórias: o menu e o Narrador sempre concordam na "melhor voz"', dif5 === 0, dif5 + ' diferentes');
      var ex = [{ name: 'Fake PT', lang: 'pt-BR', localService: true }, { name: 'Microsoft Maria Online (Natural)', lang: 'pt-BR', localService: false }, { name: 'Google português do Brasil', lang: 'pt-BR', localService: false }];
      ok('NR4b exemplo legível: entre três vozes pt-BR vence a neural online; a escolhida pelo aluno vence qualquer ranking; nome que sumiu volta ao ranking', V.escolher('pt', '', ex).name === 'Microsoft Maria Online (Natural)' && V.escolher('pt', 'Fake PT', ex).name === 'Fake PT' && V.escolher('pt', 'Sumiu', ex).name === 'Microsoft Maria Online (Natural)' && V.escolher('en', '', ex) === null);

      // ===== NR6 · sincronia por estimativa, com o tempo SIMULADO (cenários do test_sync.ps1 do livro) =====
      var FRASES = ['Algorithms decide what we read and what we buy, and nobody explains how they work.', 'It is not a neutral process, because every ranking carries a value judgement.', 'The laborious diligence of the merchant, however, was rewarded in the end.', 'Understanding that fact is the first step towards resisting it; the rest is practice.', 'Few people ask, and fewer still wait for an answer.', 'They shape our choices every day, quietly, without ever asking permission.', 'What would the old philosophers have said about this machine?', 'Perhaps they would have laughed: time, they taught, is the only thing we truly own.', 'Life is long if you know how to use it, and short only if you waste it.', 'So we read, we listen, we repeat, and slowly the language becomes our own.'];
      var SC = { lenta: { cps: 11.5, p: [0.30, 0.45, 0.70] }, rapida: { cps: 19, p: [0.08, 0.12, 0.20] } };
      function pausaDe(w, p) { if (/[.!?…]["'”’)\]]*$/.test(w)) return p[2]; if (/[;:]["'”’)\]]*$/.test(w) || /^[—–]$/.test(w)) return p[1]; if (/,["'”’)\]]*$/.test(w)) return p[0]; return 0; }
      function simula(cenario, rate) {
        var sc = SC[cenario], tab = R.novaTabela(), erros = [], voltou = 0, fimOk = 0, ate = 0, LAT = 150;
        FRASES.forEach(function (fr) {
          var ws = [], re = /\S+/g, mt; while ((mt = re.exec(fr))) ws.push({ s: mt.index, e: mt.index + mt[0].length, w: mt[0] });
          var cps = sc.cps * rate, t = 0; ws.forEach(function (x) { x.t = t; t += (x.w.length + 1) / cps + pausaDe(x.w, sc.p) / rate; }); var total = t;
          var m = R.modelo(fr), cpsUsado = tab.cpsDe('en', 'Voz'), mostrada = 0, ultimaMostrada = -1, ultimoTick = -1;
          for (var ms = 0; ms <= total * 1000; ms += 20) {                          // o relógio simulado anda de 20 em 20 ms
            var el = ms / 1000;
            if (ms % 60 === 0 && ms >= 0) { var pos = R.posicaoEm(m, el, cpsUsado, rate), k = 0; while (k < ws.length - 1 && ws[k].e <= pos) k++; mostrada = k; if (ultimaMostrada > mostrada) voltou++; ultimaMostrada = mostrada; }
            if (ms % 40 === 0) { var verdade = 0; for (var q2 = 0; q2 < ws.length; q2++) if (ws[q2].t <= el) verdade = q2; erros.push(mostrada - verdade); }
          }
          ate += ws.length; if (mostrada >= ws.length - 2) fimOk++;
          tab.aprender('en', 'Voz', m, cpsUsado, total, rate);                       // termina bem: aprende a velocidade desta voz
        });
        var abs = erros.map(Math.abs).sort(function (x, y) { return x - y; }), n = abs.length, media = abs.reduce(function (x, y) { return x + y; }, 0) / n;
        return { media: media, p95: abs[Math.min(n - 1, Math.floor(n * 0.95))], max: abs[n - 1], voltou: voltou, fimOk: fimOk, frases: FRASES.length };
      }
      var res = {}; ['lenta', 'rapida'].forEach(function (c) { [1, 1.5, 0.7].forEach(function (rt) { res[c + '@' + rt] = simula(c, rt); }); });
      var piores = Object.keys(res).map(function (k) { return k + '=' + res[k].media.toFixed(2); }).join(' ');
      ok('NR6 sincronia por estimativa, SEM calibração prévia e sem evento de palavra: nas vozes lenta e rápida, a 0,7×, 1× e 1,5×, o erro médio entre a palavra destacada e a falada é de no máximo 1,5 palavra (critério do test_sync.ps1)', Object.keys(res).every(function (k) { return res[k].media <= 1.5; }), piores);
      ok('NR7a o destaque estimado NUNCA volta atrás dentro de uma frase, em nenhum cenário', Object.keys(res).every(function (k) { return res[k].voltou === 0; }), Object.keys(res).map(function (k) { return k + '=' + res[k].voltou; }).join(' '));
      ok('NR7b ao fim de cada frase o destaque chega perto da última palavra (a no máximo 1 palavra do fim) em todas as frases e cenários', Object.keys(res).every(function (k) { return res[k].fimOk === res[k].frases; }), Object.keys(res).map(function (k) { return k + '=' + res[k].fimOk + '/' + res[k].frases; }).join(' '));
      var l1 = simula('lenta', 1);
      ok('NR7c o erro máximo fica limitado: no máximo 5 palavras em 10 frases com voz lenta (o pior caso é a frase de aprendizado, sem calibração prévia; depois dela o erro cai)', l1.max <= 5, 'max=' + l1.max + ' p95=' + l1.p95);

      // ===================== R2.2 · motor de voz do navegador e laço do Narrador (fala e relógio FALSOS) =====================
      var VN = App.get('voz-navegador'), NA = App.get('narrador'), EV = App.get('eventos');
      function relogioFalso() { var t = 0, id = 0, tm = []; return { agora: function () { return t; }, setInterval: function (f, ms) { tm.push({ id: ++id, f: f, ms: ms, prox: t + ms, rep: true }); return id; }, clearInterval: function (i) { tm = tm.filter(function (x) { return x.id !== i; }); }, setTimeout: function (f, ms) { tm.push({ id: ++id, f: f, ms: ms, prox: t + ms, rep: false }); return id; }, clearTimeout: function (i) { tm = tm.filter(function (x) { return x.id !== i; }); }, anda: function (ms) { var fim = t + ms; while (t < fim) { t += 10; tm.slice().forEach(function (x) { if (tm.indexOf(x) >= 0 && x.prox <= t) { if (x.rep) x.prox += x.ms; else tm = tm.filter(function (y) { return y !== x; }); x.f(); } }); } } }; }
      // speechSynthesis falsa: o cancel() avisa DEPOIS (assíncrono), como os navegadores de verdade
      function sintesFalsa() {
        var s = { fila: [], falando: null, falas: [], cancelamentos: 0, voices: [{ name: 'Voz EN', lang: 'en-US', localService: true }, { name: 'Voz PT', lang: 'pt-BR', localService: true }] };
        s.getVoices = function () { return s.voices; };
        Object.defineProperty(s, 'speaking', { get: function () { return !!s.falando || s.fila.length > 0; } });
        Object.defineProperty(s, 'pending', { get: function () { return s.fila.length > 0; } });
        s.speak = function (u) { s.falas.push(u); s.fila.push(u); };
        s.cancel = function () { s.cancelamentos++; var tudo = (s.falando ? [s.falando] : []).concat(s.fila); s.falando = null; s.fila = []; setTimeout(function () { tudo.forEach(function (u) { if (u.onerror) u.onerror({ error: 'canceled' }); }); }, 0); };
        s.inicia = function () { if (!s.falando && s.fila.length) { s.falando = s.fila.shift(); if (s.falando.onstart) s.falando.onstart(); } };      // o motor começa a próxima da fila
        s.palavra = function (ci) { if (s.falando && s.falando.onboundary) s.falando.onboundary({ name: 'word', charIndex: ci }); };
        s.termina = function () { var u = s.falando; s.falando = null; if (u && u.onend) u.onend(); };
        return s;
      }
      function Fala(texto) { this.text = texto; this.rate = 1; this.lang = ''; this.voice = null; }
      var tique = function () { return new Promise(function (r) { setTimeout(r, 0); }); };
      async function ate(fn) { for (var i = 0; i < 200; i++) { if (fn()) return true; await tique(); } return false; }
      function motor(extra) { var c = relogioFalso(), s = sintesFalsa(), m = VN.criar(Object.assign({ synth: s, Utterance: Fala, relogio: c }, extra || {})); return { c: c, s: s, m: m }; }

      // NV1 fala simples
      var A = motor(), resA = null, pA = A.m.falar('Hello there, my friend.', 'en', {}).then(function (x) { resA = x; });
      A.s.inicia(); A.c.anda(100); var uA = A.s.falas[0]; A.s.termina(); await pA;
      ok('NV1 uma fala simples: usa a voz certa do idioma (Voz EN), a língua en-US e a velocidade pedida, e termina com "end"', resA === 'end' && uA.voice.name === 'Voz EN' && uA.lang === 'en-US' && uA.rate === 1 && uA.text === 'Hello there, my friend.', resA + ' ' + (uA.voice && uA.voice.name));
      var Av = motor({ velocidade: function () { return 1.5; } }); Av.m.falar('Oi, tudo bem com você hoje?', 'pt', {}); Av.s.inicia();
      ok('NV1b a velocidade efetiva (com a escala dos modos de treino) vai para a fala e o português usa a voz pt-BR', Av.s.falas[0].rate === 1.5 && Av.s.falas[0].voice.name === 'Voz PT' && Av.s.falas[0].lang === 'pt-BR');

      // NV2 fila à frente sem lacuna
      var B = motor(), prox = { text: 'Second sentence is here.', lang: 'en' }, resB = [];
      var pB1 = B.m.falar('First sentence is here.', 'en', { proxima: function () { return prox; } }).then(function (x) { resB.push(x); });
      B.s.inicia(); B.c.anda(100);
      var enfileirou = B.s.falas.length === 2 && B.s.falas[1].text === 'Second sentence is here.';
      B.s.termina(); await pB1; B.s.inicia();
      var pB2 = B.m.falar('Second sentence is here.', 'en', {}).then(function (x) { resB.push(x); });
      var semNovoSpeak = B.s.falas.length === 2, semCancelar = B.s.cancelamentos === 0; B.s.termina(); await pB2;
      ok('NV2 FILA À FRENTE: com a frase 1 tocando, a frase 2 já entra na fila do motor; ao chegar a vez dela o motor só assume os ganchos (nenhum speak novo, nenhum cancelamento) e as duas terminam com "end"', enfileirou && semNovoSpeak && semCancelar && resB.join() === 'end,end', 'falas=' + B.s.falas.length);
      var B2 = motor({ podeEnfileirar: function () { return false; } }); B2.m.falar('Training mode sentence one.', 'en', { proxima: function () { return prox; } }); B2.s.inicia(); B2.c.anda(100);
      ok('NV2b nos modos de treino (podeEnfileirar falso) a fila à frente fica desligada', B2.s.falas.length === 1);
      var B3 = motor(); B3.m.falar('Sentence A is long enough.', 'en', { proxima: function () { return prox; } }); B3.s.inicia(); B3.c.anda(100);
      var antes3 = B3.s.cancelamentos; B3.m.falar('Another sentence entirely different.', 'en', {});
      ok('NV2c se sobrou frase enfileirada que NÃO é a pedida (o fluxo mudou), a fila é limpa antes de falar', antes3 === 0 && B3.s.cancelamentos === 1);
      await tique();

      // NV3 vigia de partida
      var C = motor(), resC = []; C.m.falar('The engine swallows this one.', 'en', {}).then(function (x) { resC.push(x); });
      C.c.anda(7100); await tique(); await tique(); C.m.falar('The engine swallows this one.', 'en', {}).then(function (x) { resC.push(x); }); C.c.anda(7100); await tique(); await tique();
      ok('NV3 VIGIA DE PARTIDA: o motor engoliu o speak(): a 1ª vez devolve "restart" (tenta de novo); se a mesma frase repetir, devolve "error" (pula)', resC.join() === 'restart,error', resC.join());

      // NV4 estimativa de tempo sem evento de palavra, e evento de palavra
      var D = motor(), tx4 = 'This is a rather long sentence, with commas, so the estimate has work to do.', pos4 = [];
      D.m.falar(tx4, 'en', { aoProgresso: function (ci) { pos4.push(ci); } }); D.s.inicia(); D.c.anda(2500);
      var cresce = pos4.length > 5 && pos4.every(function (x, i) { return i === 0 || x >= pos4[i - 1]; });
      ok('NV4 sem evento de palavra, o destaque avança só por estimativa de tempo: muitas posições, nunca voltando atrás, dentro do texto', cresce && pos4[pos4.length - 1] < tx4.length && pos4[pos4.length - 1] > 10, pos4.length + ' posições, última ' + pos4[pos4.length - 1]);
      var E = motor(), tx5 = 'Word one, word two, word three and then word four goes here.', pos5 = [];
      E.m.falar(tx5, 'en', { aoProgresso: function (ci) { pos5.push(ci); } }); E.s.inicia(); E.s.palavra(5); E.c.anda(60); var n5 = pos5.length; E.s.palavra(10);
      ok('NV4b quando a voz informa a palavra, o evento manda: vira posição na hora, e a estimativa não corre à frente dele enquanto o evento está em dia', pos5[0] === 5 && n5 === 1 && pos5[1] === 10, pos5.join());

      // NV5 reiniciar e voz que emudece
      var F = motor(), resF = null, pF = F.m.falar('Restart this sentence please.', 'en', {}).then(function (x) { resF = x; }); F.s.inicia(); F.m.reiniciar(); await pF;
      ok('NV5 reiniciar() faz a fala em curso terminar com "restart"', resF === 'restart', String(resF));
      var F2 = motor(), r2 = null; F2.m.falar('Another sentence for later.', 'en', {}); F2.m.reiniciar(); F2.m.cancelar(); await tique(); await tique();
      F2.m.falar('Plain sentence after.', 'en', {}).then(function (x) { r2 = x; }); F2.s.inicia(); F2.s.termina(); await tique();
      ok('NV5b cancelar() zera o pedido de reinício: a fala seguinte termina com "end", não com "restart"', r2 === 'end', String(r2));
      var G = motor(), resG = null; G.m.falar('Short one that dies silently.', 'en', {}).then(function (x) { resG = x; }); G.s.inicia(); G.c.anda(20000); await tique(); await tique();
      ok('NV5c VIGIA DA VOZ MUDA: a voz começou e emudeceu (sem evento): passado o limite o motor cancela sozinho e a frase termina como "cancel", para a leitura seguir', resG === 'cancel' && G.s.cancelamentos >= 1, String(resG));

      // ----- Narrador, com voz e fonte falsas -----
      function fonteFalsa(par, extra) {
        var f = { audio: 'en', orig: 'en', idiomaOriginal: 'en', paragrafos: function () { return par.length; }, frases: function (p) { return par[p].length; }, idiomaAudio: function () { return f.audio; },
          texto: async function (p, s, id, ativo) { await tique(); if (!ativo()) return null; var x = par[p][s]; return { text: x, lang: id === f.orig ? id : (f.traduz ? id : f.orig) }; },
          jaPronta: function (p, s, id) { var x = par[p][s]; return x == null ? null : { text: x, lang: f.orig }; } };
        return Object.assign(f, extra || {});
      }
      function vozFalsa() { var v = { chamadas: [], pendente: null, cancelamentos: 0, reinicios: 0, tipo: 'falsa' };
        v.falar = function (t, id, op) { v.chamadas.push({ t: t, id: id, op: op }); return new Promise(function (res) { v.pendente = res; }); };
        v.cancelar = function () { v.cancelamentos++; var p = v.pendente; v.pendente = null; if (p) p('cancel'); };
        v.reiniciar = function () { v.reinicios++; var p = v.pendente; v.pendente = null; if (p) p('restart'); };
        v.fim = function (r) { var p = v.pendente; v.pendente = null; if (p) p(r || 'end'); };
        return v; }
      function gravaEventos() { var lista = []; ['narracao-frase', 'narracao-palavra', 'narracao-estado', 'narracao-parou', 'narracao-retomou', 'frase-ouvida'].forEach(function (n) { EV.on(n, function (d) { lista.push(n + (d ? ':' + JSON.stringify(d) : '')); }); }); return lista; }
      var P1 = [['One is here.', 'Two is here.'], ['Three is here.']];

      // NA1 sequência, eventos, palavras ouvidas
      var ev1 = gravaEventos(), v1 = vozFalsa(), n1 = NA.criar({ voz: v1 }); n1.abrir(fonteFalsa(P1)); n1.tocar(0, 0);
      await ate(function () { return v1.chamadas.length === 1; }); v1.fim(); await ate(function () { return v1.chamadas.length === 2; }); v1.fim('cancel'); await ate(function () { return v1.chamadas.length === 3; }); v1.fim();
      await ate(function () { return !n1.estado().tocando; });
      var ouvidas1 = ev1.filter(function (e) { return e.indexOf('frase-ouvida') === 0; }), estados1 = ev1.filter(function (e) { return e.indexOf('narracao-estado') === 0; });
      ok('NA1 SEQUÊNCIA: fala as 3 frases em ordem, atravessando o parágrafo; palavras ouvidas só contam quando a frase termina bem ("end", não "cancel"); ao fim a narração para sozinha avisando tocando:true e depois tocando:false', v1.chamadas.map(function (x) { return x.t; }).join('|') === 'One is here.|Two is here.|Three is here.' && ouvidas1.length === 2 && ouvidas1[0].indexOf('"palavras":3') > 0 && !n1.estado().tocando && estados1.join() === 'narracao-estado:{"tocando":true},narracao-estado:{"tocando":false}', ouvidas1.join(' '));
      ok('NA1b cada frase avisa "narracao-frase" com o texto e o idioma falados, e a voz recebe a frase seguinte já pronta para a fila à frente (e nada depois da última)', ev1.indexOf('narracao-frase:{"p":0,"s":0,"texto":"One is here.","idioma":"en"}') >= 0 && v1.chamadas[0].op.proxima().text === 'Two is here.' && v1.chamadas[1].op.proxima().text === 'Three is here.' && v1.chamadas[2].op.proxima() === null);

      // NA2 token: eventos atrasados de fala antiga não mexem na nova
      var ev2 = gravaEventos(), v2 = vozFalsa(), n2 = NA.criar({ voz: v2 }); n2.abrir(fonteFalsa(P1)); n2.tocar(0, 0); await ate(function () { return v2.chamadas.length === 1; });
      var op0 = v2.chamadas[0].op; n2.tocar(1, 0); await ate(function () { return v2.chamadas.length === 2; }); var antes2 = ev2.length; op0.aoProgresso(3); v2.chamadas[1].op.aoProgresso(4);
      var palavras2 = ev2.slice(antes2).filter(function (e) { return e.indexOf('narracao-palavra') === 0; });
      ok('NA2 TOKEN: depois de pular para outra frase, um evento de palavra atrasado da fala antiga é ignorado e o da nova passa', palavras2.length === 1 && palavras2[0].indexOf('"ci":4') > 0, palavras2.join());
      n2.parar(); await tique();
      ok('NA2b parar() cancela a voz e a narração fica parada, sem avançar para a próxima frase', !n2.estado().tocando && v2.cancelamentos >= 2 && v2.chamadas.length === 2);

      // NA3 retomar da palavra
      var v3 = vozFalsa(), n3 = NA.criar({ voz: v3 }); n3.abrir(fonteFalsa([['The merchant spoke about laborious diligence today.']])); n3.tocar(0, 0); await ate(function () { return v3.chamadas.length === 1; });
      v3.chamadas[0].op.aoProgresso(17); n3.reiniciar(); await ate(function () { return v3.chamadas.length === 2; });
      var ev3 = gravaEventos(); v3.chamadas[1].op.aoProgresso(5);
      ok('NA3 RETOMA DA PALAVRA: trocar velocidade/voz no meio recomeça da palavra que estava sendo falada ("spoke about laborious…"), nunca do começo; a posição reportada continua contando no texto inteiro (5 na fala cortada = 18 no texto)', v3.reinicios === 1 && v3.chamadas[1].t === 'spoke about laborious diligence today.' && v3.chamadas[0].t.indexOf('The merchant') === 0 && ev3.some(function (e) { return e.indexOf('"ci":18') > 0; }), v3.chamadas[1].t + ' | ' + ev3.join());
      n3.parar();

      // NA4 pular sem letra e parar após erros
      var v4 = vozFalsa(), n4 = NA.criar({ voz: v4 }); n4.abrir(fonteFalsa([['...', 'Real sentence here.', '123']])); n4.tocar(0, 0);
      await ate(function () { return v4.chamadas.length === 1; }); v4.fim(); await ate(function () { return v4.chamadas.length === 2; }); v4.fim(); await ate(function () { return !n4.estado().tocando; });
      ok('NA4 PULA O QUE NÃO É FALA: frase sem letra nem número ("...") é ignorada; número ("123") é falado', v4.chamadas.map(function (x) { return x.t; }).join('|') === 'Real sentence here.|123', v4.chamadas.map(function (x) { return x.t; }).join('|'));
      var v5 = vozFalsa(), n5b = NA.criar({ voz: v5 }); n5b.abrir(fonteFalsa([['A one is here.', 'A two is here.', 'A three is here.', 'A four is here.', 'A five is here.', 'A six is here.']])); n5b.tocar(0, 0);
      for (var e5 = 1; e5 <= 5; e5++) { await ate(function () { return v5.chamadas.length === e5 || !n5b.estado().tocando; }); if (v5.pendente) v5.fim('error'); }
      await ate(function () { return !n5b.estado().tocando; });
      ok('NA4b PARA APÓS OS ERROS: depois do 4º erro a narração para sozinha (não fica tentando para sempre)', !n5b.estado().tocando && v5.chamadas.length === 4, 'falas=' + v5.chamadas.length);

      // NA5 passo
      var m0b = NA.criar({ voz: vozFalsa() }); m0b.abrir(fonteFalsa(P1)); m0b.passo(1); var cb = m0b.estado().marca; m0b.passo(1); var cc = m0b.estado().marca; m0b.passo(1); var cd = m0b.estado().marca; m0b.passo(-1); m0b.passo(-1); m0b.passo(-1); var cf = m0b.estado().marca;
      ok('NA5 PASSO PARADO: as setas só movem a marca (nada é falado): (0,0)→(0,1)→(1,0); no fim do livro fica onde estava; voltando atravessa o parágrafo e para no começo', cb.p === 0 && cb.s === 1 && cc.p === 1 && cc.s === 0 && cd.p === 1 && cd.s === 0 && cf.p === 0 && cf.s === 0, JSON.stringify([cb, cc, cd, cf]));
      var v7 = vozFalsa(), n7 = NA.criar({ voz: v7 }); n7.abrir(fonteFalsa(P1)); n7.tocar(0, 0); await ate(function () { return v7.chamadas.length === 1; }); n7.passo(1); await ate(function () { return v7.chamadas.length === 2; });
      ok('NA5b passo TOCANDO: a voz segue da nova frase (a anterior é cancelada)', v7.chamadas[1].t === 'Two is here.' && v7.cancelamentos >= 2);
      n7.parar();

      // NA6 idioma do áudio diferente do idioma do livro; sem tradução cai no original e a voz acompanha
      var v8 = vozFalsa(), f8 = fonteFalsa([['The merchant works.']], { audio: 'pt', traduz: false }), n8 = NA.criar({ voz: v8 }); n8.abrir(f8); n8.tocar(0, 0); await ate(function () { return v8.chamadas.length === 1; });
      ok('NA6 pedido de áudio em português SEM tradução disponível: fala o original e a voz acompanha o idioma do texto realmente falado (en), não o pedido (pt)', v8.chamadas[0].id === 'en' && v8.chamadas[0].t === 'The merchant works.', v8.chamadas[0].id); n8.parar();

      // NA7 gancho de treino
      var v9 = vozFalsa(), repeticoes = 0, n9 = NA.criar({ voz: v9, ganchos: { aoTerminarFrase: async function () { return (repeticoes++ < 1) ? 'repeat' : undefined; } } }); n9.abrir(fonteFalsa([['Only sentence here.', 'Next sentence here.']])); n9.tocar(0, 0);
      await ate(function () { return v9.chamadas.length === 1; }); v9.fim(); await ate(function () { return v9.chamadas.length === 2; }); v9.fim(); await ate(function () { return v9.chamadas.length === 3; });
      ok('NA7 GANCHO DE TREINO: depois da frase o gancho pode pedir "repetir": a mesma frase é falada de novo antes de seguir', v9.chamadas.map(function (x) { return x.t; }).join('|') === 'Only sentence here.|Only sentence here.|Next sentence here.', v9.chamadas.map(function (x) { return x.t; }).join('|')); n9.parar();

      // NA8 tradução que chega depois de parar não fala; NA9 sem fonte
      var v10 = vozFalsa(), lenta = null, f10 = fonteFalsa([['Slow translation here.']], { texto: function (p, s, id, ativo) { return new Promise(function (res) { lenta = function () { res(ativo() ? { text: 'Slow translation here.', lang: 'en' } : null); }; }); } }), n10 = NA.criar({ voz: v10 });
      n10.abrir(f10); n10.tocar(0, 0); await tique(); n10.parar(); lenta(); await tique(); await tique();
      ok('NA8 TOKEN NA TRADUÇÃO: se o aluno parou enquanto a tradução da frase ainda chegava, a frase não é falada depois', v10.chamadas.length === 0 && !n10.estado().tocando);
      ok('NA9 sem fonte aberta, tocar(), passo() e parar() não fazem nada nem quebram', (function () { var nn = NA.criar({ voz: vozFalsa() }); nn.tocar(); nn.passo(1); nn.parar(); return !nn.estado().tocando; })());

      // NA10 de ponta a ponta: Narrador + motor do navegador + synth falsa
      var K = motor(), n11 = NA.criar({ voz: K.m }); n11.abrir(fonteFalsa([['Frase um completa.', 'Frase dois completa.']])); n11.tocar(0, 0);
      await ate(function () { return K.s.falas.length >= 1; }); K.s.inicia(); await ate(function () { return K.s.falas.length === 2; }); var fila2 = K.s.falas[1] && K.s.falas[1].text; K.s.termina();
      await ate(function () { return K.s.falando === null && K.s.falas.length >= 2; }); K.s.inicia(); K.s.termina(); await ate(function () { return !n11.estado().tocando; });
      ok('NA10 DE PONTA A PONTA: o Narrador com o motor do navegador fala as duas frases, a 2ª já enfileirada enquanto a 1ª tocava (só 2 speak) e para sozinho no fim', fila2 === 'Frase dois completa.' && K.s.falas.length === 2 && !n11.estado().tocando, 'falas=' + K.s.falas.length + ' cancel=' + K.s.cancelamentos + ' tocando=' + n11.estado().tocando);

      // ===================== R2.3 · voz neural (Piper SIMULADO, áudio e relógio falsos) e composição =====================
      var NE = App.get('voz-neural');
      function piperFalso(modelos, modo) {
        var f = { predicoes: [], criadas: [], modo: modo || 'ok', modelos: modelos || ['en_US-lessac-medium', 'pt_BR-faber-medium'], carregou: 0 };
        f.fabrica = function () { f.carregou++; return Promise.resolve({ stored: async function () { return f.modelos; }, TtsSession: { create: async function (o) { f.criadas.push(o.voiceId); return { predict: async function (t) { await tique(); if (f.modo === 'falha') throw new Error('falha simulada'); f.predicoes.push(t); return { blob: t }; } }; } } }); };
        return f;
      }
      var audios = [];
      function AudioFalso(url) { this.url = url; this.duration = 2; this.currentTime = 0; this.playbackRate = 1; this.pausado = false; this.rejeita = false; audios.push(this); }
      AudioFalso.prototype.play = function () { var a = this; if (a.rejeita) return Promise.reject(new Error('bloqueado')); setTimeout(function () { if (a.onplay) a.onplay(); }, 0); return Promise.resolve(); };
      AudioFalso.prototype.pause = function () { this.pausado = true; };
      var PREFS_ON = { en: { on: true, voice: 'en_US-lessac-medium' }, pt: { on: false, voice: 'pt_BR-faber-medium' }, ready: { 'en_US-lessac-medium': true } };
      function neural(extra, prefs) { var c = relogioFalso(), p = piperFalso(), falhas = [], n = NE.criarNeural(Object.assign({ preferencias: function () { return prefs || PREFS_ON; }, fabrica: p.fabrica, Audio: AudioFalso, relogio: c, urlDe: function (b) { return 'blob:' + b.blob; }, revogar: function () {}, aoFalhar: function (i, e) { falhas.push(i + ':' + e.message); }, suportado: true }, extra || {})); return { n: n, c: c, p: p, falhas: falhas }; }
      async function ultimoAudio(antes) { await ate(function () { return audios.length > antes; }); return audios[audios.length - 1]; }

      // NN1 quando está ativa
      var N1x = neural({}, { en: { on: false, voice: 'x' }, pt: { on: true, voice: 'y' }, ready: { y: true } }), N1y = neural({}, { en: { on: true, voice: 'x' }, pt: { on: false, voice: 'y' }, ready: {} }), N1z = neural();
      ok('NN1 a voz neural só está ativa se estiver LIGADA e com o modelo BAIXADO (ligada sem modelo, ou desligada com modelo, não vale); voz de cada idioma separada', N1x.n.ativa('en') === false && N1x.n.ativa('pt') === true && N1y.n.ativa('en') === false && N1z.n.ativa('en') === true && N1z.n.ativa('pt') === false);

      // NN2 fala, progresso, fim, velocidade
      var N2 = neural({ velocidade: function () { return 1.25; } }), tx2 = 'Algorithms decide what we read, and nobody explains how.', pos2 = [], res2 = null, a0 = audios.length;
      var p2 = N2.n.falar(tx2, 'en', { aoProgresso: function (ci, len) { pos2.push([ci, len]); } }).then(function (x) { res2 = x; });
      var au2 = await ultimoAudio(a0); await tique(); au2.currentTime = 0.5; N2.c.anda(100); au2.currentTime = 1.0; N2.c.anda(100); au2.currentTime = 1.9; N2.c.anda(100); au2.onended(); await p2;
      var cresce2 = pos2.length >= 3 && pos2.every(function (x, i) { return i === 0 || x[0] >= pos2[i - 1][0]; }) && pos2.every(function (x) { return x[1] === tx2.length && x[0] < tx2.length; });
      ok('NN2 fala com a voz neural: sintetiza o texto no modelo certo, toca o áudio na velocidade pedida (1,25×), acompanha a posição pela fração do áudio (crescente, dentro do texto) e termina com "end"', res2 === 'end' && N2.p.criadas.join() === 'en_US-lessac-medium' && N2.p.predicoes[0] === tx2 && au2.playbackRate === 1.25 && cresce2 && au2.url === 'blob:' + tx2, 'pos=' + pos2.map(function (x) { return x[0]; }).join(','));

      // NN3 cache e preparar à frente
      var N3 = neural(), a3 = audios.length; N3.n.preparar('Prepared sentence here.', 'en'); N3.n.preparar('Prepared sentence here.', 'en'); N3.n.preparar('...', 'en'); N3.n.preparar('Em português não ativo.', 'pt');
      await ate(function () { return N3.p.predicoes.length >= 1; }); var p3 = N3.n.falar('Prepared sentence here.', 'en', {}); var au3 = await ultimoAudio(a3); au3.onended(); await p3;
      ok('NN3 PREPARAR À FRENTE: a frase seguinte é sintetizada antes de tocar e o cache evita repetir (1 síntese para 3 pedidos); frase sem letra e idioma desligado não sintetizam; só 1 modelo foi carregado', N3.p.predicoes.length === 1 && N3.p.carregou === 1 && N3.p.criadas.length === 1, 'predições=' + N3.p.predicoes.length);

      // NN4 modelo ausente / falha de síntese -> fallback e desliga na sessão
      var N4 = neural(); N4.p.modelos = []; var r4 = await N4.n.falar('The model was removed from the browser.', 'en', {});
      ok('NN4 MODELO APAGADO do navegador: não baixa escondido; devolve "fallback" (a voz do navegador assume), avisa a tela e a voz neural fica desligada nesta sessão', r4 === 'fallback' && N4.falhas.length === 1 && /modelo ausente/.test(N4.falhas[0]) && N4.n.ativa('en') === false && N4.n.falhou('en') === true, r4 + ' ' + N4.falhas.join());
      var N5 = neural(); N5.p.modo = 'falha'; var r5 = await N5.n.falar('Synthesis will fail now.', 'en', {});
      ok('NN5 FALHA DE SÍNTESE: devolve "fallback" e desliga a voz neural na sessão', r5 === 'fallback' && N5.n.ativa('en') === false && N5.falhas.length === 1);
      var N6 = neural(), a6 = audios.length, p6 = N6.n.falar('Audio will error out.', 'en', {}); var au6 = await ultimoAudio(a6); await tique(); au6.onerror(); var r6 = await p6;
      var N7b = neural(); var a7b = audios.length; AudioFalso.prototype.play = function () { return Promise.reject(new Error('bloqueado')); }; var r7b = await N7b.n.falar('Autoplay is blocked.', 'en', {}); AudioFalso.prototype.play = function () { var a = this; setTimeout(function () { if (a.onplay) a.onplay(); }, 0); return Promise.resolve(); };
      ok('NN6 erro no áudio ou navegador que bloqueia a reprodução: devolve "fallback" nos dois casos (nunca trava)', r6 === 'fallback' && r7b === 'fallback' && N6.n.ativa('en') === false, r6 + ' ' + r7b);

      // NN7 cancelar e reiniciar
      var N8 = neural(), a8 = audios.length, p8 = N8.n.falar('This will be cancelled midway.', 'en', {}); var au8 = await ultimoAudio(a8); await tique(); N8.n.cancelar(); var r8 = await p8;
      var N9 = neural(), p9 = N9.n.falar('Cancelled while still synthesising.', 'en', {}); N9.n.cancelar(); var r9 = await p9, a9 = audios.length; await tique(); await tique();
      ok('NN7 cancelar() para o áudio e devolve "cancel"; cancelar ainda durante a síntese também (e nada chega a tocar depois)', r8 === 'cancel' && au8.pausado === true && r9 === 'cancel' && audios.length === a9, r8 + ' ' + r9);
      var N10 = neural(), a10 = audios.length, p10 = N10.n.falar('This one will be restarted.', 'en', {}); var au10 = await ultimoAudio(a10); await tique(); N10.n.reiniciar(); var r10 = await p10;
      var a10b = audios.length, p10b = N10.n.falar('Next one is plain.', 'en', {}); var au10b = await ultimoAudio(a10b); await tique(); au10b.onended(); var r10b = await p10b;
      ok('NN8 reiniciar() faz a fala terminar com "restart" (o Narrador retoma da palavra) e o pedido não gruda na frase seguinte (que termina "end")', r10 === 'restart' && r10b === 'end', r10 + ' ' + r10b);

      // NN9 composição: neural quando ativa, navegador quando não ou quando cai
      function navFalso() { var v = { chamadas: [], cancel: 0, reinic: 0 }; v.falar = function (t, id) { v.chamadas.push(t + '|' + id); return Promise.resolve('end'); }; v.cancelar = function () { v.cancel++; }; v.reiniciar = function () { v.reinic++; }; return v; }
      var nvF = navFalso(), N11 = neural(), comp = NE.compor({ neural: N11.n, navegador: nvF }), a11 = audios.length, p11 = comp.falar('Neural voice speaks this.', 'en', {}); var au11 = await ultimoAudio(a11); await tique(); au11.onended(); var r11 = await p11;
      var r11b = await comp.falar('Esta é em português, neural desligada.', 'pt', {});
      N11.p.modo = 'falha'; var r11c = await comp.falar('Now the neural voice falls.', 'en', {});
      ok('NN9 COMPOSIÇÃO: neural fala quando ativa (o navegador não é chamado); idioma sem neural vai para o navegador; se a neural cair no meio do caminho, o navegador fala a MESMA frase ("fallback" nunca chega ao Narrador)', r11 === 'end' && r11b === 'end' && r11c === 'end' && nvF.chamadas.join() === 'Esta é em português, neural desligada.|pt,Now the neural voice falls.|en', nvF.chamadas.join());
      var nvG = navFalso(), N12 = neural(), comp2 = NE.compor({ neural: N12.n, navegador: nvG }); comp2.reiniciar(); comp2.cancelar();
      ok('NN9b o pedido de reinício vai só para o motor que está falando (por padrão o navegador) e o cancelamento vai para os dois', nvG.reinic === 1 && nvG.cancel === 1);

      // NN10 ponta a ponta: Narrador + voz composta + neural simulada
      var nvH = navFalso(), N13 = neural(), vozH = NE.compor({ neural: N13.n, navegador: nvH }), nH = NA.criar({ voz: vozH }); nH.abrir(fonteFalsa([['Neural one is long enough.', 'Neural two is long enough.']])); var a13 = audios.length; nH.tocar(0, 0);
      var auH1 = await ultimoAudio(a13); await tique(); auH1.onended(); await ate(function () { return audios.length > a13 + 1; }); var auH2 = audios[audios.length - 1]; await tique(); auH2.onended(); await ate(function () { return !nH.estado().tocando; });
      ok('NN10 DE PONTA A PONTA: o Narrador com a voz composta fala as duas frases pela voz neural (2 áudios, 2 sínteses, o navegador não é usado) e para sozinho', N13.p.predicoes.join('|') === 'Neural one is long enough.|Neural two is long enough.' && nvH.chamadas.length === 0 && !nH.estado().tocando, N13.p.predicoes.length + ' sínteses');
      App.get('armazem').ls.set(NE.CHAVE, { en: { on: true, voice: 'en_US-lessac-medium' }, ready: { 'en_US-lessac-medium': true } });
      var N14 = NE.criarNeural({ suportado: true });
      ok('NN11 sem preferências injetadas, lê as do armazém no mesmo formato do app de hoje (dd-ingles-neural): inglês ligado e baixado fica ativo, português (padrão) não', N14.ativa('en') === true && N14.ativa('pt') === false);
      App.get('armazem').ls.set(NE.CHAVE, null);

      // ===================== R2.4 · PARIDADE com o app de hoje (ingles.js), lado a lado, com o MESMO motor de fala falso =====================
      // O app de hoje roda numa moldura (../ingles.html); o Narrador novo roda aqui. Os dois recebem o mesmo texto e falam num motor de fala
      // idêntico (fila, fim da fala, eventos de palavra, erro). Compara-se o que o aluno ouviria: a sequência de falas (texto, idioma,
      // velocidade, se entrou na fila à frente) e os eventos de frase e de palavras ouvidas.
      var legF = document.createElement('iframe'); legF.src = '../ingles.html'; legF.style.cssText = 'position:fixed;left:-9999px;width:900px;height:600px'; document.body.appendChild(legF);
      await until(function () { return legF.contentWindow && legF.contentWindow.DDLab && legF.contentWindow.DDLab.addText; });
      var LW = legF.contentWindow, LD = LW.DDLab, H = { m: null }, COL = { pecas: [], ouvidas: 0 };
      LW.DD_TRANSLATOR_FACTORY = function (a, b) { return { translate: async function (t) { await wait(2); return '[' + b + '] ' + t; } }; };
      function criarMotor(cfg) {
        var m = { log: [], fila: [], atual: null, cfg: cfg || {} };
        function iniciar() {
          if (m.atual || !m.fila.length) return; var u = m.fila.shift(); m.atual = u;
          setTimeout(function () {
            if (m.atual !== u) return; if (u.onstart) u.onstart();
            var ws = [], re = /\S+/g, x, dur = m.cfg.dur || 120;
            if (m.cfg.palavras) { while ((x = re.exec(u.text))) ws.push(x.index); ws.forEach(function (ci, k) { setTimeout(function () { if (m.atual === u && u.onboundary) u.onboundary({ name: 'word', charIndex: ci }); }, 20 + k * m.cfg.palavras); }); dur = 20 + ws.length * m.cfg.palavras + 20; }
            setTimeout(function () { if (m.atual !== u) return; m.atual = null; if ((m.cfg.erros || []).indexOf(u.__n) >= 0) { if (u.onerror) u.onerror({ error: 'synthesis-failed' }); } else if (u.onend) u.onend(); iniciar(); }, dur);
          }, 0);
        }
        m.speak = function (u) { u.__n = m.log.length; m.log.push({ text: u.text, lang: u.lang, rate: u.rate, fila: !!(m.atual || m.fila.length) }); m.fila.push(u); iniciar(); };
        m.cancel = function () { var tudo = (m.atual ? [m.atual] : []).concat(m.fila); m.atual = null; m.fila = []; setTimeout(function () { tudo.forEach(function (u) { if (u.onerror) u.onerror({ error: 'canceled' }); }); }, 0); };
        return m;
      }
      H.m = criarMotor({});
      var SS = LW.speechSynthesis;
      Object.defineProperty(SS, 'speak', { configurable: true, value: function (u) { H.m.speak(u); } });
      Object.defineProperty(SS, 'cancel', { configurable: true, value: function () { H.m.cancel(); } });
      Object.defineProperty(SS, 'getVoices', { configurable: true, value: function () { return []; } });
      Object.defineProperty(SS, 'speaking', { configurable: true, get: function () { return !!(H.m.atual || H.m.fila.length); } });
      Object.defineProperty(SS, 'pending', { configurable: true, get: function () { return H.m.fila.length > 0; } });
      LD.on('piece', function (e) { COL.pecas.push(e.p + '.' + e.s + '.' + e.lang + '.' + e.text); });
      LD.on('heard', function (e) { COL.ouvidas += e.words; });
      LW.postMessage({ type: 'readlang', value: 'en' }, '*'); LW.postMessage({ type: 'audiolang', value: 'en' }, '*'); await wait(300);
      var errAdd = ''; try { await LD.addText('Paridade', 'Algorithms decide what we read and what we buy. They shape our choices every day. Nobody explains how they work, and few people ask.\n\nUnderstanding that fact is the first step towards resisting it. The people who build these systems are rarely asked to explain them.'); } catch (e) { errAdd = String(e); }
      await until(function () { return LD.doc && LD.doc.title === 'Paridade' && LD.doc.paras.length >= 2; }, 20000);

      var PARAS = LD.doc ? LD.doc.paras.map(function (p) { return p.s.slice(); }) : [];
      ok('PA0 o app de hoje carrega na moldura com o documento de teste (2 parágrafos, 5 frases) e o motor de fala falso instalado', PARAS.length === 2 && PARAS[0].length + PARAS[1].length === 5, JSON.stringify(PARAS.map(function (p) { return p.length; })));

      async function rodar(lado, cenario) {
        var motor = criarMotor(cenario.cfg); H.m = motor; COL.pecas = []; COL.ouvidas = 0;
        var api;
        if (lado === 'hoje') {
          LD.stopTts(); LD.tts.cursor = null; LD.state.rate = 1; LW.postMessage({ type: 'audiolang', value: cenario.audio || 'en' }, '*'); await wait(150);
          api = { tocar: function (p, s) { LD.startTts(p, s); }, parar: function () { LD.stopTts(); }, passo: function (d) { LD.stepSentence(d); }, taxa: function (v) { LD.setRate(v); }, tocando: function () { return LD.tts.playing; } };
        } else {
          var taxa = 1, ev = App.get('eventos'), pecas = [], ouv = 0;
          var offs = [ev.on('narracao-frase', function (e) { if (e.texto != null) COL.pecas.push(e.p + '.' + e.s + '.' + e.idioma + '.' + e.texto); }), ev.on('frase-ouvida', function (e) { COL.ouvidas += e.palavras; })];
          var audio = cenario.audio || 'en';
          var fonte = { idiomaOriginal: 'en', paragrafos: function () { return PARAS.length; }, frases: function (p) { return PARAS[p].length; }, idiomaAudio: function () { return audio; },
            texto: async function (p, s, id, ativo) { if (id === 'en') return { text: PARAS[p][s], lang: 'en' }; await wait(2); return ativo() ? { text: '[' + id + '] ' + PARAS[p][s], lang: id } : null; },
            jaPronta: function (p, s, id) { return id === 'en' ? { text: PARAS[p][s], lang: 'en' } : null; } };
          var voz = VN.criar({ synth: { speak: motor.speak, cancel: motor.cancel, getVoices: function () { return []; }, get speaking() { return !!(motor.atual || motor.fila.length); }, get pending() { return motor.fila.length > 0; } }, Utterance: function (t) { this.text = t; }, velocidade: function () { return taxa; } });
          var nar = NA.criar({ voz: voz }); nar.abrir(fonte);
          api = { tocar: function (p, s) { nar.tocar(p, s); }, parar: function () { nar.parar(); }, passo: function (d) { nar.passo(d); }, taxa: function (v) { taxa = v; nar.reiniciar(); }, tocando: function () { return nar.estado().tocando; }, fim: function () { offs.forEach(function (f) { f(); }); nar.fechar(); } };
        }
        await cenario.rodar(api, motor);
        await wait(400);
        if (api.fim) api.fim(); else LD.stopTts();
        await wait(150);
        return { falas: motor.log.map(function (x) { return (cenario.semFila ? [x.text, x.lang, x.rate] : [x.text, x.lang, x.rate, x.fila]).join('~'); }), pecas: COL.pecas.slice(), ouvidas: COL.ouvidas };
      }
      async function ateM(motor, n, ms) { return until(function () { return motor.log.length >= n; }, ms || 8000); }
      var CEN = {
        corrida: { cfg: { dur: 120 }, rodar: async function (a, m) { a.tocar(0, 0); await until(function () { return !a.tocando(); }, 30000); } },
        parar: { cfg: { palavras: 25 }, rodar: async function (a, m) { a.tocar(0, 0); await ateM(m, 2); await wait(60); a.parar(); } },
        passo: { cfg: { dur: 300 }, rodar: async function (a, m) { a.tocar(0, 0); await ateM(m, 1); a.passo(1); await ateM(m, 3); await wait(50); a.parar(); } },
        velocidade: { cfg: { palavras: 25 }, rodar: async function (a, m) { a.tocar(0, 0); await ateM(m, 1); await wait(85); a.taxa(1.5); await ateM(m, 3); await wait(50); a.parar(); } },
        traduzido: { cfg: { dur: 100 }, audio: 'pt', semFila: true, rodar: async function (a, m) { a.tocar(0, 0); await until(function () { return !a.tocando(); }, 30000); } },
        erros: { cfg: { dur: 80, erros: [1, 2, 3, 4] }, rodar: async function (a, m) { a.tocar(0, 0); await until(function () { return !a.tocando(); }, 30000); } }
      };
      var DESCR = { corrida: 'leitura inteira até o fim (com fila à frente)', parar: 'parar no meio, com eventos de palavra', passo: 'passo para a frase seguinte tocando', velocidade: 'trocar a velocidade no meio da frase (retoma da palavra)', traduzido: 'áudio em português com tradução por frase', erros: 'quatro erros de voz seguidos' };
      var resP = {};
      for (var nomeC of ['corrida', 'parar', 'passo', 'velocidade', 'traduzido', 'erros']) {
        var rh = await rodar('hoje', CEN[nomeC]), rn = await rodar('novo', CEN[nomeC]);
        resP[nomeC] = { hoje: rh, novo: rn };
        var iguais = JSON.stringify(rh) === JSON.stringify(rn);
        ok('PA-' + nomeC + ' PARIDADE · ' + DESCR[nomeC] + ': o Narrador novo faz EXATAMENTE a sequência de falas, de frases e de palavras ouvidas do app de hoje', iguais && rh.falas.length >= 1, 'falas hoje=' + rh.falas.length + ' novo=' + rn.falas.length + ' ouvidas ' + rh.ouvidas + '/' + rn.ouvidas + (iguais ? '' : ' | HOJE ' + rh.falas.map(function (f) { return f.slice(0, 22); }).join(' ; ') + ' | NOVO ' + rn.falas.map(function (f) { return f.slice(0, 22); }).join(' ; ')));
      }
      ok('PA-sanidade os cenários realmente exercitam o que dizem: a corrida fala as 5 frases e a segunda já entra na fila; a velocidade muda para 1,5 e retoma no meio da frase; os erros param após 5 falas (1 boa e 4 com erro); o áudio em português fala a tradução', resP.corrida.hoje.falas.length === 5 && /~true$/.test(resP.corrida.hoje.falas[1]) && resP.velocidade.hoje.falas.some(function (f) { return /~1.5/.test(f); }) && resP.velocidade.hoje.falas.some(function (f) { return f.split('~')[0].length < PARAS[0][0].length && /~1.5/.test(f); }) && resP.erros.hoje.falas.length === 5 && /^\[pt\] /.test(resP.traduzido.hoje.falas[0]), 'corrida=' + resP.corrida.hoje.falas.length + ' erros=' + resP.erros.hoje.falas.length);
    } catch (e) { fails++; out.push('FAIL exceção: ' + e + ' ' + (e && e.stack ? e.stack.split('\n')[1] : '')); }
    out.push('RESULTADO: ' + (fails ? fails + ' falha(s)' : 'tudo certo'));
    live(); clearInterval(hb);
  });
})();
</script>
'@

$html = [IO.File]::ReadAllText("$tmp\novo\index.html", $enc)
$html = $html -replace '(?i)</body>', ($test + '</body>')
$testFile = "$tmp\novo\__test.html"
[IO.File]::WriteAllText($testFile, $html, $enc)
$prof = Join-Path $tmp 'profile'
$outFile = Join-Path $tmp 'out.txt'
Start-Process -FilePath $Chrome -ArgumentList @('--headless=new', '--disable-gpu', '--no-first-run', "--user-data-dir=`"$prof`"",
    '--window-size=1200,900', '--virtual-time-budget=4200000', '--allow-file-access-from-files', '--dump-dom',
    "`"file:///$($testFile.Replace('\','/'))`"") -Wait -NoNewWindow -RedirectStandardOutput $outFile -RedirectStandardError "$tmp\err.txt"
$dom = [IO.File]::ReadAllText($outFile)
$m = [regex]::Match($dom, '(?s)<pre id="result"[^>]*>(.*?)</pre>')
if (-not $m.Success) { 'Teste não produziu resultado. Erros do Chrome:'; Get-Content "$tmp\err.txt" -TotalCount 15; exit 2 }
[System.Net.WebUtility]::HtmlDecode($m.Groups[1].Value)
Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
if ($m.Groups[1].Value -match 'FAIL') { exit 1 }
exit 0
