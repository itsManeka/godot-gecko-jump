# Gecko Jump

Plataforma vertical infinita, so retrato (tambem no desktop/itch.io): 180 px de largura com altura expandida (minimo 320, ADR 0002). O gecko so pisa nas plataformas da cor dele (4 cores); a cada
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

| Acao                                                 | Comando                                                                                                                                                                                                                       |
| ---------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Importar                                             | `<godot> --headless --path . --import`                                                                                                                                                                                        |
| Rodar sem janela                                     | `<godot> --headless --path . --quit-after <frames>`                                                                                                                                                                           |
| Jogar (janela)                                       | `<godot> --path .`                                                                                                                                                                                                            |
| Oraculo completo (import, compile, GUT, run de 10 s) | `node .verify.mjs <wave>`                                                                                                                                                                                                     |
| So os testes GUT                                     | `<godot> --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://test -gexit` (le o `.gutconfig.json`, cujo `pre_run_script` isola o recorde real; outro `-gconfig` sem ele grava no `user://best_score.cfg` de quem joga) |
| Export web                                           | `<godot> --headless --path . --export-release "Web" export/web/index.html` (sem threads; servir `export/web/` por servidor estatico, nao `file://`)                                                                           |

## Estrutura

```
scenes/    Stage (fluxo, pontuacao), Player, Platform, RunningPlatforms (gerador),
           ScrollLevel (scroll vindo da curva de dificuldade + avanco suavizado quando o gecko sobe acima do limite de topo), PowerUpHud (icone e barra de duracao do power-up ativo, desenho pela fonte unica PowerUpDesenho; so branco/preto, nunca cor de plataforma), TouchControls (toque -> acoes de input, esquemas A/B selecionaveis (nomes de apresentacao Flick e Joy invisivel), B padrao; ADR 0013), TouchHint (dica das zonas),
           PauseBotao / PauseOverlay (pausa por toque, clique e acao `pause`; ADR 0008), OpcoesBotao / OptionsScreen (volumes, modo de toque, sensibilidade do modo Flick (A) com ele ativo, Ver tutorial),
           TutorialCard (card da 1a partida e reabertura modal), LevelUpFrame (vinheta branca nas 4 bordas da safe area que pulsa N vezes na subida de estagio), ModoBotao / ModosScreen (botao `Modo: <rotulo>` acima do Play e tela de modos em carrossel; so com o jogo nao iniciado)
scripts/   Global.gd (autoload: plataformas, estado), Enums.gd (cores, tipos de plataforma, COR_INICIAL),
           ScoreKeeper.gd (pontuacao e recorde, sem I/O), BestScoreStore.gd (recorde por modo: `user://best_score_<id>.cfg`; Classico em `user://best_score.cfg`) / OptionsStore.gd (opcoes em user://; buses Music/SFX),
           PlatformTypePicker.gd (tipo do gerador, sem cena),
           StaticPlatformColors.gd (cores das estaticas iniciais, sem cena),
           RowSeed.gd (rng por linha da partida com seed: indice pelo y local e canais layout/cor_movel, sem cena; `ScrollLevel.semente`),
           InitialRows.gd (ys das linhas iniciais pela altura visivel, sem cena),
           MovingRowFill.gd (x pre-colocados das linhas moveis a partir do ponto de nascimento, sem cena),
           ReachableColors.gd (cor do gecko alcancavel no pouso e nas plataformas moveis, sem cena),
           PlayArea.gd (largura jogavel 180, fonte unica de wrap, fantasma, cor do pouso e gerador),
           TouchClassifier.gd (lado do toque para o esquema B, sem cena),
           TouchMode.gd (modos de toque A/B, nomes Flick e Joy invisivel: enum, padrao B e validacao do valor salvo, sem cena),
           TouchTuning.gd (valores de sensacao do toque — zona morta, flick, janela, rearme e sensibilidade do A — um simbolo cada),
           TouchScheme.gd / TouchSchemes.gd / TouchSchemeA/B.gd (contrato e esquemas de toque, sem cena; ADR 0013),
           DifficultyCurve.gd / DifficultyStage.gd (curva de dificuldade, sem cena; ADR 0007), PlatformModifier(s).gd + PlatformNarrower/PlatformCrumble/PlatformColorCycle.gd (mecanicas de plataforma, sem cena; ADR 0009/0010),
           DifficultyState.gd (progresso da partida: pontos e tempo, snapshot, sinal `estagio_mudou`, sem cena),
           PowerUp.gd / PowerUpState.gd (contrato do power-up com hooks virtuais de padrao neutro `ignora_cor()`/`fator_scroll()` e estado agregado de ativo/carga; sem cena; ADR 0014), PowerUps.gd (registro nome -> script; producao registra camaleao e desacelera, fakes so via `registrar`), PowerUpCamaleao.gd / PowerUpDesacelera.gd (power-ups reais: cor livre por 5 s e scroll x fator por 5 s, duracao e fator de `power_ups.tres`), PowerUpConfig.gd (`ressources/power_ups.tres`: duracoes e fator, fallback do ADR quando ausente/invalido), PowerUpDraw.gd (sorteio do tipo por `raridade_power_up` e `pesos_power_ups` da curva; rng dedicado), PowerUpDesenho.gd (fonte unica dos comandos de desenho: camaleao em 4 quadrantes, desacelera em ampulheta, glifo derivado do nome para tipo sem forma), PowerUpIcone.gd (icone 16x16 sobre a plataforma elegivel, centrado, base 2 px acima do topo), PowerUpDeTeste.gd (fake dos testes, nunca no registro de producao),
           CameraFollow.gd (limite de topo do gecko = 0,40 da altura visivel e avanco suavizado do excesso de subida, sem cena),
           PauseState.gd (pausa = `get_tree().paused`, nunca `Global.iniciado`; sem cena; ADR 0008),
           TutorialFlag.gd (flag "tutorial ja visto" no OptionsStore), DebugArgs.gd (args de usuario do nativo debug, `--nome=valor` depois de `--`), ModoTutorialVisto.gd (`?tutorial=` dos smokes, so debug), ModoProgressoInicial.gd (`?progresso=` dos smokes, so debug), ModoPowerUpInicial.gd (`?powerup=` dos smokes: power-up ativo ao iniciar a partida, so debug), ModoTempoInicial.gd (`?tempo=<s>` dos smokes: duracao do Contra o tempo, so debug), ModoToqueInicial.gd (`?toque=` dos smokes, so debug), ModoMolduraFixa.gd (`?moldura=fixa`, so debug), ModoMolduraLenta.gd (`?moldura=lenta`, pulso em camera lenta dos smokes, so debug),
           UiHelpers.gd (estilo de caixa, label e chave do mouse das telas de UI, sem cena), GameMode.gd / GameModes.gd / GameModeRule.gd / ClassicoRule.gd / PuroRule.gd / TempoRule.gd (relogio da partida na Stage, regra sem estado) / GameModeTeste.gd (modos de jogo, sem cena: id estavel e chave do recorde, registro com instancias reusadas e ciclo do seletor, hook de regra da Stage; Classico e o padrao, teste so com a flag de debug), TempoConfig.gd (duracao do Contra o tempo de `ressources/tempo.tres`, fallback 60 quando ausente/invalido), GameModesDebug.gd (decide `?modos=teste`, so debug)
test/      testes GUT (`test_*.gd`, `extends GutTest`); `test_landing_restart.gd` regressao do pouso/reinicio (issue #3), sem skip
test/smoke/ roteiros do game-smoke (export web): `gecko.smoke.json` (fluxo), `retrato-*` (telas de celular) e
           `janela-larga-1280x720` (coluna de 180 com barras laterais); mudou input, fluxo de inicio/derrota ou tempos? ajuste-os.
           Todos usam `?tutorial=visto`, menos `tutorial.smoke.json` (1a partida com `user://` limpo); `estagio.smoke.json` (`?progresso=`) prova a subida de `dificuldade.estagio`; `power-up.smoke.json` (`?powerup=`) prova `powerup.ativo|restante|carga` da ponte; `camaleao.smoke.json` e `desacelera.smoke.json` (`?powerup=camaleao|desacelera`) provam ativar, duracao e expirar dos power-ups reais; `toque-modo-{a,b}.smoke.json` (`?toque=a|b`) prova a direcao/diagonal/flick do modo de toque por `player.x/y`; `?semderrota=1` em pontua, estagio e nos roteiros longos (queda pela borda segue); roteiros longos esperam `playing` antes de cada rajada; `modos.smoke.json` (`?modos=teste`) prova o seletor de modo (abrir, trocar, OK; ciclo classico -> puro -> tempo -> zen -> teste) e o campo `modo` da ponte; `modo-puro.smoke.json` prova o Puro sem power-up e `modo-tempo.smoke.json` (`?tempo=<s>`) prova o Contra o tempo: relogio na ponte e `lost` ao zerar; `modo-zen.smoke.json` prova o Zen: sem power-up, queda sem derrota e saida pela pausa (`Sair`) ao menu
addons/    GUT v9.7.1 (vendorizado; nao editar)
assets/    Gecko.png 64×96, GeckoPlataforma.png 64×16 (cor via modulate); fonts/, sounds/ (jump, lose)
export/    saida de build (ignorada; so o .gdignore e versionado, para o Godot nao importar o build)
ressources/ curva_dificuldade.tres (curva de dificuldade, editada no inspector, com `raridade_power_up` e `pesos_power_ups` por estagio; ADR 0007) e power_ups.tres (duracao dos power-ups e fator do Desacelera; ADR 0014) e tempo.tres (duracao do Contra o tempo; ADR 0014)
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
