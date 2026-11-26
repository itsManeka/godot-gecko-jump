# Direção de Arte e Áudio — Gecko Jump (E6)

Especificação visual, sonora e de licenciamento definitiva do **Gecko Jump** para o marco **E6** (issue `#18`), consolidando identidade visual **16-bit SNES/GBA luminosa e carismática** (referência de estilo em `assets/src/ref-estilo-dono.jpg` e provas visuais aprovadas em `assets/src/refs/`), paleta de trabalho por rampas de material com contraste WCAG AA (`>= 4.5:1`) nos tokens de UI, acessibilidade sem cor (issue `#41`), sprites de gameplay, 4 biomas luminosos com parallax e névoa reativa, tipografia comercial livre, kit UI em pixel art, remodelagem completa do menu com reserva de espaço para **Ranking (E5)** e **Remover anúncios (E8)**, direção de SFX (issues `#13`, `#43`), arquitetura de música dinâmica persistente (`ADR 0015`) e política de licenças comerciais (E7/E8).

Base técnica evoluída (`ADR 0015` sobre `ADR 0002`): largura lógica fixa de **`360 px`** (fator exato `2×` sobre `180×320`), altura visível mínima `640 px` expandida em aparelhos altos (`360×800` em 1080×2400, `360×924+`), `keep_width`, pixel quadrado, filtro `Nearest` (`default_texture_filter = 0`) e escala inteira exata nos celulares-alvo (`720p = 2×`, `1080p = 3×`, `1440p = 4×`). Fontes editáveis em Aseprite vivem isoladas em `assets/src/` (`ADR 0004`).

---

## 1. Identidade visual e paleta de trabalho

### 1.1 Estética, resolução `360×640` e regras de leitura

- **Resolução lógica `360×640` (`2×` sobre `180×320`):** para acomodar o nível de detalhe 16-bit SNES/GBA aprovado (olhos expressivos, cauda espiral, ilhotas orgânicas com micro-ornamentos, biomas detalhados e logo arcade) sem perda nem borrão, a resolução lógica passa de `180×320` para **`360×640`** (`stretch/aspect = "keep_width"`, `scale_mode = "integer"`, filtro `Nearest`). A escala inteira exata fica preservada em todos os alvos mobile: `720 / 360 = 2×` (`720×1280` → `360×640`), `1080 / 360 = 3×` (`1080×2400` → `360×800`) e `1440 / 360 = 4×`. A migração de código, física, câmera e UI para `360×640` ocorre em entrega própria antes da integração dos sprites finais (`ADR 0015`).
- **Estilo:** Pixel art **16-bit SNES/GBA luminosa e carismática**, guiada pelas referências oficiais aprovadas em `assets/src/ref-estilo-dono.jpg` e `assets/src/refs/`, com silhuetas arredondadas e expressivas legíveis sem zoom, contorno escuro limpo (`#052018`, verde-carvão em vez de preto chapado puro) e sombreado em rampa de 4–5 tons por material com variação de matiz (seção 1.2 e guia da seção 1.5), além de 3 tons próprios de terra/rocha orgânica para a base das ilhotas flutuantes.
- **Hierarquia visual obrigatória (preservando contraste sobre biomas luminosos):**
  1. **Primeiro plano (gameplay — Gecko, ilhotas flutuantes, power-ups):** alta saturação, brilhos especulares claros (`*_luz`), base orgânica de terra/rocha (`terra_luz`/`terra_base`/`terra_sombra`) e **contorno escuro nítido `1 px` (`#052018`)** ao redor de toda a silhueta.
  2. **Interface (HUD, botões, cards):** cores próprias de UI (`#3d6b35`, `#9c521b`, `#1f2738`) que nunca dependem das 4 cores das plataformas, com texto em `#fffdf5` / `#d4e0e6`. Sobre fundos claros dos biomas luminosos (`e1` Céu Azul e Nuvens, `e2` Pôr do Sol e trechos claros de `e0` água/cachoeira), o HUD usa obrigatoriamente **contorno `#052018`** e **faixa translúcida `#052018` a `70%`** para garantir contraste `>= 4.5:1`.
  3. **Fundo (4 biomas luminosos e partículas ambientais):** paleta luminosa estilo SNES/GBA com contraste interno suave entre camadas de parallax (`<= 2.2:1`) e **ausência de contorno escuro `#052018`** nos elementos de cenário, permitindo que o primeiro plano contornado salte visualmente mesmo contra céu claro ou pôr do sol.

### 1.2 Paleta de trabalho

A paleta é **aberta e organizada por rampas de material**, não por uma contagem fixa de cores: cada material (pele do gecko, barriga, olho, cobertura de cada variante, terra) tem uma rampa de **4–5 tons** em que o matiz muda junto com a luminosidade (sombras puxam para o frio/saturado, luzes para o quente/amarelado), em vez de só clarear e escurecer a mesma cor. O arquivo `assets/src/palette.gpl` (formato GIMP Palette) é a fonte das cores aceitas na quantização; rampa nova entra nele quando o material correspondente é pintado e aprovado.

#### Rampa aprovada: gecko (pele, barriga, olho, rubor)

Medida na ref mestra (o contorno `#052018` vem dela) `assets/src/refs/gecko-idle-mestre.aseprite` (export `gecko-idle-mestre.png`, `64×64`). O matiz da pele vai de `162°` (sombra, teal) a `72°` (brilho, amarelo-limão), passando por `133°`, `103°` e `86°`.

| Material | Tom | Hex | Uso |
|---|---|---|---|
| Contorno | `contorno` | `#052018` | Silhueta externa, `1 px` (ver contorno seletivo na seção 1.5) |
| Pele | `verde 0 linha` | `#1f5c4a` | Linhas internas (braço, mão, espiral, seam da cauda) e menor tom da pele |
| Pele | `verde 1 sombra` | `#4aae5f` | Sombra projetada (lado oposto à luz, base do corpo, pés) |
| Pele | `verde 2 base` | `#7fdb5a` | Cor de preenchimento dominante |
| Pele | `verde 3 luz` | `#b2ee62` | Topo da cabeça e lado voltado à luz |
| Pele | `verde 4 brilho` | `#e2f88a` | Brilho especular no topo da cabeça e da cauda |
| Barriga | `barriga sombra` | `#b4dc8a` | Sombra da barriga, base do peito |
| Barriga | `barriga` | `#e3f5b0` | Preenchimento da barriga |
| Olho | `olho sombra` | `#bccbd9` | Sombra do branco do olho (borda inferior) |
| Olho | `olho branco` | `#fbfbef` | Esclera |
| Rubor | `rubor` | `#f07f86` | Bochecha e interior da boca (acento único, não usar em outro material) |

#### Âncoras de cor das variantes (`scripts/Enums.gd`)

As 4 cores de gameplay seguem como âncoras exatas: são a identidade de cada variante de plataforma e de gecko, lidas do código no seguinte ponto:

| Variante (`Enums.COLOR`) | Âncora | Linha em `scripts/Enums.gd` |
|---|---|---|
| `AMARELO` | `#f6db61` | `Enums.gd:26` |
| `VERDE` | `#79cf5a` | `Enums.gd:28` |
| `AZUL` | `#5987e9` | `Enums.gd:30` |
| `VERMELHO` | `#ec4848` | `Enums.gd:32` |

A rampa de 4–5 tons de cada variante (cobertura da plataforma e pele do gecko) parte da âncora acima como tom de base e é derivada seguindo a regra de matiz acima; o `palette.gpl` recebe os tons assim que a variante é pintada e aprovada. O verde do gecko (`#7fdb5a`) é a rampa aprovada da tabela anterior e não precisa coincidir com a âncora `#79cf5a` da plataforma verde.

#### Rampas aprovadas: variantes do gecko, terra e plataformas

Entraram no `palette.gpl` conforme cada peça foi desenhada e aprovada pelo dono (valores lidos do arquivo):

| Material | Tons (escuro para claro) | Observação |
|---|---|---|
| Gecko amarelo | `#b17834` (linha), `#f5be3c`, `#fce65e` (base), `#fffa92`, `#fffcd8` (brilho); sombra `#c48f29`; barriga `#f0d898` / `#fff4d0` | A plataforma amarela reusa esses tons, sem cor nova |
| Gecko azul | `#353880` (linha), `#5c5fc8`, `#5991ff` (base), `#61aff9`, `#9ec1ed` (brilho); luz `#a6c8ff`; barriga `#b2c8ea` / `#e2eefa` | A plataforma azul reusa esses tons mais `#3a5ad6` (sombra do gelo, mais fria que `#5c5fc8`) |
| Grama da plataforma verde | `#22604a` (linha), `#52ba56`, base = âncora `#79cf5a`, `#a2ec5c`, `#e0f592` (brilho) | Cobertura derramando na borda da terra |
| Terra / rocha orgânica (4 plataformas) | `#472b1b` (sombra), `#784b2e` (base), `#a87349` (luz), `#c99a5e` (brilho) | Os 3 primeiros tons são `terra_sombra` / `terra_base` / `terra_luz` da tabela abaixo; `terra_brilho` é o tom novo |
| Cobertura e cogumelos da plataforma vermelha | `#7c182f` (linha), `#cd294c`, `#ff443e` (base), `#ff7a62`, `#f49c89` (brilho); talo `#f3c3a5` / `#ffe9d6` | Rampa a reconferir quando o gecko vermelho final chegar (pendente do dono) |

#### Rampas aprovadas: menu (seção 5.3)

Céu, nuvens e folhagem de fundo não levam contorno (seção 1.1). Os botões e o card usam rampas suavizadas a partir dos matizes de `ui_cta_*`, `ui_btn_*` e `painel_escuro`.

| Material | Tons (escuro para claro) |
|---|---|
| Céu | `menu ceu` `#70a2d4` |
| Nuvens | `#aab6c4` (funda), `#c5b8cc` (sombra), `#e0e0e8` (corpo), `#f7ffe8` (luz) |
| Folhagem | `#3d6e70` (sombra), `#3ca370` (corpo), `#8fde5d` (luz), `#cfff70` (brilho) |
| Botão CTA `Play` | `#8a4f2a` (linha), `#c47f4c`, `#eeb07a` (corpo), `#f8cfa2`, `#fff0d8` (brilho) |
| Botão padrão | `#4a7040` (linha), `#74a364`, `#9cc886` (corpo), `#c2e2ac`, `#eaf6dc` (brilho) |
| Card | `#2a3450` (linha), `#3a4766`, `#4a5878` (corpo), `#6a7a9c`, `#9aa8c6` (brilho) |

#### Tokens de UI, cenário e rampas legadas de 3 tons

Os tokens abaixo continuam válidos e são os usados na prova de contraste da seção 1.3 (o único token alterado é `ink_contorno`, agora `#052018`; as razões da seção 1.3 que o envolvem foram recalculadas e seguem acima de `4.5:1`). Os tokens de neutros, UI e biomas estão no `palette.gpl`. As rampas legadas de 3 tons de gameplay (`*_luz` / `*_base` / `*_sombra`) seguem referenciadas nas seções 2 e 3 e ficam apenas nesta tabela, fora do `palette.gpl`, até a rampa nova do material correspondente ser pintada; as de terra já estão no `palette.gpl` (rampa acima). A cor histórica de botão `#5b8a4a` (`ressources/Button.tres`) é preservada como chanfro superior/preenchimento de slider (`ui_btn_luz`), enquanto o corpo dos botões evolui para `#3d6b35` (`ui_btn_base`) para atingir contraste WCAG AA `>= 4.5:1` (com `#ffffff`, `#5b8a4a` entregava apenas `4.05:1`).

| Grupo | Token | Hex | Luminância relativa (`L`) | Luma BT.709 (0–255) | Uso principal |
|---|---|---|---:|---:|---|
| **Neutros e Contorno (5)** | `ink_contorno` | `#052018` | `0.0113` | `26` | Contorno de sprites/texto/logo, fissuras, faixa/overlay translúcido (`70%`) |
| | `painel_escuro` | `#1f2738` | `0.0203` | `39` | Fundo de cards/placar/modais, barras laterais (`default_clear_color`) e céu noturno `e3` |
| | `ui_desabilitado` | `#3b4654` | `0.0595` | `69` | Fundo de botão desabilitado (`"Ja jogado hoje"`) e ranhura de cursor |
| | `ui_texto_sec` | `#d4e0e6` | `0.7302` | `222` | Texto secundário, rótulo desabilitado, nuvens iluminadas e estrelas |
| | `branco_texto` | `#fffdf5` | `0.9810` | `253` | Texto primário, olhos do gecko, brilho de nuvem, ícones HUD, cursor do slider |
| **Gameplay Amarelo (3)** | `amarelo_luz` | `#fff4b8` | `0.8942` | `242` | Brilho superior do mel/gecko amarelo, brilhos dourados em `color_change`, pulso `LevelUpFrame` |
| | `amarelo_base` | `#f6db61` | `0.7112` | `216` | Âncora `Enums.COLOR.AMARELO`, moldura de foco, destaque de recorde |
| | `amarelo_sombra` | `#c48f29` | `0.3154` | `147` | Sombra quente do mel pingando, relevo da cobertura e do gecko amarelo |
| **Gameplay Verde (3)** | `verde_luz` | `#bef297` | `0.7669` | `224` | Brilho da grama/folhas e topo do gecko verde |
| | `verde_base` | `#79cf5a` | `0.4943` | `180` | Âncora `Enums.COLOR.VERDE`, cobertura de grama e rostinho de `segunda_chance` |
| | `verde_sombra` | `#3f8f42` | `0.2110` | `120` | Sombra das vinhas/folhinhas e do gecko verde |
| **Gameplay Azul (3)** | `azul_luz` | `#a6c8ff` | `0.5664` | `197` | Faceta iluminada dos micro-cristais/gelo e brilho do gecko azul |
| | `azul_base` | `#5987e9` | `0.2533` | `132` | Âncora `Enums.COLOR.AZUL` |
| | `azul_sombra` | `#3050a8` | `0.0919` | `80` | Sombra prismática do gelo/cristal e do gecko azul |
| **Gameplay Vermelho (3)** | `vermelho_luz` | `#ff9b90` | `0.4672` | `175` | Brilho quente da cobertura vermelha, coração e gecko vermelho |
| | `vermelho_base` | `#ec4848` | `0.2294` | `107` | Âncora `Enums.COLOR.VERMELHO`, cobertura/cogumelos e coração de `segunda_chance` |
| | `vermelho_sombra` | `#9e2433` | `0.0877` | `63` | Sombra quente da cobertura vermelha, coração e gecko vermelho |
| **Terra / Rocha Orgânica (3)** | `terra_luz` | `#a87349` | `0.2107` | `123` | Relevo iluminado da terra/rocha na base das ilhotas flutuantes |
| | `terra_base` | `#784b2e` | `0.0922` | `82` | Corpo orgânico da terra/rocha das ilhotas e fragmentos de desmoronamento |
| | `terra_sombra` | `#472b1b` | `0.0315` | `48` | Sombra profunda sob a cobertura derramando e rachaduras da ilhota |
| **UI e Destaque (6)** | `ui_btn_luz` | `#5b8a4a` | `0.2090` | `123` | Chanfro superior de botão padrão e preenchimento de slider (herança `Button.tres`) |
| | `ui_btn_base` | `#3d6b35` | `0.1176` | `93` | Corpo dos botões padrão (`Modo`, `Opcoes`, `Pausa`, `Ranking`, `Remover anuncios`) |
| | `ui_btn_sombra` | `#274a24` | `0.0546` | `64` | Chanfro inferior e estado `pressed` de botão padrão |
| | `ui_cta_luz` | `#c9772e` | `0.2581` | `131` | Chanfro superior do CTA `Play` e gradiente do `"JUMP"` no logo |
| | `ui_cta_base` | `#9c521b` | `0.1318` | `94` | Corpo do botão CTA `Play` (âmbar queimado, distinto das 4 cores de jogo) |
| | `ui_cta_sombra` | `#6e3611` | `0.0599` | `63` | Chanfro inferior e estado `pressed` do CTA `Play` |
| **Biomas Luminosos e Névoa (6)** | `b0_floresta` | `#3e7d5a` | `0.1643` | `109` | Bioma `e0` (*Floresta e Cachoeira*): copas, cipós e ruínas com musgo |
| | `b0_agua` | `#53a6a8` | `0.3194` | `148` | Bioma `e0` (*Floresta e Cachoeira*): céu filtrado e quedas d'água; aurora ciano em `e3` |
| | `b1_ceu` | `#6db4e8` | `0.4172` | `169` | Bioma `e1` (*Céu Azul e Nuvens*): céu azul luminoso diurno |
| | `b2_roxo` | `#6b4b82` | `0.0977` | `86` | Bioma `e2` (*Pôr do Sol*): céu superior, silhueta de montanhas e corpo da névoa/aurora |
| | `b2_laranja` | `#eb8b54` | `0.3677` | `155` | Bioma `e2` (*Pôr do Sol*): horizonte quente roxo-laranja |
| | `nevoa_brilho` | `#9ab0c9` | `0.4214` | `173` | Crista da névoa reativa, sombra de nuvens (`e1`), espuma da cachoeira e filete interno de painéis |

> **Separação tonal em escala de cinza das 4 âncoras:** Amarelo (`Y = 216`) > Verde (`Y = 180`) > Azul (`Y = 132`) > Vermelho (`Y = 107`), assegurando degraus mínimos de `25–48` níveis de luminância além das silhuetas e micro-ornamentos distintos da seção 2. A base de terra (`terra_luz/base/sombra`, `Y = 123 / 82 / 48`) permanece restrita à porção inferior das ilhotas, nunca substituindo a cor da cobertura superior.

### 1.3 Prova numérica de contraste WCAG AA (`>= 4.5:1`)

Cálculo pela fórmula oficial WCAG 2.1 de luminância relativa `L = 0.2126·R_lin + 0.7152·G_lin + 0.0722·B_lin` (linearização com limiar `0.04045`, idêntica à de `test/test_stage_faixa_placar.gd`) e razão `(L_max + 0.05) / (L_min + 0.05)`.

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
| Texto HUD com contorno escuro (`Pontos`, `PowerUpHud`, `TouchHint`) | `#fffdf5` (`branco_texto`) | `#052018` (`ink_contorno`) | **16.82:1** | PASS (AAA) |
| Texto HUD direto sobre Bioma `e0` (*Floresta e Cachoeira* — copas) | `#fffdf5` (`branco_texto`) | `#3e7d5a` (`b0_floresta`) | **4.81:1** | PASS (AA) |
| Texto HUD direto sobre Bioma `e2` (*Pôr do Sol* — topo roxo) | `#fffdf5` (`branco_texto`) | `#6b4b82` (`b2_roxo`) | **6.98:1** | PASS (AA) |
| Texto HUD direto sobre Bioma `e3` (*Noite Estrelada e Aurora*) | `#fffdf5` (`branco_texto`) | `#1f2738` (`painel_escuro`) | **14.67:1** | PASS (AAA) |

#### Prova de composição alfa da faixa/overlay (`#052018` a `70%`) sobre plataformas e fundos claros

Para superfícies translúcidas (`COR_FUNDO_OVERLAY = #052018` a `70%` de opacidade, usado em `PauseOverlay`, `TouchHint`, faixa de HUD sobre fundos claros e overlays sobre o jogo), cada cor composta resulta da mistura sRGB 8-bit `round(0.70 · fg + 0.30 · bg)` (arredondamento half-up; em empates `.5`, como `#f6db61` e `#eb8b54`, o half-to-even varia no máximo `0.1` na razão, mantendo folga ampla acima de `4.5:1`). Sobre fundos claros dos biomas luminosos (`e1` céu azul/nuvens, `e2` horizonte laranja do pôr do sol, `e0` água/cachoeira) — onde o contraste direto de `#fffdf5` cairia para `2.21:1`–`2.79:1` — a combinação de **contorno `#052018`** com a **faixa `#052018` a `70%`** garante folga acima de `4.5:1` inclusive sobre nuvem branca:

| Superfície atrás da faixa / overlay | Cor composta (`#052018` a `70%`) | Contraste com `#fffdf5` | Contraste com `#d4e0e6` | Status (`>= 4.5:1`) |
|---|---|---:|---:|---|
| Plataforma Amarelo (`#f6db61`, pior caso de plataforma) | `#4d582e` | **7.50:1** | **5.67:1** | PASS |
| Plataforma Verde (`#79cf5a`) | `#28552c` | **8.50:1** | **6.43:1** | PASS |
| Plataforma Azul (`#5987e9`) | `#1e3f57` | **10.83:1** | **8.20:1** | PASS |
| Plataforma Vermelho (`#ec4848`) | `#4a2c26` | **12.28:1** | **9.29:1** | PASS |
| Bioma `e0` água/cachoeira (`#53a6a8`) | `#1c4843` | **10.02:1** | **7.58:1** | PASS |
| Bioma `e1` céu azul (`#6db4e8`) | `#244c56` | **9.19:1** | **6.96:1** | PASS |
| Bioma `e1` nuvem branca (`#fffdf5`, pior caso absoluto) | `#50625a` | **6.37:1** | **4.82:1** | PASS |
| Bioma `e2` pôr do sol laranja (`#eb8b54`) | `#4a402a` | **10.02:1** | **7.58:1** | PASS |
| *Referência legada (`#052018` a `60%` sobre Amarelo)* | *`#656b35`* | ***5.56:1*** | — | *PASS* |

No menu remodelado, o cartão do placar `Last`/`Best` usa painel sólido `#1f2738` (ou `92%` sobre `#052018`, contraste mínimo `>= 13.0:1`), mantendo folga ainda maior sobre qualquer plataforma animada ou bioma luminoso ao fundo.

### 1.4 Pipeline oficial de produção de arte e catálogo de referências

Conforme `ADR 0004`, a arte é pixel art desenhada de verdade, na grade e na paleta de trabalho, e o acabamento final é do dono no Aseprite local (`assets/src/` permanece fora do `.pck` via `assets/src/.gdignore`):

1. **Desenho no Aseprite (agente `pixel-artist`, modelo opus):** o agente desenha cada peça pixel a pixel na grade de destino (`64×64`, `96×40`, `32×32`, `128×128`, `360×480`), com a paleta de trabalho (`assets/src/palette.gpl`), contorno `#052018` e rampas por material, medindo a estrutura contra a ref do dono e não contra a rodada anterior. Entrega os arquivos editáveis **`.aseprite`** com camadas/tags e a exportação **PNG** sem interpolação (`Nearest`).
2. **Ref do dono como âncora:** a ref mestra `assets/src/refs/gecko-idle-mestre.aseprite` (idle `64×64` acabado pelo dono) e o estilo de `assets/src/ref-estilo-dono.jpg` mandam em toda peça nova (seção 1.5).
3. **Acabamento manual do dono:** revisão final quadro a quadro, ajuste fino de expressões/silhuetas e aprovação no jogo antes do embarque no `.pck`. Peça cuja rodada não converge pode ser acabada pelo dono a partir da melhor prova.

Imagem gerada por IA entra **só como inspiração** (`assets/src/refs/_inspiracao-ia/`): ajuda a pensar composição e clima, mas **não é etapa obrigatória** do pipeline nem fonte de pixel do jogo. As imagens de `assets/src/refs/_inspiracao/` (`pixel-cozy.png`, `pixel-bg.png`) também são só referência de clima e leitura: origem e licença desconhecidas, **não entram no jogo** e nenhum pixel delas é copiado.

**Catálogo de `assets/src/refs/`** (cada arquivo existe no repositório; o que ainda não foi desenhado fica marcado "ref na feature de execução"):

| Referência | Caminho no repositório | Escopo ancorado |
|---|---|---|
| Estilo geral 16-bit | `assets/src/ref-estilo-dono.jpg` | Identidade luminosa SNES/GBA, contorno `#052018` e sombreado quente |
| Gecko mestre (idle) | `assets/src/refs/gecko-idle-mestre.aseprite` / `.png` | Ref mestra `64×64` acabada pelo dono: rampa, contorno, luz e proporções (seções 1.2 e 1.5) |
| Gecko verde, amarelo e azul | `assets/src/refs/gecko-verde.*`, `gecko-amarelo.*`, `gecko-azul.*` (`.aseprite` + `.png`) | Variantes aprovadas pelo dono com marca `#41` própria (brotinho, manchas solares, cristais de gelo) |
| Gecko vermelho | (sem arquivo em `assets/src/refs/` ainda) | **Pendente do acabamento do dono no Aseprite**; chega com rampa no `palette.gpl` e nova rodada da prova cinza |
| Plataformas | `assets/src/refs/plataforma-amarelo.*`, `plataforma-verde.*`, `plataforma-azul.*`, `plataforma-vermelho.*` (`.aseprite` + `.png`) | 4 ilhotas aprovadas; a azul é a versão com gelo clareado (original preservado em `assets/src/_orig/plataforma-azul-r15.*`) |
| Prova cinza `#41` | `assets/src/refs/prova-cinza-41.png` (gerada por `assets/src/prova_cinza_41.py`) | Prancha em escala de cinza aprovada pelo dono, com o gecko vermelho marcado **pendente** |
| Rascunho do menu | `assets/src/refs/menu-rascunho.aseprite` / `.png` | Rascunho aprovado do menu (seção 5.3); o dono faz o acabamento |
| Inspiração de clima | `assets/src/refs/_inspiracao/pixel-cozy.png`, `pixel-bg.png` | Só referência (origem/licença desconhecida); não entra no jogo |
| Inspiração de IA | `assets/src/refs/_inspiracao-ia/` | `gecko-bipede-chibi-ref.jpg` (+ `_stand.png`), `ilhotas-powerups-ref.jpg`, `biomas-4-estagios-ref.jpg`, `menu-mockup-ref.jpg`: composição e clima, não pixel art de produção |
| Power-ups, tiles de bioma e kit UI | (ainda sem arte) | Ref na feature de execução |

O arquivo `assets/src/direcao-arte.aseprite` foi removido: os arquivos de `assets/src/refs/` o substituem.

### 1.5 Guia de estilo: luz, rampas, contorno e proporções

A ref mestra do estilo é **`assets/src/refs/gecko-idle-mestre.aseprite`** (idle `64×64` acabado pelo dono, export `gecko-idle-mestre.png` na mesma pasta). Toda variante, pose e peça nova é medida contra ela, não contra a rodada anterior.

**Luz.** Uma fonte só, **vinda do alto à esquerda**: o brilho (`verde 4`) e a luz (`verde 3`) ficam no topo e no lado esquerdo da cabeça e da cauda; a sombra (`verde 1`) cai na base do corpo, no lado direito e nos pés; o meio-tom (`verde 2`) preenche o resto. Nenhum tom isolado: cada transição passa pelo tom vizinho da rampa, sem pular tons e sem dither dentro do gecko.

**Rampas.** 4–5 tons por material, com o matiz acompanhando a luminosidade (seção 1.2): sombra mais fria e saturada, luz mais quente e clara. Um material não empresta tons de outro (a barriga tem rampa própria; o rubor é acento de `1` cor). O gecko usa só as cores da rampa aprovada; variante nova de cor parte da âncora de `scripts/Enums.gd` (`Enums.gd:26`, `:28`, `:30`, `:32`).

**Contorno seletivo.** O contorno escuro `#052018` (verde-carvão da ref mestra, ver seção 1.1) tem `1 px` e fecha **só a silhueta externa**. Linhas internas (braço, mão, dobra da cauda, espiral) usam o **menor tom da própria rampa do material** (`#1f5c4a` no gecko), nunca `#052018`, para não retalhar a forma. O olho tem anel escuro próprio ao redor do branco. Fundo, cenário e névoa não levam contorno (seção 1.1).

**Proporções do gecko (ref mestra, px no frame `64×64`).** Medidas por script sobre o export da mestra; pés na última linha de pixel `y = 59`, silhueta ocupa `x = 10..52` e `y = 9..59`.

| Medida | Valor (px) | Observação |
|---|---:|---|
| Altura total | `51` | `y = 9..59` |
| Largura total | `43` | `x = 10..52` (cauda incluída) |
| Cabeça: altura | `27` | do topo ao queixo (`y = 35`) |
| Cabeça: largura | `31` | maior linha acima do queixo |
| Corpo: altura | `18` | do queixo ao topo das pernas |
| Corpo: largura | `25` | `x >= 25`, sem a cauda |
| Pernas: comprimento | `6` | linhas com dois segmentos separados, até os pés |
| Braço: comprimento | `12` | do ombro (`y = 37`) à linha da mão (`y = 48`) |
| Olho grande: diâmetro | `11` | com o anel escuro |
| Olho de trás: altura × largura visíveis | `11 × 6` | centro em `(48.5, 22.0)` |
| Espiral da cauda: diâmetro | `9` | pela linha interna `#1f5c4a`, `x = 13..21`, `y = 40..48` |
| Cauda: largura × altura | `15 × 19` | `x = 10..24`, `y = 36..54` |

A cabeça ocupa cerca de `53%` da altura total (`27` de `51`) e a razão cabeça/corpo em altura é `27:18`; é essa a leitura chibi a preservar nas outras poses e variantes.

**Nomes de arquivo de arte** (fixados para as entregas seguintes; `<cor>` é `amarelo`, `verde`, `azul` ou `vermelho`):

| Arquivo | Conteúdo |
|---|---|
| `gecko-<cor>.png` | Folha do gecko da variante, grade `64×64` |
| `plataforma-<cor>.png` | Peça mestre da ilhota da variante, `96×40` |
| `prova-cinza-41.png` | Prancha de leitura em escala de cinza das 4 variantes (acessibilidade sem cor, seção 2) |
| `menu-rascunho.png` | Rascunho do menu remodelado (seção 5) |

---

## 2. Acessibilidade sem cor (issue `#41`)

Nenhuma informação essencial de gameplay depende exclusivamente de matiz. Cada uma das 4 cores de `scripts/Enums.gd` recebe uma **identidade tátil e geométrica completa**, distinguível em **escala de cinza** a `360 px` de largura lógica e replicada nos 4 pontos de leitura do jogo: ilhota de plataforma, camaleão bípede chibi (`64×64`), partículas de troca de cor e card de tutorial.

| Cor (`Enums.COLOR`) | Tema tátil | Ilhota flutuante (`36–44 px` altura visual, 9-slice `120/112/100/88 px`) | Marca sutil `#41` no Gecko (`64×64`) | Partículas / aura na troca de cor (`color_change`) | Amostra no `TutorialCard` |
|---|---|---|---|---|---|
| **Amarelo** (`#f6db61`) | **Mel Dourado / Florzinhas** | Cobertura de **mel dourado pingando** pela borda da terra + **micro-florzinhas** discretas (`4–6 px`) no topo (sem confundir com obstáculo) | **Manchas solares** circulares sutis (`amarelo_sombra`) no flanco/dorso, preservando a silhueta chibi bípede | **Círculos / brilhos dourados** (`8×8 px` redondos + mini-estrelas) | Mini-ilhota mel `64×24` + mini-gecko manchas `24×32` + rótulo `"amarelo"` |
| **Verde** (`#79cf5a`) | **Grama / Folhinhas** | Cobertura de **grama verde** derramando na borda + **folhinhas e vinhas** curtas caindo na terra e brotos discretos no topo | **Brotinho de 2 folhas** nascendo no topo da cabeça, preservando a silhueta chibi bípede | **Folhas / gotas suaves** (`10×6 px` inclinadas caindo em leve arco) | Mini-ilhota grama `64×24` + mini-gecko brotinho `24×32` + rótulo `"verde"` |
| **Azul** (`#5987e9`) | **Gelo / Cristal** | Cobertura de **gelo azul** derramando na borda + **micro-cristais angulares** discretos (`6–8 px`, `azul_luz`) no topo | **Cristais de gelo** angulares sutis no dorso/cabeça sem deformar os olhões nem a cauda espiral | **Losangos / cristais** (`10×10 px` em diamante com núcleo `azul_luz`) | Mini-ilhota gelo `64×24` + mini-gecko cristais `24×32` + rótulo `"azul"` |
| **Vermelho** (`#ec4848`) | **Rubro / Cogumelos** | Cobertura **vermelha** derramando na borda + **micro-cogumelos** vermelhos com pintas brancas (`6–8 px`) no topo | **Espinhos dorsais fofos** curtos e arredondados ao longo do dorso sem poluir a silhueta | **Triângulos / faíscas** (`8×8 px` triangulares subindo rapidamente) | Mini-ilhota cogumelos `64×24` + mini-gecko espinhos `24×32` + rótulo `"vermelho"` |

### Regras de preservação do `#41`

1. **Fim do tingimento chapado (`modulate`):** tanto o Gecko quanto as ilhotas abandonam o tingimento de sprite branco por `Enums.get_cor(...)`. Cada variante é desenhada diretamente com sua rampa de 3 cores + contorno `ink_contorno` (`#052018`), preservando olhos grandes (`#fffdf5` + pupila/espiral `#052018`), base de terra (`terra_luz/base/sombra`), brilhos quentes e marcas táteis sem lavagem de cor.
2. **Validação obrigatória em escala de cinza:** a prancha em escala de cinza `assets/src/refs/prova-cinza-41.png` (gerada por `assets/src/prova_cinza_41.py`, luma Rec.601; critério: diferença média absoluta `>= 10` ou `XOR >= 5%` entre cada par) comprova que as 4 ilhotas e os camaleões bípedes chibi são diferenciáveis mesmo sem saturação cromática. O dono aprovou a prancha com o gecko vermelho marcado **pendente**: o script roda de novo quando o gecko vermelho final chegar. A plataforma azul teve o gelo clareado para separar do vermelho em cinza (original em `assets/src/_orig/plataforma-azul-r15.*`).
3. **Tutorial bilíngue cor + padrão:** em `scenes/TutorialCard.gd`, os retângulos chapados das amostras (`=` igual / `X` diferente) e dos 4 quadrados da legenda passam a exibir mini-sprites das ilhotas e do gecko com suas marcas reais acompanhados dos nomes (`amarelo`, `verde`, `azul`, `vermelho`).

---

## 3. Especificação de sprites e animações

Toda a produção segue o pipeline de rascunho em 2 etapas + acabamento manual (`seção 1.4`, `ADR 0004`) ancorado nas referências oficiais de `assets/src/refs/` e na paleta de trabalho (`assets/src/palette.gpl`).

### 3.1 Gecko (`scenes/Player.tscn`, `scenes/Player.gd`)

- **Design do personagem (`assets/src/refs/_inspiracao-ia/gecko-bipede-chibi-ref.jpg` e `assets/src/ref-estilo-dono.jpg`):** camaleão **bípede (em pé sobre as duas patas traseiras) em todas as poses**, com proporção **chibi `1:1` cabeça/corpo**, **olhões grandes esbugalhados com pupilas levemente desalinhadas** (`#fffdf5` + `#052018`) para uma expressão fofa e confusa, **cauda enrolada em espiral**, contorno limpo `#052018` e sombreado quente em 3 tons. As marcas `#41` sutis por cor (manchas solares no amarelo, brotinho de 2 folhas na cabeça no verde, cristais de gelo no dorso/cabeça no azul e espinhos dorsais fofos no vermelho) preservam intacta a silhueta chibi bípede.
- **Tamanho do frame:** **`64×64 px`** exatos (`2×` sobre `32×32 px`), pivô no centro `(32, 32)`. Prepara e preserva proporcionalmente na migração `360×640`:
  - **`GHOST_HALF_WIDTH = 32.0`** (`2×` de `16.0`) para wrap horizontal contínuo nas bordas de `PlayArea.LARGURA = 360`;
  - `CollisionShape2D` do corpo e `DetectorPlataforma` escalados `2×` na entrega de migração para `360×640`, mantendo a base do pé alinhada ao mesmo ponto de contato em todas as poses (`y = 60` do frame `64×64`, `y = +28 px` a partir do pivô).
- **Organização de variantes:** 4 conjuntos de `SpriteFrames` (ou prefixo por cor no mesmo `SpriteFrames`: `amarelo_*`, `verde_*`, `azul_*`, `vermelho_*`), todos compartilhando a mesma grade `64×64` e pontos de contato dos pés para que a troca de cor nunca cause salto visual.
- **6 animações especificadas (bípede chibi em todas as poses):**

| Animação | Frames | FPS | Loop | Duração ciclo | Descrição visual e regra de transição |
|---|---:|---:|---|---|---|
| `idle` | 4 | 6 | Sim | `0.67 s` | **Bípede** (em pé sobre as duas patas traseiras) sobre a plataforma: respiração leve de `1–2 px` na barriguinha/cabeça `1:1`, olhões esbugalhados com pupilas levemente desalinhadas e piscada no frame 3, cauda espiral balançando devagar |
| `run` | 4 | 10 | Sim | `0.40 s` | **Bípede** em corrida energética com alternância rápida das patas traseiras e bracinhos curtos, corpo inclinado à frente e **linhas de velocidade horizontais** (com poeirinha discreta atrás) |
| `jump` | 2 | 10 | Não | `0.20 s` | **Bípede com bracinhos abertos/erguidos**: Frame 0 impulsiona para cima; Frame 1 mantém pose ascendente enquanto `velocity.y < 0` |
| `fall` | 2 | 8 | Sim | `0.25 s` | **Bípede com bracinhos abertos** equilibrando o corpo, olhões atentos/confusos e cauda em espiral durante `velocity.y >= 0` no ar |
| `lose` | 3 | 8 | Não | `0.38 s` | **De cabeça para baixo** (pose cômica invertida), com **olhos em espiral** e **linguinha** de fora durante a `lose_animation` de `1.5 s` |
| `color_change` | 3 | 18 | Não | `0.17 s` | **Bípede** com **efeito arco-íris** percorrendo o corpo, **olhos estrelados** e **brilhos dourados** (`amarelo_luz` / `amarelo_base`) ao redor até estabilizar na nova cor. **Não atrasa física nem colisão:** a nova `color` vale no mesmo frame do pouso; se o jogador pular ou andar imediatamente, `jump`/`run` pode interromper a animação visual sem perder a troca de variante |

- **Sincronização com `Ghost` (`scenes/Player.gd`):** `Ghost` usa o mesmo recurso de spritesheet `64×64` e replica `animation`, `frame` e `flip_h` com `modulate = Color.WHITE` (pois a cor já está pintada no sprite), mantendo `modulate` livre para eventuais brilhos de power-up sem conflitar com o wrap horizontal.
- **Partículas / aura de `color_change`:** `CPUParticles2D` one-shot filho do `Player` (em coordenadas do mundo/`local_coords = false` para deixar rastro curto se o jogador se mover), emitindo **8 a 10 partículas** de `8×8`–`10×10 px` no formato da nova cor (seção 2), duração `0.28 s`, velocidade radial `56–88 px/s`, `gravity = Vector2(0, 80)`, sem colisão. Quando **Camaleão** (`Global.cor_livre`) está ativo, um emissor leve emite 1 partícula a cada `0.12 s` ciclando as 4 formas/cores como aura visual da invulnerabilidade cromática.

### 3.2 Plataformas (`scenes/Platform.tscn`, `scenes/Platform.gd`)

- **Visual de ilhotas flutuantes (`assets/src/refs/_inspiracao-ia/ilhotas-powerups-ref.jpg` e `assets/src/ref-estilo-dono.jpg`):**
  - Cada plataforma é uma **ilhota flutuante de terra/rocha orgânica** (`terra_luz`, `terra_base`, `terra_sombra`) com **base arredondada pendurada** (incluindo 1–2 micro-pedrinhas soltas sob a base, puramente visuais) e **cobertura colorida grossa derramando pela borda** da terra com contorno `#052018`.
  - **Micro-ornamentos no topo (discretos, `4–8 px`, sem nunca parecer obstáculo nem invadir o espaço de power-up):**
    - **Verde:** grama verde + folhinhas e vinhas curtas pendentes na terra.
    - **Vermelho:** cobertura vermelha + micro-cogumelos vermelhos com pintas brancas.
    - **Azul:** cobertura de gelo azul + micro-cristais brilhantes.
    - **Amarelo:** cobertura de mel dourado pingando na borda + micro-florzinhas.
- **Dimensões e técnica 9-slice / 3-fatias (substituindo `region_rect`):**
  - **Altura visual total de `36–44 px`** (`2×` sobre `18–22 px`; peça mestre de referência `96×40 px`, podendo alcançar `44 px` nos picos dos micro-ornamentos e pontas inferiores da terra pendurada), mantendo o plano de pouso/topo útil alinhado à referência física para preservar integralmente **`CollisionShape2D`**, **`AreaCheck`** e a folga proporcional **`ICONE_FOLGA = 4.0 px`** (`2×` de `2.0 px`) entre o topo da cobertura da plataforma e a base de `PowerUpIcone` (`32×32`).
  - As 4 larguras da curva (`ressources/curva_dificuldade.tres`) escaladas `2×` — **`120 px` (`e0`), `112 px` (`e1`), `100 px` (`e2`), `88 px` (`e3`)** (`2×` de `60/56/50/44 px`) — **não usam recorte `region_rect`** (que decepava as pontas nas larguras estreitas).
  - Cada uma das 4 variantes de cor é composta como **textura 9-slice horizontal (`NinePatchRect` ou grupo de 3 `Sprite2D`: `PontaEsq` + `Miolo` + `PontaDir`)** a partir da peça mestre (`96×40 px`) com:
    - **Ponta esquerda (endcap):** **`20 px`** de largura fixa (`patch_margin_left = 20`) — preserva a curva arredondada da ilhota e a cobertura colorida derramando pela lateral.
    - **Miolo repetível:** **`56 px`** de largura no mestre (`axis_stretch_horizontal = TILE`), renderizado com largura útil de **`80 px` (`120`), `72 px` (`112`), `60 px` (`100`) e `48 px` (`88`)** — todos múltiplos pares que repetem cobertura, micro-ornamentos e base de terra sem distorção nem corte de borda.
    - **Ponta direita (endcap):** **`20 px`** de largura fixa (`patch_margin_right = 20`), fechando simetricamente a borda da ilhota.
- **Desmoronamento em 3 estágios de rachadura e ilhota partida (`AVISO_TREMOR_S = 0.3`):**
  - Sobreposição por um nó filho dedicado **`OverlayRachadura`** (`9-slice` horizontal com os mesmos `20 px` de margem lateral, desenhado em `ink_contorno` `#052018` + destaque `1–2 px` `terra_sombra`/`branco_texto` para leitura imediata na cobertura e na terra):
    - **Estágio 0 (intacta):** `OverlayRachadura.visible = false`.
    - **Estágio 1 (início do desmoronamento, `_tempo_restante > AVISO_TREMOR_S`):** fissura capilar inicial descendo da cobertura para a terra, sinalizando imediatamente após o pouso que a ilhota vai ceder.
    - **Estágio 2 (janela de tremor, `0.10 s < _tempo_restante <= AVISO_TREMOR_S = 0.30 s`):** rachaduras ramificadas atravessando cobertura e terra + tremor horizontal `Visual.position.x = ±2.0 px` (`TREMOR_AMPLITUDE` proporcional `2×`, 20 ciclos/s).
    - **Estágio 3 (colapso iminente, `_tempo_restante <= 0.10 s`):** ilhota se partindo em **pedaços de terra separados** por lacunas abertas de `2–4 px` (2 a 3 blocos prestes a desabar).
  - **Fragmentação ao cair (`_tempo_restante <= 0.0`):** antes do `queue_free()` da plataforma, emitir no container pai (`RunningPlatforms` / `Stage`, para sobreviver à liberação do nó) um burst one-shot de **6 a 8 pedaços de terra e cobertura** (`4×4`–`8×6 px` em `terra_base`/`terra_sombra` + cor da plataforma) caindo por `0.35 s` com gravidade (`440 px/s²`), sem colisão.
- **Compatibilidade e isolamento total de canais visuais (sem colisão entre modificadores):**

| Mecânica / ADR | Propriedade visual exclusiva | Comportamento com outros modificadores ativos |
|---|---|---|
| **Cor e padrão `#41`** | Textura da variante no nó filho `Visual` (`NinePatchRect` / 3 fatias) | Nunca usa `sprite.modulate` para tingir cor |
| **`PlatformColorCycle` (`ADR 0010`)** | **Faixa arco-íris** no aviso pré-troca (segmento com as 4 cores da paleta na borda da ilhota) + troca de textura de `Visual` entre `color` e `proxima_cor()` + pulso de **`Visual.modulate.a`** (`1.0` ↔ `AVISO_ALFA_BAIXO = 0.55` a `12 fases/s`) | Sinaliza ciclagem pela faixa arco-íris e alterna a textura/micro-ornamentos inteiros para jogadores daltônicos sem tocar `self.modulate.a` |
| **`PlatformBlink` (`ADR 0012`)** | Exclusivamente **`self.modulate.a`** no nó raiz `Platform` (`1.0` visível, `0.35` no flicker a `20 fases/s`, `0.20` fantasma) | Compõe multiplicativamente com `Visual.modulate.a` do `ColorCycle` sem nunca sobrescrever nem ser sobrescrito por ele |
| **Desmoronamento (`AVISO_TREMOR_S = 0.3`)** | Frame de **`OverlayRachadura`** + deslocamento **`Visual.position.x`** (`±2.0 px`) + burst de pedaços de terra no pai | Ortogonal a `self.modulate.a`, `Visual.modulate.a` e troca de textura; uma plataforma que pisca, cicla e desmorona simultaneamente preserva todos os 3 sinais visuais sem conflito |

### 3.3 Power-ups (`PowerUpIcone`, `PowerUpHud`), Modos (`ModosScreen`) e Ícone (`icon.png`)

- **Ícones `32×32` de power-up (`ADR 0014`, `assets/src/refs/_inspiracao-ia/ilhotas-powerups-ref.jpg`):** usados de forma idêntica sobre a plataforma (`base 4 px acima do topo`) e no `PowerUpHud` (`y = s_top + 60..92`). Todos possuem **contorno `#052018`** e silhueta imediatamente distinguível em qualquer fundo ou escala de cinza:
  - **`camaleao` (`32×32`):** **estrela arco-íris** de 5 pontas com contorno `#052018`, núcleo brilhante `branco_texto`/`amarelo_luz` e faixas das 4 cores da paleta (`vermelho_base`, `amarelo_base`, `verde_base`, `azul_base`).
  - **`segunda_chance` (`32×32`):** **coração vermelho** (`vermelho_base` com brilho `vermelho_luz` e sombra `vermelho_sombra`) com o **rostinho verde do gecko** (`verde_base` + olhos `branco_texto`/`ink_contorno`) no centro e contorno `#052018`.
  - **`desacelera` (`32×32`):** **cronômetro com asinhas** (corpo redondo em `azul_luz`/`branco_texto`, ponteiros e botão superior em `ink_contorno`, duas asinhas brancas laterais em `branco_texto`/`nevoa_brilho`) e contorno `#052018`.
  - **Fallback para tipos de teste:** mantém geração determinística em `#fffdf5` sobre `#052018` (compatível com `PowerUpDesenho`).
- **Estilo do `PowerUpHud` (`y = s_top + 60..92`):**
  - Barra de duração `80×8 px` (`x = 44..124`, `y = s_top + 72..80`): moldura `1–2 px` `ink_contorno` `#052018`, trilho vazio `painel_escuro` `#1f2738`, preenchimento `branco_texto` `#fffdf5` com sombra inferior `2 px` `ui_texto_sec` esvaziando estritamente da direita para a esquerda (leitura por extensão).
  - Segundos restantes (`x = 132..164`) e relógio `m:ss` do modo Contra o tempo (`x = 276..356`): fonte `32 px`, `branco_texto` `#fffdf5` com contorno `ink_contorno` `#052018` (e faixa `#052018` a `70%` quando sobre fundo claro).
  - Carga de `segunda_chance` (`x = 180..212`): mesmo sprite `32×32` do coração com rostinho do gecko, oculto sem carga.
- **5 ilustrações `128×128` dos modos (`ModosScreen`, `x = 116..244` do bloco):**
  - Todas emolduradas por borda `2 px` `ink_contorno` + filete interno `2 px` `ui_texto_sec`, usando apenas a paleta de trabalho:
    1. **`classico` (`128×128`):** gecko bípede em pleno salto sobre ilhotas flutuantes coloridas, fundo *Floresta e Cachoeira* (`b0_floresta`/`b0_agua`) e pequena estrela arco-íris brilhando.
    2. **`puro` (`128×128`):** gecko bípede focado sobre ilhota limpa sob céu estrelado noturno (`painel_escuro`), sem ícones extras (comunica imediatamente "sem power-ups").
    3. **`tempo` (`128×128`):** gecko bípede escalando em diagonal diante do **cronômetro com asinhas** em destaque (`azul_luz`/`branco_texto`/`amarelo_base`).
    4. **`zen` (`128×128`):** gecko bípede relaxado sentado numa ilhota de grama verde sob *Céu Azul e Nuvens* (`b1_ceu`/`branco_texto`), sem névoa de perigo na base.
    5. **`diario` (`128×128`):** página de calendário pixel art destacada com estrela dourada (`amarelo_base`) no topo e silhueta do gecko saltando na base.
  - **Fallback para `teste` (flag debug):** moldura `painel_escuro` `#1f2738` com ícone geométrico de engrenagem/grade `32×32` em `ui_texto_sec` centrado, preservando o carrossel debug sem exigir ilustração dedicada.
- **Ícone do jogo (`icon.png` e variantes de export):**
  - Arte mestre **`128×128 px`** em pixel art seguindo `assets/src/refs/_inspiracao-ia/gecko-bipede-chibi-ref.jpg` e `assets/src/ref-estilo-dono.jpg`: rosto expressivo do camaleão verde (`verde_base`/`verde_luz`/`verde_sombra`) com olhos grandes (`branco_texto` + pupila `ink_contorno`), sorriso simpático e pequeno brilho `amarelo_base` no canto, sobre fundo `b0_floresta` `#3e7d5a` com moldura arredondada `painel_escuro` e contorno `ink_contorno`.
  - **Exportação sem interpolação (`Nearest`):**
    - `icon.png` (raiz, `project.godot:16`): **`128×128 px`** (substituindo o `32×32` provisório).
    - Variantes Web/PWA (`export_presets.cfg:34-36`, preenchidas na entrega de polimento/publicação E7) e loja (itch.io E7 / Play Store E8): **`144×144 px`** (`128×128` centrado com `8 px` de borda de fundo `b0_floresta`), **`180×180 px`** (`128×128` com margem segura `26 px`) e **`512×512 px`** (`4×` inteiro exato de `128×128`, com zona segura central de `66%` para recorte adaptativo Android).

---

## 4. Cenário — 4 biomas luminosos, parallax, partículas e névoa reativa

### 4.1 Mapeamento dos 4 biomas aos estágios (`ressources/curva_dificuldade.tres`)

Todos os 4 biomas (`assets/src/refs/_inspiracao-ia/biomas-4-estagios-ref.jpg`) adotam paleta luminosa 16-bit SNES/GBA com **contraste interno suave (`<= 2.2:1`)** e **sem contorno `#052018`**, mantendo separação imediata em relação às ilhotas, power-ups e gecko contornados em `#052018`.

| Estágio | `progresso_inicio` | Bioma luminoso | Cores da paleta usadas no fundo | Camada 1 (longe, `0.15×`) | Camada 2 (média, `0.30×`) | Camada 3 (partículas ambientais) |
|---|---:|---|---|---|---|---|
| **`e0`** | `0.0` | **Floresta e Cachoeira** | `b0_floresta` `#3e7d5a` + `b0_agua` `#53a6a8` + espuma `nevoa_brilho` e ruínas `terra_base`/`b0_floresta` | Dossel luminoso de floresta e céu filtrado + quedas d'água suaves ao longe | Ruínas de pedra com musgo, troncos laterais e **cipós** nas bordas | 8–10 folhas pixel (`6×4 px`, `b0_floresta`/`verde_luz`, alfa `0.40`) + gotículas de espuma `nevoa_brilho` |
| **`e1`** | `0.35` | **Céu Azul e Nuvens** | `b1_ceu` `#6db4e8` + nuvens `branco_texto`/`ui_texto_sec` sombreadas em `nevoa_brilho` *(HUD com contorno + faixa `70%`)* | Céu azul luminoso com nuvens amplas distantes em dither suave | Bancos de nuvens fofas em camadas médias e montanhas distantes azuladas | 8–10 fiapos de nuvem/brisa (`6×4 px`, `branco_texto`/`nevoa_brilho`, alfa `0.35`) derivando lentamente |
| **`e2`** | `0.70` | **Pôr do Sol** | `b2_roxo` `#6b4b82` + `b2_laranja` `#eb8b54` + silhuetas em `b2_roxo`/`painel_escuro` *(HUD com contorno + faixa `70%`)* | Gradiente crepuscular roxo-laranja suave em dither 16-bit | Cadeias de **montanhas** em silhueta roxo-violácea nas margens e fundo médio | 8–10 motas crepusculares (`4×4 px`, `amarelo_luz`/`b2_laranja`, alfa `0.35`) flutuando devagar |
| **`e3`** | `1.00` | **Noite Estrelada e Aurora** | `painel_escuro` `#1f2738` + aurora `b0_agua` `#53a6a8` / `b2_roxo` `#6b4b82` + estrelas `ui_texto_sec`/`amarelo_luz` | Céu noturno profundo com faixas onduladas luminosas de **aurora** | Constelações e véus suaves de aurora em paralelo distante | 10–14 estrelas cintilantes (`2×2`–`4×4 px`, `ui_texto_sec`/`amarelo_luz`, alfa `0.30–0.50`) |

### 4.2 Transições de bioma, modos sem estágio fixo e janela larga

1. **Modos com progressão de estágio (`Classico`, `Tempo`, `Diario` e `Puro` durante `e0..e3`):**
   - Ao receber o sinal `dificuldade.estagio_mudou(novo)` (`0 -> 1 -> 2 -> 3`), o controlador de fundo executa **crossfade suave de `1.2 s`** entre o bioma atual e o novo bioma (interpolação de opacidade entre grupos de camadas, mantendo o scroll vertical contínuo sem pulo de posição).
2. **Alternância cíclica por distância nos modos sem estágio fixo (`Zen`) e pós-platô (`Puro` / `Classico` após `e3`):**
   - No modo **`Zen`** (`fator_scroll_forcado = 0.0`, sem avanço de estágio na curva de dificuldade) — e igualmente em **`Puro`** ou **`Classico`** após atingir o platô `e3` — o cenário não fica estático indefinidamente: o controlador monitora `ScrollLevel.position_scrolled` (que avança tanto pelo scroll da curva quanto pelo `avancar_camera` da issue `#46`) e a cada **`2.400 px` lógicos acumulados** (`2×` sobre `1.200 px` da base `180×320`, ~24 linhas de plataformas) promove uma **transição cíclica suave** (`e0 -> e1 -> e2 -> e3 -> e0`) com crossfade estendido de **`1.8 s`**.
3. **Arquitetura modular em loop vertical (`640 px` até `924+ px` em `keep_width`):**
   - Todas as camadas de parallax vivem em `z_index < 0` (sempre abaixo de plataformas, gecko, névoa e HUD).
   - **Camada 0 (base de céu):** `ColorRect` / textura gradiente vertical dithered `360×480 px` preenchida em toda a altura visível (`visible_size.y`), velocidade `0.05×`.
   - **Camadas 1 e 2 (parallax):** tiles verticais sem costura **`360×480 px`** (ou `360×360 px` para detalhes médios), configurados com `repeat_size = Vector2(0, 480)` e `repeat_times = 3` (cobrindo `1.440 px` verticais contínuos, garantindo zero bordas descobertas em `360×640`, `360×800` e `360×924+`).
   - **Produção enxuta:** cada bioma precisa de apenas 2 tiles compactos (`360×480`) + 1 sprite de partícula (`8×8`), evitando sobrecarga de acabamento manual no Aseprite.
4. **Cor das barras laterais em janela larga (`1280×720`, `1920×1080`):**
   - Em janela paisagem desktop/Web (`stretch/aspect = "keep_width"`), a área fora da coluna lógica de `360 px` exibe `rendering/environment/defaults/default_clear_color`.
   - O `default_clear_color` em `project.godot:87` passa a **`painel_escuro` `#1f2738`** (`Color(0.1216, 0.1529, 0.2196, 1.0)`), emoldurando a coluna de jogo com tom neutro-escuro coerente com todos os 4 biomas luminosos e com o painel de UI.

### 4.3 Névoa reativa na base (zona de derrota)

- **Função visual:** comunicar intuitivamente, sem texto, que cair pela borda inferior causa derrota (`CheckPlayer`, logo abaixo de `visible_size.y`).
- **Construção visual:** 2 faixas pixel art sobrepostas (`tile 360×64 px`, recorte ondulado com dither 16-bit em `painel_escuro` `#1f2738` / `b2_roxo` `#6b4b82` + crista `nevoa_brilho` `#9ab0c9`, sem gradiente borrado), deslizando horizontalmente em velocidades lentas opostas (`+16 px/s` e `-10 px/s`), ancoradas na borda inferior visível (`y = H`), renderizadas acima do cenário e abaixo do HUD (`layer` abaixo de `CanvasLayer` de HUD, `mouse_filter = IGNORE`).
- **Comportamento reativo por proximidade do gecko:**
  - **No menu (`!started`):** permanece suave e discreta na base (`altura visível = 28 px`, `opacidade = 0.35`, abaixo do último slot do menu).
  - **Em partida com derrota (`Classico`, `Puro`, `Tempo`, `Diario`):**
    - Zona segura (`player.global_position.y < H - 176`): `altura visível = 32 px`, `opacidade = 0.45`.
    - Zona de aproximação (`H - 176 <= player.global_position.y <= H - 32`): fator de perigo `p = clamp((player.y - (H - 176)) / 144.0, 0.0, 1.0)`. A névoa sobe linearmente de **`32 px` até `64 px`** e sua opacidade intensifica de **`0.45` até `0.85`** (com ondulação de frequência `+40%` quando `p > 0.5`), dando feedback imediato antes da queda sem bloquear a leitura da plataforma inferior.
- **Ocultação explícita no modo Zen:**
  - No modo **`Zen`** (`Global.get_modo_jogo() == GameModes.ID_ZEN`, onde não existe derrota e a queda devolve o gecko a uma plataforma) — e também sob `Global.sem_derrota` — a névoa reativa fica **completamente oculta (`visible = false`, `modulate.a = 0.0`)**. A visibilidade é reavaliada imediatamente ao trocar de modo no menu (`_fechar_modos`) e no início da cena (`_ready`).

---

## 5. Tipografia comercial livre, Kit UI e Remodelagem completa do Menu

### 5.1 Fonte comercial livre substituta

A fonte atual (`fonts/alterebro-pixel-font.ttf`) possui licença **CC BY-NC** (não comercial), incompatível com a distribuição comercial planejada (itch.io **E7** e anúncios/IAP na Play Store **E8**).

- **Recomendação primária:** **`m5x7`** (autor: Daniel Linssen, licença **CC0 1.0 Universal** — domínio público, uso comercial irrestrito).
  - **Tamanho nativo:** **`16 px`** (`UiHelpers.FONTE_NATIVO = 16`), grade `5×7 px` por maiúscula (avanço típico `5–6 px` em `16 px`, `10–12 px` em `32 px` e `20–24 px` em `64 px`, compatível com `docs/fonte-pixel-tamanho-nativo.md`).
  - **Escala inteira exata em `360×640` (zero fração de pixel):** `UiHelpers.TAMANHOS_UI = [32, 64]` (ou `[16, 32, 64]` se algum detalhe auxiliar usar `16 px`), mantendo **texto principal em `32 px` (`2×` inteiro exato sobre `16 px`)** e **título / `"Play"` em `64 px` (`4×` inteiro exato sobre `16 px`)** — ambos múltiplos inteiros perfeitos de `UiHelpers.FONTE_NATIVO = 16`, atualizando de forma sincronizada o contrato de `test/test_ui_tamanhos.gd` na migração `360×640`.
  - **Parâmetros obrigatórios no `.import` (travados por `test/test_ui_tamanhos.gd:80-86`):**
    - `antialiasing = 0`
    - `hinting = 0`
    - `subpixel_positioning = 0`
    - `oversampling = 1.0`
    - `generate_mipmaps = false`
  - **Cobertura de glifos:** cobre integralmente todo o conjunto ASCII usado nas strings do jogo (`A–Z`, `a–z`, `0–9`, `: . , ! ? - + < > = / %`), além de acentuação latina básica para eventual localização futura.
- **Alternativas comerciais pré-qualificadas (contingência métrica):** caso a validação real com `FontFile.get_string_size()` na troca da fonte aponte qualquer divergência métrica de `m5x7` frente a `UiHelpers.TAMANHOS_UI = [32, 64]` (ou `[16, 32, 64]`) ou aos limites de largura de `TutorialCard` (`296 px`) e `OptionsScreen` (`224 px`), adotar em ordem de preferência:
  1. **`m3x6`** (Daniel Linssen, **CC0**, nativo `16 px`, proporção ultra-compacta `3×6 px`, avanço `8 px` em `32 px`, margem ainda maior em `360 px`).
  2. **`Tiny5`** ou **`Silkscreen`** (**SIL OFL 1.1**, nativo `8 px`, portanto múltiplos inteiros exatos em **`32 px` = `4×`** e **`64 px` = `8×`**, preservando escala inteira perfeita com cobertura Latin-1 completa).

### 5.2 Kit UI em pixel art (reutilizável em E6, E5 e E8)

Todos os controles (`assets/src/refs/_inspiracao-ia/menu-mockup-ref.jpg`) migram de `StyleBoxFlat` liso para `StyleBoxTexture` 9-slice em pixel art (`filter = Nearest`, sem antialiasing), garantindo alvos interativos `>= 48×48 px` em `360×640` (`2×` sobre `24×24` da base anterior) e pistas não-cor em todos os estados:

> **Divergência aprovada pelo dono (rascunho do menu, `assets/src/refs/menu-rascunho.png`):** os botões do menu são **pílulas** (cantos totalmente arredondados) cujo contorno tem **`1 px` na própria família de cor do botão** (`menu cta linha`, `menu btn linha`, `menu card linha` da seção 1.2), e não `2 px` de `ink_contorno` `#052018` como na linha de botões abaixo. As demais pistas (corpo, chanfro, sombra, estados e alvo `>= 48×48 px`) valem como especificado. Esse acabamento é o que o dono refina no Aseprite; a tabela abaixo permanece como contrato de estados e dimensões.

| Componente | Construção 9-slice / Sprite | Estados e pistas não-cor |
|---|---|---|
| **Botão padrão** (`Modo`, `Opcoes`, `Pausa`, `Modos`, `Options`, `Ranking` E5, `Remover anuncios` E8) | Peça mestre `48×48 px`, `patch_margin = 8 px` nos 4 lados. Borda externa `2 px` `ink_contorno`, chanfro superior `2 px` `ui_btn_luz`, corpo `ui_btn_base`, sombra inferior `4 px` `ui_btn_sombra` | **`normal`:** rótulo centrado (`branco_texto`, contorno `ink_contorno`). **`pressed`:** borda `4 px` `ink_contorno`, corpo `ui_btn_sombra`, chanfro invertido, rótulo `+2 px` em Y. **`disabled`:** corpo `ui_desabilitado`, texto `ui_texto_sec`, sem brilho superior. **`focus`:** moldura externa `4 px` `amarelo_base` + `2 px` `ink_contorno` (`2 px` fora do botão) + prefixo `"> "` no rótulo |
| **Botão CTA `Play`** | Peça mestre `48×48 px`, `patch_margin = 8 px`. Mesma geometria biselada, usando rampa quente `ui_cta_luz` / `ui_cta_base` / `ui_cta_sombra` | Mesmos 4 estados acima; no estado bloqueado do Desafio Diário (`"Ja jogado hoje"`), troca para o estilo `disabled` (`ui_desabilitado` + `ui_texto_sec`) e fonte `32 px` |
| **Ativos prontos para E5 e E8** | **`Ranking` (E5):** botão padrão + mini-ícone troféu `24×24 px` (`amarelo_base` + `ink_contorno`). **`Remover anuncios` (E8):** botão padrão + mini-ícone "AD" riscado `24×24 px` (`ui_texto_sec` + `vermelho_base` + `ink_contorno`) | Entregues prontos no kit UI para ativação imediata no E5 e no E8 sem alterar coordenadas; **não são exibidos como botões mortos antes de seus respectivos marcos** (ver seção 5.3) |
| **Painéis e cards** (`CardPlacar`, `TutorialCard`, telas `Modos` e `Opcoes`) | Peça mestre `48×48 px`, `patch_margin = 8 px`. Borda externa `2 px` `ink_contorno`, filete interno `2 px` `nevoa_brilho`, fundo `painel_escuro` `#1f2738` | `CardPlacar` no menu usa `painel_escuro` sólido (contraste `14.67:1`); fundo de tela cheia dos overlays usa `ink_contorno` `#052018` a `70%` |
| **Sliders (`OptionsScreen`)** | Trilho `296×12 px` em `ink_contorno` com borda `2 px` `ui_texto_sec`; preenchimento pixel art em `ui_btn_luz` `#5b8a4a`; cursor `24×32 px` (`28×40 px` ao arrastar) em `branco_texto` com 2 ranhuras verticais `ui_desabilitado` e contorno `ink_contorno` | Mantém proporção `2×` das medidas de `scenes/OptionsScreen.gd`, rótulo `"mudo"` em `0`, cursor alargado ao arrastar e moldura + `"> "` no foco |
| **`PauseBotao` (`48×48`)** | 9-slice do botão padrão (`48×48`) em `x[s_left + 4, s_left + 52]`, `y[s_top + 4, s_top + 52]` | Glifo pixel art de 2 barras `6×24 px` em `branco_texto` com contorno `ink_contorno` (`+2 px` em Y no `pressed`); oculto fora de partida ativa |
| **`LevelUpFrame`** | Vinheta de borda (`PROFUNDIDADE = 40 px` dentro da `safe_area`) + cantoneiras pixel art sutis `16×16 px` nos 4 cantos | Pulsa `N` vezes (`N = estagio novo`) em `amarelo_luz` / `branco_texto` (`ALPHA_PICO = 0.5`), sem texto, `MOUSE_FILTER_IGNORE` e congelado na pausa (`ADR 0008`) |
| **`TouchHint`** | Linha divisória em `x = 180` (traço `4 px` liga / `4 px` desliga em `branco_texto` a `60%` com sombra `2 px` `ink_contorno`); setas direcionais pixel art `48×48` (`branco_texto` + contorno `ink_contorno`) | Faixa `COR_FUNDO_OVERLAY` atrás das 2 linhas de texto (`32 px`), preservando proporcionalmente `2×` os retângulos e regras de fade-out de `scenes/TouchHint.gd` |
| **`TutorialCard`** | Card `328 px` de largura (`296 px` de conteúdo útil em `360×640`) com 9-slice de painel e botão `Pular`/`Voltar` no estilo padrão | Amostras `=` / `X` e legenda `2×2` exibem mini-sprites acessíveis (`#41`, seção 2) com nomes por escrito, mantendo toda linha `<= 296 px` em `32 px` |

### 5.3 Remodelagem completa do menu (`360×640` e `360×800+`)

#### Decisão de produto para o slot E8 ("Remover anúncios") e slot E5 ("Ranking")

- **Slot `Remover anuncios` (E8) — Opção A (aprovada):** o menu mantém o **espaço reservado vazio** nas coordenadas da tabela abaixo durante o E6 e a publicação gratuita do E7 no itch.io (evitando exibir um botão morto/desabilitado que confundiria jogadores da versão gratuita), enquanto o ativo visual completo (botão 9-slice + ícone "sem anúncios") já fica pronto no kit UI para ativação direta no E8.
- **Slot `Ranking` (E5):** segue o mesmo princípio de espaço reservado vazio nas coordenadas fixas abaixo até a entrega do E5, garantindo que tanto E5 quanto E8 ativem seus botões no lugar sem mover `Logo`, `Play`, `Modo`, `CardPlacar` ou `Opcoes`.
- **Visibilidade do HUD `Pontos` no menu:** durante o estado de menu (`!started`), o rótulo `Pontos` (`x[82, 356], y[s_top, s_top + 60]`) fica **oculto** para não poluir o topo acima do logo `"GECKO JUMP"`, passando a visível assim que a partida inicia (`started == true`).

#### Regra única de ancoragem (vale para `360×640`, `360×800` e `360×924+`)

Todos os elementos do menu compõem um **bloco unificado centrado** (classe **centro**) de altura total **`H_BLOCO = 556 px`** (`2×` exato de `278 px` na base `180×320`), contido integralmente na `safe_area`:

- **Símbolos:** `s_top = safe.position.y`, `s_bottom = H - safe.end.y`, `s_left = safe.position.x`, `s_right = 360 - safe.end.x`, altura útil `U = H - s_top - s_bottom`, largura útil `W_util = 360 - s_left - s_right`.
- **Origem vertical:** `y0 = max(s_top, floor(s_top + (U - 556) / 2))`.
- **Origem horizontal de cada elemento de largura `w`:** `x0 = s_left + floor((W_util - w) / 2)`.
- **Cobertura garantida de `safe_area`:** como `H_BLOCO = 556 px`, o bloco inteiro cabe folgadamente dentro de:
  - `360×640` sem entalhe (`U = 640` → `y0 = 42`, fim `y = 598`);
  - `360×640` com entalhe padrão (`s_top = 40, s_bottom = 12`, `U = 588` → `y0 = 56`, fim `y = 612 <= 628`);
  - `360×640` com entalhe extremo (`s_top = 60, s_bottom = 0`, `U = 580` → `y0 = 72`, fim `y = 628 <= 640`);
  - `360×800` sem entalhe (`1080×2400` a `3×` inteiro, `U = 800` → `y0 = 122`, fim `y = 678`);
  - `360×800` com entalhe (`s_top = 40, s_bottom = 12`, `U = 748` → `y0 = 136`, fim `y = 692 <= 788`);
  - `360×924` com entalhe (`s_top = 40, s_bottom = 20`, `U = 864` → `y0 = 194`, fim `y = 750 <= 904`).

#### Tabela única de coordenadas exatas (px lógicos em `360×640` e `360×800`)

Valores horizontais com `s_left = s_right = 0`. A coluna `360×640` assume `s_top = s_bottom = 0` (`y0 = 42`); a coluna `360×800` assume `s_top = s_bottom = 0` (`y0 = 122`); com entalhe, soma-se apenas a variação de `y0` da fórmula acima. *(Equivalência exata `2×` sobre a grade anterior `180×320` com `y0 = 21` e `180×400` com `y0 = 61`.)*

| Elemento | Tamanho (`w×h`) | `y_rel` no bloco | Folga abaixo | `360×640` (`y0 = 42`) | `360×800` (`y0 = 122`) | Estado / Regra |
|---|---|---|---:|---|---|---|
| **Logo `"GECKO JUMP"`** | `312×96` | `[0, 96]` | `20 px` | `x[24, 336] y[42, 138]` | `x[24, 336] y[122, 218]` | Sprite pixel art (não interativo, `assets/src/refs/_inspiracao-ia/menu-mockup-ref.jpg`): letras gordinhas arcade com contorno escuro `#052018`, `"GECKO"` verde-amarelo com `G` em cauda espiral, `"JUMP"` em gradiente quente e gecko chibi empoleirado |
| **Botão `Play` (normal)** | `248×72` | `[116, 188]` | `16 px` | `x[56, 304] y[158, 230]` | `x[56, 304] y[238, 310]` | CTA `ui_cta_base`, fonte `64 px`; alvo `>= 48×48` |
| **Botão `Play` (estendido Diário)** | `296×72` | `[116, 188]` | `16 px` | `x[32, 328] y[158, 230]` | `x[32, 328] y[238, 310]` | Texto `"Ja jogado hoje"` em `32 px`, estado `disabled`; mesma altura/faixa `y` do normal |
| **Botão `Modo: <nome>`** | `296×52` | `[204, 256]` | `16 px` | `x[32, 328] y[246, 298]` | `x[32, 328] y[326, 378]` | Botão padrão `ui_btn_base`, fonte `32 px`; comporta todos os rótulos de `GameModes.gd` |
| **Card Placar (`FaixaPlacar`)** | `328×84` | `[272, 356]` | `20 px` | `x[16, 344] y[314, 398]` | `x[16, 344] y[394, 478]` | Painel `painel_escuro` (`MOUSE_FILTER_IGNORE`); envolve `Last` e `Best` |
| └─ **Linha `Last`** *(filho do card)* | `312×34` | `[278, 312]` | `4 px` | `x[24, 336] y[320, 354]` | `x[24, 336] y[400, 434]` | Fonte `32 px`, contorno `#052018`; comporta 4 dígitos (`9999`) |
| └─ **Linha `Best`** *(filho do card)* | `312×34` | `[316, 350]` | `6 px` *(pad)* | `x[24, 336] y[358, 392]` | `x[24, 336] y[438, 472]` | Fonte `32 px`, contorno `#052018`; oculta no modo Zen sem mover o card |
| **Botão `Opcoes`** | `264×52` | `[376, 428]` | `12 px` | `x[48, 312] y[418, 470]` | `x[48, 312] y[498, 550]` | Botão padrão `ui_btn_base`, fonte `32 px`; ativo em E6/E7/E5/E8 |
| **Slot `Ranking` (E5)** | `264×52` | `[440, 492]` | `12 px` | `x[48, 312] y[482, 534]` | `x[48, 312] y[562, 614]` | **Reservado vazio antes do E5**; ativo no E5 no mesmo retângulo |
| **Slot `Remover anuncios` (E8)** | `296×52` | `[504, 556]` | — | `x[32, 328] y[546, 598]` | `x[32, 328] y[626, 678]` | **Opção A: reservado vazio antes do E8 + ativo pronto no kit UI**; ativo no E8 |

#### Prova matemática de pior caso (zero interseção, folgas e textos em `360×640`)

1. **Disjunção mútua e folga `>= 12 px`:**
   - Todos os 7 blocos principais ocupam faixas verticais estritamente crescentes e disjuntas: `[0, 96]`, `[116, 188]`, `[204, 256]`, `[272, 356]`, `[376, 428]`, `[440, 492]`, `[504, 556]`.
   - Folgas verticais entre blocos adjacentes: **`20 px`, `16 px`, `16 px`, `20 px`, `12 px`, `12 px`** — todas `>= 12 px` (mesmo descontando `2 px` externos da moldura de foco em dois botões vizinhos, restam `>= 8 px`).
   - Dentro do `CardPlacar`, `Last` (`[278, 312]`) e `Best` (`[316, 350]`) são disjuntos com folga exata de **`4 px`** e `6 px` de respiro superior/inferior dentro do painel `[272, 356]`.
2. **Alvos interativos `>= 48×48`:** `Play` (`248×72` / `296×72`), `Modo` (`296×52`), `Opcoes` (`264×52`), slot `Ranking` (`264×52`) e slot `Remover anuncios` (`296×52`) — todos têm largura `>= 248 px` e altura `>= 52 px` (`>= 48×48`).
3. **Pior caso de largura de texto (`m5x7` a `32 px`: avanço máx. `12 px/caractere`; `64 px`: `24 px/caractere`):**
   - `"> Play"` em `64 px`: `6 × 24 = 144 px <= 248 px` (sobra `104 px`).
   - `"Ja jogado hoje"` em `32 px` (Desafio Diário): `14 × 12 = 168 px <= 296 px` (mesmo em fonte contingência de avanço `14 px`: `196 px <= 296 px`, sobra `100 px`).
   - `"> Modo: Classico"` (rótulo curto mais longo de `scripts/GameModes.gd`): `16 × 12 = 192 px <= 296 px` (sobra `104 px`). Comporta até o hipotético rótulo longo `"> Modo: Contra o tempo"` (`22 × 12 = 264 px <= 296 px`, sobra `32 px`).
   - `"Melhor pontuacao: 9999"` e `"Ultima pontuacao: 9999"` (4 dígitos em `32 px`): `22 × 12 = 264 px <= 312 px` úteis do `CardPlacar` (mesmo em fonte contingência `14 px`: `308 px <= 312 px`).
   - `"> Opcoes"`: `8 × 12 = 96 px <= 264 px` (sobra `168 px`).
   - `"> Ranking"`: `9 × 12 = 108 px <= 264 px` (sobra `156 px`).
   - `"> Remover anuncios"`: `18 × 12 = 216 px <= 296 px` (sobra `80 px`).

```text
 escala aproximada: 1 coluna = 10 px; mostra 360x640 (y0 = 42); vale a tabela (2x de 180x320)
 +------------------------------------+  y = 0
 |                                    |
 |   +----------------------------+   |  y 42..138  Logo "GECKO JUMP" (312x96)
 |   |         GECKO JUMP         |   |
 |   +----------------------------+   |
 |                                    |  folga 20 px
 |    [         Play         ]        |  y 158..230 Play (248x72 | estendido 296x72)
 |                                    |  folga 16 px
 |    [    Modo: Classico    ]        |  y 246..298 Modo (296x52)
 |                                    |  folga 16 px
 |  +------------------------------+  |  y 314..398 Card Placar (328x84)
 |  |   Ultima pontuacao: 9999     |  |  y 320..354 Last (32 px)
 |  |   Melhor pontuacao: 9999     |  |  y 358..392 Best (32 px, folga 4 px)
 |  +------------------------------+  |
 |                                    |  folga 20 px
 |      [       Opcoes       ]        |  y 418..470 Opcoes (264x52)
 |      :     (Ranking E5)   :        |  y 482..534 Slot reservado vazio (E5)
 |    :   (Remover anuncios E8)  :    |  y 546..598 Slot reservado vazio (E8)
 |~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|  y 612..640 Nevoa suave (oculta no Zen)
 +------------------------------------+  y = 640
```

#### Ordem de foco no menu (teclado / joypad)

- Em **E6 / E7:** ciclo vertical `Play` ↔ `Modo` ↔ `Opcoes` (pula slots vazios reservados).
- Em **E5:** `Play` ↔ `Modo` ↔ `Opcoes` ↔ `Ranking`.
- Em **E8:** `Play` ↔ `Modo` ↔ `Opcoes` ↔ `Ranking` ↔ `Remover anuncios`.

### 5.4 Nota de impacto em testes e roteiros de smoke na entrega de UI/Menu

A migração para `360×640`, a remodelagem completa do menu e a troca da fonte `.ttf` nas entregas correspondentes do E6 têm impacto previsto e planejado sobre os seguintes artefatos de validação:

- **Testes GUT de layout, fonte e contraste (`test/`):**
  - `test/test_stage_hud.gd` — atualizar expectativas de `Rect2` de `Play`, `Last`, `Best` (que migram para o bloco centrado `H_BLOCO = 556` em `360×640`) e validar ocultação de `Pontos` no menu / visibilidade na partida;
  - `test/test_stage_faixa_placar.gd` — atualizar cor/estilo do card do placar (`painel_escuro` / `COR_FUNDO_OVERLAY`) e checagem de não-sobreposição com o novo layout;
  - `test/test_modo_botao.gd` e `test/test_opcoes_botao.gd` — atualizar constantes de `Rect2` de `ModoBotao` (`296×52`) e `OpcoesBotao` (`264×52`) e a fórmula de centro na `safe_area`;
  - `test/test_ui_tamanhos.gd` — atualizar o caminho `FONTE_IMPORT` de `alterebro-pixel-font.ttf.import` para o arquivo `.import` da fonte comercial (`m5x7`) e os tamanhos escalados (`TAMANHOS_UI = [32, 64]` ou `[16, 32, 64]`, todos múltiplos inteiros de `FONTE_NATIVO = 16`), preservando todas as asserções de `hinting = 0`, `subpixel_positioning = 0`, `oversampling = 1.0` e `antialiasing = 0`.
- **Roteiros de smoke (`test/smoke/*.smoke.json`):**
  - Todos os roteiros que disparam clique/toque por coordenadas fixas nos botões do menu (`Play`, `Modo`, `Opcoes` — cerca de 10 roteiros, incluindo `modos.smoke.json`, `opcoes.smoke.json`, `opcoes-persistencia.smoke.json`, `modo-puro.smoke.json`, `modo-tempo.smoke.json`, `modo-zen.smoke.json`, `modo-diario.smoke.json` e `tutorial-reabertura.smoke.json`) devem ser atualizados para os centros exatos dos novos retângulos da tabela da seção 5.3 em `360×640`.

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
| **Estágio `e0`** (*Floresta e Cachoeira*) | `music_e0_floresta.ogg` | `loop = true` | Tema principal chiptune leve e convidativo (melodia principal + baixo triângulo suave); usado também no menu inicial e como base calma no modo `Zen`. |
| **Estágio `e1`** (*Céu Azul e Nuvens*) | `music_e1_ceu_nuvens.ogg` | `loop = true` | Acrescenta arpejo fluido e percussão leve mantendo a mesma grade rítmica de `e0`. |
| **Estágio `e2`** (*Pôr do Sol*) | `music_e2_por_do_sol.ogg` | `loop = true` | Expande a harmonia com contracanto brilhante e condução rítmica mais firme. |
| **Estágio `e3`** (*Noite Estrelada e Aurora*) | `music_e3_noite_aurora.ogg` | `loop = true` | Variação de clímax de alta energia com linhas rápidas de sintetizador retrô. |
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

