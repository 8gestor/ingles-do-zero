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
      ok('LT0 o app liga com o módulo texto pronto', rel.ok === true && App.tem('texto') && App.tem('tradutor') && App.tem('fonte') && App.tem('pagina') && App.tem('marcacao') && App.tem('alinhar') && App.tem('explorar'), rel.modulos.filter(function (m) { return m.estado !== 'pronto'; }).map(function (m) { return m.nome + ':' + m.erro; }).join(' '));
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

      // ===================== R2.5d · Página e marcação em quatro camadas: o MESMO HTML que o app de hoje =====================
      var PG = App.get('pagina'), MC = App.get('marcacao'), EVm = App.get('eventos');
      await LD.addText('Marca', 'Algorithms decide what we read and what we buy. They shape our choices every day. Nobody explains how they work, and few people ask.\n\nRoses are red\nViolets are blue\nSugar is sweet\nAnd so are you\n\nUnderstanding that fact is the first step towards resisting it. The people who build these systems are rarely asked to explain them.');
      await until(function () { return LD.doc && LD.doc.title === 'Marca' && LD.doc.paras.length === 3; }, 20000);
      async function reiniciaHoje() { LD.stopTts(); LD.tts.mark = null; LD.tts.word = -1; LD.tts.cursor = null; Array.from(LD.$('lb-text').children).forEach(function (e) { e.classList.remove('speaking'); }); LD.repaintAll(); await wait(200); }
      function htmlDe(host) { return Array.from(host.children).map(function (e) { return e.tagName + '.' + e.className + '|' + e.innerHTML; }).join('\n'); }
      function criaNovo() {
        var d = LD.doc, docN = { lang: d.lang, paras: d.paras.map(function (p) { return { t: p.t, s: p.s.slice() }; }), tr: JSON.parse(JSON.stringify(d.tr)) };
        var host = document.createElement('div'), faixa = document.createElement('div'), env = document.createElement('div'); env.style.cssText = 'position:relative'; env.append(host, faixa); document.body.appendChild(env);
        var pagina = PG.criar({ host: host, doc: function () { return docN; }, lerIdioma: function () { return LD.state.readLang; }, lado: function () { return LD.state.side; }, aoPintar: function (i) { marc.reaplicar(i); } });
        var marc = MC.criar({ pagina: pagina, faixa: faixa, envoltorio: env, modo: function () { return LD.state.mode; }, mapear: function () { return LD.mapPos.apply(LD, arguments); } });
        var offs = marc.ligar(EVm); pagina.construir(0);
        return { host: host, faixa: faixa, marc: marc, pagina: pagina, fim: function () { offs.forEach(function (f) { f(); }); env.remove(); } };
      }
      var LHOST = LD.$('lb-text'), SEQ = [], FR = LD.doc.paras.map(function (p) { return p.s.slice(); });
      function passoMarca(p, s) { return { h: function () { LD.setMark(p, s); }, n: function () { EVm.emit('narracao-frase', { p: p, s: s, texto: FR[p][s], idioma: 'en' }); } }; }
      function passoPal(p, s, ci, falado, idioma) { var t = falado || FR[p][s]; return { h: function () { LD.setWordAt(ci, t.length, t, idioma || 'en'); }, n: function () { EVm.emit('narracao-palavra', { ci: ci, len: t.length, texto: t, idioma: idioma || 'en' }); } }; }
      var passoParar = { h: function () { LD.stopTts(); }, n: function () { EVm.emit('narracao-estado', { tocando: false }); } };
      async function compararMarcacao(rotulo, passos, preparo) {
        await reiniciaHoje(); if (preparo) await preparo();
        var N = criaNovo(), difs = [], antes = htmlDe(LHOST) === htmlDe(N.host); function achaDif(r2) { var a = Array.from(LHOST.children), b = Array.from(N.host.children); for (var q = 0; q < Math.max(a.length, b.length); q++) { var x = a[q] ? a[q].className + ' # ' + a[q].innerHTML : '(sem)', y = b[q] ? b[q].className + ' # ' + b[q].innerHTML : '(sem)'; if (x !== y) { out.push('DIAG ' + rotulo + ' ' + r2 + ' par ' + q + ' HOJE: ' + x.slice(0, 260) + ' || NOVO: ' + y.slice(0, 260)); live(); return; } } } if (!antes) achaDif('antes');
        for (var i = 0; i < passos.length; i++) { passos[i].h(); passos[i].n(); if (htmlDe(LHOST) !== htmlDe(N.host)) { if (!difs.length) achaDif('passo ' + i); difs.push('passo ' + i); } }
        var final = { bandaH: LD.$('lb-band').style.display, bandaN: N.faixa.style.display };
        N.fim(); return { rotulo: rotulo, antes: antes, difs: difs, banda: final };
      }
      // M1 pintura inicial (leitura em inglês) e M2 marcas e palavras
      var m1 = await compararMarcacao('pintura', []);
      ok('M1 PINTURA: a página nova gera o MESMO HTML que o app de hoje para os 3 parágrafos (texto corrido, estrofe de versos, texto corrido): mesmas tags, classes e frases', m1.antes && LHOST.children.length === 3, m1.antes ? 'igual' : 'diferente');
      var passosEn = [passoMarca(0, 0), passoPal(0, 0, 0), passoPal(0, 0, 11), passoPal(0, 0, 30), passoPal(0, 0, 9999), passoMarca(0, 1), passoPal(0, 1, 5), passoPal(0, 1, 20), passoMarca(1, 2), passoPal(1, 2, 3), passoMarca(2, 1), passoPal(2, 1, 40), passoPal(2, 1, 41), passoParar];
      var m2 = await compararMarcacao('marcas e palavras', passosEn);
      ok('M2 MARCAÇÃO EM QUATRO CAMADAS: seguindo a narração (frase, palavra, mudar de frase, de parágrafo, de estrofe, parar), o HTML novo é IGUAL ao do app de hoje a cada passo: parágrafo falado, frase com marca-texto, palavra atual e palavras da frase', m2.difs.length === 0, m2.difs.length + ' passos diferentes ' + m2.difs.join(','));
      ok('M2b a faixa da linha (camada 2) aparece com a frase marcada e some quando a narração para, nos dois', m2.banda.bandaH === m2.banda.bandaN && m2.banda.bandaH === 'none', m2.banda.bandaH + '/' + m2.banda.bandaN);
      var m2c = await compararMarcacao('faixa visível', [passoMarca(0, 1), passoPal(0, 1, 5)]);
      ok('M2c com a narração tocando, a faixa fica visível (display:block) nos dois e acompanha a palavra', m2c.difs.length === 0 && m2c.banda.bandaH === 'block' && m2c.banda.bandaN === 'block', m2c.banda.bandaH + '/' + m2c.banda.bandaN);
      // M3 lendo em português (tradução na tela) com a voz em inglês: alinhamento entre idiomas
      LW.postMessage({ type: 'readlang', value: 'pt' }, '*'); await until(function () { return LD.doc && Object.keys(LD.doc.tr).length >= 3; }, 30000); await wait(400);
      var m3 = await compararMarcacao('pintura em português', []);
      ok('M3 PINTURA LENDO EM PORTUGUÊS: com a tradução pronta, a página nova mostra a tradução frase a frase com o MESMO HTML do app de hoje', m3.antes && /\[pt\]/.test(LHOST.textContent), m3.antes ? 'igual' : 'diferente');
      var passosPt = [passoMarca(0, 0), passoPal(0, 0, 0), passoPal(0, 0, 14), passoPal(0, 0, 33), passoMarca(1, 1), passoPal(1, 1, 8), passoPal(1, 1, 22), passoParar];
      var m4 = await compararMarcacao('lendo pt, ouvindo en', passosPt);
      ok('M4 TELA EM PORTUGUÊS, VOZ EM INGLÊS: a palavra marcada na tradução acompanha a palavra falada (alinhamento entre idiomas) e o HTML é IGUAL ao do app de hoje a cada passo', m4.difs.length === 0, m4.difs.join(','));
      // M5 lado a lado
      LD.setMode('side'); await wait(400);
      var m5 = await compararMarcacao('lado a lado', [passoMarca(0, 1), passoPal(0, 1, 6), passoMarca(1, 0), passoPal(1, 0, 4), passoParar]);
      ok('M5 LADO A LADO: original à esquerda e tradução à direita com a mesma frase marcada nas duas colunas; HTML IGUAL ao do app de hoje (pintura e marcação)', m5.antes && m5.difs.length === 0 && /lb-col-tr/.test(LHOST.innerHTML), 'antes=' + m5.antes + ' ' + m5.difs.join(','));
      LD.setMode('single'); LW.postMessage({ type: 'readlang', value: 'en' }, '*'); await wait(400);
      // M6 repintura com a frase marcada (a tradução chega no meio)
      await reiniciaHoje(); var N6 = criaNovo(); LD.setMark(1, 1); EVm.emit('narracao-frase', { p: 1, s: 1, texto: FR[1][1], idioma: 'en' });
      LD.repaintAll(); N6.pagina.pintarTudo(0); await wait(200);
      ok('M6 REPINTURA: repintar a página com uma frase marcada devolve a marca (parágrafo e frase), igual ao app de hoje', htmlDe(LHOST) === htmlDe(N6.host) && /speaking/.test(N6.host.innerHTML) && N6.marc.estado().marca.p === 1, 'igual=' + (htmlDe(LHOST) === htmlDe(N6.host)));
      N6.fim(); await reiniciaHoje();
      // M7 documento grande: pintura em partes e primeira visível
      var grande = { lang: 'en', paras: [], tr: {} }; for (var gi = 0; gi < 650; gi++) grande.paras.push({ t: 'p', s: ['Sentence ' + gi + ' of the big book.'] });
      var gh = document.createElement('div'); document.body.appendChild(gh); var pgG = PG.criar({ host: gh, doc: function () { return grande; }, lerIdioma: function () { return 'en'; } }); pgG.construir(400);
      var logo = gh.querySelectorAll('.lb-s').length; await until(function () { return gh.querySelectorAll('.lb-s').length === 650; }, 15000);
      ok('M7 DOCUMENTO GRANDE (650 parágrafos): a página abre pintando só uma parte (perto da leitura) e termina pintando tudo aos poucos; o parágrafo 400 já nasce pintado', logo >= 80 && logo < 650 && gh.querySelectorAll('.lb-s').length === 650 && gh.classList.contains('lb-big') && /Sentence 400 /.test(gh.children[400].textContent), 'no começo=' + logo);
      gh.remove();

      // ===================== R2.5e · Alinhamento entre idiomas (AL) e setas palavra a palavra (EX): iguais ao app de hoje =====================
      var ALM = App.get('alinhar'), EXP = App.get('explorar');
      function traduzPal(raw, lang) { return Promise.resolve('[' + (lang === 'en' ? 'pt' : 'en') + '] ' + raw); }
      await LD.alignPrepare('Zorbal frumious bandersnatch', 'en'); await wait(2200);
      var cacheHoje = JSON.parse(LW.localStorage.getItem('dd-ingles-pal-tr') || '{}');
      var alN = ALM.criar({ traduzirPalavra: traduzPal, armazenar: false, palavras: cacheHoje });
      // AL · mapPos idêntico em frases aleatórias, nos dois sentidos
      var difA = 0, NA_ = 400, trocas = 0;
      for (var ia = 0; ia < NA_; ia++) {
        var falEn = r() < 0.5, sp = textoAleatorio(falEn ? PAL_EN : PAL_PT), tg = textoAleatorio(falEn ? PAL_PT : PAL_EN), cii = Math.floor(r() * (sp.length + 5));
        if (alN.mapPos(sp, cii, tg, falEn ? 'en' : 'pt') !== LD.mapPos(sp, cii, tg, falEn ? 'en' : 'pt')) difA++;
      }
      ok('AL3 o alinhamento de palavras entre idiomas é IDÊNTICO ao do app de hoje em 400 pares aleatórios de frase falada e frase mostrada (inglês falado e português na tela, e o contrário), com o mesmo cache de palavras', difA === 0, difA + ' diferentes');
      var enF = 'The merchant of laborious diligence', ptT = 'O comerciante de diligência laboriosa';
      var iLab = enF.indexOf('laborious'), iDil = enF.indexOf('diligence');
      var pLab = alN.mapPos(enF, iLab, ptT, 'en'), pDil = alN.mapPos(enF, iDil, ptT, 'en'), pCom = alN.mapPos(enF, enF.indexOf('merchant'), ptT, 'en');
      ok('AL1 inglês falado, português na tela: "laborious" cai em "laboriosa" e "diligence" em "diligência" (adjetivo e substantivo trocados); "merchant" cai em "comerciante"; igual ao app de hoje', ptT.slice(pLab).indexOf('laboriosa') === 0 && ptT.slice(pDil).indexOf('diligência') === 0 && ptT.slice(pCom).indexOf('comerciante') === 0 && pLab === LD.mapPos(enF, iLab, ptT, 'en') && pDil === LD.mapPos(enF, iDil, ptT, 'en'), pLab + ' ' + pDil);
      var ptF = 'O comerciante de diligência laboriosa', enT = 'The merchant of laborious diligence';
      var q1 = alN.mapPos(ptF, ptF.indexOf('diligência'), enT, 'pt'), q2 = alN.mapPos(ptF, ptF.indexOf('laboriosa'), enT, 'pt');
      ok('AL2 português falado, inglês na tela: "diligência" cai em "diligence" e "laboriosa" em "laborious"; o resto da frase segue em ordem; igual ao app de hoje', enT.slice(q1).indexOf('diligence') === 0 && enT.slice(q2).indexOf('laborious') === 0 && q1 === LD.mapPos(ptF, ptF.indexOf('diligência'), enT, 'pt') && q2 === LD.mapPos(ptF, ptF.indexOf('laboriosa'), enT, 'pt'));
      var chamadasPal = 0, alP = ALM.criar({ traduzirPalavra: function (raw, lang) { chamadasPal++; return traduzPal(raw, lang); }, armazenar: false }), v0 = alP.versao();
      await alP.preparar('Frumious bandersnatch and the zorbal', 'en'); var c1 = chamadasPal, v1 = alP.versao(); await alP.preparar('Frumious bandersnatch and the zorbal', 'en');
      ok('AL5 PREPARAR PALAVRAS: traduz cada palavra nova (3 letras ou mais) uma só vez, guarda no cache (a segunda preparação não chama o tradutor), e a versão sobe para o alinhamento se refazer; as traduções gravadas são as mesmas que o app de hoje guardou', c1 === 5 && chamadasPal === 5 && v1 === v0 + 1 && alP.palavras()['en|zorbal'] === '[pt] zorbal' && cacheHoje['en|zorbal'] === alP.palavras()['en|zorbal'] && cacheHoje['en|frumious'] === alP.palavras()['en|frumious'], 'chamadas=' + chamadasPal + ' ' + JSON.stringify(Object.keys(alP.palavras())));

      // EX · setas palavra a palavra: o mesmo HTML e a mesma etiqueta que o app de hoje, passo a passo
      function criaNovoEx() {
        var dd = LD.doc;
        var docX = { id: 'ex', lang: dd.lang, paras: dd.paras.map(function (p) { return { t: p.t, s: p.s.slice() }; }), tr: JSON.parse(JSON.stringify(dd.tr)), pos: 0 };
        var host = document.createElement('div'), faixa = document.createElement('div'), env = document.createElement('div'); env.style.cssText = 'position:relative'; env.append(host, faixa); document.body.appendChild(env);
        var pg0 = PG.criar({ host: host, doc: function () { return docX; }, lerIdioma: function () { return LD.state.readLang; }, lado: function () { return LD.state.side; }, aoPintar: function (i) { mc.reaplicar(i); } });
        var pg = Object.assign({}, pg0, { primeiraVisivel: function () { return 0; } });
        var mc = MC.criar({ pagina: pg0, faixa: faixa, envoltorio: env, modo: function () { return LD.state.mode; }, mapear: function () { return alN.mapPos.apply(alN, arguments); } });
        var offs = mc.ligar(EVm); pg0.construir(0);
        var trX = TRD.criar({ fabrica: fabN }); trX.abrir(docX);
        var nar = NAR.criar({ voz: { falar: function () { return new Promise(function () {}); }, cancelar: function () {}, reiniciar: function () {} } });
        var ex = EXP.criar({ host: host, envoltorio: env, doc: function () { return docX; }, lerIdioma: function () { return LD.state.readLang; }, pagina: pg, marcacao: mc, narrador: nar, tradutor: trX, alinhar: alN, eventos: EVm });
        offs = offs.concat(ex.ligar(EVm));
        return { host: host, env: env, ex: ex, mc: mc, fim: function () { offs.forEach(function (f) { f(); }); env.remove(); } };
      }
      var glossDe = function (raiz) { var g = raiz.querySelector('.lb-gloss'); return g ? (g.hidden ? '' : g.textContent + '/' + g.lang) : ''; };
      async function compararExplorar(rotulo, passos, preparo) {
        await reiniciaHoje(); LD.tts.cursor = null; LD.emit('close'); if (preparo) await preparo();
        var E = criaNovoEx(), difs = [];
        for (var i = 0; i < passos.length; i++) {
          LD.explore.step(passos[i]); E.ex.passo(passos[i]); await wait(5);
          var h = htmlDe(LHOST) + '#' + glossDe(LW.document.getElementById('lb-wrap') || LW.document), n = htmlDe(E.host) + '#' + glossDe(E.env);
          if (h !== n) { if (!difs.length) { out.push('DIAG ' + rotulo + ' passo ' + i + ' HOJE: ' + h.replace(/<[^>]+>/g, '').slice(-140) + ' || NOVO: ' + n.replace(/<[^>]+>/g, '').slice(-140)); live(); } difs.push(i); }
        }
        var vistas = E.host.querySelectorAll('.wd.now').length;
        E.fim(); return { difs: difs, vistas: vistas };
      }
      var PASSOS = []; for (var s1 = 0; s1 < 26; s1++) PASSOS.push(1); for (var s2 = 0; s2 < 9; s2++) PASSOS.push(-1); for (var s3 = 0; s3 < 6; s3++) PASSOS.push(1);
      var e1 = await compararExplorar('leitura em inglês', PASSOS);
      ok('EX1 SETAS PALAVRA A PALAVRA (lendo em inglês): 41 passos para a frente e para trás, atravessando frases, a estrofe e os parágrafos: a palavra marcada, a frase e a etiqueta da palavra equivalente em português são IGUAIS ao app de hoje a cada passo', e1.difs.length === 0 && e1.vistas === 1, e1.difs.length + ' passos diferentes');
      LW.postMessage({ type: 'readlang', value: 'pt' }, '*'); await wait(500);
      var e2 = await compararExplorar('leitura em português', PASSOS);
      ok('EX2 SETAS (lendo em português, equivalente em inglês na etiqueta): IGUAL ao app de hoje a cada passo; a palavra equivalente fica em outra marca (etiqueta) e a principal continua uma só', e2.difs.length === 0 && e2.vistas === 1, e2.difs.length + ' passos diferentes');
      LD.setMode('side'); await wait(400);
      var e3 = await compararExplorar('lado a lado', PASSOS.slice(0, 22));
      ok('EX6 LADO A LADO: a palavra equivalente fica marcada, em outra cor (.now2), na coluna da tradução; HTML IGUAL ao do app de hoje a cada passo', e3.difs.length === 0, e3.difs.length + ' passos diferentes');
      LD.setMode('single'); LW.postMessage({ type: 'readlang', value: 'en' }, '*'); await wait(400);
      // sair da exploração quando a narração toca uma frase, e o ▶ continuar dali
      var Ex2 = criaNovoEx(); Ex2.ex.passo(1); Ex2.ex.passo(1); var antesEx = Ex2.ex.estado();
      EVm.emit('narracao-frase', { p: 2, s: 0, texto: 'Understanding that fact is the first step towards resisting it.', idioma: 'en' });
      ok('EX8 a exploração termina quando a narração toca uma frase (o estado volta a "nenhuma palavra explorada" e a etiqueta some)', !!antesEx && Ex2.ex.estado() === null && glossDe(Ex2.env) === '', JSON.stringify(antesEx));
      Ex2.fim(); await reiniciaHoje();
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
