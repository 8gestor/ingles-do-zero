/*
 * eventos.js — barramento de eventos TIPADO do app novo (docs/07, seção 4.3).
 *
 * Substitui "ids de DOM + variáveis globais" como forma de um módulo avisar outro. Só existem os eventos DECLARADOS: emitir ou escutar um
 * nome desconhecido é erro (pega erro de digitação na hora, em vez de um aviso que nunca chega). Um módulo novo declara os seus com
 * `eventos.declarar('nome', 'descrição')`. Um escutador que falha não impede os outros nem quem emitiu: o erro vai para `eventos.erros`.
 */
App.define('eventos', [], function () {
    'use strict';
    const catalogo = new Map();          // nome -> descrição
    const escutas = new Map();           // nome -> Set<função>
    const erros = [];

    function declarar(nome, descricao) {
        if (typeof nome !== 'string' || !/^[a-z0-9]+(-[a-z0-9]+)*$/.test(nome)) throw new Error('eventos.declarar: nome inválido (use minúsculas e hífens): ' + nome);
        if (!catalogo.has(nome)) { catalogo.set(nome, descricao || ''); escutas.set(nome, new Set()); }
    }
    function exigir(nome) { if (!catalogo.has(nome)) throw new Error('evento desconhecido: "' + nome + '" (declare com eventos.declarar)'); }

    function on(nome, fn) {
        exigir(nome); if (typeof fn !== 'function') throw new Error('eventos.on: falta a função');
        escutas.get(nome).add(fn);
        return () => off(nome, fn);                                   // devolve o "desligar"
    }
    function off(nome, fn) { exigir(nome); escutas.get(nome).delete(fn); }
    function uma(nome, fn) { const sai = on(nome, function (d) { sai(); return fn(d); }); return sai; }
    function emit(nome, dados) {
        exigir(nome);
        let n = 0;
        Array.from(escutas.get(nome)).forEach((fn) => {
            try { fn(dados); n++; } catch (e) { erros.push({ evento: nome, erro: String((e && e.message) || e), em: Date.now() }); if (erros.length > 50) erros.shift(); }
        });
        return n;                                                      // quantos escutadores rodaram sem erro
    }

    // eventos do núcleo (os módulos de livro, narração e atividades declaram os seus quando forem construídos)
    declarar('config-mudou', 'uma preferência mudou: { chave, valor, antes }');
    declarar('rota-mudou', 'a tela mudou: { rota, params }');
    declarar('armazem-migrado', 'um banco subiu de versão: { banco, de, para, copia }');
    declarar('armazem-erro', 'um banco não abriu ou falhou: { banco, erro }');
    declarar('dados-importados', 'um backup foi carregado: { dias, cartoes, livros }');

    return { declarar, on, off, uma, emit, erros, nomes: () => Array.from(catalogo.keys()) };
});
