/*
 * vozes.js — escolha da VOZ de narração (R2.1; docs/10-r2-narrador.md, seção 3). Puro: recebe a lista de vozes, não toca no navegador.
 *
 * Port fiel de `voiceRank` e `pickVoice` do `ingles.js` de hoje (linhas 667–680) — que é a MESMA regra do menu de vozes da casca
 * (`populateVoices`), então um só código serve às duas coisas:
 *   preferência: neural ("Natural", "Neural") > Google/rede ("online") > locais; o idioma exato (pt-BR, en-US) desempata;
 *   a voz que o aluno escolheu pelo nome sempre vence, se ainda existir na lista.
 * Pontuação (igual à de hoje): neural/natural +10 · "online" +2 · idioma exato +4 · "google" +1 · voz local +0,5.
 */
App.define('vozes', [], function () {
    'use strict';
    const TAG = { pt: 'pt-BR', en: 'en-US' };

    // idioma = 'pt' | 'en'. `voz` = { name, lang, localService } como a do navegador.
    function pontuar(voz, idioma) {
        const l = String(voz.lang || '').replace('_', '-').toLowerCase();
        return (/natural|neural/i.test(voz.name) ? 10 : 0) + (/online/i.test(voz.name) ? 2 : 0) + (l === TAG[idioma].toLowerCase() ? 4 : 0) +
            (/google/i.test(voz.name) ? 1 : 0) + (voz.localService ? 0.5 : 0);
    }
    // vozes do idioma, da melhor para a pior (serve ao menu de escolha de voz)
    function ordenar(idioma, lista) {
        return (lista || []).filter((v) => String(v.lang || '').toLowerCase().indexOf(idioma) === 0).sort((a, b) => pontuar(b, idioma) - pontuar(a, idioma));
    }
    // A voz a usar: a escolhida pelo aluno (por nome) se existir; senão a melhor do idioma; senão null.
    function escolher(idioma, nomePreferido, lista) {
        const vs = lista || [];
        const eleita = nomePreferido && vs.find((x) => x.name === nomePreferido);
        if (eleita) return eleita;
        return ordenar(idioma, vs)[0] || null;
    }
    return { pontuar, ordenar, escolher, TAG };
});
