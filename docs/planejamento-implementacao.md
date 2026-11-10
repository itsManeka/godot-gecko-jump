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
3. **Tudo verificavel pela linha de comando** (Godot headless), com o dono jogando como gate de "pronto"
   ([ADR 0005](adr/0005-desenvolvimento-headless-e-mcp-isolado.md)).
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
| 4. Gameplay e mobile | Tela mobile, controles de toque, dificuldade progressiva, pausa/opcoes/tutorial | #15, #11, #10, #12 | epic 2 |
| 5. Conteudo | Power-ups, modos de jogo | #16, #17 | epic 3 |
| 6. Arte e audio | Arte final em pixel art, sons e musica | #18, #13 | epic 3 ou 4 |
| 7. Publicacao | Web no itch.io; build Android | #19, #20 | ultimo epic |

A divisao dos epics 2+ e proposta; confirmar com o dono ao abrir cada um. Todo epic termina com uma feature de QA
em que o dono joga (Godot e export web; Android quando existir).

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

## Regras de trabalho

- **Achado vira issue**: todo problema encontrado (bug, aviso, lacuna de teste) e cadastrado no GitHub com sintoma,
  causa (se conhecida) e criterio de aceite, mesmo fora do escopo da tarefa. `gh issue list` antes, para nao duplicar.
- Branch a partir de `main`, PR para `main`, merge pelo dono. Commits pequenos (conventional commits).
- Guardar o original de um sprite antes de substitui-lo (`assets/src/_orig/`).
- Validar pela CLI (`.verify.mjs`) e, quando houver mudanca jogavel, pedir ao dono para jogar.

## Baseline (2026-11-08, Godot 3.6.3)

A 1a partida funciona do inicio ao fim. Problemas conhecidos estao nas issues #3 a #6 (colisao por cor quebra apos
reiniciar, vazamento ao fechar, aviso de import, cor inicial). O `.verify.mjs` roda sem input e nao exercita o
pouso; a cobertura de gameplay vem com os testes GUT (#7).
