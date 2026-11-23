/*
 * tela-leitor.js — a TELA do Leitor, rota `#/ler/<livro>` (R2.5g; docs/10, seção 12; decisão visual aprovada em 2026-11-23).
 * Junta os módulos do Leitor e do Narrador numa tela de verdade, sobre o MESMO banco do app de hoje (`dd-ingles`: meta, docs, tr):
 * abre o livro, pinta o texto, narra com marcação em quatro camadas, traduz por frase, explora palavra a palavra, grava a posição sem
 * errar quando o layout muda e registra o estudo. Tudo é montado com `textContent` (nada que venha de dados vira código).
 *
 * Controles: LER e OUVIR (pt/en), velocidade 0,1× a 3×, ▶/⏸, modo (Leitura ou Lado a lado), setas (palavra a palavra; Shift = frase),
 * toque numa frase para ouvir dali. As atividades do trecho (Nota, Comentar, Falar, Escrever) aparecem na barra, ainda desligadas: são
 * as próximas telas (folha que sobe, aprovadas na proposta visual).
 */
App.define('tela-leitor', ['eventos', 'armazem', 'config', 'rotas', 'registro', 'vozes', 'tradutor', 'fonte', 'pagina', 'marcacao', 'alinhar', 'explorar', 'posicao', 'narrador', 'voz-navegador', 'voz-neural'], function (d) {
    'use strict';
    const ev = d.eventos, armazem = d.armazem, config = d.config, rotas = d.rotas, registro = d.registro;
    const h = (tag, cls, txt) => { const e = document.createElement(tag); if (cls) e.className = cls; if (txt != null) e.textContent = txt; return e; };
    const botao = (rotulo, fn, cls) => { const b = h('button', 'lei-btn' + (cls ? ' ' + cls : ''), rotulo); b.type = 'button'; if (fn) b.addEventListener('click', fn); return b; };
    const MODO = 'dd-ingles-modo';
    let sessao = null;

    function fechar() { if (sessao) { const s = sessao; sessao = null; s.fechar(); } }
    ev.on('rota-mudou', (r) => { if (!r || String(r.rota || '').indexOf('/ler/') !== 0) fechar(); });

    async function carregar(id) {
        const db = await armazem.legado();
        const [meta, corpo, tr] = await Promise.all([db.get('meta', id), db.get('docs', id), db.porPrefixo('tr', id + ':')]);
        if (!meta || !corpo) return null;
        const trs = {};
        Object.keys(tr).forEach((k) => {
            const i = Number(k.slice(id.length + 1)), src = corpo.paras[i] && corpo.paras[i].s;
            if (!src || src.every((s, j) => tr[k][j] === s && /\p{L}{3}/u.test(s))) return;      // versões antigas gravavam o original como "tradução"
            trs[i] = tr[k];
        });
        const sess = registro.espelho.melhor(meta, corpo.paras.length);
        return { db, doc: { id, title: meta.title, lang: corpo.lang, pages: meta.pages, paras: corpo.paras, tr: trs, words: meta.words, sentences: meta.sentences, added: meta.added, pos: sess.pos, heard: sess.heard, lastOpened: Date.now(), x: meta.x || {} } };
    }

    async function abrir(el, id) {
        el.textContent = '';
        const aviso = h('p', 'novo-fase', 'Abrindo o livro…'); el.append(aviso);
        let c;
        try { c = await carregar(id); } catch (e) { aviso.className = 'novo-erro'; aviso.textContent = 'Não foi possível abrir o livro: ' + String((e && e.message) || e); return; }
        if (!c) { aviso.className = 'novo-erro'; aviso.textContent = 'Livro não encontrado neste aparelho: ' + id + '. Traga-o pela Estante ou carregue o backup.'; return; }
        fechar();
        const db = c.db, doc = c.doc, ouvintes = [];
        let modo = armazem.ls.getRaw(MODO, 'single') === 'side' ? 'side' : 'single', salvarT = null;
        const lerIdioma = () => config.get('readLang'), audio = () => config.get('audioLang');

        /* ---- tela ---- */
        el.textContent = '';
        const raiz = h('section', 'lei-raiz'); raiz.id = 'lei-raiz';
        const topo = h('div', 'lei-topo'); const volta = h('a', 'lei-volta', '‹ Estante'); volta.href = '#/estante'; topo.append(volta, h('strong', 'lei-titulo', doc.title));
        const faixaIdioma = h('div', 'lei-faixa');
        const grupo = (rotulo, chave) => {
            const g = h('span', 'lei-grupo'); g.append(h('span', 'lei-rotulo', rotulo));
            ['pt', 'en'].forEach((l) => { const b = botao(l.toUpperCase(), () => { config.set(chave, l); }, 'lei-chip'); b.dataset.l = l; g.append(b); });
            return g;
        };
        const gLer = grupo('LER', 'readLang'), gOuvir = grupo('OUVIR', 'audioLang');
        const velo = h('span', 'lei-velo', ''); const menos = botao('−', () => mudarVelocidade(-0.1), 'lei-chip'), mais = botao('+', () => mudarVelocidade(0.1), 'lei-chip');
        menos.setAttribute('aria-label', 'Mais devagar'); mais.setAttribute('aria-label', 'Mais depressa');
        const play = botao('▶ Ouvir', () => alternar(), 'lei-play'); play.id = 'lei-play';
        faixaIdioma.append(gLer, gOuvir, menos, velo, mais, play);
        const faixaModo = h('div', 'lei-faixa');
        const bModo = { single: botao('Leitura', () => trocarModo('single'), 'lei-chip'), side: botao('Lado a lado', () => trocarModo('side'), 'lei-chip') };
        const estado = h('span', 'lei-estado', ''); estado.id = 'lei-estado';
        faixaModo.append(bModo.single, bModo.side, estado);
        const erro = h('p', 'novo-erro'); erro.hidden = true; erro.id = 'lei-erro';
        const wrap = h('div', 'lb-wrap'); wrap.id = 'lb-wrap';
        const band = h('div', 'lb-band'); band.id = 'lb-band'; band.setAttribute('aria-hidden', 'true');
        const texto = h('article'); texto.id = 'lb-text'; wrap.append(band, texto);
        const acoes = h('div', 'lei-acoes');
        ['Nota', 'Comentar', 'Falar', 'Escrever'].forEach((r) => { const b = botao(r, null, 'lei-acao'); b.disabled = true; b.title = 'Em construção: próxima tela (folha que sobe)'; acoes.append(b); });
        raiz.append(topo, faixaIdioma, faixaModo, erro, wrap, acoes); el.append(raiz);

        /* ---- módulos ---- */
        const synth = window.speechSynthesis;
        const pagina = d.pagina.criar({ host: texto, doc: () => doc, lerIdioma, lado: () => modo === 'side', aoPintar: (i) => marc.reaplicar(i) });
        const tradutor = d.tradutor.criar({
            precisa: () => lerIdioma() !== doc.lang || audio() !== doc.lang || modo === 'side' || tradutor.modoTudo(),
            gravar: (idLivro, i, out) => { db.put('tr', out, idLivro + ':' + i).catch(() => {}); agendar(); },
            aoParagrafo: (i) => pagina.pintar(i), aoEstado: () => atualizaEstado()
        });
        tradutor.abrir(doc);
        const alinhar = d.alinhar.criar({ traduzirPalavra: (raw, lang) => tradutor.traduzir(raw, lang) });
        const marc = d.marcacao.criar({ pagina, faixa: band, envoltorio: wrap, modo: () => modo, mapear: (a, b2, c2, e2) => alinhar.mapPos(a, b2, c2, e2) });
        const posicao = d.posicao.criar({ doc: () => doc, aberto: () => !!sessao, pagina, aoPosicao: (i) => { if (!narrador.estado().tocando) { tradutor.ancora(i); tradutor.bombear(); } agendar(); } });
        const navegador = synth ? d['voz-navegador'].criar({ synth, Utterance: window.SpeechSynthesisUtterance, velocidade: () => config.get('rate'), voz: (idioma) => d.vozes.escolher(idioma, (config.get('voices') || {})[idioma], synth.getVoices()) }) : null;
        const neural = d['voz-neural'].criarNeural({ velocidade: () => config.get('rate'), aoFalhar: () => { estado.textContent = 'Voz neural indisponível agora; usando a voz do navegador.'; } });
        const voz = navegador ? d['voz-neural'].compor({ neural, navegador }) : { falar: async () => 'error', cancelar() {}, reiniciar() {}, preparar() {} };
        const narrador = d.narrador.criar({ voz });
        const fonte = d.fonte.doDocumento({ doc, tradutor, idiomaAudio: audio, aoOcupado: () => atualizaEstado(true), primeiraVisivel: () => pagina.primeiraVisivel() });
        narrador.abrir(fonte);
        const explorar = d.explorar.criar({ host: texto, envoltorio: wrap, doc: () => doc, lerIdioma, pagina, marcacao: marc, narrador, tradutor, alinhar, eventos: ev });

        /* ---- comportamento ---- */
        function agendar() { espelhar(); clearTimeout(salvarT); salvarT = setTimeout(salvar, 1500); }
        function espelhar() { registro.espelho.gravar(doc); }
        function salvar() {
            clearTimeout(salvarT); espelhar();
            db.put('meta', { id: doc.id, title: doc.title, lang: doc.lang, pages: doc.pages, sentences: doc.sentences, words: doc.words, added: doc.added, trDone: Object.keys(doc.tr).length, trTotal: doc.paras.length, pos: doc.pos, heard: doc.heard || 0, lastOpened: doc.lastOpened || 0, savedAt: Date.now(), x: doc.x || {} }).catch(() => {});
        }
        function atualizaEstado(ocupado) {
            const e = tradutor.estado(), pct = Math.round(e.traduzidos / doc.paras.length * 100), precisa = lerIdioma() !== doc.lang || audio() !== doc.lang || modo === 'side';
            let t = '';
            if (!precisa && !e.traduzidos) t = '';
            else if (e.erro) t = 'Tradução com erro: ' + e.erro;
            else if (e.avail === 'unsupported' || e.avail === 'unavailable') t = 'Este navegador não traduz neste aparelho.';
            else if (e.avail === 'downloadable' || e.avail === 'downloading') t = 'A tradução precisa baixar o modelo do navegador.';
            else if (ocupado || e.ocupado) t = 'Traduzindo ' + pct + '%';
            else t = pct >= 100 ? 'Tradução completa' : pct + '% traduzido';
            estado.textContent = t;
        }
        function aplicarIdiomas() {
            [[gLer, lerIdioma()], [gOuvir, audio()]].forEach(([g, v]) => g.querySelectorAll('button').forEach((b) => b.setAttribute('aria-pressed', String(b.dataset.l === v))));
            velo.textContent = String(config.get('rate')).replace('.', ',') + '×';
            Object.keys(bModo).forEach((k) => bModo[k].setAttribute('aria-pressed', String(k === modo)));
        }
        function repintar() { pagina.pintarTudo(doc.paras.length > pagina.GRANDE ? pagina.primeiraVisivel() : 0); }
        function mudou() { aplicarIdiomas(); repintar(); if (narrador.estado().tocando) narrador.reiniciar(); tradutor.ancora(doc.pos || 0); tradutor.bombear(); explorar.idioma(); atualizaEstado(); }
        function alternar() { if (narrador.estado().tocando) narrador.parar(); else narrador.tocar(); }
        function mudarVelocidade(delta) { config.set('rate', Math.round((config.get('rate') + delta) * 10) / 10); }
        function trocarModo(m) {
            if (m === modo) return; modo = m; armazem.ls.setRaw(MODO, m);
            const manter = doc.pos || 0; repintar(); tradutor.bombear(); aplicarIdiomas(); posicao.assentar(manter);
        }
        ouvintes.push(ev.on('config-mudou', (e) => { if (e && (e.chave === 'readLang' || e.chave === 'audioLang')) mudou(); else if (e && e.chave === 'rate') { aplicarIdiomas(); if (narrador.estado().tocando) narrador.reiniciar(); } }));
        ouvintes.push(ev.on('narracao-estado', (e) => { play.textContent = e.tocando ? '⏸ Pausar' : '▶ Ouvir'; play.setAttribute('aria-pressed', String(!!e.tocando)); }));
        ouvintes.push(ev.on('narracao-frase', (e) => { if (e.texto != null) { doc.pos = e.p; agendar(); } if (neural.ativa(audio())) { /* a próxima frase já sintetiza à frente */ } }));
        ouvintes.push(ev.on('frase-ouvida', (e) => { doc.heard = (doc.heard || 0) + ((e && e.palavras) || 0); agendar(); }));
        marc.ligar(ev).forEach((f) => ouvintes.push(f)); explorar.ligar(ev).forEach((f) => ouvintes.push(f));
        texto.addEventListener('click', (e) => {                                  // toque numa frase: ouvir dali
            const sp = e.target.closest && e.target.closest('.lb-s'); if (!sp) return;
            const sel = window.getSelection && window.getSelection(); if (sel && !sel.isCollapsed) return;
            narrador.tocar(Number(sp.parentNode.dataset.i), Number(sp.dataset.k));
        });
        const teclas = (e) => {
            if (e.altKey || e.ctrlKey || e.metaKey || /^(input|textarea|select)$/i.test((e.target && e.target.tagName) || '') || (e.target && e.target.isContentEditable)) return;
            if (e.key === 'ArrowRight' || e.key === 'ArrowLeft') { e.preventDefault(); const dir = e.key === 'ArrowRight' ? 1 : -1; if (e.shiftKey) narrador.passo(dir); else explorar.passo(dir); }
        };
        document.addEventListener('keydown', teclas);
        const desligarPos = posicao.ligar();

        sessao = {
            id,
            fechar() {
                salvar(); desligarPos(); document.removeEventListener('keydown', teclas); ouvintes.forEach((f) => { try { f(); } catch (e) { /* já solto */ } });
                narrador.fechar(); registro.pararRelogio(); ev.emit('livro-fechado', { id: doc.id, titulo: doc.title });
            },
            api: { narrador, marcacao: marc, explorar, tradutor, pagina, posicao, doc, voz }
        };
        registro.iniciarRelogio(() => ({ aberto: !!sessao, ouvindo: narrador.estado().tocando }));
        ev.emit('livro-aberto', { id: doc.id, titulo: doc.title });
        aplicarIdiomas(); pagina.construir(doc.pos || 0);
        const el0 = pagina.paraEl(Math.min(doc.pos || 0, doc.paras.length - 1)); if (el0) el0.scrollIntoView({ block: 'start' });
        posicao.aceitar(); tradutor.ancora(doc.pos || 0); tradutor.bombear(); atualizaEstado();
    }

    d.rotas.registrar('/ler/:livro', { titulo: 'Leitura', montar(el, p) { abrir(el, p.livro); } });
    return { fechar, atual: () => sessao };
});
