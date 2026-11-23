# Registro de evolução (CHANGELOG)

> Uma entrada por dia de trabalho, da mais nova para a mais antiga. Escreva **o que mudou, por quê e como conferir**. Mantém o autor e o Claude sem precisar reler conversas antigas.

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
