# Registro de evolução (CHANGELOG)

> Uma entrada por dia de trabalho, da mais nova para a mais antiga. Escreva **o que mudou, por quê e como conferir**. Mantém o autor e o Claude sem precisar reler conversas antigas.
## 2026-11-23 · Teleprompter mais fluido (frases longas)

- **Relato do autor:** o teleprompter travava um pouco durante a leitura. **Diagnóstico (por leitura do código, sem perfil no aparelho dele):** não era memória; era trabalho na thread principal durante a animação. O alinhamento de palavras entre idiomas (`ingles-alinhar.js`) tinha custo cúbico na frase, era refeito a cada lote de traduções e rodava no meio do deslize; o rodapé reescrevia ~12 textos a cada palavra. *Noites Brancas* tem frases de 100 a 200 palavras.
- **Correções:** (1) frase com mais de 1.600 pares palavra×palavra alinha só numa faixa de ±16 palavras em torno da diagonal (custo linear; frases curtas seguem com a conta completa, resultado idêntico); (2) `DDLab.alignWarm` calcula o alinhamento da frase atual e da seguinte em tempo ocioso (`requestIdleCallback`), chamado por `render()` do teleprompter; (3) traduções novas não invalidam mais, na hora, o cálculo de frase longa (ele é refeito em tempo ocioso; frase curta continua recalculando na hora); (4) rodapé de estatísticas a cada 250 ms durante a fala (`paintStatsSoon`), e `mark()` troca só as duas palavras que mudam no passo normal.
- **Medição (Chrome, frase de 220 palavras, tempo real):** 66 ms → 14 ms por alinhamento, mesmo resultado. Em aparelho fraco (celular, TV, Kindle) os números absolutos serão maiores, a proporção deve se manter.
- **Teste:** AL6 (frase longa: cada palavra cai na equivalente) em `test_ingles_modulos.ps1`; `test_ingles_modulos.ps1` e `test_ingles.ps1` passam. Branch `fix/teleprompter-fluidez`, não publicado.

## 2026-11-23 · Testes sem resultado: orcamento de tempo virtual do Chrome

- **Defeito do teste (nao do site):** rodadas do `test_ingles_modulos.ps1` terminavam sem a linha RESULTADO (cortadas em 173 a 250 das 259 linhas, sem nenhum FAIL). **Causa:** o Chrome sem tela encerrava ao esgotar `--virtual-time-budget=4200000` (70 min virtuais); com disco/CPU lentos o tempo virtual corre mais depressa durante as esperas por IndexedDB.
- **Correcao:** orcamento subiu para 40000000 (so um teto; o teste termina quando acaba).
- **Conferido:** 6 de 6 rodadas completas (259 linhas, "tudo certo"); antes, cerca de 1 em 3 vinha cortada.

## 2026-11-23 · Noites Brancas, de Dostoiévski, vira o primeiro livro da Biblioteca

- **Pedido do autor:** incluir *Noites Brancas* (1848, domínio público) como primeiro livro da lista.
- **O que mudou:** o roteiro passou de 8 para 9 semanas; *White Nights* é a **semana 1** e os outros livros subiram uma posição (o histórico é por `slug`, então o progresso de quem já leu não se perde). Texto em `site/assets/livros/dostoievski-noites-brancas.txt` (~20 mil palavras, só a novela, sem as outras histórias do volume). **Fonte:** tradução de Constance Garnett (1918), Project Gutenberg #36034; a Standard Ebooks ainda não publica esta obra. O original é em russo, então a Biblioteca traz a tradução inglesa em domínio público; o português vem do Tradutor do Chrome, como nos demais livros.
- **Arquivos:** `ingles-semana.js` (ROTEIRO e textos), `LEIAME.md` dos livros, manual (PT/EN), `test_ingles_modulos.ps1` (L9–L13, Q5–Q7 ajustados para 9 livros e semana 3 = Epicteto).
- **Conferir:** `pwsh tools\test_ingles_modulos.ps1` (resultado: tudo certo). Não publicado; branch `feature/noites-brancas`.

## 2026-11-23 · Teste DG7 estavel (espera pela lista, nao por tempo fixo)

- **Defeito do teste (nao do site):** o DG7 usava `wait(600)` apos trocar o idioma; se a lista do Degrau 0 redesenhava depois, lia estado velho (`toda=false` ou `pouco=true`).
- **Correcao** (`test_ingles_modulos.ps1`): espera ate a linha 1 ficar "done" (ouviu tudo) e ate deixar de ficar (ouviu pouco). Codigo do site intocado.
- **Conferido:** DG7 passou 8 de 8 rodadas. Algumas rodadas terminam sem a linha final RESULTADO (execucao encerrada antes do fim, sem FAIL; tambem acontece no main anterior): investigar a parte.

## 2026-11-22 · Degrau 0: fabula ouvida inteira passa a contar como lida

- **Defeito (relatado pelo autor):** mesmo lendo/ouvindo a historia toda, ela nao ficava concluida. **Causa:** a fabula cabe numa tela, a pagina nao rola e `meta.pos` fica em 0; o Degrau 0 so marcava "lida" com `pos` no ultimo paragrafo.
- **Correcao** (`ingles-degrau0.js`): lida = chegou ao ultimo paragrafo OU ouviu 80% das palavras (`meta.heard`); "em andamento" tambem considera palavras ouvidas.
- **Teste:** DG7 em `test_ingles_modulos.ps1`. Rodadas completas tiveram falhas intermitentes diferentes (G6, L7, A18, TC5), nenhuma ligada ao Degrau 0.

## 2026-11-22 · Manual reescrito (explica o sistema inteiro)

- **Pedido do autor:** reescrever todo o manual explicando como funciona todo o sistema.
- **Feito:** `site/manual-biblioteca.html` (PT e EN) agora tem 12 seções: a ideia (ler, ouvir, falar, escrever), mapa do site e barra do topo, primeiro dia (Degrau 0 ou roteiro), biblioteca e livros, leitor (modos, narração, cores), ler e ouvir, teleprompter, ferramentas de estudo e vocabulário, rotina (sessão do dia e progresso), aparelhos, conta e backup, privacidade, problemas. Corrige o texto antigo que citava "colar texto" (retirado da interface) e acrescenta Degrau 0, seções do menu e Configurações.
- **Teste:** M1 em `test_ingles.ps1` passou a esperar 12 seções por idioma.
- **Não publicado** (regra do autor).


## 2026-11-22 (madrugada) · Testes instáveis do app de hoje: causa e conserto (DG5, TC5, L14, L7)

- **Pedido do autor:** corrigir os testes que oscilavam (DG5, TC5, L14). Eram falhas dos **testes**, não do código do app.
- **Medido antes:** só **5 de 12** rodadas de `test_ingles_modulos` limpas (DG5 falhou em 5, "exceção" em 2, L14 em 1; TC5 e L7 em outras rodadas).
- **Causa raiz** (a mesma que já tinha mordido os testes novos): o Chrome de teste usa **tempo virtual**, e enquanto a página espera o disco (IndexedDB) o relógio corre. Três formas frágeis de esperar:
  1. `until(fn, ms)` com **prazo curto** (ex.: 5000): vencia antes de o disco responder e o teste conferia cedo demais (L7, L14, "elemento nulo").
  2. `wait(600)` **fixo** antes de conferir a tela (DG5): conferia antes de a lista ser redesenhada.
  3. **TC5**: o contador do teleprompter só conta com atividade nos últimos 60 s do relógio do app, e o teste nunca simulava atividade; só passava se o relógio virtual ainda não tivesse corrido 60 s desde o carregamento.
- **Conserto** (só em `site/tools/test_ingles_modulos.ps1` e `test_ingles.ps1`; **nenhum código do app mudou**): `until` passa a tratar o prazo pedido como **piso** (espera até 15 min virtuais); DG5 espera a condição (`until`) em vez de `wait(600)`; TC5 simula a atividade (`pointerdown`) antes de medir.
- **Medido depois:** **20 de 20** rodadas limpas de `test_ingles_modulos` numa máquina normal (antes: 5 de 12). Sob **carga máxima artificial** (12 processos ocupando os 12 núcleos): 8 de 10 limpas e o `test_ingles` (PDF) passou; as 2 falhas foram em **E5** e **L5**, uma vez cada, e não tinham falhado antes.
- **Resíduo conhecido (honesto):** E5 e L5 oscilaram uma vez cada sob carga extrema; **não tenho causa confirmada**, então não alterei nada neles. Se aparecerem em máquina normal, aplicar a mesma receita (esperar a condição, nunca prazo curto nem `wait` fixo) ao teste específico. Ainda há ~159 `wait(N)` fixos nos testes antigos; não reescrevi todos de propósito.
- **Estado final:** `test_ingles` 44, `test_ingles_modulos` 242, `test_novo_nucleo` 30, `test_novo_dados` 41, `test_novo_narrador` 13: todos passando.
## 2026-11-22 (madrugada) · Publicação da R1 e da R2.1 no main, mesclagem com a outra sessão e correção da tela Sistema

- **Publicado (autorizado pelo autor: "commit e publique"):** mesclagem `bc3a789` no `main` (R1a, R1b e R2.1 do app novo), com o site no ar em `ingles.vocealgoritmo.com.br` e o app novo em `/novo/` (prévia, `noindex`). Deploy e endereços conferidos (200), o livro segue no ar.
- **Colisão com a outra sessão, e como foi resolvida:** as duas sessões usam a mesma pasta de trabalho. A outra sessão commitou, junto com o trabalho dela, as **minhas cópias soltas** da R1a (`docs/09` e todo `site/novo/`), que estavam sem commit na pasta compartilhada, e mesclou no `main` antes de mim. Conferi que o que ela publicou era **idêntico** ao meu commit da R1a; a mesclagem então ficou com as minhas versões nesses arquivos (superconjunto: R1b e R2.1) e **juntou as entradas dos dois lados** no `CHANGELOG.md` (Degrau 0, Seções e Roteiro dela + as minhas). Nada dela foi perdido.
- **Regra nova para quem trabalha em paralelo:** trabalho meu fica **sempre commitado** em branch própria na pasta separada (`ingles-do-zero-r1`); nada solto na pasta compartilhada, para a outra sessão não varrer sem querer.
- **Testes do app de hoje no `main` puro:** DG5 (Degrau 0, da outra sessão), TC5 e L14 **oscilam sozinhos**, sem nada meu (medido: `main` puro falhou em 4 de 4 rodadas; a árvore mesclada, em 4 de 4). Não são regressão da mesclagem. Pendente: estabilizar esses testes de tempo.
- **Defeito meu, achado na conferência do que foi publicado:** abrindo o app direto em `#/sistema`, a tela mostrava "HÁ FALHAS" com 12 módulos prontos e nenhum com erro, porque a rota inicial abria **dentro da fábrica do módulo `inicio`**, que ainda estava "iniciando". Correção: `inicio` agora expõe `abrir()` e a rota só abre **depois** do fim do boot. Novo teste **NU1b** (abre a página direto em `#/sistema` e confere os 13 módulos prontos). O teste antigo não pegava porque navegava depois que tudo já tinha iniciado.
- **Totais agora:** app novo = **84 testes** (30 núcleo + 41 dados + 13 narrador).
- **Pendente:** R2.2 (`voz-navegador.js` e `narrador.js` com `speechSynthesis` falsa); estabilizar DG5, TC5, L14.
## 2026-11-22 (madrugada) · Vocabulário com função própria e Configurações autoexplicativas

- **Pedido do autor:** não entendia a função da aba Vocabulário; Configurações deveria ter só o que faz sentido e se explicar sozinha.
- **Vocabulário** (`ingles-palavras.js`, `ingles.css`): a aba era só um contador vazio (palavras só entravam tocando num livro aberto). Agora é o **caderno de palavras**: texto "como funciona", contadores novas/aprendendo/dominadas, **Adicionar uma palavra** à mão (significado e frase opcionais; sem significado o tradutor preenche), **palavras do livro da semana** para salvar uma a uma ou todas (a frase vem do próprio livro), lista com busca, revisão e exportação como antes. IDs antigos (`lb-vocab-sum`, `lb-vocab-review`) preservados.
- **Configurações** (`ingles-abas.js`): frase de abertura ("ajustes opcionais, o site funciona sem mexer"), explicação de "para que serve" em Tradução e Voz; o texto técnico longo foi absorvido pela explicação da tradução. Conta, backup e voz neural já tinham texto próprio. Subtítulos das abas sem jargão ("o que não está no menu superior" saiu).
- **Testes:** A16 a A20 em `test_ingles_modulos.ps1` passam. Observação: a bateria tem falhas **intermitentes** (TC5, DG3, DG5, B7, SY7…) que também aparecem sem estas mudanças; não investigadas.
- **Não publicado** (regra do autor).
## 2026-11-22 (noite) · Degrau 0: primeiras histórias (primeiro conteúdo para iniciante)

- **Pedido do autor:** nível iniciante; objetivo de 3 meses = ler, escrever, falar e ouvir em inglês; ~1 h por dia; IA local do Chrome adiada. Primeira versão = Degrau 0 como seção própria da Biblioteca, uma história por dia.
- **Conteúdo:** `site/assets/livros/degrau0-primeiras-historias.txt`, 6 fábulas (~750 palavras, frases curtas, presente e passado simples). Enredos de Esopo (domínio público); **texto reescrito por IA (Claude) como adaptação própria, declarado no `LEIAME.md` da pasta e pendente de revisão do autor** (regra 6, Q8).
- **Código:** novo módulo `site/assets/js/ingles-degrau0.js` (não altera `ingles-semana.js`), carregado em `ingles.html` logo após o Livro da semana. Mostra a seção acima do Livro da semana: 4 passos (ler com tradução, ouvir devagar, shadowing, salvar palavras), contador "N de 6", história de hoje destacada. Cada história vira um documento próprio ("First Stories · N. Título", `meta.x.degrau0 = N`); lida = posição no último parágrafo. PT/EN. Sem recurso opcional obrigatório (só `DDLab`).
- **Testes:** seção DG (6 verificações) em `test_ingles_modulos.ps1`; as três baterias (`test_ingles_modulos` 252, `test_ingles`, `test_novo_nucleo`) dão "tudo certo". Achado: `L13b` pegava o primeiro `.lb-rot-count` da página; a contagem do Degrau 0 usa classe própria (`lb-dg-count`).
- **Pendente:** revisão do autor dos 6 textos; ampliar o degrau 0 (mais histórias, ditado e cartões ligados a cada uma); teste em celular e em largura estreita (regra de plataformas); documentar no `06-biblioteca-modulos.md` e na matriz `08`. Não commitado nem publicado (branch `feature/abas-biblioteca`, que já tinha alterações anteriores não commitadas).

## 2026-11-22 (noite) · Seções no menu lateral e visual organizado

Pedido do autor: separar a Biblioteca em seções, sem perder nada, **escolhidas pelo menu lateral** (não por abas dentro da página), e organizar o visual (alinhado, justificado, margens).

| Item do menu lateral | Conteúdo | Endereço |
|---|---|---|
| BIBLIOTECA | Livro da semana + Sua biblioteca (lista, busca, ordenação) | `#ingles` |
| LEITOR / SUBIR PDF | área de envio (PDF, TXT, EPUB) | `#ingles-leitor` |
| PROGRESSO | Sessão do dia + estatísticas (e Zerar estatísticas) | `#ingles-progresso` |
| VOCABULÁRIO | palavras salvas, revisão, exportar TSV/Anki | `#ingles-vocabulario` |
| CONFIGURAÇÕES | tradução no navegador, voz, voz neural, conta e nuvem, backup do progresso (o que não está no menu superior) | `#ingles-configuracoes` |
| MANUAL DA BIBLIOTECA | (em "AJUDA") | `#manual-biblioteca` |

- **Como funciona:** `sumario.js` ganhou `id` e `pane` por item; `leitor.js` (`loadPage`, `keyOf`) troca de seção sem recarregar a página (mensagem `lab-pane`; um livro aberto é fechado e a posição gravada); `ingles-abas.js` mostra a seção escolhida e troca selo, título e subtítulo. Os módulos acham a âncora da sua seção (`lb-a-week`, `lb-a-sess`, `lb-a-prog`, `lb-a-vocab`; conta e backup usam `lb-pane-cfg`). Nenhuma função foi removida.
- **Retirado:** o bloco "Colar texto" da interface (`ingles-importar.js`). O núcleo ainda tem `DDLab.addText` (Livro da semana, testes) e o EPUB continua aceito. O "colar" do backup do progresso é outra coisa e continua.
- **Visual (`ingles.css`, bloco final):** todos os blocos usam a largura inteira da coluna (textos sem limite de caracteres, para o justificado/esquerda do painel Aa alinhar com cartões e botões), mesmo acabamento de cartão (borda, raio, respiro), títulos no mesmo ritmo, botões e campos com 44 px e grupos de botões alinhados em linha (à esquerda; nas listas, à direita; no celular distribuídos na largura).
- **Roteiro de 8 semanas (redesenho):** cada semana é uma linha em grade (marcador redondo com o número, ✓ preenchido quando lida, anel quando em andamento), título que quebra sem estourar, selo "✓ LIDO" / "EM ANDAMENTO" ao lado do tamanho, botões alinhados à direita (no celular, abaixo, com a largura toda), resumo "N de 8 semanas concluídas" com faixa de 8 segmentos e título sem a barra do tema Papel. Teste L13b (inclui a conferência de que nenhuma linha estoura a largura). Publicado em 2026-11-22 com autorização do autor.
- Manual da Biblioteca atualizado (PT/EN). Testes: seção AB (9 verificações) e F5 em `test_ingles_modulos.ps1`; 1a/1b em `test_ingles.ps1`. `TC5` (tempo do teleprompter) falha também sem estas mudanças; é anterior.
- Publicado em `main` (2026-11-22), com autorização do autor.

## 2026-11-22 (madrugada) · R2 · Narrador: desenho aprovado e R2.1 feita

- **Mapa:** a narração do `ingles.js` (linhas 663–949, ~290) mistura quatro responsabilidades: motor de voz e tempo, laço de reprodução, marcação na tela (DOM) e tradução. Só as duas primeiras são o Narrador; a marcação é do Leitor; a tradução vira serviço atrás de uma interface (`Fonte`). 10 comportamentos a preservar listados em `docs/10-r2-narrador.md`.
- **Decisões do autor:** desenho aprovado; velocidade aprendida por voz só **depois da paridade**; **voz neural (Piper) portada já na R2.3**; **Narrador primeiro, Leitor depois**.
- **R2.1 feita:** `site/novo/assets/js/narrador/ritmo.js` e `vozes.js` (puros) + `site/tools/test_novo_narrador.ps1` com **13 verificações, todas passando**. Cada peça foi comparada com uma **cópia literal do código antigo** em 300 a 600 entradas aleatórias: **0 diferenças**. Sincronia por estimativa simulada (cenários do `test_sync.ps1`): erro médio **0,35 a 0,73 palavra** (limite 1,5), nunca volta atrás, chega ao fim da frase.
- **Tempo simulado:** os testes do Narrador não usam fala nem relógio reais, então **não sofrem da instabilidade por carga da máquina** dos testes de hoje.
- **Totais:** app novo = **83 testes** (29 núcleo + 41 dados + 13 narrador). Núcleo agora com 13 módulos.
- **Pendente:** R2.2 (`voz-navegador.js` e `narrador.js` com `speechSynthesis` falsa); autorização para commit.
## 2026-11-22 (madrugada) · R1b: dados do aluno no app novo (R1 concluída)

- **Autorização do autor:** seguir para a R1b (backup, sincronização e gravação à prova de fechamento), trabalhando na pasta separada `ingles-do-zero-r1` para não colidir com a outra sessão.
- **Feito:** `mescla.js`, `dados.js`, `registro.js`, `nuvem.js`, `telas-dados.js` (rota `#/dados`) em `site/novo/`; eventos do estudo e da nuvem declarados; `armazem.ls` ganhou `getRaw/setRaw` (o código do aparelho do app de hoje é texto puro). `test_novo_dados.ps1` com **41 verificações, todas passando**; `test_novo_nucleo.ps1` segue "tudo certo" (agora com 11 módulos).
- **Paridade provada, não suposta:** o teste carrega o app de hoje numa moldura e compara: a **mescla** (8 casos + **300 pares aleatórios**, byte a byte), o **snapshot** e o **backup nos dois sentidos** (arquivo do novo carregado no de hoje e vice-versa restauram exatamente o mesmo progresso). Backup, sessão e dados são compartilhados entre os dois apps enquanto convivem.
- **Melhoria sobre o app de hoje:** o registro de estudo **lê o storage antes de gravar e soma o pendente**, então uma mescla (backup ou nuvem) feita no meio nunca é sobrescrita por um valor antigo da memória.
- **Matriz de paridade:** BK 11/11, SY 10/10 e S 2/2 passam no app novo (23 de 279). N1/N2 ficam com a infraestrutura pronta (integra ao Leitor na R2); N3–N6 são do painel Progresso (R3).
- **Aviso, testes do app de hoje:** `test_ingles_modulos.ps1` (TC5, L7, L14) oscila conforme a carga da máquina. Medi **igual com e sem a pasta `novo/`** (9 falhas em 12 sem, 6 em 12 com); passam quando a máquina está sossegada. Rodar sozinho antes de suspeitar do código.
- **Correção de contagem:** o núcleo (R1a) tem **29** verificações (não 32); com as 41 de dados, o app novo tem **70** testes (não 73).`n- **Pendente:** autorização para publicar (o `/novo/` só vai ao ar com o merge em `main`); próxima fase **R2 (Motores: Leitor e Narrador)**.
## 2026-11-22 (madrugada) · R1a: núcleo do app novo

- **Autorização do autor:** começar a R1. Escopo desta etapa (R1a): registro de módulos, eventos, armazém com migração e cópia de segurança, preferências, rotas e moldura do app; **R1b** (backup, sincronização, gravação à prova de fechamento) fica para depois, porque exige portar e testar a mescla contra a do app de hoje.
- **Feito:** `site/novo/` (prévia, `noindex`) com `app.js`, `eventos.js`, `armazem.js`, `config.js`, `rotas.js`, `telas.js`, `inicio.js`, moldura e tela técnica `#/sistema`; teste `site/tools/test_novo_nucleo.ps1` com **29 verificações, todas passando** (a primeira versão deste registro e o texto do commit `1ac2cc3` diziam 32 por engano; o certo é 29). As baterias antigas (módulos e núcleo/PDF) continuam "tudo certo". Nenhum arquivo do app de hoje foi alterado. Documento vivo: `docs/09-nucleo-novo.md`.
- **Descoberta crítica (registrada em `07`, seção 7, e `09`, seção 4):** o app de hoje abre `dd-ingles` **fixo na versão 2**; subir a versão no núcleo novo **quebraria o site atual**. Regra: o banco antigo **não é migrado** enquanto os dois apps coexistirem; o app novo usa o mesmo banco sem mudar a versão e guarda o novo em `dd-ingles-novo` (esse sim com migração e cópia automática). Teste `NU6c` garante que o app antigo ainda abre o banco depois do núcleo novo.
- **Aprendizado de teste:** o Chrome headless usa tempo virtual; esperar o IndexedDB sem um timer ativo faz a página parar, e um `open` pode gastar ~100 s virtuais. O teste usa batimento de timer, prazos generosos e orçamento maior (detalhe em `09`, seção 8).
- **Pendente:** R1b; autorização para commit e para publicar (o `/novo/` só vai ao ar com o merge em `main`).

## 2026-11-22 (madrugada) · Desenho da reconstrução (imersão em livros)

- **Pedido do autor:** desenhar o site como **imersão em livros** (ler, ouvir, falar, escrever, entender contextos), não como escola tradicional; reformular o que existe, **cortando o excesso e mantendo o útil**; segurança/duas etapas **adiadas**.
- **Feito:** `docs/07-desenho-reconstrucao.md` (documento-mãe): tese do produto, método (ciclo do livro), jornada (sessão do dia, escada de leitura em 6 degraus), arquitetura em camadas, modelo de dados, contratos entre módulos, telas, inventário manter/fundir/cortar/criar, protocolo "nenhuma função perdida", roadmap R0–R8, riscos e 9 perguntas.
- **Achado:** o plano antigo (`02`, `03`, `04`) era lição-por-nível (escola tradicional) e contradizia o que já funciona (livros). `02`, `03` e `04` receberam aviso de substituição. O roteiro de 8 livros cobre bem os degraus 3–5; **faltam os degraus 0–2** ("do zero"): o maior trabalho de conteúdo.
- **Decisões do autor (Q1–Q4):** falar = shadowing + gravar-se local; conversa = roteiro + retorno por regras; zero = adaptações de domínio público como ponte; reconstrução ao lado, módulo a módulo. Registradas na seção 11 do `07`.`n- **R0 feita:** `docs/08-paridade.md` (matriz de paridade) gerada dos testes atuais: **279 verificações em 39 áreas** (44 do núcleo + 235 dos módulos), cada uma com destino no app novo e fase; mais um quadro de 23 funções de hoje → onde ficam. Hoje todas passam no site atual e estão `[ ]` no app novo. Desenho e R0 commitados na branch `feature/desenho-reconstrucao` (commit `44f1938` + R0).`n- **Pendente:** perguntas Q5–Q8 do `07` (áudio, nome/domínio, sustento, quanto revisar); começar a **R1 (núcleo novo)** com autorização do autor.
## 2026-11-22 (noite) · Backup do progresso (exportar e importar)

- **Decisão do autor:** migrar o progresso do livro para o site novo por **arquivo** (baixar no livro, carregar no site novo).
- **Feito:** bloco "Backup do progresso (arquivo)" na Biblioteca (`ingles-sync.js`): baixar, carregar arquivo e colar texto; reaproveita `snapshot`/`merge`/`apply` da nuvem (nunca apaga, não duplica); livros que ainda não estão no aparelho ficam pendentes (`dd-ingles-pend-docs`) e abrem na posição certa quando entram. Detalhes e limites em `06-biblioteca-modulos.md`.
- **Testes:** seção BK (11 verificações) em `test_ingles_modulos.ps1`; passam no site novo e no livro; o restante das suítes continua "tudo certo".
- **Mesmo código nos dois projetos:** `ingles-sync.js` idêntico no livro (para baixar) e no site (para carregar). O livro só recebeu esta mudança.
- **Aprendizado de teste:** o Chrome headless com `--virtual-time-budget` adianta o relógio quando está parado; esperas curtas (`wait`/`until` de poucos segundos) estouram antes de o IndexedDB responder. Esperar pelo **resultado** (`until` com prazo longo).
- **Aprendizado de PowerShell:** `R` é alias de `Invoke-History`; não nomear funções auxiliares com 1-2 letras (`r`, `rd`, `sc`...).
- **Publicado e conferido no ar (22/11, 21h30 BRT):** `ingles-do-zero` (`54e3ee1`) e `voce.algoritmo` (`8887a3b`). Os dois endereços servem o novo `ingles-sync.js` e o manual atualizado, e o Chrome mostra o bloco com Baixar progresso, Carregar progresso e Colar texto em ambos.
- **Pendente:** teste manual do ciclo completo pelo autor (baixar no livro, carregar no site novo); trocar a aba do livro por link (com aviso para baixar o progresso antes).

## 2026-11-22 (noite) · Site de inglês no ar

- **Publicado:** https://ingles.vocealgoritmo.com.br/ (GitHub Pages, fluxo `.github/workflows/static.yml`, publica só `site/`). Merge `713396f` em `main`. O primeiro disparo (push) falhou porque o Pages ainda não estava ligado; ligado o Pages (`build_type=workflow`, domínio `ingles.vocealgoritmo.com.br`) e rodado o fluxo de novo: build e deploy com sucesso.
- **DNS/HTTPS:** CNAME criado pelo autor no Registro.br e propagado; certificado aprovado; HTTPS obrigatório (301 de http para https).
- **Conferido no ar:** páginas, scripts, fontes, Piper e livros respondem 200; Chrome headless renderiza a casca com o menu (Biblioteca, Manual); o livro (`vocealgoritmo.com.br`) segue 200; CORS do Supabase aceita a nova origem.
- **Aprendizado:** o primeiro push em `main` sempre falha se o Pages não estiver ligado antes; ligar o Pages **antes** do merge nos próximos projetos.
- **Pendente:** login por código digitado no navegador no endereço novo; migração do progresso local (origens diferentes); trocar a aba do livro por link e arquivar o código de inglês de lá.
## 2026-11-22 · Separação do livro e do site de inglês

- **Decisão do autor:** dois projetos independentes, cada um em sua página; o inglês será reconstruído. Endereço: subdomínio `ingles.vocealgoritmo.com.br`. A aba de inglês do livro vira link, **depois** do site novo estar no ar. Ver `05-separacao-do-livro.md`.
- **Feito (local, na branch `feature/separacao-site`, nada publicado):**
  - `site/`: todo o aplicativo de inglês do livro copiado (58 arquivos), incluindo a melhoria ainda não publicada que mostra na tela o motivo técnico da falha de envio do código.
  - Casca própria (`site/index.html`, `leitor.js`, `sumario.js`) sem capítulos, ANT/PRÓX, Raio-X e estatísticas do livro; todas as funções da Biblioteca mantidas.
  - `supabase/`: esquema e passo a passo copiados.
  - Testes adaptados e **passando**: `site/tools/test_ingles_modulos.ps1` e `site/tools/test_ingles.ps1`.
  - Documentação: `docs/05-separacao-do-livro.md`, `docs/06-biblioteca-modulos.md`, `CLAUDE.md`, `README.md`.
- **Supabase conferido de ponta a ponta (22/11, 23:5x):** projeto `hsesqfvggpazutmkdqto` no ar; sem login, `progress` bloqueada (401). Com a senha de app do Gmail trocada, o envio do código funcionou (HTTP 200, e-mail chegou com o assunto "Seu código de acesso"); o código foi aceito (`/auth/v1/verify` 200, conta confirmada). Logado: leitura da própria linha 200 (já existia uma linha de `progress`, gravada por um aparelho do autor); gravar linha de outra pessoa **bloqueado** (403, RLS); ler linha de outra pessoa volta vazio. Nenhum dado foi gravado no teste.
- **Preparação da publicação (22/11):** autor mandou tornar o repositório público e fazer o commit. Varredura de segredos limpa. Criados `.github/workflows/static.yml` (publica só `site/`) e `site/CNAME`. Pages desligado até autorização do merge em `main`. DNS no Registro.br: ver `docs/05`, seção 7.`n- **Pendente:** merge em `main`/Pages, visibilidade do repositório e Pages, DNS, repetir o login no endereço novo, migração do progresso local, troca da aba no livro.
- **Como conferir:** `cd site; pwsh tools\test_ingles_modulos.ps1` e `pwsh tools\test_ingles.ps1` (precisam do Chrome; saem com "tudo certo").
