/*
 * texto.js — do arquivo ao DOCUMENTO: limpeza do texto importado, versos, idioma e frases (R2.5a; docs/10, seção 5; matriz `c2`).
 * Puro: sem DOM, sem arquivo, sem relógio. Port fiel de `buildLines`, `buildParagraphs`, `looksVerse`, `extractTxt`, `detectLang`,
 * `splitLong` e `splitSentences` do `ingles.js` de hoje (linhas 144–331) e do miolo de `importFile` (linhas 1116–1140).
 * O teste compara cada função com a do app de hoje (rodando numa moldura) em centenas de entradas aleatórias.
 *
 *   linhas(itensDoPdf)                  -> linhas { text, x, y, h, endX } na ordem do fluxo do PDF
 *   paragrafos(paginas)                 -> [{ t: 'p'|'h'|'v', text, pg, lines? }]   (remove cabeçalho/rodapé repetido e número de página,
 *                                          junta hifenização, junta frase partida entre páginas, reconhece título pelo tamanho)
 *   pareceVerso(linhas)                 -> true se o bloco é poema/letra (cada linha vira uma unidade narrada)
 *   deTxt(textoBruto)                   -> { title:'', pageCount:0, paras }   (TXT: parágrafos por linha em branco, versos, hifenização)
 *   detectarIdioma(paras)               -> 'pt' | 'en'
 *   dividirFrases(texto, idioma)        -> frases (Intl.Segmenter; parte as muito longas em vírgula/ponto e vírgula, até 320 caracteres)
 *   documento(extracao, nomeDoArquivo)  -> { lang, title, pages, paras:[{t,pg,s}], words, sentences }  (sem id nem data: quem grava decide)
 */
App.define('texto', [], function () {
    'use strict';
    const TERMINAL = /[.!?…:;”"’')\]»]$/;
    const LOWER_START = /^[("“'‘]?\p{Ll}/u;
    const PAGE_NUM = /^(page|p\.|pág\.?|página)?\s*\d+(\s*(of|de|\/)\s*\d+)?$/i;
    const mediana = (a) => { if (!a.length) return 0; const s = a.slice().sort((x, y) => x - y); return s[s.length >> 1]; };

    // Itens de texto do pdf.js -> linhas (na ordem do fluxo do PDF, o que preserva a ordem das colunas).
    function linhas(itens) {
        const out = [];
        let cur = null;
        for (const it of itens) {
            if (typeof it.str !== 'string') continue;
            const x = it.transform[4], y = it.transform[5];
            const h = Math.abs(it.transform[3]) || it.height || 10, w = it.width || 0;
            if (cur && Math.abs(y - cur.y) <= 0.5 * Math.max(h, cur.h) && x >= cur.endX - 2 * h) {
                const gap = x - cur.endX;
                const espaco = gap > 0.18 * h && !/\s$/.test(cur.text) && !/^\s/.test(it.str);
                cur.text += (espaco ? ' ' : '') + it.str;
                cur.endX = x + w; cur.h = Math.max(cur.h, h);
            } else {
                if (cur) out.push(cur);
                cur = { text: it.str, x, y, h, endX: x + w };
            }
        }
        if (cur) out.push(cur);
        out.forEach((l) => { l.text = l.text.replace(/\s+/g, ' ').trim(); });
        return out.filter((l) => l.text);
    }

    // Páginas (com linhas) -> parágrafos { t: 'p'|'h'|'v', text } ('v' = estrofe de versos, com lines[]). ATENÇÃO: altera `paginas` (como hoje).
    function paragrafos(paginas) {
        const n = paginas.length;
        // cabeçalhos e rodapés: texto que se repete nas margens de várias páginas, e números de página
        const vistos = new Map();
        paginas.forEach((pg, pi) => {
            pg.lines.forEach((l) => {
                l.margin = l.y > pg.h * 0.92 || l.y < pg.h * 0.08;
                if (l.margin) {
                    l.key = l.text.toLowerCase().replace(/\d+/g, '#');
                    if (!vistos.has(l.key)) vistos.set(l.key, new Set());
                    vistos.get(l.key).add(pi);
                }
            });
        });
        const minPaginas = Math.max(3, Math.ceil(n * 0.3));
        paginas.forEach((pg) => {
            pg.lines = pg.lines.filter((l) => !(l.margin && (PAGE_NUM.test(l.text) || (n >= 3 && vistos.get(l.key).size >= minPaginas))));
        });

        const todas = [].concat(...paginas.map((p) => p.lines));
        if (!todas.length) return [];
        const alturaCorpo = mediana(todas.map((l) => l.h));
        const espacos = [];
        paginas.forEach((pg) => { for (let i = 1; i < pg.lines.length; i++) { const g = pg.lines[i - 1].y - pg.lines[i].y; if (g > 0 && g < alturaCorpo * 4) espacos.push(g); } });
        const espacoMedio = mediana(espacos) || alturaCorpo * 1.25;

        const paras = [];
        let cur = null;
        const fechar = () => { if (cur && /\p{L}/u.test(cur.text)) paras.push({ t: cur.t, text: cur.text.trim(), pg: cur.pg }); cur = null; };

        paginas.forEach((pg, pgi) => {
            let anterior = null;
            pg.lines.forEach((linha) => {
                const ehTitulo = linha.h > alturaCorpo * 1.25 && linha.text.length < 140;
                const gap = anterior ? anterior.y - linha.y : null;
                let junta = false;
                if (cur) {
                    if (cur.t === 'h') {
                        junta = ehTitulo && gap !== null && gap > 0 && gap < espacoMedio * 1.6 * (linha.h / alturaCorpo) && Math.abs(linha.h - cur.h) < 1.5;
                    } else if (!ehTitulo) {
                        if (gap === null) junta = !TERMINAL.test(cur.text);                       // virada de página
                        else if (gap < 0 || gap > espacoMedio * 1.55) junta = !TERMINAL.test(cur.text) && LOWER_START.test(linha.text);   // coluna nova ou espaço grande
                        else if (linha.x > anterior.x + 1.2 * linha.h && TERMINAL.test(cur.text)) junta = false;   // recuo de parágrafo
                        else junta = true;
                    }
                }
                if (junta) {
                    if (/\p{L}-$/u.test(cur.text) && LOWER_START.test(linha.text)) cur.text = cur.text.slice(0, -1) + linha.text;
                    else cur.text += ' ' + linha.text;
                } else {
                    fechar();
                    cur = { t: ehTitulo ? 'h' : 'p', text: linha.text, h: linha.h, pg: pgi + 1 };
                }
                anterior = linha;
            });
        });
        fechar();
        return paras;
    }

    // Versos: bloco de linhas curtas, quase todas começando em maiúscula e poucas terminando em ponto final (poema, letra, soneto).
    // Texto corrido quebrado em colunas (linhas ~70 caracteres, que começam no meio da frase) e diálogos curtos continuam sendo prosa.
    function pareceVerso(ls) {
        const L = ls.map((x) => String(x).trim()).filter(Boolean);
        if (L.length < 2 || L.length > 40) return false;
        const len = L.map((x) => x.length), media = len.reduce((a, b) => a + b, 0) / L.length, max = Math.max.apply(null, len);
        const cap = L.filter((x) => /^[\p{Lu}"“'‘(\[¡¿—-]/u.test(x)).length / L.length;
        const final = L.filter((x) => /[.!?]["”')\]]*$/.test(x)).length / L.length;
        return media <= 62 && max <= 90 && cap >= 0.8 && final < 0.75;
    }
    function deTxt(bruto) {
        const raw = String(bruto).replace(/\r\n?/g, '\n');
        const paras = raw.split(/\n\s*\n/).map((b) => {
            const L = b.split('\n').map((x) => x.trim()).filter(Boolean);
            if (pareceVerso(L)) return { t: 'v', lines: L, text: L.join(' ') };
            let t = '';
            L.forEach((ln) => {
                if (/\p{L}-$/u.test(t) && LOWER_START.test(ln)) t = t.slice(0, -1) + ln; else t += (t ? ' ' : '') + ln;
            });
            return { t: 'p', text: t };
        }).filter((p) => /\p{L}/u.test(p.text));
        return { title: '', pageCount: 0, paras };
    }

    const PALAVRAS_COMUNS = {
        en: 'the and of to in is that it for with as was on are this be by have not but at from or an they which you we his her their will would there been has had were can all one our more'.split(' '),
        pt: 'de que e o a do da em um para com não uma os no se na por mais as dos como mas foi ao ele das tem à seu sua ou ser quando muito há nos já está eu também só pelo pela até isso ela entre era depois sem mesmo aos ter seus quem nas me esse eles estão você'.split(' ')
    };
    function detectarIdioma(paras) {
        const amostra = paras.slice(0, 400).map((p) => p.text).join(' ').toLowerCase().match(/\p{L}+/gu) || [];
        const en = new Set(PALAVRAS_COMUNS.en), pt = new Set(PALAVRAS_COMUNS.pt);
        let a = 0, b = 0;
        amostra.forEach((w) => { if (en.has(w)) a++; if (pt.has(w)) b++; });
        return b > a ? 'pt' : 'en';
    }

    function dividirLongo(s, max) {
        const out = [];
        while (s.length > max) {
            let corte = -1;
            const re = /[;:,—–] /g;
            let m;
            while ((m = re.exec(s)) && m.index < max) if (m.index >= 120) corte = m.index + 1;
            if (corte < 0) corte = s.lastIndexOf(' ', max);
            if (corte < 40) corte = max;
            out.push(s.slice(0, corte).trim());
            s = s.slice(corte).trim();
        }
        if (s) out.push(s);
        return out;
    }
    function dividirFrases(texto, idioma) {
        let partes;
        if (window.Intl && Intl.Segmenter) partes = Array.from(new Intl.Segmenter(idioma, { granularity: 'sentence' }).segment(texto), (x) => x.segment);
        else partes = texto.match(/[^.!?…]+[.!?…]+["'”’)\]]*\s*|[^.!?…]+$/g) || [texto];
        const out = [];
        partes.forEach((p) => {
            p = p.replace(/\s+/g, ' ').trim();
            if (!p) return;
            if (out.length && !/\p{L}|\p{N}/u.test(p)) { out[out.length - 1] += ' ' + p; return; }   // pontuação solta
            dividirLongo(p, 320).forEach((q) => out.push(q));
        });
        return out;
    }

    // Extração (título, páginas, parágrafos brutos) -> documento com as frases. Mesmo miolo do `importFile` de hoje; sem id/data/banco.
    function documento(ex, nomeDoArquivo) {
        const lang = detectarIdioma(ex.paras);
        const paras = ex.paras.map((p) => ({ t: p.t, pg: p.pg, s: p.t === 'h' ? [p.text] : p.t === 'v' ? p.lines.slice() : dividirFrases(p.text, lang) })).filter((p) => p.s.length);
        const words = paras.reduce((a, p) => a + p.s.join(' ').split(/\s+/).length, 0);
        const nome = String(nomeDoArquivo || 'documento');
        return {
            lang, pages: ex.pageCount, paras, words, sentences: paras.reduce((a, p) => a + p.s.length, 0),
            title: (ex.title && ex.title.trim().length > 3 ? ex.title.trim() : nome.replace(/\.(pdf|txt)$/i, '')).slice(0, 140)
        };
    }
    return { linhas, paragrafos, pareceVerso, deTxt, detectarIdioma, dividirFrases, dividirLongo, documento };
});
