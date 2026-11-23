/*
 * tradutor.js — serviço TRADUTOR do Leitor (R2.5b; docs/10, seção 10; matriz `c4`). Sem DOM.
 * Port fiel do tradutor do `ingles.js` de hoje (linhas 333–500): motor local do Chrome (`Translator`), tradução imediata de UMA frase
 * (a narração não espera o parágrafo), tradução do parágrafo com as frases em paralelo, bomba que traduz à frente da leitura
 * (40 parágrafos à frente da âncora, ou o livro todo no modo "traduzir tudo"), espera de parágrafo (a narração aguarda) e falhas.
 *
 *   criar({ fabrica, Translator, precisa, gravar, aoParagrafo, aoEstado, aoMotor, janela }) -> servico
 *     fabrica(a, b)       cria o tradutor do par (padrão: window.DD_TRANSLATOR_FACTORY; sem ela usa o `Translator` do Chrome)
 *     precisa()           true quando algo na tela ou no áudio depende da tradução (ler/ouvir no outro idioma, lado a lado, teleprompter…)
 *     gravar(id, i, out)  guarda a tradução do parágrafo i no armazém
 *     aoParagrafo(i)      o parágrafo i ficou traduzido (a tela repinta)  ·  aoEstado(ocupado)  ·  aoMotor()  (estado do motor mudou)
 *   servico.abrir(doc)    doc = { id, lang, paras:[{s:[frases]}], tr:{ [i]: [frases traduzidas] }, pos }
 *   servico.frase(p, s)   Promise<string | null>   tradução imediata (cache por frase; null se não há tradutor ou falhou)
 *   servico.garantir(i)   Promise<void>            espera o parágrafo i traduzido (resolve mesmo sem tradutor)
 *   servico.bombear()     traduz à frente; servico.ativarPar(a, b) baixa o modelo (precisa de gesto do aluno)
 *   servico.ancora(i) · servico.tudo(on) · servico.estado()  { avail, erro, ocupado, modoTudo, traduzidos }
 */
App.define('tradutor', [], function () {
    'use strict';
    const outro = (l) => (l === 'en' ? 'pt' : 'en');
    const chavePar = (a, b) => a + '>' + b;
    const TEM_LETRA = /\p{L}/u;

    function criar(o) {
        o = o || {};
        const janela = o.janela || 40, precisa = o.precisa || (() => true), gravar = o.gravar || (() => {});
        const aoParagrafo = o.aoParagrafo || (() => {}), aoEstado = o.aoEstado || (() => {}), aoMotor = o.aoMotor || (() => {});
        const TR = { insts: {}, avail: {}, progress: {}, pending: {}, err: {} };
        const esperas = {}, frasesTr = {};
        let doc = null, ancora = 0, modoTudo = false, bombeando = false, erro = '';

        const fabrica = () => o.fabrica || (typeof window !== 'undefined' && window.DD_TRANSLATOR_FACTORY) || null;
        const T = () => (o.Translator !== undefined ? o.Translator : (typeof self !== 'undefined' && 'Translator' in self ? self.Translator : null));
        async function disponibilidade(a, b) {
            if (fabrica()) return 'available';
            if (!T()) return 'unsupported';
            try { return await T().availability({ sourceLanguage: a, targetLanguage: b }); } catch (e) { return 'unsupported'; }
        }
        async function criarPar(a, b) {
            if (fabrica()) return fabrica()(a, b);
            return T().create({ sourceLanguage: a, targetLanguage: b, monitor(m) { m.addEventListener('downloadprogress', (e) => { TR.progress[chavePar(a, b)] = e.loaded; aoMotor(); aoEstado(); }); } });
        }
        const msg = (e) => (e && e.name ? e.name + ': ' : '') + (e && e.message ? e.message : e);
        // Instância pronta do par (cria sozinha só se o modelo já está baixado; senão espera o clique do aluno).
        async function instancia(a, b) {
            const k = chavePar(a, b);
            if (TR.insts[k]) return TR.insts[k];
            if (TR.pending[k]) return TR.pending[k];
            const av = await disponibilidade(a, b);
            TR.avail[k] = av;
            if (av !== 'available') { aoMotor(); return null; }
            TR.pending[k] = criarPar(a, b).then((i) => { TR.insts[k] = i; aoMotor(); return i; }).catch((e) => { TR.avail[k] = 'downloadable'; TR.err[k] = msg(e); aoMotor(); return null; }).finally(() => { delete TR.pending[k]; });
            return TR.pending[k];
        }
        async function ativarPar(a, b) {   // precisa de gesto do aluno (baixa o modelo)
            const k = chavePar(a, b);
            TR.avail[k] = 'downloading'; aoMotor(); aoEstado();
            try { TR.insts[k] = await criarPar(a, b); TR.avail[k] = 'available'; TR.err[k] = ''; }
            catch (e) { TR.avail[k] = 'downloadable'; TR.err[k] = msg(e); }
            erro = ''; aoMotor(); aoEstado(); bombear();
        }

        const contar = () => (doc ? Object.keys(doc.tr).length : 0);
        function proximoPendente() {
            const N = doc.paras.length;
            const fim = modoTudo ? N : Math.min(N, ancora + janela);
            for (let i = ancora; i < fim; i++) if (!doc.tr[i]) return i;
            if (modoTudo) for (let i = 0; i < ancora; i++) if (!doc.tr[i]) return i;
            return -1;
        }

        // Tradução imediata de uma frase: a narração e a legenda não esperam o parágrafo inteiro ficar pronto.
        function frase(p, s) {
            if (!doc) return Promise.resolve(null);
            if (doc.tr[p] && doc.tr[p][s] != null) return Promise.resolve(doc.tr[p][s]);
            const src = doc.paras[p] && doc.paras[p].s[s];
            if (src == null) return Promise.resolve(null);
            if (!TEM_LETRA.test(src)) return Promise.resolve(src);
            const chave = doc.id + ':' + p + ':' + s, de = doc.lang;
            if (!frasesTr[chave]) {
                frasesTr[chave] = (async () => {
                    const inst = await instancia(de, outro(de));
                    if (!inst) return null;
                    return String(await inst.translate(src)).trim() || null;
                })().catch(() => null).then((r) => { if (r === null) delete frasesTr[chave]; return r; });
            }
            return frasesTr[chave];
        }

        async function traduzirParagrafo(i, inst) {
            const d0 = doc;
            const saida = await Promise.all(d0.paras[i].s.map(async (s, k) => {       // frases do parágrafo em paralelo
                if (!TEM_LETRA.test(s)) return s;
                const c = frasesTr[d0.id + ':' + i + ':' + k];
                if (c) { const r0 = await c; if (r0) return r0; }
                const r = String(await inst.translate(s)).trim();
                if (!r) throw new Error('tradução vazia');
                return r;
            }));
            if (doc !== d0) return;
            doc.tr[i] = saida;
            gravar(doc.id, i, saida);
            aoParagrafo(i);
            if (esperas[i]) { esperas[i].forEach((r) => r()); delete esperas[i]; }
        }
        function soltarEsperas() { Object.keys(esperas).forEach((k) => { esperas[k].forEach((r) => r()); delete esperas[k]; }); }

        async function bombear() {
            if (bombeando || !doc || !precisa()) { aoEstado(); return; }
            bombeando = true;
            const meu = doc;
            try {
                const inst = await instancia(doc.lang, outro(doc.lang));
                if (!inst) { soltarEsperas(); return; }
                while (doc === meu && precisa()) {
                    const i = proximoPendente();
                    if (i < 0) break;
                    aoEstado(true);
                    try { await traduzirParagrafo(i, inst); erro = ''; }
                    catch (e) { erro = msg(e); soltarEsperas(); break; }
                }
            } finally { bombeando = false; aoEstado(); }
        }
        // Garante a tradução de um parágrafo (usada pela narração). Resolve mesmo sem tradutor.
        function garantir(i) {
            if (!doc || doc.tr[i]) return Promise.resolve();
            ancora = i;
            return new Promise((res) => { (esperas[i] = esperas[i] || []).push(res); bombear(); });
        }
        function abrir(d) { doc = d; ancora = (d && d.pos) || 0; modoTudo = false; }
        return {
            abrir, frase, garantir, bombear, ativarPar,
            ancora(i) { ancora = i; }, tudo(on) { modoTudo = !!on; if (modoTudo) bombear(); }, modoTudo: () => modoTudo,
            estado() { const k = doc ? chavePar(doc.lang, outro(doc.lang)) : ''; return { avail: TR.insts[k] ? 'available' : TR.avail[k], erro, ocupado: bombeando, modoTudo, traduzidos: contar(), progresso: TR.progress[k] || 0, erroMotor: TR.err[k] || '' }; }
        };
    }
    return { criar, outro };
});
