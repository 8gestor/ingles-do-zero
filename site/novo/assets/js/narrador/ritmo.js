/*
 * ritmo.js — modelo de TEMPO da fala (R2.1; docs/10-r2-narrador.md, seção 3). Puro: sem DOM, sem relógio, sem fala.
 *
 * Problema: muitas vozes (sobretudo as de rede) NÃO avisam em que palavra estão. Para destacar a palavra falada em sincronia, o
 * Narrador estima onde a voz está a partir do tempo decorrido. Este módulo é essa estimativa.
 *
 * Como funciona (port fiel do `speakBrowser` do app de hoje, `ingles.js`, linhas 682–757):
 *   · Cada caractere "custa" 1 unidade de tempo; pontuação acrescenta uma PAUSA (vírgula/dois-pontos = 4, ponto/!/?/… = 8).
 *     `modelo(texto)` guarda o tempo acumulado por caractere e o total (WT).
 *   · A velocidade média da voz, em unidades por segundo a 1× (CPS), começa num valor típico por idioma (pt 16, en 17) e é
 *     APRENDIDA a cada frase terminada (média móvel 70/30), separada POR IDIOMA E POR VOZ, limitada a 6–40.
 *   · A posição estimada no instante t é a busca binária do alvo `min(WT, t · CPS · velocidade)` no tempo acumulado.
 * Cada número abaixo é o do app de hoje; o teste NUD/NR compara este módulo com uma cópia literal do código antigo.
 *
 * Melhoria futura JÁ DECIDIDA pelo autor (só depois da paridade): guardar a tabela de CPS entre sessões.
 */
App.define('ritmo', [], function () {
    'use strict';
    const PAUSAS = { ',': 4, ';': 4, ':': 4, '—': 4, '–': 4, '.': 8, '!': 8, '?': 8, '…': 8 };
    const CPS_PADRAO = { pt: 16, en: 17 };
    const CPS_MIN = 6, CPS_MAX = 40;                  // limites da velocidade aprendida
    const MIN_CHARS_APRENDER = 25, MIN_SEGUNDOS_APRENDER = 0.5;     // frase curta demais ou fala curtíssima não ensina nada

    // Tempo acumulado esperado por caractere, com as pausas da pontuação. cum[i] = tempo ao chegar ao caractere i; total = cum[n].
    function modelo(texto) {
        const s = String(texto == null ? '' : texto), cum = new Float32Array(s.length + 1);
        for (let i = 0; i < s.length; i++) cum[i + 1] = cum[i] + 1 + (PAUSAS[s[i]] || 0);
        return { texto: s, cum, total: cum[s.length], tamanho: s.length };
    }
    // Índice do caractere em que a voz está quando já "passaram" `alvo` unidades de tempo (busca binária no tempo acumulado).
    function caractereNoAlvo(m, alvo) {
        let lo = 0, hi = m.tamanho - 1;
        while (lo < hi) { const mid = (lo + hi) >> 1; if (m.cum[mid + 1] > alvo) hi = mid; else lo = mid + 1; }
        return lo;
    }
    // Posição estimada (índice de caractere) depois de `segundos` de fala, com a velocidade média `cps` (a 1×) e o fator `velocidade`.
    function posicaoEm(m, segundos, cps, velocidade) {
        return caractereNoAlvo(m, Math.min(m.total, segundos * cps * velocidade));
    }

    // Tabela de velocidades médias aprendidas. Uma instância por sessão; os testes criam instâncias novas (começam "sem calibração").
    function novaTabela() {
        const cps = Object.assign({}, CPS_PADRAO);
        const chave = (idioma, voz) => idioma + '|' + (voz || '');
        return {
            // velocidade média atual: a aprendida para esta voz, senão o valor típico do idioma
            cpsDe(idioma, voz) { return cps[chave(idioma, voz)] || cps[idioma]; },
            // Chamar quando a frase TERMINOU bem (`end`). `m` = modelo do texto falado, `cpsUsado` = a velocidade que valia no começo da frase,
            // `duracao` = segundos de fala medidos, `velocidade` = fator usado. Devolve o novo valor, ou null se a frase não serve para aprender.
            aprender(idioma, voz, m, cpsUsado, duracao, velocidade) {
                if (!(m.tamanho > MIN_CHARS_APRENDER) || !(duracao > MIN_SEGUNDOS_APRENDER)) return null;
                const novo = Math.max(CPS_MIN, Math.min(CPS_MAX, cpsUsado * 0.7 + (m.total / (duracao * velocidade)) * 0.3));
                cps[chave(idioma, voz)] = novo;
                return novo;
            },
            copia: () => Object.assign({}, cps),
            definir(valores) { Object.keys(valores || {}).forEach((k) => { const v = Number(valores[k]); if (isFinite(v)) cps[k] = Math.max(CPS_MIN, Math.min(CPS_MAX, v)); }); }       // usado só pela melhoria futura (guardar entre sessões)
        };
    }

    return { modelo, caractereNoAlvo, posicaoEm, novaTabela, PAUSAS, CPS_PADRAO, CPS_MIN, CPS_MAX };
});
