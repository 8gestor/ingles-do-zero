/*
 * sumario.js — menu lateral do site de inglês.
 *
 * `extras` = as páginas do site (cada uma abre no quadro do leitor). Chave `f` = arquivo; `id` = nome na URL (#id);
 * `pane` = seção da Biblioteca (ingles.html) que o item abre: o menu lateral é quem organiza as seções
 * (BIBLIOTECA, LEITOR / SUBIR PDF, PROGRESSO, VOCABULÁRIO, CONFIGURAÇÕES), a página só mostra a escolhida.
 * Para acrescentar uma página nova, basta incluir uma linha aqui.
 * Títulos em inglês (TITLES_EN / CATEGORIES_EN, pela chave `id`) valem quando o idioma de leitura é EN.
 */
const extras = [
    { id: "ingles", t: "Biblioteca", f: "ingles.html", pane: "lib", cat: "ESTUDO DE INGLÊS" },
    { id: "ingles-leitor", t: "Leitor / Subir PDF", f: "ingles.html", pane: "up", cat: "ESTUDO DE INGLÊS" },
    { id: "ingles-progresso", t: "Progresso", f: "ingles.html", pane: "prog", cat: "ESTUDO DE INGLÊS" },
    { id: "ingles-vocabulario", t: "Vocabulário", f: "ingles.html", pane: "vocab", cat: "ESTUDO DE INGLÊS" },
    { id: "ingles-configuracoes", t: "Configurações", f: "ingles.html", pane: "cfg", cat: "ESTUDO DE INGLÊS" },
    { id: "manual-biblioteca", t: "Manual da Biblioteca", f: "manual-biblioteca.html", cat: "AJUDA" }
];

const TITLES_EN = {
    "ingles": "Library",
    "ingles-leitor": "Reader / Upload PDF",
    "ingles-progresso": "Progress",
    "ingles-vocabulario": "Vocabulary",
    "ingles-configuracoes": "Settings",
    "manual-biblioteca": "Library Manual"
};
const CATEGORIES_EN = {
    "ESTUDO DE INGLÊS": "ENGLISH STUDY",
    "AJUDA": "HELP"
};