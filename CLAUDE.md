# Inglês do zero ao avançado — base de desenvolvimento

Site (em projeto) para estudar inglês do zero ao avançado. Repositório `8gestor/ingles-do-zero`, **privado**.
Nasceu da aba "Estudo de Inglês" do livro `8gestor/voce.algoritmo` (projeto separado, que **não deve ser alterado** por este; só na etapa final da separação a aba do livro vira um link, ver `docs/05-separacao-do-livro.md`).
**Leia este arquivo antes de mexer em qualquer coisa.**

## 1. Estado atual (atualizado em 2026-11-22)

- **Separação do livro em andamento** (decisão do autor, 22/11): dois projetos independentes, cada um em sua página. O inglês será **reconstruído** aqui. Registro completo e lista de etapas em `docs/05-separacao-do-livro.md`; histórico dia a dia em `docs/CHANGELOG.md`.
- **`site/` = aplicativo de inglês funcionando**, copiado do livro em 22/11 (todas as funções) com casca própria. Testes passam (`site/tools/`). Branch de trabalho: `feature/separacao-site`. **Ainda não publicado.**
- Endereço escolhido: subdomínio `ingles.vocealgoritmo.com.br` (depende de visibilidade do repositório/Pages e de DNS: ver `docs/05`, seção 5).
- Módulos, narração, regra de plataformas e sincronização (Supabase): `docs/06-biblioteca-modulos.md` (**documento vivo**; o do livro não é mais atualizado por este projeto). Supabase: `supabase/LEIAME.md` e `supabase/schema.sql`.
- Planejamento da reconstrução: `docs/01` a `docs/04` (itens **(?)** aguardam decisão do autor).
- `legado-livro/` é cópia **antiga** de referência (de 21/11, sem os módulos novos). **A cópia atual e completa está em `site/`.** Não editar `legado-livro/`.
- **Nunca criar domínio, Pages ou publicar sem pedido explícito.** Alterar o repositório do livro só nas etapas da seção 4 de `docs/05`.

## 2. Regras do autor (herdadas do livro, valem sempre)

1. **Publicar só com autorização.** Merge em `main` ou qualquer deploy exige pedido explícito do autor naquela fase.
2. **Perguntar antes de criar** (arquivos grandes, estruturas, repositórios) e **mostrar opções em português**.
3. **Nenhum dado pessoal (nome, e-mail) sai para serviços externos.** Consultas externas levam só o mínimo necessário.
4. **Privacidade do aluno:** texto, áudio e voz ficam no aparelho; o **progresso** é local primeiro e pode ser copiado para a nuvem (Supabase) só se a pessoa entrar com código de e-mail; **nunca** o texto dos livros. Sem analytics de terceiros. Recursos que baixam modelos são opcionais e avisam o tamanho.
5. **Fonte real ou ressalva.** Fato sem fonte conferida não entra como certeza.
6. **Declarar a participação da máquina.** Conteúdo de lições produzido com apoio de IA é declarado e passa por revisão do autor.
7. Gastar poucos tokens sem perder profundidade: ler só o necessário, testar uma vez no fim.
8. **Nenhuma função perdida e nada quebrado**, em nenhum dos dois projetos (autor, 2026-11-22).
9. **Registrar na documentação tudo o que evoluirmos** (`docs/CHANGELOG.md` + o documento do assunto), para ninguém precisar reconstruir o contexto de conversas antigas.
10. **Toda decisão nova funciona em PC, smartphone, tablet, Kindle, TV e outros aparelhos** (regra de plataformas em `docs/06`).

## 3. Máquina e ferramentas

- Windows. **Só PowerShell 7 (`pwsh`), Git Bash e Chrome.** Python e Node não existem nesta máquina.
- Testes: Chrome headless dirigido por PowerShell. Rodar de dentro de `site/`: `pwsh tools\test_ingles_modulos.ps1` e `pwsh tools\test_ingles.ps1` (app de hoje) e `pwsh tools\test_novo_nucleo.ps1` + `pwsh tools\test_novo_dados.ps1` (núcleo e dados do app novo, em `site/novo/`; este compara com o app de hoje). Os testes de tempo do app de hoje (TC5, L7, L14) oscilam com a carga da máquina: rodar sozinho antes de suspeitar do código; esperado: `tudo certo`. **Em teste que use IndexedDB no Chrome sem tela: manter um batimento de timer e prazos generosos (tempo virtual; ver `docs/09`, seção 8). Nunca mudar a versão nem o desenho do banco `dd-ingles` enquanto o app de hoje existir.** Os testes copiam `site/` para uma pasta temporária e injetam o código de teste na casca (`index.html`).
- PowerShell: aliases colidem com funções (`rd`, `r`); use nomes como `ReadFx/WriteFx/Subst`. UTF-8 **sem BOM**; guarda de não vazio antes de gravar.

## 4. Git e GitHub

- `main` é a linha principal. Trabalho novo em `feature/<tema>`. Mensagens de commit em português.
- **`git add` sempre com caminhos explícitos** (nunca `-A` nem `.`).
- Finais de linha: o Git avisa "LF will be replaced by CRLF"; é esperado no Windows.

## 5. Documentos

- `docs/01-visao.md` · `docs/02-niveis.md` · `docs/03-arquitetura-roadmap.md` · `docs/04-telas.md` · `docs/05-separacao-do-livro.md` · `docs/06-biblioteca-modulos.md` · **`docs/07-desenho-reconstrucao.md` (desenho vigente; onde contradiz 02/03/04, vale o 07)** · `docs/08-paridade.md` (matriz de paridade: contrato da reconstrução) · `docs/09-nucleo-novo.md` (núcleo do app novo, `site/novo/`) · `docs/CHANGELOG.md`.
- Atualizar o documento certo quando uma decisão for tomada, trocando o **(?)** pela decisão e a data.
