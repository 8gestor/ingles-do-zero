<#
  test_novo_narrador.ps1 — confere, no Chrome, o Narrador do app novo (site/novo/assets/js/narrador/; fase R2; ver docs/10-r2-narrador.md).

  R2.1 (ritmo e vozes). A prova é feita de duas formas, as duas SEM relógio real nem fala real (por isso não sofrem com a carga da máquina):
    · ORÁCULO: uma cópia LITERAL do código antigo (`ingles.js`, linhas 667–680 e 736–757) roda ao lado do módulo novo, com centenas de entradas
      aleatórias (semente fixa); o resultado tem de ser idêntico.
    · SIMULAÇÃO de voz: os cenários do `test_sync.ps1` do livro (voz lenta e voz rápida, SEM evento de palavra) com o tempo SIMULADO; mede o erro
      entre a palavra destacada pela estimativa e a palavra realmente falada. Critério herdado: erro médio <= 1,5 palavra.
  NR1 tempo acumulado · NR2 posição estimada · NR3 aprendizado da velocidade por idioma e voz · NR4 escolha da voz · NR5 ordenação do menu de vozes ·
  NR6 sincronia por estimativa (lenta e rápida, em 3 velocidades) · NR7 sem voltar atrás e chegando ao fim da frase
  R2.2 (voz do navegador e Narrador, com speechSynthesis e relógio FALSOS): NR8 token · NR9 fila à frente · NR10 retomar da palavra · NR11 estimativa e evento ·
  NR12 idioma do áudio · NR13 frases sem fala e erros · NR14 palavras ouvidas · NR15 setas · NR16 treino e 0,1×–3× · NR17 vigias
  R2.3 (voz neural com Piper SIMULADO e composição): NR18 quando a neural vale · NR19 áudio e posição · NR20 fila única e cache · NR21 cancelar · NR22 falhas e fallback ·
  NR23 carga preguiçosa · NR24 voz composta (neural + navegador, recomeço) · NR25 Narrador com neural (ordem da síntese, retomar da palavra)
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
      ok('NR0 o app liga com os módulos ritmo e vozes prontos', rel.ok === true && App.tem('ritmo') && App.tem('vozes'), rel.modulos.filter(function (m) { return m.estado !== 'pronto'; }).map(function (m) { return m.nome + ':' + m.erro; }).join(' '));
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

      /* ======================= R2.2 · voz do navegador e laço do Narrador (relógio e speechSynthesis FALSOS) ======================= */
      ok('NR8a o app liga também com os módulos voz-navegador e narrador prontos', App.tem('voz-navegador') && App.tem('narrador'), '');
      var EVB = App.get('eventos'), VN = App.get('voz-navegador'), NA = App.get('narrador');
      async function flush() { for (var q = 0; q < 60; q++) await Promise.resolve(); }
      function Fala(t) { this.text = t; }
      function relogio() {
        var t = 0, id = 0, lista = [];
        var c = { agora: function () { return t; },
          setInterval: function (f, ms) { lista.push({ id: ++id, f: f, ms: ms, quando: t + ms, rep: true }); return id; },
          setTimeout: function (f, ms) { lista.push({ id: ++id, f: f, ms: ms, quando: t + ms, rep: false }); return id; },
          limpa: function (i) { lista = lista.filter(function (x) { return x.id !== i; }); },
          avanca: function (ms) { var fim = t + ms; for (;;) { var prox = lista.filter(function (x) { return x.quando <= fim; }).sort(function (a, b) { return a.quando - b.quando; })[0]; if (!prox) break; t = prox.quando; if (prox.rep) prox.quando += prox.ms; else lista = lista.filter(function (x) { return x !== prox; }); prox.f(); } t = fim; } };
        c.clearInterval = c.limpa; c.clearTimeout = c.limpa; return c;
      }
      function sintese(vozes) {                      // motor controlado à mão: nada começa nem termina sozinho; o cancelamento chega DEPOIS (como no navegador)
        var s = { speaking: false, pending: false, falas: [], fila: [], atual: null, getVoices: function () { return vozes || []; }, cancelamentos: 0 };
        s.speak = function (u) { s.falas.push(u); if (!s.atual) { s.atual = u; s.speaking = true; } else s.fila.push(u); s.pending = s.fila.length > 0; };
        s.cancel = function () { var tudo = [s.atual].concat(s.fila).filter(Boolean); s.atual = null; s.fila = []; s.speaking = false; s.pending = false; s.cancelamentos++; Promise.resolve().then(function () { tudo.forEach(function (u) { if (u.onerror) u.onerror({ error: 'canceled' }); }); }); };
        s.comecar = function () { if (s.atual && s.atual.onstart) s.atual.onstart(); };
        s.palavra = function (ci) { if (s.atual && s.atual.onboundary) s.atual.onboundary({ name: 'word', charIndex: ci }); };
        s.terminar = function () { var u = s.atual; s.atual = s.fila.shift() || null; s.speaking = !!s.atual; s.pending = s.fila.length > 0; if (u && u.onend) u.onend(); if (s.atual && s.atual.onstart) s.atual.onstart(); };
        s.falhar = function () { var u = s.atual; s.atual = s.fila.shift() || null; s.speaking = !!s.atual; if (u && u.onerror) u.onerror({ error: 'synthesis-failed' }); };
        return s;
      }
      var VOZES = [{ name: 'Voz PT', lang: 'pt-BR', localService: true }, { name: 'Voz EN', lang: 'en-US', localService: true }];
      function monta(paras, opc) {
        opc = opc || {};
        var rel = relogio(), sy = sintese(VOZES), est = { vel: 1, idioma: opc.idioma || 'en', escala: 1, modo: 'normal', depois: null }, antecipadas = [];
        var voz = VN.criar({ synth: sy, Utterance: Fala, agora: rel.agora, setInterval: rel.setInterval, clearInterval: rel.clearInterval, setTimeout: rel.setTimeout, clearTimeout: rel.clearTimeout, modoNormal: function () { return est.modo === 'normal'; } });
        function pronta(p, s, idioma) { if (idioma === 'en' || !opc.tr) return { text: paras[p][s], lang: 'en' }; var t = opc.tr[p] && opc.tr[p][s]; return t != null ? { text: t, lang: 'pt' } : { text: paras[p][s], lang: 'en' }; }
        var fonte = { paragrafos: function () { return paras.length; }, frases: function (p) { return paras[p].length; }, jaPronta: pronta,
          texto: async function (p, s, idioma, vale) { await Promise.resolve(); return vale() ? pronta(p, s, idioma) : null; }, antecipar: function (p, s) { antecipadas.push(p + ':' + s); } };
        var evs = [], offs = [];
        ['narracao-estado', 'narracao-frase', 'narracao-palavra', 'narracao-parou', 'narracao-retomou', 'frase-ouvida'].forEach(function (n) { offs.push(EVB.on(n, function (d) { evs.push({ n: n, d: d }); })); });
        var nar = NA.criar({ fonte: fonte, voz: voz, agora: rel.agora, velocidade: function () { return est.vel; }, idiomaAudio: function () { return est.idioma; },
          ganchos: { escala: function () { return est.escala; }, aoTerminarFrase: function (i) { return est.depois ? est.depois(i) : Promise.resolve(null); } } });
        return { rel: rel, sy: sy, est: est, nar: nar, evs: evs, antecipadas: antecipadas, voz: voz, fim: function () { nar.parar(); offs.forEach(function (o) { o(); }); },
          so: function (n) { return evs.filter(function (e) { return e.n === n; }); } };
      }
      async function inicia(m, p, s) { m.nar.tocar(p, s); await flush(); m.sy.comecar(); await flush(); }

      // ===== NR8 · cancelamento por token =====
      var m8 = monta([['One two three four five six.', 'Second sentence goes here now.']]);
      await inicia(m8, 0, 0); m8.sy.palavra(10); await flush();
      var u0 = m8.sy.atual, antes8 = m8.evs.length, palavrasAntes = m8.so('narracao-palavra').length;
      m8.nar.parar(); await flush(); var aposParar = m8.evs.length;
      u0.onboundary({ name: 'word', charIndex: 20 }); u0.onend(); await flush();
      var tardias = m8.evs.length === aposParar;
      m8.nar.tocar(0, 1); await flush(); var aposNova = m8.evs.length; u0.onboundary({ name: 'word', charIndex: 5 }); u0.onend(); await flush();
      ok('NR8 nenhum evento de uma fala antiga mexe na fala nova: depois de parar e de começar outra frase, eventos atrasados da fala velha (palavra e fim) são ignorados e o cursor não anda', tardias && m8.evs.length === aposNova && m8.nar.estado().cursor.s === 1 && m8.so('frase-ouvida').length === 0, 'eventos tardios=' + (m8.evs.length - aposNova));
      m8.fim();

      // ===== NR9 · fila à frente sem lacuna =====
      var P9 = [['First sentence is right here.', 'Second sentence follows it soon.', 'Third sentence ends the page.']];
      var m9 = monta(P9); await inicia(m9, 0, 0);
      var fila1 = m9.sy.falas.length === 2 && m9.sy.fila.length === 1 && m9.sy.fila[0].text === P9[0][1];
      m9.sy.terminar(); await flush();
      var noMeio = m9.nar.estado().cursor.s === 1 && m9.sy.falas.length === 3 && m9.sy.fila.length === 1 && m9.sy.fila[0].text === P9[0][2];
      m9.sy.terminar(); await flush();
      var cada = m9.sy.falas.map(function (u) { return u.text; }).join('|') === P9[0].join('|');
      var m9b = monta(P9); m9b.est.modo = 'treino'; await inicia(m9b, 0, 0);
      var m9c = monta(P9); await inicia(m9c, 0, 0); var tinhaFila = m9c.sy.fila.length === 1; m9c.nar.tocar(0, 2); await flush();
      var m9d = monta(P9); await inicia(m9d, 0, 0); m9d.est.vel = 2; m9d.sy.terminar(); await flush(); var trocou = m9d.sy.atual && m9d.sy.atual.text === P9[0][1] && m9d.sy.atual.rate === 2 && m9d.sy.fila.length === 0;
      ok('NR9 a frase seguinte entra na fila do motor enquanto a atual toca (cada frase é enviada uma única vez, na ordem); nos modos de treino NÃO há fila; ao mudar o fluxo (pulo, ou velocidade diferente da já enfileirada) a fila que sobrou é limpa', fila1 && noMeio && cada && m9b.sy.falas.length === 1 && tinhaFila && m9c.sy.fila.length === 0 && m9c.sy.atual.text === P9[0][2] && trocou, 'falas=' + m9.sy.falas.length + ' treino=' + m9b.sy.falas.length + ' apos pulo fila=' + m9c.sy.fila.length);
      m9.fim(); m9b.fim(); m9c.fim(); m9d.fim();

      // ===== NR10 · trocar velocidade no meio da frase retoma da palavra falada =====
      var T10 = 'alpha beta gamma delta epsilon zeta eta theta';
      var m10 = monta([[T10]]); await inicia(m10, 0, 0); m10.sy.palavra(17); await flush();
      m10.est.vel = 2; m10.nar.reiniciarFala(); await flush(); m10.sy.comecar(); await flush(); m10.sy.palavra(6); await flush();
      var ultima10 = m10.sy.falas[m10.sy.falas.length - 1], cis = m10.so('narracao-palavra').map(function (e) { return e.d.ci; }), nunca = cis.every(function (c, i) { return i === 0 || c >= cis[i - 1]; });
      ok('NR10 trocar a velocidade no meio da frase recomeça DA PALAVRA falada (não do começo): fala "delta epsilon…" a 2×, e o destaque continua de onde estava e nunca volta atrás', m10.sy.falas.length === 2 && ultima10.text === T10.slice(17) && ultima10.rate === 2 && nunca && cis[cis.length - 1] === 23 && m10.so('narracao-retomou').length === 1, JSON.stringify(cis) + ' | ' + ultima10.text);
      m10.fim();

      // ===== NR11 · destaque por estimativa (voz sem evento de palavra) e por evento =====
      var T11 = 'The merchant spoke slowly, and the whole town listened to him with great care.';
      var m11 = monta([[T11]]); await inicia(m11, 0, 0); var sec = R.modelo(T11).total / (17 * 1);
      for (var ms = 0; ms < sec * 1000 * 1.05; ms += 60) m11.rel.avanca(60);
      var c11 = m11.so('narracao-palavra').map(function (e) { return e.d.ci; });
      ok('NR11a sem evento de palavra o destaque avança pelo tempo estimado: cresce sem voltar atrás e chega perto do fim da frase', c11.length > 5 && c11.every(function (c, i) { return i === 0 || c >= c11[i - 1]; }) && c11[c11.length - 1] >= T11.length - 12, c11.length + ' marcas, última=' + c11[c11.length - 1] + ' de ' + T11.length);
      var m11b = monta([[T11]]); await inicia(m11b, 0, 0);
      [0, 4, 13, 20, 26].forEach(function (ci) { m11b.sy.palavra(ci); m11b.rel.avanca(120); });
      ok('NR11b com evento de palavra em dia (intervalo menor que 350 ms) a estimativa NÃO corre à frente: só os eventos da voz marcam a posição', m11b.so('narracao-palavra').length === 5, m11b.so('narracao-palavra').length + ' marcas para 5 eventos');
      m11.fim(); m11b.fim();

      // ===== NR12 · idioma do áudio diferente do livro =====
      var m12 = monta([['Hello world dear friend.']], { idioma: 'pt', tr: [['Olá mundo querido amigo.']] }); await inicia(m12, 0, 0);
      var fPt = m12.sy.falas[0], m12b = monta([['Hello world dear friend.']], { idioma: 'pt', tr: [[]] }); await inicia(m12b, 0, 0); var fEn = m12b.sy.falas[0];
      ok('NR12 áudio em português fala a TRADUÇÃO com a voz pt-BR; sem tradução cai para o original e a voz acompanha (en-US)', fPt.text === 'Olá mundo querido amigo.' && fPt.lang === 'pt-BR' && fPt.voice.name === 'Voz PT' && fEn.text === 'Hello world dear friend.' && fEn.lang === 'en-US' && fEn.voice.name === 'Voz EN', fPt.lang + ' / ' + fEn.lang);
      m12.fim(); m12b.fim();

      // ===== NR13 · frases sem fala e erros seguidos =====
      var m13 = monta([['...', '!!!', 'A real sentence is here.']]); await inicia(m13, 0, 0);
      var pulou = m13.sy.falas.length === 1 && m13.sy.falas[0].text === 'A real sentence is here.' && m13.so('narracao-frase').length === 3;
      var m13b = monta([['One sentence here.', 'Two sentences here.', 'Three sentences here.', 'Four sentences here.', 'Five sentences here.', 'Six sentences here.']]);
      m13b.nar.tocar(0, 0); await flush();
      for (var e13 = 0; e13 < 6 && m13b.nar.estado().tocando; e13++) { m13b.sy.falhar(); await flush(); }
      var ult = m13b.evs.filter(function (e) { return e.n === 'narracao-estado'; }).pop();
      ok('NR13 frase sem letra nem número é pulada (não vai à voz, mas a marca passa por ela); mais de 3 erros seguidos PARAM a narração', pulou && m13b.sy.falas.length === 4 && m13b.nar.estado().tocando === false && ult.d.tocando === false, 'falas até parar=' + m13b.sy.falas.length);
      m13.fim(); m13b.fim();

      // ===== NR14 · palavras ouvidas =====
      var m14 = monta([['One two three four five.', 'Another sentence to hear.']]); await inicia(m14, 0, 0);
      m14.nar.parar(); await flush(); var semOuvir = m14.so('frase-ouvida').length === 0;
      var m14b = monta([['One two three four five.', 'Another sentence to hear.']]); await inicia(m14b, 0, 0); m14b.sy.terminar(); await flush();
      var fo = m14b.so('frase-ouvida');
      ok('NR14 palavras ouvidas só contam quando a frase TERMINA bem (cancelada não conta), pelas palavras do texto falado: 5 palavras na primeira frase', semOuvir && fo.length === 1 && fo[0].d.palavras === 5 && fo[0].d.p === 0 && fo[0].d.s === 0, JSON.stringify(fo.map(function (e) { return e.d; })));
      m14.fim(); m14b.fim();

      // ===== NR15 · passo (setas) =====
      var P15 = [['A1 one here.', 'A2 two here.'], ['B1 three here.']];
      var m15 = monta(P15);
      var a = m15.nar.passo(1), mar1 = JSON.stringify(m15.nar.estado().marca), b = m15.nar.passo(1), mar2 = JSON.stringify(m15.nar.estado().marca), c = m15.nar.passo(1), mar3 = JSON.stringify(m15.nar.estado().marca), d = m15.nar.passo(-1), mar4 = JSON.stringify(m15.nar.estado().marca);
      var parado = a && b && !c && d && mar1 === '{"p":0,"s":1}' && mar2 === '{"p":1,"s":0}' && mar3 === mar2 && mar4 === '{"p":0,"s":1}' && m15.sy.falas.length === 0;
      var m15b = monta(P15); await inicia(m15b, 0, 0); m15b.nar.passo(1); await flush();
      ok('NR15 setas: parado, só a marca anda (atravessa parágrafos e para nas pontas, sem falar); tocando, a voz segue da frase nova', parado && m15b.sy.atual.text === 'A2 two here.' && m15b.nar.estado().tocando === true, mar1 + mar2 + mar3 + mar4 + ' | ' + (m15b.sy.atual && m15b.sy.atual.text));
      m15.fim(); m15b.fim();

      // ===== NR16 · ganchos de treino e velocidade 0,1× a 3× =====
      var P16 = [['Repeat this sentence now.', 'Then move on to this one.']];
      var m16 = monta(P16), rep = 0; m16.est.modo = 'treino'; m16.est.depois = function (i) { return Promise.resolve(i.s === 0 && rep++ === 0 ? 'repeat' : null); };
      await inicia(m16, 0, 0); m16.sy.terminar(); await flush(); m16.sy.comecar(); await flush(); m16.sy.terminar(); await flush();
      var txs = m16.sy.falas.map(function (u) { return u.text; });
      var m16b = monta(P16); m16b.est.escala = 0.5; m16b.est.vel = 1.2; await inicia(m16b, 0, 0);
      var vels = [], m16c;
      for (var vi = 0; vi < 2; vi++) { m16c = monta(P16); m16c.est.vel = [0.1, 3][vi]; m16c.nar.tocar(0, 0); await flush(); vels.push(m16c.sy.falas[0].rate); m16c.fim(); }
      ok('NR16 gancho de treino pede "repetir" (a mesma frase fala de novo antes de seguir); a escala de velocidade do treino multiplica a velocidade (1,2 × 0,5 = 0,6); 0,1× e 3× chegam à voz sem corte', txs[0] === P16[0][0] && txs[1] === P16[0][0] && txs[txs.length - 1] === P16[0][1] && Math.abs(m16b.sy.falas[0].rate - 0.6) < 1e-9 && vels[0] === 0.1 && vels[1] === 3, txs.length + ' falas; rate=' + m16b.sy.falas[0].rate + ' / ' + vels.join(','));
      m16.fim(); m16b.fim();

      // ===== NR17 · vigias =====
      var P17 = [['The first sentence is here.', 'The second sentence is here.', 'The third sentence is here.']];
      var m17 = monta(P17); m17.nar.tocar(0, 0); await flush(); m17.rel.avanca(7001); await flush();
      var tentou = m17.sy.falas.length === 2 && m17.sy.falas[1].text === P17[0][0];
      m17.rel.avanca(7001); await flush();
      var pulou17 = m17.sy.falas.length === 3 && m17.sy.falas[2].text === P17[0][1];
      var m17b = monta(P17); await inicia(m17b, 0, 0); m17b.rel.avanca(14000); await flush();
      var seguiu = m17b.sy.falas[m17b.sy.falas.length - 1].text === P17[0][1] && m17b.sy.cancelamentos >= 1;
      ok('NR17 vigia de partida: se o motor engole a fala, tenta a MESMA frase de novo uma vez (7 s) e, se repetir, segue para a próxima; vigia de mudez: voz que começou e calou é cancelada e a leitura segue', tentou && pulou17 && seguiu, 'falas=' + m17.sy.falas.length + ' / mudez seguiu=' + seguiu);
      m17.fim(); m17b.fim();

      /* ======================= R2.3 · voz neural (Piper SIMULADO) e composição das vozes ======================= */
      ok('NR18a o app liga também com os módulos voz-neural e voz prontos', App.tem('voz-neural') && App.tem('voz'), '');
      var VNE = App.get('voz-neural'), VZ = App.get('voz');
      function SomFalso(url) { this.url = url; this.duration = 10; this.currentTime = 0; this.tocando = false; SomFalso.todos.push(this); }
      SomFalso.todos = []; SomFalso.rejeita = false;
      SomFalso.prototype.play = function () { var s = this; return Promise.resolve().then(function () { if (SomFalso.rejeita) throw new Error('bloqueado'); s.tocando = true; if (s.onplay) s.onplay(); }); };
      SomFalso.prototype.pause = function () { this.tocando = false; };
      function montaN(opc) {
        opc = opc || {}; SomFalso.todos = []; SomFalso.rejeita = !!opc.rejeitaPlay;
        var rel = relogio(), st = { cargas: 0, criadas: [], predicts: [], emVoo: 0, maxEmVoo: 0, revogadas: [], urls: 0, falhas: [], ausentes: [] };
        var lib = { TtsSession: { create: async function (o) { st.criadas.push(o.voiceId); return { predict: async function (t) {
          if (opc.erro) throw new Error('boom'); st.emVoo++; st.maxEmVoo = Math.max(st.maxEmVoo, st.emVoo); st.predicts.push(t); await Promise.resolve(); await Promise.resolve(); st.emVoo--; return { texto: t }; } }; } } };
        if (!opc.semStored) lib.stored = async function () { return opc.guardados || ['v-en', 'v-pt']; };
        var est = { on: { en: opc.on !== false, pt: opc.on !== false }, prontas: opc.prontas || ['v-en', 'v-pt'], suportado: opc.suportado !== false };
        var neural = VNE.criar({ biblioteca: function () { st.cargas++; return Promise.resolve(lib); }, suportado: function () { return est.suportado; }, Audio: SomFalso,
          URL: { createObjectURL: function () { return 'blob:' + (++st.urls); }, revokeObjectURL: function (u) { st.revogadas.push(u); } },
          setInterval: rel.setInterval, clearInterval: rel.clearInterval, aoFalhar: function (i, e) { st.falhas.push(i); },
          prefs: { ativa: function (i) { return !!est.on[i]; }, voz: function (i) { return i === 'en' ? 'v-en' : 'v-pt'; }, pronta: function (id) { return est.prontas.indexOf(id) >= 0; }, ausente: function (id) { st.ausentes.push(id); } } });
        return { neural: neural, rel: rel, st: st, est: est };
      }
      var FR = 'Hello there my dear friend.';

      // ===== NR18 · quando a voz neural vale =====
      var n18 = montaN(), a1 = n18.neural.ativa('en'); n18.est.on.en = false; var a2 = n18.neural.ativa('en'); n18.est.on.en = true; n18.est.prontas = []; var a3 = n18.neural.ativa('en');
      n18.est.prontas = ['v-en']; n18.est.suportado = false; var a4 = n18.neural.ativa('en'); n18.est.suportado = true; var a5 = n18.neural.ativa('en'), a6 = n18.neural.ativa('pt');
      ok('NR18 a voz neural só vale no idioma com a opção ligada, o modelo baixado e o aparelho com suporte (por idioma: modelo do português ausente não afeta o inglês)', a1 && !a2 && !a3 && !a4 && a5 && !a6, [a1, a2, a3, a4, a5, a6].join(','));

      // ===== NR19 · falar: áudio na velocidade pedida e posição pela fração tocada =====
      var n19 = montaN(), prog = [], f19 = n19.neural.falar(FR, 'en', { velocidade: 1.5, aoProgresso: function (ci) { prog.push(ci); } }); await flush();
      var au = SomFalso.todos[0], m19 = R.modelo(FR);
      au.currentTime = 5; n19.rel.avanca(40); au.currentTime = 10; n19.rel.avanca(40); au.onended(); var r19 = await f19;
      ok('NR19 toca o áudio sintetizado na velocidade pedida (1,5×); a posição no texto acompanha a fração do áudio sobre o texto ponderado (mesma conta do ritmo); ao fim devolve "end"', !!au && au.playbackRate === 1.5 && r19 === 'end' && prog.length === 2 && prog[0] === R.caractereNoAlvo(m19, 0.5 * m19.total) && prog[1] >= prog[0] && prog[1] === R.caractereNoAlvo(m19, m19.total), JSON.stringify(prog) + ' ' + r19);

      // ===== NR20 · fila única e cache =====
      var n20 = montaN(); n20.neural.preparar('Frase um aqui.', 'en'); n20.neural.preparar('Frase dois aqui.', 'en'); n20.neural.preparar('Frase um aqui.', 'en'); n20.neural.preparar('...', 'en'); await flush();
      var so2 = n20.st.predicts.length === 2 && n20.st.maxEmVoo === 1;
      var n20b = montaN(); for (var k20 = 0; k20 < 33; k20++) n20b.neural.preparar('Frase numero ' + k20 + ' aqui.', 'en'); for (var f20 = 0; f20 < 12; f20++) await flush();
      ok('NR20 a síntese é UMA por vez (um modelo de cada vez); frase repetida usa o cache (não sintetiza de novo); sem letra não sintetiza; passando de 30 frases guardadas as mais antigas liberam o áudio', so2 && n20b.st.predicts.length === 33 && n20b.st.maxEmVoo === 1 && n20b.st.revogadas.length === 3, n20.st.predicts.length + ' sínteses; revogadas=' + n20b.st.revogadas.length);

      // ===== NR21 · cancelar =====
      var n21 = montaN(), p21 = n21.neural.falar(FR, 'en', {}); n21.neural.cancelar(); var c21 = await Promise.race([p21, wait(3000).then(function () { return 'travou'; })]);
      var n21b = montaN(), p21b = n21b.neural.falar(FR, 'en', {}); await flush(); var au21 = SomFalso.todos[0]; n21b.neural.cancelar(); var c21b = await Promise.race([p21b, wait(3000).then(function () { return 'travou'; })]); au21.onended();
      ok('NR21 cancelar durante a síntese ou durante o áudio devolve "cancel" (o áudio é pausado e um "fim" atrasado não muda nada)', c21 === 'cancel' && c21b === 'cancel' && au21.tocando === false && SomFalso.todos.length === 1, c21 + ' / ' + c21b);

      // ===== NR22 · falhas viram "fallback" e desligam só aquele idioma =====
      var n22 = montaN({ erro: true }), r22 = await n22.neural.falar(FR, 'en', {});
      var after = n22.neural.ativa('en'), pt22 = n22.neural.ativa('pt');
      var n22b = montaN(), q22 = n22b.neural.falar(FR, 'en', {}); await flush(); SomFalso.todos[0].onerror(); var r22b = await q22;
      var n22c = montaN({ rejeitaPlay: true }), r22c = await n22c.neural.falar(FR, 'en', {});
      var n22d = montaN({ guardados: [] }), r22d = await n22d.neural.falar(FR, 'en', {});
      ok('NR22 síntese que falha, erro de áudio, navegador que bloqueia o play e modelo apagado do navegador devolvem "fallback"; a tela é avisada; o idioma fica desligado na sessão (o outro não); modelo ausente é marcado como não baixado', r22 === 'fallback' && !after && pt22 && n22.st.falhas[0] === 'en' && r22b === 'fallback' && r22c === 'fallback' && r22d === 'fallback' && n22d.st.ausentes[0] === 'v-en', [r22, r22b, r22c, r22d].join(','));

      // ===== NR23 · biblioteca só carrega quando vai falar =====
      var n23 = montaN(); n23.neural.ativa('en'); n23.neural.preparar('...', 'en'); n23.neural.cancelar(); var zero = n23.st.cargas;
      var q23 = n23.neural.falar(FR, 'en', {}); await flush(); n23.neural.falar(FR, 'pt', {}); await flush();
      ok('NR23 a biblioteca (≈ 60 MB) NÃO é carregada enquanto nada vai ser falado; ao falar carrega uma vez só, e abre um modelo por voz (en e pt)', zero === 0 && n23.st.cargas === 1 && n23.st.criadas.join() === 'v-en,v-pt', 'cargas ' + zero + ' → ' + n23.st.cargas + ' · ' + n23.st.criadas.join());

      // ===== NR24 · composição neural + navegador =====
      function comp(opc) { var n = montaN(opc), sy = sintese(VOZES), nav = VN.criar({ synth: sy, Utterance: Fala, agora: n.rel.agora, setInterval: n.rel.setInterval, clearInterval: n.rel.clearInterval, setTimeout: n.rel.setTimeout, clearTimeout: n.rel.clearTimeout }); return { n: n, sy: sy, nav: nav, voz: VZ.compor({ navegador: nav, neural: opc && opc.semNeural ? null : n.neural }) }; }
      var c1 = comp(), p24 = c1.voz.falar(FR, 'en', {}); await flush(); SomFalso.todos[0].onended(); var r24 = await p24;
      var c2 = comp({ erro: true }), p24b = c2.voz.falar(FR, 'en', {}); await flush();
      var c3 = comp({ on: false }), p24c = c3.voz.falar(FR, 'en', {}); await flush();
      var c4 = comp(), p24d = c4.voz.falar(FR, 'en', {}); await flush(); c4.voz.pedirReinicio(); var r24d = await p24d; await flush();
      var c5 = comp({ on: false }), p24e = c5.voz.falar(FR, 'en', {}); await flush(); c5.voz.pedirReinicio(); await flush(); var r24e = await p24e;
      ok('NR24 voz composta: neural ativa fala sozinha (navegador calado); neural que falha cai no navegador com o MESMO texto; neural desligada vai direto ao navegador; "recomeçar" vale para os dois motores (devolve restart e não deixa o pedido preso para a próxima fala)',
        r24 === 'end' && c1.sy.falas.length === 0 && c2.sy.falas.length === 1 && c2.sy.falas[0].text === FR && c3.sy.falas.length === 1 && r24d === 'restart' && r24e === 'restart', c1.sy.falas.length + '/' + c2.sy.falas.length + '/' + c3.sy.falas.length + ' ' + r24d + ' ' + r24e);
      var c6 = comp(), p24f = c6.voz.falar(FR, 'en', {}); await flush(); SomFalso.todos[0].onended(); await p24f;
      var p24g = c6.voz.falar(FR, 'en', {}); await flush(); SomFalso.todos[1].onended(); var r24g = await p24g;
      ok('NR24b depois de um recomeço a fala seguinte termina normalmente (o pedido de recomeço não fica preso)', r24g === 'end', r24g);

      // ===== NR25 · Narrador + voz neural: ordem da síntese e retomada da palavra =====
      var P25 = [['Alpha beta gamma delta epsilon zeta.', 'Second sentence is next.', 'Third sentence follows too.', 'Fourth sentence waits.']];
      var cc = comp(), est25 = { vel: 1 }, ev25 = [], fonte25 = { paragrafos: function () { return 1; }, frases: function () { return P25[0].length; }, jaPronta: function (p, s) { return { text: P25[0][s], lang: 'en' }; }, texto: async function (p, s, i, vale) { await Promise.resolve(); return vale() ? { text: P25[0][s], lang: 'en' } : null; } };
      var off25 = EVB.on('narracao-palavra', function (d) { ev25.push(d.ci); });
      var nar25 = NA.criar({ fonte: fonte25, voz: cc.voz, velocidade: function () { return est25.vel; }, idiomaAudio: function () { return 'en'; }, agora: cc.n.rel.agora });
      nar25.tocar(0, 0); await flush();
      var ordem = cc.n.st.predicts.join('|') === P25[0].slice(0, 3).join('|');
      var au25 = SomFalso.todos[0]; au25.duration = 10; au25.currentTime = 6; cc.n.rel.avanca(40);    // ~ 60% da frase
      var ciAntes = ev25[ev25.length - 1]; est25.vel = 2; nar25.reiniciarFala(); await flush(); await flush();
      var au25b = SomFalso.todos[SomFalso.todos.length - 1], novoTexto = cc.n.st.predicts[cc.n.st.predicts.length - 1];
      var desv = P25[0][0].lastIndexOf(' ', Math.max(0, ciAntes - 1)) + 1;
      ok('NR25 no Narrador, a frase de agora entra na fila de síntese ANTES das 2 seguintes (a voz não espera o futuro); trocar a velocidade com a voz neural recomeça da palavra falada, a 2×', ordem && ciAntes > 0 && novoTexto === P25[0][0].slice(desv) && au25b !== au25 && au25b.playbackRate === 2, 'ordem=' + cc.n.st.predicts.join(' | ').slice(0, 80) + ' · retomou em "' + novoTexto + '"');
      nar25.parar(); off25();
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
