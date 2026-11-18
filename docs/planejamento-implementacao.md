# Plano de Implementacao — Gecko Jump

> **Fonte de verdade** do projeto. Chats limpos (`/feature`, `/epic` em contexto zerado) leem este arquivo antes de
> tocar codigo. Briefing original: [`planejamento-design/briefing-original.md`](planejamento-design/briefing-original.md).
> Design provisorio das telas de pausa, opcoes, tutorial e dica de toque:
> [`planejamento-design/handoff-telas-novas.md`](planejamento-design/handoff-telas-novas.md).
> Decisoes com justificativa: [`adr/`](adr/README.md). Backlog: issues do GitHub (`gh issue list -R itsManeka/godot-gecko-jump`).

## Contexto

Gecko Jump e uma plataforma vertical infinita: o gecko so pisa nas plataformas da cor dele (4 cores); a cada pouso
troca de cor e ganha 1 ponto. Nasceu na game jam #1JAM Chroma em Godot 3 (~460 linhas de GDScript). Objetivo:
**jogo completo para celular (Android) e web (itch.io)**, web publicado primeiro.

Restricoes que guiam as decisoes:

1. **Celular primeiro.** Tela retrato, um polegar, sessao curta ([ADR 0002](adr/0002-tela-mobile-largura-180.md),
   [ADR 0003](adr/0003-controle-de-um-polegar.md)).
2. **Pixel art de verdade.** Pixel quadrado em qualquer tela; arte final feita no Aseprite ([ADR 0004](adr/0004-arte-no-aseprite-com-rascunho-por-ia.md)).
3. **Tudo verificavel pela linha de comando** (Godot headless,
   [ADR 0005](adr/0005-desenvolvimento-headless-e-mcp-isolado.md)), com o gate de "pronto" em 3 camadas
   ([ADR 0006](adr/0006-oraculo-de-jogo-em-3-camadas.md)): testes GUT; smoke do export web + bot nativo; o dono joga
   so sensacao, dificuldade, legibilidade, audio e toque.
4. **Escopo final:** mecanica de cores + power-ups + modos de jogo. Mudar mecanica e rebalancear e permitido em
   features proprias.

## Ambiente

| Item                    | Onde                                                                                                                              |
| ----------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| Godot 4.7.2 (alvo)      | `D:/Dev/.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe` + templates em `%APPDATA%/Godot/export_templates/4.7.2.stable/` |
| Aseprite (fork pessoal) | `dev-workspace/ecossistemas/ferramentas/aseprite/build/bin/aseprite.exe`                                                          |
| Android SDK / JDK       | `D:/android/Sdk`; JDK 21 (Liberica) instalado — conferir a versao exigida pelo Godot 4.7 no build Android                         |
| Oraculo do repo         | `node .verify.mjs <wave>`                                                                                                         |

No dev-workspace, os caminhos ficam em `workspace-config.json` → `ecosystems.game-gecko.tools`; fora dele, use a
env `GODOT_PATH`.

## Roadmap

| Fase                | Conteudo                                                                                         | Issues                 | Estado                         |
| ------------------- | ------------------------------------------------------------------------------------------------ | ---------------------- | ------------------------------ |
| 1. Preparacao       | `.gitignore`, oraculo headless, CLAUDE.md, baseline jogado                                       | PR #2                  | concluida (2026-11-08)         |
| 2. Migracao Godot 4 | Projeto, cenas e scripts no 4.7; export web pela CLI; rename do gerador                          | #8, #14                | epic 1, concluida (2026-11-09) |
| 3. Base solida      | Testes GUT; bugs da lista de plataformas, vazamento, aviso de import, cor inicial; recorde salvo | #7, #3, #4, #5, #6, #9 | epic 1, concluida (2026-11-09) |

Divisao em epics (as fases 1 a 3 acima formam o E1):

| Epic                                                | Conteudo                                                                                                                     | Issues                                               | Estado                              |
| --------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------- | ----------------------------------- |
| E1. Migracao e base solida                          | Migracao para Godot 4.7, oraculo headless, testes GUT, bugs da jam, recorde salvo (fases 1 a 3)                              | #8, #14, #7, #3, #4, #5, #6, #9                      | concluido (2026-11-09)              |
| E2. CI, tela mobile e jogabilidade da base          | CI, roteiros de smoke, tela 180 px, borda lateral, linhas moveis, cor alcancavel                                             | #28, #26, #15, #25, #24, #23 (+ #38, achada no epic) | QA concluido em 2026-11-11 (PR #31) |
| E3. Controles, dificuldade e pausa/opcoes/tutorial  | Primeiro as issues herdadas do E2; depois toque, dificuldade, pausa, opcoes, tutorial e camera que acompanha o gecko no alto | #36, #37, #39, #40, #42, #11, #10, #12, #47, #46     | toque fixado; aguardando playtest   |
| E4. Conteudo                                        | Power-ups, modos de jogo, gerador com seed                                                                                   | #16, #17                                             | planejado                           |
| E5. Ranking online por modo                         | Ranking por modo de jogo; depende do E4 e do ChumGames E1                                                                    | #29                                                  | planejado                           |
| E6. Arte final e audio                              | Arte final em pixel art, sons e musica                                                                                       | #18, #13                                             | planejado                           |
| E7. Publicacao                                      | Web no itch.io; build Android                                                                                                | #19, #20                                             | planejado                           |
| E8. Monetizacao e Play Store                        | Anuncios, remocao paga e publicacao na Play Store                                                                            | #30                                                  | planejado                           |
| ChumGames E1 (ecossistema proprio, fora deste repo) | Backend Firebase compartilhado de ranking + addon Godot; pre-requisito do E5                                                 | —                                                    | planejado                           |

Herdadas do E2 no E3: #36 (EOL dos `.import`), #37 (enum `MOVE_TO_LEFT`/`MOVE_TO_RIGHT` invertido) e #39 (smoke
intermitente por sorteio da partida).

Ordem: E3 → E4 → E5 → E6 → E7 → E8 (cada um depende do anterior). Todo epic termina com uma feature de QA em que o
dono joga o que a maquina nao julga (Godot e export web; Android quando existir).

Dificuldade: uma curva unica em `ressources/curva_dificuldade.tres` (estagios com interpolacao, avaliados por pontos e tempo de partida) controla scroll, velocidade das plataformas moveis, o K da garantia de cor (`DifficultyStage.k`: quao rara fica a garantia da cor do gecko nas moveis; K maior = mais dificil, K = 1 = facil demais) e a proporcao de plataformas estaticas. Valores e decisao em [ADR 0007](adr/0007-curva-de-dificuldade-em-resource.md).

## Epic 1 — Migracao e base solida

Escopo: fases 2 e 3. **A mecanica fica igual a original** (velocidade e scroll fixos, regra de cor; a dificuldade progressiva entrou no E3).

**Estado: concluido em 2026-11-09.** O dono jogou 3 partidas seguidas no Godot 4.7.2 e no export web, sem erro no
console nem vazamento ao fechar, com o recorde mantido entre sessoes. O QA achou e corrigiu as plataformas moveis que
saiam uma por linha (#22). Problemas de jogabilidade herdados da jam ficaram como issues para os proximos epics: #23
(linha sem plataforma da cor do gecko), #24 (linha movel comeca vazia) e #25 (gecko sai pela lateral).

1. Migracao 3.6 → 4.7 (#8): `KinematicBody2D`→`CharacterBody2D`, `onready`/`export`→`@onready`/`@export`,
   `change_scene`→`change_scene_to_file`, preset `HTML5`→`Web` sem threads, GDScript tipado. Atualizar o README
   (versao do Godot, como rodar).
2. Rename `RuningPlatforms` → `RunningPlatforms` (#14), com `--import` depois de mover.
3. Testes GUT headless chamados pelo `.verify.mjs` (#7); um teste de pouso → reinicio → pouso que falha com o #3.
4. Bugs #3, #4, #5, #6. Criterio: zero `SCRIPT ERROR`/`ERROR:` em 3 partidas seguidas e ao fechar.
5. Recorde em `user://` (#9), inclusive no export web.
6. QA: `.verify.mjs` + GUT + o dono joga 3 partidas seguidas no Godot 4 e no export web.

## Epic 2 — CI, tela mobile e jogabilidade da base

Escopo: CI, tela mobile e os problemas de jogabilidade herdados da jam (#23, #24, #25). Controles de toque,
dificuldade e pausa/opcoes/tutorial ficaram para o E3.

**Estado: QA concluido em 2026-11-11** (PR #31). Camada 1 (GUT, 173 testes) e camada 2 (smoke
dos 7 roteiros + bot nativo contra a `main`) verdes. O dono jogou 4 partidas no Godot (3 na janela padrao, 1 em
1280x720) e 3 no export web em retrato emulado (720x1280, 1080x2400, 1170x2532), sem erro no console nem `leaked at
exit`. Observacoes do dono: com a garantia de cor o jogo ficou bem mais facil (entra na curva de dificuldade, #10 no
E3); em 1170x2532 sobram barras nos quatro lados pela escala inteira, aceitavel. Pendente para o E3: conferir a costura
lateral com toque no aparelho (o jogo ainda nao le toque, #11).

1. CI (#28): workflow com `verify`, `export-web` e agregador `CI`; Godot fixado por action local.
2. Roteiros de smoke (#26): 7 roteiros em `test/smoke/`, jogados no export web.
3. Tela de 180 px de largura com `keep_width` + escala inteira e HUD na safe area (#15,
   [ADR 0002](adr/0002-tela-mobile-largura-180.md)).
4. Gerador de plataformas cobre a altura visivel (#15).
5. Borda lateral com wrap (#25).
6. Linhas moveis preenchidas desde o inicio (#24).
7. Cor alcancavel em toda janela de K plataformas moveis (#23); a #38, achada no QA, foi corrigida no epic.
8. Janela larga com a coluna de 180 centralizada e barras laterais.
9. Gate em 3 camadas ([ADR 0006](adr/0006-oraculo-de-jogo-em-3-camadas.md)).

## Epic 3 — Controles, dificuldade e pausa/opcoes/tutorial

Escopo: as issues herdadas do E2 (#36, #37, #39, #40, #42), toque (#11) e modos de toque alternaveis (#47), dificuldade (#10) e pausa, opcoes e tutorial (#12).

**Estado: aguardando playtest do dono (QA final); padrao de toque B fixado no playtest de 2026-11-17** (branch
`epic/gecko-e3-controles-e-progressao`). A camada automatica esta verde no HEAD: o oraculo do repo (`.verify.mjs final`:
import, compile, GUT com 919 testes, run) passa; os 30 roteiros de smoke passam no export web de debug, incluindo os de
toque por modo (A e B); no game-bot nativo do HEAD contra a `main`, os 8 roteiros comparados passam, e as divergencias
sao a UI nova do epic (pausa, opcoes, tutorial, dica de toque, estagios). O toque por modo foi provado por GUT
(deterministico) e pelos roteiros de smoke no export web de debug. Ficam para o playtest do dono a sensacao no aparelho,
a legibilidade e o toque no aparelho. As
issues #36, #37, #39, #40, #42 e #46 estao resolvidas no epic; o que falta da #11, #10 e #12 (toque no aparelho, calibracao
da curva, pausa por foco) e a sensacao do limite da camera (#46) a maquina nao julga e fica para o playtest do dono.

1. Dificuldade progressiva (#10, [ADR 0007](adr/0007-curva-de-dificuldade-em-resource.md)): a curva em
   `ressources/curva_dificuldade.tres` troca os literais de scroll, velocidade das moveis, K da garantia de cor e
   proporcao de estaticas por estagios com interpolacao, avaliados por pontos e tempo da partida (plato em cerca de 3
   min). Sem texto de nivel: so o aviso visual de subida (item 6). Calibracao fina pelo playtest do dono (pendente).
2. Pausa (#12, [ADR 0008](adr/0008-pausa-por-tree-paused.md)): acao `pause` (Esc, P, start do controle), botao de
   toque no canto superior esquerdo, pausa automatica ao perder o foco e overlay Continuar/Opcoes, por
   `get_tree().paused`. Pausa por foco no web e no Android: verificacao manual no playtest do dono.
3. Opcoes (#12): buses `Music` e `SFX` (os sons do jogo vao para `SFX`; `Music` sem faixa ate o E6), volumes salvos em
   `user://options.cfg` (mesma escrita atomica do recorde) e aplicados no boot e ao mudar. Tela de Opcoes (sliders
   Music/SFX e Voltar) aberta pelo botao Opcoes do menu inicial e pelo overlay de pausa; o arrasto aplica o volume na hora
   e grava ao soltar. Persistencia apos recarga no web: provada pelo smoke do QA do epic; nivel audivel no aparelho:
   verificacao manual no playtest do dono.
4. Tutorial da 1a partida (#12): card com os controles (variante de toque ou de teclado, pela mesma conta da dica)
   aberto na 1a partida, que fecha no 1o pouso ou em Pular, com fade de 0.3 s; a flag `tutorial/visto` em
   `user://options.cfg` so grava ao concluir ou pular (derrota antes do 1o pouso reabre o card). O item "Ver tutorial"
   de Opcoes reabre o card em modo modal, sobre o fundo da pausa, sem mudar a flag. Os smokes forcam o tutorial como visto
   por `?tutorial=visto` (so em build debug); `tutorial.smoke.json` joga a 1a partida com `user://` limpo.
5. Plataformas que piscam ([ADR 0012](adr/0012-plataformas-que-piscam.md)): mecanica da curva que faz parte das
   plataformas somirem (sem colisao) e voltarem em ritmo fixo, no ultimo estagio. Aviso visivel antes de sumir, nao
   cromatico; gecko em cima segura o ciclo; fora da linha inicial e exclusiva da cicladora. Calibracao de ritmo e
   legibilidade fica para o playtest do dono.
6. Aviso de subida de estagio (#10): vinheta branca nas 4 bordas da safe area (alpha de pico na borda, decaindo para o
   miolo transparente) que pulsa N vezes (N = estagio novo) nas 3 subidas, sem texto. Sinal `estagio_mudou` do
   `DifficultyState`; a ponte publica `dificuldade.aviso` para os smokes. O som do aviso fica para a #43. O visual da
   moldura original foi redesenhado para vinheta (fecha #45). Sensacao e legibilidade sobre fundo claro: verificacao manual no playtest do dono.
7. Modos de toque alternaveis (#47, [ADR 0013](adr/0013-modos-de-toque-alternaveis.md)): dois esquemas selecionaveis
   nas Opcoes — A (arrastar + flick, um polegar) e B (dois polegares, zonas invisiveis, padrao do playtest) — com pulo
   reto, correcao de direcao no ar e comeco a andar no press. O esquema C prototipado foi descartado no playtest e
   podado do codigo, dos testes e dos textos; save antigo com ele cai no B. O modo A tem sensibilidade ajustavel nas Opcoes
   (um controle que escala a zona morta e o dy do flick; o padrao reproduz 6 px / 24 px; faixa 0,5x a 2x provisoria) e o
   flick nao repula no arrasto vertical longo nem falha com FPS baixo (#48). Valores de sensacao em um simbolo cada
   (`scripts/TouchTuning.gd`). Os roteiros de smoke por modo (`toque-modo-{a,b}.smoke.json`) provam direcao, diagonal e
   flick por `player.x/y`.
8. Legibilidade das fontes da UI (#42): a fonte pixel tem tamanho nativo de 16 px
   ([nota de medicao](fonte-pixel-tamanho-nativo.md)); toda a UI usa so multiplos inteiros dele (`UiHelpers`: titulo,
   placar e Play em 32; texto, botoes de menu e dica em 16), com o import sem hinting nem subpixel, para as hastes sairem
   com espessura uniforme. Texto sobre as plataformas (placar Last/Best e dica de toque) ganha uma faixa de fundo
   translucida, na mesma cor do fundo da pausa (contraste acima de 4,5:1 sobre a plataforma amarela). Legibilidade no
   aparelho: verificacao manual no playtest do dono.
9. Camera que acompanha o gecko no alto (#46): quando o gecko sobe acima do limite de topo (0,40 da altura visivel,
   `scripts/CameraFollow.gd`), o mundo avanca o excesso no mesmo frame (plataformas, gatilho de linhas novas e gecko
   deslocados juntos), entao ele nunca sai pelo topo; o scroll da curva de dificuldade segue como piso (nunca diminui) e,
   sem partida iniciada (menu), nada se move. Sem roteiro de smoke: nenhum roteiro com seed fixa leva o gecko ao limite
   de forma deterministica (#48); cobertura por GUT e a sensacao do limite pelo playtest do dono.

## Regras de trabalho

- **Achado vira issue**: todo problema encontrado (bug, aviso, lacuna de teste) e cadastrado no GitHub com sintoma,
  causa (se conhecida) e criterio de aceite, mesmo fora do escopo da tarefa. `gh issue list` antes, para nao duplicar.
- Branch a partir de `main`, PR para `main`, merge pelo dono. Commits pequenos (conventional commits).
- Guardar o original de um sprite antes de substitui-lo (`assets/src/_orig/`).
- Gate de "pronto" em 3 camadas ([ADR 0006](adr/0006-oraculo-de-jogo-em-3-camadas.md)): GUT (`.verify.mjs`); smoke do
  export web + bot nativo; o dono joga so sensacao, dificuldade, legibilidade, audio e toque, com a camada 2 verde.

## Baseline (2026-11-08, Godot 3.6.3)

A 1a partida funciona do inicio ao fim. Problemas conhecidos estao nas issues #3 a #6 (colisao por cor quebra apos
reiniciar, vazamento ao fechar, aviso de import, cor inicial). O `.verify.mjs` roda sem input e nao exercita o
pouso; a cobertura de gameplay vem com os testes GUT (#7).
