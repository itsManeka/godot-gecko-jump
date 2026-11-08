# 0002 — Tela mobile: largura logica 180 px, altura expandida, escala inteira

- **Status:** aceito
- **Data:** 2026-11-08
- **Decisores:** itsManeka + Claude

## Contexto

O jogo final e para celular. A tela atual e 180x320 (9:16) fixa, mas celulares atuais vao de 9:16 a 9:21. Pixel art
precisa de pixel quadrado (escala inteira) para nao distorcer.

## Decisao

Largura logica fixa de **180 px**; altura minima 320 e **expandida** conforme o aparelho. Godot 4:
`display/window/stretch/mode="viewport"`, `aspect="expand"`, `scale_mode="integer"`, filtro Nearest. HUD ancorado no
topo, dentro da safe area. Implementacao: issue #15.

## Consequencias

- **Positivas:** 1080/180 = 6 e 720/180 = 4, entao as larguras Android mais comuns ficam pixel-perfect
  (1080x2400 mostra 180x400). Tela alta mostra mais torre acima, o que ajuda num jogo de subida.
- **Negativas / trade-offs:** o gerador de plataformas precisa cobrir a area visivel variavel; a dificuldade nao pode
  depender da altura da tela.
- **Riscos aceitos:** larguras que nao dividem por 180 (ex.: 1170 no iPhone) ficam com barras laterais finas.

## Alternativas consideradas

- **Resolucao maior (270x480, 360x640):** mais espaco para arte e UI, mas exige refazer a escala da arte e rebalancear
  distancias; pode ser revisto na fase de arte.
- **Escala fracionaria:** preenche a tela inteira, mas distorce pixels.

Referencias: [Godot — multiple resolutions](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html),
[forum Godot — pixel art em mobile](https://forum.godotengine.org/t/what-are-the-right-resolution-aspect-mode-and-scaling-for-pixel-art-games-for-mobile/94804).
