# Handoff de design: telas novas (fundacao visual)

Design provisorio das telas de pausa, opcoes, tutorial e dica de toque (issues #11 e #12). A arte final e outra
entrega; este documento fixa so o que as telas compartilham: paleta, fonte, botao, alvo de toque, safe area e ancoragem.
Legibilidade no aparelho e classe (c) do [ADR 0006](../adr/0006-oraculo-de-jogo-em-3-camadas.md), julgada no QA final do epic, nao aqui.

Pre-requisito ausente: nao ha tema/fonte de UI alem de `Button.tres`. Hoje existe um unico estilo de botao
(`ressources/Button.tres`), nenhum tema de UI e nenhum slider. Este documento define o estilo; nada dele esta
implementado.

Base: largura logica fixa de 180 px, altura visivel minima 320, expandida em aparelho alto (1080x2400 mostra 180x400),
so retrato ([ADR 0002](../adr/0002-tela-mobile-largura-180.md)). Toque: metade esquerda/direita da tela
([ADR 0003](../adr/0003-controle-de-um-polegar.md)). Nenhuma medida usa largura diferente de 180 e nenhuma depende da
altura para dificuldade.

## 1. Paleta

Todo valor de cor tem origem no repo ou deriva de um valor dele por decisao registrada; nao ha cor nova.

| Uso | Valor | Origem |
|---|---|---|
| Amarelo (cor do gecko e das plataformas) | `#f6db61` | `scripts/Enums.gd:26` |
| Verde | `#79cf5a` | `scripts/Enums.gd:28` |
| Azul | `#5987e9` | `scripts/Enums.gd:30` |
| Vermelho | `#ec4848` | `scripts/Enums.gd:32` |
| Branco (fallback de cor) | `#ffffff` | `scripts/Enums.gd:33` |
| Fundo de botao | `#5b8a4a` | `ressources/Button.tres:8` (`Color(0.356863, 0.541176, 0.290196)` convertido) |
| Contorno de texto e de botao pressionado/foco | `#000000` | `scenes/Stage.tscn:70,90,103,117` (`font_outline_color` `Color(0, 0, 0, 1)`) |

Tokens nomeados para o que o repo nao define (nenhum valor de cor novo: todos derivam da tabela acima):

| Token | Valor | Origem |
|---|---|---|
| Fundo do overlay | `#000000` com 60% de opacidade (alpha 0.6) | decisao do dono, 2026-11-11, derivado de `#000000` |
| Cor do texto | `#ffffff` com contorno `#000000` (mesma regra de contorno da secao 2) | decisao do dono, 2026-11-11, derivado de `#ffffff` |
| Borda do botao | `#000000` | decisao do dono, 2026-11-11, derivado de `#000000` |
| Trilha do slider | `#000000` | decisao do dono, 2026-11-11, derivado de `#000000` |
| Preenchimento do slider | `#5b8a4a` | decisao do dono, 2026-11-11, derivado de `#5b8a4a` |
| Cursor do slider | `#ffffff` com contorno `#000000` (nao depende so de cor) | decisao do dono, 2026-11-11, derivado de `#ffffff` |

Hoje os rotulos nao tem `font_color` (`scenes/Stage.tscn:70-120`), `ressources/Button.tres` tem borda de 1 px sem
`border_color` e o projeto nao tem slider: estes tokens passam a valer quando a tela nova os implementar.

Regra de uso: qualquer das 4 cores do gecko pode estar atras de um elemento de UI, entao nenhum elemento de UI depende
dessas cores para ser lido. Botao = fundo `#5b8a4a` + contorno preto, nunca uma das 4 cores do jogo. Cor nunca e a unica
pista: toda distincao por cor leva tambem rotulo, forma ou posicao. As plataformas do jogo hoje se distinguem so por
cor; isso e uma lacuna do jogo, fora deste handoff, e as telas novas nao inventam padrao de plataforma.

## 2. Tipografia

- Fonte: `res://fonts/alterebro-pixel-font.ttf`, a unica do projeto.
- Tamanhos permitidos: **36** (placar, `Stage.tscn:73`), **26** (Play, `Stage.tscn:93`) e **20** (Last/Best,
  `Stage.tscn:106,120`). Nenhum tamanho novo; texto de tela nova usa um desses. Menor que 20 nao e permitido (pixel art
  em 180 px perde legibilidade).
- Contorno preto `#000000`: 2 px no tamanho 36, 1 px nos tamanhos 26 e 20 (`Stage.tscn:71,91,104,118`). Texto novo repete
  a mesma regra.
- Largura de glifo e altura de linha por tamanho nao estao no repo: quem implementa mede no Godot antes de fechar
  contagem de linhas por card.

## 3. Botao

Estilo base: `ressources/Button.tres` (`StyleBoxFlat`, raio 4, borda 1 px, `content_margin_bottom` 4, fundo `#5b8a4a`).
Hoje `normal`, `hover`, `pressed`, `focus` e `disabled` apontam para o mesmo recurso (`Stage.tscn:85-89`), logo os
estados abaixo sao proposta nova.

| Estado | Fundo | Contorno | Conteudo | Pista nao-cor |
|---|---|---|---|---|
| normal | `#5b8a4a` | borda de 1 px (`Button.tres`) | rotulo na posicao normal | rotulo |
| pressed | `#5b8a4a` | borda de 2 px `#000000` | rotulo 1 px abaixo | deslocamento + borda mais grossa |
| disabled | `#5b8a4a` com 50% de opacidade | borda de 1 px | rotulo com 50% de opacidade | opacidade reduzida; acao nao dispara |
| focus (teclado/joypad) | `#5b8a4a` | moldura externa de 2 px `#000000`, 1 px fora do botao | marcador `>` antes do rotulo | marcador `>` + moldura |

Nenhum estado troca o fundo por outra cor: o par fundo/contorno e o mesmo, o que muda e forma, deslocamento e opacidade.
Opacidade nao e cor nova.

### Alvo minimo de toque

**Minimo 24x24 px logicos**, medido no retangulo que responde ao toque (nao so no desenho), com folga minima de 2 px
entre dois alvos vizinhos.

Justificativa: em 1080 px de largura 1 px logico = 6 px fisicos (1080 / 180). A recomendacao usual de ~48 dp em densidade
~2,6 equivale a ~125 px fisicos, ~21 px logicos. 24 px logicos = 144 px fisicos, com margem de ~15% sobre o minimo usual.
Em 720 px de largura 1 px logico = 4 px fisicos e 24 px logicos = 96 px fisicos, abaixo de 48 dp em densidade alta;
aceito como risco, pois o alvo real de jogo e o aparelho de 1080 px e o botao pode crescer sem mudar este minimo.

## 4. Safe area e ancoragem

### Simbolos

A safe area vem de `VisibleArea.current_safe_rect` e chega ao layout como `safe` (`scenes/Stage.gd:55,71`). Margens em
px logicos:

| Simbolo | Definicao |
|---|---|
| `s_top` | `safe.position.y` |
| `s_bottom` | `H - safe.end.y` |
| `s_left` | `safe.position.x` |
| `s_right` | `180 - safe.end.x` |
| `H` | altura visivel (320 ou 400; 462 e citado no ADR 0002 e segue as mesmas formulas) |
| `U` | altura util = `H - s_top - s_bottom` |

Em 180x320 e 180x400 sem entalhe os quatro `s_*` valem 0. Exemplo ilustrativo com entalhe (nao medido em aparelho):
`s_top` = 20 e `s_bottom` = 6, dando `U` = 294 em 320 e `U` = 374 em 400. A largura da coluna e sempre 180; a faixa
horizontal util e `[s_left, 180 - s_right]`.

### Classes de ancoragem

Todo elemento de tela nova declara uma destas classes e usa a formula dela. Medidas sao da borda de cima do elemento
(`y0`) com altura `h`.

| Classe | Referencia | Formula de `y0` |
|---|---|---|
| topo | `safe.position.y` (como `_layout_hud`, `Stage.gd:71-78`) | `y0 = s_top + o`, `o` = offset a partir do topo |
| centro | meio da altura util | `y0 = s_top + (U - h) / 2` |
| base | `safe.end.y` | `y0 = (H - s_bottom) - m - h`, `m` = margem ate a base |

Horizontal: elemento centrado usa `x0 = s_left + (180 - s_left - s_right - w) / 2`; elemento colado a direita usa
`x1 = 180 - s_right - 2` (o mesmo `HUD_RIGHT_MARGIN` de 2 do placar, `Stage.gd:12,73`).

### Tabela de ancoragem

Valores com `s_top` = `s_bottom` = 0. Com `s_top` > 0, soma-se `s_top` as linhas de topo e de centro; com `s_bottom` > 0,
subtrai-se `s_bottom` de `H` nas linhas de base e a conta de `U` ja o considera.

| Elemento | Classe | Formula de `y0` | 180x320 | 180x400 |
|---|---|---|---|---|
| Placar (existente) | topo | `s_top + 0` | y[0, 30] | y[0, 30] |
| Play, menu (existente) | topo | `s_top + 147` | y[147, 173] | y[147, 173] |
| Last, menu (existente) | topo | `s_top + 230` | y[230, 247] | y[230, 247] |
| Best, menu (existente) | topo | `s_top + 248` | y[248, 265] | y[248, 265] |
| Bloco centrado, `h` = 100 (exemplo de formula) | centro | `s_top + (U - 100) / 2` | y0 = 110 | y0 = 150 |
| Bloco de base, `h` = 40 e `m` = 8 (exemplo de formula) | base | `(H - s_bottom) - 8 - 40` | y0 = 272 | y0 = 352 |

Elementos de topo ficam iguais nas duas alturas: o menu atual nao se re-centraliza em tela alta, ele fica no topo e a
sobra aparece embaixo. As linhas de exemplo mostram a formula resolvida; cada tela nova aplica a formula ao seu `h` e
`m` reais e registra o resultado nas duas colunas.

Regra de escolha: o que o polegar alcanca (dica de toque, acoes primarias) fica na metade inferior, classe base ou
centro; o que e informacao ou acao rara fica no topo ([ADR 0003](../adr/0003-controle-de-um-polegar.md)). Nenhum
elemento muda de tamanho, espaco ou velocidade com a altura (ADR 0002).

## 5. Zonas ocupadas (proibidas para elemento novo)

Retangulos em px logicos, `y` relativo a `s_top`, com `s_left` e `s_right` = 0 (com margem, o placar vai de
`41 - s_right` ate `178 - s_right`):

| Ocupante | Retangulo | Visivel quando | Origem |
|---|---|---|---|
| Placar (Pontos) | x[41, 178] y[0, 30] | sempre | `Stage.gd:13,14,73-74` (`right` = 180 - 2, largura 137) |
| Play | x[62, 118] y[147, 173] | so no menu | `Stage.gd:15-17,75-76` |
| Last | x[0, 180] y[230, 247] | so no menu | `Stage.gd:18-19,77` |
| Best | x[0, 180] y[248, 265] | so no menu | `Stage.gd:20-21,78` |
| Faixa de derrota | fora da area visivel, abaixo de `H` | sempre | `Stage.gd:10,66` (espessura 20) |

Elemento novo de partida nao cobre o placar. Elemento novo de menu ou de overlay nao cobre Play, Last nem Best enquanto
eles estiverem visiveis. O jogo em si ocupa a coluna inteira de 180: o toque de jogo cobre a tela toda, e qualquer
excecao (botao de pausa) e declarada como zona morta na tela dona dela.

## 6. Limites desta fundacao

- Nao ha acao `pause` no `project.godot` (so `ui_left`, `ui_right`, `jump`); teclas de pausa citadas nas telas sao
  previsao.
- Hoje nenhuma tela trata toque alem do clique/toque emulado do botao Play.
- Nao ha slider, tema de UI nem fonte alem da do placar; os estados e o alvo de toque desta pagina sao proposta, a
  confirmar no QA final.
