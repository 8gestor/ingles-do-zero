# 01 · Visão e público

> Estado: **rascunho para o autor revisar**. Tudo aqui é proposta, não decisão fechada. Itens marcados com **(?)** precisam de resposta do autor.

## Em uma frase

Um site para quem quer aprender inglês **do zero ao avançado**, com trilha clara por níveis, prática de leitura, escuta, fala e escrita, e revisão espaçada, tudo funcionando **no próprio aparelho** do aluno.

## Quem é o aluno (hipóteses a validar)

| Perfil | Situação | O que precisa |
|---|---|---|
| Iniciante absoluto | Nunca estudou ou parou há anos | Começar sem vergonha: sons, frases úteis, vocabulário mínimo, tudo em português |
| Retomada | Sabe "um pouco", trava para falar | Diagnóstico honesto de nível e uma trilha que não repita o que já sabe |
| Intermediário travado | Entende, mas não avança | Volume de leitura e escuta no nível certo, vocabulário em contexto |
| Avançado | Quer precisão, naturalidade, textos reais | Leitura de textos próprios, escrita, nuances |

Público-base: falante de **português brasileiro**. **(?)** Há interesse em outros idiomas de origem no futuro?

## Promessa

1. **Você sabe onde está** (diagnóstico) e **para onde vai** (trilha por nível, com critério para avançar).
2. **Cada sessão cabe na sua vida**: blocos curtos, retomada fácil depois de dias parado.
3. **Você pratica as quatro habilidades**: ler, ouvir, falar, escrever.
4. **Seu progresso é seu**: fica no seu aparelho, sem conta obrigatória e sem rastreamento.

## O que o site NÃO será (por ora)

- Não é curso com certificado oficial nem promete "fluência em X dias".
- Não é rede social nem ranking competitivo.
- Não exige cadastro para estudar.
- Não envia texto, áudio ou voz do aluno para serviços externos.

## Princípios pedagógicos (proposta)

- **Entrada compreensível**: ler e ouvir bastante em um nível um pouco acima do atual (i+1).
- **Repetição espaçada** para vocabulário e frases (já existe um SM-2 enxuto no código legado).
- **Produção cedo**: repetir, imitar (shadowing) e ditado desde o nível inicial.
- **Palavras em contexto**: vocabulário sempre ligado à frase de origem, nunca lista solta.
- **Erro sem punição**: feedback curto, sem pontuação humilhante.
- **Progressão visível**: o aluno vê o que já domina.

## Princípios de privacidade (herdados do projeto do livro)

1. Nada de dado pessoal sai do aparelho: texto, áudio, voz e progresso ficam locais (IndexedDB e localStorage).
2. Consultas externas, quando existirem, levam só o mínimo (uma palavra, uma frase), nunca identidade.
3. Recursos que baixam modelos (tradutor, voz neural) avisam o que baixam e o tamanho, e são opcionais.
4. Sem analytics de terceiros.

## Princípios de produto

- Estático (HTML + JS puro), sem build, sem dependências de servidor, enquanto for possível.
- Funciona offline depois da primeira carga **(?)** meta desejada.
- Acessível: rótulos de texto nos controles, contraste, teclado, leitor de tela.
- Interface em português; o inglês aparece como conteúdo, não como ruído na interface.
- Celular em pé como tela principal; desktop como conforto.

## Perguntas em aberto para o autor

1. Modelo de negócio: gratuito, doação, pago? Isso muda arquitetura (contas, pagamento) e privacidade.
2. Quem cria o conteúdo das lições: o autor, IA com revisão, material de domínio público? Isso exige regra de verificação, como no livro.
3. Haverá conteúdo em áudio gravado por humanos ou só voz sintética?
4. Nome do projeto e do futuro domínio (o repositório provisório é `ingles-do-zero`).
