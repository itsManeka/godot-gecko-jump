# 0002 — Tela mobile: largura logica 180 px, altura expandida, escala inteira

- **Status:** aceito
- **Data:** 2026-11-08 (corrigido em 2026-11-10: `aspect` e `keep_width`, o jogo e so retrato)
- **Decisores:** itsManeka + Claude

## Contexto

O jogo final e para celular. A tela atual e 180x320 (9:16) fixa, mas celulares atuais vao de 9:16 a 9:21. Pixel art
precisa de pixel quadrado (escala inteira) para nao distorcer.

## Decisao

Largura logica fixa de **180 px**; altura minima 320 e **expandida** conforme o aparelho. O jogo e **so retrato**,
tambem no desktop e no itch.io: janela mais larga que a coluna de 180 ganha barras laterais, nunca mais area de jogo.
Godot 4: `display/window/stretch/mode="viewport"`, `aspect="keep_width"`, `scale_mode="integer"`, filtro Nearest. HUD
ancorado no topo, dentro da safe area. Implementacao: issue #15.

## Consequencias

- **Positivas:** 1080/180 = 6 e 720/180 = 4, entao as larguras Android mais comuns ficam pixel-perfect
  (1080x2400 mostra 180x400). Tela alta mostra mais torre acima, o que ajuda num jogo de subida.
- **Negativas / trade-offs:** o gerador de plataformas precisa cobrir a altura visivel variavel (a largura e sempre
  180); a dificuldade nao pode depender da altura da tela. Em janela larga sobra tela preta dos dois lados.
- **Riscos aceitos:** larguras que nao dividem por 180 (ex.: 1170 no iPhone) ficam com barras finas. A escala cai para
  o inteiro abaixo (1170 px: 6x, area de 1080x2337 em 1170x2532), entao as barras aparecem nas laterais e tambem em
  cima e embaixo, nao so nas laterais. 720x1280 (4x) e 1080x2400 (6x) fecham sem barras. Janela em paisagem mostra a
  coluna de 180 no centro: 1280x720 fica em 2x (area de 360x640, logica 180x320), com 460 px de barra em cada lateral e
  40 px em cima e embaixo.

## Notas de implementacao (issue #15)

- Janela de desktop (`window_*_override`) continua 360x640: 2x inteiro, 9:16.
- O HUD nao usa ancoras topo/direita do editor: a posicao e recalculada a partir da area visivel e da safe area a cada
  mudanca de tamanho da tela. O efeito e o mesmo de ancorar no topo.
- O gerador cobre a altura visivel: ao iniciar o nivel, linhas a cada 50 px de y=-10 ate a borda inferior (320 tem 7,
  400 tem 9, 462 tem 10). Durante a partida nasce uma linha a cada 50 px de scroll, sempre em y=-10, sem depender da
  altura da tela; por isso espacamento e dificuldade sao os mesmos em qualquer aparelho. Redimensionar a janela no meio
  da partida nao preenche a faixa nova.
- A largura jogavel vem de uma constante unica (`scripts/PlayArea.gd`): wrap do gecko, fantasma da borda, cor do pouso
  e gerador leem dela, nunca do viewport. A area visivel serve so para altura, safe area e layout do HUD.
- O placar encosta no topo da safe area. Na versao da jam ele ficava 4 px acima da borda da tela; em 180x320 ele desce
  esses 4 px, porque subir sairia da safe area em aparelho com entalhe.

## Alternativas consideradas

- **Resolucao maior (270x480, 360x640):** mais espaco para arte e UI, mas exige refazer a escala da arte e rebalancear
  distancias; pode ser revisto na fase de arte.
- **Escala fracionaria:** preenche a tela inteira, mas distorce pixels.
- **Expandir tambem a largura (stretch `expand`):** foi a configuracao inicial. Em janela larga a area logica passava
  de 180 (1280x720 mostrava 568x320) e o gerador so cobria por inteiro a coluna original; o resto recebia poucas
  plataformas. Descartada: o jogo nao tem jogabilidade de tela larga.

Referencias: [Godot — multiple resolutions](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html),
[forum Godot — pixel art em mobile](https://forum.godotengine.org/t/what-are-the-right-resolution-aspect-mode-and-scaling-for-pixel-art-games-for-mobile/94804).
