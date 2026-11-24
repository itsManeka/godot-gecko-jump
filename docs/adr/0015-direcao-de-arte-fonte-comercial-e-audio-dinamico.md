# 0015 — Direcao de arte, fonte comercial livre, menu remodelado e audio dinamico

- **Status:** aceito
- **Data:** 2026-11-24
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

Os ADRs seguintes **permanecem aceitos** e nao sao superados por esta decisao — este ADR os complementa e preserva
integralmente suas garantias:

- [ADR 0002](0002-tela-mobile-largura-180.md) (`aceito`): largura logica de `180 px`, altura expandida, pixel quadrado,
  filtro `Nearest` e escala inteira (`TAMANHOS_UI = [16, 32]`).
- [ADR 0004](0004-arte-no-aseprite-com-rascunho-por-ia.md) (`aceito`): arte produzida no Aseprite local com fontes
  editaveis isoladas em `assets/src/` (fora do `.pck` via `assets/src/.gdignore`).
- [ADR 0006](0006-oraculo-de-jogo-em-3-camadas.md) (`aceito`): oraculo em 3 camadas mantido; alteracoes de layout de
  menu atualizam explicitamente os testes GUT de `Rect2` e roteiros `test/smoke/*.smoke.json`.
- [ADR 0008](0008-pausa-por-tree-paused.md) (`aceito`): pausa governada por `get_tree().paused`, com
  `PROCESS_MODE_ALWAYS` restrito ao que precisa operar pausado (overlay, opcoes, sons de UI e player de musica
  atenuado).
- [ADR 0014](0014-power-ups-e-modos-de-jogo.md) (`aceito`): 3 power-ups e 5 modos de jogo mantidos; icones `16x16`,
  ilustracoes `64x64` e cues sonoros respeitam todas as regras de cada modo (incluindo `Zen` sem derrota e sem nevoa).

## Decisao

### 1. Direcao de arte, acessibilidade `#41` e 4 biomas

- Adotar estetica pixel art **16-bit/GBC vibrante** com paleta coesa de **32 cores** ancorada nos 4 matizes de
  `scripts/Enums.gd` (`#f6db61`, `#79cf5a`, `#5987e9`, `#ec4848`) e contraste **WCAG AA >= 4.5:1** em todos os pares de
  texto/UI.
- Implementar acessibilidade sem cor (issue #41) em quatro frentes sincronizadas e distinguiveis em escala de cinza a
  `180 px`: 4 texturas/silhuetas de plataforma em 9-slice horizontal (`60/56/50/44 px`, preservando pontas no lugar de
  recorte `region_rect`), 4 detalhes anatomicos no gecko (`32x32`), 4 formatos de particulas de `color_change` e
  mini-sprites rotulados no `TutorialCard`.
- Organizar o cenario em **4 biomas (`e0..e3`)** com parallax modular vertical de baixa saturacao/contraste, particulas
  ambientais e **nevoa reativa na base** (oculta no modo `Zen` e sob `Global.sem_derrota`).

### 2. Troca comercial da fonte (`alterebro-pixel-font.ttf` -> `m5x7`)

- Substituir `fonts/alterebro-pixel-font.ttf` (**CC BY-NC**, bloqueada para uso comercial) por **`m5x7`** (Daniel
  Linssen, **CC0 1.0**, tamanho nativo `16 px`, proporcao 5x7), preservando integralmente
  [ADR 0002](0002-tela-mobile-largura-180.md), `UiHelpers.FONTE_NATIVO = 16`, `TAMANHOS_UI = [16, 32]`
  (`test/test_ui_tamanhos.gd`) e import sem antialiasing/hinting/subpixel (`antialiasing = 0`, `hinting = 0`,
  `subpixel_positioning = 0`, `oversampling = 1.0`).
- Em caso de divergencia metrica na importacao real, adotar as alternativas comerciais pre-qualificadas em ordem:
  `m3x6` (**CC0 1.0**, nativo `16 px`) ou `Tiny5` / `Silkscreen` (**SIL OFL 1.1**, nativo `8 px`, multiplos inteiros
  exatos em `16 px` e `32 px`).

### 3. Remodelagem do menu e estado dos slots reservados (E5 e E8)

- Remodelar o menu como um **bloco unificado centrado (`H_BLOCO = 278 px`)** dentro da `safe_area` para `180x320` e
  `180x400+`, conforme a tabela de coordenadas exatas de `docs/planejamento-design/direcao-de-arte.md` (secao 5.3):
  Logo `"GECKO JUMP"`, `Play` (normal `124x36` e estendido `148x36` para `"Ja jogado hoje"`), `Modo: <nome>` (`148x26`),
  `CardPlacar` (`Last`/`Best`, `164x42`), `Opcoes` (`132x26`), slot `Ranking` (E5, `132x26`) e slot `Remover anuncios`
  (E8, `148x26`), todos mutuamente disjuntos, com folga >= `2 px` e alvos >= `24x24`.
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

- **Positivas:** elimina risco juridico antes das entregas comerciais E7/E8; congela geometria unica do menu para E6,
  E5 e E8 sem retrabalho de coordenadas; garante continuidade musical entre partidas e feedback imediato do slider
  `Music` na pausa; formaliza plano B (`AudioStreamSynchronized`) contra riscos de Web/WASM.
- **Negativas / trade-offs:** a remodelagem completa do menu exige atualizar os testes GUT de `Rect2`
  (`test/test_stage_hud.gd`, `test/test_stage_faixa_placar.gd`, `test/test_modo_botao.gd`, `test/test_opcoes_botao.gd`),
  `test/test_ui_tamanhos.gd` e os roteiros `test/smoke/*.smoke.json` que clicam coordenadas do menu; manter a musica
  atenuada na pausa exige cuidar explicitamente do silencio em segundo plano no mobile/web.
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
