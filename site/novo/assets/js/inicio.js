/*
 * inicio.js — liga o app novo: aplica a aparência escolhida, marca o item do menu e abre a rota do endereço.
 * É o último módulo: se ele (ou algo de que depende) falhar, a página mostra o que falhou em vez de ficar em branco.
 */
App.define('inicio', ['eventos', 'armazem', 'config', 'rotas', 'telas'], function (deps) {
    'use strict';
    const { eventos, config, rotas } = deps;

    function aparencia() {
        document.body.className = config.get('theme') + '-mode';
        document.documentElement.dataset.face = config.get('face');
        document.documentElement.style.setProperty('--base-size', config.get('font') + 'px');
        document.documentElement.lang = config.get('readLang') === 'en' ? 'en' : 'pt-BR';
    }
    function marcaMenu(r) {
        document.querySelectorAll('#novo-menu a').forEach((a) => {
            const on = a.getAttribute('href') === '#/' + String((r && r.rota) || '').split('/')[1];
            a.classList.toggle('on', on); if (on) a.setAttribute('aria-current', 'page'); else a.removeAttribute('aria-current');
        });
    }
    aparencia();
    eventos.on('config-mudou', aparencia);
    eventos.on('rota-mudou', marcaMenu);
    // A rota inicial só abre DEPOIS que todos os módulos terminaram de iniciar (no fim do boot, abaixo): se abrisse aqui, dentro da fábrica,
    // a tela Sistema (aberta direto por #/sistema) veria este próprio módulo como "iniciando" e mostraria "HÁ FALHAS".
    return { abrir() { rotas.iniciar(document.getElementById('vista')); } };
});

// Liga tudo quando a página carrega; se algo falhar, mostra no lugar da tela.
window.addEventListener('DOMContentLoaded', function () {
    App.boot().then(function (rel) {
        if (App.tem('inicio')) App.get('inicio').abrir();               // primeiro abre a tela; só então avisa que o app está pronto
        window.__appPronto = App.relatorio();
        if (rel.ok) return;
        const v = document.getElementById('vista'); if (!v) return;
        v.textContent = '';
        const p = document.createElement('p'); p.className = 'novo-erro'; p.textContent = 'Alguma parte do app não iniciou:'; v.appendChild(p);
        const ul = document.createElement('ul');
        rel.modulos.filter(function (m) { return m.estado !== 'pronto'; }).forEach(function (m) { const li = document.createElement('li'); li.textContent = m.nome + ' — ' + m.estado + (m.erro ? ' (' + m.erro + ')' : ''); ul.appendChild(li); });
        v.appendChild(ul);
    });
});
