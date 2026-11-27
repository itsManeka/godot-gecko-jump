# 0016 — Visual da plataforma em NinePatchRect, com cor por textura e canais visuais por dono

- **Status:** aceito
- **Data:** 2026-11-27
- **Decisores:** itsManeka + Claude

## Contexto

A ilhota de plataforma era um `Sprite2D` `64x16` com `scale 2x`, tingido pela cor da variante via `modulate` e recortado
com `region_rect` nas larguras estreitas ([ADR 0009](0009-modificadores-de-plataforma.md)). Isso tinha tres problemas:

- A cor dependia de tingimento chapado, o que contraria a acessibilidade sem cor (`#41`, [ADR 0015](0015-direcao-de-arte-fonte-comercial-e-audio-dinamico.md)).
- O recorte decepava as pontas da ilhota nas larguras `88` a `120`.
- Cicladora ([ADR 0010](0010-plataformas-cicladoras.md)), piscante ([ADR 0012](0012-plataformas-que-piscam.md)) e tremor
  do desmoronamento disputavam o mesmo `modulate` e a mesma posicao do sprite.

A arte final da plataforma e uma peca `96x40` por cor, com pontas de `20 px` e miolo repetivel, pensada para 9-slice.

Restricoes que moldam a decisao:

- `Control` nao tem offset nem escala de centro como `Sprite2D`: `position` e o canto superior esquerdo e o tamanho vem de `size`.
- Escala fracionaria nao e aceita no pixel art ([ADR 0009](0009-modificadores-de-plataforma.md), [ADR 0015](0015-direcao-de-arte-fonte-comercial-e-audio-dinamico.md)).
- Alfa e tremor precisam de um no `Node2D` proprio, para nao tocar a textura nem o corpo fisico.

## Decisao

- **Contrato visual.** `Platform` tem um no `Visual` (`Node2D`, origem no centro, sem `scale`). Dentro dele fica um
  `NinePatchRect` com a peca da cor: `patch_margin_left = 20`, `patch_margin_right = 20`,
  `axis_stretch_horizontal = TILE`, tamanho `largura x 40`, posicionado em `-size/2` mais o deslocamento vertical da arte
  que alinha a superficie da cobertura ao topo da colisao. Um no `OverlayRachadura` (`NinePatchRect`, mesmas margens) e
  filho de `Visual` e recebe a textura do estagio de rachadura.
- **Mouse e foco.** Todo `Control` na subarvore da plataforma usa `mouse_filter = MOUSE_FILTER_IGNORE` e
  `focus_mode = FOCUS_NONE`, para o jogo de toque nao capturar entrada.
- **Largura.** `set_largura(w)` redimensiona o `NinePatchRect` sem `region_rect` e mantem o `RectangleShape2D`
  duplicado por instancia ([ADR 0009](0009-modificadores-de-plataforma.md)). `Platform.scale` e `Visual.scale` ficam
  `Vector2.ONE`. O `AreaCheck` nao muda.
- **Miolo.** O miolo repete (TILE) e corta a direita, pela conta `x % 56` a partir da esquerda:
  - `120`: miolo `80` = 1 tile inteiro + 24 colunas do seguinte, cortado;
  - `112`: miolo `72` = 1 tile + 16 colunas;
  - `100`: miolo `60` = 1 tile + 4 colunas;
  - `88`: miolo `48` = o unico tile sai cortado (48 de 56 colunas).

  A juncao cortada na ponta direita e a repeticao visivel sao aceitas. O TILE do Godot foi conferido pixel a pixel contra
  essa conta nas quatro cores e nas quatro larguras, sem diferenca.
- **Cor = textura.** Uma fonte unica sem cena (`scripts/PlatformVisuais.gd`) mapeia `Enums.COLOR` para `Texture2D`, com
  as quatro texturas pre-carregadas. `_ready` e `_aplicar_cor` aplicam a textura da cor; `modulate` nao tinge mais a
  cor da plataforma.
- **Canais visuais, um dono cada:**
  - textura: cor da variante (`_aplicar_cor`) e, no aviso da cicladora, alternancia entre a cor atual e `proxima_cor()`;
  - `Visual.modulate.a`: pulso do aviso da cicladora (`1.0` e `AVISO_ALFA_BAIXO = 0.55`); fora do aviso,
    `Visual.modulate` volta a branco;
  - `Platform.modulate.a` (no raiz): flicker do piscante ([ADR 0012](0012-plataformas-que-piscam.md));
  - `Visual.position.x`: tremor do desmoronamento (`TREMOR_AMPLITUDE = 2.0`);
  - `OverlayRachadura`: estagio da rachadura, independente de cor.

  Nenhum canal e escrito por outro. Um teste exercita os quatro no mesmo frame.
- **Faixa arco-iris no aviso (fora de escopo).** O aviso da cicladora nao ganha faixa arco-iris. A textura inteira ja e
  um sinal sem matiz (cada cor tem padrao proprio), e a faixa exigiria arte e codigo adicionais.
- **Topo visual.** `topo_visual() -> float` devolve a posicao y do topo da peca no espaco da `Platform`, ja com o
  deslocamento da arte. `icone_power_up` fica `ICONE_FOLGA = 4.0` acima desse topo, centrado em `x = 0`. A referencia e
  o topo da peca (a arte garante topo opaco a no maximo `2 px` da primeira linha), e nao a metade da altura da textura.
- **Notifier.** O `VisibleOnScreenNotifier2D` da cena muda so `scale.y`, para cobrir a altura de `40 px` do visual. Shape
  e `AreaCheck` ficam intactos. Esta e a excecao ao "notifier intacto" da [ADR 0009](0009-modificadores-de-plataforma.md):
  o retangulo antigo, com `32 px` de altura, deixava `8 px` do visual fora da cobertura vertical e a plataforma podia
  "estalar" ao sair da tela.

## Consequencias

- **Positivas:** a cor deixa de depender de tingimento, entao a leitura sem cor (`#41`) fica na arte e nao no codigo. Cada
  canal visual tem um dono e e testado no mesmo frame. As pontas de `20 px` preservam a curva da ilhota em todas as larguras.
- **Negativas / trade-offs:** o miolo repetido corta a juncao da ponta direita, e no `88` o unico tile sai cortado. A
  arte final do acabamento manual pode suavizar a juncao sem mudar o contrato.
- **Riscos aceitos:**
  - O aviso da cicladora alterna a textura inteira a `6 Hz` (`AVISO_FASES_POR_S = 12`), mais contrastante que o pulso de
    alfa anterior. O conforto visual e avaliado jogando.
  - A rampa da peca vermelha pode mudar quando o acabamento do dono for aplicado; o contrato de topo e de tamanho nao muda.
  - `NinePatchRect` com largura abaixo de `40 px` degenera; o menor valor usado nos testes e `44`.

## Alternativas consideradas

- **`Sprite2D` com `region_rect` e `scale`:** rejeitada. Decepava as pontas nas larguras estreitas e escalava o pixel art.
- **Tres `Sprite2D` (ponta esquerda, miolo, ponta direita):** rejeitada. Mais nos e sem o TILE nativo do `NinePatchRect`.
- **Manter o tingimento por `modulate` e trocar so a textura:** rejeitada. A cor seria aplicada duas vezes e o alfa do aviso
  disputaria o mesmo canal.
- **Alfa do aviso em um `Control`:** rejeitada. O `Control` herda o `modulate` e o alfa do aviso precisa ficar em um `Node2D`.
- **Faixa arco-iris no aviso da cicladora:** rejeitada nesta entrega, pelo custo de arte e codigo extra frente a textura
  que ja e um sinal sem matiz.
- **Escalar o notifier pela largura:** rejeitada. So a altura precisa cobrir o visual; a largura do notifier continua fixa.
