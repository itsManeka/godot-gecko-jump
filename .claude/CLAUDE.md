# Gecko Jump

Plataforma vertical infinita, tela retrato 180×320. O gecko so pisa nas plataformas da cor dele (4 cores); a cada
pouso troca de cor e ganha 1 ponto. Prototipo da game jam #1JAM Chroma rumo a versao final (web/itch.io + Android).

## Stack

- **Hoje: Godot 3.6.3** (`config_version=4`, `KinematicBody2D`, `.import/`). Migracao para **Godot 4.7.2** e a
  proxima fase; ate la, nada de sintaxe do 4 nos scripts.
- GDScript, ~460 linhas em 7 scripts. Autoload `Global` (`scripts/Global.gd`). Sem addons.
- Executaveis fora do PATH: `workspace-config.json` → `ecosystems.game-gecko.tools` (dev-workspace) ou env
  `GODOT_PATH` (4) / `GODOT3_PATH` (3).

## Comandos

| Acao | Godot 3 (atual) | Godot 4 (pos-migracao) |
|---|---|---|
| Importar | `<godot3> --no-window --path . -e --quit` | `<godot> --headless --path . --import` |
| Rodar sem janela | `<godot3> --no-window --path . --fixed-fps 60` (parar por timeout) | `<godot> --headless --path . --quit-after <frames>` |
| Jogar (janela) | `<godot3> --path .` | `<godot> --path .` |
| Oraculo completo | `node .verify.mjs <wave>` | idem (detecta a versao pelo `config_version`) |
| Export web | — (sem templates do 3 instalados; export so pos-migracao) | `<godot> --headless --path . --export-release "Web" export/web/index.html` |

O editor do Godot 3 reescreve `project.godot` ao importar (so reserializa); descarte com `git checkout -- project.godot`
se nao houve mudanca intencional. O `.verify.mjs` ja faz isso.

## Estrutura

```
scenes/    Stage (fluxo, pontuacao), Player, Platform, RuningPlatforms (gerador; nome com erro, renomear na fase 3),
           ScrollLevel (scroll 20 px/s)
scripts/   Global.gd (autoload: plataformas, estado, recorde), Enums.gd (cores e tipos de plataforma)
assets/    Gecko.png 64×96, GeckoPlataforma.png 64×16 (cor via modulate); fonts/, sounds/ (jump, lose)
export/    saida de build (ignorada)
```

## Convencoes

- Stack doc do workspace: `.claude/dev-stacks/godot.md` (convencoes GDScript 4, migracao 3→4, armadilhas de export).
- Cena e script com o mesmo nome em PascalCase; funcoes/variaveis em `snake_case`; constantes em `UPPER_CASE`.
- Comunicacao entre cenas por sinais; estado global so no autoload.
- Recorde e configuracoes em `user://`, nunca em `res://`.
- Paleta: `#f6db61`, `#79cf5a`, `#5987e9`, `#ec4848` (`scripts/Enums.gd`).
- Assets: copiar o original para `assets/src/_orig/` antes de substituir.

## Baseline (Fase 1, 2026-11-08)

- Godot 3.6.3: importa e roda 10 s sem erro de script. Unico aviso conhecido no import:
  `Another resource is loaded from path 'res://assets/Gecko.png' (possible cyclic resource inclusion)`.
- Pontos fracos conhecidos (fases seguintes): recorde nao persiste, dificuldade constante, so teclado, sem pausa/
  opcoes/tutorial, lista `platforms` do `Global` pode guardar plataformas liberadas, cor inicial nao garantida.

## Git

Trunk: branch a partir de `main`, PR para `main`, merge pelo dono. Commits pequenos (conventional commits).

## Indice

(sem indice)

Agentes e memorias sao globais do workspace.
