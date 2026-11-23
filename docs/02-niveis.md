# 02 · Mapa de níveis (zero ao avançado)

> **Atualização 22/11/2026: parcialmente substituído por `07-desenho-reconstrucao.md` (seção 3.3, escada de leitura).** A escala CEFR fica só como rótulo; a lição de 10–15 min com gramática deixa de ser a unidade de trabalho (agora é o livro e o ciclo ler/ouvir/falar/escrever/contexto).
>
> Estado: **rascunho**. A estrutura segue a escala **CEFR/QECR (A1 a C2)**, de uso internacional. Os números de vocabulário e horas são **ordens de grandeza a validar**, não metas oficiais.

## Estrutura geral

| Nível | Nome no site (proposta) | O aluno consegue... (descrição resumida) |
|---|---|---|
| **Pré-A1** | Primeiros passos | Reconhecer sons e letras, dizer cumprimentos, entender palavras isoladas |
| **A1** | Iniciante | Apresentar-se, pedir e dar informações muito simples, entender frases do dia a dia ditas devagar |
| **A2** | Básico | Conversar sobre rotina, compras, família, lugares, em frases simples; ler textos curtos e previsíveis |
| **B1** | Intermediário | Lidar com a maioria das situações de viagem, falar de experiências e planos, entender o essencial de textos e falas claras |
| **B2** | Intermediário avançado | Entender textos e conversas complexas sobre temas variados, interagir com espontaneidade, escrever com clareza |
| **C1** | Avançado | Usar o idioma com flexibilidade para estudo e trabalho, entender textos longos e implícitos, expressar-se com fluência |
| **C2** | Domínio | Entender praticamente tudo, resumir e argumentar com nuance e precisão |

**Decisão do autor (2026-11-21): serão feitos os seis níveis (A1 a C2)**, com Pré-A1 como degrau de entrada. Como o novo site só será publicado quando estiver pronto, a ordem de **produção** segue de baixo para cima (Pré-A1 a C2), mas o **lançamento** só ocorre com a trilha completa. B2 a C2 se apoiam também no leitor de textos próprios.

## Habilidades por nível

Cada nível trabalha as mesmas cinco frentes, com profundidade crescente:

| Frente | O que treina | Ferramenta no site |
|---|---|---|
| Vocabulário | Palavras e expressões em contexto | Cartões com repetição espaçada |
| Gramática | Padrões, não regras soltas | Mini-lições com exemplos e exercícios |
| Leitura | Compreensão e volume | Textos graduados + leitor de textos próprios |
| Escuta | Ouvir no ritmo certo | Narração por frase, velocidade ajustável |
| Fala e escrita | Produção | Repetir, shadowing, ditado, escrita guiada |

## Critério para avançar de nível (proposta)

O aluno **não avança por tempo**, avança por **evidência**:

1. Concluiu a maior parte das lições do nível.
2. Acertou acima de um limiar em um **teste de saída** curto do nível (limiar inicial sugerido: 80%, a calibrar com uso real).
3. Tem vocabulário do nível com revisão em dia.

Sempre é possível **avançar por conta própria** depois de ver o aviso do que provavelmente vai faltar. O site orienta, não tranca.

## Diagnóstico de nível (porta de entrada)

- Teste adaptativo curto (5 a 10 minutos): começa no meio e sobe ou desce conforme os acertos.
- Mede leitura e compreensão de escuta; fala e escrita entram como autoavaliação nesta fase.
- Resultado: **nível sugerido + trilha inicial**, com a opção "começar do zero mesmo assim".
- O código legado já tem uma **estimativa de dificuldade de texto** (`ingles-nivel.js`, lista de ~1.300 palavras comuns). Serve de ponto de partida, **não substitui** uma calibração por nível real.

## Unidade de trabalho: a lição

Padrão único, para facilitar produção de conteúdo:

1. **Objetivo** em uma frase ("Pedir comida em um restaurante").
2. **Entrada**: diálogo ou texto curto, com áudio e tradução por frase.
3. **Foco**: 5 a 8 palavras ou estruturas, sempre em contexto.
4. **Prática**: repetir, ouvir e escolher, ditado, montar frase.
5. **Saída**: mini-tarefa de produção (falar ou escrever).
6. **Revisão**: o que foi aprendido entra nos cartões de repetição espaçada.

Duração-alvo: **10 a 15 minutos**.

## Quantidade de conteúdo (estimativa de trabalho, a validar)

| Nível | Lições (ordem de grandeza) | Observação |
|---|---|---|
| Pré-A1 | 10–15 | Sons, alfabeto, números, cumprimentos |
| A1 | 40–60 | Núcleo do "do zero" |
| A2 | 50–70 | |
| B1 | 60–80 | Mais leitura e escuta longa |
| B2 | 60–80 | Textos autênticos, argumentação |
| C1 | 50–70 | Nuance, registro formal e informal, textos longos |
| C2 | 40–60 | Precisão, humor, ambiguidade; muito apoio no leitor próprio |

Isso dimensiona o esforço de produção: **mais de 150 lições só até B1 e algo entre 350 e 450 nos seis níveis** (estimativa grosseira). Com a IA produzindo e o autor revisando, o gargalo passa a ser **revisão e validação**, não escrita. Daí a importância de um formato de lição simples e de um fluxo de produção e revisão (ver arquitetura).
