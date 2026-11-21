# 01 · Visão e público

> Estado: **rascunho com decisões iniciais do autor (2026-11-21)**. As decisões estão na seção "Decisões do autor" no fim. Itens marcados com **(?)** ainda precisam de resposta.

## Em uma frase

Um site para quem quer aprender inglês **do zero ao avançado**, com trilha clara por níveis, prática de leitura, escuta, fala e escrita, e revisão espaçada, tudo funcionando **no próprio aparelho** do aluno.

## Quem é o aluno (hipóteses a validar)

| Perfil | Situação | O que precisa |
|---|---|---|
| Iniciante absoluto | Nunca estudou ou parou há anos | Começar sem vergonha: sons, frases úteis, vocabulário mínimo, tudo em português |
| Retomada | Sabe "um pouco", trava para falar | Diagnóstico honesto de nível e uma trilha que não repita o que já sabe |
| Intermediário travado | Entende, mas não avança | Volume de leitura e escuta no nível certo, vocabulário em contexto |
| Avançado | Quer precisão, naturalidade, textos reais | Leitura de textos próprios, escrita, nuances |

Público-base: falante de **português brasileiro**. **(?)** Há interesse em outros idiomas de origem no futuro? (não decidido; não é prioridade agora)

## Promessa

1. **Você sabe onde está** (diagnóstico) e **para onde vai** (trilha por nível, com critério para avançar).
2. **Cada sessão cabe na sua vida**: blocos curtos, retomada fácil depois de dias parado.
3. **Você pratica as quatro habilidades**: ler, ouvir, falar, escrever.
4. **Seu progresso é seu**: fica no seu aparelho, sem conta obrigatória e sem rastreamento.
5. **É gratuito e sem estresse**: sem cobrança, sem pressão, sem ranking, sem gastar horrores para aprender.

## O que o site NÃO será (por ora)

- **Não é pago.** Sem assinatura, sem paywall, sem anúncios que dependam de rastrear o aluno.
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

## Decisões do autor (2026-11-21)

1. **Modelo: gratuito.** O objetivo é ensinar de forma que as pessoas aprendam **sem estresse e sem gastar horrores**. Consequências para o projeto: nada de contas, pagamento ou backend pago; hospedagem estática gratuita; tudo que roda no aparelho do aluno; recursos pesados (voz neural, modelos) sempre opcionais. Como não há receita, **custo operacional deve ficar perto de zero**.
2. **Conteúdo: a IA produz, o autor pode revisar.** A IA é usada para ganhar tempo, agilidade e profundidade de pesquisa; os materiais **podem ser revisados** pelo autor. Regras que continuam valendo: conteúdo com apoio de IA é **declarado** no site, e fato sem fonte conferida entra com ressalva. **(?)** Definir o nível de revisão: toda lição, ou por amostragem com validação automática em todas (ver `03-arquitetura-roadmap.md`, seção 4).
3. **Níveis: os seis (A1 a C2)** serão feitos, com Pré-A1 como degrau de entrada (ver `02-niveis.md`).
4. **Visual: manter** o visual do livro (estética terminal/papel, temas Papel/Terminal/Claro/Sépia). A suavidade "sem estresse" vem do **tom dos textos, do ritmo e das cores de feedback**, não de trocar a identidade (ver `04-telas.md`).

## Perguntas ainda em aberto

1. Haverá conteúdo em áudio gravado por humanos ou só voz sintética? (impacta custo: gravação não é gratuita)
2. Nome do projeto e do futuro domínio (o repositório provisório é `ingles-do-zero`; domínio só quando o projeto estiver pronto).
3. Como o projeto se sustenta no longo prazo sendo gratuito (tempo do autor, doação voluntária, apoio institucional)? Não precisa ser decidido agora, mas afeta a manutenção.