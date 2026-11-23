/*
 * app.js — registro de módulos do app novo (fase R1 da reconstrução; ver docs/07-desenho-reconstrucao.md, seção 4.5).
 *
 * Por que existe: o app de hoje é um monólito ligado por variáveis globais (window.DDLab) e ids de DOM. Aqui cada peça se declara com
 * nome e dependências, e o registro decide a ORDEM de início, recusa dependência faltando ou circular e mostra o que falhou.
 * Sem build e sem `type="module"` (navegadores de e-reader/TV nem sempre suportam): são scripts comuns que se registram em `App`.
 *
 *   App.define('nome', ['dep1', 'dep2'], function (deps) { return { ...api }; });   // pode devolver uma Promise
 *   await App.boot();                                                                   // inicia na ordem certa
 *   App.get('nome')                                                                     // api de um módulo já pronto
 *
 * Um módulo que falha NÃO derruba o app: fica com estado 'erro' e quem depende dele fica 'bloqueado'. `App.relatorio()` mostra tudo
 * (a tela #/sistema usa isso).
 */
(function (g) {
    'use strict';
    const App = g.App = g.App || {};
    const mods = new Map();            // nome -> { nome, deps, fabrica, estado, api, erro }
    let iniciado = false;

    App.versao = 'novo-r1a';

    App.define = function (nome, deps, fabrica) {
        if (typeof nome !== 'string' || !nome) throw new Error('App.define: nome inválido');
        if (!Array.isArray(deps)) throw new Error('App.define(' + nome + '): deps precisa ser uma lista');
        if (typeof fabrica !== 'function') throw new Error('App.define(' + nome + '): falta a função fábrica');
        if (mods.has(nome)) throw new Error('App.define: módulo repetido: ' + nome);
        if (iniciado) throw new Error('App.define(' + nome + '): o app já iniciou; defina os módulos antes de App.boot()');
        mods.set(nome, { nome, deps: deps.slice(), fabrica, estado: 'definido', api: null, erro: null });
    };

    App.tem = (nome) => mods.has(nome) && mods.get(nome).estado === 'pronto';

    App.get = function (nome) {
        const m = mods.get(nome);
        if (!m) throw new Error('App.get: módulo desconhecido: ' + nome);
        if (m.estado !== 'pronto') throw new Error('App.get: módulo "' + nome + '" não está pronto (estado: ' + m.estado + ')');
        return m.api;
    };

    // Ordem de início: dependências primeiro. Devolve { ordem, problemas } sem iniciar nada.
    function planejar() {
        const ordem = [], marca = new Map(), problemas = [];     // marca: 1 = visitando, 2 = pronto
        function visita(nome, trilha) {
            const m = mods.get(nome);
            if (marca.get(nome) === 2) return;
            if (marca.get(nome) === 1) { problemas.push({ modulo: nome, erro: 'dependência circular: ' + trilha.concat(nome).join(' → ') }); return; }
            marca.set(nome, 1);
            m.deps.forEach((d) => {
                if (!mods.has(d)) { problemas.push({ modulo: nome, erro: 'depende de "' + d + '", que não foi definido' }); return; }
                visita(d, trilha.concat(nome));
            });
            marca.set(nome, 2); ordem.push(nome);
        }
        Array.from(mods.keys()).forEach((n) => visita(n, []));
        return { ordem, problemas };
    }

    App.boot = async function () {
        if (iniciado) return App.relatorio();
        iniciado = true;
        const plano = planejar();
        plano.problemas.forEach((p) => { const m = mods.get(p.modulo); if (m && m.estado === 'definido') { m.estado = 'erro'; m.erro = p.erro; } });
        for (const nome of plano.ordem) {
            const m = mods.get(nome);
            if (m.estado === 'erro') continue;
            const ruins = m.deps.filter((d) => !mods.has(d) || mods.get(d).estado !== 'pronto');
            if (ruins.length) { m.estado = 'bloqueado'; m.erro = 'dependência indisponível: ' + ruins.join(', '); continue; }
            m.estado = 'iniciando';
            try {
                const deps = {}; m.deps.forEach((d) => { deps[d] = mods.get(d).api; });
                m.api = (await m.fabrica(deps)) || {};
                m.estado = 'pronto';
            } catch (e) { m.estado = 'erro'; m.erro = String((e && e.message) || e); }
        }
        return App.relatorio();
    };

    App.relatorio = function () {
        const lista = Array.from(mods.values()).map((m) => ({ nome: m.nome, deps: m.deps.slice(), estado: m.estado, erro: m.erro }));
        return { versao: App.versao, ok: lista.every((m) => m.estado === 'pronto'), modulos: lista };
    };

    // Só para testes: volta ao estado inicial (nunca usar no app).
    App._zerar = function () { mods.clear(); iniciado = false; };
})(window);
