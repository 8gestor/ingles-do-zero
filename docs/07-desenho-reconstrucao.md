# 07 · Desenho da reconstrução: imersão em livros

> **Estado: desenho aprovado em linhas gerais; Q1–Q4 decididas em 2026-11-22 (seção 11). Restam Q5–Q8.** Itens **(?)** são decisões do autor. Onde este documento contradiz `02-niveis.md`, `03-arquitetura-roadmap.md` ou `04-telas.md`, **vale este** (ver seção 12).
> Este é o documento-mãe da reconstrução. Quando uma decisão for tomada, trocar o **(?)** pela decisão e a data.

---

## 1. Tese do produto

> **Aprender inglês vivendo dentro de livros de verdade.** O aluno lê, ouve, repete, escreve e discute **o mesmo texto**, em um nível um pouco acima do que já entende, todo dia, até o inglês deixar de ser tradução e virar compreensão direta.

- **O livro é o currículo.** Cada livro é um "curso": a lista de capítulos é a lista de lições, o vocabulário vem do texto, a gramática aparece onde o texto a usa, a escrita é sobre o que foi lido.
- **Não somos escola tradicional.** Não há aula de "verbo to be" isolada, lista de palavras solta, nem exercício sem contexto. Não ensinamos *sobre* o inglês; fazemos o aluno *usar* o inglês.
- **Imersão em quatro frentes + contexto**, sempre sobre o mesmo texto: **ler · ouvir · falar · escrever · entender o contexto.**
- **Sem estresse e gratuito**: ritmo curto e retomável, sem ranking, sem punição, custo operacional perto de zero (decisões do autor de 21/11).
- **Funciona em qualquer aparelho** (PC, celular, tablet, Kindle, TV): regra de plataformas em `06-biblioteca-modulos.md`.

### O que não somos
Curso com certificado · "fluência em X dias" · rede social/ranking · loja de conteúdo pago · aplicativo que manda texto, voz ou áudio do aluno para serviços de terceiros sem aviso e escolha.

---

## 2. O método: o ciclo do livro

As cinco frentes são **atividades sobre o texto**, não módulos separados.

| Frente | O que o aluno faz | Como é feito no site | O que se mede (local) |
|---|---|---|---|
| **Ler** | Leitura densa, no ritmo dele, com apoio sob demanda (tradução por frase, toque na palavra) | Leitor com modos (seção 5); apoio em português que o aluno liga e desliga | palavras lidas, tempo lendo, % do livro |
| **Ouvir** | Ouvir o texto narrado enquanto acompanha (palavra a palavra); depois **ouvir sem ler** | Narração por frase, velocidade 0,1× a 3×, alinhamento de palavras, teleprompter | palavras ouvidas, tempo ouvindo, velocidade usada |
| **Falar** | **Shadowing** (repetir junto/logo após), leitura em voz alta, **gravar-se e comparar** com a narração | Modo Shadowing (já existe) + gravação local opcional para se ouvir | frases repetidas, tempo falando |
| **Escrever** | Resumo com as próprias palavras, objeção/opinião, reescrita de uma frase, ditado | Escrita guiada por livro (já existe a semanal) + ditado (já existe) | textos escritos, checagens por regras |
| **Entender o contexto** | Saber **por que** o autor diz o que diz: quem fala, época, ideia, ironia, referência | **Notas de contexto** por trecho, **perguntas de compreensão**, **roteiro de discussão** do capítulo | acertos nas perguntas, notas lidas |

### Gramática, sem aula de gramática
- **Padrões do trecho**: ao tocar numa frase, o aluno pode abrir "o que está acontecendo aqui" (ex.: *would have gone*; ordem adjetivo-substantivo). Notas curtas, ligadas à **frase real do livro**.
- **Revisão em contexto**: os cartões são **a frase do livro** com a palavra/padrão escondido (cloze), nunca a palavra solta.
- A nota de padrão é **produzida na criação do conteúdo** (IA + revisão do autor, declarada), não gerada na hora para cada aluno: custo zero e sem depender de internet.

### Entender o contexto
- **Notas de contexto** do catálogo: autor, época, vocabulário cultural, referências. Curtas, com fonte citada ou ressalva.
- **Perguntas de compreensão** em 3 camadas: literal (o que diz), inferência (o que quer dizer), opinião (o que você pensa).
- **Conversa sobre o livro**: roteiro de discussão por capítulo, em que o aluno responde por escrito (ou falando) e recebe retorno por regras. Se existir modelo de IA local no aparelho, ele pode ampliar; **nunca é requisito** (ver Q2).

---

## 3. A jornada do aluno

### 3.1 Primeiro dia: descobrir onde começar (sem prova)
Em vez de teste de múltipla escolha: o aluno lê **3 amostras curtas** de degraus diferentes e marca "entendi tudo / entendi a maior parte / me perdi". O sistema sugere o degrau (seção 3.3). O que "me perdi" no teste vira primeiras palavras do vocabulário. Dá para começar do zero mesmo assim.

### 3.2 A sessão diária (padrão já construído: 50 minutos, 4 blocos)
```
 ┌────────────────────────────────────────────────────────────┐
 │  SESSÃO DO DIA  (≈50 min, retomável a qualquer momento)    │
 ├──────────────┬──────────────┬──────────────┬───────────────┤
 │ 1. LER       │ 2. PALAVRAS  │ 3. FALAR     │ 4. ESCREVER   │
 │ cota do dia  │ revisão dos  │ shadowing do │ 2 frases +    │
 │ do livro     │ cartões que  │ trecho lido  │ objeção, ou   │
 │ (leitura +   │ vencem hoje  │ (ouvir →     │ resumo, ou    │
 │ escuta)      │ (cloze)      │ repetir)     │ ditado        │
 └──────────────┴──────────────┴──────────────┴───────────────┘
  Dia leve (10 min): só 1 e 2.   Dia de conversa: troca o 4 pela discussão do capítulo.
```
- O ritmo se ajusta ao degrau: nos degraus iniciais, **ouvir e ler ao mesmo tempo** (bimodal) pesa mais; nos altos, ler denso e escrever pesam mais.
- **Uma ação principal por dia**: o aluno nunca decide o que estudar; "Continuar" abre o próximo bloco.

### 3.3 A escada de leitura (substitui os "níveis A1–C2 com lições")
A progressão é por **textos cada vez mais ricos**, não por unidades de aula. Cada degrau tem tipo de texto, tamanho, apoio e meta. A referência CEFR é só rótulo.

| Degrau | Nome | Texto típico | Apoio padrão | Referência |
|---|---|---|---|---|
| **0** | Primeiras histórias | Fábulas e cenas **adaptadas**, 80 a 250 palavras, vocabulário mínimo | tradução por frase, áudio lento, palavras tocáveis | Pré-A1–A1 |
| **1** | Histórias curtas | Contos infantis e clássicos **adaptados**, 300 a 1.200 palavras | tradução sob demanda | A2 |
| **2** | Contos | Contos de autores clássicos, **adaptação leve ou texto original curto** | tradução sob demanda, notas de contexto | B1 |
| **3** | Livros curtos | Novelas e ensaios curtos em texto original (ex.: *Jekyll and Hyde*, *Civil Disobedience*) | notas, perguntas, discussão | B2 |
| **4** | Pensamento clássico | Filosofia e memórias (ex.: Epicteto, Platão, Emerson) | contexto denso, escrita com objeção | C1 |
| **5** | Densidade | Textos longos e ambíguos (ex.: Sêneca, Tolstói) | poucas muletas, discussão aberta | C2 |

**Achado importante:** o roteiro de 8 semanas que já existe cobre bem os degraus **3 a 5**. **O degrau 0 a 2 está vazio**, e é exatamente o "do zero". Preencher isso é o maior trabalho de **conteúdo** da reconstrução. Todo texto deve ser de **domínio público** ou autoral nosso; **verificar a licença livro a livro** antes de entrar (Standard Ebooks/Project Gutenberg como fonte; adaptações produzidas aqui são declaradas como adaptação).

### 3.4 Ritmo maior
- **Semana**: um livro (ou um capítulo longo) com plano de 7 dias, cota diária e **fechamento** (revisão com números reais + resumo). Já existe.
- **Mês**: marcos visíveis ("12 livros curtos lidos", "1.000 palavras salvas", "20 h ouvindo") e um **ponto de revisão do degrau** (sugere subir quando as marcas de compreensão estão altas por 2 semanas).
- O site **orienta, não tranca**: o aluno pode ir a qualquer degrau, com aviso do que provavelmente vai faltar.

---

## 4. Arquitetura de software

### 4.1 Camadas
```
┌─────────────────────────────────────────────────────────────────────┐
│ INTERFACE (telas)   Hoje · Estante · Leitura · Palavras · Progresso │
├─────────────────────────────────────────────────────────────────────┤
│ ATIVIDADES (plugins)  ler · ouvir · shadowing · ditado · escrita ·  │
│                       perguntas · discussão · revisão de cartões    │
├─────────────────────────────────────────────────────────────────────┤
│ PLANEJADOR   sessão do dia · plano da semana · sugestão de degrau   │
├───────────────────────────┬─────────────────────────────────────────┤
│ MOTORES                   │ SERVIÇOS                                │
│  Leitor (texto, frases,   │  Voz (navegador / Piper / [gravada])    │
│   marcação, alinhamento)  │  Tradução (catálogo / tradutor local)   │
│  Narrador (fila, buffer,  │  Dicionário (palavra → sentido)         │
│   velocidade, palavra)    │  Reconhecimento de fala [opcional]      │
├───────────────────────────┴─────────────────────────────────────────┤
│ NÚCLEO   Armazenamento (IndexedDB+localStorage) · Eventos · Config  │
│          Sincronização e backup (mesclar, nunca apagar)             │
├─────────────────────────────────────────────────────────────────────┤
│ CATÁLOGO (dados)  livros · edições · traduções · notas · perguntas  │
└─────────────────────────────────────────────────────────────────────┘
```
Regra: **cada camada só conhece a de baixo**. Atividades e telas nunca mexem em IndexedDB nem em `speechSynthesis` direto: usam o núcleo, o narrador e a voz.

### 4.2 Modelo de dados (entidades)
| Entidade | Campos principais | Onde mora |
|---|---|---|
| **Livro** | id, título, autor, degrau, idioma original, licença, fonte, resumo, capítulos | catálogo (arquivo) |
| **Capítulo/Edição** | livro, idioma, parágrafos → frases (ou versos), páginas | catálogo (texto) ou aluno (importado) |
| **Tradução** | frase → texto PT, origem (`humana`/`ia-revisada`/`local`) | catálogo; ou cache do tradutor local |
| **Nota** | frase/trecho → tipo (`contexto`/`padrão`), texto, fonte | catálogo |
| **Pergunta** | capítulo → camada (literal/inferência/opinião), enunciado, chave de checagem | catálogo |
| **Cartão** | frase de origem, palavra/padrão, tipo (cloze/palavra), repetição espaçada | aluno |
| **Posição** | livro/idioma → parágrafo, palavras ouvidas, última abertura | aluno |
| **Registro** | dia → segundos lendo/ouvindo/falando/escrevendo, palavras, revisões | aluno |
| **Escrita** | data, tipo, livro, texto | aluno |
| **Plano** | semana, livro, cota, histórico | aluno |

**Catálogo ≠ aluno.** O catálogo é conteúdo versionado no repositório (público, validado por script). O estado do aluno é privado, local-primeiro, e é só ele que sincroniza ou entra no backup. Livros **importados pelo aluno** (PDF/EPUB/texto) ficam só no aparelho dele e **nunca sobem**.

### 4.3 Contratos entre módulos (para trocar peças sem quebrar o resto)
- **Voz** `speak(frase, {idioma, velocidade}) → eventos {início, palavra, fim}`; implementações: voz do navegador, Piper local, (futuro) áudio gravado. O narrador não sabe qual está usando.
- **Tradutor** `traduzir(frase, de, para) → texto`; implementações: catálogo (prioridade), tradutor local do Chrome (textos do aluno), nenhum (cai em "sem tradução", o site continua).
- **Atividade** (plugin): `{ id, título, aplicaA(estado), montar(contêiner, contexto), concluir() → registro }`. Nova atividade = um arquivo, sem tocar no núcleo.
- **Armazém** `get/put/all/del` com **migração de versão** do banco e **backup automático antes de migrar**.
- **Eventos** tipados (`livro-aberto`, `frase-ouvida`, `palavra-salva`, `revisão-feita`…) em vez de ids de DOM e variáveis globais.

### 4.4 Do iframe com mensagens para uma aplicação de página única
Hoje: o aplicativo roda **dentro de um iframe** e conversa com uma casca por `postMessage` (herança do livro). Funciona e está testado, mas custa: duas telas para manter, atrasos, estado duplicado (barra de andamento na casca e na página).
Proposta: **uma só aplicação** com rotas por `#/hoje`, `#/estante`, `#/ler/<livro>`, `#/palavras`, `#/progresso`. Menu, tema, voz, velocidade e andamento viram componentes do próprio app. **Mantém**: preferências em `dd-settings`, atalhos (setas, F11, Esc), modo imersivo.

### 4.5 Código sem build, mas organizado
- Continua **JS puro, sem build e sem dependências**, para rodar em navegadores simples (Kindle, TV).
- **Sem `type="module"`** por ora (suporte irregular em navegadores de e-reader/TV): um **registro de módulos** simples (`App.define('nome', deps, fábrica)`) dá ordem e fronteiras sem exigir módulos nativos.
- `ingles.js` (~1.300 linhas, 79 KB) é um monólito que mistura leitor, narrador, tradução, biblioteca e barra inferior. **Será dividido em motores**, preservando o comportamento (medido pelos testes).

### 4.6 Conteúdo como dados, com validação automática
```
catalogo/
  livros.json                  índice (título, autor, degrau, licença, fonte)
  <livro>/
    texto.en.txt               texto de partida
    traducao.pt.json           frase → PT (origem declarada)
    notas.json  perguntas.json padrões, contexto, compreensão
```
Script `tools/validar-catalogo.ps1` confere: licença preenchida, paridade de frases PT/EN, tamanho por degrau, vocabulário do degrau, notas com fonte ou ressalva, perguntas com chave. **Nada entra sem passar.**

### 4.7 Offline e aparelhos
- **Site instalável e offline** (service worker) com cache da casca e dos livros que o aluno abriu; **degrada com graça** onde o aparelho não suporta (Kindle/TV): abre online normalmente.
- Regra de plataformas (alvos de toque ≥ 44 px, nada só com mouse/atalho, layout de 320 px a TV, tema legível em papel eletrônico) **continua obrigatória** em toda tela nova.

### 4.8 Dados do aluno: local primeiro, nuvem opcional
Já pronto e mantido: IndexedDB `dd-ingles` + localStorage; **nuvem** (Supabase, login por código); **backup por arquivo**; mescla que nunca apaga. A reconstrução **mantém o formato do backup (v1)** e acrescenta versões, com leitura de todas as anteriores.

---

## 5. Telas (celular em pé é a principal)

Barra inferior: **Hoje · Estante · Palavras · Progresso** (a Leitura abre de dentro de Hoje ou da Estante).

```
┌───────────────────────────┐   ┌───────────────────────────┐
│ HOJE · 5 dias seguidos    │   │ ESTANTE                   │
│                           │   │ [ Degrau 0 ▾ ]  [buscar]  │
│ ▶ Continuar               │   │ ┌─────┐ ┌─────┐ ┌─────┐   │
│   O Corvo e a Raposa      │   │ │Corvo│ │Lebre│ │Cigar│   │
│   Bloco 1 · Ler   ~15 min │   │ │ 4 % │ │ novo│ │ ✓   │   │
│                           │   │ └─────┘ └─────┘ └─────┘   │
│ ◉ 8 palavras para rever   │   │ + Trazer meu livro        │
│ ✎ Escrita de hoje         │   │   (PDF · EPUB · texto)    │
│ ═══ 32 de 50 min ═══      │   └───────────────────────────┘
└───────────────────────────┘
```
```
┌───────────────────────────────────────┐   ┌───────────────────────────┐
│ ‹  O Corvo e a Raposa     ⚙  ⛶       │   │ PALAVRAS                  │
│ LER [PT|EN]  OUVIR [PT|EN]  0,8×  ▶   │   │ 12 vencem hoje  [Revisar] │
│ Modo: Leitura · Lado a lado · Foco ·  │   │ 340 salvas · 61 dominadas │
│       Teleprompter                    │   │ ┌───────────────────────┐ │
│───────────────────────────────────────│   │ │ …the crow opened her  │ │
│ A crow found a piece of cheese …      │   │ │ ____ to sing…         │ │
│ ▓▓▓ palavra falada (cor 1)            │   │ │ [mostrar] [difícil]   │ │
│ linha atual (cor 2)                   │   │ └───────────────────────┘ │
│ equivalente em PT sob a palavra       │   └───────────────────────────┘
│───────────────────────────────────────│
│ Notas ▸  Perguntas ▸  Falar ▸  Escrever ▸    ← atividades do trecho
│ pág 3/12 · 540/1.800 palavras · 14 min│
└───────────────────────────────────────┘
```
```
┌───────────────────────────┐   ┌───────────────────────────┐
│ PROGRESSO                 │   │ ESCRITA / DISCUSSÃO       │
│ Degrau 1 ●●●○○  (sugestão │   │ Cap. 2 · pergunta:        │
│ de subir em ~9 dias)      │   │ "Por que a raposa elogia  │
│ Esta semana: 3 de 7 dias  │   │  a voz do corvo?"         │
│ ▁▃▅▇▅▃▇  tempo por dia    │   │ [ sua resposta … ]        │
│ Lendo 4h · Ouvindo 6h ·   │   │ Retorno: usou 'because' ✓ │
│ Falando 1h · Escrevendo 1h│   │ [ ver nota de contexto ]  │
│ [Backup] [Sincronizar]    │   └───────────────────────────┘
└───────────────────────────┘
```
**Modos de leitura** (ver seção 6): Leitura (1 coluna, coluna larga como opção), Lado a lado (original | tradução), Foco com painel, **Teleprompter** (legenda corrida, tela limpa). O aluno escolhe a qualquer momento e a escolha é lembrada.

---

## 6. Inventário: manter, fundir, cortar, criar

> O autor pediu para **excluir o excesso e manter o que é usual e bom**. Esta tabela é a **proposta**; **nenhuma linha vira corte sem aprovação**, e nada sai do ar antes de o equivalente novo passar nos mesmos testes (seção 7). Os módulos estão descritos em `06-biblioteca-modulos.md`.

| Módulo / recurso hoje | Veredito | Destino |
|---|---|---|
| Leitor: marcação em 4 camadas (parágrafo/linha/frase/palavra) | **Manter** | Motor Leitor |
| Narração: buffer à frente, velocidade 0,1–3×, retomar da palavra | **Manter** | Motor Narrador |
| Alinhamento de palavras entre idiomas (`ingles-alinhar`) | **Manter** | Serviço do Narrador |
| Teleprompter | **Manter** (modo imersivo) | Modo de leitura |
| Legenda | **Fundir** com o Teleprompter (mesma lógica, duas apresentações) | Modo de leitura |
| 5 modos de leitura em seletor | **Reorganizar** em 4 (coluna larga vira opção da Leitura) | Leitura |
| Setas palavra a palavra (`ingles-explorar`) | **Manter** | Atalho do Leitor |
| Destacar incomuns (`ingles-destaque`) | **Fundir** como opção do Leitor | Opção de leitura |
| Toque na palavra + cartões (SM-2) | **Manter e evoluir** para cartões **cloze da frase** | Palavras |
| Exportar para Anki (TSV) | **Manter** | Palavras |
| Nível do texto (`ingles-nivel`, 1.300 palavras) | **Evoluir** para faixas de frequência por degrau | Catálogo/Estante |
| Treino: repetir / shadowing / ditado | **Manter**; shadowing ganha gravação local opcional | Atividades |
| Sessão do dia (50 min, 4 blocos) | **Manter** e virar a tela **Hoje** | Planejador |
| Livro da semana + fechamento | **Manter** | Planejador |
| Roteiro de 8 livros (degraus 3–5) | **Manter**; **criar degraus 0–2** | Catálogo |
| Perguntas de compreensão com modelo local do Chrome | **Trocar**: perguntas **escritas no catálogo**; modelo local vira extra opcional | Atividades |
| Importar PDF/EPUB/texto colado | **Manter** | Estante |
| Voz neural local (Piper, 60 MB/idioma) | **Manter, opcional**, com aviso de tamanho | Serviço de Voz |
| Progresso: sequência, minutos, gráfico 7 dias | **Manter**; **unificar** os 3 painéis de andamento (foco, teleprompter, rodapé) em **um componente** | Progresso |
| Conta (Supabase) + backup por arquivo | **Manter** | Núcleo |
| Manual da Biblioteca (página separada) | **Fundir** em ajuda dentro do app (mesmo texto PT/EN) | Interface |
| Casca com iframe + `postMessage` | **Cortar** (seção 4.4), depois de paridade | Interface |
| Pasta `legado-livro/` (cópia antiga) | **Cortar** (já substituída por `site/`) | Repositório |
| **Novo:** notas de contexto e de padrão | **Criar** | Catálogo |
| **Novo:** discussão do capítulo com retorno por regras | **Criar** | Atividades |
| **Novo:** gravação local para se ouvir (shadowing) | **Criar** (opcional) | Atividades |
| **Novo:** degraus 0–2 (adaptações de domínio público) | **Criar** | Catálogo |
| **Novo:** instalável/offline (service worker) | **Criar** | Núcleo |

---

## 7. Protocolo "nenhuma função perdida, nada quebrado"

1. **Matriz de paridade**: uma tabela (`docs/08-paridade.md`, a criar na R0) com **cada função de hoje → quem a substitui → qual teste a cobre**. A reconstrução só avança quando a coluna do teste está verde.
2. **Construir ao lado, trocar depois** (padrão "estrangulador"): a versão atual continua no ar e funcionando; a nova roda em `/novo/` (ou com `?novo=1`) até **passar todos os testes atuais + os novos**. Só então é a principal.
3. **Os testes de hoje viram o contrato.** Tudo o que `test_ingles_modulos.ps1` e `test_ingles.ps1` verificam precisa passar no app novo (adaptando só os seletores, nunca enfraquecendo a verificação).
4. **Dados do aluno nunca são perdidos**: migração do banco com **backup automático antes**, leitura de todos os formatos de backup anteriores, e a mescla continua "nunca apaga".
5. **Registro**: cada etapa entra no `CHANGELOG.md`; cada decisão troca um **(?)** neste documento.
6. **Publicar só com autorização** (regra do projeto), e sempre com as duas versões no ar até a paridade.

---

## 8. Roadmap da reconstrução

| Fase | Entrega | Saída verificável | Esforço |
|---|---|---|---|
| **R0 · Fundações do desenho** | Este documento aprovado; matriz de paridade; ajuste dos docs 01–04 | Autor aprova o desenho e as respostas das perguntas | P |
| **R1 · Núcleo novo** | Armazém com migração, eventos, registro de módulos, configuração; app de página única com rotas vazias | Testes do núcleo verdes; dados antigos migram sem perda | M |
| **R2 · Motores** | Leitor e Narrador separados do monólito, atrás dos contratos de Voz e Tradutor | Testes de leitura, narração, sincronia e teleprompter verdes no app novo | G |
| **R3 · Telas essenciais** | Hoje, Estante, Leitura (4 modos), Palavras, Progresso | O autor usa o app novo no dia a dia no celular e no PC | G |
| **R4 · Atividades** | Shadowing (com gravação), ditado, escrita, cartões cloze, andamento unificado | Sessão do dia completa de ponta a ponta | M |
| **R5 · Catálogo e contexto** | Formato de catálogo + validador; degraus 3–5 migrados; notas, perguntas e discussão nos 8 livros do roteiro | `validar-catalogo` verde; um livro completo com todas as camadas | G |
| **R6 · Degraus 0–2** | Adaptações de domínio público (fábulas, contos), com licença conferida e declaração de IA | Uma pessoa iniciante conclui o degrau 0 e dá retorno | G (conteúdo) |
| **R7 · Offline e aparelhos** | Service worker; testes em celular real, tablet, Kindle/TV (quando houver aparelho) | Roteiro de testes por aparelho preenchido | M |
| **R8 · Troca e limpeza** | App novo vira o principal; aba do livro vira link; remove iframe, `legado-livro/`, manual duplicado | Paridade 100% + backup do aluno carregando sem perda | P |

Esforço: P = pequeno, M = médio, G = grande (referência relativa; o custo real depende de quanto conteúdo o autor revisa).

---

## 9. Riscos

| Risco | Efeito | Mitigação |
|---|---|---|
| Reescrever um monólito de 79 KB muito testado | Regressões sutis (sincronia da narração, posição de leitura) | Paridade primeiro, testes de hoje como contrato, versão atual no ar até o fim |
| Conteúdo dos degraus 0–2 (volume e qualidade) | O "do zero" não fica pronto; erros ensinam errado | Começar por poucos textos curtos; validador automático; revisão do autor priorizando o degrau 0; declarar IA |
| **Direitos autorais** (adaptações, traduções, notas) | Problema legal | Só domínio público ou texto autoral; licença e fonte por livro; auditoria no validador |
| Reconhecimento de fala no Chrome pode enviar áudio a servidores de terceiros (**verificar**) | Quebra a regra de privacidade | Opcional, desligado por padrão, com aviso claro; ou não usar (ver Q1) |
| IA em tempo de uso custa dinheiro | Fere o "gratuito" | IA só na **produção** do conteúdo; em uso, só modelo local opcional (ver Q2) |
| Qualidade de voz sintética | Pronúncia ruim ensina errado | Voz neural opcional; aviso de limitação; áudio gravado nas peças-chave (ver Q5) |
| Navegadores simples (Kindle, TV) | Recursos não funcionam | Degradar com graça; testar em aparelho real quando existir |
| Escopo grande | Projeto não termina | Fases com saída verificável; o app atual segue utilizável durante toda a obra |

---

## 10. Perguntas abertas

Marcadas **(?)** até o autor decidir. As quatro primeiras mudam o desenho e foram feitas em 22/11/2026.

1. **Q1 · Falar — DECIDIDO 22/11/2026: shadowing + gravar-se e comparar, tudo local** (sem reconhecimento de voz de terceiros; sem enviar áudio). Reavaliar reconhecimento de voz opcional só depois, com verificação de privacidade.
2. **Q2 · Conversa sobre o livro — DECIDIDO 22/11/2026: roteiro e retorno por regras**, produzidos junto com o conteúdo (custo zero, funciona offline); modelo de IA local do navegador só como extra opcional. Chave de IA do aluno fica como ideia futura.
3. **Q3 · Quem está no zero — DECIDIDO 22/11/2026: ambos, com adaptações como ponte.** Degraus 0 a 2 = adaptações de domínio público (IA, declaradas, revisadas pelo autor); originais a partir do degrau 3.
4. **Q4 · Como reconstruir — DECIDIDO 22/11/2026: ao lado, módulo a módulo.** O site atual segue no ar; o novo só vira o principal quando passar em todos os testes de hoje (seção 7).
5. **Q5 · Áudio:** só voz sintética (navegador e Piper) ou também gravações humanas nas peças-chave, que não são gratuitas. **(?)**
6. **Q6 · Nome do projeto e do domínio final** (hoje `ingles-do-zero`; endereço provisório `ingles.vocealgoritmo.com.br`). **(?)**
7. **Q7 · Sustento a longo prazo** sendo gratuito (tempo do autor, doação, apoio). Não bloqueia agora. **(?)**
8. **Q8 · Quanto revisar:** toda adaptação/nota ou por amostragem com validação automática forte. **(?)**
9. **Q9 · Segurança e acesso** (autenticação em duas etapas, restringir uso): **adiado por decisão do autor em 22/11**; retomar depois do sistema robusto.

---

## 11. Decisões registradas

| Data | Decisão | Origem |
|---|---|---|
| 2026-11-22 | O produto é **imersão em livros**, não escola tradicional; as cinco frentes (ler, ouvir, falar, escrever, entender contexto) agem sobre o mesmo texto | Autor |
| 2026-11-22 | Reformular o que existe: **excluir o excesso, manter o que é usual e bom** | Autor |
| 2026-11-22 | Manter: gratuito, estático, local-primeiro, nuvem opcional, backup por arquivo, regra de plataformas | Decisões anteriores |
| 2026-11-22 | Segurança/duas etapas: **adiar**; programar até o sistema ser robusto | Autor |
| 2026-11-22 | **Falar** = shadowing + gravar-se, tudo local (Q1) | Autor |
| 2026-11-22 | **Conversa** = roteiro + retorno por regras; IA local só opcional (Q2) | Autor |
| 2026-11-22 | **Zero** = adaptações de domínio público como ponte para os originais (Q3) | Autor |
| 2026-11-22 | **Reconstrução** ao lado, módulo a módulo, site atual no ar até a paridade (Q4) | Autor |

---

## 12. Relação com os documentos anteriores

| Documento | Situação |
|---|---|
| `01-visao.md` | Vale, com duas mudanças: **há conta opcional na nuvem** (não é mais "só no aparelho") e o foco passa a ser **livros**, não lições |
| `02-niveis.md` | **Parcialmente substituído** por 3.3 (escada de leitura). A escala CEFR fica só como rótulo; "lição de 10–15 min com gramática" deixa de ser a unidade de trabalho |
| `03-arquitetura-roadmap.md` | **Substituído** nas seções 2 e 3 por 4 e 8 deste documento. A seção 1 (o que reaproveitar) e a 4 (fluxo de produção de conteúdo, com IA declarada) continuam valendo |
| `04-telas.md` | **Substituído** pela seção 5 (Hoje · Estante · Palavras · Progresso). O diagnóstico por prova some em favor das amostras de leitura (3.1) |
| `05-separacao-do-livro.md` | Vale (histórico da separação e do site no ar) |
| `06-biblioteca-modulos.md` | Vale como **descrição do que existe hoje**; vira a base da matriz de paridade (R0) |
