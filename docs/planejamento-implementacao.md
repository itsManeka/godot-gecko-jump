# Plano de Implementacao — Gecko Jump

> **Fonte de verdade** do projeto. Chats limpos (`/feature`, `/epic` em contexto zerado) leem este arquivo antes de
> tocar codigo. Briefing original: [`planejamento-design/briefing-original.md`](planejamento-design/briefing-original.md).
> Decisoes com justificativa: [`adr/`](adr/README.md). Backlog: issues do GitHub (`gh issue list -R itsManeka/godot-gecko-jump`).

## Contexto

Gecko Jump e uma plataforma vertical infinita: o gecko so pisa nas plataformas da cor dele (4 cores); a cada pouso
troca de cor e ganha 1 ponto. Nasceu na game jam #1JAM Chroma em Godot 3 (~460 linhas de GDScript). Objetivo:
**jogo completo para celular (Android) e web (itch.io)**, web publicado primeiro.

Restricoes que guiam as decisoes:

1. **Celular primeiro.** Tela retrato, um polegar, sessao curta ([ADR 0002](adr/0002-tela-mobile-largura-180.md),
   [ADR 0003](adr/0003-controle-de-um-polegar.md)).
2. **Pixel art de verdade.** Pixel quadrado em qualquer tela; arte final feita no Aseprite ([ADR 0004](adr/0004-arte-no-aseprite-com-rascunho-por-ia.md)).
3. **Tudo verificavel pela linha de comando** (Godot headless, [ADR 0005](adr/0005-desenvolvimento-headless-e-mcp-isolado.md)),
   com o gate de "pronto" em 3 camadas ([ADR 0006](adr/0006-oraculo-de-jogo-em-3-camadas.md)): testes GUT; smoke do
   export web + bot nativo; o dono joga so sensacao, dificuldade, legibilidade, audio e toque.
4. **Escopo final:** mecanica de cores + power-ups + modos de jogo. Mudar mecanica e rebalancear e permitido em
   features proprias.

## Ambiente

| Item | Onde |
|---|---|
| Godot 4.7.2 (alvo) | `D:/Dev/.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe` + templates em `%APPDATA%/Godot/export_templates/4.7.2.stable/` |
| Aseprite (fork pessoal) | `dev-workspace/ecossistemas/ferramentas/aseprite/build/bin/aseprite.exe` |
| Android SDK / JDK | `D:/android/Sdk`; JDK 21 (Liberica) instalado — conferir a versao exigida pelo Godot 4.7 no build Android |
| Oraculo do repo | `node .verify.mjs <wave>` |

No dev-workspace, os caminhos ficam em `workspace-config.json` → `ecosystems.game-gecko.tools`; fora dele, use a
env `GODOT_PATH`.

## Roadmap

| Fase | Conteudo | Issues | Estado |
|---|---|---|---|
| 1. Preparacao | `.gitignore`, oraculo headless, CLAUDE.md, baseline jogado | PR #2 | concluida (2026-11-08) |
| 2. Migracao Godot 4 | Projeto, cenas e scripts no 4.7; export web pela CLI; rename do gerador | #8, #14 | epic 1, concluida (2026-11-09) |
| 3. Base solida | Testes GUT; bugs da lista de plataformas, vazamento, aviso de import, cor inicial; recorde salvo | #7, #3, #4, #5, #6, #9 | epic 1, concluida (2026-11-09) |

Divisao em epics (as fases 1 a 3 acima formam o E1):

| Epic | Conteudo | Issues | Estado |
|---|---|---|---|
| E1. Migracao e base solida | Migracao para Godot 4.7, oraculo headless, testes GUT, bugs da jam, recorde salvo (fases 1 a 3) | #8, #14, #7, #3, #4, #5, #6, #9 | concluido (2026-11-09) |
| E2. CI, tela mobile e jogabilidade da base | CI, roteiros de smoke, tela 180 px, borda lateral, linhas moveis, cor alcancavel | #28, #26, #15, #25, #24, #23 (+ #38, achada e corrigida no epic) | QA concluido em 2026-11-11; PR #31 aguardando merge do dono |
| E3. Controles, dificuldade e pausa/opcoes/tutorial | Toque de um polegar, dificuldade progressiva, pausa, opcoes, tutorial; primeiro item: issues herdadas do E2 (#36 EOL dos `.import`, #37 enum `MOVE_TO_LEFT`/`MOVE_TO_RIGHT` invertido, #39 smoke intermitente por sorteio) | #11, #10, #12, #36, #37, #39 | proximo |
| E4. Conteudo | Power-ups, modos de jogo, gerador com seed | #16, #17 | planejado |
| E5. Ranking online por modo | Ranking por modo de jogo; depende do E4 e do ChumGames E1 | #29 | planejado |
| E6. Arte final e audio | Arte final em pixel art, sons e musica | #18, #13 | planejado |
| E7. Publicacao | Web no itch.io; build Android | #19, #20 | planejado |
| E8. Monetizacao e Play Store | Anuncios, remocao paga e publicacao na Play Store | #30 | planejado |
| ChumGames E1 (ecossistema proprio, fora deste repo) | Backend Firebase compartilhado de ranking + addon Godot; pre-requisito do E5 | — | planejado |

Ordem: E3 → E4 → E5 → E6 → E7 → E8 (cada um depende do anterior). Todo epic termina com uma feature de QA em que o
dono joga o que a maquina nao julga (Godot e export web; Android quando existir).

Dificuldade da cor: `ReachableColors.K` (default 3) e o botao que controla quao rara fica a garantia da cor do gecko nas plataformas moveis; K maior = mais dificil, K = 1 = facil demais.

## Epic 1 — Migracao e base solida

Escopo: fases 2 e 3. **A mecanica fica igual a original** (velocidade 60, scroll 20 px/s, regra de cor).

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

**Estado: QA concluido em 2026-11-11** (PR #31 aguardando merge do dono). Camada 1 (GUT, 173 testes) e camada 2 (smoke
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
7. Cor alcancavel com `ReachableColors.K` (#23); a #38, achada no QA, foi corrigida no epic.
8. Janela larga com a coluna de 180 centralizada e barras laterais.
9. Gate em 3 camadas ([ADR 0006](adr/0006-oraculo-de-jogo-em-3-camadas.md)).

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
