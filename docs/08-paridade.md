# 08 · Matriz de paridade (fase R0)

> **Para que serve:** garantir que **nenhuma função se perde** na reconstrução (`07-desenho-reconstrucao.md`, seção 7). Cada verificação dos testes de hoje é um **contrato**: o app novo só vira o principal quando todas passarem nele (adaptando seletores, **nunca enfraquecendo** a verificação).
> **Gerada em 2026-11-22** a partir de `site/tools/test_ingles.ps1` (núcleo) e `site/tools/test_ingles_modulos.ps1` (módulos): **279 verificações** em **39 áreas**. Quando um teste for criado, alterado ou removido, atualizar esta matriz e o `CHANGELOG.md`.
> **Status:** `[ ]` = ainda não verificada no app novo · `[x]` = passa no app novo (data) · `[~]` = substituída por decisão do autor (explicar). Em 22/11/2026 (fim da R1b): **BK 11/11, SY 10/10 e S 2/2 já passam no app novo** (23 de 279); o restante segue `[ ]`. As 279 passam no site atual.

## 1. Funções de hoje → onde ficam no app novo

| # | Função (o que o aluno vê/faz) | Arquivo hoje | Áreas de teste | Destino no app novo | Fase |
|---|---|---|---|---|---|
| 1 | Importar PDF, EPUB e texto colado | `ingles.js`, `ingles-importar.js` | c0 c2 c3 F | Estante (importador) | R3 |
| 2 | Dividir em frases/versos, marcar 4 camadas (parágrafo, linha, frase, palavra) | `ingles.js` | c4 R W | Motor Leitor | R2 |
| 3 | Tradução por frase (tradutor local) e paridade de frases PT/EN | `ingles.js` | c4 J | Serviço Tradutor (catálogo primeiro, tradutor local para textos do aluno) | R2 |
| 4 | Narração por frase, buffer à frente, retomar da palavra, velocidade 0,1–3× | `ingles.js` | c5 c6 V X Y Z | Motor Narrador + serviço Voz | R2 |
| 5 | Voz neural local opcional (Piper) | `ingles-voz.js`, `assets/vendor/piper` | G | Serviço Voz (opcional) | R2 |
| 6 | Alinhar palavra falada ↔ mostrada entre idiomas (laborious diligence) | `ingles-alinhar.js` | AL | Serviço do Narrador | R2 |
| 7 | Setas ← → palavra a palavra (Shift = frase), F11, Esc | `ingles-explorar.js`, casca | AR EX | Atalhos do Leitor/Narrador | R2 |
| 8 | Modos de leitura: coluna única, larga, lado a lado, foco com painel | `ingles-modos.js` | U P W I | Leitura (4 modos) | R3 |
| 9 | Teleprompter (legenda corrida, imersivo) e Legenda | `ingles-teleprompter.js`, `ingles-legenda.js` | J U X Z TC | Modo de leitura (Legenda fundida ao Teleprompter) | R3 |
| 10 | Destacar palavras incomuns | `ingles-destaque.js` | H | Opção do Leitor | R3 |
| 11 | Toque na palavra, significado, pronúncia, salvar | `ingles-palavras.js` | A | Palavras | R3 |
| 12 | Revisão espaçada (SM-2 enxuto), exportar para Anki | `ingles-palavras.js` | A | Palavras (evolui para cloze da frase) | R3–R4 |
| 13 | Nível de dificuldade do texto | `ingles-nivel.js` | B | Catálogo/Estante (faixas por degrau) | R5 |
| 14 | Treino: repetir, shadowing, ditado | `ingles-treino.js` | C | Atividades (+ gravação local no shadowing) | R4 |
| 15 | Perguntas de compreensão (modelo local do Chrome) | `ingles-compreensao.js` | D | Atividades (perguntas do catálogo; modelo local opcional) | R4–R5 |
| 16 | Sessão do dia (50 min, 4 blocos) | `ingles-dia.js` | O | Planejador / tela Hoje | R3–R4 |
| 17 | Livro da semana, roteiro de 8 livros, fechamento da semana | `ingles-semana.js`, `assets/livros/` | L Q | Planejador + Catálogo | R4–R5 |
| 18 | Painel de progresso (sequência, minutos, palavras, gráfico 7 dias), zerar estatísticas | `ingles-progresso.js` | E S N | Progresso + Núcleo | R1–R3 |
| 19 | Gravação à prova de fechamento da aba (espelho em localStorage) | `ingles.js` | N S | Núcleo (Armazém) | R1 |
| 20 | Conta e sincronização (Supabase, login por código) | `ingles-sync.js`, `sync-config.js`, `supabase/` | SY | Núcleo (sincronização) | R1 |
| 21 | Backup do progresso em arquivo (baixar, carregar, colar) | `ingles-sync.js` | BK | Núcleo (sincronização e backup) | R1 |
| 22 | Casca: tema, fonte, margens, alinhamento, voz, idiomas LER/OUVIR, barra de andamento | `index.html`, `leitor.js`, `sumario.js` | c1 I T V | Interface (app de página única) | R3 |
| 23 | Manual da Biblioteca (PT/EN) | `manual-biblioteca.html/js` | M | Ajuda dentro do app | R8 |

> Códigos de "Áreas de teste" (`c0`–`c7`, `A`, `AL`…) estão na seção 2. Funções **novas** do desenho (notas de contexto, discussão, gravação de voz, degraus 0–2, offline) ainda não têm teste; ganham a sua seção quando forem construídas (fases R4–R7).

## 2. Resumo por área de teste

| Área | O que cobre | Verificações | Destino no app novo | Fase | Passam no novo |
|---|---|---|---|---|---|
| `c0` | Núcleo · texto colado vira documento | 1 | Estante (importador) | R3 | 0/1 |
| `c1` | Núcleo · menu do site | 5 | Interface (rotas e menu do app de página única) | R3 | 0/5 |
| `c2` | Núcleo · limpeza do texto importado | 7 | Motor Leitor (importação e limpeza) | R2 | 0/7 |
| `c3` | Núcleo · importar PDF | 7 | Estante (importador) | R3 | 0/7 |
| `c4` | Núcleo · LER em PT (tradução por frase, paridade) | 4 | Motor Leitor + serviço Tradutor | R2 | 0/4 |
| `c5` | Núcleo · OUVIR em PT | 9 | Motor Narrador + serviço Voz | R2 | 0/9 |
| `c6` | Núcleo · trocar idioma do áudio no meio da fala | 3 | Motor Narrador | R2 | 0/3 |
| `c7` | Núcleo · biblioteca (salvar, reabrir, buscar) | 6 | Estante + Armazém | R3 | 0/6 |
| `M` | Manual da Biblioteca | 10 | Ajuda dentro do app (mesmo texto PT/EN) | R8 | 0/10 |
| `V` | Velocidade 0,1–3× e marcação da estrofe | 10 | Interface + Motor Narrador | R2 | 0/10 |
| `A` | Toque na palavra e vocabulário (repetição espaçada) | 15 | Palavras (cartões; evolui para cloze da frase) | R3–R4 | 0/15 |
| `AL` | Alinhamento de palavras entre idiomas | 5 | Serviço do Narrador | R2 | 0/5 |
| `AR` | Setas e velocidade no teleprompter | 5 | Leitor/Narrador (atalhos) | R2 | 0/5 |
| `B` | Nível de dificuldade do texto | 7 | Catálogo/Estante (faixas por degrau) | R5 | 0/7 |
| `BK` | Backup do progresso em arquivo | 11 | Núcleo (sincronização e backup) | R1 | **11/11** |
| `C` | Treino: repetir, shadowing, ditado | 9 | Atividades (shadowing ganha gravação local) | R4 | 0/9 |
| `D` | Perguntas de compreensão (modelo local) | 5 | Atividades (troca por perguntas do catálogo; local vira extra) | R4–R5 | 0/5 |
| `E` | Painel de progresso (dias, minutos, palavras) | 6 | Progresso | R3 | 0/6 |
| `EX` | Setas palavra a palavra | 7 | Motor Leitor (atalho) | R2 | 0/7 |
| `F` | Importar EPUB e texto colado | 6 | Estante (importador) | R3 | 0/6 |
| `G` | Voz neural local (Piper) | 11 | Serviço Voz (opcional) | R2 | 0/11 |
| `H` | Destacar palavras incomuns | 6 | Opção do Leitor | R3 | 0/6 |
| `I` | Controles de estudo e painéis Aa/Voz no cabeçalho | 6 | Interface | R3 | 0/6 |
| `J` | Legenda | 17 | Modo de leitura (fundida ao Teleprompter) | R3 | 0/17 |
| `L` | Livro da semana (roteiro de 8 livros) | 16 | Planejador | R4 | 0/16 |
| `N` | Posição e palavras gravadas ao fechar a aba | 7 | Núcleo (Armazém) | R1 | 0/7 (infra pronta: N1 e N2 faltam integrar ao Leitor, R2; N3–N6 são do painel Progresso, R3) |
| `O` | Sessão do dia (50 min, 4 blocos) | 13 | Planejador / tela Hoje | R3–R4 | 0/13 |
| `P` | Modo foco com painel (AGORA, PROGRESSO, HOJE) | 8 | Leitura + componente de andamento unificado | R3–R4 | 0/8 |
| `Q` | Fechamento da semana | 8 | Planejador | R4 | 0/8 |
| `R` | Posição estável quando o layout muda | 6 | Motor Leitor | R2 | 0/6 |
| `S` | Estatísticas gravadas na hora | 2 | Núcleo (Armazém) | R1 | **2/2** |
| `SY` | Conta e sincronização (Supabase) | 10 | Núcleo (sincronização e backup) | R1 | **10/10** |
| `T` | Botões do site (Teleprompter, Raio-X) | 4 | Interface | R3 | 0/4 |
| `TC` | Painel de andamento do teleprompter | 6 | Componente de andamento unificado | R4 | 0/6 |
| `U` | Seletor de modos e teleprompter | 10 | Leitura (4 modos) | R3 | 0/10 |
| `W` | 4 temas × 4 modos: destaque visível | 1 | Leitura | R3 | 0/1 |
| `X` | Combinações ler × ouvir (PT/EN) | 2 | Motor Narrador | R2 | 0/2 |
| `Y` | Velocidade no meio da frase | 3 | Motor Narrador | R2 | 0/3 |
| `Z` | Centragem, fila sem lacuna, deslize contínuo | 5 | Motor Narrador + Teleprompter | R2 | 0/5 |

## 3. Todas as verificações (o contrato)

Arquivo: **N** = `test_ingles.ps1` (núcleo), **M** = `test_ingles_modulos.ps1` (módulos). Texto resumido; o completo está no teste.

### `c0` · Núcleo · texto colado vira documento → Estante (importador) (R3)

- [ ] `0` (M) texto colado vira documento

### `c1` · Núcleo · menu do site → Interface (rotas e menu do app de página única) (R3)

- [ ] `1a` (N) seção ESTUDO DE INGLÊS é a última do menu
- [ ] `1b` (N) o menu tem só a Biblioteca e o Manual (o site de inglês não tem capítulos de livro)
- [ ] `1c` (N) a Biblioteca abre sozinha ao entrar no site
- [ ] `1d` (N) abre a página no quadro
- [ ] `1e` (N) barra inferior de capítulo escondida

### `c2` · Núcleo · limpeza do texto importado → Motor Leitor (importação e limpeza) (R2)

- [ ] `2a` (N) cabeçalho repetido removido
- [ ] `2b` (N) número de página removido
- [ ] `2c` (N) hifenização juntada
- [ ] `2d` (N) título vira h
- [ ] `2e` (N) frase partida entre páginas é reunida
- [ ] `2f` (N) frases separadas
- [ ] `2g` (N) idioma detectado

### `c3` · Núcleo · importar PDF → Estante (importador) (R3)

- [ ] `3a` (N) PDF importado e aberto
- [ ] `3b` (N) idioma original = EN
- [ ] `3c` (N) texto extraído
- [ ] `3d` (N) cabeçalho "Test Journal" do PDF não entrou
- [ ] `3e` (N) títulos detectados
- [ ] `3f` (N) frases separadas
- [ ] `3g` (N) tela em EN mostra o original

### `c4` · Núcleo · LER em PT (tradução por frase, paridade) → Motor Leitor + serviço Tradutor (R2)

- [ ] `4a` (N) parágrafos próximos traduzidos
- [ ] `4b` (N) paridade de frases em todos os parágrafos traduzidos
- [ ] `4c` (N) tela mostra a tradução, frase a frase
- [ ] `4d` (N) "traduzir tudo" completa o documento

### `c5` · Núcleo · OUVIR em PT → Motor Narrador + serviço Voz (R2)

- [ ] `5a` (N) narração em PT fala a tradução, com voz pt-BR
- [ ] `5b` (N) a primeira frase falada é a primeira do documento
- [ ] `5c` (N) a frase falada fica destacada
- [ ] `5d` (N) a palavra falada fica marcada (camada de palavra)
- [ ] `5e` (N) a faixa da linha acompanha a palavra
- [ ] `5f` (N) o parágrafo falado fica marcado
- [ ] `5g` (N) barra inferior: total de páginas e avanço
- [ ] `5h` (N) barra inferior mostra palavras lidas / total
- [ ] `5i` (N) barra superior mostra página e %

### `c6` · Núcleo · trocar idioma do áudio no meio da fala → Motor Narrador (R2)

- [ ] `6a` (N) trocar para EN fala em en-US, sem prefixo de tradução
- [ ] `6b` (N) retoma a mesma frase (paridade), no outro idioma
- [ ] `6c` (N) segundo toque para a narração

### `c7` · Núcleo · biblioteca (salvar, reabrir, buscar) → Estante + Armazém (R3)

- [ ] `7a` (N) documento aparece na biblioteca
- [ ] `7b` (N) mostra 100% traduzido
- [ ] `7b1` (N) biblioteca agrupa por situação de leitura
- [ ] `7b2` (N) busca sem resultado esconde os documentos
- [ ] `7b3` (N) limpar a busca traz o documento de volta
- [ ] `7c` (N) reabrir recupera as traduções salvas

### `M` · Manual da Biblioteca → Ajuda dentro do app (mesmo texto PT/EN) (R8)

- [ ] `M1` (N) o Manual da Biblioteca abre pelo menu em português (10 seções) e troca para inglês com o idioma de leitura
- [ ] `M1` (M) um seletor reúne os 4 modos de leitura, começa em coluna única e o corpo não tem classe de modo
- [ ] `M2` (M) cabeçalho simétrico: voltar encosta na esquerda, o modo na direita e a barra de estudo ocupa a largura toda
- [ ] `M3` (M) coluna larga: o cartão de leitura fica mais largo e a escolha é guardada
- [ ] `M4` (M) lado a lado: original à esquerda com frases clicáveis, tradução à direita e rótulos das colunas
- [ ] `M5` (M) as duas colunas ficam lado a lado, na mesma altura
- [ ] `M6` (M) voltar à biblioteca devolve a largura normal e reabrir o livro mantém o modo escolhido
- [ ] `M7` (M) reabrir mantém lado a lado e o seletor mostra o modo
- [ ] `M8` (M) foco com painel: menu do site recolhido, texto em coluna única e painel ao lado com hoje, livro e palavras
- [ ] `M9` (M) sair do modo foco reabre o menu do site e esconde o painel

### `V` · Velocidade 0,1–3× e marcação da estrofe → Interface + Motor Narrador (R2)

- [ ] `V1` (N) o menu de velocidade do site vai de 0,1 a 3 em passos de 0,1 (30 opções)
- [ ] `V2` (N) F11 liga a tela inteira no site e também quando apertado dentro da página (Biblioteca)
- [ ] `V1` (M) poema: cada estrofe vira um bloco de versos com uma linha por unidade
- [ ] `V2` (M) prosa quebrada em colunas e diálogo curto continuam sendo prosa, não verso
- [ ] `V3` (M) na tela, 3 estrofes e cada verso numa linha própria
- [ ] `V4` (M) durante a narração: só a estrofe falada fica marcada, só a linha falada (o 2º verso) e uma palavra dessa linha
- [ ] `V5` (M) a palavra destacada avança dentro da linha, em sincronia com a voz
- [ ] `V6` (M) terminada uma linha, a marca passa para o verso seguinte (3º) na mesma estrofe
- [ ] `V7` (M) acabando o último verso da estrofe, a marca de estrofe passa para a seguinte
- [ ] `V8` (M) a estrofe falada ganha a barra de destaque mais forte que as demais

### `A` · Toque na palavra e vocabulário (repetição espaçada) → Palavras (cartões; evolui para cloze da frase) (R3–R4)

- [ ] `A1` (M) tocar numa palavra abre o cartão
- [ ] `A2` (M) tocar na palavra não inicia a narração
- [ ] `A3` (M) mostra a tradução da palavra
- [ ] `A4` (M) mostra a frase de contexto
- [ ] `A5` (M) pronuncia a palavra em inglês
- [ ] `A6` (M) salvar grava o cartão
- [ ] `A7` (M) segunda palavra salva
- [ ] `A8` (M) Esc fecha o cartão
- [ ] `A9` (M) intervalos crescem: 1d → 3d → ~8d
- [ ] `A10` (M) errar zera o avanço e volta em minutos
- [ ] `A11` (M) biblioteca mostra o resumo do vocabulário
- [ ] `A12` (M) revisão abre com o cartão da palavra
- [ ] `A13` (M) terminar a revisão mostra a conclusão
- [ ] `A14` (M) cartões revisados ficam para depois
- [ ] `A15` (M) sair da revisão fecha a tela

### `AL` · Alinhamento de palavras entre idiomas → Serviço do Narrador (R2)

- [ ] `AL1` (M) EN falado, PT na tela: "laborious" cai em "laboriosa" e "diligence" em "diligência" (adjetivo e substantivo trocados)
- [ ] `AL2` (M) PT falado, EN na tela: "diligência" cai em "diligence" e "laboriosa" em "laborious"
- [ ] `AL3` (M) o resto da frase segue em ordem (sem saltos para trás além da troca das vizinhas)
- [ ] `AL4` (M) no teleprompter, quando a voz diz "laborious" acende "laboriosa", em "diligence" acende "diligência" e em "merchant" acende "comerciante"
- [ ] `AL5` (M) palavras sem parentesco de grafia: com a tradução da palavra solta, big cai em grande e house em casa

### `AR` · Setas e velocidade no teleprompter → Leitor/Narrador (atalhos) (R2)

- [ ] `AR1` (M) parado, seta direita avança a marca frase a frase (0:1, 0:2, 1:0) e a esquerda volta (0:2), passando de um parágrafo ao outro
- [ ] `AR2` (M) a frase marcada fica destacada no texto e o ▶ continua dali
- [ ] `AR3` (M) as setas não interferem quando o foco está num campo de escolha ou de digitação
- [ ] `AR4` (M) com a narração tocando, seta direita pula para a próxima frase e a voz segue dela; seta esquerda volta à anterior
- [ ] `AR5` (M) velocidade de 0,1 em 0,1 de 0,1x a 3x: + e − do teleprompter andam um décimo (1 -> 1,5 -> 1,4), param em 3 e em 0,1, e a legenda lista 30 valores

### `B` · Nível de dificuldade do texto → Catálogo/Estante (faixas por degrau) (R5)

- [ ] `B1` (M) texto simples sai como Fácil
- [ ] `B2` (M) texto acadêmico sai como Difícil ou pior
- [ ] `B3` (M) lista reconhece flexões e rejeita palavras raras
- [ ] `B4` (M) português não recebe nível
- [ ] `B5` (M) o documento aberto mostra a dificuldade
- [ ] `B6` (M) o nível fica gravado no documento
- [ ] `B7` (M) a biblioteca mostra o nível no documento

### `BK` · Backup do progresso em arquivo → Núcleo (sincronização e backup) (R1)

- [x] `BK1` (M) o bloco Backup do progresso existe na Biblioteca, com baixar, carregar e colar — **app novo: NUD8a** (22/11)
- [x] `BK2` (M) exportar gera um arquivo do site (app, versão, data) com o progresso e SEM o corpo dos livros (só títulos, posição e contadores; o cartão da palavra guarda a frase de … — **app novo: NUD3a** (22/11)
- [x] `BK3` (M) importar soma sem perder nada: dia/campo = maior valor (900 fica, 50 entra), dia novo entra, cartão novo, histórico e escrita em união — **app novo: NUD3c, NUD3d** (22/11)
- [x] `BK4` (M) o que o arquivo traz de livro que ainda não está aqui fica guardado (posição e palavras ouvidas) e vai nos próximos backups — **app novo: NUD4a** (22/11)
- [x] `BK5` (M) carregar o mesmo arquivo de novo não duplica nada — **app novo: NUD3d** (22/11)
- [x] `BK6` (M) arquivo que não é backup do site é recusado e não muda nada — **app novo: NUD3e, NUD3f** (22/11)
- [x] `BK7` (M) quando o livro do backup entra na biblioteca ele já abre na posição e com as palavras ouvidas guardadas, e a pendência some — **app novo: NUD4b** (22/11)
- [x] `BK8` (M) sem suporte a download, o progresso aparece como texto para copiar (e é um backup válido) — **app novo: NUD8b** (22/11)
- [x] `BK9` (M) colar o texto de um backup e importar funciona e mostra o resumo — **app novo: NUD8c** (22/11)
- [x] `BK10` (M) texto colado que não é backup mostra aviso claro — **app novo: NUD8d** (22/11)
- [x] `BK11` (M) o backup funciona com a sincronização desligada (sem configuração, sem conta) — **app novo: NUD8d** (22/11)

### `C` · Treino: repetir, shadowing, ditado → Atividades (shadowing ganha gravação local) (R4)

- [ ] `C1` (M) ditado compara palavra a palavra (ordem, caixa e pontuação ignoradas)
- [ ] `C2` (M) repetir: a frase toca duas vezes
- [ ] `C3` (M) repetir: a segunda passada é mais lenta
- [ ] `C4` (M) voltar à velocidade normal ao parar
- [ ] `C5` (M) shadowing: pausa entre frases para repetir
- [ ] `C6` (M) ditado: abre a caixa de escrita depois da frase
- [ ] `C7` (M) ditado: mostra acertos e a palavra que faltou
- [ ] `C8` (M) ditado: continuar segue para a próxima frase
- [ ] `C9` (M) parar a narração fecha o ditado

### `D` · Perguntas de compreensão (modelo local) → Atividades (troca por perguntas do catálogo; local vira extra) (R4–R5)

- [ ] `D1` (M) sem modelo local o botão não aparece
- [ ] `D2` (M) com modelo local o botão aparece
- [ ] `D3` (M) gera 3 perguntas sobre o trecho
- [ ] `D4` (M) corrige a resposta do aluno
- [ ] `D5` (M) fechar remove o painel

### `E` · Painel de progresso (dias, minutos, palavras) → Progresso (R3)

- [ ] `E1` (M) eventos do estudo entram no registro do dia
- [ ] `E2` (M) sequência conta dias seguidos até hoje
- [ ] `E3` (M) painel mostra a sequência e os blocos do dia
- [ ] `E4` (M) gráfico dos últimos 7 dias
- [ ] `E5` (M) grava no navegador
- [ ] `E6` (M) conta o tempo de estudo com o documento aberto

### `EX` · Setas palavra a palavra → Motor Leitor (atalho) (R2)

- [ ] `EX1` (M) seta direita explora palavra a palavra com destaque principal (The, laborious, diligence) e a equivalente em português numa etiqueta de outra cor (a, laboriosa, diligê…
- [ ] `EX2` (M) seta esquerda volta uma palavra e a etiqueta acompanha
- [ ] `EX3` (M) a cor da palavra equivalente é diferente da cor da palavra principal
- [ ] `EX4` (M) passando do fim da frase a seta segue para a primeira palavra da próxima frase
- [ ] `EX5` (M) Shift + seta pula a frase inteira (continua valendo o passo por frase)
- [ ] `EX6` (M) no modo lado a lado a palavra equivalente fica marcada, em outra cor, na coluna da tradução
- [ ] `EX7` (M) no teleprompter as setas exploram palavra a palavra na linha grande e a equivalente do outro idioma acende embaixo

### `F` · Importar EPUB e texto colado → Estante (importador) (R3)

- [ ] `F1` (M) EPUB importado com o título do livro
- [ ] `F2` (M) capítulos viram títulos e o texto vira parágrafos
- [ ] `F3` (M) bloco aninhado não duplica o texto
- [ ] `F4` (M) EPUB ganha páginas estimadas para a barra inferior
- [ ] `F5` (M) texto colado vira documento com o título dado
- [ ] `F6` (M) o seletor de arquivo aceita EPUB

### `G` · Voz neural local (Piper) → Serviço Voz (opcional) (R2)

- [ ] `G1` (M) painel da voz neural lista português e inglês, desligada por padrão
- [ ] `G2` (M) baixar e ativar liga a voz neural do inglês
- [ ] `G3` (M) painel mostra "ativa"
- [ ] `G4` (M) a narração usa a voz neural (e não a do navegador)
- [ ] `G5` (M) prepara as próximas frases enquanto toca
- [ ] `G6` (M) a palavra marcada acompanha o áudio neural
- [ ] `G7` (M) ao terminar uma frase segue para a próxima
- [ ] `G8` (M) parar interrompe o áudio
- [ ] `G9` (M) palavra avulsa (cartão) também usa a voz neural
- [ ] `G10` (M) se a voz neural falhar, cai para a voz do navegador sem travar
- [ ] `G11` (M) remover apaga a voz baixada

### `H` · Destacar palavras incomuns → Opção do Leitor (R3)

- [ ] `H1` (M) botão Destacar existe e começa desligado
- [ ] `H2` (M) ligar destaca palavras incomuns
- [ ] `H3` (M) palavra comum e nome próprio no meio da frase não são destacados
- [ ] `H4` (M) lendo em português não destaca nada
- [ ] `H5` (M) voltando ao inglês o destaque volta
- [ ] `H6` (M) desligar limpa o destaque

### `I` · Controles de estudo e painéis Aa/Voz no cabeçalho → Interface (R3)

- [ ] `I1` (M) controles de estudo ficam num grupo próprio
- [ ] `I2` (M) voltar e status ficam fora do grupo de estudo
- [ ] `I3` (M) grupo de estudo tem rótulo acessível
- [ ] `I4` (M) voz da narração fica no painel Voz, não no Aa
- [ ] `I5` (M) botão Voz abre só o painel de voz
- [ ] `I6` (M) abrir Aa fecha o painel de voz

### `J` · Legenda → Modo de leitura (fundida ao Teleprompter) (R3)

- [ ] `J1` (M) botão Legenda fica no grupo Estudo e a faixa começa fechada
- [ ] `J2` (M) ligar abre a faixa com a frase da posição atual
- [ ] `J3` (M) a tradução aparece na linha de baixo
- [ ] `J4` (M) a próxima frase aparece esmaecida e não há anterior na primeira
- [ ] `J5` (M) próxima frase leva a legenda e a narração para a frase 2
- [ ] `J6` (M) a frase anterior passa a aparecer
- [ ] `J7` (M) a palavra falada fica marcada
- [ ] `J8` (M) a marca anda para a palavra seguinte
- [ ] `J9` (M) pausar para a narração e mostra ▶
- [ ] `J10` (M) ler retoma a partir da frase mostrada
- [ ] `J11` (M) A+ aumenta a letra da legenda
- [ ] `J12` (M) tocar numa palavra da legenda abre o cartão da palavra
- [ ] `J13` (M) destacar incomuns também marca palavras na legenda
- [ ] `J14` (M) fechar a legenda esconde a faixa e solta o botão
- [ ] `J15` (M) inverter troca o idioma do texto e o da legenda/áudio
- [ ] `J16` (M) inverter de novo volta ao original
- [ ] `J17` (M) traduz uma frase isolada sem esperar o parágrafo

### `L` · Livro da semana (roteiro de 8 livros) → Planejador (R4)

- [ ] `L1` (M) livro da semana: oferece os livros em inglês da biblioteca e o botão de começar
- [ ] `L2` (M) começar a semana (ainda sem ler): título, dia 1 de 7, progresso zerado, cota = livro dividido em 7 e ritmo em dia (não atrasado)
- [ ] `L3` (M) o plano fica guardado no navegador e as palavras difíceis aparecem para ver antes de ler
- [ ] `L4` (M) ler metade do livro: progresso sobe para ~50% e a cota de hoje fica cumprida
- [ ] `L5` (M) no dia 4 com pouca leitura: mostra atraso e a cota sobe para o que falta dividido pelos dias que restam
- [ ] `L6` (M) chegar ao fim do livro mostra livro concluído e a escolha do próximo
- [ ] `L7` (M) escolher o próximo livro apaga o plano e volta à seleção
- [ ] `L8` (M) as notas de rodapé no fim do livro não entram no total nem na cota
- [ ] `L9` (M) roteiro: 8 semanas com autor, título e tamanho, e um botão para começar cada uma
- [ ] `L9b` (M) os 8 arquivos do roteiro existem, são texto em inglês, cabem em 50 min por dia (até 30 mil palavras) e não trazem cabeçalho de edição
- [ ] `L10` (M) começar a semana 2 traz o livro de domínio público para a biblioteca e inicia o plano
- [ ] `L11` (M) durante o plano o roteiro fica recolhido e marca a semana atual como em andamento, sem botões de começar outra
- [ ] `L12` (M) terminar o livro registra no histórico uma única vez, mesmo renderizando de novo
- [ ] `L12b` (M) renderizar de novo não duplica o registro
- [ ] `L13` (M) depois de ler, a semana 2 aparece como lida e as outras 7 continuam disponíveis
- [ ] `L14` (M) livro concluído pode ser relido: nova semana começa do início e o histórico da anterior fica

### `N` · Posição e palavras gravadas ao fechar a aba → Núcleo (Armazém) (R1)

- [ ] `N1` (M) ao ocultar ou fechar a aba, a posição e as palavras ouvidas são gravadas na hora (espelho síncrono e banco) — infraestrutura pronta no app novo (NUD6e, NUD6h); falta integrar ao Leitor (R2)
- [ ] `N2` (M) se o banco ficou para trás (aba fechada antes de gravar), ao reabrir vale o espelho mais novo — infraestrutura pronta no app novo (NUD6e, NUD6h); falta integrar ao Leitor (R2)
- [ ] `N3` (M) o botão Zerar estatísticas aparece quando há o que zerar — painel Progresso (R3)
- [ ] `N4` (M) pede confirmação explicando o que será zerado e o que fica, e cancelar não apaga nada — painel Progresso (R3)
- [ ] `N4b` (M) cancelar volta ao botão e mantém as estatísticas
- [ ] `N5` (M) zerar apaga minutos, palavras ouvidas, contadores dos livros e histórico, e mantém posição, livros e palavras salvas — painel Progresso (R3)
- [ ] `N6` (M) depois de zerar o botão some e o painel volta ao convite inicial — painel Progresso (R3)

### `O` · Sessão do dia (50 min, 4 blocos) → Planejador / tela Hoje (R3–R4)

- [ ] `O1` (M) sem plano da semana, a sessão do dia explica que nasce do plano e não mostra blocos
- [ ] `O2` (M) com plano: 4 blocos (leitura 25, vocabulário 10, shadowing 8, escrita 7 min = 50) com metas do dia
- [ ] `O3` (M) ler a cota do dia fecha o bloco de leitura sozinho
- [ ] `O4` (M) o bloco de vocabulário usa as palavras que vencem hoje como meta e abre a revisão
- [ ] `O5` (M) cumprir as revisões fecha o bloco de vocabulário
- [ ] `O6` (M) "Marcar como feito" fecha o shadowing e fica guardado no dia
- [ ] `O7` (M) escrita curta recebe dicas (palavras, vocabulário do livro e objeção) e não é salva
- [ ] `O8` (M) escrita completa é salva, fecha o bloco e aparece em "Seus textos"
- [ ] `O9` (M) com os 4 blocos feitos: sessão concluída, dia registrado uma vez e sequência de 1 dia
- [ ] `O10` (M) renderizar de novo não duplica o registro do dia
- [ ] `O11` (M) em um novo dia o estado recomeça (marcas manuais zeradas) e o histórico fica
- [ ] `O12` (M) a sequência conta dias seguidos e ignora buracos
- [ ] `O13` (M) Zerar estatísticas apaga as sessões do dia, mas mantém os textos escritos

### `P` · Modo foco com painel (AGORA, PROGRESSO, HOJE) → Leitura + componente de andamento unificado (R3–R4)

- [ ] `P1` (M) o painel começa com AGORA (atividade e tempos) e PROGRESSO (palavras, %, sessão e próxima marca) antes de HOJE e das palavras salvas
- [ ] `P2` (M) avançar na leitura soma as palavras e a porcentagem na hora, e mostra as palavras ganhas na sessão
- [ ] `P3` (M) a próxima marca é a primeira acima da porcentagem atual e diz quantas palavras faltam
- [ ] `P4` (M) sem mexer na página por mais de 30 s nem narração, a atividade é Pausado
- [ ] `P5` (M) mexer na página muda a atividade para Lendo
- [ ] `P6` (M) lendo e ouvindo ao mesmo tempo mostra os dois, e cada tempo conta separado
- [ ] `P7` (M) ao chegar ao fim, 100% e a mensagem de livro concluído
- [ ] `P8` (M) os tempos de leitura e escuta ficam no log de estudo e aparecem no painel de progresso da biblioteca

### `Q` · Fechamento da semana → Planejador (R4)

- [ ] `Q1` (M) ao concluir o livro aparece o fechamento da semana com a revisão em 8 números reais
- [ ] `Q2` (M) o contador de palavras acompanha o texto
- [ ] `Q3` (M) resumo curto recebe dicas (palavras, vocabulário do livro e objeção) e não é salvo
- [ ] `Q4` (M) resumo completo é salvo: aparece no fechamento, vai para "Seus textos" e marca o livro como fechado no histórico
- [ ] `Q5` (M) sem o livro no roteiro, o próximo sugerido é a semana 1 e há a opção de escolher outro
- [ ] `Q6` (M) o próximo sugerido pula os livros do roteiro já lidos (semana 2 depois da 1)
- [ ] `Q7` (M) começar o próximo livro traz o texto para a biblioteca e abre o plano da semana 2
- [ ] `Q8` (M) Zerar estatísticas apaga o histórico das semanas e mantém o texto do fechamento

### `R` · Posição estável quando o layout muda → Motor Leitor (R2)

- [ ] `R1` (M) reabrir em coluna única volta ao parágrafo gravado
- [ ] `R2` (M) trocar para o modo foco (o menu recolhe e o texto reflui) mantém a posição de leitura
- [ ] `R3` (M) trocar para lado a lado também mantém a posição
- [ ] `R4` (M) a posição gravada continua a mesma depois das trocas de modo
- [ ] `R5` (M) reabrir direto no modo foco não salta para a frente
- [ ] `R6` (M) o painel não inventa palavras lidas ao reabrir (+0 nesta sessão)

### `S` · Estatísticas gravadas na hora → Núcleo (Armazém) (R1)

- [x] `S1` (M) palavras ouvidas (e salvas, revisões, ditados) são gravadas na hora, no mesmo instante do evento — **app novo: NUD6a** (22/11)
- [x] `S2` (M) os tempos (total, lendo, ouvindo) são gravados em até 2 s, sem esperar ocultar nem fechar a aba — **app novo: NUD6c** (22/11)

### `SY` · Conta e sincronização (Supabase) → Núcleo (sincronização e backup) (R1)

- [x] `SY1` (M) a tela Conta e sincronização existe na Biblioteca e, sem configuração, diz que a sincronização não está ativada (o site segue normal) — **app novo: NUD7a, NUD8a** (22/11)
- [x] `SY2` (M) mesclar não perde nada: dia/campo = maior valor, cartão = o mais revisado, listas = união, livro = posição mais recente com o maior número de palavras ouvidas — **app novo: NUD1a, NUD1b, NUD1c** (22/11)
- [x] `SY3` (M) com a configuração presente, aparece o campo de e-mail para entrar — **app novo: NUD8e** (22/11)
- [x] `SY4` (M) enviar o código chama o login por código e abre o campo do código — **app novo: NUD7d, NUD8e** (22/11)
- [x] `SY4b` (M) quando o envio do código falha, a tela mostra o motivo técnico (ex.: 500: Error sending magic link email) para achar o problema — **app novo: NUD7c** (22/11)
- [x] `SY5` (M) código errado é recusado; o certo entra e o progresso local sobe para a nuvem (estatísticas e vocabulário), sem o texto dos livros — **app novo: NUD7e** (22/11)
- [x] `SY6` (M) o que veio de outro aparelho entra aqui sem perder o local: dia com o maior tempo, cartão novo, posição e palavras ouvidas do livro mais recentes — **app novo: NUD7f** (22/11)
- [x] `SY7` (M) se outro aparelho gravar no meio, a sincronização relê, mescla e tenta de novo (conflito resolvido) e a nuvem fica com tudo — **app novo: NUD7f** (22/11)
- [x] `SY8` (M) sair da conta não apaga nada do aparelho (estatísticas, vocabulário e livros continuam) — **app novo: NUD7h, NUD8f** (22/11)
- [x] `SY9` (M) sem configuração o site volta ao normal (nada é chamado) — **app novo: NUD7a** (22/11)

### `T` · Botões do site (Teleprompter, Raio-X) → Interface (R3)

- [ ] `T1` (M) na Biblioteca, com documento aberto, aparece o botão Teleprompter
- [ ] `T2` (M) clicar em Teleprompter alterna o modo (tele liga, tele de novo desliga)
- [ ] `T3` (M) clicar de novo volta ao modo anterior
- [ ] `T4` (M) no Manual (sem documento aberto), o Teleprompter some

### `TC` · Painel de andamento do teleprompter → Componente de andamento unificado (R4)

- [ ] `TC1` (M) o contador de palavras avança com o texto (lidas / total) e mostra quanto falta
- [ ] `TC2` (M) mostra a página em que o leitor está (de quantas) e quantas faltam
- [ ] `TC3` (M) mostra o tempo usado, a média para concluir e o que falta, com o ritmo em palavras por minuto
- [ ] `TC4` (M) mostra o que se trabalha agora: lendo e ouvindo, idiomas de leitura e de escuta, livro e frase
- [ ] `TC5` (M) o tempo usado corre enquanto o leitor está na tarefa (mesmo parado, com atividade recente)
- [ ] `TC6` (M) o tempo usado fica guardado para o livro (continua na próxima vez)

### `U` · Seletor de modos e teleprompter → Leitura (4 modos) (R3)

- [ ] `U1` (M) o seletor de modos tem o Teleprompter como quinta opção
- [ ] `U2` (M) o resto da tela some: menu, barra de comandos e rodapé do site escondem, e a legenda cobre a janela
- [ ] `U3` (M) a narração começa sozinha ao escolher o modo
- [ ] `U4` (M) ler em português e ouvir em inglês: a linha grande está em português (idioma de leitura), de uma linha só e letras grandes, e embaixo está o inglês que se ouve
- [ ] `U5` (M) a palavra destacada na linha em português acompanha a voz em inglês (posição proporcional entre os idiomas)
- [ ] `U6` (M) a linha corre da direita para a esquerda: avançar a voz move o texto para a esquerda, mantendo a palavra no ponto de leitura
- [ ] `U7` (M) a frase seguinte já estava carregada à direita (prévia) e vira a atual vindo da direita, sem salto
- [ ] `U8` (M) trocar para ler em inglês e ouvir em português (e o contrário) pelos botões da própria legenda, que também atualizam o site
- [ ] `U9` (M) próxima frase avança o contador, e A+ aumenta a letra com o tamanho guardado
- [ ] `U10` (M) Esc sai do teleprompter: o site volta (menu, comandos e rodapé), o modo volta a coluna única e o seletor acompanha

### `W` · 4 temas × 4 modos: destaque visível → Leitura (R3)

- [ ] `W1` (M) em 4 temas x 4 modos (coluna única, larga, lado a lado, foco): a frase destacada, a linha e a palavra sincronizada têm cores visíveis e de famílias diferentes

### `X` · Combinações ler × ouvir (PT/EN) → Motor Narrador (R2)

- [ ] `X1` (M) teleprompter: ler PT/ouvir PT, ler PT/ouvir EN, ler EN/ouvir PT, ler EN/ouvir EN (linha grande no idioma de leitura, voz no de áudio, o outro idioma embaixo)
- [ ] `X2` (M) com a narração tocando, trocar Ouvir muda a voz na hora e trocar Ler muda a linha na hora, sem parar o modo

### `Y` · Velocidade no meio da frase → Motor Narrador (R2)

- [ ] `Y1` (M) trocar a velocidade no meio da frase continua da palavra falada (antes recomeçava a frase do início)
- [ ] `Y2` (M) depois de retomar, o destaque continua a partir da posição já falada, sem voltar ao início da frase
- [ ] `Y3` (M) sem evento de palavra da voz, o destaque avança por estimativa, sem voltar atrás e chegando perto do fim da frase — **ritmo pronto no app novo (NR6, NR7a, NR7b)**; falta a voz do navegador (R2.2)

### `Z` · Centragem, fila sem lacuna, deslize contínuo → Motor Narrador + Teleprompter (R2)

- [ ] `Z1` (M) a palavra falada fica sempre no ponto de leitura (erro máximo de centragem em px) e o destaque nunca volta atrás, com voz em um idioma e legenda em outro
- [ ] `Z2` (M) a frase seguinte entra na fila do motor enquanto a atual ainda toca (sem lacuna), e a marcação segue a ordem sem repetir nem pular frases
- [ ] `Z3` (M) a próxima frase já aparece carregada à direita, esmaecida, enquanto só a atual é destacada
- [ ] `Z4` (M) atualizações repetidas sem mudança não refazem a linha: mesmos elementos, mesma palavra destacada e a linha não se mexe (sem travada na transição)
- [ ] `Z5` (M) a linha desliza de forma contínua e linear no ritmo da fala (sem parar a cada palavra): duração entre 90 e 1400 ms

## 4. Testes novos do app novo (criados a partir da R1a)

Além das 279 verificações herdadas, o núcleo novo tem os seus testes em `site/tools/test_novo_nucleo.ps1`: **29 verificações, todas passando em 22/11/2026**. Cobrem recursos que a reconstrução **acrescenta** (registro de módulos, eventos tipados, migração com cópia de segurança, rotas) e garantem a convivência com o app de hoje (`NU6`: o banco antigo abre na versão 2 depois do núcleo novo). Detalhes em `09-nucleo-novo.md`, seção 8.

| Área | O que cobre | Verificações |
|---|---|---|
| `NU1` | O app liga sozinho; os 6 módulos ficam prontos | 1 |
| `NU2` | Eventos tipados: desconhecido é erro, escutador que falha isolado, desligar, uma vez | 3 |
| `NU3` | Preferências compatíveis com `dd-settings`: limpeza e limites, preserva campos do app antigo, aparência | 5 |
| `NU5` | localStorage seguro | 1 |
| `NU6` | Banco do app de hoje: versão 2 mantida, leitura e gravação, **app antigo ainda abre** | 3 |
| `NU7` | Banco novo (6 stores) | 1 |
| `NU8–NU12` | Migração com cópia automática, restauração, cancelamento se a cópia falhar, versão mais nova, só 3 cópias | 5 |
| `NU13–NU17` | Rotas (parâmetros, desconhecida, erro numa tela, texto nunca vira HTML) e tela Sistema | 6 |
| `NU18` | Registro de módulos (ordem, dependência faltando, ciclo, módulo que falha, definir tarde) | 4 |
| **Total** | | **29** |

**Áreas da matriz ainda abertas na R1 (R1b):** `BK`, `SY`, `N`, `S`.

### 4.1 Testes de dados do app novo (R1b): `site/tools/test_novo_dados.ps1`

**41 verificações, todas passando em 22/11/2026.** A peça central é a **paridade com o app de hoje**: o teste carrega o app atual numa moldura e compara, com os mesmos dados, o app novo e o de hoje.

| Área | O que cobre | Verificações |
|---|---|---|
| `NUD0` | O app de hoje carrega como referência | 1 |
| `NUD1` | **Mescla idêntica nos dois apps**: 8 casos fixos, **300 pares aleatórios** (semente fixa) e propriedades (idempotente, nunca perde dia, cartão ou livro) | 3 |
| `NUD2` | Snapshot do app novo = snapshot do app de hoje (mesmo banco, mesmo localStorage) | 1 |
| `NUD3` | Backup **nos dois sentidos** (exportado por um, carregado pelo outro), sem duplicar, 6 tipos de arquivo inválido, arquivo com partes quebradas | 6 |
| `NUD4` | Livros pendentes: ficam guardados, abrem na posição certa quando entram, livro já existente recebe a posição | 3 |
| `NUD5` | Livro aberto não muda por baixo do leitor; livro fechado recebe a mescla | 2 |
| `NUD6` | Registro de estudo (eventos na hora, tempos a cada 2 s, pagehide, soma por cima de mescla alheia, sequência) e espelho da leitura | 8 |
| `NUD7` | Nuvem simulada: sem configuração, e-mail inválido, falha do envio com motivo, login, código errado, sincronizar, **conflito**, sessão vencida, sair, sem rede e volta | 11 |
| `NUD8` | Tela `#/dados`: backup (baixar com texto de apoio, colar, recusar) e conta (entrar e sair) | 6 |
| **Total** | | **41** |

**Total de testes do app novo: 83** (29 do núcleo + 41 de dados + 13 do narrador, ver 4.2).

> **Aviso sobre os testes do app de hoje (`test_ingles_modulos.ps1`, itens TC5, L7 e L14):** são sensíveis à carga da máquina (tempo virtual do Chrome). Em 22/11/2026 falharam de forma intermitente, **igual com e sem a pasta `novo/`** (9 falhas em 12 sem `novo/`, 6 em 12 com), e passam quando a máquina está sossegada. Se falharem, rodar de novo sozinho, sem outros testes ou Chrome ao mesmo tempo, antes de suspeitar do código.

### 4.2 Testes do Narrador (R2.1): `site/tools/test_novo_narrador.ps1`

**13 verificações, todas passando em 22/11/2026.** Cada peça pura (ritmo e vozes) é comparada com uma **cópia literal do código antigo** com centenas de entradas aleatórias, e a sincronia é simulada com os cenários do `test_sync.ps1` do livro, em tempo simulado.

| Área | O que cobre | Verificações |
|---|---|---|
| `NR0` | módulos `ritmo` e `vozes` prontos | 1 |
| `NR1`–`NR2` | tempo acumulado e posição estimada idênticos aos do código antigo | 2 |
| `NR3` | aprendizado da velocidade por idioma e voz, limites 6–40 | 3 |
| `NR4`–`NR5` | escolha e ordenação de vozes idênticas às do app de hoje e do menu da casca | 3 |
| `NR6`–`NR7` | sincronia por estimativa: erro médio ≤ 1,5 palavra (medido 0,35–0,73), nunca volta atrás, chega ao fim da frase, erro máximo limitado | 4 |
| **Total** | | **13** |