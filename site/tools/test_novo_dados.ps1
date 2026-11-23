<#
  test_novo_dados.ps1 — confere, no Chrome, os DADOS do app novo (site/novo/, fase R1b; ver docs/07, 08 e 09):
  mescla, snapshot, backup por arquivo, registro de estudo, espelho da leitura, conta e sincronização (nuvem simulada) e a tela #/dados.

  A peça central é a PARIDADE COM O APP DE HOJE: o teste carrega o app atual (../ingles.html) numa moldura e compara, com os mesmos dados,
    NUD1  a mescla do app novo com a do app de hoje (casos fixos + 300 pares aleatórios com semente fixa)
    NUD2  o snapshot (os dois leem o mesmo banco e o mesmo localStorage)
    NUD3  arquivos de backup nos dois sentidos (exportado por um, importado pelo outro) e arquivo inválido
  Depois: NUD4 livros pendentes · NUD5 livro aberto não muda · NUD6 registro e espelho · NUD7 nuvem (login, sincronizar, conflito, sessão vencida,
  sem rede) · NUD8 tela #/dados.
  Uso: pwsh tools\test_novo_dados.ps1 [-Chrome <caminho>]    (sai com 1 se alguma verificação falhar)
#>
param([string]$Chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe')
$ErrorActionPreference = 'Stop'
$enc = New-Object System.Text.UTF8Encoding($false)
$repo = Split-Path -Parent $PSScriptRoot
$tmp = Join-Path ([IO.Path]::GetTempPath()) ('dd-nud-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory $tmp | Out-Null
robocopy $repo $tmp /E /XD .git .github /NFL /NDL /NJH /NJS /NP | Out-Null

$test = @'
<script>
(function () {
  var out = [], fails = 0;
  function live() { var p = document.getElementById('result'); if (!p) { p = document.createElement('pre'); p.id = 'result'; p.style.cssText = 'position:fixed;left:-99999px;top:0;width:10px;height:10px;overflow:hidden'; document.body.appendChild(p); } p.textContent = out.join(String.fromCharCode(10)); }
  function ok(name, cond, extra) { if (!cond) fails++; out.push((cond ? 'PASS ' : 'FAIL ') + name + (extra ? '  [' + extra + ']' : '')); live(); }
  function wait(ms) { return new Promise(function (r) { setTimeout(r, ms); }); }
  // Tempo VIRTUAL do Chrome de teste (ver docs/09, seção 8): batimento de timer + prazos generosos.
  var hb = setInterval(function () {}, 4);
  async function until(fn, ms) { var t = Date.now(); while (Date.now() - t < 900000) { try { if (fn()) return true; } catch (e) {} await wait(100); } return false; }
  async function lancaErro(fn) { try { await fn(); return null; } catch (e) { return String((e && e.message) || e); } }
  function semCarimbo(o) { var c = JSON.parse(JSON.stringify(o)); delete c.at; delete c.device; return c; }
  function igual(a, b) { return JSON.stringify(a) === JSON.stringify(b); }

  window.addEventListener('load', async function () {
    try {
      await until(function () { return window.__appPronto; });
      var M = App.get('mescla'), dados = App.get('dados'), reg = App.get('registro'), nv = App.get('nuvem'), ar = App.get('armazem'), ev = App.get('eventos'), cf = App.get('config'), rt = App.get('rotas');
      var lg = await ar.legado();
      async function zera() {
        ['dd-ingles-log', 'dd-ingles-dia-hist', 'dd-ingles-semana-hist', 'dd-ingles-escrita', 'dd-ingles-pend-docs', 'dd-ingles-sessao', 'dd-sync-sess', 'dd-sync-last'].forEach(function (k) { localStorage.removeItem(k); });
        for (var s of ['meta', 'vocab', 'docs', 'tr']) await lg.limpar(s);
      }
      async function semeia() {
        await zera();
        localStorage.setItem('dd-ingles-log', JSON.stringify({ d: { '2026-05-01': { sec: 300, heard: 40, saved: 1, rev: 2, dict: 0, rd: 100, ls: 200 }, '2026-05-02': { sec: 60, heard: 5, saved: 0, rev: 0, dict: 1, rd: 20, ls: 10 } } }));
        localStorage.setItem('dd-ingles-dia-hist', JSON.stringify({ '2026-05-01': { ok: true } }));
        localStorage.setItem('dd-ingles-semana-hist', JSON.stringify([{ n: 1, livro: 'Livro A' }]));
        localStorage.setItem('dd-ingles-escrita', JSON.stringify([{ date: '2026-05-01', kind: 'dia', title: 'Livro A', text: 'um texto escrito pelo aluno com bastante palavras' }]));
        await lg.put('vocab', { id: 'en:alfa', word: 'alfa', lang: 'en', reps: 3, lapses: 0, due: 10, ivl: 3, ease: 2.5, added: 1, sent: 'frase de contexto' });
        await lg.put('vocab', { id: 'en:beta', word: 'beta', lang: 'en', reps: 1, lapses: 1, due: 5, ivl: 1, ease: 2.3, added: 2 });
        await lg.put('meta', { id: 'm-a', title: 'Livro A', lang: 'en', pos: 5, heard: 50, words: 100, sentences: 10, savedAt: 1700000000000 });
        await lg.put('meta', { id: 'm-b', title: 'Livro B', lang: 'pt', pos: 1, heard: 0, words: 20, sentences: 3, lastOpened: 1700000001000 });
      }

      // ===== carrega o app de hoje numa moldura (referência para a paridade) =====
      var fr = document.createElement('iframe'); fr.id = 'leg'; fr.src = '../ingles.html'; fr.style.cssText = 'position:fixed;left:-9999px;width:900px;height:600px'; document.body.appendChild(fr);
      var carregou = await until(function () { return fr.contentWindow && fr.contentWindow.DDLab && fr.contentWindow.DDLab.sync && fr.contentWindow.DDLab.sync.exportData; });
      var LEG = fr.contentWindow.DDLab.sync;
      ok('NUD0 o app de hoje carrega na moldura de referência (mescla, snapshot e backup disponíveis)', carregou && !!LEG.merge && !!LEG.snapshot && !!LEG.importData);

      // ===================== NUD1 · mescla: app novo = app de hoje =====================
      var fa = { log: { d: { '2026-01-01': { sec: 100, heard: 5 } } }, vocab: [{ id: 'en:a', reps: 1 }, { id: 'en:b', reps: 4 }], semHist: [{ n: 1 }], escrita: [{ date: 'x', title: 't', text: 'um' }], docs: { 'livro|en': { title: 'Livro', lang: 'en', pos: 10, heard: 50, savedAt: 100 } } };
      var fb = { log: { d: { '2026-01-01': { sec: 80, heard: 9 }, '2026-01-02': { sec: 30 } } }, vocab: [{ id: 'en:a', reps: 3 }, { id: 'en:b', reps: 2 }, { id: 'en:c', reps: 0 }], semHist: [{ n: 1 }, { n: 2 }], escrita: [{ date: 'x', title: 't', text: 'um' }, { date: 'y', title: 't', text: 'dois' }], docs: { 'livro|en': { title: 'Livro', lang: 'en', pos: 70, heard: 20, savedAt: 200 } } };
      var casos = [[fa, fb], [fb, fa], [fa, null], [null, fb], [{}, {}], [null, null], [undefined, fb], [fa, { log: { d: { z: { sec: 'texto' } } } }]];
      var dif = casos.filter(function (c) { return !igual(semCarimbo(M.merge(c[0], c[1])), semCarimbo(LEG.merge(c[0], c[1]))); }).length;
      ok('NUD1a mesclar os 8 casos fixos (inclusive vazios, nulos e campo não numérico) dá o MESMO resultado nos dois apps', dif === 0, dif + ' diferenças');
      function rnd(seed) { return function () { seed |= 0; seed = seed + 0x6D2B79F5 | 0; var t = Math.imul(seed ^ seed >>> 15, 1 | seed); t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t; return ((t ^ t >>> 14) >>> 0) / 4294967296; }; }
      var R = rnd(20261122);
      function pick(a) { return a[Math.floor(R() * a.length)]; }
      function gera() {
        var s = { log: { d: {} }, vocab: [], docs: {}, semHist: [], escrita: [], diaHist: null };
        for (var i = 0, nd = Math.floor(R() * 4); i < nd; i++) { var o = {}; ['sec', 'heard', 'saved', 'rev', 'dict', 'rd', 'ls', 'x'].forEach(function (f) { if (R() < 0.6) o[f] = f === 'x' ? 'txt' : Math.floor(R() * 500); }); s.log.d[pick(['2026-01-01', '2026-01-02', '2026-01-03'])] = o; }
        for (var j = 0, nv = Math.floor(R() * 5); j < nv; j++) s.vocab.push(R() < 0.06 ? { reps: 9 } : { id: pick(['en:a', 'en:b', 'en:c', 'pt:d']), reps: Math.floor(R() * 6), lapses: Math.floor(R() * 3), due: Math.floor(R() * 100), word: 'w' + Math.floor(R() * 9) });
        ['livro a|en', 'livro b|pt', 'livro c|en'].forEach(function (k) { if (R() < 0.6) s.docs[k] = { title: k, lang: 'en', pos: Math.floor(R() * 90), heard: Math.floor(R() * 300), words: Math.floor(R() * 900), savedAt: Math.floor(R() * 1000) }; });
        for (var k = 0, nh = Math.floor(R() * 3); k < nh; k++) s.semHist.push({ n: Math.floor(R() * 4) });
        for (var m = 0, ne = Math.floor(R() * 4); m < ne; m++) s.escrita.push({ date: pick(['2026-01-01', '2026-01-02']), kind: pick(['dia', 'semana', undefined]), title: 't' + Math.floor(R() * 3), text: 'abc' + Math.floor(R() * 3) });
        var q = R(); s.diaHist = q < 0.3 ? null : q < 0.6 ? [{ d: Math.floor(R() * 3) }] : { a: Math.floor(R() * 3), b: { c: Math.floor(R() * 2) } };
        return s;
      }
      var totalF = 300, difF = 0, primeiro = '';
      for (var n = 0; n < totalF; n++) { var A = gera(), B = gera(), x1 = semCarimbo(M.merge(A, B)), x2 = semCarimbo(LEG.merge(A, B)); if (!igual(x1, x2)) { difF++; if (!primeiro) primeiro = JSON.stringify(A).slice(0, 80); } }
      ok('NUD1b mesclar 300 pares aleatórios (semente fixa) dá o MESMO resultado nos dois apps, byte a byte', difF === 0, difF + ' de ' + totalF + ' diferentes' + (primeiro ? ' ex.: ' + primeiro : ''));
      var A2 = gera(), B2 = gera(), C2 = gera(), idem = igual(semCarimbo(M.merge(M.merge(A2, B2), B2)), semCarimbo(M.merge(A2, B2)));
      ok('NUD1c propriedades: mesclar duas vezes o mesmo dado não muda nada (idempotente) e o resultado de A+B não perde nenhum dia, cartão ou livro de A nem de B', idem && (function () { var r = M.merge(A2, B2), ok1 = true; [A2, B2].forEach(function (s) { Object.keys(s.log.d).forEach(function (d) { if (!r.log.d[d]) ok1 = false; }); s.vocab.forEach(function (c) { if (c.id && !r.vocab.some(function (v) { return v.id === c.id; })) ok1 = false; }); Object.keys(s.docs).forEach(function (k) { if (!r.docs[k]) ok1 = false; }); }); return ok1; })());

      // ===================== NUD2 · snapshot: os dois leem o mesmo banco e o mesmo localStorage =====================
      await semeia();
      var s1 = await dados.snapshot(), s2 = await LEG.snapshot();
      ok('NUD2 com os mesmos dados no aparelho, o snapshot do app novo é IGUAL ao do app de hoje (estatísticas, históricos, escrita, cartões e livros)', igual(semCarimbo(s1), semCarimbo(s2)) && s1.device === s2.device && s1.vocab.length === 2 && Object.keys(s1.docs).length === 2, JSON.stringify(Object.keys(s1.docs)));

      // ===================== NUD3 · backup nos dois sentidos =====================
      var arqNovo = await dados.exportar(), po = JSON.parse(arqNovo);
      ok('NUD3a exportar gera o formato v1 do app de hoje (app, v, exportedAt, data) e SEM o corpo dos livros', po.app === 'ingles-progresso' && po.v === 1 && !!po.exportedAt && po.data.vocab.length === 2 && !/"paras"/.test(arqNovo));
      var alvo = semCarimbo(await dados.snapshot());
      await zera(); await LEG.importData(arqNovo);                            // arquivo do app NOVO carregado no app de HOJE
      var viaLegado = semCarimbo(await dados.snapshot());
      ok('NUD3b um arquivo exportado pelo app NOVO, carregado no app de HOJE, restaura exatamente o mesmo progresso', igual(viaLegado, alvo), JSON.stringify(viaLegado).length + ' vs ' + JSON.stringify(alvo).length);
      await semeia(); var arqLeg = await LEG.exportData(); var alvo2 = semCarimbo(await LEG.snapshot());
      await zera(); var rImp = await dados.importar(arqLeg); var viaNovo = semCarimbo(await dados.snapshot());
      ok('NUD3c um arquivo exportado pelo app de HOJE, carregado no app NOVO, restaura exatamente o mesmo progresso (e informa dias, cartões e livros)', igual(viaNovo, alvo2) && rImp.days === 2 && rImp.cards === 2 && rImp.books === 2, JSON.stringify(rImp));
      var rImp2 = await dados.importar(arqLeg);
      ok('NUD3d carregar o mesmo arquivo de novo não duplica nada (0 dias e 0 cartões novos; o snapshot não muda)', rImp2.days === 0 && rImp2.cards === 0 && igual(semCarimbo(await dados.snapshot()), alvo2));
      var recusas = []; for (var bad of ['{"x":1}', 'isso nao e json', JSON.stringify({ app: 'outro', v: 1, data: {} }), JSON.stringify({ app: 'ingles-progresso', v: 2, data: {} }), JSON.stringify({ app: 'ingles-progresso', v: 1 }), '']) { var e1 = await lancaErro(function () { return dados.importar(bad); }), e2 = await lancaErro(function () { return LEG.importData(bad); }); recusas.push((e1 === 'formato') + '/' + (e2 === 'formato')); }
      ok('NUD3e arquivos que não são backup (6 casos) são recusados com o mesmo erro nos dois apps, sem mudar nada', recusas.every(function (r) { return r === 'true/true'; }) && igual(semCarimbo(await dados.snapshot()), alvo2), recusas.join(' '));
      var parcial = JSON.stringify({ app: 'ingles-progresso', v: 1, data: { vocab: [{ id: 'en:so', reps: 1 }, null, { word: 'sem id' }, { id: 7 }], log: 'quebrado', docs: [], semHist: 'x' } });
      await dados.importar(parcial); var sp = await dados.snapshot();
      ok('NUD3f arquivo com partes quebradas é aceito só no que é válido: cartão com id entra, os inválidos e as seções erradas são ignorados, e nada que existia se perde', sp.vocab.some(function (c) { return c.id === 'en:so'; }) && sp.vocab.length === 3 && sp.vocab.every(function (c) { return typeof c.id === 'string'; }) && Object.keys(sp.log.d).length === 2 && Object.keys(sp.docs).length === 2);

      // ===================== NUD4 · livros que ainda não estão neste aparelho =====================
      await semeia(); var arq4 = await dados.exportar(); await zera();
      await dados.importar(arq4);
      var pend = JSON.parse(localStorage.getItem('dd-ingles-pend-docs') || '{}');
      ok('NUD4a livros do backup que ainda não existem aqui ficam pendentes (posição e palavras ouvidas), vão nos próximos backups e ainda não criam livro nenhum', Object.keys(pend).sort().join(',') === 'livro a|en,livro b|pt' && (await lg.all('meta')).length === 0 && JSON.parse(await dados.exportar()).data.docs['livro a|en'].heard === 50);
      var livroA = { title: 'Livro A', lang: 'en', paras: [{}, {}, {}] }, aplicou = dados.aplicarPendenteAoLivro(livroA), aplicou2 = dados.aplicarPendenteAoLivro({ title: 'Livro A', lang: 'en', paras: [{}, {}] });
      ok('NUD4b quando o livro entra, abre na posição guardada (limitada ao tamanho do livro: 5 vira 2) com as palavras ouvidas, e a pendência some (só vale uma vez)', aplicou === true && livroA.pos === 2 && livroA.heard === 50 && aplicou2 === false && !JSON.parse(localStorage.getItem('dd-ingles-pend-docs')).hasOwnProperty('livro a|en') && dados.aplicarPendenteAoLivro({ title: 'Nao existe', lang: 'en', paras: [] }) === false);
      await lg.put('meta', { id: 'm-b', title: 'Livro B', lang: 'pt', pos: 0, heard: 0, words: 20, sentences: 3 });          // o livro B já estava aqui, sem progresso
      await dados.aplicarPendentes();
      var mB = await lg.get('meta', 'm-b');
      ok('NUD4c um livro que já estava no aparelho recebe a posição do backup quando ela é mais nova, e a pendência dele some', mB.pos === 1 && !JSON.parse(localStorage.getItem('dd-ingles-pend-docs')).hasOwnProperty('livro b|pt'), JSON.stringify(mB));

      // ===================== NUD5 · livro aberto não muda por baixo do leitor =====================
      await semeia();
      var rem = { v: 1, log: { d: {} }, semHist: [], escrita: [], vocab: [], diaHist: null, docs: { 'livro a|en': { title: 'Livro A', lang: 'en', pos: 99, heard: 900, savedAt: 1800000000000 } } };
      await dados.apply(M.merge(await dados.snapshot(), rem), { abertos: ['m-a'] }); var ma1 = await lg.get('meta', 'm-a');
      ok('NUD5a com o livro aberto, a mescla NÃO mexe na posição nem nas palavras dele', ma1.pos === 5 && ma1.heard === 50, JSON.stringify(ma1));
      await dados.apply(M.merge(await dados.snapshot(), rem), { abertos: [] }); var ma2 = await lg.get('meta', 'm-a');
      ok('NUD5b com o livro fechado, a mescla traz a posição mais nova e o maior número de palavras ouvidas', ma2.pos === 99 && ma2.heard === 900 && ma2.savedAt === 1800000000000 && ma2.title === 'Livro A', JSON.stringify(ma2));

      // ===================== NUD6 · registro de estudo e espelho =====================
      await zera(); var hoje = reg.chaveDia(), lido = function () { return (JSON.parse(localStorage.getItem('dd-ingles-log') || '{"d":{}}').d[hoje]) || {}; };
      ev.emit('frase-ouvida', { palavras: 12 }); var depoisFrase = lido().heard; ev.emit('palavra-salva'); ev.emit('revisao-feita'); ev.emit('ditado-feito'); var l1 = lido();
      ok('NUD6a eventos (palavras ouvidas, palavra salva, revisão, ditado) são gravados NA HORA no registro do dia', depoisFrase === 12 && l1.saved === 1 && l1.rev === 1 && l1.dict === 1 && l1.heard === 12, JSON.stringify(l1));
      var fonte = { aberto: true, ouvindo: true }; reg.iniciarRelogio(function () { return fonte; }); reg.pararRelogio();          // só informa a fonte (livro aberto e ouvindo), sem deixar os timers rodando
      reg.atividade(); for (var i = 0; i < 5; i++) reg.tick();
      var antes = lido(), vista = reg.ler().d[hoje];
      ok('NUD6b os tempos (estudando, lendo, ouvindo) entram na memória a cada tique e NÃO são gravados a cada tique, mas a leitura (reg.ler) já os inclui', (antes.sec || 0) === 0 && vista.sec === 5 && vista.rd === 5 && vista.ls === 5, 'gravado=' + (antes.sec || 0) + ' visto=' + vista.sec);
      reg.iniciarRelogio(function () { return fonte; }); reg.atividade(); await wait(5300); reg.pararRelogio();
      var depois = lido();
      ok('NUD6c com o relógio ligado, o tempo é gravado de 2 em 2 s (perda máxima ≈ 2 s): depois de 5,3 s já há pelo menos 5 + 3 s gravados, e estudando, lendo e ouvindo sobem juntos', depois.sec >= 8 && depois.rd >= 8 && depois.ls >= 8 && depois.sec === depois.ls && depois.sec <= 5 + 6, JSON.stringify(depois));
      var antesParado = reg.ler().d[hoje].sec; reg.atividade(Date.now() - 120000); fonte = { aberto: true, ouvindo: false }; reg.tick(); reg.tick(); var parado = reg.ler().d[hoje].sec;
      fonte = { aberto: false, ouvindo: true }; reg.tick(); var fechado = reg.ler().d[hoje].sec;
      ok('NUD6d sem atividade recente e sem narração, ou sem livro aberto, o tempo NÃO conta', parado === antesParado && fechado === antesParado, 'sec=' + antesParado);
      var totalAntes = reg.ler().d[hoje].sec; reg.somar('sec', 3); window.dispatchEvent(new Event('pagehide')); var aposFecha = lido().sec;
      ok('NUD6e ao esconder ou fechar a aba (pagehide) TODO o tempo pendente é gravado na hora (o que já estava na memória e os 3 s novos)', aposFecha === totalAntes + 3 && reg.ler().d[hoje].sec === aposFecha, totalAntes + ' → ' + aposFecha);
      reg.somar('sec', 7); var outro = JSON.parse(localStorage.getItem('dd-ingles-log')); outro.d['2026-06-30'] = { sec: 500, heard: 9, saved: 0, rev: 0, dict: 0, rd: 0, ls: 0 }; localStorage.setItem('dd-ingles-log', JSON.stringify(outro)); reg.salvar();
      var logF = JSON.parse(localStorage.getItem('dd-ingles-log'));
      ok('NUD6f se uma mescla (backup/nuvem) gravou o registro no meio, o tempo pendente é SOMADO por cima dela: nada é sobrescrito por um valor antigo da memória', !!logF.d['2026-06-30'] && logF.d['2026-06-30'].sec === 500 && logF.d[hoje].sec === aposFecha + 7, JSON.stringify(Object.keys(logF.d)));
      var dd = new Date(); var seq = {}; for (var q = 0; q < 3; q++) { var dq = new Date(dd); dq.setDate(dq.getDate() - q); seq[reg.chaveDia(dq)] = { sec: 60, heard: 0 }; } localStorage.setItem('dd-ingles-log', JSON.stringify({ d: seq })); var s3 = reg.sequencia();
      localStorage.setItem('dd-ingles-log', JSON.stringify({ d: (function () { var o = {}, d1 = new Date(dd); d1.setDate(d1.getDate() - 1); o[reg.chaveDia(d1)] = { sec: 60 }; return o; })() }));
      ok('NUD6g sequência de dias: 3 dias seguidos contam 3; hoje ainda vazio não quebra a sequência de ontem', s3 === 3 && reg.sequencia() === 1, s3 + '/' + reg.sequencia());
      reg.espelho.gravar({ id: 'm-a', pos: 9, heard: 70 }); var esp = reg.espelho.ler();
      var m1 = reg.espelho.melhor({ id: 'm-a', pos: 5, heard: 50, savedAt: 0 }, 20), m2 = reg.espelho.melhor({ id: 'm-a', pos: 5, heard: 50, savedAt: Date.now() + 60000 }, 20), m3 = reg.espelho.melhor({ id: 'outro', pos: 5, heard: 50 }, 20), m4 = reg.espelho.melhor({ id: 'm-a', pos: 5, heard: 50, savedAt: 0 }, 4);
      ok('NUD6h espelho da leitura (dd-ingles-sessao, formato do app de hoje): vale o mais recente entre o banco e o espelho; livro diferente ou banco mais novo ignoram o espelho; a posição é limitada ao tamanho do livro', esp.id === 'm-a' && esp.pos === 9 && esp.heard === 70 && typeof esp.t === 'number' && m1.pos === 9 && m1.heard === 70 && m1.restaurado === true && m2.pos === 5 && m2.restaurado === false && m3.pos === 5 && m4.pos === 3, JSON.stringify([m1, m2, m3, m4]));

      // ===================== NUD7 · nuvem (Supabase simulado, como no teste do app de hoje) =====================
      await semeia();
      var srv = { row: null, calls: [], bump: false, otp500: false, refresh: 'ok', expiresIn: 0 };
      var mk = function (status, body) { return { ok: status >= 200 && status < 300, status: status, json: async function () { if (body === undefined) throw new Error('vazio'); return body; } }; };
      window.fetch = async function (url, opt) {
        var u = new URL(url), p = u.pathname, m = (opt && opt.method) || 'GET', b = opt && opt.body ? JSON.parse(opt.body) : null;
        srv.calls.push(m + ' ' + p);
        if (srv.offline) throw new Error('offline');
        if (p === '/auth/v1/otp') return srv.otp500 ? mk(500, { msg: 'Error sending magic link email' }) : mk(200, {});
        if (p === '/auth/v1/verify') return b.token === '123456' ? mk(200, { access_token: 'A1', refresh_token: 'R1', expires_in: srv.expiresIn || 3600, user: { id: 'u1', email: b.email } }) : mk(400, { msg: 'bad' });
        if (p === '/auth/v1/token') return srv.refresh === 'ok' ? mk(200, { access_token: 'A2', refresh_token: 'R2', expires_in: srv.expiresIn || 3600, user: { id: 'u1', email: 'leitor@example.com' } }) : mk(400, { msg: 'invalid' });
        if (p === '/rest/v1/progress') {
          if (m === 'GET') return mk(200, srv.row ? [{ data: srv.row.data, updated_at: srv.row.updated_at }] : []);
          if (m === 'POST') { if (srv.row) return mk(409, {}); srv.row = { data: b.data, updated_at: b.updated_at }; return mk(201); }
          if (m === 'PATCH') {
            var want = u.searchParams.get('updated_at').replace(/^eq\./, '');
            if (srv.bump) { srv.bump = false; srv.row.updated_at = '2099-01-01T00:00:00.000Z'; return mk(200, []); }
            if (!srv.row || srv.row.updated_at !== want) return mk(200, []);
            srv.row = { data: b.data, updated_at: b.updated_at }; return mk(200, [srv.row]);
          }
        }
        return mk(404, {});
      };
      window.DD_SYNC = { url: '', key: '' };
      var off = nv.estado(), rOff = await nv.enviarCodigo('leitor@example.com'), sOff = await nv.sincronizar('x');
      ok('NUD7a sem configuração a sincronização fica desligada: nada é chamado e o app segue normal', off.configurada === false && rOff === false && sOff === false && srv.calls.length === 0, srv.calls.length + ' chamadas');
      window.DD_SYNC = { url: 'https://mock.supabase.test', key: 'anon-public-key' };
      var n0 = srv.calls.length, rBad = await nv.enviarCodigo('sem-arroba');
      ok('NUD7b e-mail inválido é recusado sem chamar a rede', rBad === false && srv.calls.length === n0 && nv.estado().msg === 'fail');
      srv.otp500 = true; var rErr = await nv.enviarCodigo('leitor@example.com'), eErr = nv.estado();
      ok('NUD7c quando o envio do código falha, o motivo técnico fica disponível (500: Error sending magic link email)', rErr === false && /500: Error sending magic link email/.test(eErr.erro) && eErr.msg === 'fail', eErr.erro);
      srv.otp500 = false; var rOk = await nv.enviarCodigo('leitor@example.com'), eOk = nv.estado();
      ok('NUD7d enviar o código chama o login por código e guarda o e-mail aguardando o código', rOk === true && eOk.msg === 'sent' && eOk.pendente === 'leitor@example.com' && srv.calls.indexOf('POST /auth/v1/otp') >= 0);
      var rBadCode = await nv.entrar('000000'), eBad = nv.estado();
      var rGood = await nv.entrar('123456'); await until(function () { return srv.row !== null; });
      var up = srv.row.data, sessao = JSON.parse(localStorage.getItem('dd-sync-sess') || 'null');
      ok('NUD7e código errado é recusado; o certo entra, a sessão fica na chave do app de hoje (dd-sync-sess) e o progresso local sobe para a nuvem (estatísticas e cartões) SEM o texto dos livros', rBadCode === false && eBad.msg === 'bad' && rGood === true && nv.estado().logado && sessao && sessao.email === 'leitor@example.com' && up.log.d['2026-05-01'].sec === 300 && up.vocab.some(function (c) { return c.id === 'en:alfa'; }) && !/"paras"/.test(JSON.stringify(up)));
      var rem2 = JSON.parse(JSON.stringify(srv.row.data));
      rem2.log.d['2026-05-01'].sec = 999; rem2.log.d['2026-05-03'] = { sec: 60, heard: 6 };
      rem2.vocab.push({ id: 'en:fromphone', word: 'fromphone', lang: 'en', reps: 5, lapses: 0, due: 9, ivl: 9, ease: 2.5, added: 2 });
      rem2.docs['livro a|en'] = { title: 'Livro A', lang: 'en', pos: 3, heard: 777, savedAt: Date.now() + 100000, words: 1, sentences: 1 };
      srv.row = { data: rem2, updated_at: '2026-03-01T10:00:00.000Z' };
      await lg.put('vocab', { id: 'en:localonly', word: 'localonly', lang: 'en', reps: 1, lapses: 0, due: 1, ivl: 1, ease: 2.5, added: 3 });
      srv.bump = true; srv.calls.length = 0;
      var rSync = await nv.sincronizar('manual');
      var lg2 = JSON.parse(localStorage.getItem('dd-ingles-log')), vc = await lg.all('vocab'), mA = await lg.get('meta', 'm-a'), patches = srv.calls.filter(function (c) { return c === 'PATCH /rest/v1/progress'; }).length;
      ok('NUD7f outro aparelho gravou no meio (conflito): relê, mescla e tenta de novo; o local ganha dia com mais tempo, cartão novo e a posição mais recente do livro, e a nuvem fica com tudo, inclusive o que só existia aqui', rSync === true && patches >= 2 && lg2.d['2026-05-01'].sec === 999 && !!lg2.d['2026-05-03'] && vc.some(function (c) { return c.id === 'en:fromphone'; }) && mA.pos === 3 && mA.heard === 777 && srv.row.data.vocab.some(function (c) { return c.id === 'en:localonly'; }) && srv.row.data.log.d['2026-05-01'].sec === 999, 'patches=' + patches);
      var pre = srv.calls.length; await nv.sincronizar('de novo');
      ok('NUD7g sincronizar quando já está tudo igual não grava de novo (só lê)', srv.calls.slice(pre).every(function (c) { return /^GET /.test(c); }) && nv.estado().msg === '', srv.calls.slice(pre).join(','));
      nv.sair(); var depSair = nv.estado();
      ok('NUD7h sair da conta não apaga nada do aparelho (estatísticas, cartões e livros continuam) e remove a sessão', depSair.logado === false && depSair.estado === 'out' && localStorage.getItem('dd-sync-sess') === null && (await lg.all('vocab')).length >= 3 && !!localStorage.getItem('dd-ingles-log'));
      srv.expiresIn = 30;                                             // o servidor passa a emitir sessões de 30 s (menos que a margem de 60 s): toda chamada precisa renovar
      await nv.enviarCodigo('leitor@example.com'); await nv.entrar('123456'); await until(function () { return nv.estado().estado === 'in'; });
      srv.refresh = 'ruim'; var sessSincro = await nv.sincronizar('venceu'), eVenc = nv.estado(); srv.expiresIn = 0;
      ok('NUD7i sessão vencida e renovação recusada: avisa "sessão venceu", sai da conta e mantém os dados locais', sessSincro === false && eVenc.msg === 'session' && eVenc.logado === false && (await lg.all('vocab')).length >= 3, JSON.stringify(eVenc));
      srv.refresh = 'ok'; await nv.enviarCodigo('leitor@example.com'); await nv.entrar('123456'); await until(function () { return nv.estado().estado === 'in'; });
      srv.offline = true; await lg.put('vocab', { id: 'en:offline', word: 'offline', lang: 'en', reps: 1, lapses: 0, due: 1, ivl: 1, ease: 2.5, added: 4 });
      var rOffline = await nv.sincronizar('sem rede'), eOffline = nv.estado();
      ok('NUD7j sem rede: não perde nada, avisa "sem conexão" e continua conectado para tentar de novo', rOffline === false && eOffline.msg === 'offline' && eOffline.logado === true && (await lg.all('vocab')).some(function (c) { return c.id === 'en:offline'; }));
      srv.offline = false; await nv.sincronizar('voltou'); await until(function () { return srv.row.data.vocab.some(function (c) { return c.id === 'en:offline'; }); });
      ok('NUD7k quando a rede volta, o que foi feito sem conexão sobe sozinho e o aviso some', srv.row.data.vocab.some(function (c) { return c.id === 'en:offline'; }) && nv.estado().msg === '');
      nv.sair();

      // ===================== NUD8 · tela #/dados =====================
      var vista = document.getElementById('vista'); window.DD_SYNC = { url: '', key: '' };
      location.hash = '#/dados'; await until(function () { return document.getElementById('dad-backup') && document.getElementById('dad-conta'); });
      ok('NUD8a a tela Dados e conta tem o backup (baixar, carregar, colar) e a conta; sem configuração a conta diz que a sincronização não foi ativada e esconde o e-mail', !!document.getElementById('dad-down') && !!document.getElementById('dad-up') && !!document.getElementById('dad-paste') && /(ainda não foi ativada)/.test(document.getElementById('dad-conta-linha').textContent) && document.getElementById('dad-email').hidden, document.getElementById('dad-conta-linha').textContent.slice(0, 40));
      URL.createObjectURL = undefined;                                               // aparelho que não baixa arquivos: cai no texto para copiar
      document.getElementById('dad-down').click(); await until(function () { return !document.getElementById('dad-text').hidden && /(não baixa)/.test(document.getElementById('dad-bk-status').textContent); });
      var ta = document.getElementById('dad-text'), tj = null; try { tj = JSON.parse(ta.value); } catch (e) { /* ignora */ }
      ok('NUD8b sem suporte a download, o progresso aparece como texto para copiar (e é um backup válido)', !ta.hidden && tj && tj.app === 'ingles-progresso');
      var novoCartao = JSON.parse(JSON.stringify(tj)); novoCartao.data.vocab = [{ id: 'en:colado', word: 'colado', lang: 'en', reps: 1, due: 1 }];
      ta.value = JSON.stringify(novoCartao); document.getElementById('dad-go').click(); await until(function () { return /(Progresso carregado)/.test(document.getElementById('dad-bk-status').textContent); });
      ok('NUD8c colar o texto de um backup e importar funciona e mostra o resumo', (await lg.all('vocab')).some(function (c) { return c.id === 'en:colado'; }) && /\+1 palavras salvas novas/.test(document.getElementById('dad-bk-status').textContent), document.getElementById('dad-bk-status').textContent.slice(0, 70));
      ta.value = '{"x":1}'; document.getElementById('dad-go').click(); await until(function () { return /(não é um backup)/.test(document.getElementById('dad-bk-status').textContent); });
      ok('NUD8d texto colado que não é backup mostra aviso claro e o backup funciona sem conta e sem sincronização', /(não é um backup)/.test(document.getElementById('dad-bk-status').textContent) && nv.estado().configurada === false);
      window.DD_SYNC = { url: 'https://mock.supabase.test', key: 'anon-public-key' }; location.hash = '#/sistema'; await wait(200); location.hash = '#/dados'; await until(function () { return document.getElementById('dad-email') && !document.getElementById('dad-email').hidden; });
      document.getElementById('dad-email').value = 'leitor@example.com'; document.getElementById('dad-send').click(); await until(function () { return !document.getElementById('dad-code').hidden; });
      document.getElementById('dad-code').value = '123456'; document.getElementById('dad-enter').click(); await until(function () { return /(Conectado)/.test(document.getElementById('dad-conta-linha').textContent); });
      ok('NUD8e pela tela: com a configuração presente aparece o e-mail; enviar o código abre o campo do código; o código certo entra e mostra "Conectado como …"', /Conectado como leitor@example.com/.test(document.getElementById('dad-conta-linha').textContent) && !document.getElementById('dad-now').hidden, document.getElementById('dad-conta-linha').textContent.slice(0, 50));
      document.getElementById('dad-out').click(); await until(function () { return !document.getElementById('dad-email').hidden; });
      ok('NUD8f pela tela: Sair volta ao campo de e-mail', !document.getElementById('dad-email').hidden && nv.estado().logado === false);
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
