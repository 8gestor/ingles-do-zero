# legado-livro — referência

Cópia do código da aba **Estudo de Inglês** do livro *Data Double*, tirada de `8gestor/voce.algoritmo` no commit `d25d4b8` (21/11/2026).

**Isto é material de referência, não o site novo.**

- Foi copiado **sem o shell do livro** (`index.html`, `leitor.js`, `sumario.js`). O núcleo `assets/js/ingles.js` conversa com esse shell por `postMessage` (HUD, narração, idioma), então **não foi testado rodando sozinho**.
- Os testes em `tools/` (`test_ingles.ps1`, `test_ingles_modulos.ps1`) abrem o livro completo e **não funcionam aqui sem o repositório do livro**. Servem como modelo de como testar.
- Fica em pasta própria para não se misturar com o código novo. Quando o núcleo novo existir (fase F2), módulos úteis são **copiados** para ele, e esta pasta pode ser removida.
- O livro continua com a aba funcionando em https://vocealgoritmo.com.br/ até o novo site ficar pronto. Correções feitas lá **não** vêm para cá automaticamente.

Inventário dos módulos e o que reaproveitar: `../docs/03-arquitetura-roadmap.md`.
