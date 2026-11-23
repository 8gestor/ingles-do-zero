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
