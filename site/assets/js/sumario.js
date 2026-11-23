/*
 * sumario.js — menu lateral do site de inglês.
 *
 * `extras` = as páginas do site (cada uma abre no quadro do leitor). Chave `f` = arquivo.
 * Para acrescentar uma página nova (ex.: Trilha por níveis), basta incluir uma linha aqui.
 * Títulos em inglês (TITLES_EN / CATEGORIES_EN) valem quando o idioma de leitura é EN.
 */
const extras = [
    { t: "Biblioteca", f: "ingles.html", cat: "ESTUDO DE INGLÊS" },
    { t: "Manual da Biblioteca", f: "manual-biblioteca.html", cat: "ESTUDO DE INGLÊS" }
];

const TITLES_EN = {
    "ingles.html": "Library",
    "manual-biblioteca.html": "Library Manual"
};
const CATEGORIES_EN = {
    "ESTUDO DE INGLÊS": "ENGLISH STUDY"
};
