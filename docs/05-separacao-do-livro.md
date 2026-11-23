# 05 · Separação do livro e do site de inglês

> Registro da decisão de **22/11/2026**. Atualizar este arquivo a cada etapa concluída (marcar `[x]` e a data).

## 1. Decisão do autor

- O **livro** (*Data Double*, `8gestor/voce.algoritmo`, https://vocealgoritmo.com.br/) e o **site de inglês** (`8gestor/ingles-do-zero`) passam a ser **dois projetos independentes, cada um abrindo na sua própria página**.
- O site de inglês será **reconstruído**. Por isso as coisas deixam de ficar misturadas.
- Endereço do site de inglês: **subdomínio** do domínio do livro, `ingles.vocealgoritmo.com.br` (escolhido em 22/11/2026).
- A aba "Estudo de Inglês" do livro (`vocealgoritmo.com.br/#ingles`) **vira um link** para o site novo, mas **só depois** de o site novo estar no ar e conferido (ver etapas).
- Ponto de partida do site novo: **copiar tudo o que existe hoje e reorganizar por cima** (nenhuma função se perde).
- Regras permanentes: **não perder função em nenhum dos dois projetos**, **não quebrar nada**, **registrar na documentação tudo o que evoluirmos**.

## 2. Estado das etapas

- [x] 22/11 — Branch `feature/separacao-site` criada em `ingles-do-zero`.
- [x] 22/11 — Aplicativo de inglês copiado para `site/` (58 arquivos, 3,5 MB), **a partir da versão de trabalho do livro** (inclui a melhoria, ainda não publicada, que mostra na tela o motivo técnico quando o código de acesso falha).
- [x] 22/11 — Casca própria do site (`site/index.html`, `site/assets/js/leitor.js`, `site/assets/js/sumario.js`) sem o que é só do livro.
- [x] 22/11 — Testes adaptados e passando no site novo: `site/tools/test_ingles_modulos.ps1` (todas as seções) e `site/tools/test_ingles.ps1` (núcleo, PDF real).
- [x] 22/11 — Documentação: este arquivo, `06-biblioteca-modulos.md`, `CHANGELOG.md`, `CLAUDE.md` e `README.md` atualizados.
- [x] 22/11 — Commit da branch `feature/separacao-site` (autor autorizou).
- [x] 22/11 — Autor decidiu **tornar o repositório público** (varredura feita: sem segredos; o e-mail dos commits já era público no livro). Fluxo do Pages preparado em `.github/workflows/static.yml` (publica só `site/`) e `site/CNAME` com `ingles.vocealgoritmo.com.br`; **Pages ainda desligado** até o autor autorizar o merge em `main`.
- [ ] Publicar o site novo (GitHub Pages) e conferir no ar.
- [ ] Criar o registro DNS do subdomínio e o arquivo `CNAME` (ação do autor no provedor do domínio).
- [x] 22/11 — Login por código e `progress` na nuvem testados (envio, confirmação, leitura própria, bloqueio de linha alheia).`n- [ ] Repetir o login por código **no endereço novo**, depois de publicado (o Supabase aceita qualquer origem, mas conferir).
- [ ] No livro: trocar a aba de inglês por um link para o site novo, atualizar `CLAUDE.md` do livro e arquivar o código antigo (ver seção 4).

## 3. O que veio do livro e o que mudou

### Copiado sem alteração (mesmo conteúdo do livro em 22/11/2026)

`ingles.html`, `manual-biblioteca.html`, todos os `assets/js/ingles*.js`, `manual-biblioteca.js`, `sync-config.js`, `assets/css/{base,leitor,narracao,papel}.css`, `capitulos/{ingles,manual-biblioteca}.css`, `assets/fonts/`, `assets/vendor/` (pdf.js e Piper, ~2 MB), `assets/livros/` (8 livros de domínio público, 632 KB) e `supabase/` (`schema.sql`, `LEIAME.md`).

### Casca do site (adaptada do `index.html` e do `leitor.js` do livro)

A Biblioteca **não roda sozinha**: ela fala com a casca por mensagens (`postMessage`). A casca cuida de tema, fonte, margens, voz, velocidade (0,1× a 3×), botões Legenda e Teleprompter, F11, setas, barra de andamento e menu. Por isso o site novo tem casca própria, **igual à do livro, menos**:

| Retirado (é só do livro) | Motivo |
|---|---|
| Capítulos, `structure`, botões ANT/PRÓX | o site de inglês não tem capítulos de livro |
| Raio-X (botão, painel, `raiox.js`) | é do glossário do livro |
| Estatísticas de capítulo (`estatisticas-dados.js`, `dd-progress`, `dd-listen`, `dd-stats-reset`, `dd-goto`) | contam leitura dos capítulos do livro; a Biblioteca tem as suas (`ingles-progresso.js`) |

Renomeado: a função `loadExtra` virou `loadPage`; o texto do cabeçalho passou a "INGLÊS // ESTUDO". **Mantido igual:** preferências em `localStorage` `dd-settings`, mensagens `dd-lab-sidebar`, `dd-fullscreen`, `dd-lab-immersive`, `dd-set-option`, `dd-lab-hud`, `legend-swap`, `legend-state`, `tts-state`, atalhos Esc/F11/setas e o modo imersivo do teleprompter.

### Testes adaptados (o que mudou nas verificações)

Os testes injetam o código de teste dentro da casca. No site novo a Biblioteca já abre sozinha (no livro a página inicial era um capítulo), então:
- abertura: o teste vai ao Manual e volta à Biblioteca, para a página carregar do zero com os simuladores de tradutor e voz;
- `T1`: tirada a checagem do Raio-X; `T4`: passou a conferir que o Teleprompter some no **Manual**;
- `1b`/`1c` (núcleo): o menu tem só 2 links (Biblioteca e Manual); a Biblioteca abre sozinha.

Nenhuma verificação das funções de inglês foi enfraquecida.
Resultado em 22/11/2026: **tudo certo** nos dois testes (o do livro também continua certo).

## 4. Aba de inglês do livro (plano, ainda não executado)

Decisão do autor: "trocar já por um link". Ordem segura, para nunca ficar sem lugar de estudo:

1. Site novo **no ar e conferido** (itens da seção 2).
2. No livro: `extras` de `sumario.js` passa a apontar para o endereço novo; `ingles.html` e o resto do código de inglês vão para uma pasta de arquivo (`arquivo-ingles/`) em vez de serem apagados; o histórico do Git também guarda tudo.
3. Atualizar `CLAUDE.md` e `README.md` do livro: o inglês agora mora em `ingles-do-zero`.

Impacto para quem já usa: o progresso **fica no navegador por origem**. `vocealgoritmo.com.br` e `ingles.vocealgoritmo.com.br` são origens diferentes, então o progresso local de quem estudou no livro **não aparece sozinho no endereço novo**. Caminhos: entrar com o código de acesso (nuvem) antes da troca, ou exportar/importar. **Item aberto: decidir e implementar antes de trocar a aba.**

## 5. Pontos que dependem do autor

1. **Visibilidade e Pages.** O repositório `ingles-do-zero` é **privado**. GitHub Pages em repositório privado exige plano pago; no plano gratuito é preciso torná-lo **público**. Tornar público expõe o código e o histórico (o código já é, em boa parte, público no livro). Opções: tornar público; ou publicar o conteúdo de `site/` em outro repositório público. **Decisão pendente.**
2. **DNS.** O subdomínio precisa de um registro `CNAME` (`ingles` → `8gestor.github.io`) no provedor do domínio, e de um arquivo `CNAME` em `site/` com `ingles.vocealgoritmo.com.br`. O domínio hoje **não tem registro MX** (não recebe e-mail); isso não afeta o site.
3. **Supabase (conferido em 22/11/2026).** O envio do código usa o SMTP do Gmail do autor. O erro `535` foi resolvido trocando a senha de app; o envio real, a confirmação do código e as regras de segurança por linha (RLS) foram testados e funcionam (detalhes no `CHANGELOG.md`). **Limite a vigiar:** o Gmail limita envios por dia; se o site tiver muitos alunos, trocar por um SMTP próprio (Resend, Brevo ou similar).

## 6. Regras que valem para este projeto (resumo; versão completa no `CLAUDE.md`)

Perguntar antes de criar e mostrar opções em português · publicar só com autorização · nenhuma função perdida, nada quebrado · **toda decisão nova deve funcionar em PC, smartphone, tablet, Kindle, TV e outros aparelhos** · registrar cada evolução na documentação.

## 7. DNS do subdomínio no Registro.br (passo a passo)

O DNS de `vocealgoritmo.com.br` fica no próprio Registro.br (servidores `d.sec.dns.br` e `e.sec.dns.br`, conferido em 22/11/2026). O domínio principal já aponta para o GitHub Pages (4 IPs `185.199.108–111.153`); **não mexer nesses registros**.

1. Entrar em https://registro.br → **Acessar painel** → entrar com o seu usuário.
2. Em **Domínios**, clicar em `vocealgoritmo.com.br`.
3. Em **DNS**, clicar em **Editar zona** (se pedir, é o DNS do Registro.br, o padrão).
4. **Novo registro** com: **Nome** `ingles` · **Tipo** `CNAME` · **Dados** `8gestor.github.io.` (com o ponto no fim).
5. **Salvar** e depois **Publicar alterações**. A propagação costuma levar de minutos a poucas horas.
6. Conferir: `Resolve-DnsName ingles.vocealgoritmo.com.br -Type CNAME` deve mostrar `8gestor.github.io`.
7. Depois de publicado (merge em `main` e Pages ligado), em *Settings → Pages* do repositório confirmar o domínio `ingles.vocealgoritmo.com.br` e marcar **Enforce HTTPS** quando o GitHub liberar (o certificado leva alguns minutos após o DNS responder).