# Inglês do zero ao avançado (nome provisório)

Site para estudar inglês do **zero ao avançado**: trilha por níveis, leitura, escuta, fala, escrita e revisão espaçada, com os dados do aluno guardados só no próprio aparelho.

**Estado (22/11/2026):** em separação do livro. `site/` já contém o aplicativo de inglês funcionando (testes passando), **ainda não publicado**. Endereço escolhido: `ingles.vocealgoritmo.com.br` (pendente de Pages e DNS). Repositório **privado**. Ver `docs/05-separacao-do-livro.md`.

Este projeto nasceu da aba "Estudo de Inglês" do livro *Data Double* (`8gestor/voce.algoritmo`, https://vocealgoritmo.com.br/). Os dois projetos são **independentes**: este não altera o livro, exceto na etapa final em que a aba de inglês do livro vira um link para cá.

## Planejamento

| Documento | Conteúdo |
|---|---|
| [`docs/01-visao.md`](docs/01-visao.md) | Público, promessa, o que não será, princípios |
| [`docs/02-niveis.md`](docs/02-niveis.md) | Mapa de níveis (Pré-A1 a C2), critério de avanço, formato da lição |
| [`docs/03-arquitetura-roadmap.md`](docs/03-arquitetura-roadmap.md) | O que reaproveitar do legado, arquitetura, fases, riscos |
| [`docs/04-telas.md`](docs/04-telas.md) | Esboços das telas e fluxo |
| [`docs/07-desenho-reconstrucao.md`](docs/07-desenho-reconstrucao.md) | **Desenho da reconstrução** (imersão em livros): método, jornada, arquitetura, telas, roadmap |
| [`docs/08-paridade.md`](docs/08-paridade.md) | **Matriz de paridade**: as 279 verificações de hoje que o app novo precisa cumprir |
| [`docs/09-nucleo-novo.md`](docs/09-nucleo-novo.md) | **Núcleo do app novo** (R1a): módulos, eventos, armazém, rotas, como acrescentar peças |
| [`docs/05-separacao-do-livro.md`](docs/05-separacao-do-livro.md) | Decisão de separar, etapas, o que mudou, pendências |
| [`docs/06-biblioteca-modulos.md`](docs/06-biblioteca-modulos.md) | Módulos da Biblioteca, narração, plataformas, sincronização |
| [`docs/CHANGELOG.md`](docs/CHANGELOG.md) | Registro dia a dia do que evoluiu |

Cada documento tem perguntas marcadas com **(?)** que dependem do autor.

## Código

- [`site/`](site/): o aplicativo de inglês (Biblioteca, narração, teleprompter, vocabulário, progresso, sincronização). Testes: `cd site; pwsh tools\test_ingles_modulos.ps1`.
- [`supabase/`](supabase/LEIAME.md): banco do progresso na nuvem (esquema e passo a passo).
- [`legado-livro/`](legado-livro/README.md): cópia **antiga** de referência (21/11); a atual está em `site/`.
- `CLAUDE.md`: regras e contexto de desenvolvimento (lido no início de cada sessão).
