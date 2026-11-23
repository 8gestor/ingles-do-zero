# 10 · R2 · Motor Narrador (mapa do que existe e desenho proposto)

> **Estado: desenho APROVADO em 2026-11-22 (decisões na seção 6). Andamento: R2.1 e R2.2 FEITAS; próxima R2.3.** Itens **(?)** restantes são decisões do autor.
> Contexto: `07-desenho-reconstrucao.md` (fase R2, motores), `08-paridade.md` (contrato: áreas `c5 c6 V X Y Z AR AL G`), `09-nucleo-novo.md` (núcleo pronto).
> **Princípio da R2: mover sem mudar o comportamento.** Melhorias vêm depois da paridade, uma por vez, com teste.

---

## 1. Mapa: o que a narração é hoje (`ingles.js`, linhas 663–949, ~290 linhas)

| Bloco | Linhas | O que faz | Acoplamentos (o que precisa de fora) |
|---|---|---|---|
| Estado `tts` | 664 | `{ playing, token, cursor, mark, word, restart, pre }` | variável única, mexida por quase todas as funções |
| Escolha de voz | 667–680 | `voiceRank`, `pickVoice`: neural > Google/rede > locais; idioma exato desempata; a voz escolhida pelo aluno vence | `synth`, `state.voices`, `LANG_TAG` |
| Modelo de ritmo | 682–685, 736–757 | velocidade média em caracteres/segundo por idioma **e por voz** (`CPS`, aprendida a cada frase); pausas ponderadas (`,` = 4, `.` = 8…); tempo acumulado por caractere e **busca binária a cada 60 ms** quando a voz não informa a palavra | só o texto e a velocidade |
| Falar uma frase | 689–769 | `speakOne` (voz neural se ativa, senão navegador), `newUtt`, `speakBrowser`: ganchos de início/palavra/fim, **fila à frente** (a próxima frase entra na fila do motor enquanto a atual toca), aprendizado de `CPS` | `DDLab.neural`, `DDLab.rateScale`, `DDLab.trainMode`, `synth.speaking/pending` |
| Marcação na tela | 771–844 | `wrapWords`, `setWordAt`, `markSpan`, `setMark`, `moveBand`, `keepInView`: 4 camadas (parágrafo, linha, frase, palavra) | **DOM**, `paraEl`, `paintPara`, `DDLab.mapPos` (alinhamento entre idiomas) |
| Texto da frase | 846–858 | `textFor`: texto no idioma de áudio; traduz só esta frase (caminho rápido) e cai no original se faltar | **tradutor** (`trSentence`, `ensureTr`, `pump`), `doc.tr` |
| **Laço de reprodução** | 860–895 | `runTts`: percorre frases, cancela por **token**, pula o que não tem letra, mantém a tradução à frente, **retoma da palavra falada** se a velocidade/voz mudou, conta palavras ouvidas, gancho de treino (repetir/shadowing/ditado), para após 3 erros seguidos | `doc`, tradução, `emit`, `scheduleMetaSave`, `DDLab.afterSentence` |
| Controle | 897–949 | `startTts`, `stopTts`, `restartCurrent`, `stepSentence` (setas), F11 | `doc`, DOM, `postParent` (casca), `firstVisible` |

**Eventos que o resto do app escuta hoje:** `sentence`, `piece`, `wordpos`, `heard`, `playstate`, `stop`, `restartspeech` (legenda, teleprompter, treino, progresso, modo foco dependem deles).

### O que isso mostra
O bloco mistura **quatro responsabilidades**: (A) *motor de voz e tempo* (sem DOM, sem livro), (B) *laço de reprodução* (precisa só de "dê-me o texto da frase N"), (C) *marcação na tela* (DOM) e (D) *tradução*. Só (A) e (B) são o Narrador; (C) é do **Leitor**; (D) vira o **serviço Tradutor** que o Leitor oferece ao Narrador por uma interface.

---

## 2. Comportamentos que PRECISAM ser preservados (viram testes)

1. **Cancelamento por token:** nenhum evento de uma fala antiga pode mexer na fala nova (parar, trocar de frase e mudar de idioma no meio).
2. **Fila à frente sem lacuna:** a frase seguinte entra na fila do motor enquanto a atual toca; só com motor que informa `speaking`/`pending` e fora dos modos de treino; se o fluxo mudou, a fila sobrando é limpa.
3. **Retomar da palavra:** trocar velocidade ou voz no meio da frase continua **da palavra falada**, nunca do começo da frase, e o destaque não volta atrás.
4. **Sem evento de palavra:** o destaque avança por estimativa de tempo (pausas ponderadas, velocidade aprendida **por idioma e por voz**), sem voltar atrás e chegando perto do fim da frase.
5. **Idioma de áudio ≠ idioma do livro:** fala a tradução; sem tradução, cai para o original **e a voz acompanha** o idioma do texto realmente falado.
6. **Pular o que não é fala:** frase sem letra nem número é ignorada; 3 erros seguidos param a narração.
7. **Palavras ouvidas:** só conta quando a frase termina bem (`end`), pelas palavras do texto falado.
8. **Passo (setas):** ← → andam frase a frase atravessando parágrafos; tocando, a voz segue da nova frase; parado, só a marca anda.
9. **Gancho de treino:** depois de cada frase, o modo de treino pode pedir "repetir"; a velocidade pode ser escalada (`rateScale`).
10. **Velocidade 0,1× a 3×** de 0,1 em 0,1 (preferência já no núcleo novo).

---

## 3. Desenho proposto

### 3.1 Peças (arquivos novos em `site/novo/assets/js/narrador/`)

```
              ┌────────────────────────────────────────────────────────┐
  Leitor ───▶ │  narrador.js   laço de reprodução, cursor, token,      │ ──▶ eventos tipados
 (fonte de    │                passo, retomar na palavra, ganchos      │     (marcação, legenda,
  texto)      └──────┬─────────────────┬──────────────────┬────────────┘      teleprompter, registro)
                     │                 │                  │
              ritmo.js (puro)    vozes.js (puro)    voz-*.js (motores)
              tempo por caractere,   escolher a voz,    navegador (speechSynthesis + fila à frente)
              CPS por idioma+voz,    ranking            neural (Piper, opcional)  ·  [gravada, futuro]
              posição estimada
```

| Arquivo | Responsabilidade | DOM? | Testável sem Chrome real? |
|---|---|---|---|
| `ritmo.js` | modelo de tempo: pesos de pausa, tempo acumulado, busca da posição, aprendizado de velocidade por idioma+voz | não | **sim, determinístico** |
| `vozes.js` | `pontuar` e `escolher(idioma, nomePreferido, lista)` | não | **sim** |
| `voz-navegador.js` | `falar(texto, idioma, { velocidade, aoProgresso, proxima }) → Promise<'end'\|'cancel'\|'error'>`, fila à frente, `cancelar()` | não | sim, com **speechSynthesis falsa** |
| `voz-neural.js` | adaptador do Piper (`ingles-voz.js`) atrás do mesmo contrato; devolve `'fallback'` quando não ativo | não | sim, com Piper simulado |
| `narrador.js` | `abrir(fonte)`, `tocar(p, s)`, `parar()`, `passo(dir)`, `retomarNaPalavra()`, `estado()`; ganchos `aoTerminarFrase`, `escalaDeVelocidade`, `modoTreino` | não | sim |

**Contrato da Fonte** (quem fornece o texto; o Leitor implementa): `paragrafos()`, `frases(p)`, `idiomaOriginal`, `texto(p, s, idioma, token) → Promise<{ text, lang } \| null>` (traduz ou cai no original), `jaPronta(p, s, idioma) → { text, lang } \| null` (para a fila à frente, sem esperar).
**Contrato da Voz**: `ativa(idioma)`, `falar(...)`, `cancelar()`, `filaAFrente()`. O Narrador não sabe qual motor está usando.

### 3.2 Eventos (tipados, declarados no núcleo)
`narracao-estado { tocando }` · `narracao-frase { p, s, texto, idioma }` · `narracao-palavra { ci, len, texto, idioma }` · `narracao-parou` · `narracao-retomou` e o já existente `frase-ouvida { palavras, p, s }` (o registro de estudo já escuta). Mapa dos eventos de hoje: `sentence`→`narracao-frase`, `piece`→(mesmo evento, com o texto falado), `wordpos`→`narracao-palavra`, `heard`→`frase-ouvida`, `playstate`→`narracao-estado`, `stop`→`narracao-parou`, `restartspeech`→`narracao-retomou`.

### 3.3 O que NÃO entra no Narrador
- **Marcação na tela** (`wrapWords`, `setWordAt`, faixa de linha, rolagem): é do **Leitor** (segunda metade da R2), que escuta `narracao-frase` e `narracao-palavra`.
- **Alinhamento de palavras entre idiomas** (`mapPos`): serviço do Leitor/Narrador consumido pela marcação (área `AL`).
- **Gravação da voz do aluno** (shadowing): atividade da **R4**.
- **Tradução**: serviço Tradutor, atrás da Fonte.

### 3.4 Melhorias possíveis (NÃO nesta fase; só depois da paridade, uma por vez)
- **Guardar a velocidade média aprendida por voz** (hoje volta ao valor típico a cada abertura da página): melhora a sincronia já na primeira frase. **Decidido: só depois da paridade.**
- Estado da narração concentrado num só objeto, em vez de variável global mexida por várias funções (já resolvido pela arquitetura acima).
- Relógio injetável (`agora()` e timers), usado para testar sincronia de forma **determinística** (ver 4).

---

## 4. Como vamos provar que nada mudou (estratégia de testes)

Novo arquivo `site/tools/test_novo_narrador.ps1`, no mesmo estilo. Três camadas:

1. **Ritmo, determinístico (sem Chrome de fala, sem relógio real).** Os 4 cenários do `test_sync.ps1` do livro: voz **lenta**, **rápida**, **esparsa** (evento de palavra só a cada 3) e **com evento em toda palavra**; mede o erro médio em palavras entre o destaque e a palavra realmente falada, critério herdado: **erro médio ≤ 1,5 palavra**. Como o tempo é simulado, **não sofre da instabilidade por carga da máquina** que vimos nos testes de hoje.
2. **Comportamentos 1–10 da seção 2, com `speechSynthesis` falsa controlada à mão:** fila à frente sem lacuna (Z2), retomar da palavra (Y1 e Y2), troca de idioma no meio (c6), passo e setas (lógica de AR1 e AR4), parada após 3 erros, token cancelando eventos atrasados, contagem de palavras ouvidas, gancho de repetir, escala de velocidade.
3. **Paridade com o app de hoje:** a mesma sequência (abrir, tocar, trocar velocidade, passo, parar) roda no `ingles.js` (moldura, como no teste de dados) e no Narrador; compara-se a **sequência de falas** (texto, idioma, velocidade, ordem). É o mesmo método que provou a mescla idêntica na R1b.

Os testes da área `c5`, `V`, `X`, `Z3–Z5` e `AL4` dependem da **marcação na tela, do teleprompter e da legenda**; passam quando o **Leitor** e os **modos de leitura** existirem (R2 segunda metade e R3). A matriz (`08`) registra isso, item a item.

---

## 5. Sequência de trabalho da R2

| Etapa | Entrega | Saída verificável |
|---|---|---|
| **R2.1** — **FEITA 22/11/2026** | `ritmo.js` e `vozes.js` | cenários de sincronia determinísticos verdes; ranking de voz igual ao de hoje (**13 verificações `NR`, ver seção 7**) |
| **R2.2** — **FEITA 23/11/2026** | `voz-navegador.js` e `narrador.js` com `speechSynthesis` falsa | comportamentos 1–10 verdes (**12 verificações NR8–NR17, ver seção 8**) |
| **R2.3** | `voz-neural.js` (adaptador do Piper) | com Piper simulado, cai no navegador se falhar (área `G`) |
| **R2.4** | Teste de paridade com o `ingles.js` de hoje | sequências de falas idênticas |
| **R2.5** | **Leitor**: texto, frases, marcação em 4 camadas, importação, tradução por frase | áreas `c2 c4 R W` e as de marcação (`5c–5f`, `V4–V8`) |
| **R2.6** | Integração e atalhos (setas, F11) | `AR`, `Y`, `EX` verdes no app novo |

Cada etapa termina com **testes verdes, documentação atualizada e CHANGELOG**, e só avança com o seu aval.

---

## 6. Decisões do autor (2026-11-22)

1. **Desenho aprovado; começar pela R2.1.**
2. **Velocidade aprendida por voz: guardar, mas SÓ depois da paridade** (melhoria separada e testada; a R2 mantém o comportamento de hoje: reaprender a cada abertura).
3. **Voz neural (Piper): portar o adaptador já na R2.3** (não só o contrato), com teste usando um Piper simulado.
4. **Ordem: Narrador primeiro, Leitor depois.**

---

## 7. R2.1 · resultado (2026-11-22)

**Entregue:** `site/novo/assets/js/narrador/ritmo.js` e `vozes.js` (puros: sem DOM, sem relógio, sem fala) e `site/tools/test_novo_narrador.ps1` (**13 verificações, todas passando**).

| Peça | Prova |
|---|---|
| `ritmo.modelo` (tempo acumulado com pausas da pontuação) | **idêntico** ao código antigo em 300 textos aleatórios (NR1) |
| `ritmo.posicaoEm` (posição estimada por busca binária) | **idêntica** em 600 combinações de texto, velocidade e tempo (NR2) |
| `ritmo.novaTabela().aprender` (velocidade aprendida por idioma e voz, limites 6–40) | **idêntica** em 600 casos; começa em 16 (pt) e 17 (en); uma voz não afeta outra (NR3) |
| `vozes.escolher` e `vozes.ordenar` | **idênticas** à escolha do `ingles.js` e ao menu de vozes da casca em 600 listas aleatórias: o menu e o Narrador sempre concordam na "melhor voz" (NR4, NR5) |
| Sincronia por estimativa (voz sem evento de palavra) | cenários lenta e rápida do `test_sync.ps1` a 0,7×, 1× e 1,5×, **tempo simulado**: erro médio **0,35 a 0,73 palavra** (limite herdado: 1,5); o destaque **nunca volta atrás**; chega a 1 palavra do fim em **todas** as frases (NR6, NR7) |

**Método:** o teste carrega uma **cópia literal do código antigo** ("oráculo") ao lado do módulo novo e compara com entradas aleatórias de semente fixa. Como não usa fala nem relógio reais, **não sofre da instabilidade por carga da máquina** dos testes de hoje.
**Observação honesta:** no pior caso (frase de aprendizado, sem calibração prévia) o erro máximo chegou a 5 palavras com voz lenta; depois da primeira frase o erro cai (p95 = 3). É o comportamento do algoritmo de hoje, preservado de propósito (a calibração guardada entre sessões é a melhoria decidida para depois da paridade).
---

## 8. R2.2 · resultado (2026-11-23)

**Entregue:** `site/novo/assets/js/narrador/voz-navegador.js` (motor de voz do navegador) e `narrador.js` (laço de reprodução), ligados em `site/novo/index.html`; `test_novo_narrador.ps1` foi de 13 para **25 verificações** (NR8a e NR8–NR17). O app de hoje não foi tocado.

**Método:** nada de fala nem relógio reais. Os testes usam uma `speechSynthesis` **falsa** (nada começa nem termina sozinho; o cancelamento chega depois, como no navegador) e um **relógio falso** injetado (`agora`, `setInterval`, `setTimeout`). Por isso não sofrem com a carga da máquina. Confirmei que os testes pegam defeito: desligar a limpeza da fila (NR9) ou o cancelamento por token (NR8) faz o teste correspondente falhar.

| Comportamento (seção 2) | Prova |
|---|---|
| 1 · cancelamento por token | NR8: depois de parar e de começar outra frase, eventos atrasados (palavra, fim) da fala velha são ignorados |
| 2 · fila à frente sem lacuna | NR9: cada frase é enviada uma vez, na ordem; nos modos de treino não há fila; pulo ou velocidade diferente limpam a fila que sobrou |
| 3 · retomar da palavra | NR10: trocar a velocidade fala "delta epsilon…" a 2× e o destaque nunca volta atrás |
| 4 · sem evento de palavra | NR11a: destaque por estimativa cresce sem voltar e chega ao fim; NR11b: com evento em dia a estimativa não corre à frente |
| 5 · idioma do áudio ≠ do livro | NR12: fala a tradução com a voz pt-BR; sem tradução cai no original e a voz acompanha (en-US) |
| 6 · pular o que não é fala; erros | NR13: frase sem letra é pulada; mais de 3 erros seguidos param |
| 7 · palavras ouvidas | NR14: só conta no `end`, pelas palavras do texto falado |
| 8 · passo (setas) | NR15: parado só a marca anda (atravessa parágrafos, para nas pontas); tocando a voz segue |
| 9 · ganchos de treino | NR16: "repetir" fala de novo; escala de velocidade multiplica (1,2 × 0,5 = 0,6) |
| 10 · velocidade 0,1×–3× | NR16: 0,1 e 3 chegam à voz sem corte |
| vigias (mapa da seção 1) | NR17: vigia de partida (7 s, tenta de novo uma vez) e de mudez |

**Contratos fixados (para o Leitor da R2.5 e a voz neural da R2.3):** Fonte `{ paragrafos, frases, texto(p,s,idioma,vale), jaPronta, antecipar?, primeiraVisivel? }`; Voz `{ falar, cancelar, pedirReinicio, limparReinicio }`; eventos `narracao-estado`, `narracao-frase`, `narracao-palavra`, `narracao-parou`, `narracao-retomou` e `frase-ouvida { palavras, p, s }`. Diferença deliberada em relação ao texto da seção 3: a Fonte recebe `vale()` (função) no lugar do `token` numérico, para não expor o contador interno.
**Adiado de propósito:** a marcação na tela (Leitor, R2.5), o adaptador do Piper (R2.3) e a prova de paridade com o `ingles.js` de hoje (R2.4).
