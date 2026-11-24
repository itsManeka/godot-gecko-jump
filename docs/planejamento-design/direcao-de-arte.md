# Direção de Arte e Áudio — Gecko Jump (E6)

Especificação visual, sonora e de licenciamento definitiva do **Gecko Jump** para o marco **E6** (issue `#18`), consolidando identidade visual 16-bit/GBC, paleta de 32 cores com contraste WCAG AA (`>= 4.5:1`), acessibilidade sem cor (issue `#41`), sprites de gameplay, 4 biomas com parallax e névoa reativa, tipografia comercial livre, kit UI em pixel art, remodelagem completa do menu com reserva de espaço para **Ranking (E5)** e **Remover anúncios (E8)**, direção de SFX (issues `#13`, `#43`), arquitetura de música dinâmica persistente (`ADR 0015`) e política de licenças comerciais (E7/E8).

Base técnica imutável: largura lógica fixa de **`180 px`**, altura visível mínima `320 px` expandida em aparelhos altos (`180×400`, `180×462+`), pixel quadrado, filtro `Nearest` (`default_texture_filter = 0`) e escala inteira (`ADR 0002`). Fontes editáveis em Aseprite vivem isoladas em `assets/src/` (`ADR 0004`).

---

## 1. Identidade visual e paleta (32 cores)

### 1.1 Estética e regras de leitura em 180 px

- **Estilo:** Pixel art **vibrante e charmosa 16-bit/GBC**, com silhuetas limpas, formas legíveis sem zoom, contorno escuro coeso (`#161822`, índigo-carvão em vez de preto chapado puro) e sombreamento em 3 tons por cor de gameplay (luz / base / sombra).
- **Hierarquia visual obrigatória:**
  1. **Primeiro plano (gameplay — Gecko, plataformas, power-ups):** alta saturação (`55%–89%`), luminosidade média-alta (`58%–67%`) e contorno escuro `1 px` (`#161822`).
  2. **Interface (HUD, botões, cards):** cores próprias de UI (`#3d6b35`, `#9c521b`, `#1f2738`) que nunca dependem das 4 cores das plataformas, com texto em `#fffdf5` / `#d4e0e6` garantindo contraste `>= 4.5:1`.
  3. **Fundo (4 biomas e partículas ambientais):** saturação travada em `<= 32%` e luminosidade em `16%–47%`, com contraste interno suave entre camadas de parallax (`<= 2.2:1`) para recuar sempre atrás do gameplay.

### 1.2 Tabela completa da paleta (32 cores)

As 4 cores base de `scripts/Enums.gd` (`#f6db61`, `#79cf5a`, `#5987e9`, `#ec4848`) são mantidas como âncoras exatas. A cor histórica de botão `#5b8a4a` (`ressources/Button.tres`) é preservada como chanfro superior/preenchimento de slider (`ui_btn_luz`), enquanto o corpo dos botões evolui para `#3d6b35` (`ui_btn_base`) para atingir contraste WCAG AA `>= 4.5:1` (com `#ffffff`, `#5b8a4a` entregava apenas `4.05:1`).

| Grupo | Token | Hex | Luminância relativa (`L`) | Luma BT.709 (0–255) | Uso principal |
|---|---|---|---:|---:|---|
| **Neutros e Contorno (5)** | `ink_contorno` | `#161822` | `0.0094` | `24` | Contorno de sprites/texto, fissuras, overlay translúcido (`70%`) |
| | `painel_escuro` | `#1f2738` | `0.0203` | `39` | Fundo de cards/placar/modais e barras laterais (`default_clear_color`) |
| | `ui_desabilitado` | `#3b4654` | `0.0595` | `69` | Fundo de botão desabilitado (`"Ja jogado hoje"`) |
| | `ui_texto_sec` | `#d4e0e6` | `0.7302` | `222` | Texto secundário, rótulo desabilitado, friso de moldura, estrelas |
| | `branco_texto` | `#fffdf5` | `0.9810` | `253` | Texto primário, olhos do gecko, ícones HUD, cursor do slider |
| **Gameplay Amarelo (3)** | `amarelo_luz` | `#fff4b8` | `0.8942` | `242` | Brilho superior de plataforma/gecko amarelo, pulso `LevelUpFrame` |
| | `amarelo_base` | `#f6db61` | `0.7112` | `216` | Âncora `Enums.COLOR.AMARELO`, moldura de foco, destaque de recorde |
| | `amarelo_sombra` | `#c48f29` | `0.3154` | `147` | Sombra e relevo interno do bloco solar/arenito e do gecko amarelo |
| **Gameplay Verde (3)** | `verde_luz` | `#bef297` | `0.7669` | `224` | Brilho de folhas/musgo e topo do gecko verde |
| | `verde_base` | `#79cf5a` | `0.4943` | `180` | Âncora `Enums.COLOR.VERDE` |
| | `verde_sombra` | `#3f8f42` | `0.2110` | `120` | Sombra do galho/musgo e do gecko verde |
| **Gameplay Azul (3)** | `azul_luz` | `#a6c8ff` | `0.5664` | `197` | Faceta iluminada do cristal/gelo e brilho do gecko azul |
| | `azul_base` | `#5987e9` | `0.2533` | `132` | Âncora `Enums.COLOR.AZUL` |
| | `azul_sombra` | `#3050a8` | `0.0919` | `80` | Sombra prismática do cristal/gelo e do gecko azul |
| **Gameplay Vermelho (3)** | `vermelho_luz` | `#ff9b90` | `0.4672` | `175` | Borda quente do tijolo vulcânico e brilho do gecko vermelho |
| | `vermelho_base` | `#ec4848` | `0.2294` | `107` | Âncora `Enums.COLOR.VERMELHO` |
| | `vermelho_sombra` | `#9e2433` | `0.0877` | `63` | Argamassa/sombra do tijolo vulcânico e do gecko vermelho |
| **UI e Destaque (6)** | `ui_btn_luz` | `#5b8a4a` | `0.2090` | `123` | Chanfro superior de botão padrão e preenchimento de slider (herança `Button.tres`) |
| | `ui_btn_base` | `#3d6b35` | `0.1176` | `93` | Corpo dos botões padrão (`Modo`, `Opcoes`, `Pausa`, `Ranking`, `Remover anuncios`) |
| | `ui_btn_sombra` | `#274a24` | `0.0546` | `64` | Chanfro inferior e estado `pressed` de botão padrão |
| | `ui_cta_luz` | `#c9772e` | `0.2581` | `131` | Chanfro superior do CTA `Play`, brilho do logo e detalhe de power-ups |
| | `ui_cta_base` | `#9c521b` | `0.1318` | `94` | Corpo do botão CTA `Play` (âmbar queimado, distinto das 4 cores de jogo) |
| | `ui_cta_sombra` | `#6e3611` | `0.0599` | `63` | Chanfro inferior e estado `pressed` do CTA `Play` |
| **Biomas e Névoa (9)** | `b0_ceu` | `#2d5452` | `0.0751` | `76` | Bioma `e0` (*Floresta Tropical*): céu/profundidade verde-petróleo |
| | `b0_folhagem` | `#3b6b61` | `0.1231` | `96` | Bioma `e0` (*Floresta Tropical*): copas, troncos e folhas ambientais |
| | `b1_pedra` | `#31465c` | `0.0581` | `67` | Bioma `e1` (*Cachoeira & Neblina*): paredão úmido azul-ardósia |
| | `b1_bruma` | `#57738a` | `0.1612` | `111` | Bioma `e1` (*Cachoeira & Neblina*): quedas d'água e névoa média |
| | `b2_ceu` | `#4e4c6b` | `0.0785` | `79` | Bioma `e2` (*Ruínas Celestes*): céu crepuscular lilás-acinzentado |
| | `b2_pedra` | `#6e6b85` | `0.1552` | `110` | Bioma `e2` (*Ruínas Celestes*): arcos antigos e nuvens dessaturadas |
| | `b3_espaco` | `#1c2036` | `0.0155` | `33` | Bioma `e3` (*Espaço & Estrelas*): fundo espacial profundo |
| | `b3_aurora` | `#3e4b73` | `0.0729` | `75` | Bioma `e3` (*Espaço & Estrelas*): aurora suave e corpo da névoa reativa |
| | `nevoa_brilho` | `#8fa3b8` | `0.3549` | `160` | Crista da névoa reativa, espuma de cachoeira e reflexos suaves |

> **Separação tonal em escala de cinza das 4 âncoras:** Amarelo (`Y = 216`) > Verde (`Y = 180`) > Azul (`Y = 132`) > Vermelho (`Y = 107`), assegurando degraus mínimos de `25–48` níveis de luminância além das silhuetas e texturas distintas da seção 2.

### 1.3 Prova numérica de contraste WCAG AA (`>= 4.5:1`)

Cálculo pela fórmula WCAG 2.1 de luminância relativa `L = 0.2126·R_lin + 0.7152·G_lin + 0.0722·B_lin` (linearização com limiar `0.04045`; idêntica até 2 casas decimais à linearização usada em `test/test_stage_faixa_placar.gd`) e razão `(L_max + 0.05) / (L_min + 0.05)`.

| Par de UI / Placar | Texto (Foreground) | Fundo (Background) | Razão WCAG 2.1 | Status (`>= 4.5:1`) |
|---|---|---|---:|---|
| Texto primário sobre card/painel (`Last`/`Best`, `Modos`, `Opcoes`, `Tutorial`) | `#fffdf5` (`branco_texto`) | `#1f2738` (`painel_escuro`) | **14.67:1** | PASS (AAA) |
| Texto secundário sobre card/painel | `#d4e0e6` (`ui_texto_sec`) | `#1f2738` (`painel_escuro`) | **11.10:1** | PASS (AAA) |
| Destaque ouro (foco/badge) sobre card/painel | `#f6db61` (`amarelo_base`) | `#1f2738` (`painel_escuro`) | **10.83:1** | PASS (AAA) |
| Texto primário sobre botão padrão (`normal`) | `#fffdf5` (`branco_texto`) | `#3d6b35` (`ui_btn_base`) | **6.15:1** | PASS (AA) |
| Texto primário sobre botão padrão (`pressed`) | `#fffdf5` (`branco_texto`) | `#274a24` (`ui_btn_sombra`) | **9.86:1** | PASS (AAA) |
| Texto primário sobre CTA `Play` (`normal`) | `#fffdf5` (`branco_texto`) | `#9c521b` (`ui_cta_base`) | **5.67:1** | PASS (AA) |
| Texto primário sobre CTA `Play` (`pressed`) | `#fffdf5` (`branco_texto`) | `#6e3611` (`ui_cta_sombra`) | **9.38:1** | PASS (AAA) |
| Texto desabilitado sobre botão desabilitado (`"Ja jogado hoje"`) | `#d4e0e6` (`ui_texto_sec`) | `#3b4654` (`ui_desabilitado`) | **7.13:1** | PASS (AAA) |
| Texto HUD com contorno escuro (`Pontos`, `PowerUpHud`, `TouchHint`) | `#fffdf5` (`branco_texto`) | `#161822` (`ink_contorno`) | **17.36:1** | PASS (AAA) |
| Texto HUD sobre fundo Bioma `e0` (`Floresta Tropical`) | `#fffdf5` (`branco_texto`) | `#2d5452` (`b0_ceu`) | **8.24:1** | PASS (AAA) |
| Texto HUD sobre fundo Bioma `e1` (`Cachoeira & Neblina`) | `#fffdf5` (`branco_texto`) | `#31465c` (`b1_pedra`) | **9.54:1** | PASS (AAA) |
| Texto HUD sobre fundo Bioma `e2` (`Ruinas Celestes`) | `#fffdf5` (`branco_texto`) | `#4e4c6b` (`b2_ceu`) | **8.02:1** | PASS (AAA) |
| Texto HUD sobre fundo Bioma `e3` (`Espaco & Estrelas`) | `#fffdf5` (`branco_texto`) | `#1c2036` (`b3_espaco`) | **15.75:1** | PASS (AAA) |

#### Prova de composição alfa da faixa/overlay sobre todas as 4 plataformas (`test/test_stage_faixa_placar.gd`)

Para superfícies translúcidas (`COR_FUNDO_OVERLAY = #161822` a `70%` de opacidade, usado em `PauseOverlay`, `TouchHint` e overlays sobre o jogo; e compatibilidade retroativa mesmo a `60%`), o pior caso é o fundo sobre uma plataforma amarela (`#f6db61`):

| Plataforma atrás do overlay | Cor composta (`#161822` a `70%`) | Contraste com `#fffdf5` | Contraste com `#d4e0e6` | Status (`>= 4.5:1`) |
|---|---|---:|---:|---|
| Amarelo (`#f6db61`, pior caso) | `#595335` | **7.64:1** | **5.78:1** | PASS |
| Verde (`#79cf5a`) | `#344f33` | **8.94:1** | **6.76:1** | PASS |
| Azul (`#5987e9`) | `#2a395e` | **11.14:1** | **8.43:1** | PASS |
| Vermelho (`#ec4848`) | `#56262d` | **12.00:1** | **9.08:1** | PASS |
| *Referência legada (`#161822` a `60%` sobre Amarelo)* | *`#70663b`* | ***5.65:1*** | — | *PASS* |

No menu remodelado, o cartão do placar `Last`/`Best` usa painel sólido `#1f2738` (ou `92%` sobre `#161822`, contraste mínimo `>= 13.0:1`), mantendo folga ainda maior sobre qualquer plataforma animada ao fundo.

---

## 2. Acessibilidade sem cor (issue `#41`)

Nenhuma informação essencial de gameplay depende exclusivamente de matiz. Cada uma das 4 cores de `scripts/Enums.gd` recebe uma **identidade tátil e geométrica completa**, distinguível em **escala de cinza** a `180 px` de largura lógica e replicada de forma consistente nos 4 pontos de leitura do jogo: plataforma, gecko, partículas de troca de cor e card de tutorial.

| Cor (`Enums.COLOR`) | Tema tátil | Plataforma (`16 px` altura, 9-slice `60/56/50/44 px`) | Detalhe anatômico no Gecko (`32×32`) | Partículas / aura na troca de cor (`color_change`) | Amostra no `TutorialCard` |
|---|---|---|---|---|---|
| **Amarelo** (`#f6db61`) | **Solar / Arenito** | **Borda arredondada** nos 4 cantos + **listras verticais suaves** (`amarelo_sombra` a cada `6 px`) + brilho superior `amarelo_luz` | **Crista dorsal de pontinhas arredondadas** (3 lóbulos curtos na cabeça/dorso) + **manchas circulares** na barriga/flanco | **Círculos / raios solares** (`4×4 px` redondos + mini-raios em cruz) | Mini-plataforma solar `32×10` + mini-gecko solar `12×16` + rótulo `"amarelo"` |
| **Verde** (`#79cf5a`) | **Galho / Musgo** | **Borda orgânica** irregular com **folhinhas brotando nas duas pontas** + textura horizontal de casca/musgo pendendo `2 px` abaixo da borda superior | **Folhinha/folhagem** na ponta da cauda e 2 brotinhos foliares no topo da cabeça | **Folhas / gotas suaves** (`5×3 px` inclinadas caindo em leve arco) | Mini-plataforma galho `32×10` + mini-gecko foliar `12×16` + rótulo `"verde"` |
| **Azul** (`#5987e9`) | **Cristal / Gelo** | **Borda chanfrada angular** (`45°` nas 4 pontas) + **facetas e brilho diagonal** (`azul_luz` em barras inclinadas `45°` no miolo) | **Escamas geométricas angulares** em losango no dorso + **cristal pontudo prismático** na crista | **Losangos / cristais** (`5×5 px` em diamante com núcleo `azul_luz`) | Mini-plataforma cristal `32×10` + mini-gecko cristal `12×16` + rótulo `"azul"` |
| **Vermelho** (`#ec4848`) | **Tijolo / Vulcânico** | **Borda serrilhada / entalhada** nas extremidades (dentes de alvenaria) + **padrão de tijolinhos alternados** com rejunte em `vermelho_sombra` | **Espinhos triangulares pontudos** (3 pontas serrilhadas) ao longo do dorso e cauda | **Triângulos / faíscas** (`4×4 px` triangulares subindo rapidamente) | Mini-plataforma tijolo `32×10` + mini-gecko espinhos `12×16` + rótulo `"vermelho"` |

### Regras de preservação do `#41`

1. **Fim do tingimento chapado (`modulate`):** tanto o Gecko quanto as plataformas abandonam o tingimento de sprite branco por `Enums.get_cor(...)`. Cada variante é desenhada diretamente com sua rampa de 3 cores + contorno `ink_contorno` (`#161822`), preservando olhos (`#fffdf5` + pupila `#161822`), brilho e padrões táteis sem lavagem de cor.
2. **Validação obrigatória em escala de cinza:** a prancha de referência (`assets/src/direcao-arte-cinza-4x.png`) comprova que todas as 4 plataformas (`60 px` e `44 px`) e os 4 geckos são diferenciáveis mesmo sem saturação cromática.
3. **Tutorial bilíngue cor + padrão:** em `scenes/TutorialCard.gd`, os retângulos chapados das amostras (`=` igual / `X` diferente) e dos 4 quadrados da legenda passam a exibir mini-sprites das plataformas e do gecko com suas silhuetas e texturas reais acompanhados dos nomes (`amarelo`, `verde`, `azul`, `vermelho`).

---

## 3. Especificação de sprites e animações

### 3.1 Gecko (`scenes/Player.tscn`, `scenes/Player.gd`)

- **Tamanho do frame:** **`32×32 px`** exatos, pivô no centro `(16, 16)`. Preserva intactas:
  - `GHOST_HALF_WIDTH = 16.0` (`scenes/Player.gd:12`) para wrap horizontal contínuo nas bordas de `PlayArea.LARGURA = 180`;
  - `CollisionShape2D` do corpo (`10.28×28.52`) e `DetectorPlataforma` (`9.96×4.39`, base do pé em `y = +14 px` dentro do frame `32×32`).
- **Organização de variantes:** 4 conjuntos de `SpriteFrames` (ou prefixo por cor no mesmo `SpriteFrames`: `amarelo_*`, `verde_*`, `azul_*`, `vermelho_*`), todos compartilhando a mesma grade de frames e pontos de contato dos pés (`y = 30` do frame `32×32`) para que a troca de cor nunca cause salto visual.
- **6 animações especificadas:**

| Animação | Frames | FPS | Loop | Duração ciclo | Descrição visual e regra de transição |
|---|---:|---:|---|---|---|
| `idle` | 4 | 6 | Sim | `0.67 s` | Respiração leve de `1 px` no tronco, cauda balançando devagar; piscada de olho no frame 3 |
| `run` | 4 | 10 | Sim | `0.40 s` | Corrida energética com alternância clara de patas e corpo inclinado `1 px` para frente |
| `jump` | 2 | 10 | Não | `0.20 s` | Frame 0: esticamento de impulso; Frame 1: pose ascendente mantida enquanto `velocity.y < 0` |
| `fall` | 2 | 8 | Sim | `0.25 s` | Patas abertas para pouso, cauda erguida oscilando suavemente enquanto `velocity.y >= 0` no ar |
| `lose` | 3 | 8 | Não | `0.38 s` | Expressão cômica de susto (olhos arregalados) e pose de queda desengonçada durante a `lose_animation` de `1.5 s` |
| `color_change` | 3 | 18 | Não | `0.17 s` | Pulso rápido de transformação (silhueta iluminada -> transição de detalhe anatômico -> nova variante firme). **Não atrasa física nem colisão:** a nova `color` vale no mesmo frame do pouso; se o jogador pular ou andar imediatamente, `jump`/`run` pode interromper a animação visual sem perder a troca de variante |

- **Sincronização com `Ghost` (`scenes/Player.gd:56-69`):** `Ghost` usa o mesmo recurso de spritesheet e replica `animation`, `frame` e `flip_h` com `modulate = Color.WHITE` (pois a cor já está pintada no sprite), mantendo `modulate` livre para eventuais brilhos de power-up sem conflitar com o wrap horizontal.
- **Partículas / aura de `color_change`:** `CPUParticles2D` one-shot filho do `Player` (em coordenadas do mundo/`local_coords = false` para deixar rastro curto se o jogador se mover), emitindo **8 a 10 partículas** de `4×4`–`5×5 px` no formato da nova cor (seção 2), duração `0.28 s`, velocidade radial `28–44 px/s`, `gravity = Vector2(0, 40)`, sem colisão. Quando **Camaleão** (`Global.cor_livre`) está ativo, um emissor leve emite 1 partícula a cada `0.12 s` ciclando as 4 formas/cores como aura visual da invulnerabilidade cromática.

### 3.2 Plataformas (`scenes/Platform.tscn`, `scenes/Platform.gd`)

- **Dimensões e técnica 9-slice / 3-fatias (substituindo `region_rect`):**
  - Altura visual mantida em **`16 px`** (mesma altura de `assets/GeckoPlataforma.png` `64×16`), preservando o topo visual em `y = -8 px` e a folga exata `ICONE_FOLGA = 2.0 px` entre o topo da plataforma e a base de `PowerUpIcone` (`16×16`).
  - As 4 larguras da curva (`ressources/curva_dificuldade.tres:13,25,37,56`) — **`60 px` (`e0`), `56 px` (`e1`), `50 px` (`e2`), `44 px` (`e3`)** — **não usam mais recorte `region_rect`** (que decepava as pontas nas larguras estreitas).
  - Cada uma das 4 variantes de cor é composta como **textura 9-slice horizontal (`NinePatchRect` ou grupo de 3 `Sprite2D`: `PontaEsq` + `Miolo` + `PontaDir`)** a partir de uma peça mestre **`48×16 px`** com:
    - **Ponta esquerda (endcap):** `10×16 px` fixos (`patch_margin_left = 10`) — preserva integralmente a silhueta `#41` (canto solar arredondado, broto com folhinhas, chanfro de cristal, dentes de tijolo).
    - **Miolo repetível:** `28×16 px` no mestre (`axis_stretch_horizontal = TILE`), renderizado com largura útil de **`40 px` (`60`), `36 px` (`56`), `30 px` (`50`) e `24 px` (`44`)** — todos múltiplos pares que mantêm a textura interna sem distorção nem corte de borda.
    - **Ponta direita (endcap):** `10×16 px` fixos (`patch_margin_right = 10`), espelho simétrico da ponta esquerda.
- **Estágios de rachadura e fragmentação (plataformas que caem, `AVISO_TREMOR_S = 0.3`):**
  - Sobreposição por um nó filho dedicado **`OverlayRachadura`** (`9-slice` horizontal com os mesmos `10 px` de margem lateral, desenhado em `ink_contorno` `#161822` + destaque `1 px` `branco_texto` para legibilidade em qualquer das 4 cores):
    - **Estágio 0 (intacta):** `OverlayRachadura.visible = false`.
    - **Estágio 1 (início do desmoronamento, `_tempo_restante > AVISO_TREMOR_S`):** fissura capilar central (2 linhas finas saindo do topo), sinalizando imediatamente após o pouso que a plataforma vai cair.
    - **Estágio 2 (janela de tremor, `0.10 s < _tempo_restante <= AVISO_TREMOR_S = 0.30 s`):** rachaduras ramificadas atravessando toda a espessura da plataforma + tremor horizontal `Visual.position.x = ±1.0 px` (`TREMOR_AMPLITUDE`, 20 ciclos/s).
    - **Estágio 3 (colapso iminente, `_tempo_restante <= 0.10 s`):** fratura aberta com lacunas de `1–2 px` dividindo o miolo em 3 blocos.
  - **Fragmentação ao cair (`_tempo_restante <= 0.0`):** antes do `queue_free()` da plataforma, emitir no container pai (`RunningPlatforms` / `Stage`, para sobreviver à liberação do nó) um burst one-shot de **6 a 8 fragmentos pixel art** (`2×2`–`3×3 px` com a cor base + sombra da plataforma) caindo por `0.35 s` com gravidade (`220 px/s²`), sem colisão.
- **Compatibilidade e isolamento total de canais visuais (sem colisão entre modificadores):**

| Mecânica / ADR | Propriedade visual exclusiva | Comportamento com outros modificadores ativos |
|---|---|---|
| **Cor e padrão `#41`** | Textura da variante no nó filho `Visual` (`NinePatchRect` / 3 fatias) | Nunca usa `sprite.modulate` para tingir cor |
| **`PlatformColorCycle` (`ADR 0010`)** | Troca de textura de `Visual` entre `color` e `proxima_cor()` + pulso de **`Visual.modulate.a`** (`1.0` ↔ `AVISO_ALFA_BAIXO = 0.55` a `12 fases/s`) | Como alterna a textura inteira (não apenas matiz), o aviso pré-troca exibe a **próxima silhueta/padrão `#41`** para jogadores daltônicos e não toca `self.modulate.a` |
| **`PlatformBlink` (`ADR 0012`)** | Exclusivamente **`self.modulate.a`** no nó raiz `Platform` (`1.0` visível, `0.35` no flicker a `20 fases/s`, `0.20` fantasma) | Compõe multiplicativamente com `Visual.modulate.a` do `ColorCycle` sem nunca sobrescrever nem ser sobrescrito por ele |
| **Desmoronamento (`AVISO_TREMOR_S = 0.3`)** | Frame de **`OverlayRachadura`** + deslocamento **`Visual.position.x`** (`±1.0 px`) + burst de partículas no pai | Ortogonal a `self.modulate.a`, `Visual.modulate.a` e troca de textura; uma plataforma que pisca, cicla e desmorona simultaneamente preserva todos os 3 sinais visuais sem conflito |

### 3.3 Power-ups (`PowerUpIcone`, `PowerUpHud`), Modos (`ModosScreen`) e Ícone (`icon.png`)

- **Ícones `16×16` de power-up (`ADR 0014`):** usados de forma idêntica sobre a plataforma (`base 2 px acima do topo`) e no `PowerUpHud` (`y = s_top + 30..46`). Nunca usam cor de plataforma como pista única — a leitura primária é **silhueta + moldura escura `ink_contorno` + preenchimento alto-contraste `branco_texto`**:
  - **`camaleao` (`16×16`):** medalhão octogonal com contorno `#161822`, aro `#fffdf5` e 4 micro-quadrantes `5×5` exibindo os 4 micro-símbolos táteis (ponto, folha, losango, triângulo) com os 4 matizes da paleta — legível tanto em cor quanto em cinza pela grade 2×2.
  - **`desacelera` (`16×16`):** ampulheta pixel art de cintura estreita com contorno `#161822`, vidro `#fffdf5` / `#8fa3b8` e areia fluindo em `#c9772e` (`ui_cta_luz`) — distinguível pela silhueta de dois triângulos opostos.
  - **`segunda_chance` (`16×16`):** cruz/escudo alado de resgate com contorno `#161822`, corpo `#fffdf5` e núcleo dourado `#f6db61` / `#c9772e` — distinguível pela silhueta de `+` com mini-asas laterais.
  - **Fallback para tipos de teste:** mantém geração determinística em `#fffdf5` sobre `#161822` (compatível com `PowerUpDesenho`).
- **Estilo do `PowerUpHud` (`y = s_top + 30..46`):**
  - Barra de duração `40×4 px` (`x = 22..62`, `y = s_top + 36..40`): moldura `1 px` `ink_contorno` `#161822`, trilho vazio `painel_escuro` `#1f2738`, preenchimento `branco_texto` `#fffdf5` com sombra inferior `1 px` `ui_texto_sec` esvaziando estritamente da direita para a esquerda (leitura por extensão).
  - Segundos restantes (`x = 66..82`) e relógio `m:ss` do modo Contra o tempo (`x = 138..178`): fonte `16 px`, `branco_texto` `#fffdf5` com contorno `1 px` `ink_contorno` `#161822`.
  - Carga de `segunda_chance` (`x = 90..106`): mesmo sprite `16×16` sobre a plataforma, oculto sem carga.
- **5 ilustrações `64×64` dos modos (`ModosScreen`, `x = 58..122` do bloco):**
  - Todas emolduradas por borda `1 px` `ink_contorno` + filete interno `1 px` `ui_texto_sec`, usando apenas a paleta oficial de 32 cores:
    1. **`classico` (`64×64`):** gecko em pleno salto sobre plataformas de cores distintas, fundo *Floresta Tropical* (`b0_ceu`/`b0_folhagem`) e pequeno ícone brilhante de power-up flutuando.
    2. **`puro` (`64×64`):** gecko focado sobre plataforma limpa de arenito sob céu minimalista com estrelas discretas, sem ícones extras (comunica imediatamente "sem power-ups").
    3. **`tempo` (`64×64`):** gecko escalando em diagonal diante de um cronômetro retrô grande no centro com ponteiro em destaque `ui_cta_luz`/`amarelo_base`.
    4. **`zen` (`64×64`):** gecko relaxado sentado numa plataforma de musgo verde sob nuvens suaves e folhas flutuando devagar, sem névoa de perigo na base.
    5. **`diario` (`64×64`):** página de calendário pixel art destacada com estrela dourada (`amarelo_base`) no topo e silhueta do gecko saltando na base.
  - **Fallback para `teste` (flag debug):** moldura `painel_escuro` `#1f2738` com ícone geométrico de engrenagem/grade `16×16` em `ui_texto_sec` centrado, preservando o carrossel debug sem exigir ilustração dedicada.
- **Ícone do jogo (`icon.png` e variantes de export):**
  - Arte mestre **`64×64 px`** em pixel art: busto/rosto expressivo do gecko verde (`verde_base`/`verde_luz`/`verde_sombra`) com olhos grandes (`branco_texto` + pupila `ink_contorno`), sorriso simpático e pequeno brilho `amarelo_base` no canto, sobre fundo `b0_ceu` `#2d5452` com moldura arredondada `painel_escuro` e contorno `ink_contorno`.
  - **Exportação sem interpolação (`Nearest`):**
    - `icon.png` (raiz, `project.godot:16`): **`64×64 px`** (ou `128×128 px` em escala `2×` inteira, substituindo o `32×32` provisório).
    - Variantes Web/PWA (`export_presets.cfg:34-36`, preenchidas na entrega de polimento/publicação E7) e loja (itch.io E7 / Play Store E8): **`144×144 px`** (`2×` de `64×64` centrado com `8 px` de borda de fundo `b0_ceu`), **`180×180 px`** (`2×` com margem segura `26 px`) e **`512×512 px`** (`8×` inteiro exato de `64×64`, com zona segura central de `66%` para recorte adaptativo Android).

---

## 4. Cenário — 4 biomas, parallax, partículas e névoa reativa

### 4.1 Mapeamento dos 4 biomas aos estágios (`ressources/curva_dificuldade.tres`)

| Estágio | `progresso_inicio` | Bioma | Paleta travada (baixa saturação) | Camada 1 (longe, `0.15×`) | Camada 2 (média, `0.30×`) | Camada 3 (partículas ambientais) |
|---|---:|---|---|---|---|---|
| **`e0`** | `0.0` | **Floresta Tropical** | `b0_ceu` `#2d5452` + `b0_folhagem` `#3b6b61` | Silhueta contínua de montanhas e copa densa ao longe | Troncos verticais suaves nas bordas laterais + cipós discretos | 8–10 folhas pixel (`3×2 px`, `b0_folhagem`, alfa `0.40`) descendo em deriva diagonal lenta |
| **`e1`** | `0.35` | **Cachoeira & Neblina** | `b1_pedra` `#31465c` + `b1_bruma` `#57738a` + detalhes `nevoa_brilho` | Paredão de rocha úmida em relevo suave | Faixas verticais sutis de cachoeira (animação 2 frames) + bancos de bruma | 10–12 gotículas/vapor (`2×2 px`, `nevoa_brilho`, alfa `0.35`) flutuando para cima |
| **`e2`** | `0.70` | **Ruínas Celestes** | `b2_ceu` `#4e4c6b` + `b2_pedra` `#6e6b85` + detalhes `nevoa_brilho` | Camada de nuvens planas em horizonte elevado | Arcos de pedra antigos e pilares quebrados nas margens | 8–10 motas de poeira luminosa (`2×2 px`, `amarelo_luz` a alfa `0.30`) + nuvens lentas |
| **`e3`** | `1.00` | **Espaço & Estrelas** | `b3_espaco` `#1c2036` + `b3_aurora` `#3e4b73` + pontos `ui_texto_sec` | Nebulosa/aurora em faixas suaves verticais | Constelações e micro-planetas silhuetados muito distantes | 10–14 estrelas cintilantes (`1×1`–`2×2 px`, `ui_texto_sec`/`nevoa_brilho`, alfa `0.25–0.45`) |

### 4.2 Transições de bioma, modos sem estágio fixo e janela larga

1. **Modos com progressão de estágio (`Classico`, `Tempo`, `Diario` e `Puro` durante `e0..e3`):**
   - Ao receber o sinal `dificuldade.estagio_mudou(novo)` (`0 -> 1 -> 2 -> 3`), o controlador de fundo executa **crossfade suave de `1.2 s`** entre o bioma atual e o novo bioma (interpolação de opacidade entre grupos de camadas, mantendo o scroll vertical contínuo sem pulo de posição).
2. **Alternância cíclica por distância nos modos sem estágio fixo (`Zen`) e pós-platô (`Puro` / `Classico` após `e3`):**
   - No modo **`Zen`** (`fator_scroll_forcado = 0.0`, sem avanço de estágio na curva de dificuldade) — e igualmente em **`Puro`** ou **`Classico`** após atingir o platô `e3` — o cenário não fica estático indefinidamente: o controlador monitora `ScrollLevel.position_scrolled` (que avança tanto pelo scroll da curva quanto pelo `avancar_camera` da issue `#46`) e a cada **`1.200 px` lógicos acumulados** (~24 linhas de plataformas) promove uma **transição cíclica suave** (`e0 -> e1 -> e2 -> e3 -> e0`) com crossfade estendido de **`1.8 s`**.
3. **Arquitetura modular em loop vertical (`320 px` até `462+ px` em `keep_width`):**
   - Todas as camadas de parallax vivem em `z_index < 0` (sempre abaixo de plataformas, gecko, névoa e HUD).
   - **Camada 0 (base de céu):** `ColorRect` / textura gradiente vertical dithered `180×240 px` preenchida em toda a altura visível (`visible_size.y`), velocidade `0.05×`.
   - **Camadas 1 e 2 (parallax):** tiles verticais sem costura **`180×240 px`** (ou `180×180 px` para detalhes médios), configurados com `repeat_size = Vector2(0, 240)` e `repeat_times = 3` (cobrindo `720 px` verticais contínuos, garantindo zero bordas descobertas em `180×320`, `180×400` e `180×462+`).
   - **Produção enxuta:** cada bioma precisa de apenas 2 tiles compactos (`180×240`) + 1 sprite de partícula (`4×4`), evitando sobrecarga de acabamento manual no Aseprite.
4. **Cor das barras laterais em janela larga (`1280×720`, `1920×1080`):**
   - Em janela paisagem desktop/Web (`stretch/aspect = "keep_width"`), a área fora da coluna lógica de `180 px` exibe `rendering/environment/defaults/default_clear_color`.
   - O `default_clear_color` em `project.godot:87` passa a **`painel_escuro` `#1f2738`** (`Color(0.1216, 0.1529, 0.2196, 1.0)`), emoldurando o jogo com tom neutro-escuro coerente com todos os 4 biomas (sem contrastar agressivamente contra o Espaço `e3` nem parecer uma borda branca/turquesa solta na Floresta `e0`).

### 4.3 Névoa reativa na base (zona de derrota)

- **Função visual:** comunicar intuitivamente, sem texto, que cair pela borda inferior causa derrota (`CheckPlayer`, logo abaixo de `visible_size.y`).
- **Construção visual:** 2 faixas pixel art sobrepostas (`tile 180×32 px`, recorte ondulado com dither 16-bit em `b3_aurora` `#3e4b73` + crista `nevoa_brilho` `#8fa3b8`, sem gradiente borrado), deslizando horizontalmente em velocidades lentas opostas (`+8 px/s` e `-5 px/s`), ancoradas na borda inferior visível (`y = H`), renderizadas acima do cenário e abaixo do HUD (`layer` abaixo de `CanvasLayer` de HUD, `mouse_filter = IGNORE`).
- **Comportamento reativo por proximidade do gecko:**
  - **No menu (`!started`):** permanece suave e discreta na base (`altura visível = 14 px`, `opacidade = 0.35`, abaixo do último slot do menu).
  - **Em partida com derrota (`Classico`, `Puro`, `Tempo`, `Diario`):**
    - Zona segura (`player.global_position.y < H - 88`): `altura visível = 16 px`, `opacidade = 0.45`.
    - Zona de aproximação (`H - 88 <= player.global_position.y <= H - 16`): fator de perigo `p = clamp((player.y - (H - 88)) / 72.0, 0.0, 1.0)`. A névoa sobe linearmente de **`16 px` até `32 px`** e sua opacidade intensifica de **`0.45` até `0.85`** (com ondulação de frequência `+40%` quando `p > 0.5`), dando feedback imediato antes da queda sem bloquear a leitura da plataforma inferior.
- **Ocultação explícita no modo Zen:**
  - No modo **`Zen`** (`Global.get_modo_jogo() == GameModes.ID_ZEN`, onde não existe derrota e a queda devolve o gecko a uma plataforma) — e também sob `Global.sem_derrota` — a névoa reativa fica **completamente oculta (`visible = false`, `modulate.a = 0.0`)**. A visibilidade é reavaliada imediatamente ao trocar de modo no menu (`_fechar_modos`) e no início da cena (`_ready`).

---

## 5. Tipografia comercial livre, Kit UI e Remodelagem completa do Menu

### 5.1 Fonte comercial livre substituta

A fonte atual (`fonts/alterebro-pixel-font.ttf`) possui licença **CC BY-NC** (não comercial), incompatível com a distribuição comercial planejada (itch.io **E7** e anúncios/IAP na Play Store **E8**).

- **Recomendação primária:** **`m5x7`** (autor: Daniel Linssen, licença **CC0 1.0 Universal** — domínio público, uso comercial irrestrito).
  - **Tamanho nativo:** **`16 px`** (`UiHelpers.FONTE_NATIVO = 16`), grade `5×7 px` por maiúscula (avanço típico `5–6 px`, compatível com `docs/fonte-pixel-tamanho-nativo.md`).
  - **Escala inteira preservada:** `UiHelpers.TAMANHOS_UI = [16, 32]` (`TAMANHO_TITULO = 32`, `TAMANHO_BOTAO = 32` para `"Play"`, `TAMANHO_TEXTO = 16` para botões de menu, placar `Last`/`Best`, `"Ja jogado hoje"`, `TutorialCard`, `ModosScreen` e `OptionsScreen`), mantendo íntegro o contrato de `test/test_ui_tamanhos.gd`.
  - **Parâmetros obrigatórios no `.import` (travados por `test/test_ui_tamanhos.gd:80-86`):**
    - `antialiasing = 0`
    - `hinting = 0`
    - `subpixel_positioning = 0`
    - `oversampling = 1.0`
    - `generate_mipmaps = false`
  - **Cobertura de glifos:** cobre integralmente todo o conjunto ASCII usado nas strings do jogo (`A–Z`, `a–z`, `0–9`, `: . , ! ? - + < > = / %`), além de acentuação latina básica para eventual localização futura.
- **Alternativas comerciais pré-qualificadas (contingência métrica):** caso a validação real com `FontFile.get_string_size()` na troca da fonte aponte qualquer divergência métrica de `m5x7` frente a `UiHelpers.TAMANHOS_UI = [16, 32]` ou aos limites de largura de `TutorialCard` (`148 px`) e `OptionsScreen` (`112 px`), adotar em ordem de preferência:
  1. **`m3x6`** (Daniel Linssen, **CC0**, nativo `16 px`, proporção ultra-compacta `3×6 px`, avanço `4 px`, margem ainda maior em `180 px`).
  2. **`Tiny5`** ou **`Silkscreen`** (**SIL OFL 1.1**, nativo `8 px`, portanto múltiplos inteiros exatos em **`16 px` = `2×`** e **`32 px` = `4×`**, preservando `TAMANHOS_UI = [16, 32]` com cobertura Latin-1 completa).

### 5.2 Kit UI em pixel art (reutilizável em E6, E5 e E8)

Todos os controles migram de `StyleBoxFlat` liso para `StyleBoxTexture` 9-slice em pixel art (`filter = Nearest`, sem antialiasing), preservando `>= 24×24 px` de alvo interativo e pistas não-cor em todos os estados:

| Componente | Construção 9-slice / Sprite | Estados e pistas não-cor |
|---|---|---|
| **Botão padrão** (`Modo`, `Opcoes`, `Pausa`, `Modos`, `Options`, `Ranking` E5, `Remover anuncios` E8) | Peça mestre `24×24 px`, `patch_margin = 4 px` nos 4 lados. Borda externa `1 px` `ink_contorno`, chanfro superior `1 px` `ui_btn_luz`, corpo `ui_btn_base`, sombra inferior `2 px` `ui_btn_sombra` | **`normal`:** rótulo centrado (`branco_texto`, contorno `1 px` `ink_contorno`). **`pressed`:** borda `2 px` `ink_contorno`, corpo `ui_btn_sombra`, chanfro invertido, rótulo `+1 px` em Y. **`disabled`:** corpo `ui_desabilitado`, texto `ui_texto_sec`, sem brilho superior. **`focus`:** moldura externa `2 px` `amarelo_base` + `1 px` `ink_contorno` (`1 px` fora do botão) + prefixo `"> "` no rótulo |
| **Botão CTA `Play`** | Peça mestre `24×24 px`, `patch_margin = 4 px`. Mesma geometria biselada, usando rampa quente `ui_cta_luz` / `ui_cta_base` / `ui_cta_sombra` | Mesmos 4 estados acima; no estado bloqueado do Desafio Diário (`"Ja jogado hoje"`), troca para o estilo `disabled` (`ui_desabilitado` + `ui_texto_sec`) e fonte `16 px` |
| **Ativos prontos para E5 e E8** | **`Ranking` (E5):** botão padrão + mini-ícone troféu `12×12 px` (`amarelo_base` + `ink_contorno`). **`Remover anuncios` (E8):** botão padrão + mini-ícone "AD" riscado `12×12 px` (`ui_texto_sec` + `vermelho_base` + `ink_contorno`) | Entregues prontos no kit UI para ativação imediata no E5 e no E8 sem alterar coordenadas; **não são exibidos como botões mortos antes de seus respectivos marcos** (ver seção 5.3) |
| **Painéis e cards** (`CardPlacar`, `TutorialCard`, telas `Modos` e `Opcoes`) | Peça mestre `24×24 px`, `patch_margin = 4 px`. Borda externa `1 px` `ink_contorno`, filete interno `1 px` `b1_bruma`, fundo `painel_escuro` `#1f2738` | `CardPlacar` no menu usa `painel_escuro` sólido (contraste `14.67:1`); fundo de tela cheia dos overlays usa `ink_contorno` `#161822` a `70%` |
| **Sliders (`OptionsScreen`)** | Trilho `148×6 px` em `ink_contorno` com borda `1 px` `ui_texto_sec`; preenchimento pixel art em `ui_btn_luz` `#5b8a4a`; cursor `12×16 px` (`14×20 px` ao arrastar) em `branco_texto` com 2 ranhuras verticais `ui_desabilitado` e contorno `ink_contorno` | Mantém medidas exatas de `scenes/OptionsScreen.gd`, rótulo `"mudo"` em `0`, cursor alargado ao arrastar e moldura + `"> "` no foco |
| **`PauseBotao` (`24×24`)** | 9-slice do botão padrão (`24×24`) em `x[s_left + 2, s_left + 26]`, `y[s_top + 2, s_top + 26]` | Glifo pixel art de 2 barras `3×12 px` em `branco_texto` com contorno `1 px` `ink_contorno` (`+1 px` em Y no `pressed`); oculto fora de partida ativa |
| **`LevelUpFrame`** | Vinheta de borda (`PROFUNDIDADE = 20 px` dentro da `safe_area`) + cantoneiras pixel art sutis `8×8 px` nos 4 cantos | Pulsa `N` vezes (`N = estagio novo`) em `amarelo_luz` / `branco_texto` (`ALPHA_PICO = 0.5`), sem texto, `MOUSE_FILTER_IGNORE` e congelado na pausa (`ADR 0008`) |
| **`TouchHint`** | Linha divisória em `x = 90` (traço `2 px` liga / `2 px` desliga em `branco_texto` a `60%` com sombra `1 px` `ink_contorno`); setas direcionais pixel art `24×24` (`branco_texto` + contorno `ink_contorno`) | Faixa `COR_FUNDO_OVERLAY` atrás das 2 linhas de texto (`16 px`), preservando todos os retângulos e regras de fade-out de `scenes/TouchHint.gd` |
| **`TutorialCard`** | Card `164 px` de largura (`148 px` de conteúdo útil em `180×320`) com 9-slice de painel e botão `Pular`/`Voltar` no estilo padrão | Amostras `=` / `X` e legenda `2×2` exibem mini-sprites acessíveis (`#41`, seção 2) com nomes por escrito, mantendo toda linha `<= 148 px` em `16 px` |

### 5.3 Remodelagem completa do menu (`180×320` e `180×400+`)

#### Decisão de produto para o slot E8 ("Remover anúncios") e slot E5 ("Ranking")

- **Slot `Remover anuncios` (E8) — Opção A (aprovada):** o menu mantém o **espaço reservado vazio** nas coordenadas da tabela abaixo durante o E6 e a publicação gratuita do E7 no itch.io (evitando exibir um botão morto/desabilitado que confundiria jogadores da versão gratuita), enquanto o ativo visual completo (botão 9-slice + ícone "sem anúncios") já fica pronto no kit UI para ativação direta no E8.
- **Slot `Ranking` (E5):** segue o mesmo princípio de espaço reservado vazio nas coordenadas fixas abaixo até a entrega do E5, garantindo que tanto E5 quanto E8 ativem seus botões no lugar sem mover `Logo`, `Play`, `Modo`, `CardPlacar` ou `Opcoes`.
- **Visibilidade do HUD `Pontos` no menu:** durante o estado de menu (`!started`), o rótulo `Pontos` (`x[41, 178], y[s_top, s_top + 30]`) fica **oculto** para não poluir o topo acima do logo `"GECKO JUMP"`, passando a visível assim que a partida inicia (`started == true`).

#### Regra única de ancoragem (vale para `180×320`, `180×400` e `180×462+`)

Todos os elementos do menu compõem um **bloco unificado centrado** (classe **centro**) de altura total **`H_BLOCO = 278 px`**, contido integralmente na `safe_area`:

- **Símbolos:** `s_top = safe.position.y`, `s_bottom = H - safe.end.y`, `s_left = safe.position.x`, `s_right = 180 - safe.end.x`, altura útil `U = H - s_top - s_bottom`, largura útil `W_util = 180 - s_left - s_right`.
- **Origem vertical:** `y0 = max(s_top, floor(s_top + (U - 278) / 2))`.
- **Origem horizontal de cada elemento de largura `w`:** `x0 = s_left + floor((W_util - w) / 2)`.
- **Cobertura garantida de `safe_area`:** como `H_BLOCO = 278 px`, o bloco inteiro cabe folgadamente dentro de:
  - `180×320` sem entalhe (`U = 320` → `y0 = 21`, fim `y = 299`);
  - `180×320` com entalhe padrão (`s_top = 20, s_bottom = 6`, `U = 294` → `y0 = 28`, fim `y = 306 <= 314`);
  - `180×320` com entalhe extremo (`s_top = 30, s_bottom = 0`, `U = 290` → `y0 = 36`, fim `y = 314 <= 320`);
  - `180×400` sem entalhe (`U = 400` → `y0 = 61`, fim `y = 339`);
  - `180×400` com entalhe (`s_top = 20, s_bottom = 6`, `U = 374` → `y0 = 68`, fim `y = 346 <= 394`);
  - `180×462` com entalhe (`s_top = 20, s_bottom = 10`, `U = 432` → `y0 = 97`, fim `y = 375 <= 452`).

#### Tabela única de coordenadas exatas (px lógicos)

Valores horizontais com `s_left = s_right = 0`. A coluna `180×320` assume `s_top = s_bottom = 0` (`y0 = 21`); a coluna `180×400` assume `s_top = s_bottom = 0` (`y0 = 61`); com entalhe, soma-se apenas a variação de `y0` da fórmula acima.

| Elemento | Tamanho (`w×h`) | `y_rel` no bloco | Folga abaixo | `180×320` (`y0 = 21`) | `180×400` (`y0 = 61`) | Estado / Regra |
|---|---|---|---:|---|---|---|
| **Logo `"GECKO JUMP"`** | `156×48` | `[0, 48]` | `10 px` | `x[12, 168] y[21, 69]` | `x[12, 168] y[61, 109]` | Sprite pixel art (não interativo); título 2 linhas com silhueta do gecko |
| **Botão `Play` (normal)** | `124×36` | `[58, 94]` | `8 px` | `x[28, 152] y[79, 115]` | `x[28, 152] y[119, 155]` | CTA `ui_cta_base`, fonte `32 px`; alvo `>= 24×24` |
| **Botão `Play` (estendido Diário)** | `148×36` | `[58, 94]` | `8 px` | `x[16, 164] y[79, 115]` | `x[16, 164] y[119, 155]` | Texto `"Ja jogado hoje"` em `16 px`, estado `disabled`; mesma altura/faixa `y` do normal |
| **Botão `Modo: <nome>`** | `148×26` | `[102, 128]` | `8 px` | `x[16, 164] y[123, 149]` | `x[16, 164] y[163, 189]` | Botão padrão `ui_btn_base`, fonte `16 px`; comporta todos os rótulos de `GameModes.gd` |
| **Card Placar (`FaixaPlacar`)** | `164×42` | `[136, 178]` | `10 px` | `x[8, 172] y[157, 199]` | `x[8, 172] y[197, 239]` | Painel `painel_escuro` (`MOUSE_FILTER_IGNORE`); envolve `Last` e `Best` |
| └─ **Linha `Last`** *(filho do card)* | `156×17` | `[139, 156]` | `2 px` | `x[12, 168] y[160, 177]` | `x[12, 168] y[200, 217]` | Fonte `16 px`, contorno `1 px`; comporta 4 dígitos (`9999`) |
| └─ **Linha `Best`** *(filho do card)* | `156×17` | `[158, 175]` | `3 px` *(pad)* | `x[12, 168] y[179, 196]` | `x[12, 168] y[219, 236]` | Fonte `16 px`, contorno `1 px`; oculta no modo Zen sem mover o card |
| **Botão `Opcoes`** | `132×26` | `[188, 214]` | `6 px` | `x[24, 156] y[209, 235]` | `x[24, 156] y[249, 275]` | Botão padrão `ui_btn_base`, fonte `16 px`; ativo em E6/E7/E5/E8 |
| **Slot `Ranking` (E5)** | `132×26` | `[220, 246]` | `6 px` | `x[24, 156] y[241, 267]` | `x[24, 156] y[281, 307]` | **Reservado vazio antes do E5**; ativo no E5 no mesmo retângulo |
| **Slot `Remover anuncios` (E8)** | `148×26` | `[252, 278]` | — | `x[16, 164] y[273, 299]` | `x[16, 164] y[313, 339]` | **Opção A: reservado vazio antes do E8 + ativo pronto no kit UI**; ativo no E8 |

#### Prova matemática de pior caso (zero interseção, folgas e textos)

1. **Disjunção mútua e folga `>= 2 px`:**
   - Todos os 7 blocos principais ocupam faixas verticais estritamente crescentes e disjuntas: `[0, 48]`, `[58, 94]`, `[102, 128]`, `[136, 178]`, `[188, 214]`, `[220, 246]`, `[252, 278]`.
   - Folgas verticais entre blocos adjacentes: **`10 px`, `8 px`, `8 px`, `10 px`, `6 px`, `6 px`** — todas `>= 6 px` (mesmo descontando `1 px` externo da moldura de foco em dois botões vizinhos, restam `>= 4 px >= 2 px`).
   - Dentro do `CardPlacar`, `Last` (`[139, 156]`) e `Best` (`[158, 175]`) são disjuntos com folga exata de **`2 px`** e `3 px` de respiro superior/inferior dentro do painel `[136, 178]`.
2. **Alvos interativos `>= 24×24`:** `Play` (`124×36` / `148×36`), `Modo` (`148×26`), `Opcoes` (`132×26`), slot `Ranking` (`132×26`) e slot `Remover anuncios` (`148×26`) — todos têm largura `>= 124 px` e altura `>= 26 px` (`>= 24×24`).
3. **Pior caso de largura de texto (`m5x7` a `16 px`: avanço máx. `6 px/caractere`; `32 px`: `12 px/caractere`):**
   - `"> Play"` em `32 px`: `6 × 12 = 72 px <= 124 px` (sobra `52 px`).
   - `"Ja jogado hoje"` em `16 px` (Desafio Diário): `14 × 6 = 84 px <= 148 px` (mesmo em fonte contingência de avanço `7 px`: `98 px <= 148 px`, sobra `50 px`).
   - `"> Modo: Classico"` (rótulo curto mais longo de `scripts/GameModes.gd`): `16 × 6 = 96 px <= 148 px` (sobra `52 px`). Comporta até o hipotético rótulo longo `"> Modo: Contra o tempo"` (`22 × 6 = 132 px <= 148 px`, sobra `16 px`).
   - `"Melhor pontuacao: 9999"` e `"Ultima pontuacao: 9999"` (4 dígitos em `16 px`): `22 × 6 = 132 px <= 156 px` úteis do `CardPlacar` (mesmo em fonte contingência `7 px`: `154 px <= 156 px`).
   - `"> Opcoes"`: `8 × 6 = 48 px <= 132 px` (sobra `84 px`).
   - `"> Ranking"`: `9 × 6 = 54 px <= 132 px` (sobra `78 px`).
   - `"> Remover anuncios"`: `18 × 6 = 108 px <= 148 px` (sobra `40 px`).

```text
 escala aproximada: 1 coluna = 5 px; mostra 180x320 (y0 = 21); vale a tabela
 +------------------------------------+  y = 0
 |                                    |
 |   +----------------------------+   |  y 21..69   Logo "GECKO JUMP" (156x48)
 |   |         GECKO JUMP         |   |
 |   +----------------------------+   |
 |                                    |  folga 10 px
 |    [         Play         ]        |  y 79..115  Play (124x36 | estendido 148x36)
 |                                    |  folga 8 px
 |    [    Modo: Classico    ]        |  y 123..149 Modo (148x26)
 |                                    |  folga 8 px
 |  +------------------------------+  |  y 157..199 Card Placar (164x42)
 |  |   Ultima pontuacao: 9999     |  |  y 160..177 Last (16 px)
 |  |   Melhor pontuacao: 9999     |  |  y 179..196 Best (16 px, folga 2 px)
 |  +------------------------------+  |
 |                                    |  folga 10 px
 |      [       Opcoes       ]        |  y 209..235 Opcoes (132x26)
 |      :     (Ranking E5)   :        |  y 241..267 Slot reservado vazio (E5)
 |    :   (Remover anuncios E8)  :    |  y 273..299 Slot reservado vazio (E8)
 |~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|  y 306..320 Nevoa suave (oculta no Zen)
 +------------------------------------+  y = 320
```

#### Ordem de foco no menu (teclado / joypad)

- Em **E6 / E7:** ciclo vertical `Play` ↔ `Modo` ↔ `Opcoes` (pula slots vazios reservados).
- Em **E5:** `Play` ↔ `Modo` ↔ `Opcoes` ↔ `Ranking`.
- Em **E8:** `Play` ↔ `Modo` ↔ `Opcoes` ↔ `Ranking` ↔ `Remover anuncios`.

### 5.4 Nota de impacto em testes e roteiros de smoke na entrega de UI/Menu

A remodelagem completa do menu e a troca da fonte `.ttf` na etapa de UI do E6 têm impacto previsto e planejado sobre os seguintes artefatos de validação:

- **Testes GUT de layout, fonte e contraste (`test/`):**
  - `test/test_stage_hud.gd` — atualizar expectativas de `Rect2` de `Play`, `Last`, `Best` (que migram da ancoragem de topo antiga `y = 147 / 230 / 248` para o bloco centrado `H_BLOCO = 278`) e validar ocultação de `Pontos` no menu / visibilidade na partida;
  - `test/test_stage_faixa_placar.gd` — atualizar cor/estilo do card do placar (`painel_escuro` / `COR_FUNDO_OVERLAY`) e checagem de não-sobreposição com o novo layout;
  - `test/test_modo_botao.gd` e `test/test_opcoes_botao.gd` — atualizar constantes de `Rect2` de `ModoBotao` (`148×26`) e `OpcoesBotao` (`132×26`) e a fórmula de centro na `safe_area`;
  - `test/test_ui_tamanhos.gd` — atualizar o caminho `FONTE_IMPORT` de `alterebro-pixel-font.ttf.import` para o arquivo `.import` da fonte comercial (`m5x7`), preservando todas as asserções de `TAMANHOS_UI = [16, 32]`, `hinting = 0`, `subpixel_positioning = 0`, `oversampling = 1.0` e `antialiasing = 0`.
- **Roteiros de smoke (`test/smoke/*.smoke.json`):**
  - Todos os roteiros que disparam clique/toque por coordenadas fixas nos botões do menu (`Play`, `Modo`, `Opcoes` — cerca de 10 roteiros, incluindo `modos.smoke.json`, `opcoes.smoke.json`, `opcoes-persistencia.smoke.json`, `modo-puro.smoke.json`, `modo-tempo.smoke.json`, `modo-zen.smoke.json`, `modo-diario.smoke.json` e `tutorial-reabertura.smoke.json`) devem ser atualizados para os centros exatos dos novos retângulos da tabela da seção 5.3.

---

## 6. Direção de Áudio (SFX e Música Dinâmica)

### 6.1 Estética sonora, buses e fluxo de síntese de SFX

- **Estética:** **Chiptune retrô alegre/arcade**, coesa com a identidade 16-bit/GBC das seções 1–4 — timbres limpos de ondas quadrada, triângulo, pulso e ruído curto, com ataque rápido para feedback tátil imediato e sem fadiga auditiva em sessões longas.
- **Buses de áudio (`default_bus_layout.tres`):**
  - `Master` (`bus 0`) — saída final.
  - `Music` (`bus 1` -> `Master`) — música dinâmica em 4 variações e stingers musicais.
  - `SFX` (`bus 2` -> `Master`) — efeitos de gameplay e interface.
- **Controle de volume (`scripts/Global.gd:271-300`, `scripts/OptionsStore.gd:15-26`):**
  - Sliders de `OptionsScreen` entregam ganho linear em `[0.0, 1.0]`, convertido por `OptionsStore.volume_linear_to_db(linear)` com piso finito `MUTE_DB = -80.0 dB`.
  - Em `linear <= 0.0` (`0%`), o bus recebe `-80.0 dB` **e** `AudioServer.set_bus_mute(idx, true)`, garantindo silêncio total.
- **Pré-requisito e formato de produção de SFX:**
  - Os efeitos sonoros do bus `SFX` serão sintetizados e iterados com uma **ferramenta/agente local de síntese retrô baseada em `jsfxr`**, gerando sempre pares versionados em `sounds/`:
    - `<nome>.wav` (PCM 16-bit, `44.1 kHz`, mono, normalizado com pico em **`-3 dBFS`** para evitar clipping em sobreposições);
    - `<nome>.sfx.json` (parâmetros e semente completos de síntese, garantindo reprodutibilidade, ajustes finos posteriores e comprovação de origem autoral).

### 6.2 Inventário completo de SFX (bus `SFX`)

| Cue | Arquivos (`sounds/`) | Trigger exato no código | Estética / duração | Prioridade e anti-sobreposição | `process_mode` | Regras de exceção obrigatórias |
|---|---|---|---|---|---|---|
| **Pulo** | `jump.wav` + `jump.sfx.json` | `Player._physics_process` (`scenes/Player.gd:109-113`, `JumpAudio`) | Sweep ascendente alegre (`square`/`triangle`), `0.10–0.14 s` | Média; `polyphony = 1` (novo pulo reinicia o player) | `INHERIT` (pausável) | Substitui `sounds/jump.wav` atual (sem registro de licença). Só toca com `on_ground == true` e partida ativa. |
| **Pouso que pontua (`#13`)** | `land_point.wav` + `land_point.sfx.json` | `Stage.add_point()` (`scenes/Stage.gd:925-941`, via `_on_player_add_point`) | Plim/chime arcade curto e nítido, `0.09–0.13 s` | Média; `polyphony = 2`, cooldown `40 ms`; cede destaque se coincidir com `powerup_collect` | `INHERIT` (pausável) | **Separação estrita:** dispara **somente** quando `points >= 0` antes do incremento (`0 -> 1`, `1 -> 2`, ...) e `state != STATE_LOST`. **Nunca dispara** no salto/pouso inicial `-1 -> 0` (`scenes/Stage.gd:928-930`) nem nos reaparecimentos sem ponto (`Segunda chance` em `Stage._tentar_reaparecimento` e `Zen` em `Stage._reposicionar_na_ultima_plataforma`, protegidos por `_guarda_reaparecimento` em `scenes/Player.gd:80,189`). |
| **Derrota** | `lose.wav` + `lose.sfx.json` | `Stage._encerrar_partida` (`scenes/Stage.gd:806-810`, `LoseAudio`) | Descida chiptune expressiva de fim de partida, `0.50–0.65 s` | Máxima; interrompe `stage_up` caso coincidam | `INHERIT` (pausável) | Substitui `sounds/lose.wav` atual (sem registro de licença). Toca em derrota por queda ou por fim do relógio (`Contra o tempo`). **Não dispara** em `Sair` da pausa (`scenes/Stage.gd:572-578`), resgate `Segunda chance` ou reposicionamento `Zen`. |
| **Aviso de subida de estágio (`#43`)** | `stage_up.wav` + `stage_up.sfx.json` | `Stage._on_estagio_mudou(novo)` (`scenes/Stage.gd:468-471`), sincronizado a `level_up_frame.pulsar(novo)` | Arpejo retrô curto e celebratório (~**`0.50 s`**, faixa `0.45–0.55 s`) | Alta; `polyphony = 1`, interrompido se ocorrer derrota | `INHERIT` (pausável, congela junto com `LevelUpFrame`) | **Bloqueado em `STATE_LOST`:** deve respeitar a mesma guarda `ultimo_estado.get("state", "") == GameState.STATE_LOST` (`scenes/Stage.gd:469-470`) e nunca disparar após a derrota. |
| **Plataforma rachando** | `platform_crack.wav` + `platform_crack.sfx.json` | `Platform.iniciar_desmoronamento` (`scenes/Platform.gd:133-138`, chamado por `PlatformCrumble.ao_pousar` em `scripts/PlatformCrumble.gd:14-16`) | Estalo percussivo seco de pedra/madeira rachando, `0.12–0.18 s` | Média; disparado **1x** por plataforma (guarda `_desmoronando or desmoronada`); `polyphony = 2` | `INHERIT` (pausável) | **Inerte em `Global.sem_derrota`:** o som é totalmente desativado quando `Global.sem_derrota == true` (alinhado à guarda de `scripts/PlatformCrumble.gd:14`). |
| **Plataforma colapsando** *(complementar)* | `platform_break.wav` + `platform_break.sfx.json` | `_avancar_desmoronamento` quando `_tempo_restante <= 0.0` (`scenes/Platform.gd:142-147`) | Ruído curto de fragmentação/queda, `0.15–0.22 s` | Baixa–média; `polyphony = 2`; tocado em player fora da `Platform` (pois ela executa `queue_free()` no mesmo frame) | `INHERIT` (pausável) | **Inerte em `Global.sem_derrota`:** segue a mesma guarda de `platform_crack`. |
| **Coleta de power-up** | `powerup_collect.wav` + `powerup_collect.sfx.json` | `Stage._coletar_power_up(tipo)` (`scenes/Stage.gd:857-863`) | Fanfarra curta brilhante ascendente, `0.20–0.26 s` | Alta; sobrescreve/atenua `land_point` no mesmo frame para evitar saturação | `INHERIT` (pausável) | Só dispara com `power_ups_habilitados == true` e `PowerUps.resolver(tipo) != null` (nunca em `Puro`, `Zen`, `Diario` nem na injeção silenciosa de debug `_ativar_power_up_inicial`). |
| **Expiração de power-up** | `powerup_expire.wav` + `powerup_expire.sfx.json` | Borda de expiração de efeito temporizado (`Camaleao` / `Desacelera`) em `PowerUpState` durante `STATE_PLAYING` | Tom curto suave descendente, `0.15–0.20 s` | Baixa–média; `polyphony = 1` | `INHERIT` (pausável) | Nunca dispara em `STATE_LOST`, no menu nem na liberação/recarga de cena; timbre claramente distinto de `lose.wav`. |
| **Resgate `Segunda chance`** | `second_chance_save.wav` + `second_chance_save.sfx.json` | `Stage._tentar_reaparecimento(body)` (`scenes/Stage.gd:786-803`), no caminho de sucesso junto a `consumir_carga()` | Brilho heroico/teleporte ascendente, `0.28–0.38 s` | Muito alta; `polyphony = 1` | `INHERIT` (pausável) | Só toca quando há carga e candidata visível (`int(escolha["indice"]) >= 0`). Sem candidata visível cai na derrota padrão (`lose.wav`). Nunca dispara no reposicionamento `Zen`. |
| **UI — foco / navegação** | `ui_focus.wav` + `ui_focus.sfx.json` | Troca de foco por teclado/joypad no Menu, `PauseOverlay`, `OptionsScreen`, `ModosScreen` e `TutorialCard` | Tick ultracurto e suave, `0.03–0.05 s` | Baixa; `polyphony = 1`, cooldown `50 ms` | **`ALWAYS`** (`Node.PROCESS_MODE_ALWAYS`) | Obrigatório `process_mode = ALWAYS` para soar na pausa (`ADR 0008`). Não dispara no foco inicial automático ao abrir a tela. |
| **UI — clique / confirmar** | `ui_click.wav` + `ui_click.sfx.json` | Acionamento de botões habilitados (`Play`, `Modo`, `Opcoes`, `Continuar`, `Sair`, `OK`, `Pular`, `PauseBotao`) e ajuste discreto de slider | Blip tátil positivo, `0.06–0.09 s` | Média; `polyphony = 2`, cooldown `70 ms` durante arrasto de slider | **`ALWAYS`** (`Node.PROCESS_MODE_ALWAYS`) | Obrigatório `process_mode = ALWAYS` para soar em Pausa e Pausa -> Opções (`ADR 0008`). Botão desabilitado (`"Ja jogado hoje"`) não toca `ui_click`. |
| **UI — voltar / cancelar** | `ui_back.wav` + `ui_back.sfx.json` | Ação `Voltar` / `Esc` em `OptionsScreen`, `ModosScreen` e revisão do `TutorialCard` | Blip curto levemente descendente, `0.06–0.09 s` | Média; `polyphony = 1` | **`ALWAYS`** (`Node.PROCESS_MODE_ALWAYS`) | Obrigatório `process_mode = ALWAYS` para funcionar na pausa (`ADR 0008`). |

- **Avaliação dos sons atuais (`sounds/jump.wav` e `sounds/lose.wav`):** ambos são originais provisórios da game jam **sem registro de licença no repositório**. Ficam preservados apenas como referência histórica em `assets/src/_orig/` (excluídos do export via `assets/src/.gdignore`) e serão substituídos na etapa de SFX por versões sintetizadas com `.sfx.json` e timbre uniforme com todo o inventário acima.
- **Ordem de prioridade e mixagem no bus `SFX`:** `lose` > `second_chance_save` > `stage_up` > `powerup_collect` > `jump` / `land_point` / `platform_crack` > `powerup_expire` / `platform_break` > `ui_*`. Em sobreposição no mesmo frame (`land_point` + `powerup_collect`), suprimir ou atenuar `-6 dB` o cue de menor prioridade para preservar clareza em alto-falantes móveis.

### 6.3 Direção de Música Dinâmica (bus `Music`)

#### 4 variações por estágio (`e0..e3`) + stingers

A trilha acompanha a escalada visual dos 4 biomas (`ressources/curva_dificuldade.tres`) compartilhando tonalidade, andamento base (ex.: `120 BPM`, compasso `4/4`) e estrutura harmônica compatível para transições sem quebra de pulso:

| Variação / Recurso | Arquivo esperado (`sounds/`) | Loop | Contexto e caráter musical |
|---|---|---|---|
| **Estágio `e0`** (*Floresta Tropical*) | `music_e0_floresta.ogg` | `loop = true` | Tema principal chiptune leve e convidativo (melodia principal + baixo triângulo suave); usado também no menu inicial e como base calma no modo `Zen`. |
| **Estágio `e1`** (*Cachoeira & Neblina*) | `music_e1_cachoeira.ogg` | `loop = true` | Acrescenta arpejo fluido e percussão leve mantendo a mesma grade rítmica de `e0`. |
| **Estágio `e2`** (*Ruínas Celestes*) | `music_e2_ruinas.ogg` | `loop = true` | Expande a harmonia com contracanto brilhante e condução rítmica mais firme. |
| **Estágio `e3`** (*Espaço & Estrelas*) | `music_e3_espaco.ogg` | `loop = true` | Variação de clímax de alta energia com linhas rápidas de sintetizador retrô. |
| **Stinger de transição** *(opcional/harmonizado)* | `stinger_stage_up.ogg` | `loop = false` | Frase musical de 1–2 tempos (ou integrada ao aviso `#43` sem disputar o mesmo espectro) marcando a mudança de variação. |

- **Formato técnico:** **Ogg Vorbis (`.ogg`)**, `44.1 kHz`, `loop = true` nas 4 variações (`e0..e3`), masterizado em torno de **`-14 LUFS`** para deixar folga confortável aos SFX (`-3 dBFS` pico).
- **Modos sem progressão fixa (`Zen`) e pós-platô:** no `Zen`, a música permanece na variação calma (`e0`, ou alterna suavemente entre `e0` e `e1` sem stinger de tensão ao ciclar biomas por distância); em `Classico` / `Puro` após `e3`, mantém `e3` (ou acompanha o ciclo de biomas com crossfade longo de `1.8 s`).

#### Arquitetura no Godot 4.7.2: `AudioStreamInteractive` + fallback `AudioStreamSynchronized`

- **Implementação primária — `AudioStreamInteractive`:**
  - Os 4 clipes (`e0..e3`) são agrupados em um recurso `AudioStreamInteractive` (`bus = &"Music"`), com matriz de transições configurada para trocar no próximo tempo ou compasso (`TRANSITION_FROM_TIME_NEXT_BEAT` / `TRANSITION_FROM_TIME_NEXT_BAR`) com crossfade curto (`FADE_CROSS`, `0.25–0.50 s`).
  - Ao receber `dificuldade.estagio_mudou(novo)`, o controlador solicita a troca de clipe (`playback.switch_to_clip_by_name(...)`), mantendo a continuidade métrica da música.
- **Fallback técnico oficial para Web/WASM — `AudioStreamSynchronized` (stems em crossfade):**
  - Caso o teste no export HTML5/WebAssembly do Godot 4.7.2 apresente estalos, travamento de buffer ou incompatibilidade no `AudioStreamInteractive`, o mesmo controlador de música troca apenas o recurso interno para **`AudioStreamSynchronized`** contendo as 4 variações sincronizadas em tempo real e interpola `set_sync_stream_volume(i, db)` por `Tween` (`0.8–1.2 s`, de `-80 dB` a `0 dB`).
  - A API exposta ao restante do jogo (`definir_estagio(estagio: int)`, `definir_pausado(pausado: bool)`, `notificar_gesto_usuario()`) permanece idêntica entre `AudioStreamInteractive` e `AudioStreamSynchronized`, isolando completamente `Stage.gd` do detalhe do backend de áudio.

#### Persistência fora de `Stage.tscn`, pausa (`ADR 0008`) e desbloqueio WebAudio

1. **Hospedagem fora de `Stage.tscn` (sobrevivência a `change_scene_to_file`):**
   - `Stage.tscn` é destruída e recarregada por `get_tree().change_scene_to_file("res://scenes/Stage.tscn")` em `Stage._on_animation_end()` (`scenes/Stage.gd:845-846`) e em `_recarregar_stage()` (`scenes/Stage.gd:584-588`: `Sair` da pausa, troca de modo cruzando a fronteira do Desafio Diário em `_fechar_modos` e virada de dia UTC em `_bloquear_inicio`).
   - Por isso, o `AudioStreamPlayer` da música **nunca vive em `Stage.tscn`**: ele é hospedado em um **autoload persistente (`MusicManager`, ou nó filho persistente do autoload `Global`)**, no bus `&"Music"`, com **`process_mode = Node.PROCESS_MODE_ALWAYS`**.
   - Em recargas de `Stage.tscn`, a trilha continua tocando sem corte; ao retornar ao menu (`!started`), transita suavemente de volta à variação `e0`.
2. **Comportamento na pausa (`ADR 0008` — Opção A aprovada):**
   - Quando `get_tree().paused == true`, a música **não pausa**: o player permanece em execução (`process_mode = Node.PROCESS_MODE_ALWAYS`) e sofre **atenuação suave (ducking) de `-12 dB`** (transição de `~0.15 s`) aplicada exclusivamente no `volume_db` do player de música (sem tocar `AudioServer.set_bus_volume_db` nem o valor salvo em `OptionsStore`).
   - Ao retomar a partida ou sair para o menu, o `volume_db` do player retorna suavemente para `0.0 dB` relativo.
   - **Feedback em tempo real do slider `Music` em Pausa -> Opções:** como o slider ajusta o bus `Music` (`Global.set_volume_music` em `scripts/Global.gd:271-300`), o jogador ouve imediatamente o efeito do ajuste enquanto está pausado; em **`0%` (`linear <= 0.0`)**, o bus recebe `MUTE_DB = -80.0 dB` e `AudioServer.set_bus_mute(idx, true)` (`scripts/OptionsStore.gd:15,24-26`), garantindo silêncio total.
   - Em `NOTIFICATION_APPLICATION_PAUSED` / `NOTIFICATION_APPLICATION_FOCUS_OUT` (app em segundo plano no Android/Web), além de pausar a partida (`ADR 0008`), o gerenciador silencia temporariamente a saída enquanto o foco está ausente e restaura o estado atenuado (`-12 dB`) quando o foco retorna.
3. **Desbloqueio de WebAudio após primeiro gesto do usuário:**
   - Em navegadores (export Web/HTML5), o `AudioContext` nasce suspenso até o primeiro gesto de entrada do usuário.
   - Quando `OS.has_feature("web")` é verdadeiro, o gerenciador de música não força `play()` no `_ready` antes da interação: registra um listener `_input` (`process_mode = ALWAYS`) que, no primeiro evento pressionado (`InputEventScreenTouch`, `InputEventMouseButton`, `InputEventKey` ou `InputEventJoypadButton`), desbloqueia e inicia a reprodução da trilha de forma idempotente (nunca reinicia se já estiver tocando).
   - Em ambiente headless (`--headless`, suite GUT), o gerenciador opera de forma segura sem erros mesmo sem dispositivo de saída de áudio.

#### Opções concretas de origem comercial para a música em 4 variações

Todas as opções abaixo são compatíveis com distribuição gratuita (itch.io **E7**) e monetização comercial com anúncios e IAP (Play Store **E8**):

1. **Composição original própria em tracker/DAW chiptune livre *(recomendada pela precisão dos loops sincronizados)*:**
   - **Furnace Tracker** (GPLv2; emulação fiel de chips GBC/NES/SNES; áudio exportado `.wav`/`.ogg` 100% autoral sem restrição comercial), **LMMS** (GPLv2) ou **BeepBox / JummBox** (ferramentas livres para síntese chiptune cuja composição autoral pertence ao autor). Permite exportar as 4 variações (`e0..e3`) exatamente no mesmo BPM, tom e número de compassos, além de stingers sob medida.
2. **Pacotes chiptune CC0 1.0 multi-seção / em stems:**
   - Seleção de pacotes explicitamente sob **CC0 1.0 Universal** (domínio público) em catálogos consolidados como **OpenGameArt.org** (ex.: coleções chiptune CC0 multi-faixa no mesmo estilo/tom, como packs *SubspaceAudio / Juhani Junkala* CC0 ou equivalentes verificados no ato da coleta) ou **itch.io** (packs chiptune com licença CC0 confirmada na página do autor), adaptando/cortando 4 seções em loop coerentes no mesmo andamento.
3. **Pack comercial royalty-free ou encomenda pontual:**
   - Aquisição de pacote chiptune adaptativo/multi-camada (itch.io ou compositor independente) com licença escrita autorizando uso comercial em jogos gratuitos e monetizados por anúncios/IAP, arquivando os termos em `sounds/LICENSES.md`.

> **Vedado:** qualquer faixa sob licença **Non-Commercial (`CC BY-NC*`)**, **No-Derivatives (`CC BY-ND*`)** (impede corte em loops e variações), origem não verificável ou serviço de geração por IA cujos termos restrinjam uso comercial/anúncios/IAP.

---

## 7. Política e Auditoria de Licenças Comerciais (E7 e E8)

### 7.1 Regra de elegibilidade comercial

Todo ativo embarcado no `.pck` (sprites, fontes, SFX, músicas) deve ser 100% compatível com publicação gratuita no **itch.io (E7)** e monetização comercial com anúncios e compras no aplicativo na **Play Store (E8)**:

- **Licenças aceitas:** autoral próprio do projeto, **CC0 1.0 Universal**, **SIL OFL 1.1** (fontes), **MIT / Apache-2.0 / zlib**, **CC BY 4.0** (mediante crédito explícito no jogo e em `LICENSES.md`), ou licença comercial paga sem royalties devidamente arquivada.
- **Licenças bloqueadas:** qualquer variante **Non-Commercial (`CC BY-NC`, `CC BY-NC-SA`, `CC BY-NC-ND`)**, **No-Derivatives (`CC BY-ND`)** em arquivos que exijam edição/loop, ou qualquer ativo **sem registro verificável de autor e licença**.

### 7.2 Auditoria real dos ativos presentes no repositório

| Ativo atual no repositório | Tipo | Licença encontrada | Situação comercial (E7/E8) | Ação obrigatória no E6 |
|---|---|---|---|---|
| `fonts/alterebro-pixel-font.ttf` | Fonte | **CC BY-NC** (não comercial) | **BLOQUEADO** — incompatível com distribuição comercial, anúncios e IAP | Substituir por `m5x7` (**CC0 1.0**) — ou contingência `m3x6` (CC0) / `Tiny5` / `Silkscreen` (SIL OFL 1.1) — na entrega de UI/Menu e registrar em `fonts/LICENSES.md` |
| `sounds/jump.wav` | SFX | **Sem licença registrada** no repositório (provisório de game jam) | **BLOQUEADO** — ausência de licença impede distribuição comercial segura | Cópia histórica mantida em `assets/src/_orig/jump.wav` (isolada por `.gdignore`); substituir por síntese própria (`jsfxr`) + `jump.sfx.json` na entrega de SFX e registrar em `sounds/LICENSES.md` |
| `sounds/lose.wav` | SFX | **Sem licença registrada** no repositório (provisório de game jam) | **BLOQUEADO** — ausência de licença impede distribuição comercial segura | Cópia histórica mantida em `assets/src/_orig/lose.wav` (isolada por `.gdignore`); substituir por síntese própria (`jsfxr`) + `lose.sfx.json` na entrega de SFX e registrar em `sounds/LICENSES.md` |
| `assets/Gecko.png`, `assets/GeckoPlataforma.png`, `icon.png` | Sprites | Autoral do projeto (provisórios de game jam) | Elegível (substituídos pela arte final E6) | Cópias históricas mantidas em `assets/src/_orig/`; arte final produzida no Aseprite (`ADR 0004`) |

### 7.3 Formato obrigatório de registro (`fonts/LICENSES.md` e `sounds/LICENSES.md`)

As entregas de fonte/UI, SFX, música e polimento final do E6 devem manter dois inventários versionados — **`fonts/LICENSES.md`** e **`sounds/LICENSES.md`** — usando obrigatoriamente a estrutura de tabela abaixo:

```markdown
| Arquivo | Tipo | Autor | Origem / URL ou Preset/Seed jsfxr | Licença | Atribuição obrigatória | Uso comercial (E7/E8) |
|---|---|---|---|---|---|---|
| `m5x7.ttf` | Fonte | Daniel Linssen | https://managore.itch.io/m5x7 | CC0 1.0 | Não (crédito opcional) | Aprovado |
| `jump.wav` | SFX | Projeto Gecko Jump | Sintetizado localmente (`sounds/jump.sfx.json`) | Autoral / CC0 | Não | Aprovado |
| `music_e0_floresta.ogg` | Música | <autor> | <URL oficial ou ferramenta autoral> | <CC0 1.0 / CC BY 4.0 / Autoral> | <Não / Sim: texto exato> | Aprovado |
```

- **Critério de fechamento do E6:**
  1. 100% dos arquivos de mídia em `fonts/` e `sounds/` possuem linha correspondente em `fonts/LICENSES.md` ou `sounds/LICENSES.md`.
  2. Nenhum arquivo com licença `NC`, `ND` ou desconhecida permanece fora de `assets/src/_orig/` (que fica excluído do `.pck` via `assets/src/.gdignore`).
  3. Qualquer ativo sob `CC BY 4.0` tem o texto exato de atribuição copiado no campo correspondente para inclusão nos créditos do E7/E8.

