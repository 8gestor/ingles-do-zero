/*
 * voz.js — compõe as vozes num só contrato (R2.3; docs/10-r2-narrador.md, seção 3). O Narrador fala com ESTA voz e não sabe qual motor
 * está por baixo: a neural (Piper local), quando ativa naquele idioma, senão — ou se ela falhar — a do navegador.
 *
 * Port de `speakOne` do `ingles.js` de hoje (linhas 689–696): "se a neural está ativa, tenta; se devolveu 'fallback', cai no navegador".
 * Recomeçar a fala (velocidade ou voz mudou no meio da frase) vale para os dois motores: devolve 'restart' e o laço do Narrador continua da
 * palavra falada.
 *
 *   compor({ navegador, neural? }) → { falar, cancelar, pedirReinicio, limparReinicio, preparar, ativaNeural }
 */
App.define('voz', [], function () {
    'use strict';
    function compor(op) {
        const nav = op.navegador, neural = op.neural || null;
        let reiniciar = false;
        async function falar(texto, idioma, o) {
            if (neural && neural.ativa(idioma)) {
                const r = await neural.falar(texto, idioma, o);
                if (r !== 'fallback') {
                    if (reiniciar) { reiniciar = false; nav.limparReinicio(); return 'restart'; }
                    return r;
                }
            }
            const r = await nav.falar(texto, idioma, o);
            reiniciar = false;
            return r;
        }
        function cancelar() { if (neural) neural.cancelar(); nav.cancelar(); }
        function pedirReinicio() { reiniciar = true; if (neural) neural.cancelar(); nav.pedirReinicio(); }
        function limparReinicio() { reiniciar = false; nav.limparReinicio(); }
        function preparar(texto, idioma) { if (neural) neural.preparar(texto, idioma); }
        return { falar, cancelar, pedirReinicio, limparReinicio, preparar, ativaNeural: (idioma) => !!(neural && neural.ativa(idioma)) };
    }
    return { compor };
});
