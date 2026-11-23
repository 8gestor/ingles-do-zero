<#
  test_novo_leitor.ps1 — confere, no Chrome, o Leitor do app novo (site/novo/assets/js/leitor/; fase R2.5; ver docs/10-r2-narrador.md, seção 10).

  R2.5a (texto): cada função do módulo `texto` roda ao lado da do app de hoje (numa moldura, via window.__ddLab) com entradas aleatórias de semente
  fixa; o resultado tem de ser idêntico. LT1 linhas do PDF · LT2 parágrafos (cabeçalho, rodapé, número, hifenização, título, frase partida) ·
  LT3 TXT inteiro vira o mesmo documento · LT4 idioma e frases. Cobre a área `c2` da matriz (2a–2g).
  Uso: pwsh tools\test_novo_leitor.ps1 [-Chrome <caminho>]    (sai com 1 se alguma verificação falhar)
#>
param([string]$Chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe')
$ErrorActionPreference = 'Stop'
$enc = New-Object System.Text.UTF8Encoding($false)
$repo = Split-Path -Parent $PSScriptRoot
$tmp = Join-Path ([IO.Path]::GetTempPath()) ('dd-lei-' + [guid]::NewGuid().ToString('N'))
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
      ok('LT0 o app liga com o módulo texto pronto', rel.ok === true && App.tem('texto') && App.tem('tradutor') && App.tem('fonte'), rel.modulos.filter(function (m) { return m.estado !== 'pronto'; }).map(function (m) { return m.nome + ':' + m.erro; }).join(' '));
      var T = App.get('texto'), r = rnd(20261123);
      function pick(a) { return a[Math.floor(r() * a.length)]; }
      // app de hoje numa moldura (oráculo): funções expostas pelo gancho de teste window.__ddLab
      var legF = document.createElement('iframe'); legF.src = '../ingles.html'; legF.style.cssText = 'position:fixed;left:-9999px;width:900px;height:600px'; document.body.appendChild(legF);
      await until(function () { return legF.contentWindow && legF.contentWindow.__ddLab && legF.contentWindow.DDLab && legF.contentWindow.DDLab.addText; });
      var LW = legF.contentWindow, LL = LW.__ddLab, LD = LW.DDLab;
      var clone = function (x) { return JSON.parse(JSON.stringify(x)); };
      ok('LT0b o app de hoje carrega na moldura com as funções de texto expostas (oráculo)', typeof LL.buildParagraphs === 'function' && typeof LL.buildLines === 'function' && typeof LL.splitSentences === 'function' && typeof LL.detectLang === 'function');

      var PAL_EN = ['the', 'merchant', 'laborious', 'diligence', 'algorithms', 'decide', 'what', 'we', 'read', 'and', 'buy', 'people', 'build', 'systems', 'rarely', 'asked', 'explain', 'them', 'Seneca', 'life', 'time'];
      var PAL_PT = ['o', 'comerciante', 'laboriosa', 'diligência', 'os', 'algoritmos', 'decidem', 'que', 'nós', 'lemos', 'e', 'compramos', 'as', 'pessoas', 'constroem', 'não', 'explicam', 'vida', 'tempo'];
      function frase(pal, n) { var ws = []; for (var i = 0; i < n; i++) ws.push(pick(pal)); var s = ws.join(' '); return s.charAt(0).toUpperCase() + s.slice(1) + pick(['.', '.', '.', '!', '?', '…', '.']); }
      function textoAleatorio(pal) { var n = 1 + Math.floor(r() * 7), s = []; for (var i = 0; i < n; i++) s.push(frase(pal, 3 + Math.floor(r() * (r() < 0.1 ? 70 : 14)))); return s.join(pick([' ', ' ', '  ', ' "', ' Dr. Smith said 3.14 '])); }

      // ===== LT1 · linhas do PDF =====
      var dif1 = 0, N1 = 200;
      for (var i = 0; i < N1; i++) {
        var itens = [], y = 700, x = 50, nI = 5 + Math.floor(r() * 40);
        for (var k = 0; k < nI; k++) { var str = r() < 0.05 ? '' : (r() < 0.1 ? ' ' : pick(PAL_EN)); var w = str.length * 5; if (r() < 0.2) { y -= 14 + Math.floor(r() * 6); x = 50 + Math.floor(r() * 30); } itens.push({ str: str, transform: [12, 0, 0, 12 + (r() < 0.1 ? 8 : 0), x, y], width: w, height: 12 }); x += w + (r() < 0.5 ? 0 : 4); }
        if (r() < 0.1) itens.push({ foo: 1 });
        if (JSON.stringify(T.linhas(clone(itens))) !== JSON.stringify(LL.buildLines(clone(itens)))) dif1++;
      }
      ok('LT1 as linhas montadas a partir dos itens do PDF (espaço entre itens, quebra por altura, itens vazios ou sem texto) são IDÊNTICAS às do app de hoje em 200 PDFs aleatórios', dif1 === 0, dif1 + ' diferentes');

      // ===== LT2 · parágrafos a partir de páginas (cabeçalho, rodapé, número, hifenização, título, frase partida) =====
      function paginaAleatoria(pg, nPag) {
        var linhas = [], y = 760, H = 800;
        linhas.push({ text: r() < 0.7 ? 'THE BOOK OF TIME' : 'Capítulo ' + pg, x: 50, y: 780, h: 9, endX: 200 });                    // cabeçalho (repete)
        var nL = 6 + Math.floor(r() * 30);
        for (var k = 0; k < nL; k++) {
          var kind = r(); var t, h = 12, x = 50;
          if (kind < 0.06) { t = frase(PAL_EN, 3); h = 20; }                                    // título (maior)
          else if (kind < 0.16) { t = pick(PAL_EN) + ' ' + pick(PAL_EN) + ' ' + pick(['dili-', 'labo-', 'sys-']); }   // termina em hífen
          else if (kind < 0.26) { t = pick(PAL_EN) + ' ' + pick(PAL_EN) + ' ' + pick(PAL_EN) + pick(['.', '?']); x = 70; }       // fim de parágrafo, próxima recua
          else { t = pick(PAL_EN) + ' ' + pick(PAL_EN) + ' ' + pick(PAL_EN) + ' ' + pick(PAL_EN); }
          if (r() < 0.12) t = t.charAt(0).toUpperCase() + t.slice(1);
          y -= (r() < 0.15 ? 30 : 14) * (r() < 0.05 ? -1 : 1); if (y < 70) y = 70 + Math.floor(r() * 5);
          linhas.push({ text: t, x: x, y: y, h: h, endX: x + t.length * 5 });
        }
        linhas.push({ text: r() < 0.8 ? String(pg) : 'Page ' + pg + ' of ' + nPag, x: 300, y: 30, h: 9, endX: 320 });                  // número de página (rodapé)
        return { h: H, lines: linhas };
      }
      var dif2 = 0, N2 = 200, algumTitulo = 0, algumaJuncao = 0, algumaHifen = 0, semCab = 0;
      for (var j = 0; j < N2; j++) {
        var nPag = 1 + Math.floor(r() * 6), pgs = []; for (var q = 0; q < nPag; q++) pgs.push(paginaAleatoria(q + 1, nPag));
        var novo = T.paragrafos(clone(pgs)), velho = LL.buildParagraphs(clone(pgs));
        if (JSON.stringify(novo) !== JSON.stringify(velho)) dif2++;
        if (novo.some(function (p) { return p.t === 'h'; })) algumTitulo++;
        if (nPag >= 3 && !novo.some(function (p) { return /THE BOOK OF TIME/.test(p.text); })) semCab++;
        if (novo.some(function (p) { return /(dili|labo|sys)[a-z]+ ?/.test(p.text) && !/(dili|labo|sys)- /.test(p.text); })) algumaHifen++;
      }
      ok('LT2 os parágrafos montados a partir de páginas (margens, títulos, recuo, virada de página, colunas) são IDÊNTICOS aos do app de hoje em 200 documentos aleatórios de 1 a 6 páginas', dif2 === 0 && algumTitulo > 20, dif2 + ' diferentes; com título em ' + algumTitulo);
      // casos legíveis da matriz c2 (2a–2e), checados no módulo novo e iguais ao de hoje
      function pag(linhas) { return { h: 800, lines: linhas }; }
      var L = function (text, y, h, x) { return { text: text, x: x || 50, y: y, h: h || 12, endX: (x || 50) + text.length * 5 }; };
      var tresPag = [0, 1, 2].map(function (i) { return pag([L('TOPO REPETIDO', 780, 9), L('Corpo da página ' + i + ' continua aqui.', 700), L('Mais uma linha de texto normal.', 686), L(String(i + 1), 20, 9)]); });
      var c2a = T.paragrafos(clone(tresPag)), c2a_h = LL.buildParagraphs(clone(tresPag));
      ok('2a cabeçalho repetido removido e 2b número de página removido (só sobra o corpo, 3 parágrafos de página)', !c2a.some(function (p) { return /TOPO REPETIDO/.test(p.text); }) && !c2a.some(function (p) { return /^\d+$/.test(p.text); }) && JSON.stringify(c2a) === JSON.stringify(c2a_h), c2a.map(function (p) { return p.text.slice(0, 20); }).join(' | '));
      var hif = [pag([L('A frase com palavra parti-', 700), L('da no meio da linha.', 686)])];
      var c2c = T.paragrafos(clone(hif));
      ok('2c hifenização juntada ("parti-" + "da" = "partida")', c2c.length === 1 && /partida no meio/.test(c2c[0].text) && !/parti- /.test(c2c[0].text) && JSON.stringify(c2c) === JSON.stringify(LL.buildParagraphs(clone(hif))), c2c[0] && c2c[0].text);
      var tit = [pag([L('UM GRANDE TITULO', 740, 24), L('Texto do corpo que vem depois do título.', 700), L('Segunda linha do mesmo parágrafo corrido.', 686)])];
      var c2d = T.paragrafos(clone(tit));
      ok('2d título (letra maior) vira cabeçalho "h" e o corpo continua parágrafo "p"', c2d[0].t === 'h' && c2d[1].t === 'p' && JSON.stringify(c2d) === JSON.stringify(LL.buildParagraphs(clone(tit))), c2d.map(function (p) { return p.t; }).join());
      var parte = [pag([L('Esta frase começa no fim da primeira página e', 100)]), pag([L('termina no começo da segunda página.', 740)])];
      var c2e = T.paragrafos(clone(parte));
      ok('2e frase partida entre páginas é reunida em UM parágrafo', c2e.length === 1 && /primeira página e termina no começo/.test(c2e[0].text) && JSON.stringify(c2e) === JSON.stringify(LL.buildParagraphs(clone(parte))), c2e.length + ' parágrafo(s)');

      // ===== LT3 · TXT: parágrafos, versos, hifenização, e o documento inteiro =====
      var RAWS = [
        'Primeiro parágrafo de um texto corrido, com várias frases. Mais uma frase aqui!\n\nSegundo parágrafo com palavra parti-\nda na quebra de linha.\r\n\r\n   \nTerceiro.',
        'Roses are red\nViolets are blue\nSugar is sweet\nAnd so are you\n\nA normal paragraph follows the poem. It has two sentences.',
        'The merchant spoke about diligence. He was a laborious man, and nobody doubted it.\nThe next line of the same paragraph continues here without a blank.\n\n1234\n\n...\n\nFim.',
        'Linha curta um.\nLinha curta dois.\nLinha curta três.\n\n"Quoted dialogue," she said. "Short lines."\n"Another one."'
      ];
      for (var rr = 0; rr < 8; rr++) { var bl = [], nb = 1 + Math.floor(r() * 5); for (var bb = 0; bb < nb; bb++) bl.push(textoAleatorio(r() < 0.5 ? PAL_EN : PAL_PT)); RAWS.push(bl.join('\n\n')); }
      var dif3 = 0, mostra3 = '';
      for (var u = 0; u < RAWS.length; u++) {
        var nome = 'Texto ' + u, esperado = T.documento(T.deTxt(RAWS[u]), nome + '.txt');
        await LD.addText(nome, RAWS[u]);
        var okAbriu = await until(function () { return LD.doc && LD.doc.title === nome; }, 20000);
        var d = LD.doc, atual = okAbriu ? { lang: d.lang, pages: d.pages, paras: d.paras.map(function (p) { return { t: p.t, pg: p.pg, s: p.s }; }), words: d.words, sentences: d.sentences, title: d.title } : null;
        var ex = { lang: esperado.lang, pages: esperado.pages, paras: esperado.paras.map(function (p) { return { t: p.t, pg: p.pg, s: p.s }; }), words: esperado.words, sentences: esperado.sentences, title: nome };
        if (JSON.stringify(atual) !== JSON.stringify(ex)) { dif3++; mostra3 += ' #' + u; }
        LW.postMessage({ type: 'x' }, '*'); LD.stopTts(); LD.$('lb-back') && LD.$('lb-back').click(); await wait(150);
      }
      ok('LT3 o documento montado a partir de um TXT (parágrafos por linha em branco, versos, hifenização, idioma, frases, contagem de palavras e de frases, título) é IDÊNTICO ao que o app de hoje cria ao importar, em ' + RAWS.length + ' textos (4 de mão e 8 aleatórios em inglês e português)', dif3 === 0, dif3 + ' diferentes' + mostra3);
      var versos = T.deTxt(RAWS[1]).paras;
      ok('LT3b versos viram estrofe "v" (cada linha uma unidade narrada) e prosa continua "p"; hifenização do TXT é juntada; parágrafo só de números ou pontos some', versos[0].t === 'v' && versos[0].lines.length === 4 && versos[1].t === 'p' && /partida na quebra/.test(T.deTxt(RAWS[0]).paras[1].text) && T.deTxt(RAWS[2]).paras.every(function (p) { return /\p{L}/u.test(p.text); }) && T.pareceVerso(['Roses are red', 'Violets are blue']) === true && T.pareceVerso(['Uma única linha']) === false);

      // ===== LT4 · idioma e frases =====
      var dif4 = 0, dif5 = 0, N4 = 300, pt = 0, en = 0;
      for (var a = 0; a < N4; a++) {
        var paras = []; for (var b = 0; b < 1 + Math.floor(r() * 4); b++) paras.push({ text: textoAleatorio(r() < 0.5 ? PAL_EN : PAL_PT) });
        var i1 = T.detectarIdioma(paras), i2 = LL.detectLang(paras); if (i1 !== i2) dif4++; if (i1 === 'pt') pt++; else en++;
        var tx = textoAleatorio(r() < 0.5 ? PAL_EN : PAL_PT), lg = r() < 0.5 ? 'en' : 'pt';
        if (JSON.stringify(T.dividirFrases(tx, lg)) !== JSON.stringify(LL.splitSentences(tx, lg))) dif5++;
      }
      ok('LT4a o idioma detectado (inglês ou português, pelas palavras mais comuns) é IDÊNTICO ao do app de hoje em 300 textos; os dois idiomas aparecem na amostra', dif4 === 0 && pt > 30 && en > 30, dif4 + ' diferentes; pt=' + pt + ' en=' + en);
      ok('LT4b a divisão em frases (inclusive abreviações, números com ponto, aspas e frases longas partidas em vírgula e ponto e vírgula) é IDÊNTICA à do app de hoje em 300 textos', dif5 === 0, dif5 + ' diferentes');
      var longa = (PAL_EN.join(' ') + ', ').repeat(6) + 'fim.';
      var partes = T.dividirFrases(longa, 'en');
      ok('2f frases separadas: três frases viram três; frase de mais de 320 caracteres é partida em pedaços de no máximo 320, sem perder texto', T.dividirFrases('Uma frase. Outra frase! E a terceira?', 'pt').length === 3 && partes.length > 1 && partes.every(function (x) { return x.length <= 320; }) && partes.join(' ').replace(/\s+/g, ' ').length >= longa.replace(/\s+/g, ' ').trim().length - partes.length, partes.length + ' pedaços');
      ok('2g idioma detectado: texto em português dá "pt", em inglês dá "en", vazio dá "en"', T.detectarIdioma([{ text: 'O comerciante não sabia que o tempo da vida é curto e que muito se perde.' }]) === 'pt' && T.detectarIdioma([{ text: 'The merchant did not know that the time of life is short and that much is lost.' }]) === 'en' && T.detectarIdioma([]) === 'en');

      // ===================== R2.5b · Tradutor (c4): mesmo resultado do app de hoje =====================
      var TRD = App.get('tradutor'), chamadasL = 0, chamadasN = 0;
      LW.DD_TRANSLATOR_FACTORY = function (a, b) { return { translate: async function (t) { chamadasL++; await wait(2); return '[' + b + '] ' + t; } }; };
      var fabN = function (a, b) { return { translate: async function (t) { chamadasN++; await wait(2); return '[' + b + '] ' + t; } }; };
      var LONGO = []; for (var pI = 0; pI < 60; pI++) LONGO.push('Sentence number ' + pI + ' is here. And a second one follows it!');
      LW.postMessage({ type: 'readlang', value: 'pt' }, '*'); await wait(300);
      await LD.addText('Longo', LONGO.join('\n\n'));
      await until(function () { return LD.doc && LD.doc.title === 'Longo' && LD.doc.paras.length === 60; }, 30000);
      await until(function () { return Object.keys(LD.doc.tr).length >= 40; }, 30000); await wait(800);
      var trHoje40 = JSON.parse(JSON.stringify(LD.doc.tr)), cHoje40 = chamadasL;
      var docN = { id: 'novo-longo', lang: LD.doc.lang, paras: LD.doc.paras.map(function (p) { return { s: p.s.slice() }; }), tr: {}, pos: 0 };
      var pintados = [], gravados = [], tN = TRD.criar({ fabrica: fabN, precisa: function () { return true; }, aoParagrafo: function (i) { pintados.push(i); }, gravar: function (id, i, out) { gravados.push(i); } });
      tN.abrir(docN); tN.bombear(); await until(function () { return Object.keys(docN.tr).length >= 40; }, 30000); await wait(800);
      ok('4a PARÁGRAFOS PRÓXIMOS TRADUZIDOS: a bomba traduz exatamente os 40 parágrafos à frente da âncora (nem mais, nem menos) e o resultado é IDÊNTICO ao do app de hoje, com o mesmo número de chamadas ao tradutor', Object.keys(docN.tr).length === 40 && JSON.stringify(docN.tr) === JSON.stringify(trHoje40) && chamadasN === cHoje40, 'novo=' + Object.keys(docN.tr).length + ' hoje=' + Object.keys(trHoje40).length + ' chamadas ' + chamadasN + '/' + cHoje40);
      var okParidade = Object.keys(docN.tr).every(function (i) { return docN.tr[i].length === docN.paras[i].s.length; });
      ok('4b paridade de frases: cada parágrafo traduzido tem exatamente o mesmo número de frases do original; a tela é avisada (aoParagrafo) e o armazém recebe (gravar) cada parágrafo', okParidade && pintados.length === 40 && gravados.length === 40, pintados.length + ' pintados');
      LD.$('lb-translate-all').click(); await until(function () { return Object.keys(LD.doc.tr).length >= 60; }, 30000); await wait(300);
      tN.tudo(true); await until(function () { return Object.keys(docN.tr).length >= 60; }, 30000); await wait(300);
      ok('4d "TRADUZIR TUDO" completa o documento: os 60 parágrafos traduzidos, IDÊNTICO ao do app de hoje', Object.keys(docN.tr).length === 60 && JSON.stringify(docN.tr) === JSON.stringify(LD.doc.tr), Object.keys(docN.tr).length + ' de 60');
      // tradução imediata de uma frase e cache
      var dN2 = { id: 'novo-frase', lang: 'en', paras: [{ s: ['Quick translated sentence here.', '123'] }, { s: ['Another one.'] }], tr: {}, pos: 0 }, antesC = chamadasN, t2 = TRD.criar({ fabrica: fabN });
      t2.abrir(dN2); var f1 = await t2.frase(0, 0), f1b = await t2.frase(0, 0), fnum = await t2.frase(0, 1), fnada = await t2.frase(9, 9);
      ok('4e FRASE IMEDIATA: traduz só aquela frase, guarda no cache (2 pedidos = 1 chamada), devolve frase sem letra como está ("123") sem chamar o tradutor, e nulo se a frase não existe', f1 === '[pt] Quick translated sentence here.' && f1b === f1 && fnum === '123' && fnada === null && chamadasN - antesC === 1, f1 + ' chamadas=' + (chamadasN - antesC));
      // sem tradutor / falha / espera
      var tSem = TRD.criar({ fabrica: null, Translator: null }), dS = { id: 'sem', lang: 'en', paras: [{ s: ['No translator here at all.'] }], tr: {}, pos: 0 };
      tSem.abrir(dS); var fs = await tSem.frase(0, 0); await tSem.garantir(0); tSem.bombear(); await wait(50);
      ok('4f SEM TRADUTOR: a frase vem nula, "garantir" resolve mesmo assim (a narração não trava) e o estado diz "unsupported"', fs === null && tSem.estado().avail === 'unsupported' && Object.keys(dS.tr).length === 0, String(tSem.estado().avail));
      var tFalha = TRD.criar({ fabrica: function () { return { translate: async function (t) { if (/boom/.test(t)) throw new Error('quebrou'); return '[pt] ' + t; } }; } }), dF = { id: 'falha', lang: 'en', paras: [{ s: ['First one is fine.'] }, { s: ['Now boom happens here.'] }, { s: ['Third.'] }], tr: {}, pos: 0 };
      tFalha.abrir(dF); await tFalha.garantir(0); var esperou = false; tFalha.garantir(1).then(function () { esperou = true; }); await until(function () { return esperou; }, 5000);
      ok('4g FALHA DO TRADUTOR: o erro aparece no estado ("quebrou"), o parágrafo anterior ficou traduzido, e quem esperava o parágrafo que falhou é liberado (a leitura segue sem tradução)', esperou && /quebrou/.test(tFalha.estado().erro) && !!dF.tr[0] && !dF.tr[1], tFalha.estado().erro);
      var dN3 = { id: 'espera', lang: 'en', paras: LONGO.map(function (x) { return { s: [x] }; }), tr: {}, pos: 0 }, t3 = TRD.criar({ fabrica: fabN }); t3.abrir(dN3); await t3.garantir(25);
      ok('4h A NARRAÇÃO ESPERA o parágrafo: "garantir(25)" só resolve quando o parágrafo 25 está traduzido (a bomba pula para a âncora nova)', !!dN3.tr[25] && dN3.tr[25][0] === '[pt] ' + LONGO[25], Object.keys(dN3.tr).length + ' traduzidos');
      LW.postMessage({ type: 'readlang', value: 'en' }, '*'); LD.$('lb-back') && LD.$('lb-back').click(); await wait(200);

      // ===================== R2.5c · Fonte do documento + Tradutor + Narrador: PARIDADE com o app de hoje =====================
      var FO = App.get('fonte'), NAR = App.get('narrador'), VNV = App.get('voz-navegador');
      var Hm = { m: null };
      function criarMotor(cfg) {
        var m = { log: [], fila: [], atual: null, cfg: cfg || {} };
        function iniciar() {
          if (m.atual || !m.fila.length) return; var u = m.fila.shift(); m.atual = u;
          setTimeout(function () {
            if (m.atual !== u) return; if (u.onstart) u.onstart();
            var ws = [], re = /\S+/g, x, dur = m.cfg.dur || 120;
            if (m.cfg.palavras) { while ((x = re.exec(u.text))) ws.push(x.index); ws.forEach(function (ci, k) { setTimeout(function () { if (m.atual === u && u.onboundary) u.onboundary({ name: 'word', charIndex: ci }); }, 20 + k * m.cfg.palavras); }); dur = 20 + ws.length * m.cfg.palavras + 20; }
            setTimeout(function () { if (m.atual !== u) return; m.atual = null; if (u.onend) u.onend(); iniciar(); }, dur);
          }, 0);
        }
        m.speak = function (u) { m.log.push({ text: u.text, lang: u.lang, rate: u.rate }); m.fila.push(u); iniciar(); };
        m.cancel = function () { var tudo = (m.atual ? [m.atual] : []).concat(m.fila); m.atual = null; m.fila = []; setTimeout(function () { tudo.forEach(function (u) { if (u.onerror) u.onerror({ error: 'canceled' }); }); }, 0); };
        return m;
      }
      Hm.m = criarMotor({});
      var SSL = LW.speechSynthesis;
      Object.defineProperty(SSL, 'speak', { configurable: true, value: function (u) { Hm.m.speak(u); } });
      Object.defineProperty(SSL, 'cancel', { configurable: true, value: function () { Hm.m.cancel(); } });
      Object.defineProperty(SSL, 'getVoices', { configurable: true, value: function () { return []; } });
      Object.defineProperty(SSL, 'speaking', { configurable: true, get: function () { return !!(Hm.m.atual || Hm.m.fila.length); } });
      Object.defineProperty(SSL, 'pending', { configurable: true, get: function () { return Hm.m.fila.length > 0; } });
      var PECAS = [], OUV = { n: 0 };
      LD.on('piece', function (e) { PECAS.push(e.p + '.' + e.s + '.' + e.lang + '.' + e.text); });
      LD.on('heard', function (e) { OUV.n += e.words; });
      LW.postMessage({ type: 'readlang', value: 'en' }, '*'); LW.postMessage({ type: 'audiolang', value: 'en' }, '*'); await wait(300);
      await LD.addText('FontePar', 'Algorithms decide what we read and what we buy. They shape our choices every day. Nobody explains how they work, and few people ask.\n\nUnderstanding that fact is the first step towards resisting it. The people who build these systems are rarely asked to explain them.\n\nShort third paragraph here. And one more!');
      await until(function () { return LD.doc && LD.doc.title === 'FontePar' && LD.doc.paras.length === 3; }, 20000);
      var PARF = LD.doc.paras.map(function (p) { return p.s.slice(); });
      async function rodarF(lado, cen) {
        var motor = criarMotor(cen.cfg); Hm.m = motor; PECAS = []; OUV.n = 0; var api;
        if (lado === 'hoje') {
          LD.stopTts(); LD.tts.cursor = null; LD.state.rate = 1; LW.postMessage({ type: 'audiolang', value: cen.audio }, '*'); await wait(200);
          api = { tocar: function (p, s) { LD.startTts(p, s); }, parar: function () { LD.stopTts(); }, tocando: function () { return LD.tts.playing; } };
        } else {
          var EVn = App.get('eventos'), audio = cen.audio;
          var docN = { id: 'fp-' + cen.audio, lang: 'en', paras: PARF.map(function (s) { return { s: s.slice() }; }), tr: {}, pos: 0 };
          var trN = TRD.criar({ fabrica: fabN, precisa: function () { return audio !== docN.lang; } }); trN.abrir(docN);
          var fonteN = FO.doDocumento({ doc: docN, tradutor: trN, idiomaAudio: function () { return audio; } });
          var voz = VNV.criar({ synth: { speak: motor.speak, cancel: motor.cancel, getVoices: function () { return []; }, get speaking() { return !!(motor.atual || motor.fila.length); }, get pending() { return motor.fila.length > 0; } }, Utterance: function (t) { this.text = t; } });
          var nar = NAR.criar({ voz: voz }); nar.abrir(fonteN);
          var offs = [EVn.on('narracao-frase', function (e) { if (e.texto != null) PECAS.push(e.p + '.' + e.s + '.' + e.idioma + '.' + e.texto); }), EVn.on('frase-ouvida', function (e) { OUV.n += e.palavras; })];
          api = { tocar: function (p, s) { nar.tocar(p, s); }, parar: function () { nar.parar(); }, tocando: function () { return nar.estado().tocando; }, fim: function () { offs.forEach(function (f) { f(); }); nar.fechar(); } };
        }
        await cen.rodar(api, motor); await wait(400);
        if (api.fim) api.fim(); else LD.stopTts();
        await wait(200);
        return { falas: motor.log.map(function (x) { return [x.text, x.lang, x.rate].join('~'); }), pecas: PECAS.slice(), ouvidas: OUV.n };
      }
      var CENF = {
        original: { audio: 'en', cfg: { dur: 100 }, rodar: async function (a) { a.tocar(0, 0); await until(function () { return !a.tocando(); }, 30000); } },
        traduzido: { audio: 'pt', cfg: { dur: 100 }, rodar: async function (a) { a.tocar(0, 0); await until(function () { return !a.tocando(); }, 30000); } },
        'traduzido do meio': { audio: 'pt', cfg: { palavras: 20 }, rodar: async function (a) { a.tocar(1, 1); await until(function () { return !a.tocando(); }, 30000); } }
      };
      for (var nomeF of ['original', 'traduzido', 'traduzido do meio']) {
        var fh = await rodarF('hoje', CENF[nomeF]), fn = await rodarF('novo', CENF[nomeF]), igF = JSON.stringify(fh) === JSON.stringify(fn);
        ok('PF-' + nomeF + ' PARIDADE com Fonte + Tradutor reais · ' + (nomeF === 'original' ? 'ouvir no idioma do livro' : nomeF === 'traduzido' ? 'ouvir em português um livro em inglês (tradução frase a frase)' : 'ouvir em português a partir do meio do livro') + ': mesmas falas (texto, idioma, velocidade), mesmas frases e mesmas palavras ouvidas que o app de hoje', igF && fh.falas.length >= 3, 'falas hoje=' + fh.falas.length + ' novo=' + fn.falas.length + ' ouvidas ' + fh.ouvidas + '/' + fn.ouvidas + (igF ? '' : ' | HOJE ' + fh.falas.map(function (x) { return x.slice(0, 18); }).join(';') + ' | NOVO ' + fn.falas.map(function (x) { return x.slice(0, 18); }).join(';')));
      }
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
