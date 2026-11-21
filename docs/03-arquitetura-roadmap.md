# 03 · Arquitetura e roadmap

> Estado: **rascunho**. Parte do código existente (`legado-livro/`), que nasceu como aba do site do livro "Data Double".

## 1. O que existe hoje (legado)

Aba "Estudo de Inglês" do livro: leitor de PDF/EPUB/texto colado, tradução frase a frase, narração, toque na palavra, vocabulário com repetição espaçada, treino (repetir, shadowing, ditado), nível do texto, progresso, voz neural opcional.

| Módulo legado | Reaproveitar? | Observação |
|---|---|---|
| `ingles-palavras.js` (cartões, SM-2 enxuto, exportar Anki) | **Sim** | Base da revisão espaçada |
| `ingles-treino.js` (repetir, shadowing, ditado) | **Sim** | Vira prática de lição |
| `ingles-voz.js` (Piper local) | **Sim, com cuidado** | Modelos de ~60 MB por idioma; manter opcional |
| `ingles-progresso.js` | **Sim** | Sequência de dias, tempo, gráfico de 7 dias |
| `ingles-nivel.js` | **Parcial** | Lista de ~1.300 palavras é pequena; precisa de lista por nível |
| `ingles-importar.js` (EPUB, texto colado) | **Sim** | Leitor de textos próprios para B1+ |
| `ingles.js` (núcleo: PDF, frases, tradução, narração) | **Parcial** | Está acoplado ao shell do livro (`postMessage` com `leitor.js`); precisa de reescrita para rodar sozinho |
| `ingles-compreensao.js` (perguntas com modelo local do Chrome) | **Opcional** | Depende de API experimental do Chrome |
| Shell do livro (`index.html`, `leitor.js`, `sumario.js`) | **Não** | Navegação própria do novo site |

**Atenção:** `legado-livro/` é **referência**. Ele foi copiado sem o shell do livro e **não foi testado rodando sozinho**.

## 2. Arquitetura proposta

Princípios: estático, sem build, sem servidor, local-first. Mesma stack do livro (HTML + JS puro), que o autor já domina e já tem bateria de testes em PowerShell + Chrome headless.

```
ingles-do-zero/
  index.html              entrada: diagnóstico ou trilha
  app/                    telas (trilha, lição, revisão, leitor, progresso)
  conteudo/               lições em dados (JSON ou JS), por nível
    pre-a1/  a1/  a2/  b1/
  assets/
    js/                   módulos (núcleo, cartões, treino, voz, progresso)
    vendor/               pdf.js, piper (locais, sem CDN)
  docs/                   planejamento
  tools/                  scripts PowerShell: validar conteúdo, testes
  legado-livro/           referência (não publicar)
```

**Dados do aluno** (somente no aparelho): IndexedDB para cartões, textos e traduções; localStorage para preferências e registro de dias.

**Conteúdo como dados**: cada lição é um arquivo estruturado (objetivo, texto, foco, exercícios). A interface só renderiza. Isso permite validar conteúdo por script antes de publicar.

### Pontos de decisão técnica (precisam do autor)

1. **Tradução**: o legado usa o tradutor embutido do Chrome (`window.Translator`), que **só existe no Chrome** e exige baixar modelo. Para um site de ensino, as traduções das lições devem ser **escritas e revisadas por humano**, não geradas na hora. O tradutor fica só para textos próprios do aluno. **(?)**
2. **Voz**: voz do navegador varia por aparelho e qualidade. Opções: manter voz do navegador + Piper opcional, ou gravar áudio das lições. **(?)**
3. **Navegadores-alvo**: celular Android/iOS e desktop. Safari/iOS tem diferenças em voz e armazenamento; precisa de teste real.
4. **Contas e sincronização entre aparelhos**: hoje não existe. Se o autor quiser, exige backend e muda a política de privacidade. Alternativa local: **exportar e importar progresso** em arquivo.

## 3. Roadmap por fases

| Fase | Entrega | Saída verificável |
|---|---|---|
| **F0 · Planejamento** (agora) | Visão, níveis, arquitetura, telas | Documentos aprovados pelo autor |
| **F1 · Protótipo de telas** | Telas navegáveis sem conteúdo real (HTML estático) | Autor navega o fluxo no celular e aprova |
| **F2 · Núcleo** | Shell próprio, armazenamento, cartões, progresso rodando sozinhos | Testes automatizados passando |
| **F3 · Primeiro nível** | Pré-A1 + A1 completos, com diagnóstico simples | Uma pessoa real completa A1 e dá retorno |
| **F4 · Prática** | Treino de fala/escuta, ditado, revisão diária | Retenção medida só localmente, no aparelho do aluno (sem enviar nada) |
| **F5 · Leitor próprio** | Leitor de PDF/EPUB/texto integrado à trilha | Importar e estudar um texto de ponta a ponta |
| **F6 · A2 a C2** | Conteúdo dos demais níveis (decisão: os seis níveis serão feitos) | Cada nível passa pela validação automática e pela revisão definida |
| **F7 · Lançamento** | Domínio próprio, publicação | Só com a trilha dos seis níveis pronta, como decidido |

Publicação nas fases iniciais: **nenhuma**. O repositório é privado e não há site no ar. Quando for útil testar no celular, usar um **preview temporário** e avisar antes.

## 4. Fluxo de produção de conteúdo (proposta)

1. Rascunho da lição **produzido pela IA** (decisão do autor: ganhar tempo, agilidade e profundidade de pesquisa), sempre **declarado** no site.
2. Revisão do autor, que **pode** ser feita lição a lição ou por amostragem **(?)**. Quanto menos revisão humana, mais forte deve ser a validação automática do passo 3.
3. Validação automática (estrutura, tamanho, palavras do nível, paridade de frases PT/EN).
4. Teste no aparelho.

Regra herdada do livro: **conteúdo gerado com apoio de IA é declarado**, e fato sem fonte entra com ressalva.

**Efeito do modelo gratuito:** sem receita, o projeto precisa de **custo operacional próximo de zero**. Isso favorece o que já foi escolhido (site estático, tudo local, sem backend, sem contas) e desfavorece áudio gravado profissional e qualquer serviço pago de voz ou de IA em tempo de uso. A IA entra **na produção do conteúdo**, não como serviço rodando para cada aluno.

**Qualidade de conteúdo gerado por IA (riscos específicos):** erros de gramática e de uso, exemplos pouco naturais, vocabulário fora do nível, e fatos errados em textos de leitura. Mitigações propostas: lista de vocabulário por nível como checagem automática, textos de leitura baseados em fontes citadas ou de domínio público, revisão humana priorizando níveis iniciais (onde o erro mais prejudica quem não tem como perceber), e canal para o aluno reportar erro **(?)**.

## 5. Riscos

| Risco | Efeito | Mitigação |
|---|---|---|
| Volume de conteúdo (150+ lições até B1) | Projeto não termina | Formato de lição simples; lançar A1 primeiro |
| Qualidade da voz sintética | Pronúncia ruim ensina errado | Avaliar voz por nível; aviso de limitação; áudio gravado nas lições-chave |
| Dependência de APIs experimentais do Chrome | Quebra em outros navegadores | Tratar como opcional, com fallback |
| Armazenamento local pode ser apagado pelo navegador | Aluno perde progresso | Exportar e importar progresso; aviso claro |
| Acoplamento do código legado ao livro | Reaproveitar custa mais que o previsto | Reescrever o núcleo em F2, copiando só módulos independentes |
