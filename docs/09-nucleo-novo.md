# 09 · Núcleo do app novo (fase R1a)

> **Estado (2026-11-22):** núcleo (R1a) e dados (R1b) escritos e testados em `site/novo/`; **83 verificações passam** (29 núcleo + 41 dados + 13 narrador). **R1 concluída; R2 em andamento (R2.1 feita), ver `10-r2-narrador.md`.** O app de hoje não foi tocado. Este é o **documento vivo** do núcleo: atualizar a cada mudança e registrar no `CHANGELOG.md`.
> Contexto: `07-desenho-reconstrucao.md` (desenho), `08-paridade.md` (contrato de paridade).

## 1. O que existe

```
site/novo/                         app novo (prévia, noindex; o site atual continua em site/)
  index.html                       moldura: topo, #vista (a tela), menu inferior
  assets/css/novo.css              moldura (usa os temas de ../../assets/css/base.css e papel.css)
  assets/js/nucleo/
    app.js        App.define / App.boot / App.get / App.relatorio   registro de módulos
    eventos.js    barramento de eventos TIPADO
    armazem.js    localStorage seguro, banco do app atual, banco novo, migração com cópia, restauração
    config.js     preferências (mesma chave dd-settings do app de hoje)
    mescla.js     regras de mescla do progresso (puras; IDÊNTICAS às do app de hoje, provado por teste)
    dados.js      snapshot do progresso, aplicar mescla, exportar/importar backup, livros pendentes
    registro.js   registro de estudo por dia, relógio de tempo, espelho da leitura à prova de fechamento
    nuvem.js      conta e sincronização (Supabase, login por código, conflito, sessão, sem rede)
    rotas.js      navegação por endereço (#/hoje, #/ler/<livro>)
  assets/js/telas.js               telas (R1: molduras + tela técnica #/sistema)
  assets/js/telas-dados.js         tela #/dados: backup do progresso e conta
  assets/js/narrador/ritmo.js      (R2.1) modelo de tempo da fala: estimativa da palavra falada, velocidade aprendida por idioma+voz
  assets/js/narrador/vozes.js      (R2.1) escolha e ordenação das vozes (a mesma regra do menu de vozes da casca)
  assets/js/inicio.js              liga tudo; mostra o que falhou se algo não iniciar
site/tools/test_novo_nucleo.ps1    29 verificações do núcleo no Chrome sem tela
site/tools/test_novo_dados.ps1     41 verificações dos dados (paridade com o app de hoje)
site/tools/test_novo_narrador.ps1  13 verificações do ritmo e das vozes (oráculo do código antigo)
```
Abrir: `site/novo/index.html` (servido em `/novo/`). A tela `#/sistema` mostra a saúde do núcleo: módulos, preferências, armazenamento, versões dos bancos e cópias de segurança.

## 2. Registro de módulos (`app.js`)
- `App.define('nome', ['dependencia'], function (deps) { return api; })`; a fábrica pode ser assíncrona.
- `App.boot()` inicia **na ordem das dependências**, mesmo definidos fora de ordem. Dependência não definida ou circular vira **erro claro**; quem depende fica **`bloqueado`**; um módulo que falha **não derruba os outros**. `App.relatorio()` mostra tudo.
- Só se define módulo **antes** do `boot`; nome repetido é erro. Sem build e sem `type="module"` (navegadores de e-reader/TV): scripts comuns, na ordem do `index.html`.

## 3. Eventos (`eventos.js`)
Só existem eventos **declarados**; emitir ou escutar nome desconhecido é erro (pega erro de digitação). Um escutador que falha não impede os outros e o erro fica em `eventos.erros`. `on()` devolve a função de desligar; `uma()` dispara uma vez.
Eventos do núcleo: `config-mudou`, `rota-mudou`, `armazem-migrado`, `armazem-erro`, `dados-importados`. Cada módulo novo declara os seus com `eventos.declarar('nome', 'descrição')` (minúsculas e hífens).

## 4. Armazém (`armazem.js`): a regra que protege o site de hoje
Dois bancos, regras diferentes:

| Banco | Dono | Regra |
|---|---|---|
| `dd-ingles` (stores `meta`, `docs`, `tr`, `vocab`) | **app de hoje** | O app de hoje o abre **fixo na versão 2**. Se o núcleo novo subisse a versão, o app de hoje **pararia de abrir o banco** (erro de versão). Por isso o núcleo novo abre na versão 2 com o mesmo desenho e **NUNCA migra**, enquanto os dois apps existirem. A migração desse banco só é decidida na **R8**. Se existir uma versão maior (ex.: outro aparelho), abre como está. |
| `dd-ingles-novo` v1 (`kv`, `registro`, `escrita`, `cartoes`, `posicoes`, `plano`) | **app novo** | Tem migração de versão de verdade. |

**Migração segura** (`abrirBanco(nome, versoes)`): antes de subir a versão, **copia tudo** para `<banco>-backup` (as **3 últimas** cópias ficam) e **só então** migra. Se a cópia não puder ser guardada, a **migração é cancelada** (banco intacto, evento `armazem-erro`). `copias(banco)` lista, `restaurarCopia(banco, id)` volta ao conteúdo da cópia. Evento `armazem-migrado` informa de, para e a cópia.
Também: `ls` (localStorage seguro, cai para a memória se o navegador bloquear), `persistir()` (pede armazenamento persistente, sem exigir), `diagnostico()`.

## 5. Preferências (`config.js`)
Mesma chave **`dd-settings`** e mesmos campos do app de hoje (`theme, font, face, margin, align, rate, readLang, audioLang, voices`): o que se escolhe num app vale no outro. Cada valor é **validado e limitado** (tema só dos 4; fonte 14–28; velocidade 0,1–3 de 0,1 em 0,1; idioma só pt/en). Gravar **preserva campos que só o app antigo conhece**. Avisa `config-mudou { chave, valor, antes }`.

## 6. Rotas e telas (`rotas.js`, `telas.js`)
Navegação por hash: `#/hoje`, `#/estante`, `#/palavras`, `#/progresso`, `#/ler/<livro>`, `#/sistema`. Voltar/avançar do navegador funcionam sozinhos. Rota desconhecida cai em `#/hoje`. Uma tela que falha mostra o aviso **no lugar dela** e as outras continuam. Telas são montadas com `textContent` (**nunca** `innerHTML`): texto vindo do endereço ou dos dados nunca vira HTML (testado).
**Para criar uma tela:** `rotas.registrar('/caminho/:param', { titulo, montar(el, params) { ... } })` dentro de um módulo; para o item de menu, acrescentar em `index.html`.

## 7. Como acrescentar uma peça (receita)
1. Arquivo novo em `assets/js/` com `App.define('nome', [deps], fábrica)`; incluir o `<script>` no `index.html` **antes** de `inicio.js`.
2. Eventos próprios: `eventos.declarar(...)`. Dados: usar `armazem` (nunca `indexedDB` direto). Preferência: `config`.
3. Se mudar o desenho do banco novo: **nova versão** em `BANCO_NOVO.versoes` (nunca editar a v1); a cópia automática e o teste NU8–NU12 protegem.
4. **Nunca** mudar a versão nem o desenho de `dd-ingles` enquanto o app de hoje existir.
5. Teste novo em `test_novo_nucleo.ps1` e linha na matriz `08-paridade.md`.

## 8. Testes (`site/tools/test_novo_nucleo.ps1`)
`pwsh tools\test_novo_nucleo.ps1` (de dentro de `site/`; precisa do Chrome; termina com `tudo certo`). 29 verificações: NU1 (liga sozinho), NU2 (eventos), NU3 (preferências), NU5 (localStorage), NU6 (banco do app de hoje: versão 2 mantida e **o app antigo ainda abre o banco depois**), NU7 (banco novo), NU8–NU12 (migração, cópia, restauração, cancelamento, versão mais nova, só 3 cópias), NU13–NU17 (rotas e telas), NU18 (registro de módulos).

**Armadilha de teste (custou uma rodada):** o Chrome de teste usa **tempo virtual**. Enquanto a página espera o disco (IndexedDB), o relógio virtual corre (um `open` gastou ~100 s virtuais) e, **sem nenhum timer ativo, a página até para** e o resultado sai incompleto. Por isso o teste mantém um **batimento** (`setInterval` de 4 ms, parado no fim), usa **prazos de espera generosos** e orçamento `--virtual-time-budget=4200000`. Em teste novo que use IndexedDB: nunca esperar o disco sem esse batimento e nunca usar prazo curto.

## 9. Dados do aluno (R1b): mescla, backup, registro, nuvem

**Convivência:** enquanto os dois apps existirem, o app novo lê e grava nas **mesmas fontes** do app de hoje (localStorage `dd-ingles-log`, `dd-ingles-dia-hist`, `dd-ingles-semana-hist`, `dd-ingles-escrita`, `dd-sync-*`; IndexedDB `dd-ingles` → `vocab` e `meta`), então um enxerga o que o outro grava. O **texto dos livros nunca** entra no snapshot, no backup nem na nuvem.

| Módulo | O que faz | Regras que importam |
|---|---|---|
| `mescla` | `merge`, `limparBackup`, `stable`, `hash` (puras) | Port **linha a linha** da mescla do app de hoje. **Resultado idêntico**, provado por NUD1: 8 casos fixos + **300 pares aleatórios** (semente fixa) comparados byte a byte com `DDLab.sync.merge`. Qualquer mudança exige NUD1 verde |
| `dados` | `snapshot`, `apply`, `exportar`, `importar`, `aplicarPendentes`, `aplicarPendenteAoLivro` | Backup v1 (`{ app: 'ingles-progresso', v: 1, exportedAt, data }`) **compatível nos dois sentidos** (NUD3b/3c). Importar = mesclar, **nunca apagar**; carregar o mesmo arquivo de novo não duplica; arquivo inválido é recusado (`formato`) sem mudar nada; seções quebradas são ignoradas. Livro do backup que ainda não está no aparelho fica **pendente** (`dd-ingles-pend-docs`) e o leitor chama `aplicarPendenteAoLivro(livro)` **antes de abrir** o livro novo (posição limitada ao tamanho dele). `apply` aceita `abertos` (ids de livros abertos, que não mudam por baixo do leitor) |
| `registro` | `somar`, `salvar`, `ler`, `sequencia`, `tick`, `iniciarRelogio`, `espelho` | **Eventos** (`frase-ouvida`, `palavra-salva`, `revisao-feita`, `ditado-feito`) gravam **na hora**. **Tempos** (estudando, lendo, ouvindo) somam a cada tique e são gravados **de 2 em 2 s** e em `pagehide`, `beforeunload` e `visibilitychange`. Toda gravação **lê o storage, soma o pendente e grava**: uma mescla feita no meio nunca é sobrescrita por valor antigo da memória (o app de hoje tem essa fragilidade). Tempo só conta com livro aberto, aba visível e atividade recente (ou narração). Espelho `dd-ingles-sessao` no formato do app de hoje: vale o mais recente entre banco e espelho |
| `nuvem` | `enviarCodigo`, `entrar`, `sair`, `sincronizar`, `agendar`, `estado`, `definirAbertos` | Login **por código digitado** (nunca link). Sessão nas **mesmas chaves** do app de hoje (quem entra num já está no outro). E-mail inválido ou nuvem desligada não chamam a rede; falha do envio guarda o motivo técnico (ex.: `500: Error sending magic link email`). Gravação condicionada a `updated_at` com até 4 tentativas (conflito: relê, mescla, tenta de novo). Sessão vencida e renovação recusada: sai da conta e **mantém os dados**. Sem rede: não perde nada e sobe quando voltar |
| `telas-dados` | rota `#/dados` | Backup funciona **sem conta e sem sincronização**; aparelho que não baixa arquivo recebe o texto para copiar e há "Colar texto" |

Eventos novos declarados: `livro-aberto`, `livro-fechado`, `livro-importado`, `frase-ouvida`, `palavra-salva`, `revisao-feita`, `ditado-feito`, `escrita-salva`, `dados-aplicados`, `nuvem-estado`, `sincronia-comecando`. **Quem emite** (Leitor, Narrador, Atividades) é construído nas fases R2 a R4; o registro, a nuvem e a sincronização já escutam.

**Teste de paridade (`test_novo_dados.ps1`):** carrega `../ingles.html` numa moldura e compara as duas implementações com os mesmos dados. Se um dia a mescla do app de hoje mudar, o NUD1 falha e mostra a diferença: decidir qual está certa e atualizar as duas.

## 10. O que falta do núcleo
- **N1 e N2** (gravar posição e palavras ao fechar a aba; vale o espelho mais novo): a infraestrutura está pronta e testada (`registro.espelho`, pagehide); falta **integrar ao Leitor** (fase R2).
- **N3 a N6** (Zerar estatísticas): é do painel **Progresso** (fase R3). Atenção: o zerar precisa apagar também `dd-ingles-pend-docs` das posições pendentes de livros (limite conhecido herdado do app de hoje).
- Banco antigo `dd-ingles`: migração só na fase R8.