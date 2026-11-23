<#
  test_novo_nucleo.ps1 — confere, no Chrome, o NÚCLEO do app novo (site/novo/, fase R1; ver docs/07 e docs/08).

  Abre novo/index.html (app de verdade) e depois exercita cada módulo:
    NU1   o app liga sozinho: todos os módulos prontos
    NU2-4 eventos tipados, preferências (valida, limita, compatível com o app de hoje)
    NU5   localStorage seguro
    NU6   banco do app de hoje (dd-ingles): aberto SEM mudar a versão 2; o app antigo ainda abre depois
    NU7   banco novo (dd-ingles-novo)
    NU8-12 migração com cópia de segurança automática, restauração, cancelamento se a cópia falhar, banco de versão mais nova, só 3 cópias
    NU13-17 rotas e telas (parâmetros, rota desconhecida, erro numa tela não derruba o app, texto nunca vira HTML, tela Sistema)
    NU18  registro de módulos: ordem, dependência faltando, ciclo, módulo que falha, fábrica assíncrona
  Uso: pwsh tools\test_novo_nucleo.ps1 [-Chrome <caminho>]    (sai com 1 se alguma verificação falhar)
#>
param([string]$Chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe')
$ErrorActionPreference = 'Stop'
$enc = New-Object System.Text.UTF8Encoding($false)
$repo = Split-Path -Parent $PSScriptRoot
$tmp = Join-Path ([IO.Path]::GetTempPath()) ('dd-nuc-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory $tmp | Out-Null
robocopy $repo $tmp /E /XD .git .github /NFL /NDL /NJH /NJS /NP | Out-Null

$test = @'
<script>
(function () {
  var out = [], fails = 0;
  function live() { var p = document.getElementById('result'); if (!p) { p = document.createElement('pre'); p.id = 'result'; p.style.cssText = 'position:fixed;left:-99999px;top:0;width:10px;height:10px;overflow:hidden'; document.body.appendChild(p); } p.textContent = out.join(String.fromCharCode(10)); }
  function ok(name, cond, extra) { if (!cond) fails++; out.push((cond ? 'PASS ' : 'FAIL ') + name + (extra ? '  [' + extra + ']' : '')); live(); }
  function wait(ms) { return new Promise(function (r) { setTimeout(r, ms); }); }
  // O Chrome de teste usa tempo VIRTUAL: enquanto a página espera o disco (IndexedDB) o relógio corre (um open pode gastar ~100 s virtuais) e, sem nenhum timer ativo, a página até para.
  // Por isso: um batimento de timer durante o teste (parado no fim) e prazos de espera generosos (o argumento ms é ignorado de propósito).
  var hb = setInterval(function () {}, 4);
  async function until(fn, ms) { var t = Date.now(); while (Date.now() - t < 900000) { try { if (fn()) return true; } catch (e) {} await wait(100); } return false; }
  function abreRaw(n, v) { return new Promise(function (res, rej) { var r = v ? indexedDB.open(n, v) : indexedDB.open(n); r.onsuccess = function () { res(r.result); }; r.onerror = function () { rej(r.error); }; }); }
  async function lancaErro(fn) { try { await fn(); return null; } catch (e) { return String((e && e.message) || e); } }

  window.addEventListener('load', async function () {
    try {
      await until(function () { return window.__appPronto; }, 20000);
      var rel = window.__appPronto || { modulos: [] };
      var nomes = rel.modulos.map(function (m) { return m.nome + ':' + m.estado; }).join(' ');
      ok('NU1 o app liga sozinho: eventos, armazem, config, rotas, telas e inicio prontos', rel.ok === true && rel.modulos.length === 6, nomes);

      var ev = App.get('eventos'), ar = App.get('armazem'), cf = App.get('config'), rt = App.get('rotas');

      // ===================== eventos =====================
      var e1 = await lancaErro(function () { ev.emit('nao-existe', {}); }), e2 = await lancaErro(function () { ev.on('nao-existe', function () {}); }), e3 = await lancaErro(function () { ev.declarar('Nome Ruim'); });
      ok('NU2a evento desconhecido (emitir ou escutar) e nome inválido são erros claros', /desconhecido/.test(e1 || '') && /desconhecido/.test(e2 || '') && /inválido/.test(e3 || ''), e1);
      ev.declarar('teste-ping', 'só para teste'); var visto = [], desliga = ev.on('teste-ping', function (d) { visto.push('a' + d); }); ev.on('teste-ping', function () { throw new Error('boom'); }); ev.on('teste-ping', function (d) { visto.push('c' + d); });
      var rodou = ev.emit('teste-ping', 1);
      ok('NU2b um escutador que falha não impede os outros nem quem emitiu, e o erro fica registrado', visto.join(',') === 'a1,c1' && rodou === 2 && ev.erros.some(function (x) { return x.evento === 'teste-ping' && /boom/.test(x.erro); }));
      desliga(); ev.emit('teste-ping', 2); var vezes = 0; ev.uma('teste-ping', function () { vezes++; }); ev.emit('teste-ping', 3); ev.emit('teste-ping', 4);
      ok('NU2c o "desligar" devolvido por on() funciona e uma() dispara uma só vez', visto.join(',') === 'a1,c1,c2,c3,c4' && vezes === 1, visto.join(','));

      // ===================== preferências =====================
      var chaves = Object.keys(cf.PADRAO).sort().join(',');
      ok('NU3a as chaves de preferência são as do app de hoje (dd-settings compatível)', chaves === 'align,audioLang,face,font,margin,rate,readLang,theme,voices', chaves);
      localStorage.setItem('dd-settings', JSON.stringify({ extra: 'so-o-app-antigo-conhece', theme: 'dark', rate: 1.5, font: 999, face: 'comic' }));
      var rc = cf.recarregar();
      ok('NU3b lê o que o app de hoje gravou e limpa valores inválidos (fonte 999 vira 28, fonte desconhecida volta ao padrão)', rc.theme === 'dark' && rc.rate === 1.5 && rc.font === 28 && rc.face === 'serif', JSON.stringify(rc));
      var mudou = []; ev.on('config-mudou', function (d) { mudou.push(d); });
      var r1 = cf.set('theme', 'neon'), r2 = cf.set('rate', 9), r3 = cf.set('rate', 0.04), r4 = cf.set('rate', 1.26), r5 = cf.set('font', 5), r6 = cf.set('readLang', 'fr');
      ok('NU3c valores fora do permitido são limitados: tema inválido → paper, velocidade 0,1–3 de 0,1 em 0,1, fonte 14–28, idioma só pt/en', r1 === 'paper' && r2 === 3 && r3 === 0.1 && r4 === 1.3 && r5 === 14 && r6 === 'pt', [r1, r2, r3, r4, r5, r6].join('|'));
      var guardado = JSON.parse(localStorage.getItem('dd-settings'));
      ok('NU3d gravar uma preferência preserva campos que só o app antigo conhece e avisa config-mudou com o valor anterior', guardado.extra === 'so-o-app-antigo-conhece' && guardado.theme === 'paper' && mudou.length >= 1 && mudou[0].chave === 'theme' && mudou[0].antes === 'dark', JSON.stringify(mudou[0]));
      var sem = await lancaErro(function () { cf.set('chave-inexistente', 1); });
      cf.set('theme', 'paper');
      ok('NU3e chave de preferência desconhecida é erro claro; mudar o tema muda a aparência da página', /desconhecida/.test(sem || '') && cf.set('theme', 'sepia') === 'sepia' && document.body.className === 'sepia-mode' && cf.set('theme', 'paper') === 'paper' && document.body.className === 'paper-mode', document.body.className);

      // ===================== localStorage seguro =====================
      ar.ls.set('nu-teste', { a: 1 }); var lsv = ar.ls.get('nu-teste', null), lsd = ar.ls.get('nu-nao-existe', 'padrao'); ar.ls.remove('nu-teste');
      ok('NU5 localStorage seguro: guarda e lê JSON, devolve o padrão se não existir, remove', lsv && lsv.a === 1 && lsd === 'padrao' && ar.ls.get('nu-teste', 'x') === 'x' && ar.ls.disponivel() === true);

      // ===================== banco do app de hoje =====================
      var lg = await ar.legado();
      await lg.put('meta', { id: 'm1', title: 'Livro antigo', pos: 7 }); await lg.put('vocab', { id: 'en:teste', word: 'teste', reps: 2 }); await lg.put('tr', 'traduzida', 'm1:0');
      var vL = await ar.lerVersao('dd-ingles');
      ok('NU6a o banco do app de hoje abre na versão 2, com as 4 stores do app antigo, e a versão NÃO muda', lg.versao === 2 && vL === 2 && lg.stores().sort().join(',') === 'docs,meta,tr,vocab', 'versao=' + vL + ' stores=' + lg.stores().sort().join(','));
      var m1 = await lg.get('meta', 'm1'), v1 = await lg.get('vocab', 'en:teste'), t1 = await lg.get('tr', 'm1:0');
      ok('NU6b lê e grava no banco antigo (meta, vocab e tr com chave externa)', m1 && m1.pos === 7 && v1 && v1.reps === 2 && t1 === 'traduzida');
      var antigo = await abreRaw('dd-ingles', 2), mAnt = await new Promise(function (res) { var q = antigo.transaction('meta').objectStore('meta').get('m1'); q.onsuccess = function () { res(q.result); }; }); antigo.close();
      ok('NU6c o app de hoje ainda abre o banco na versão 2 depois do núcleo novo (sem erro de versão) e enxerga os dados', mAnt && mAnt.title === 'Livro antigo');

      // ===================== banco novo =====================
      var nv = await ar.novo();
      await nv.put('registro', { dia: '2026-11-22', lendo: 60 }); var id1 = null, id2 = null;
      await nv.put('escrita', { texto: 'um' }); await nv.put('escrita', { texto: 'dois' }); var esc = await nv.all('escrita'); id1 = esc[0].id; id2 = esc[1].id;
      ok('NU7 banco novo: versão 1 com as 6 stores, registro por dia e escrita com número automático', nv.versao === 1 && nv.stores().sort().join(',') === 'cartoes,escrita,kv,plano,posicoes,registro' && (await nv.get('registro', '2026-11-22')).lendo === 60 && id2 === id1 + 1, nv.stores().sort().join(','));

      // ===================== migração com cópia de segurança =====================
      var N = 'dd-teste-mig', evMig = null; ev.on('armazem-migrado', function (d) { evMig = d; });
      var v1def = { v: 1, sobe: function (d) { d.createObjectStore('a', { keyPath: 'id' }); d.createObjectStore('b'); } };
      var b1 = await ar.abrirBanco(N, [v1def]); await b1.put('a', { id: 1, x: 'um' }); await b1.put('a', { id: 2, x: 'dois' }); await b1.put('b', 'valor', 'k1'); b1.fechar();
      var v2def = { v: 2, sobe: function (d) { d.createObjectStore('c', { keyPath: 'id' }); } };
      var b2 = await ar.abrirBanco(N, [v1def, v2def]); var cps = await ar.copias(N);
      ok('NU8a migrar de v1 para v2 guarda ANTES uma cópia de segurança com tudo (3 itens), avisa armazem-migrado e preserva os dados', b2.versao === 2 && b2.stores().indexOf('c') >= 0 && (await b2.all('a')).length === 2 && (await b2.get('b', 'k1')) === 'valor' && cps.length === 1 && cps[0].itens === 3 && cps[0].de === 1 && evMig && evMig.de === 1 && evMig.para === 2 && evMig.copia === cps[0].id, JSON.stringify(cps));
      await b2.del('a', 1); await b2.put('a', { id: 9, x: 'novo' }); await b2.put('b', 'outro', 'k2');
      var voltou = await ar.restaurarCopia(N, cps[0].id); var b2b = await ar.abrirBanco(N, [v1def, v2def]); var ids = (await b2b.all('a')).map(function (x) { return x.id; }).sort().join(',');
      ok('NU9 restaurar a cópia desfaz o que mudou depois (volta a id 1 e 2, some o id 9, valor k1 volta e k2 some)', voltou === 3 && ids === '1,2' && (await b2b.get('b', 'k1')) === 'valor' && (await b2b.get('b', 'k2')) === undefined, 'voltaram ' + voltou + ' ids=' + ids);
      b2.fechar(); b2b.fechar();

      var F = 'dd-teste-falha'; var f1 = await ar.abrirBanco(F, [v1def]); await f1.put('a', { id: 1, x: 'intacto' }); f1.fechar();
      (await abreRaw(F + '-backup', 5)).close();                              // banco de cópias numa versão maior: a cópia não consegue abrir
      var erroEv = null; ev.on('armazem-erro', function (d) { if (d.banco === F) erroEv = d; });
      var eMig = await lancaErro(function () { return ar.abrirBanco(F, [v1def, v2def]); }); var vF = await ar.lerVersao(F); var fchk = await abreRaw(F); var dadoF = await new Promise(function (res) { var q = fchk.transaction('a').objectStore('a').get(1); q.onsuccess = function () { res(q.result); }; }); fchk.close();
      ok('NU10 se a cópia de segurança não puder ser guardada, a migração é CANCELADA: o banco continua na v1 com os dados intactos e o erro é avisado', /cópia de segurança/.test(eMig || '') && vF === 1 && dadoF && dadoF.x === 'intacto' && erroEv && /cópia/.test(erroEv.erro), (eMig || '').slice(0, 90) + ' v=' + vF);

      var G = 'dd-teste-maior'; (await abreRaw(G, 3)).close();
      var gb = await ar.abrirBanco(G, [v1def, v2def]);
      ok('NU11 banco gravado numa versão MAIS NOVA (ex.: outro aparelho/aba) abre como está, sem erro e sem tocar', gb.versao === 3); gb.fechar();

      var K = 'dd-teste-copias', defs = [v1def];
      var k1 = await ar.abrirBanco(K, defs); await k1.put('a', { id: 1 }); k1.fechar();
      for (var n = 2; n <= 5; n++) { defs = defs.concat([{ v: n, sobe: (function (nn) { return function (d) { d.createObjectStore('s' + nn); }; })(n) }]); var kk = await ar.abrirBanco(K, defs); kk.fechar(); await wait(5); }
      var kcp = await ar.copias(K);
      ok('NU12 quatro migrações seguidas guardam só as 3 cópias mais recentes (v2→3→4→5; a de v1→2 sai)', kcp.length === 3 && kcp.map(function (c) { return c.de; }).sort().join(',') === '2,3,4', kcp.map(function (c) { return c.de; }).join(','));

      // ===================== rotas e telas =====================
      var c1 = rt.casar('/ler/abc%20d'), c2 = rt.casar('/nada/aqui'), c3 = rt.casar('/hoje');
      var dup = await lancaErro(function () { rt.registrar('/hoje', { montar: function () {} }); }), sem2 = await lancaErro(function () { rt.registrar('sem-barra', { montar: function () {} }); });
      ok('NU13a casar rotas: parâmetro vem decodificado, rota desconhecida dá nulo; rota repetida e padrão inválido são erros', c1 && c1.params.livro === 'abc d' && c2 === null && c3 && c3.rota === '/hoje' && /repetida/.test(dup || '') && /começar/.test(sem2 || ''), JSON.stringify(c1 && c1.params));
      var vista = document.getElementById('vista');
      location.hash = '#/palavras'; await until(function () { return /Palavras/.test(vista.textContent) && /fase R3/.test(vista.textContent); }, 8000);
      var menuOn = Array.prototype.map.call(document.querySelectorAll('#novo-menu a.on'), function (a) { return a.textContent; }).join(',');
      ok('NU13b navegar pelo endereço troca a tela, marca o item do menu e atualiza o título', /Palavras/.test(vista.textContent) && menuOn === 'Palavras' && /Palavras/.test(document.title), menuOn + ' | ' + document.title);
      location.hash = '#/rota-que-nao-existe'; await until(function () { return /Hoje/.test(vista.textContent) && location.hash === '#/hoje'; }, 8000);
      ok('NU14 rota desconhecida cai na tela Hoje e o endereço é corrigido para #/hoje', /Hoje/.test(vista.textContent) && location.hash === '#/hoje', location.hash);
      rt.registrar('/teste-erro', { titulo: 'Erro', montar: function () { throw new Error('tela quebrada'); } });
      location.hash = '#/teste-erro'; await until(function () { return /não abriu/.test(vista.textContent); }, 8000); var msgErro = vista.textContent;
      location.hash = '#/estante'; await until(function () { return /Estante/.test(vista.textContent) && /fase R3/.test(vista.textContent); }, 8000);
      ok('NU15 uma tela que falha mostra o aviso no lugar dela e o app continua: a próxima tela abre normal', /Esta tela não abriu: tela quebrada/.test(msgErro) && /Estante/.test(vista.textContent), msgErro.slice(0, 60));
      location.hash = '#/ler/' + encodeURIComponent('<b>negrito</b><img src=x onerror=alert(1)>'); await until(function () { return /Leitura/.test(vista.textContent); }, 8000);
      ok('NU16 texto vindo do endereço aparece como texto, nunca vira HTML (sem <b> nem <img> criados)', vista.querySelectorAll('b, img').length === 0 && vista.textContent.indexOf('<b>negrito</b>') >= 0, vista.querySelectorAll('b, img').length + ' elementos');
      location.hash = '#/sistema'; await until(function () { var b = document.getElementById('sis-armazem'); return b && /IndexedDB/.test(b.textContent); }, 15000);
      var sisMods = document.querySelectorAll('#sis-modulos li[data-estado="pronto"]').length, sisTxt = document.getElementById('sis-armazem').textContent;
      ok('NU17 a tela Sistema lista os 6 módulos prontos e mostra o armazenamento e as versões dos dois bancos (antigo v2, novo v1)', sisMods === 6 && /IndexedDB: sim/.test(sisTxt) && /versão 2/.test(sisTxt) && /dd-ingles-novo\)\: versão 1/.test(sisTxt) && !!document.getElementById('sis-persistir'), 'prontos=' + sisMods);

      // ===================== registro de módulos (depois de zerar o registro do app) =====================
      App._zerar();
      var ordem = []; App.define('c', [], function () { ordem.push('c'); return { n: 3 }; });
      App.define('a', ['b'], function (d) { ordem.push('a'); return { soma: d.b.n + 1 }; });
      App.define('b', ['c'], async function (d) { await wait(30); ordem.push('b'); return { n: d.c.n + 1 }; });
      App.define('sem-dep', ['nao-existe'], function () { return {}; }); App.define('filho-de-sem-dep', ['sem-dep'], function () { return {}; });
      App.define('x', ['y'], function () { return {}; }); App.define('y', ['x'], function () { return {}; });
      App.define('quebra', [], function () { throw new Error('falhou ao iniciar'); }); App.define('depende-de-quebra', ['quebra'], function () { return {}; }); App.define('independente', [], function () { return { ok: true }; });
      var rr = await App.boot(), st = {}; rr.modulos.forEach(function (m) { st[m.nome] = m; });
      ok('NU18a os módulos iniciam em ordem de dependência (c, b, a), mesmo definidos fora de ordem, e a fábrica assíncrona é esperada', ordem.join('') === 'cba' && App.get('a').soma === 5 && st.a.estado === 'pronto', ordem.join(','));
      ok('NU18b dependência não definida e dependência circular viram erro claro; quem depende fica bloqueado', st['sem-dep'].estado === 'erro' && /não foi definido/.test(st['sem-dep'].erro) && st['filho-de-sem-dep'].estado === 'bloqueado' && (st.x.estado === 'erro' || st.y.estado === 'erro') && /circular/.test((st.x.erro || '') + (st.y.erro || '')), (st.x.erro || st.y.erro || ''));
      ok('NU18c um módulo que falha não derruba os outros: o que depende dele fica bloqueado e o independente continua pronto', st.quebra.estado === 'erro' && /falhou ao iniciar/.test(st.quebra.erro) && st['depende-de-quebra'].estado === 'bloqueado' && st.independente.estado === 'pronto' && rr.ok === false);
      var tarde = await lancaErro(function () { App.define('tarde', [], function () {}); }), rep = await lancaErro(function () { App._zerar(); App.define('r', [], function () {}); App.define('r', [], function () {}); }), get1 = await lancaErro(function () { App.get('nao-existe'); });
      ok('NU18d definir depois do boot, repetir nome e pedir módulo inexistente são erros claros', /já iniciou/.test(tarde || '') && /repetido/.test(rep || '') && /desconhecido/.test(get1 || ''), [tarde, rep, get1].join(' | '));
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
