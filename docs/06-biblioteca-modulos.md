# 06 · Biblioteca de inglês: módulos, narração, plataformas e sincronização

> Copiado de `voce.algoritmo/CLAUDE.md` em 2026-11-22, no dia da separação dos projetos. **A partir daqui este é o documento vivo**: quando um módulo mudar, atualize AQUI (o livro não é mais alterado por este projeto).
> Caminhos: onde aparece `assets/js/...` ou `tools/...` leia `site/assets/js/...` e `site/tools/...`.

### Estudo de Inglês — módulos (cada um é um arquivo pequeno que se encaixa em `window.DDLab`, exposta por `ingles.js`)

| Arquivo | O que faz |
|---|---|
| `ingles.js` | núcleo: PDF/txt, frases, tradução frase a frase, narração, marcação (parágrafo/linha/frase/palavra), biblioteca, barra inferior |
| `ingles-palavras.js` | toque na palavra (significado, pronúncia, salvar) + vocabulário com repetição espaçada (SM-2 enxuto) + exportar TSV/Anki |
| `ingles-nivel.js` | dificuldade do texto (lista local de ~1.300 palavras comuns + tamanho médio das frases) |
| `ingles-treino.js` | modos Repetir / Shadowing / Ditado (usa `DDLab.afterSentence` e `DDLab.rateScale`) |
| `ingles-compreensao.js` | perguntas sobre o trecho com o modelo LOCAL do Chrome (`LanguageModel`); botão só aparece se o navegador tiver |
| `ingles-progresso.js` | sequência de dias, minutos, palavras ouvidas/salvas, revisões, tempo lendo (`rd`) e ouvindo (`ls`) separados, gráfico de 7 dias (localStorage `dd-ingles-log`; eventos gravam na hora e os tempos a cada 2 s, para uma aba derrubada perder no máximo ~2 s); botão **Zerar estatísticas** com confirmação (apaga log, `heard` dos livros e histórico do roteiro; mantém posição, livros e palavras salvas). Posição de leitura estável: quando a largura da página muda (o menu recolhe no modo foco, a janela é redimensionada, o modo troca) o texto continua reflundo por ~300 ms e o parágrafo visível muda sozinho; o núcleo (`settleAndKeep`) não grava posição enquanto o layout não assenta e então volta ao parágrafo em leitura (antes o app gravava o parágrafo errado, ex.: 60 virava 98). Gravação à prova de fechamento da aba: o núcleo espelha posição e palavras ouvidas em localStorage `dd-ingles-sessao` (`flush` em `pagehide`/`beforeunload`/`visibilitychange`) e, ao reabrir, vale o mais novo entre o banco (`meta.savedAt`) e o espelho |
| `ingles-destaque.js` | botão "Destacar incomuns": pinta no texto as palavras fora da lista comum (CSS Custom Highlight API, não altera o DOM; usa `__ddNivel.isCommon`); escolha em localStorage `dd-ingles-destaque` |
| `ingles-importar.js` | EPUB (ZIP lido com `DecompressionStream`) e texto colado |
| `ingles-sync.js` | conta e sincronização do progresso na nuvem (ver seção Sincronização); bloco `#lb-sync` na página da Biblioteca. Seção SY dos testes |
| `ingles-alinhar.js` | alinhamento de palavras entre o idioma falado e o mostrado (`DDLab.mapPos(falado, charIndex, mostrado, idioma)`, `DDLab.alignPrepare`): parentesco de grafia (laborious ~ laboriosa), tradução da palavra solta pelo Tradutor local (cache `dd-ingles-pal-tr`), posição relativa e programação dinâmica que aceita a troca de vizinhas (substantivo e adjetivo: *laborious diligence* = *diligência laboriosa*). Usado pelo texto corrido (`setWordAt`) e pelo teleprompter; sem ele cai na posição proporcional. Eventos `wordpos` agora levam `lang`. Testes: seção AL |
| `ingles-explorar.js` | **Setas ← → = palavra a palavra** (Shift + seta = frase; a seta pausa a narração): a palavra explorada leva o destaque principal (`setWordAt`) e a equivalente no outro idioma (`mapPos`) leva a segunda cor (`--mk-word2`): na coluna da tradução no lado a lado (`.lb-t .wd2.now2`), numa etiqueta abaixo da palavra nos outros modos (`#lb-gloss`), e nas linhas de baixo da legenda (`.lg-sw.now2`) e do teleprompter (`.tl-sw.now2`, que também acende durante a narração). Evento `explore`; API `DDLab.explore.step(dir)`/`counter`. Testes: seção EX |
| `ingles-teleprompter.js` | 5º modo de leitura, **Teleprompter** = legenda corrida: a frase corre da direita para a esquerda (entra pela direita, a palavra falada fica no ponto de leitura um pouco à direita do centro (62%)) no idioma de LEITURA, a narração fala no idioma de ÁUDIO (ler PT/ouvir EN e o contrário; a posição da palavra é mapeada proporcionalmente entre idiomas), o outro idioma aparece embaixo; o resto da tela some (mensagem `dd-lab-immersive` esconde menu, barra e rodapé do site: `body.imersivo`), botões Ler/Ouvir PT/EN da própria legenda (mensagem `dd-set-option` ao site), ⏮ ▶ ⏭ velocidade A−/A+ (`dd-ingles-tele-size`), contador e barra de progresso; narração começa ao escolher o modo; teclado Espaço ← → + − Esc |
| `ingles-dia.js` | **Sessão do dia** (50 min, 4 blocos) a partir do plano do Livro da semana: leitura densa (cota do dia, fecha sozinha), vocabulário (revisões das palavras que vencem hoje), shadowing (abre o livro no treino de shadowing; meta de palavras ouvidas) e escrita (resumo em 2 frases + objeção, checagem por regras: 15+ palavras, palavra do livro, conectivo de objeção). Estado do dia em localStorage `dd-ingles-dia`, dias completos em `dd-ingles-dia-hist` (sequência), textos em `dd-ingles-escrita` (o zerar estatísticas apaga o hist e o estado do dia, não os textos) |
| (núcleo) versos | Poemas, sonetos e letras: `looksVerse(lines)` (linhas curtas, 80%+ começando em maiúscula, menos de 75% terminando em ponto) transforma o bloco em estrofe `{ t: 'v', s: [linhas] }` na importação de .txt/texto colado e de EPUB com `<br>`; cada linha é uma unidade narrada (a legenda, o teleprompter e a tradução também vão linha a linha) e o bloco é a estrofe (`.lb-verse`, barra lateral). Marcação em 4 camadas, também nos versos: estrofe = parágrafo `.speaking`, linha = `.lb-s.seg` (e a faixa `.lb-band`), palavra = `.wd.now`. PDF não preserva linhas: poemas em PDF continuam em prosa. Livros já importados precisam ser reimportados |
| `ingles-modos.js` | Modos de leitura num só seletor no cabeçalho do leitor (`#lb-read-mode`): coluna única (padrão), coluna larga, lado a lado (original | tradução) e foco com painel (recolhe o menu do site via mensagem `dd-lab-sidebar` e mostra, ao vivo: AGORA = lendo/ouvindo/os dois/pausado com o tempo de cada um na sessão; PROGRESSO = palavras, %, palavras ganhas na sessão e próxima marca 10/25/50/75/90/100%; HOJE = cota do plano; palavras salvas). Os tempos vêm do log de estudo (campos `rd` lendo, `ls` ouvindo, `sec` total) e a posição do evento `progress` do núcleo. Desenho das colunas no núcleo (`paintPara`, `state.mode`/`state.side`, `DDLab.setMode`); classes `body.lb-<modo>-open` só com livro aberto; escolha em localStorage `dd-ingles-modo`; lado a lado precisa do tradutor do navegador |
| `ingles-semana.js` | Livro da semana: **roteiro de 9 semanas** (livros de domínio público em `assets/livros/*.txt`, extraídos da Standard Ebooks; ver o LEIAME da pasta; botão traz o livro para a biblioteca e começa a semana; histórico em `dd-ingles-semana-hist`) **fechamento da semana** (ao concluir o livro: revisão com 8 números reais da semana, resumo de ~150 palavras com objeção e checagem por regras, guardado em `dd-ingles-escrita` com `kind: 'semana'` e marcado no histórico, e sugestão do próximo livro ainda não lido do roteiro) e plano de 7 dias para qualquer livro em inglês da biblioteca, cota diária de palavras, ritmo (em dia/adiantado/atrasado) e palavras difíceis para ver antes; progresso pela posição de leitura (`meta.pos`), plano em localStorage `dd-ingles-semana` |
| `ingles-voz.js` | voz neural LOCAL opcional (Piper, `assets/vendor/piper`): ~60 MB por idioma, baixa uma vez, cai para a voz do navegador se falhar |

### Backup do progresso em arquivo (`ingles-sync.js`, bloco `#lb-backup`) — 2026-11-22

Levar o progresso de um site/aparelho para outro **sem conta e sem internet** (criado para migrar do livro para o site de inglês, serve para sempre).

- **Baixar progresso** gera `progresso-ingles-AAAA-MM-DD.json` = `{ app: 'ingles-progresso', v: 1, exportedAt, data }`, com `data` = o mesmo `snapshot()` da nuvem: estatísticas por dia, vocabulário (cada cartão leva a **frase de contexto** da palavra, como na nuvem), histórico do roteiro e do dia, textos de escrita, posição e palavras ouvidas por livro (título + idioma). **Nunca o corpo dos livros** (sem `paras`).
- **Carregar progresso** (arquivo) e **Colar texto** (para Kindle/TV, que nem sempre baixam/abrem arquivos; se o aparelho não baixa, "Baixar" mostra o texto para copiar). Valida `app`/`v` e normaliza tudo (`cleanBackup`); arquivo estranho é recusado sem mudar nada.
- **Importar = mesclar, nunca apagar:** `merge(local, arquivo)` com as mesmas regras da nuvem (dia/campo = maior valor, cartão = mais revisado, livro = posição mais recente e mais palavras ouvidas, listas em união). Carregar o mesmo arquivo duas vezes não duplica nada.
- **Livros que ainda não estão neste aparelho:** posição e palavras ouvidas ficam em `localStorage` `dd-ingles-pend-docs` (entram nos próximos backups e na nuvem). Quando o livro entra na biblioteca, o evento `imported` (que passa o objeto **antes** de abrir) injeta `pos` e `heard`, e o livro já abre no ponto certo; a pendência some. Livros já existentes são atualizados na hora (`apply`).
- Funciona com a sincronização desligada (sem `sync-config`) e sem conta. API: `DDLab.sync.exportData()`, `importData(texto)`, `applyPending()`.
- Limite conhecido: "Zerar estatísticas" não apaga posições pendentes de livros que ainda não entraram.
- Testes: seção **BK** (11 verificações) de `test_ingles_modulos.ps1`, no site e no livro.
Pontos de extensão do núcleo: eventos `open`, `close`, `lang`, `sentence`, `heard`, `tap`, `stop`, `imported`, `vocab-saved`, `reviewed`, `dictation`;
`DDLab.importers`, `DDLab.badge(meta)`, `DDLab.wordInfo(word, lang)`. Banco IndexedDB `dd-ingles` v2 (`meta`, `docs`, `tr`, `vocab`); `meta.x` guarda extras dos módulos.
Testes: `tools/test_ingles.ps1` (PDF real, núcleo) e `tools/test_ingles_modulos.ps1` (seções A–G, um por módulo; a voz neural é testada com biblioteca simulada).
Voz neural: o JS da biblioteca é local (`assets/vendor/piper`, ver README lá, com 2 linhas alteradas); só WASM e modelos vêm de fora (huggingface.co, cdn.jsdelivr.net, cdnjs). Não usar `TtsSession`/`download()` originais para vários idiomas: o singleton reaproveita a 1ª voz e `download()` não espera a gravação. Teste real (rede) feito em 2026-11-18: EN e PT narram frase a frase e marcam palavras.
No `index.html`, `ingles.html` NÃO entra em `structure` (ver `extras` em `sumario.js`).

### Narração: sincronia e velocidade (núcleo, `ingles.js`)

- **Velocidade 0,1× a 3× em passos de 0,1** em todo o site (menu `#speed-select` do `index.html` com 30 opções e `SPEEDS` em `leitor.js`; a legenda usa lista de escolha e o teleprompter botões − / + e ↑ / ↓). **Setas ← →** exploram palavra a palavra (`ingles-explorar.js`) e **Shift + seta** anda frase a frase: no site (`leitor.js`) a seta vira a mensagem `step` (palavra) ou `step-sentence` (frase), ±1, para a página aberta; a Biblioteca trata em `stepSentence` (tocando, `startTts` da vizinha; parado, só `setMark`), o teleprompter e a legenda têm as suas (evento `step`/`explore` do núcleo) e `capitulo.js` pula de trecho com a narração tocando. **F11** liga/desliga a tela inteira: `leitor.js` trata no site e as páginas (`ingles.js`, `capitulo.js`, teleprompter) mandam `dd-fullscreen` ao site. Testes: seção AR em `test_ingles_modulos.ps1`, 8 em `test_narracao.ps1`, V1 em `test_ingles.ps1`.
- Sem evento de palavra da voz, o destaque é estimado por tempo com **pausas ponderadas** (vírgula/ponto contam mais), velocidade aprendida **por idioma e por voz** (`CPS`) e busca binária a cada 60 ms.
- Trocar velocidade ou voz no meio da frase **retoma da palavra falada** (`resume` em `runTts`), não do início da frase.
- Evento `playstate` `{playing}` (início/fim da narração) alimenta o ▶/❚❚ do teleprompter e da legenda; não há mais sondagem a cada 600 ms. A velocidade mostrada vem de `D.state.rate`.
- **Painel de andamento do teleprompter** (rodapé, `ingles-teleprompter.js`): palavras lidas/total e quantas faltam (sobe a cada palavra), página estimada (250 palavras) e quantas faltam, tempo usado por livro (`dd-ingles-tele-tempo`) com média para concluir pelo ritmo medido (ou ~150 palavras/min x velocidade no começo) e `agora` = lendo e ouvindo ou pausado, idiomas, livro e frase. Testes: seção TC.
- **Buffer à frente:** a frase seguinte entra na fila do motor de voz enquanto a atual toca (`newUtt`/`nextPiece`/`tts.pre` em `speakBrowser`; só com motor que informa `speaking`/`pending` e fora dos modos de treino, via `D.trainMode`), sem lacuna entre frases. O teleprompter mostra a próxima frase esmaecida à direita (`.tl-nx`), segue contínuo ao avançar (modo `carry` de `paintLine`) e traduz as 2 frases seguintes (`prefetch`). Seção Z de `test_ingles_modulos.ps1` mede centragem (erro máx. < 2 px), fila sem lacuna e prévia.
- `pdf.min.js` (320 KB) só é baixado ao importar um PDF (`loadPdfjs`); a página abre sem ele.
- Testes: seções Y (velocidade) e X (combinações ler x ouvir) em `test_ingles_modulos.ps1`.

### Backlog do Estudo de Inglês (pendente)

1. Voz neural: avaliar vozes melhores do Piper (só há 2 em PT-BR, ambas ~60 MB) ou outro motor; hoje a melhor voz continua sendo a "Natural" do Edge.
2. Importar páginas web por URL: o navegador bloqueia (CORS); só com um serviço intermediário (fora da regra de privacidade).
4. Perguntas de compreensão: avaliar com o modelo local quando a API de prompt estiver estável no Chrome.
## Regra de plataformas (vale para toda decisão nova)

O site deve funcionar em **PC, smartphone, tablet, Kindle, TV e outros aparelhos, sem quebrar nada em nenhuma tecnologia** (regra do autor, 2026-11-22).
Na prática, antes de aceitar qualquer recurso ou estrutura nova:

1. **Degradar com graça:** detectar o recurso antes de usar (`speechSynthesis`, `Translator`, `LanguageModel`, IndexedDB, Fullscreen, `fetch`, `DecompressionStream`);
   sem ele, o site abre, lê e salva; só o recurso específico some, com aviso claro. Nunca exigir uma API opcional para a página carregar.
2. **Entrada por qualquer meio:** alvos de toque de pelo menos 44 px; nada que dependa só de mouse, de hover ou de atalho de teclado (todo atalho tem botão equivalente);
   foco visível e uso por controle remoto/teclado (setas, Enter).
3. **Layout fluido:** sem largura fixa; funcionar de ~320 px (celular) a TV; tema legível em tela de papel eletrônico (contraste, sem depender de cor ou animação).
4. **Sem dependências:** nada de biblioteca externa nem build, para o código rodar em navegadores simples (Kindle, TV). Login por **código** digitado, nunca por link.
5. **Dados:** o progresso é local primeiro e a nuvem só copia e mescla (``ingles-sync.js``); só progresso vai para a nuvem, **nunca o texto de livros enviados**
   (direitos autorais). Qualquer estrutura de dados nova entra no snapshot de sync com regra de mescla que não perde nada.
6. **Testar:** o recurso novo precisa de teste com o recurso opcional ausente e, quando mexe em layout, em largura estreita.

### Sincronização do progresso (``ingles-sync.js`` + ``supabase/``)

- Supabase (Postgres + login por código de e-mail) pela API REST com ``fetch``; configuração em ``assets/js/sync-config.js`` (``url`` e chave pública ``anon``; vazios = desligado).
  Passo a passo em ``supabase/LEIAME.md``; esquema com segurança por linha em ``supabase/schema.sql`` (uma linha por pessoa).
- O que sobe: estatísticas por dia, vocabulário, posição e palavras ouvidas por livro (casado por título + idioma), históricos do roteiro e do dia, textos de escrita. Nunca o texto dos livros.
- Mescla (``DDLab.sync.merge``): dia/campo = maior valor; cartão = o mais revisado; livro = posição mais recente e maior nº de palavras ouvidas; listas = união.
  Gravação condicionada a ``updated_at``; se outro aparelho gravou no meio, relê, mescla e tenta de novo. Sem conexão tudo segue salvo localmente e sobe depois.
- Quando sincroniza: ao entrar, ao fechar um livro, depois de revisões/escritas/importações, ao esconder a aba e a cada minuto com mudanças; botão "Sincronizar agora".
- Testes: seção SY de ``test_ingles_modulos.ps1`` (nuvem simulada com ``fetch`` falso).

