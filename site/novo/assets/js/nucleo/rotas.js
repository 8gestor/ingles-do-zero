/*
 * rotas.js — navegação do app de página única (docs/07, seção 4.4): substitui "iframe + postMessage" por rotas no endereço (#/hoje, #/ler/<livro>).
 * Voltar/avançar do navegador funcionam sozinhos (é só o hash). Rota desconhecida cai na rota padrão. Cada rota tem `montar(contêiner, params)`.
 *
 *   rotas.registrar('/ler/:livro', { titulo: 'Leitura', montar(el, p) { ... p.livro ... } });
 *   rotas.iniciar(document.getElementById('vista'));  rotas.ir('/palavras');
 */
App.define('rotas', ['eventos'], function (deps) {
    'use strict';
    const ev = deps.eventos, tabela = [], PADRAO = '/hoje';
    let el = null, atual = null, ligado = false;

    const partes = (c) => String(c || '').split('/').filter(Boolean);
    const desfaz = (s) => { try { return decodeURIComponent(s); } catch (e) { return s; } };

    function registrar(padrao, def) {
        if (typeof padrao !== 'string' || padrao[0] !== '/') throw new Error('rotas.registrar: o padrão precisa começar com "/": ' + padrao);
        if (!def || typeof def.montar !== 'function') throw new Error('rotas.registrar(' + padrao + '): falta montar()');
        if (tabela.some((r) => r.padrao === padrao)) throw new Error('rotas.registrar: rota repetida: ' + padrao);
        tabela.push({ padrao, partes: partes(padrao), def });
    }
    function casar(caminho) {
        const p = partes(caminho);
        for (const r of tabela) {
            if (r.partes.length !== p.length) continue;
            const params = {};
            const bate = r.partes.every((x, i) => (x[0] === ':' ? ((params[x.slice(1)] = desfaz(p[i])), true) : x === p[i]));
            if (bate) return { rota: r.padrao, def: r.def, params, caminho: '/' + p.join('/') };
        }
        return null;
    }
    const caminhoDoHash = () => { const h = String(location.hash || '').replace(/^#/, ''); return h ? (h[0] === '/' ? h : '/' + h) : ''; };
    function ir(caminho) { const alvo = '#' + caminho; if (location.hash === alvo) resolver(); else location.hash = alvo; }

    function resolver() {
        if (!el) return;
        let c = casar(caminhoDoHash() || PADRAO);
        if (!c) { c = casar(PADRAO); try { history.replaceState(null, '', '#' + PADRAO); } catch (e) { /* file:// */ } }
        if (!c) return;
        if (atual && atual.caminho === c.caminho && atual.montado) return;
        el.textContent = '';
        atual = { rota: c.rota, caminho: c.caminho, params: c.params, montado: false };
        try { c.def.montar(el, c.params); atual.montado = true; }
        catch (e) { const p = document.createElement('p'); p.className = 'novo-erro'; p.textContent = 'Esta tela não abriu: ' + String((e && e.message) || e); el.appendChild(p); }
        if (c.def.titulo) document.title = c.def.titulo + ' · Inglês';
        ev.emit('rota-mudou', { rota: c.rota, params: c.params });
    }
    function iniciar(contêiner) {
        el = contêiner;
        if (!ligado) { window.addEventListener('hashchange', resolver); ligado = true; }
        resolver();
    }
    return { registrar, casar, ir, iniciar, atual: () => atual, lista: () => tabela.map((r) => r.padrao), PADRAO };
});
