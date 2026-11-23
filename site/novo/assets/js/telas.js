/*
 * telas.js — as telas do app novo (docs/07, seção 5). Na fase R1 as telas de estudo são só a moldura: cada uma diz em que fase será
 * construída. A tela técnica `#/sistema` já é de verdade: mostra a saúde do núcleo (módulos, bancos, cópias de segurança, preferências).
 * Tudo é montado com `textContent` (nunca `innerHTML`), então nada que venha de dados vira código.
 */
App.define('telas', ['eventos', 'armazem', 'config', 'rotas'], function (deps) {
    'use strict';
    const { armazem, config, rotas } = deps;
    const h = (tag, cls, txt) => { const e = document.createElement(tag); if (cls) e.className = cls; if (txt != null) e.textContent = txt; return e; };
    const linha = (rot, val) => { const p = h('p', 'sis-linha'); p.append(h('b', null, rot + ': '), document.createTextNode(String(val))); return p; };

    function moldura(titulo, fase, texto) {
        return (el) => {
            el.append(h('h1', 'novo-h1', titulo));
            el.append(h('p', 'novo-fase', 'Em construção · ' + fase));
            el.append(h('p', null, texto));
        };
    }
    rotas.registrar('/hoje', { titulo: 'Hoje', montar: moldura('Hoje', 'fase R3', 'Aqui ficará a sessão do dia: continuar a leitura, palavras para rever e a escrita de hoje, numa ação principal por dia.') });
    rotas.registrar('/estante', { titulo: 'Estante', montar: moldura('Estante', 'fase R3', 'Aqui ficarão os livros por degrau de leitura e o botão para trazer o seu próprio livro (PDF, EPUB ou texto).') });
    rotas.registrar('/palavras', { titulo: 'Palavras', montar: moldura('Palavras', 'fase R3/R4', 'Aqui ficarão as palavras salvas e a revisão espaçada, com a frase do livro.') });
    rotas.registrar('/progresso', { titulo: 'Progresso', montar: moldura('Progresso', 'fase R3', 'Aqui ficará o andamento: tempo lendo, ouvindo, falando e escrevendo, e a sugestão de degrau.') });

    rotas.registrar('/sistema', {
        titulo: 'Sistema',
        montar(el) {
            el.append(h('h1', 'novo-h1', 'Sistema'));
            el.append(h('p', 'novo-fase', 'Saúde do núcleo (fase R1)'));
            const rel = App.relatorio();
            el.append(h('h2', 'novo-h2', 'Módulos · ' + (rel.ok ? 'todos prontos' : 'HÁ FALHAS')));
            const ul = h('ul', 'sis-lista'); ul.id = 'sis-modulos';
            rel.modulos.forEach((m) => { const li = h('li', 'sis-' + m.estado, m.nome + ' — ' + m.estado + (m.erro ? ' (' + m.erro + ')' : '')); li.dataset.estado = m.estado; ul.append(li); });
            el.append(ul);
            el.append(h('h2', 'novo-h2', 'Preferências'));
            const cfg = config.tudo(); Object.keys(cfg).forEach((k) => el.append(linha(k, typeof cfg[k] === 'object' ? JSON.stringify(cfg[k]) : cfg[k])));
            el.append(h('h2', 'novo-h2', 'Armazenamento'));
            const box = h('div', 'sis-armazem'); box.id = 'sis-armazem'; box.append(h('p', null, 'Lendo…')); el.append(box);
            (async () => {
                const out = [];
                try {
                    const d = await armazem.diagnostico();
                    out.push(linha('IndexedDB', d.indexedDB ? 'sim' : 'NÃO'), linha('localStorage', d.localStorage ? 'sim' : 'NÃO (usando memória)'));
                    out.push(linha('Armazenamento persistente', d.persistente === null ? 'não informado' : d.persistente ? 'sim' : 'não'));
                    if (d.estimativa) out.push(linha('Uso / cota', Math.round(d.estimativa.uso / 1024) + ' KB de ' + Math.round(d.estimativa.cota / 1048576) + ' MB'));
                    out.push(linha('Banco do app atual (dd-ingles)', d.versaoLegado ? 'versão ' + d.versaoLegado + ' (somente leitura de versão: não é alterado)' : 'ainda não existe'));
                    out.push(linha('Banco do app novo (dd-ingles-novo)', d.versaoNovo ? 'versão ' + d.versaoNovo : 'ainda não existe'));
                    const cp = await armazem.copias(armazem.BANCO_NOVO.nome);
                    out.push(linha('Cópias de segurança do banco novo', cp.length ? cp.length + ' (a mais recente de ' + new Date(cp[0].em).toLocaleString('pt-BR') + ')' : 'nenhuma ainda (só são feitas antes de migrar)'));
                } catch (e) { out.push(h('p', 'novo-erro', 'Não foi possível ler o armazenamento: ' + String((e && e.message) || e))); }
                box.textContent = ''; out.forEach((n) => box.append(n));
                const b = h('button', 'novo-btn', 'Pedir armazenamento persistente'); b.type = 'button'; b.id = 'sis-persistir';
                b.addEventListener('click', async () => { b.disabled = true; const ok = await armazem.persistir(); b.textContent = ok ? 'Armazenamento persistente: concedido' : 'O navegador não concedeu (tudo continua funcionando)'; });
                box.append(b);
            })();
        }
    });
    return {};
});
