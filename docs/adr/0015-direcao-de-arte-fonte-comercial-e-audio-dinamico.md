# 0015 — Direcao de arte, fonte comercial livre, menu remodelado e audio dinamico

- **Status:** aceito
- **Data:** 2026-11-24 (consolidado em 2026-11-25 com resolucao `360x640`, gecko bipede chibi e referencias aprovadas)
- **Decisores:** itsManeka + Claude

## Contexto

Com toda a mecanica central concluida nos marcos E1–E4, o marco E6 (issue #18) substitui os ativos provisorios de game
jam por arte pixel art definitiva, acessibilidade sem cor (issue #41), interface redesenhada e audio completo (issues
#13 e #43). A auditoria tecnica da base atual revelou quatro restricoes que exigem decisao arquitetural antes da
producao e integracao dos ativos:

1. **Bloqueio comercial de fonte e sons provisorios:** `fonts/alterebro-pixel-font.ttf` esta sob licenca **CC BY-NC**
   (nao comercial), incompativel com a publicacao planejada no itch.io (E7) e com monetizacao por anuncios/IAP na Play
   Store (E8). Alem disso, `sounds/jump.wav` e `sounds/lose.wav` nao possuem registro de autor ou licenca no repositorio.
2. **Menu sem espaco para evolucao (E5 e E8):** o menu atual ancora `Play`, `Last` e `Best` em coordenadas fixas de topo
   sem espaco reservado para o futuro botao `Ranking` (E5, issue #29) nem para `Remover anuncios` (E8, issue #30), e
   ainda nao possui logotipo nem kit visual reutilizavel em pixel art.
3. **Recarga completa de `Stage.tscn`:** `scenes/Stage.gd:846` reinicia a cena via
   `get_tree().change_scene_to_file("res://scenes/Stage.tscn")` apos a derrota, na saida pela pausa, na troca de modo
   que cruza a fronteira do Desafio diario e na virada de dia UTC. Qualquer player de musica dentro de `Stage.tscn`
   seria destruido e reiniciado abruptamente a cada recarga.
4. **Convivencia com pausa, WebAudio e ADRs vigentes:** a pausa usa `get_tree().paused`
   ([ADR 0008](0008-pausa-por-tree-paused.md)), os sliders `Music` e `SFX` atuam em tempo real sobre os buses de
   `default_bus_layout.tres` (`scripts/Global.gd:271-300`, `OptionsStore.MUTE_DB = -80.0`), e navegadores bloqueiam o
   `AudioContext` ate o primeiro gesto do usuario.

A especificacao visual, de acessibilidade, de geometria do menu, de audio e de licencas completa vive em
`docs/planejamento-design/direcao-de-arte.md`.

### Relacao com ADRs anteriores

- **Evolucao do [ADR 0002](0002-tela-mobile-largura-180.md) (`180x320` -> `360x640`):** esta decisao **evolui** o
  `ADR 0002` (que fixava largura logica `180x320`) para **`360x640`** (fator exato **`2x`**), mantendo integralmente
  todos os principios do `ADR 0002`: largura logica fixa em modo retrato (`keep_width`), filtro `Nearest`,
  `scale_mode = "integer"`, altura expandida em aparelhos altos e **escala inteira exata** em todos os celulares-alvo
  (`720 / 360 = 2x` em `720x1280` -> `360x640`; `1080 / 360 = 3x` em `1080x2400` -> `360x800`; `1440 / 360 = 4x`). A
  migracao de codigo, fisica, camera e UI para `360x640` foi executada em entrega propria (2026-11-26), antes da
  integracao dos sprites finais: os sprites atuais aparecem em escala visual `2x` so nos nos filhos visuais, e o corpo
  fisico da plataforma segue com `scale == Vector2.ONE` (ADR 0009).

Os demais ADRs seguintes **permanecem aceitos integralmente**:

- [ADR 0004](0004-arte-no-aseprite-com-rascunho-por-ia.md) (`aceito`): arte produzida no Aseprite local com fontes
  editaveis isoladas em `assets/src/` (fora do `.pck` via `assets/src/.gdignore`) e exportacao PNG/JSON. Com esta
  decisao, o rascunho deixa de vir de geracao de imagem por IA: o rascunho e desenhado na grade pelo agente
  `pixel-artist` (ver secao 1), seguido do acabamento manual do dono. As imagens de IA ficam so como inspiracao.
- [ADR 0006](0006-oraculo-de-jogo-em-3-camadas.md) (`aceito`): oraculo em 3 camadas mantido; alteracoes de resolucao e
  layout de menu atualizam explicitamente os testes GUT de `Rect2` e roteiros `test/smoke/*.smoke.json`.
- [ADR 0008](0008-pausa-por-tree-paused.md) (`aceito`): pausa governada por `get_tree().paused`, com
  `PROCESS_MODE_ALWAYS` restrito ao que precisa operar pausado (overlay, opcoes, sons de UI e player de musica
  atenuado).
- [ADR 0014](0014-power-ups-e-modos-de-jogo.md) (`aceito`): 3 power-ups e 5 modos de jogo mantidos; icones `32x32 px`,
  ilustracoes `128x128 px` (`2x` sobre `16x16` e `64x64` na nova grade `360x640`) e cues sonoros respeitam todas as
  regras de cada modo (incluindo `Zen` sem derrota e sem nevoa).

## Decisao

### 1. Direcao de arte, resolucao `360x640`, acessibilidade `#41` e 4 biomas luminosos

- **Resolucao logica `360x640` (`2x` sobre `180x320`):** para acomodar o nivel de detalhe 16-bit SNES/GBA aprovado
  (olhos expressivos, cauda espiral, ilhotas organicas com cogumelos/cristais/flores, biomas detalhados e logo arcade)
  sem perda nem borrao, a resolucao logica passa para **`360x640`** (`keep_width`, `Nearest`,
  `scale_mode = "integer"`), garantindo escala inteira exata em `720p` (`2x`), `1080p` (`3x`) e `1440p` (`4x`).
  A escolha foi confirmada por uma prova lado a lado: o mesmo gecko desenhado na grade em `32x32` e em `64x64`, usando
  apenas cores da paleta, exibido no mesmo tamanho fisico de `720x1280`. A versao `64x64` tem 6 cores e a `32x32` tem
  5; nas duas, 0 pixels ficam fora da paleta. A migracao de codigo para `360x640` segue em entrega propria.
- **Identidade, paleta e pipeline:** adotar estetica pixel art **16-bit SNES/GBA luminosa e carismatica**, com contorno
  escuro limpo `#052018`, sombreado quente e acabamento manual do dono. A referencia de cada personagem e uma ref mestra
  aprovada pelo dono (o gecko bipede chibi), e a estrutura de todas as rodadas e medida contra ela. A paleta de trabalho
  (`assets/src/palette.gpl`) e um conjunto de rampas aprovadas por material, **sem teto fixo de cores**: a paleta de
  32 cores da fase anterior vira base, nao limite. Obrigatorios: as 4 ancoras de `scripts/Enums.gd` (`#f6db61`,
  `#79cf5a`, `#5987e9`, `#ec4848`) como cor media de cada variante; contraste do padrao `#41` em escala de cinza; e
  contraste **WCAG AA >= 4.5:1** em todos os pares de texto/UI (com contorno `#052018` e faixa `#052018` a `70%` no HUD
  sobre fundos claros). Ilhotas flutuantes usam 3 tons de terra/rocha organica.
- **Pipeline de arte:** o agente `pixel-artist` (modelo `opus`) desenha na grade e na paleta de trabalho no Aseprite,
  uma pose por rodada. Cada rodada ancora a estrutura na ref mestra: mede mascara, IoU e medidas em px, e gera um
  comparativo ref x rodada. A rodada anterior fornece so acabamento (rampa, contorno), nunca a forma. Autocritica com
  checklist e obrigatoria. O dono faz o acabamento manual e aprova cada ref; nenhuma ref e dada como pronta sem
  aprovacao explicita do dono. Imagens geradas por IA nao sao etapa obrigatoria: ficam em
  `assets/src/refs/_inspiracao-ia/` como mood board, sem copia de pixel.
- **Acessibilidade sem cor (`#41`) e Gecko bipede chibi em `360x640`:** implementar acessibilidade sem cor (issue #41)
  em quatro frentes sincronizadas e distinguiveis em escala de cinza a `360 px`:
  - plataformas como **ilhotas flutuantes de terra/rocha** (`36-44 px` de altura visual, 9-slice `120/112/100/88 px` —
    `2x` de `60/56/50/44 px`, endcaps `20 px`, topo pisavel e `ICONE_FOLGA = 4.0 px` proporcionais) com cobertura
    colorida derramando na borda, micro-ornamentos no topo (grama/folhas, mel/florzinhas, gelo/cristais,
    vermelho/cogumelos), 3 estagios de rachadura e faixa arco-iris na ciclagem (canais isolados de `PlatformBlink`);
  - gecko **`64x64 px`** (`GHOST_HALF_WIDTH = 32.0`), **bipede (em pe sobre as duas patas traseiras) em todas as
    poses** (`idle`, `run`, `jump`, `fall`, `lose`, `color_change`), em **perfil 3/4 lateral**, com proporcao **chibi
    `1:1` cabeca/corpo**, crista na cabeca, olhos grandes saltados na lateral com pupilas levemente desalinhadas
    (expressao fofa e confusa), cauda enrolada em espiral,
    **`lose`** de cabeca para baixo com olhos em espiral e linguinha, **`color_change`** arco-iris com olhos
    estrelados e brilhos dourados, e as **4 marcas `#41` sutis** aprovadas (amarelo: manchas solares; verde: brotinho
    de 2 folhas na cabeca; azul: cristais de gelo no dorso/cabeca; vermelho: espinhos dorsais fofos);
  - particulas de `color_change` (`8x8`–`10x10 px`), power-ups `32x32 px`, ilustracoes dos 5 modos `128x128 px` e
    mini-sprites rotulados no `TutorialCard`.
- **4 biomas luminosos:** organizar o cenario em **`e0` Floresta e Cachoeira, `e1` Ceu Azul e Nuvens, `e2` Por do Sol
  roxo-laranja com montanhas e `e3` Noite Estrelada e Aurora** com alternancia ciclica por distancia (`2.400 px` em
  `360x640`, `2x` de `1.200 px`) no `Zen` e pos-plato, `default_clear_color = #1f2738` e **nevoa reativa na base**
  (oculta no modo `Zen` e sob `Global.sem_derrota`).

### 2. Troca comercial da fonte (`alterebro-pixel-font.ttf` -> `m5x7`)

- Substituir `fonts/alterebro-pixel-font.ttf` (**CC BY-NC**, bloqueada para uso comercial) por **`m5x7`** (Daniel
  Linssen, **CC0 1.0**, tamanho nativo `16 px`, proporcao 5x7), com `UiHelpers.FONTE_NATIVO = 16`,
  **`TAMANHOS_UI = [32, 64]`** (ou `[16, 32, 64]` — texto principal **`32 px` = `2x` inteiro exato** e titulo/`Play`
  **`64 px` = `4x` inteiro exato** em `360x640`, zero fracao de pixel; `test/test_ui_tamanhos.gd` atualizado na
  migracao) e import sem antialiasing/hinting/subpixel (`antialiasing = 0`, `hinting = 0`, `subpixel_positioning = 0`,
  `oversampling = 1.0`).
- Em caso de divergencia metrica na importacao real, adotar as alternativas comerciais pre-qualificadas em ordem:
  `m3x6` (**CC0 1.0**, nativo `16 px`) ou `Tiny5` / `Silkscreen` (**SIL OFL 1.1**, nativo `8 px`, multiplos inteiros
  exatos em `32 px` = `4x` e `64 px` = `8x`).

### 3. Remodelagem do menu em `360x640` e estado dos slots reservados (E5 e E8)

- Remodelar o menu como um **bloco unificado centrado (`H_BLOCO = 556 px`, `y0 = 42` em `360x640`)** — escala exata
  `2x` sobre `180x320` — dentro da `safe_area` para `360x640` e `360x800+`, conforme a tabela de coordenadas exatas de
  `docs/planejamento-design/direcao-de-arte.md` (secao 5.3): Logo `"GECKO JUMP"` (`312x96`), `Play` (normal `248x72` e
  estendido `296x72` para `"Ja jogado hoje"`), `Modo: <nome>` (`296x52`), `CardPlacar` (`328x84`, `4 px` entre `Last` e
  `Best`), `Opcoes` (`264x52`), slot `Ranking` (E5, `264x52`) e slot `Remover anuncios` (E8, `296x52`), todos mutuamente
  disjuntos, com folgas `>= 12 px` e alvos `>= 48x48`.
- **Estado do slot `Remover anuncios` (E8) antes do E8 (decisao aprovada — Opcao A):** manter o **espaco reservado
  vazio** no menu durante o E6 e a publicacao gratuita do E7 no itch.io, enquanto o **ativo visual completo** (botao
  9-slice + icone) permanece pronto no kit UI para ativacao direta no E8 sem deslocar nenhum outro controle. O slot
  `Ranking` (E5) segue o mesmo padrao de espaco reservado vazio ate a entrega do E5.

### 4. Arquitetura de musica dinamica persistente, pausa e SFX

- **Musica dinamica no bus `Music`:** 4 variacoes musicais (`.ogg`, `loop = true`) correspondentes aos estagios `e0..e3`
  + stingers curtos, reproduzidas via **`AudioStreamInteractive`** do Godot 4.7.2 com transicoes alinhadas ao
  tempo/compasso.
- **Fallback oficial para Web/WASM:** formalizar **`AudioStreamSynchronized` (stems em crossfade via `Tween`)** como
  fallback tecnico oficial caso o export HTML5/WebAssembly apresente estalos ou limitacao no `AudioStreamInteractive`,
  preservando a mesma interface publica do gerenciador de musica para `Stage.gd`.
- **Hospedagem fora de `Stage.tscn`:** o `AudioStreamPlayer` da musica vive em um **autoload persistente**
  (`MusicManager`, ou no filho persistente do autoload `Global`) com `bus = &"Music"` e
  `process_mode = Node.PROCESS_MODE_ALWAYS`, resistindo intacto a `get_tree().change_scene_to_file("res://scenes/Stage.tscn")`
  (`scenes/Stage.gd:846`, `_recarregar_stage()`).
- **Comportamento da musica na pausa (`ADR 0008` — decisao aprovada — Opcao A):** quando `get_tree().paused == true`,
  a musica **nao pausa** — sofre **atenuacao (ducking) de `-12 dB`** aplicada exclusivamente no `volume_db` do player de
  musica (com `process_mode = ALWAYS`), sem alterar o ganho do bus `Music` nem o valor salvo em `OptionsStore`. Isso
  preserva o feedback auditivo em tempo real ao arrastar o slider `Music` em Pausa -> Opcoes, e continua respeitando o
  mudo total em `0%` (`OptionsStore.MUTE_DB = -80.0 dB` + `AudioServer.set_bus_mute(idx, true)` em
  `scripts/Global.gd:295-300`). Em perda de foco/background do aplicativo (`NOTIFICATION_APPLICATION_PAUSED` /
  `FOCUS_OUT`), a saida fica temporariamente silenciada ate o retorno do foco.
- **Desbloqueio WebAudio:** no export Web (`OS.has_feature("web")`), o gerenciador aguarda o primeiro gesto de entrada
  do usuario (`InputEvent` pressionado) antes de iniciar a reproducao de forma idempotente.
- **SFX no bus `SFX`:** estetica chiptune retro sintetizada localmente por ferramenta/agente de sintese baseada em
  `jsfxr` com pares `<nome>.wav` + `<nome>.sfx.json`, respeitando estritamente as excecoes de gameplay e pausa:
  - pouso que pontua (`#13`) separado do salto/pouso inicial `-1 -> 0` (`scenes/Stage.gd:928-930`) e de
    reaparecimentos sem ponto (`Segunda chance` e `Zen`, `_guarda_reaparecimento`);
  - aviso de subida de estagio (`#43`, ~0,5 s) bloqueado em `STATE_LOST` (`scenes/Stage.gd:469-470`);
  - som de rachadura/desmoronamento desativado quando `Global.sem_derrota` esta ativo (`scripts/PlatformCrumble.gd:14`);
  - sons de UI configurados com `process_mode = Node.PROCESS_MODE_ALWAYS` para soar tambem na pausa.

### 5. Auditoria de licencas comerciais e origem da musica

- **Ativos bloqueados hoje no repo:**
  - `fonts/alterebro-pixel-font.ttf` (`CC BY-NC`) — bloqueado para distribuicao comercial (E7/E8); substituido na
    entrega de UI/Menu.
  - `sounds/jump.wav` e `sounds/lose.wav` (ausencia total de registro de licenca) — bloqueados para distribuicao
    comercial segura; copias historicas preservadas fora do export em `assets/src/_orig/` e substituidas por sintese
    propria na entrega de SFX.
- **Registro obrigatorio:** manter `fonts/LICENSES.md` e `sounds/LICENSES.md` listando arquivo, autor, origem/URL (ou
  preset/seed `.sfx.json`), licenca comercial compativel (autoral, CC0 1.0, SIL OFL 1.1, MIT/Apache-2.0, CC BY 4.0 com
  atribuicao, ou licenca comercial paga documentada) e status para E7/E8. Licencas `NC` e `ND` (em midia editavel) sao
  proibidas no `.pck`.
- **Opcoes concretas de origem comercial para a musica em 4 variacoes:**
  1. Composicao autoral propria em tracker/DAW chiptune livre (**Furnace Tracker**, **LMMS** ou **BeepBox /
     JummBox**), exportando as 4 variacoes (`e0..e3`) e stingers sincronizados no mesmo BPM e tom com 100% de direitos
     autorais do projeto;
  2. Pacotes chiptune sob **CC0 1.0 Universal** multi-secao/em stems de catalogos verificaveis (**OpenGameArt.org**, ex.
     colecoes chiptune CC0 *SubspaceAudio / Juhani Junkala* ou equivalentes verificados, e packs **CC0** no **itch.io**),
     adaptados em 4 loops coerentes;
  3. Pacote chiptune comercial royalty-free ou encomenda pontual com licenca escrita cobrindo distribuicao gratuita,
     anuncios e IAP.

## Consequencias

- **Positivas:** elimina risco juridico antes das entregas comerciais E7/E8; garante resolucao `360x640` (`2x` sobre
  `180x320`) com escala inteira exata em 720p/1080p/1440p e nitidez suficiente para a estetica 16-bit SNES/GBA e o
  camaleao bipede chibi aprovados; congela geometria unica do menu para E6, E5 e E8 sem retrabalho de coordenadas;
  garante continuidade musical entre partidas e feedback imediato do slider `Music` na pausa; formaliza plano B
  (`AudioStreamSynchronized`) contra riscos de Web/WASM.
- **Negativas / trade-offs:** o escopo visual completo (13 poses por cor em `64x64`, 4 biomas com parallax) pesa no
  acabamento manual das entregas seguintes; o dono aceitou esse custo. A evolucao para `360x640` exige uma entrega dedicada de migracao de codigo, fisica,
  camera e UI antes da integracao dos sprites finais; a remodelagem completa do menu exige atualizar os testes GUT de
  `Rect2` (`test/test_stage_hud.gd`, `test/test_stage_faixa_placar.gd`, `test/test_modo_botao.gd`,
  `test/test_opcoes_botao.gd`), `test/test_ui_tamanhos.gd` (`TAMANHOS_UI = [32, 64]` ou `[16, 32, 64]`) e os roteiros
  `test/smoke/*.smoke.json` que clicam coordenadas do menu; manter a musica atenuada na pausa exige cuidar
  explicitamente do silencio em segundo plano no mobile/web.
- **Riscos aceitos:** comportamento real de `AudioStreamInteractive` e do desbloqueio WebAudio em navegadores moveis
  depende de validacao no export Web da entrega de musica (mitigado pelo fallback `AudioStreamSynchronized` com a mesma
  interface).

## Alternativas consideradas

- **Manter `fonts/alterebro-pixel-font.ttf` (`CC BY-NC`) ate o E8:** rejeitada; ja bloqueia o proprio E7/E8 e exigiria
  refazer metricas de UI, `TutorialCard` e testes de fonte duas vezes.
- **Exibir botao `Remover anuncios` visivel desabilitado ja no E6/E7 (Opcao B):** rejeitada; deixaria um botao morto e
  confuso na publicacao gratuita do E7 no itch.io, sem ganho real frente a manter o espaco reservado vazio com o ativo
  pronto no kit UI (Opcao A).
- **Pausar totalmente a musica em `get_tree().paused == true` (Opcao B):** rejeitada; o jogador nao ouviria o resultado
  ao arrastar o slider `Music` em Pausa -> Opcoes, exigindo retomada ou som sintetico de preview separado.
- **Hospedar o `AudioStreamPlayer` de musica em `Stage.tscn`:** rejeitada; `change_scene_to_file` reiniciaria a faixa
  do zero a cada derrota, saida pela pausa ou troca de modo envolvendo o Desafio diario.
- **Faixa unica em loop sem variacoes por estagio:** rejeitada; a trilha em 4 variacoes reforca a progressao dos 4
  biomas (`e0..e3`) com baixo custo adicional usando um unico recurso `AudioStreamInteractive` (ou stems sincronizados).
