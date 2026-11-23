# Registro de evolução (CHANGELOG)

> Uma entrada por dia de trabalho, da mais nova para a mais antiga. Escreva **o que mudou, por quê e como conferir**. Mantém o autor e o Claude sem precisar reler conversas antigas.

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
