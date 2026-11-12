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

| Uso                                           | Valor     | Origem                                                                        |
| --------------------------------------------- | --------- | ----------------------------------------------------------------------------- |
| Amarelo (cor do gecko e das plataformas)      | `#f6db61` | `scripts/Enums.gd:26`                                                         |
| Verde                                         | `#79cf5a` | `scripts/Enums.gd:28`                                                         |
| Azul                                          | `#5987e9` | `scripts/Enums.gd:30`                                                         |
| Vermelho                                      | `#ec4848` | `scripts/Enums.gd:32`                                                         |
| Branco (fallback de cor)                      | `#ffffff` | `scripts/Enums.gd:33`                                                         |
| Fundo de botao                                | `#5b8a4a` | `ressources/Button.tres:8` (`Color(0.356863, 0.541176, 0.290196)` convertido) |
| Contorno de texto e de botao pressionado/foco | `#000000` | `scenes/Stage.tscn:70,90,103,117` (`font_outline_color` `Color(0, 0, 0, 1)`)  |

Tokens nomeados para o que o repo nao define (nenhum valor de cor novo: todos derivam da tabela acima):

| Token                   | Valor                                                                 | Origem                                             |
| ----------------------- | --------------------------------------------------------------------- | -------------------------------------------------- |
| Fundo do overlay        | `#000000` com 60% de opacidade (alpha 0.6)                            | decisao do dono, 2026-11-11, derivado de `#000000` |
| Cor do texto            | `#ffffff` com contorno `#000000` (mesma regra de contorno da secao 2) | decisao do dono, 2026-11-11, derivado de `#ffffff` |
| Borda do botao          | `#000000`                                                             | decisao do dono, 2026-11-11, derivado de `#000000` |
| Trilha do slider        | `#000000`                                                             | decisao do dono, 2026-11-11, derivado de `#000000` |
| Preenchimento do slider | `#5b8a4a`                                                             | decisao do dono, 2026-11-11, derivado de `#5b8a4a` |
| Cursor do slider        | `#ffffff` com contorno `#000000` (nao depende so de cor)              | decisao do dono, 2026-11-11, derivado de `#ffffff` |

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

| Estado                 | Fundo                          | Contorno                                              | Conteudo                     | Pista nao-cor                        |
| ---------------------- | ------------------------------ | ----------------------------------------------------- | ---------------------------- | ------------------------------------ |
| normal                 | `#5b8a4a`                      | borda de 1 px (`Button.tres`)                         | rotulo na posicao normal     | rotulo                               |
| pressed                | `#5b8a4a`                      | borda de 2 px `#000000`                               | rotulo 1 px abaixo           | deslocamento + borda mais grossa     |
| disabled               | `#5b8a4a` com 50% de opacidade | borda de 1 px                                         | rotulo com 50% de opacidade  | opacidade reduzida; acao nao dispara |
| focus (teclado/joypad) | `#5b8a4a`                      | moldura externa de 2 px `#000000`, 1 px fora do botao | marcador `>` antes do rotulo | marcador `>` + moldura               |

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

| Simbolo    | Definicao                                                                        |
| ---------- | -------------------------------------------------------------------------------- |
| `s_top`    | `safe.position.y`                                                                |
| `s_bottom` | `H - safe.end.y`                                                                 |
| `s_left`   | `safe.position.x`                                                                |
| `s_right`  | `180 - safe.end.x`                                                               |
| `H`        | altura visivel (320 ou 400; 462 e citado no ADR 0002 e segue as mesmas formulas) |
| `U`        | altura util = `H - s_top - s_bottom`                                             |

Em 180x320 e 180x400 sem entalhe os quatro `s_*` valem 0. Exemplo ilustrativo com entalhe (nao medido em aparelho):
`s_top` = 20 e `s_bottom` = 6, dando `U` = 294 em 320 e `U` = 374 em 400. A largura da coluna e sempre 180; a faixa
horizontal util e `[s_left, 180 - s_right]`.

### Classes de ancoragem

Todo elemento de tela nova declara uma destas classes e usa a formula dela. Medidas sao da borda de cima do elemento
(`y0`) com altura `h`.

| Classe | Referencia                                               | Formula de `y0`                                        |
| ------ | -------------------------------------------------------- | ------------------------------------------------------ |
| topo   | `safe.position.y` (como `_layout_hud`, `Stage.gd:71-78`) | `y0 = s_top + o`, `o` = offset a partir do topo        |
| centro | meio da altura util                                      | `y0 = s_top + (U - h) / 2`                             |
| base   | `safe.end.y`                                             | `y0 = (H - s_bottom) - m - h`, `m` = margem ate a base |

Horizontal: elemento centrado usa `x0 = s_left + (180 - s_left - s_right - w) / 2`; elemento colado a direita usa
`x1 = 180 - s_right - 2` (o mesmo `HUD_RIGHT_MARGIN` de 2 do placar, `Stage.gd:12,73`).

### Tabela de ancoragem

Valores com `s_top` = `s_bottom` = 0. Com `s_top` > 0, soma-se `s_top` as linhas de topo e de centro; com `s_bottom` > 0,
subtrai-se `s_bottom` de `H` nas linhas de base e a conta de `U` ja o considera.

| Elemento                                               | Classe | Formula de `y0`           | 180x320     | 180x400     |
| ------------------------------------------------------ | ------ | ------------------------- | ----------- | ----------- |
| Placar (existente)                                     | topo   | `s_top + 0`               | y[0, 30]    | y[0, 30]    |
| Play, menu (existente)                                 | topo   | `s_top + 147`             | y[147, 173] | y[147, 173] |
| Last, menu (existente)                                 | topo   | `s_top + 230`             | y[230, 247] | y[230, 247] |
| Best, menu (existente)                                 | topo   | `s_top + 248`             | y[248, 265] | y[248, 265] |
| Bloco centrado, `h` = 100 (exemplo de formula)         | centro | `s_top + (U - 100) / 2`   | y0 = 110    | y0 = 150    |
| Bloco de base, `h` = 40 e `m` = 8 (exemplo de formula) | base   | `(H - s_bottom) - 8 - 40` | y0 = 272    | y0 = 352    |

Elementos de topo ficam iguais nas duas alturas: o menu atual nao se re-centraliza em tela alta, ele fica no topo e a
sobra aparece embaixo. As linhas de exemplo mostram a formula resolvida; cada tela nova aplica a formula ao seu `h` e
`m` reais e registra o resultado nas duas colunas.

Regra de escolha: o que o polegar alcanca (dica de toque, acoes primarias) fica na metade inferior, classe base ou
centro; o que e informacao ou acao rara fica no topo ([ADR 0003](../adr/0003-controle-de-um-polegar.md)). Nenhum
elemento muda de tamanho, espaco ou velocidade com a altura (ADR 0002).

## 5. Zonas ocupadas (proibidas para elemento novo)

Retangulos em px logicos, `y` relativo a `s_top`, com `s_left` e `s_right` = 0 (com margem, o placar vai de
`41 - s_right` ate `178 - s_right`):

| Ocupante            | Retangulo                           | Visivel quando | Origem                                                  |
| ------------------- | ----------------------------------- | -------------- | ------------------------------------------------------- |
| Placar (Pontos)     | x[41, 178] y[0, 30]                 | sempre         | `Stage.gd:13,14,73-74` (`right` = 180 - 2, largura 137) |
| Play                | x[62, 118] y[147, 173]              | so no menu     | `Stage.gd:15-17,75-76`                                  |
| Last                | x[0, 180] y[230, 247]               | so no menu     | `Stage.gd:18-19,77`                                     |
| Best                | x[0, 180] y[248, 265]               | so no menu     | `Stage.gd:20-21,78`                                     |
| Botao Opcoes (menu) | ver secao 11.1                      | so no menu     | secao 11                                                |
| Faixa de derrota    | fora da area visivel, abaixo de `H` | sempre         | `Stage.gd:10,66` (espessura 20)                         |

Elemento novo de partida nao cobre o placar. Elemento novo de menu ou de overlay nao cobre Play, Last nem Best enquanto
eles estiverem visiveis. O jogo em si ocupa a coluna inteira de 180: o toque de jogo cobre a tela toda, e qualquer
excecao (botao de pausa) e declarada como zona morta na tela dona dela.

## 6. Limites desta fundacao

- Nao ha acao `pause` no `project.godot` (so `ui_left`, `ui_right`, `jump`); teclas de pausa citadas nas telas sao
  previsao.
- Hoje nenhuma tela trata toque alem do clique/toque emulado do botao Play.
- Nao ha slider, tema de UI nem fonte alem da do placar; os estados e o alvo de toque desta pagina sao proposta, a
  confirmar no QA final.

## 7. Botao de pausa

Botao de toque que pausa a partida (issue #12). Silhueta de duas barras verticais, legivel sem cor. Usa o estilo da
secao 3 (fundo `#5b8a4a`, borda preta) e as regras de ancoragem da secao 4.

### 7.1 Medidas

Classe **topo** com offset `o` = 2 (mesmo `HUD_RIGHT_MARGIN` de 2 do placar, `Stage.gd:12`, espelhado no lado esquerdo).
Como o botao e de topo, as medidas sao as mesmas em 180x320 e 180x400. Coordenadas relativas a `s_top`/`s_left` do aparelho;
com `s_top` > 0 soma-se `s_top` ao `y` e com `s_left` > 0 soma-se `s_left` ao `x`.

| Item                                              | Formula                                                     | `s_*` = 0 (180x320 e 180x400) | Exemplo `s_top` = 20 |
| ------------------------------------------------- | ----------------------------------------------------------- | ----------------------------- | -------------------- |
| Retangulo do botao e da area de toque (24x24)     | x[`s_left` + 2, `s_left` + 26] y[`s_top` + 2, `s_top` + 26] | x[2, 26] y[2, 26]             | x[2, 26] y[22, 46]   |
| Glifo (duas barras, 10x12, centrado no retangulo) | retangulo + 7 em x, + 6 em y                                | x[9, 19] y[8, 20]             | x[9, 19] y[28, 40]   |
| Barra esquerda (3x12)                             | glifo, primeiros 3 px                                       | x[9, 12] y[8, 20]             | x[9, 12] y[28, 40]   |
| Barra direita (3x12)                              | glifo, ultimos 3 px                                         | x[16, 19] y[8, 20]            | x[16, 19] y[28, 40]  |
| Zona morta do toque de jogo                       | igual ao retangulo do botao                                 | x[2, 26] y[2, 26]             | x[2, 26] y[22, 46]   |
| Folga horizontal ate o placar                     | `41 - s_right - (s_left + 26)`                              | 41 - 26 = **15 px**           | 15 px                |

Alvo de toque 24x24 = minimo da secao 3, medido no retangulo que responde (area de toque = desenho, sem margem extra).
Glifo branco `#ffffff` com contorno preto `#000000` de 1 px, sobre fundo `#5b8a4a` e borda preta: o botao se distingue
por silhueta (duas barras) e por borda, nunca por uma das 4 cores do jogo, que podem estar atras dele.

Folga ate o placar: o retangulo do placar (secao 5) comeca em x = 41. Enquanto `s_left` + `s_right` <= 13 a folga fica

> = 2 px (minimo da secao 3 entre alvos vizinhos). Acima disso o caso nao esta coberto: quem implementa mede o texto real do
> placar antes de mexer em qualquer coordenada.

O botao fica longe de Play, Last e Best (y >= 147) e nem aparece no menu (7.2).

```
 escala aproximada: 1 coluna = 5 px; vale a tabela, nao o desenho
 +------------------------------------+  y = s_top
 |[||]    ~~~~~~~~~~ placar ~~~~~~~~~~|
 |[||]    ~~~~~~~~~~ placar ~~~~~~~~~~|  y = s_top + 26 (fim do botao)
 +------------------------------------+
  botao x 2..26 | folga 15 px | placar x 41..178
```

### 7.2 Predicado de partida ativa

O botao de pausa so aparece quando **a partida esta em curso e nao em derrota**: o jogo foi iniciado (`started`,
`Stage.gd:8`) e a derrota nao comecou (o estado de derrota e publicado em `Stage.gd:98`, antes da animacao em
`Stage.gd:99`). Fora disso (menu, derrota, animacao de derrota) o botao fica oculto e nao recebe toque. Nao ha pausa
durante a animacao de derrota.

Este e o unico lugar que define o predicado; as outras telas o citam pelo nome "predicado de visibilidade (secao 7.2)" e
nao o reescrevem.

### 7.3 Arbitragem do toque e pausa acidental

O retangulo da zona morta (7.1) e a **unica** exclusao das zonas de toque de jogo (secao 8). Ordem de decisao quando um
toque chega, da camada de cima para a de baixo:

1. Overlay de pausa (secao propria deste documento), quando existe: consome todo toque.
2. Botao de pausa: o toque que **comeca** dentro da zona morta pertence ao botao e nunca vira pulo nem andar.
3. Classificador de toque de jogo: recebe a zona morta como retangulo a ignorar, em coordenadas relativas a `s_top` e
   `s_left` (nao em pixel absoluto), e trata o resto da tela por metade esquerda/direita.

Regras contra pausa acidental:

| Regra                            | Comportamento                                                                                                                                           |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Aciona ao soltar                 | A pausa dispara no soltar do dedo, com o dedo dentro do retangulo; o pressionar so ativa o estado pressed.                                              |
| Sem arrastar de fora para dentro | Toque que comecou fora do retangulo e entrou nele permanece toque de jogo e nao aciona a pausa.                                                         |
| Arrastar para fora cancela       | Toque que comecou no botao e saiu do retangulo antes de soltar cancela a pausa e nao vira acao de jogo.                                                 |
| Segundo dedo                     | Um dedo ja seguro em uma metade da tela nao impede o botao; ao pausar, os toques de jogo em curso sao cancelados.                                       |
| Sem limiar novo                  | Nao ha tempo minimo de pressao nem confirmacao dupla; o limiar de toque de jogo e de outra entrega ([ADR 0003](../adr/0003-controle-de-um-polegar.md)). |

### 7.4 Estados e z-order

| Estado           | Comportamento                                                                                    |
| ---------------- | ------------------------------------------------------------------------------------------------ |
| normal / pressed | como a secao 3 (pressed: borda de 2 px e glifo 1 px abaixo).                                     |
| disabled         | nao existe: fora do predicado de visibilidade (secao 7.2) o botao esta oculto, nao desabilitado. |
| focus            | o botao nao entra na cadeia de foco; teclado e joypad pausam por tecla (7.5).                    |

Z-order, de baixo para cima: (1) jogo; (2) dica de toque (secao 8); (3) botao de pausa; (4) overlay de pausa. O botao
fica acima da dica para nunca ser coberto por ela e abaixo do overlay, que o encobre.

### 7.5 Onde e acessada

- Na tela de jogo, no canto superior esquerdo (7.1), quando o predicado de visibilidade (secao 7.2) e verdadeiro.
- Por tecla ou joypad: previsao (Esc ou P no teclado, botao de start no controle). Nao existe acao `pause` no
  `project.godot`; este documento nao a cria.

## 8. Dica visual de toque

Mostra ao jogador como o toque funciona (issue #11, [ADR 0003](../adr/0003-controle-de-um-polegar.md)) sem botao virtual:
duas zonas grandes, esquerda e direita, desenhadas como dica. A dica e so desenho.

### 8.1 Zonas e divisao

A divisao e a **metade da largura**, x = 90, fixa (a coluna de 180 nao muda com entalhe). Zonas de toque de jogo, em px
logicos:

| Zona     | Retangulo 180x320                                             | Retangulo 180x400                           | Observacao                                                                     |
| -------- | ------------------------------------------------------------- | ------------------------------------------- | ------------------------------------------------------------------------------ |
| Esquerda | x[0, 90) y[0, 320] menos a zona morta do botao de pausa (7.1) | x[0, 90) y[0, 400] menos a mesma zona morta | pulo diagonal para a esquerda no toque rapido; anda para a esquerda ao segurar |
| Direita  | x[90, 180] y[0, 320]                                          | x[90, 180] y[0, 400]                        | pulo diagonal para a direita no toque rapido; anda para a direita ao segurar   |

O ponto x = 90 pertence a zona direita. A altura de cada zona e a altura visivel inteira (nao so a safe area); so o
desenho da dica fica dentro da safe area.

### 8.2 Elementos desenhados

Sem fundo e sem moldura: so glifos e texto, todos `#ffffff` com contorno preto `#000000` (1 px no texto de tamanho 20,
secao 2). Os dois lados tem a mesma cor; esquerda e direita se distinguem por **posicao, seta e texto**, nunca por cor.

| Elemento                                                                                 | Classe         | Formula / medida                                             | 180x320                | 180x400                |
| ---------------------------------------------------------------------------------------- | -------------- | ------------------------------------------------------------ | ---------------------- | ---------------------- |
| Linha divisoria (1 px, tracejado 2 px liga / 2 px desliga, `#ffffff` a 60% de opacidade) | topo (x fixo)  | x = 90, y de `s_top` + 32 ate `H - s_bottom`                 | x = 90 y[32, 320]      | x = 90 y[32, 400]      |
| Bloco esquerdo (76x60)                                                                   | base, `m` = 40 | x[max(7, `s_left` + 2), 83], `y0 = (H - s_bottom) - 40 - 60` | x[7, 83] y[220, 280]   | x[7, 83] y[300, 360]   |
| Bloco direito (76x60)                                                                    | base, `m` = 40 | x[97, min(173, 180 - `s_right` - 2)], mesmo `y0`             | x[97, 173] y[220, 280] | x[97, 173] y[300, 360] |

Conteudo de cada bloco, de cima para baixo (soma 24 + 2 + 17 + 17 = 60):

| Linha                | Altura                             | Conteudo esquerda | Conteudo direita |
| -------------------- | ---------------------------------- | ----------------- | ---------------- |
| Seta                 | 24 (glifo 24x24 centrado no bloco) | `<`               | `>`              |
| espaco               | 2                                  |                   |                  |
| Texto 1 (tamanho 20) | 17                                 | "pula"            | "pula"           |
| Texto 2 (tamanho 20) | 17                                 | "segura: anda"    | "segura: anda"   |

"pula" descreve o toque rapido (pulo diagonal para aquele lado); "segura: anda" descreve segurar (anda para aquele lado).
O limiar numerico entre os dois nao e definido aqui. Largura de glifo da fonte nao esta no repo: se "segura: anda" nao
couber em 76 px, quem implementa quebra em duas linhas e confere a soma vertical dos blocos com a altura util.

Os blocos ocupam a metade inferior (onde esta o polegar, [ADR 0003](../adr/0003-controle-de-um-polegar.md)): `y0` >=
`s_top` + `U` / 2 (160 em 180x320 e 200 em 180x400). Com `s_left`/`s_right` > 0 o bloco encolhe pelo lado externo.

Nao cobrem o placar (y[0, 30] na secao 5; a linha comeca em y = 32, 2 px abaixo) nem o botao de pausa (x[2, 26] y[2, 26],
secao 7.1): os blocos comecam em y >= 220.

```
 escala aproximada: 1 coluna = 5 px, 1 linha = 16 px; mostra 180x320; vale a tabela
 +------------------------------------+
 |[||]    ~~~~~~~~~~ placar ~~~~~~~~~~|
 |[||]    ~~~~~~~~~~ placar ~~~~~~~~~~|
 |  zona esquerda   :  zona direita   |
 |                  :                 |
 |       (...)      :      (...)      |  y 32..220: so a linha tracejada
 |                  :                 |
 | +--------------+ :+--------------+ |  y 220 (inicio dos blocos)
 | |      <       | :|      >       | |
 | |     pula     | :|     pula     | |
 | | segura: anda | :| segura: anda | |
 | +--------------+ :+--------------+ |  y 280
 |                  :                 |
 +------------------------------------+  y 320
```

As bordas `+--+` dos blocos existem so no desenho acima para mostrar a extensao; na tela nao ha moldura.

### 8.3 Sem area de toque propria

- Nenhum elemento da dica recebe entrada: sem hit area, sem foco, sem estado pressed. O toque atravessa a dica e chega ao
  classificador de toque de jogo.
- Nao e botao virtual: as setas e os textos nao sao alvos, por isso o minimo de 24x24 da secao 3 nao se aplica a eles
  (os glifos tem 24x24 por legibilidade, nao por alvo). O controle e a tela inteira dividida em metades
  ([ADR 0003](../adr/0003-controle-de-um-polegar.md)).
- A unica excecao a esse desenho e a zona morta do botao de pausa (7.1), que fica fora do toque de jogo, nao da dica.

### 8.4 Quando aparece e quando some

| Situacao                                                                       | Dica                                                                           |
| ------------------------------------------------------------------------------ | ------------------------------------------------------------------------------ |
| Predicado de visibilidade (secao 7.2) falso (menu, derrota)                    | oculta                                                                         |
| Primeira partida, antes do primeiro toque de jogo                              | visivel                                                                        |
| Primeiro toque de jogo (em qualquer zona; o toque no botao de pausa nao conta) | some com fade-out de 0.3 s (proposta provisoria)                               |
| Partidas seguintes                                                             | nao mostrada                                                                   |
| Jogo pausado                                                                   | fica sob o overlay de pausa (z-order, 7.4)                                     |
| Overlay de tutorial                                                            | reaproveitada como parte do tutorial; nao existe item de menu proprio para ela |

A flag "dica ja mostrada" e persistida em outra entrega. Variante de desktop/teclado: quando a entrada em uso e teclado ou
controle, os dois blocos mostram a tecla de cada acao (`ui_left`, `ui_right`, `jump`) no lugar de "pula"/"segura: anda";
mesma posicao, mesma cor e mesma regra de aparecer e sumir.

Onde e acessada: aparece na partida (1o toque) e como parte do overlay de tutorial. Nao ha tela nem item de menu proprio.

## 9. Overlay de pausa

Cobre a partida congelada (issue #12). Titulo "Pausado" e dois botoes, **Continuar** e **Opcoes**, nessa ordem. Usa a
paleta (secao 1), a fonte (secao 2) e o botao (secao 3).

### 9.1 Visibilidade e acesso

- Visivel somente com o predicado de visibilidade (secao 7.2) verdadeiro **e** a partida pausada. Menu e derrota nunca
  mostram o overlay.
- Abre pelo botao de pausa (7.1) ou por tecla/joypad (previsao: Esc ou P, botao de start; a acao `pause` nao existe
  no `project.godot`, este documento nao a cria).
- Fecha por **Continuar**, ou por Esc/P (previsao) com o overlay aberto. A partida volta ao ponto em que estava.
- Opcoes abre a tela da secao 10; Voltar de la devolve a este overlay.

### 9.2 Elementos e medidas

Fundo: retangulo da altura visivel inteira (`H`) e da largura 180 inteira, inclusive fora da safe area, `#000000` a 60%
(secao 1). Os elementos abaixo formam **um bloco centrado** (classe centro, secao 4) de altura 118, dentro da safe area.

| Elemento  | Texto                                | Altura | Largura | `y0` (relativo ao bloco) | `x`                      |
| --------- | ------------------------------------ | ------ | ------- | ------------------------ | ------------------------ |
| Titulo    | "Pausado", tamanho 36, contorno 2 px | 30     | 180     | 0                        | [0, 180], texto centrado |
| espaco    |                                      | 16     |         | 30                       |                          |
| Continuar | tamanho 26                           | 32     | 112     | 46                       | [34, 146]                |
| espaco    |                                      | 8      |         | 78                       |                          |
| Opcoes    | tamanho 20                           | 32     | 112     | 86                       | [34, 146]                |

Soma vertical: 30 + 16 + 32 + 8 + 32 = **118**. Formula do bloco: `y0 = s_top + (U - 118) / 2`; horizontal dos botoes:
`x0 = s_left + (180 - s_left - s_right - 112) / 2` (34 com `s_left` = `s_right` = 0).

| Elemento     | 180x320 (`U` = 320, `y0` = 101) | 180x400 (`U` = 400, `y0` = 141) |
| ------------ | ------------------------------- | ------------------------------- |
| Titulo       | y[101, 131]                     | y[141, 171]                     |
| Continuar    | x[34, 146] y[147, 179]          | x[34, 146] y[187, 219]          |
| Opcoes       | x[34, 146] y[187, 219]          | x[34, 146] y[227, 259]          |
| Fim do bloco | y = 219                         | y = 259                         |

Conferencia 180x320: 101 + 30 = 131; + 16 = 147; + 32 = 179; + 8 = 187; + 32 = 219; 219 - 101 = 118. Conferencia
180x400: 141 + 30 = 171; + 16 = 187; + 32 = 219; + 8 = 227; + 32 = 259; 259 - 141 = 118. Com `s_top` = 20 e `s_bottom` = 6
(exemplo da secao 4, `U` = 294) o bloco comeca em y = 20 + (294 - 118) / 2 = 108. Cada botao tem 32 de altura, acima do
minimo de 24 (secao 3), com 8 px entre os dois alvos (minimo 2).

O bloco fica entre y = 101 e y = 259: nunca toca o placar (y[0, 30], secao 5) nem o botao de pausa (7.1).

```
 escala aproximada: 1 coluna = 5 px, 1 linha = 16 px; mostra 180x320; vale a tabela
 +------------------------------------+
 |::::::::::: placar (escuro) :::::::::|  fundo #000000 a 60% em toda a tela
 |::::::::::::::::::::::::::::::::::::|
 |::::::::::::::  Pausado  ::::::::::::|  y 101..131
 |::::::::::::::::::::::::::::::::::::|
 |:::::::[   > Continuar   ]:::::::::::|  y 147..179 (> so com foco)
 |::::::::::::::::::::::::::::::::::::|
 |:::::::[      Opcoes     ]:::::::::::|  y 187..219
 |::::::::::::::::::::::::::::::::::::|
 +------------------------------------+  y 320
```

### 9.3 Placar, fundo e toque

- O overlay **nao esconde o placar**: o fundo o escurece (o numero fica a 40% do brilho, legivel) e o jogador ve a
  pontuacao com a partida parada. O botao de pausa (7.1) fica sob o fundo e nao recebe toque.
- Pelas regras da secao 7.3 o overlay e a camada de cima: **todo** toque e consumido. Toque no fundo, fora dos botoes,
  nao pula, nao anda e **nao retoma** (retomar por toque solto causaria despausa acidental).
- Cada botao aciona ao soltar com o dedo dentro do retangulo, como na secao 7.3.
- A dica de toque (secao 8) e o jogo ficam sob o fundo, sem receber toque.

### 9.4 Cor nao e a unica pista

Os dois botoes tem o mesmo fundo e a mesma borda (secao 3). O primario e **Continuar** por tres pistas que nao sao cor:
posicao (primeiro, acima), rotulo (verbo de retomar) e tamanho de texto (26 contra 20 de Opcoes).

### 9.5 Teclado e joypad

- Ordem de foco: Continuar, depois Opcoes; cima/baixo (`ui_up`/`ui_down`) circulam entre eles. Foco inicial em Continuar.
- Foco visivel = marcador `>` antes do rotulo + moldura de 2 px (secao 3, estado focus).
- Confirmar (`ui_accept`) aciona o botao com foco. Esc/P (previsao) = Continuar.

## 10. Tela de Opcoes

Dois sliders de volume, **Music** e **SFX**, item **Ver tutorial** e **Voltar**. Mesma tela nas duas origens. Tokens da
secao 1 (trilha `#000000`, preenchimento `#5b8a4a`, cursor `#ffffff` com contorno `#000000`).

### 10.1 Onde e acessada e para onde volta

| Origem | Como abre                         | Voltar leva a                          |
| ------ | --------------------------------- | -------------------------------------- |
| Pausa  | botao Opcoes do overlay (secao 9) | overlay de pausa, com foco em Opcoes   |
| Menu   | botao Opcoes do menu (secao 11)   | menu, com foco no botao Opcoes do menu |

- Esc/P (previsao) com a tela aberta = Voltar; nunca retoma a partida direto da tela de Opcoes.
- Da origem pausa a partida fica congelada; o fundo e o mesmo da secao 9.2 (a tela de Opcoes substitui titulo e botoes
  do overlay). Da origem menu, a tela aparece sobre o menu com o mesmo fundo e **oculta** Play, Last, Best e o botao
  Opcoes do menu (nao so os cobre): eles nao recebem toque. A partida nao inicia com a tela aberta: a entrada por tecla
  `jump` que inicia o jogo no menu (`Stage.gd:87-89`) deve ficar suspensa enquanto Opcoes esta aberta.
- Predicado de visibilidade (secao 7.2): da origem pausa vale o da secao 9.1; da origem menu a tela so abre com o jogo
  nao iniciado.
- Toque no fundo, fora dos controles, e consumido e nao faz nada.
- **Ver tutorial** abre o tutorial; a regra de retorno dele esta na secao do tutorial deste documento.

### 10.2 Medidas

Um unico bloco centrado (classe centro, secao 4), altura 220, dentro da safe area. Formula:
`y0 = s_top + (U - 220) / 2`; exige `U` >= 220 (em 320 sobram 100).

Slider (cada um): rotulo na linha de cima, area de toque embaixo.

| Parte do slider | Medida                                                                                                            |
| --------------- | ----------------------------------------------------------------------------------------------------------------- |
| Linha do rotulo | altura 17, texto tamanho 20; nome a esquerda em x = 16, valor alinhado a direita terminando em x = 164            |
| espaco          | 2                                                                                                                 |
| Area de toque   | x[8, 172] (largura 164) por 24 de altura (= minimo da secao 3), centrada na linha da trilha                       |
| Trilha          | x[16, 164] (largura 148) por 6 de altura, centrada na area de toque; moldura de 1 px `#ffffff` a 60% de opacidade |
| Preenchimento   | da borda esquerda da trilha ate o centro do cursor, 6 de altura                                                   |
| Cursor          | 12x16, `#ffffff` com contorno `#000000` de 1 px, centro em x = 16 + 148 * valor / 100                             |

Altura do slider: 17 + 2 + 24 = **43**. Cursor em 0 ocupa x[10, 22] e em 100 ocupa x[158, 170], sempre dentro da area de
toque.

Bloco, de cima para baixo:

| Elemento                                   | Altura | Largura / x                | `y0` no bloco |
| ------------------------------------------ | ------ | -------------------------- | ------------- |
| Titulo "Opcoes", tamanho 36, contorno 2 px | 30     | texto centrado em [0, 180] | 0             |
| espaco                                     | 12     |                            | 30            |
| Slider Music                               | 43     | area de toque x[8, 172]    | 42            |
| espaco                                     | 8      |                            | 85            |
| Slider SFX                                 | 43     | area de toque x[8, 172]    | 93            |
| espaco                                     | 12     |                            | 136           |
| Ver tutorial (botao, tamanho 20)           | 32     | x[34, 146]                 | 148           |
| espaco                                     | 8      |                            | 180           |
| Voltar (botao, tamanho 20)                 | 32     | x[34, 146]                 | 188           |

Soma vertical: 30 + 12 + 43 + 8 + 43 + 12 + 32 + 8 + 32 = **220**. Sem rolagem: 220 cabe em `U` = 320 e em `U` = 400.

| Elemento               | 180x320 (`y0` do bloco = 50) | 180x400 (`y0` do bloco = 90) |
| ---------------------- | ---------------------------- | ---------------------------- |
| Titulo                 | y[50, 80]                    | y[90, 120]                   |
| Music, linha do rotulo | y[92, 109]                   | y[132, 149]                  |
| Music, area de toque   | y[111, 135]                  | y[151, 175]                  |
| SFX, linha do rotulo   | y[143, 160]                  | y[183, 200]                  |
| SFX, area de toque     | y[162, 186]                  | y[202, 226]                  |
| Ver tutorial           | x[34, 146] y[198, 230]       | x[34, 146] y[238, 270]       |
| Voltar                 | x[34, 146] y[238, 270]       | x[34, 146] y[278, 310]       |
| Fim do bloco           | y = 270                      | y = 310                      |

Conferencia 180x320: 50 + 30 = 80; + 12 = 92; + 43 = 135; + 8 = 143; + 43 = 186; + 12 = 198; + 32 = 230; + 8 = 238; + 32 =
270; 270 - 50 = 220. Conferencia 180x400: 90 + 30 = 120; + 12 = 132; + 43 = 175; + 8 = 183; + 43 = 226; + 12 = 238; + 32 =
270; + 8 = 278; + 32 = 310; 310 - 90 = 220. Com `s_top` = 20 e `s_bottom` = 6 (`U` = 294) o bloco comeca em y = 20 +
(294 - 220) / 2 = 57 e termina em 277, dentro da safe area. Voltar fica na metade inferior da altura util (y >= 160), ao
alcance do polegar (ADR 0003). O titulo nao toca o placar (y[0, 30]).

```
 escala aproximada: 1 coluna = 5 px, 1 linha = 16 px; mostra 180x320; vale a tabela
 +------------------------------------+
 |::::::::::::::::::::::::::::::::::::|
 |::::::::::::::  Opcoes  :::::::::::::|  y 50..80
 |:: Music                       100% ::|  y 92..109
 |:: [============================O] ::|  y 111..135 (toque x 8..172)
 |:: SFX                         100% ::|  y 143..160
 |:: [============================O] ::|  y 162..186
 |:::::::[   Ver tutorial   ]:::::::::::|  y 198..230
 |:::::::[      Voltar      ]:::::::::::|  y 238..270
 |::::::::::::::::::::::::::::::::::::|
 +------------------------------------+  y 320
```

### 10.3 Comportamento do arrasto

- Valor inteiro de 0 a 100. A posicao horizontal `x` do dedo vira `valor = round(clamp((x - 16) / 148, 0, 1) * 100)`.
- Tocar na trilha leva o cursor ao ponto tocado; arrastar o ajusta. So o eixo horizontal conta; o movimento vertical e
  ignorado.
- O toque pertence ao slider desde o pressionar dentro da area de toque. Se o dedo sai da area (para cima, para baixo ou
  alem das pontas), o ajuste se **mantem** ate soltar, com `x` limitado a [16, 164] (o valor fica na ponta mais proxima).
- Teclado/joypad: com foco no slider, `ui_left`/`ui_right` mudam de 5 em 5, limitado a 0 e 100; `ui_up`/`ui_down` mudam de
  foco.
- A tela nao toca som de amostra: nao ha som novo ate a arte final.

### 10.4 Estados do slider

| Estado                                                                                                                         | Cursor                                         | Preenchimento          | Valor exibido                     | Pista que nao e cor                                    |
| ------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------- | ---------------------- | --------------------------------- | ------------------------------------------------------ |
| Padrao (valor de exibicao inicial: 100, proposta provisoria que reflete o jogo sem ajuste de volume; quem implementa confirma) | 12x16, contorno 1 px                           | ate o centro do cursor | "100%"                            | posicao do cursor + numero                             |
| Arrastando                                                                                                                     | 14x20, contorno 2 px (cresce, nao muda de cor) | acompanha o cursor     | numero atualizado em tempo real   | cursor maior + contorno mais grosso                    |
| 0 (mudo)                                                                                                                       | em x = 16, contorno 1 px                       | vazio (so a trilha)    | texto **"mudo"** no lugar de "0%" | texto "mudo" + preenchimento vazio                     |
| 100                                                                                                                            | em x = 164, contorno 1 px                      | trilha inteira         | "100%"                            | cursor na ponta direita + numero                       |
| Foco (teclado/joypad)                                                                                                          | igual ao padrao                                | igual                  | igual                             | marcador `>` antes do nome + moldura de 2 px (secao 3) |

Padrao e 100 coincidem no valor de exibicao inicial; o estado 100 vale tambem apos ajustar de volta. Cada botao da tela
usa a secao 3 (normal, pressed, focus). Cursor arrastando em 0 ocupa x[9, 23] e em 100 ocupa x[157, 171], dentro da area de
toque.

### 10.5 Music sem faixa

O jogo hoje nao tem faixa de musica; a trilha chega na arte final. O slider **Music** aparece e funciona normalmente
(mesmas medidas e estados, sem aviso, sem estado desabilitado): mexer nele nao muda nada audivel ate existir a faixa.
SFX age sobre os efeitos existentes.

### 10.6 Teclado e joypad

Ordem de foco: Music, SFX, Ver tutorial, Voltar (circular); foco inicial em Music. Confirmar (`ui_accept`) aciona Ver
tutorial ou Voltar. Voltar tambem por Esc/P (previsao, secao 10.1).

## 11. Botao de Opcoes no menu

Acesso a Opcoes antes de jogar (issue #12). Botao secundario no espaco livre entre o Play e o Last, so no menu.

### 11.1 Medidas

Classe **topo**, `o` = 189. Medidas iguais em 180x320 e 180x400; com `s_top` > 0 soma-se `s_top` ao `y`.

| Item                                  | Medida                                                       |
| ------------------------------------- | ------------------------------------------------------------ |
| Retangulo do botao e da area de toque | x[46, 134] y[189, 213] (88x24, minimo da secao 3)            |
| Texto                                 | "Opcoes", tamanho 20, fundo `#5b8a4a`, borda preta (secao 3) |
| Folga ate o Play (y fim 173)          | 189 - 173 = 16                                               |
| Folga ate o Last (y inicio 230)       | 230 - 213 = 17                                               |

Soma vertical entre Play e Last: 173 + 16 + 24 + 17 = **230**. `x0 = (180 - 88) / 2 = 46`, centrado como o Play
(x[62, 118]) sem o cobrir. Nao cobre o placar (y[0, 30]) nem Last/Best (secao 5).

```
 recorte de y 147 a 265; vale a tabela
        +----------+
        |   Play   |  y 147..173
        +----------+
       +------------+
       |  Opcoes    |  y 189..213
       +------------+
 Last: ....            y 230..247
 Best: ....            y 248..265
```

### 11.2 Visibilidade e uso

- Visivel apenas no menu (jogo nao iniciado), junto com Play, Last e Best; some ao iniciar a partida
  (`Stage.gd:119-123`) e nunca aparece durante a partida nem na derrota.
- Aciona ao soltar com o dedo dentro do retangulo (regra da secao 7.3). Abre a tela da secao 10; Voltar retorna ao menu.
- Teclado/joypad: ordem de foco no menu = Play, depois Opcoes (baixo vai do Play ao Opcoes); marcador `>` + moldura
  conforme secao 3.
