# 04 · Esboços das telas

> Estado: **esboço para discussão**, em texto. Celular em pé é a tela principal. Nada aqui está implementado. O objetivo é decidir fluxo e conteúdo de cada tela **antes** de qualquer código.

## Mapa de navegação

```
                        ┌──────────────┐
          primeira vez  │  Boas-vindas │
         ┌─────────────▶│ + diagnóstico│
         │              └──────┬───────┘
         │                     ▼
   ┌─────┴─────┐        ┌────────────┐      ┌───────────┐
   │   Início  │◀──────▶│   Trilha   │─────▶│   Lição   │
   │ (hoje)    │        │ (por nível)│      └─────┬─────┘
   └─────┬─────┘        └────────────┘            ▼
         │                                  ┌───────────┐
         ├─────────────▶ Revisão (cartões)  │ Prática   │
         ├─────────────▶ Leitor (meus textos)└───────────┘
         └─────────────▶ Progresso
```

Barra inferior fixa com 4 itens: **Hoje · Trilha · Ler · Progresso**. Configurações em um painel único (aparência e voz separados da experiência de estudo, como já feito no livro).

---

## Tela 1 · Boas-vindas e diagnóstico

```
┌───────────────────────────┐
│  Inglês do zero ao avançado│
│                           │
│  Quanto você já sabe?     │
│                           │
│ [ Nunca estudei ]         │  → começa no Pré-A1
│ [ Sei um pouco ]          │  → mini-teste de 5 min
│ [ Já me viro ]            │  → teste completo
│                           │
│  Seu progresso fica só    │
│  neste aparelho.          │
└───────────────────────────┘
```

Decisões: sem cadastro; a frase de privacidade aparece logo na primeira tela.

## Tela 2 · Início ("Hoje")

```
┌───────────────────────────┐
│ Hoje · 3 dias seguidos    │
│                           │
│ ▶ Continuar               │
│   A1 · Lição 12           │
│   "Pedir comida"   ~12min │
│                           │
│ ◉ Revisar 8 cartões       │
│                           │
│ ◌ Ler um texto seu        │
└───────────────────────────┘
 [Hoje] [Trilha] [Ler] [Progresso]
```

Princípio: **uma ação principal por dia**. O aluno nunca precisa decidir o que estudar.

## Tela 3 · Trilha

```
┌───────────────────────────┐
│ Pré-A1  ● ● ● ● ●  ✓      │
│ A1      ● ● ● ○ ○  12/48  │
│   ├ 1  Cumprimentos    ✓  │
│   ├ …                     │
│   └ 12 Pedir comida   ▶   │
│ A2      🔒 (pode abrir)   │
│ B1      🔒                │
└───────────────────────────┘
```

Níveis seguintes ficam **abertos com aviso**, nunca trancados à força (ver critério de avanço em `02-niveis.md`).

## Tela 4 · Lição

Fluxo linear em passos curtos, barra de progresso no topo:

```
 Passo 1 de 5 ─ Entrada
┌───────────────────────────┐
│ ▶ ouvir diálogo           │
│ "Can I have a coffee,     │
│  please?"                 │
│ Posso tomar um café,      │
│ por favor?                │
│ toque na palavra: detalhe │
│                [ Próximo ]│
└───────────────────────────┘
```

Passos: Entrada → Foco → Prática → Saída → Revisão.
Cada frase tem **ouvir**, **ouvir devagar** e **tradução**. O toque na palavra (legado) abre o cartão com opção de salvar.

## Tela 5 · Prática (exemplos de exercício)

- **Ouvir e escolher**: toca uma frase, 3 opções.
- **Ditado**: ouve e digita; mostra diferença palavra a palavra.
- **Repetir / shadowing**: ouve, depois o aluno fala; o site não "avalia a voz" nesta fase, só guia o ritmo.
- **Montar a frase**: palavras embaralhadas.

Feedback: curto, nunca pontuação punitiva.

## Tela 6 · Revisão (cartões)

```
┌───────────────────────────┐
│  8 para revisar           │
│                           │
│  "coffee"                 │
│  No contexto:             │
│  Can I have a [coffee]?   │
│                           │
│  [ Mostrar resposta ]     │
│  Errei · Difícil · Bom · Fácil
└───────────────────────────┘
```

Vem do legado (`ingles-palavras.js`), mantendo o contexto da frase.

## Tela 7 · Leitor (textos do aluno)

Biblioteca e leitor do legado, com os controles separados em **Aparência**, **Voz** e **Estudo** (grupo com traduzir, modo de treino, destacar incomuns), como já resolvido no livro.

## Tela 8 · Progresso

```
┌───────────────────────────┐
│ Sequência: 3 dias         │
│ Esta semana: ▂▅▇▃▁▆▇      │
│ Palavras ouvidas: 1.240   │
│ Cartões salvos: 86        │
│ Nível sugerido: A1 → A2   │
│                           │
│ [ Exportar meu progresso ]│
│ [ Importar progresso ]    │
└───────────────────────────┘
```

Exportar e importar são essenciais porque o armazenamento do navegador pode ser apagado.

---

## Decisões de design a tomar com o autor

1. **Identidade visual: decidido (2026-11-21), manter o visual do livro** (terminal/papel; temas Papel, Terminal, Claro, Sépia; fontes Literata, Legível, Mono). Para o aluno iniciante não se assustar, o "sem estresse" vem de: textos curtos e gentis, **tema Papel como padrão** (mais claro e calmo que o Terminal), feedback de erro neutro (sem vermelho agressivo nem som de falha), ritmo sem cronômetro e linguagem de convite ("quando quiser") em vez de cobrança. **(?)** Confirmar se o tema padrão do novo site deve ser Papel.
2. **Tom da interface**: formal, amigável, bem-humorado?
3. **Gamificação**: só sequência de dias, ou também metas e conquistas? Recomendação: **mínimo**, sem ranking.
4. **Próximo passo sugerido**: transformar este esboço em um **protótipo HTML navegável no celular** (fase F1), sem conteúdo real, para validar o fluxo antes de construir o núcleo.
