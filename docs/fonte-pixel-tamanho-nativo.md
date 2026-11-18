# Fonte pixel: tamanho nativo e escala de UI

Fonte: `fonts/alterebro-pixel-font.ttf`. Constantes: `UiHelpers.FONTE_NATIVO` e `UiHelpers.TAMANHOS_UI`.

## Medicao (metricas do TTF, `fontTools`)

- `head.unitsPerEm = 1024`; ascent/descent = 704/-128; altura de maiuscula = 448; x-height = 320.
- Todas as coordenadas Y e X dos contornos caem em multiplos de 64 unidades; advance = 320 (5 px) por glifo.
- 1 pixel da fonte = 64/1024 em = 1/16 em, entao o **tamanho nativo e 16 px por em** (maiuscula = 7 px, x-height = 5 px).

## Escala

- Multiplos inteiros: 16, 32, 48. Os tamanhos antigos 20 (1,25x), 26 (1,625x) e 36 (2,25x) nao sao multiplos: cada
  pixel da fonte cai em fracao de pixel de tela e as hastes alternam 1 e 2 px.
- Escala aprovada: **titulo/placar = 32, botao = 32 (ou 16 se a altura nao comportar), texto/Last/Best/Opcoes = 16**.
  48 nao e necessario; 32 em "Melhor pontuacao: 1000" estoura os 180 px.
- Import aplicado em `fonts/alterebro-pixel-font.ttf.import`: hinting 0 (None), subpixel_positioning 0 (Disabled),
  oversampling 1.0, antialiasing 0. Papeis: `UiHelpers.TAMANHO_TITULO` 32, `TAMANHO_BOTAO` 32 (Play), `TAMANHO_TEXTO` 16.

## Prova

A medicao vem do TTF (acima). O render headless de uma palavra em cada tamanho candidato nao foi feito nesta task
(ver nota de entrega); o GUT `test_ui_helpers.gd` trava a escala.
