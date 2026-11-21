# Inglês do zero ao avançado — base de desenvolvimento

Site (em projeto) para estudar inglês do zero ao avançado. Repositório `8gestor/ingles-do-zero`, **privado**.
Nasceu da aba "Estudo de Inglês" do livro `8gestor/voce.algoritmo` (projeto separado, que **não deve ser alterado** por este).
**Leia este arquivo antes de mexer em qualquer coisa.**

## 1. Estado atual

- Fase **F0 · Planejamento**. Documentos em `docs/` (visão, níveis, arquitetura e roadmap, telas). Itens marcados **(?)** aguardam decisão do autor.
- **Não há site publicado e não há domínio.** Não criar domínio, nem GitHub Pages, nem qualquer publicação sem pedido explícito.
- `legado-livro/` é **referência** copiada do livro (sem o shell dele; não testada rodando sozinha). Não editar para "consertar"; reaproveitar copiando módulos para o código novo quando chegar a F2.

## 2. Regras do autor (herdadas do livro, valem sempre)

1. **Publicar só com autorização.** Merge em `main` ou qualquer deploy exige pedido explícito do autor naquela fase.
2. **Perguntar antes de criar** (arquivos grandes, estruturas, repositórios) e **mostrar opções em português**.
3. **Nenhum dado pessoal (nome, e-mail) sai para serviços externos.** Consultas externas levam só o mínimo necessário.
4. **Privacidade do aluno:** texto, áudio, voz e progresso ficam no aparelho. Sem analytics de terceiros. Recursos que baixam modelos são opcionais e avisam o tamanho.
5. **Fonte real ou ressalva.** Fato sem fonte conferida não entra como certeza.
6. **Declarar a participação da máquina.** Conteúdo de lições produzido com apoio de IA é declarado e passa por revisão do autor.
7. Gastar poucos tokens sem perder profundidade: ler só o necessário, testar uma vez no fim.

## 3. Máquina e ferramentas

- Windows. **Só PowerShell 7 (`pwsh`), Git Bash e Chrome.** Python e Node não existem nesta máquina.
- Testes: Chrome headless dirigido por PowerShell, como no livro (ver `legado-livro/tools/` como modelo).
- PowerShell: aliases colidem com funções (`rd`, `r`); use nomes como `ReadFx/WriteFx/Subst`. UTF-8 **sem BOM**; guarda de não vazio antes de gravar.

## 4. Git e GitHub

- `main` é a linha principal. Trabalho novo em `feature/<tema>`. Mensagens de commit em português.
- **`git add` sempre com caminhos explícitos** (nunca `-A` nem `.`).
- Finais de linha: o Git avisa "LF will be replaced by CRLF"; é esperado no Windows.

## 5. Documentos

- `docs/01-visao.md` · `docs/02-niveis.md` · `docs/03-arquitetura-roadmap.md` · `docs/04-telas.md`.
- Atualizar o documento certo quando uma decisão for tomada, trocando o **(?)** pela decisão e a data.
