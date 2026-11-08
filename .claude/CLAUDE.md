# Gecko Jump

Plataforma vertical infinita, tela retrato 180×320. O gecko so pisa nas plataformas da cor dele (4 cores); a cada
pouso troca de cor e ganha 1 ponto. Prototipo da game jam #1JAM Chroma rumo a versao final (web/itch.io + Android).

## Contexto obrigatorio

Antes de tocar codigo: [`docs/planejamento-implementacao.md`](../docs/planejamento-implementacao.md) (roadmap, epic
atual, regras de trabalho) e [`docs/adr/`](../docs/adr/README.md). Backlog e bugs conhecidos: issues do GitHub.
Todo problema encontrado vira issue (sintoma, causa, criterio de aceite).

## Stack

- **Godot 4.7.2** (`config_version=5`, `CharacterBody2D`). GDScript 4 (`@onready`, `@export`, tipagem).
- GDScript, ~460 linhas em 7 scripts. Autoload `Global` (`scripts/Global.gd`). Sem addons.
- Executavel fora do PATH: `workspace-config.json` → `ecosystems.game-gecko.tools` (dev-workspace) ou env
  `GODOT_PATH`.

## Comandos

| Acao | Comando |
|---|---|
| Importar | `<godot> --headless --path . --import` |
| Rodar sem janela | `<godot> --headless --path . --quit-after <frames>` |
| Jogar (janela) | `<godot> --path .` |
| Oraculo completo | `node .verify.mjs <wave>` |
| Export web | `<godot> --headless --path . --export-release "Web" export/web/index.html` (sem threads; servir `export/web/` por servidor estatico, nao `file://`) |

## Estrutura

```
scenes/    Stage (fluxo, pontuacao), Player, Platform, RuningPlatforms (gerador; nome com erro, renomear na fase 3),
           ScrollLevel (scroll 20 px/s)
scripts/   Global.gd (autoload: plataformas, estado, recorde), Enums.gd (cores e tipos de plataforma)
assets/    Gecko.png 64×96, GeckoPlataforma.png 64×16 (cor via modulate); fonts/, sounds/ (jump, lose)
export/    saida de build (ignorada; so o .gdignore e versionado, para o Godot nao importar o build)
```

## Convencoes

- Stack doc do workspace: `.claude/dev-stacks/godot.md` (convencoes GDScript 4, armadilhas de export).
- Cena e script com o mesmo nome em PascalCase; funcoes/variaveis em `snake_case`; constantes em `UPPER_CASE`.
- Comunicacao entre cenas por sinais; estado global so no autoload.
- Recorde e configuracoes em `user://`, nunca em `res://`.
- Paleta: `#f6db61`, `#79cf5a`, `#5987e9`, `#ec4848` (`scripts/Enums.gd`).
- Assets: copiar o original para `assets/src/_orig/` antes de substituir.

## Git

Trunk: branch a partir de `main`, PR para `main`, merge pelo dono. Commits pequenos (conventional commits).

## Indice

(sem indice)

Agentes e memorias sao globais do workspace.
