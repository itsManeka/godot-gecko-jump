# Modos de jogo e power-ups

## Contexto

O Epic 4 (Conteudo) do Gecko Jump transformou duas ideias em subsistemas de verdade: **modos de jogo** (seletor,
regra por modo, recorde por modo) e **power-ups** (sorteio, efeito, duracao, HUD). Antes disso o jogo so tinha o
Classico e um pulo de uma cor.

Este documento tem as regras de negócio e as armadilhas. O `.claude/CLAUDE.md` do repo diz quem é cada script, o
[ADR 0014](../docs/adr/0014-power-ups-e-modos-de-jogo.md) tem os critérios de aceite de cada power-up e o `README.md`
mostra o resultado ao jogador.

## Regras

### Modos de jogo

- Todo modo tem id estavel, rotulo, descricao e uma regra (`GameModeRule`). O registro `GameModes` e a unica fonte da
  ordem do seletor: Classico, Puro, Tempo, Zen, Diario. O modo de teste entra por ultimo e so em build debug.
- O Classico e o padrao de toda resolucao: id vindo de opcao salva que seja invalido, vazio ou desconhecido volta para
  o Classico — nunca um modo que o build nao expoe.
- A regra decide, sem estado proprio (uma instancia por modo, reusada em todas as partidas): fim de partida, power-ups
  habilitados, recorde, reposicionamento ao cair, scroll forcado, relogio e seed do dia.
- Gravam recorde: Classico, Puro e Contra o tempo. Zen nao grava (o menu mostra so os pontos da partida, sem Best).
  O Desafio diario tambem nao grava no `best_score_*`: o resultado do dia vive no `DesafioDiarioStore`.
- Recorde por modo em `user://best_score_<id>.cfg`; o Classico continua no `user://best_score.cfg` (compatibilidade).
- **Desafio diario**: uma tentativa por dia UTC; a semente da partida e o dia, entao a fase e a mesma para todo mundo.
  Registro em `user://desafio_diario.cfg` com dia, tentativa gasta e resultado; a virada do dia zera a tentativa sem
  apagar o arquivo.
- **Contra o tempo**: 60 s (duracao em `ressources/tempo.tres`, fallback de 60 quando ausente ou invalido). O relogio
  vive na Stage e a partida acaba quando ele zera.
- **Zen**: o mundo para (fator de scroll forcado 0), cair reposiciona o gecko na ultima plataforma pisada, nao ha
  power-ups e nao ha Best. Na pausa, o botao **Sair** volta ao menu.
- **Puro**: o Classico sem power-ups.

### Power-ups

- Contrato `PowerUp` com hooks de padrao neutro (`ignora_cor()`, `fator_scroll()`), agregado no `PowerUpState`
  (ativo/carga).
- O sorteio (`PowerUpDraw`) usa raridade e pesos por estagio da curva, com **rng dedicado**: o sorteio do power-up
  nunca desloca o layout da fase.
- A regra de cor do Camaleao e reavaliada **na ativacao e na expiracao**, mesmo com o gecko caindo no meio; a
  plataforma sob o gecko fica travada.
- O Desacelera multiplica o scroll por 0,5; a previsao de cor usa o scroll efetivo. Duracao e fator ficam em
  `ressources/power_ups.tres`, com o fallback do ADR quando o arquivo esta ausente ou invalido.
- A Segunda chance e carga unica (no maximo 1), sem tempo: ao cruzar a linha de derrota a partida segue, a carga vai
  a 0 e o gecko reaparece na plataforma visivel mais proxima da cor dele; sem nenhuma daquela cor, na mais proxima de
  qualquer cor, assumindo a cor dela. O reaparecimento nao conta como pouso (sem ponto, sem sorteio de cor).
- Icone monocromatico (branco/preto) na plataforma e no HUD, pela fonte unica `PowerUpDesenho` — a cor nunca e a
  unica pista.
- Puro, Zen e Desafio diario nao tem power-ups.

## Integracao

- A **Stage** e dona da partida: relogio, consumo da Segunda chance, aplicacao do fator de scroll e o hook de queda.
- Seams de debug, validos so em build debug (o release ignora): `?seed=`, `?powerup=`, `?tempo=`, `?dia=`,
  `?modos=teste`.
- O `window.__GAME_STATE__` publica `modo`, `powerup.ativo|restante|carga` e o relogio para os roteiros de smoke.
- Recorde e opcoes vivem em `user://`, nunca em `res://`.

## Gotchas

- `GameModes.de_id()` nunca devolve um modo que o build nao expoe: opcao salva com id desconhecido cai no Classico.
- Os rngs de layout, de cor movel e de power-up sao separados: mexer no sorteio de power-up nao muda a fase (e
  vice-versa).
- Sem `power_ups.tres` (ou com valor invalido) o jogo usa o fallback do ADR — nunca quebrar o export.
- O modo de teste so existe em debug; em release o seletor mostra cinco modos.
- O Desafio diario usa o dia UTC como semente: a fase muda com a virada do dia UTC.
