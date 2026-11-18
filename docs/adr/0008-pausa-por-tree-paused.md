# 0008 — Pausa por `get_tree().paused`, nao por `Global.iniciado`

- **Status:** aceito
- **Data:** 2026-11-12
- **Decisores:** itsManeka + Claude

## Contexto

A partida precisava de pausa (issue #12): botao de toque, tecla/joypad e pausa automatica ao perder o foco. O jogo ja
tinha um sinal de "parado": `Global.iniciado`, que o menu usa para saber que a partida nao comecou. Esse mesmo sinal e
lido pela camada de toque (`TouchControls`, gesto em curso) e pela curva de dificuldade (`DifficultyState`, tempo de
partida). Reusa-lo para a pausa faria cada leitor confundir "pausado" com "partida nao comecou".

## Decisao

- **Pausa = `get_tree().paused = true`.** `Global.iniciado` nao muda ao pausar nem ao retomar. A logica fica em
  `scripts/PauseState.gd` (sem cena): pausar so com partida ativa (iniciada e sem derrota), pausar e retomar idempotentes.
- **So o que precisa rodar pausado e `PROCESS_MODE_ALWAYS`:** o overlay de pausa e o no que escuta a acao `pause`. A
  `Stage`, o Player, o scroll e a dificuldade continuam pausaveis: nada anda nem conta tempo com o jogo pausado.
- **Acao `pause` no InputMap:** Esc, P e o botao de start do controle. No menu e na derrota a acao e ignorada e nao e
  consumida.
- **Pausa automatica:** perda de foco da aplicacao ou da janela e app em segundo plano (`APPLICATION_PAUSED`) pausam a
  partida ativa. Voltar o foco nao retoma: so Continuar, Esc ou P retomam.
- **Ao pausar**, os toques de jogo em curso e o estado pressionado do botao de pausa sao cancelados; um dedo solto depois
  de retomar nao vira pulo nem andar.
- **Botao de pausa e overlay aceitam clique esquerdo de mouse real** (nao o emulado a partir do toque), com a mesma
  regra do toque: aciona ao soltar dentro do alvo. O gesto de jogo segue so por toque ([ADR 0003](0003-controle-de-um-polegar.md)).

## Consequencias

- **Positivas:** um so interruptor congela fisica, scroll e dificuldade; `Global.iniciado` mantem um unico significado.
- **Negativas / trade-offs:** todo no novo que precise reagir com o jogo pausado tem de declarar `PROCESS_MODE_ALWAYS`.
- **Riscos aceitos:** a pausa por foco no export web (`visibilitychange`) e no Android so e verificavel no aparelho, no
  QA do epic.

## Alternativas consideradas

- **Reusar `Global.iniciado`:** zero codigo novo, mas o menu, a camada de toque e a dificuldade passariam a ler "pausado"
  como "nao comecou".
- **Flag de pausa propria checada em cada `_process`:** cada script novo teria de lembrar de checa-la; `tree.paused` ja
  faz isso pela engine.
