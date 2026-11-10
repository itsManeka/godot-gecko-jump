# Gecko Jump

Plataforma vertical infinita, tela retrato 180 px de largura com altura expandida (minimo 320, ADR 0002). O gecko so pisa nas plataformas da cor dele (4 cores); a cada
pouso troca de cor e ganha 1 ponto. Prototipo da game jam #1JAM Chroma rumo a versao final (web/itch.io + Android).

## Contexto obrigatorio

Antes de tocar codigo: [`docs/planejamento-implementacao.md`](../docs/planejamento-implementacao.md) (roadmap, epic
atual, regras de trabalho) e [`docs/adr/`](../docs/adr/README.md). Backlog e bugs conhecidos: issues do GitHub.
Todo problema encontrado vira issue (sintoma, causa, criterio de aceite).

## Stack

- **Godot 4.7.2** (`config_version=5`, `CharacterBody2D`). GDScript 4 (`@onready`, `@export`, tipagem).
- GDScript. Autoload `Global` (`scripts/Global.gd`). Addon GUT v9.7.1 vendorizado em `addons/gut/` (plugin habilitado no `project.godot`).
- Executavel fora do PATH: `workspace-config.json` → `ecosystems.game-gecko.tools` (dev-workspace) ou env
  `GODOT_PATH`.
- CI: `.github/workflows/ci.yml` (jobs `verify`, `export-web` e agregador `CI`); Godot 4.7.2 vem da action `.github/actions/setup-godot` (trocar versao = atualizar la `GODOT_VERSION` e as duas somas SHA-512; o resto deriva delas).

## Comandos

| Acao | Comando |
|---|---|
| Importar | `<godot> --headless --path . --import` |
| Rodar sem janela | `<godot> --headless --path . --quit-after <frames>` |
| Jogar (janela) | `<godot> --path .` |
| Oraculo completo (import, compile, GUT, run de 10 s) | `node .verify.mjs <wave>` |
| So os testes GUT | `<godot> --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://test -gexit` (le o `.gutconfig.json`, cujo `pre_run_script` isola o recorde real; outro `-gconfig` sem ele grava no `user://best_score.cfg` de quem joga) |
| Export web | `<godot> --headless --path . --export-release "Web" export/web/index.html` (sem threads; servir `export/web/` por servidor estatico, nao `file://`) |

## Estrutura

```
scenes/    Stage (fluxo, pontuacao), Player, Platform, RunningPlatforms (gerador),
           ScrollLevel (scroll 20 px/s)
scripts/   Global.gd (autoload: plataformas, estado), Enums.gd (cores, tipos de plataforma, COR_INICIAL),
           ScoreKeeper.gd (pontuacao e recorde, sem I/O), BestScoreStore.gd (recorde salvo em user://),
           PlatformTypePicker.gd (tipo do gerador, sem cena),
           StaticPlatformColors.gd (cores das estaticas iniciais, sem cena),
           InitialRows.gd (ys das linhas iniciais pela altura visivel, sem cena),
           MovingRowFill.gd (x pre-colocados das linhas moveis a partir do ponto de nascimento, sem cena),
           ReachableColors.gd (cor do gecko alcancavel no pouso e nas plataformas moveis, sem cena)
test/      testes GUT (`test_*.gd`, `extends GutTest`); `test_landing_restart.gd` regressao do pouso/reinicio (issue #3), sem skip
test/smoke/ roteiro `gecko.smoke.json` do game-smoke (export web): mudou input, fluxo de inicio/derrota ou tempos? ajuste-o
addons/    GUT v9.7.1 (vendorizado; nao editar)
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
