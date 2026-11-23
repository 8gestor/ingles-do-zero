# 09 · Núcleo do app novo (fase R1a)

> **Estado (2026-11-22):** núcleo escrito e testado em `site/novo/`; **32 verificações passam** (`site/tools/test_novo_nucleo.ps1`). O app de hoje não foi tocado. Este é o **documento vivo** do núcleo: atualizar a cada mudança e registrar no `CHANGELOG.md`.
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
    rotas.js      navegação por endereço (#/hoje, #/ler/<livro>)
  assets/js/telas.js               telas (R1: molduras + tela técnica #/sistema)
  assets/js/inicio.js              liga tudo; mostra o que falhou se algo não iniciar
site/tools/test_novo_nucleo.ps1    32 verificações no Chrome sem tela
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
`pwsh tools\test_novo_nucleo.ps1` (de dentro de `site/`; precisa do Chrome; termina com `tudo certo`). 32 verificações: NU1 (liga sozinho), NU2 (eventos), NU3 (preferências), NU5 (localStorage), NU6 (banco do app de hoje: versão 2 mantida e **o app antigo ainda abre o banco depois**), NU7 (banco novo), NU8–NU12 (migração, cópia, restauração, cancelamento, versão mais nova, só 3 cópias), NU13–NU17 (rotas e telas), NU18 (registro de módulos).

**Armadilha de teste (custou uma rodada):** o Chrome de teste usa **tempo virtual**. Enquanto a página espera o disco (IndexedDB), o relógio virtual corre (um `open` gastou ~100 s virtuais) e, **sem nenhum timer ativo, a página até para** e o resultado sai incompleto. Por isso o teste mantém um **batimento** (`setInterval` de 4 ms, parado no fim), usa **prazos de espera generosos** e orçamento `--virtual-time-budget=4200000`. Em teste novo que use IndexedDB: nunca esperar o disco sem esse batimento e nunca usar prazo curto.

## 9. O que ainda NÃO está no núcleo (R1b)
Das áreas da matriz (`08-paridade.md`) marcadas **R1**, ficam para a próxima etapa: **BK** (backup por arquivo no app novo), **SY** (conta e sincronização), **N** e **S** (gravação à prova de fechamento da aba e estatísticas na hora). A mescla (`merge`) existe hoje dentro de `ingles-sync.js`; será **portada para um módulo próprio e testada contra a do app de hoje** (mesmas entradas, mesmas saídas), para o backup v1 continuar compatível nos dois sentidos.
