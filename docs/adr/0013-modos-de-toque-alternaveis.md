# 0013 — Modos de toque alternaveis: A e B selecionaveis, B padrao

- **Status:** aceito
- **Data:** 2026-11-17
- **Decisores:** itsManeka + Claude
- **Nome de apresentacao:** Flick (modo A, arrastar + flick) e Joy invisivel (modo B, dois polegares). O enum e o valor salvo continuam A/B; a decisao abaixo nao muda.

## Contexto

O playtest do controle de toque tap x segurar ([ADR 0003](0003-controle-de-um-polegar.md)) reprovou no celular
(issue #47): nao ha pulo reto (o tap sai sempre diagonal), a direcao "trava" (o lateral do tap segue ate o pouso) e
andar no chao sem pular e importante. O dono decidiu prototipar tres esquemas selecionaveis nas Opcoes e escolher o
padrao jogando, em vez de ajustar o esquema antigo.

Restricoes que moldam a decisao:

- A camada de toque segue isolada: `TouchControls` so pressiona/solta `ui_left`/`ui_right`/`jump`; a fisica do
  `Player` nao muda ([ADR 0002](0002-tela-mobile-largura-180.md), tela de 180 px). Teclado e joypad ficam intactos.
- O dono joga so o que a maquina nao julga ([ADR 0006](0006-oraculo-de-jogo-em-3-camadas.md)): a escolha do padrao
  e dele; os valores de sensacao sao provisorios ate o playtest.
- O toque no aparelho so vale com toque real: mouse (real ou emulado) e ignorado pela camada de toque.

O playtest de 2026-11-17 comparou os tres esquemas no aparelho: o dono escolheu o **B (dois polegares)** como padrao e
descartou o **C (metades + 2o toque)**; o **A** fica como alternativa, com sensibilidade ajustavel. O
mesmo playtest achou o repulo do A no arrasto vertical longo e o flick curto que falhava com FPS baixo (issue #48).

## Decisao

- **Dois esquemas de toque por tras de um contrato.** `TouchScheme` (`scripts/TouchScheme.gd`) recebe
  `press`/`mover`/`release`/`cancelar`/`cancelar_tudo` e devolve `intencao(t_ms)` ->
  `{esquerda, direita, pulo}`: lateral e nivel, `pulo` e evento de pulso (nunca fica true com o dedo segurado).
  A base cuida de zona morta, dedos ativos e cancelamento; quem traduz intencao em acoes de input e a
  `TouchControls`, que mantem a posse das acoes, o pulso de 2 ticks (`TICKS_MINIMOS`,
  `scenes/TouchControls.gd:14`), a inercia fora de partida e o cancelamento de pausa/foco/derrota.
- **Modos e persistencia.** Enum `A/B` em `scripts/TouchMode.gd:8`, salvo no `OptionsStore` (secao `controle`,
  chave `toque_modo`). Valor ausente, corrompido, de tipo errado, fracionario ou fora da faixa cai no padrao, que e
  **B** (`scripts/TouchMode.gd:17-18`); o valor 2 do esquema C e qualquer outro fora da faixa tambem caem em
  B; o valor 0 continua A. O seletor nas Opcoes e um botao "Toque: <nome>" que alterna A <-> B, grava e aplica na
  hora: trocar de esquema cancela o gesto em curso (solta toda acao da camada de toque) e rearma a dica de toque (nao o
  tutorial).
- **Sensibilidade do modo A.** Um unico controle nas Opcoes, visivel so com o modo A ativo (em B o bloco de opcoes
  continua com a altura anterior). Ele escala juntos a zona morta e o dy minimo do flick do A; a janela de 150 ms nao
  e exposta e a zona morta do B nao e escalada. O padrao 1,0x reproduz o comportamento anterior (6 px / 24 px) e a
  faixa vai de 0,5x a 2x (provisoria, o dono julga no aparelho). Persistido na secao `controle`, chave
  `toque_sensibilidade`; ausente, de tipo errado, NaN ou fora da faixa cai no padrao. A aplicacao e imediata e a
  gravacao segue a regra dos volumes (ao soltar o slider, fechar as Opcoes ou sair do app).
- **Valores de sensacao finais, um simbolo cada** (`scripts/TouchTuning.gd`): zona morta de `ZONA_MORTA_PX = 6.0` px
  logicos; flick de `FLICK_DY_MIN_PX = 24.0` px em `FLICK_JANELA_MS = 150` ms; rearme do flick de
  `REARME_VELOCIDADE_PX_MS = 0.05`, `REARME_PARADO_MS = 48` e `REARME_RECUO_PX = 12.0`; sensibilidade
  `SENSIBILIDADE_PADRAO = 1.0`, `SENSIBILIDADE_MIN = 0.5`, `SENSIBILIDADE_MAX = 2.0`. Ajustar no playtest e editar
  uma linha.
- **Regras por modo:**
  - **A — arrastar + flick, um polegar** (`scripts/TouchSchemeA.gd`): um dedo em qualquer lugar da tela. O lateral
    e relativo a uma ancora que acompanha o dedo: passou da zona morta do A para um lado = anda para ele; o lado
    inverte quando o dedo volta a zona morta contra a direcao, sem recuar ate o ponto de contato. Flick para cima
    (dy >= dy minimo do A dentro de 150 ms) pede um pulo; o lateral do instante decide reto (dedo na zona morta) ou
    diagonal (dedo deslocado). Cada flick desarma o esquema: o proximo so vale depois de o dedo parar (velocidade
    vertical media abaixo de `REARME_VELOCIDADE_PX_MS` medida em pelo menos `REARME_PARADO_MS`) ou recuar
    `REARME_RECUO_PX` para baixo, entao arrasto vertical continuo gera UM pulso e "varios flicks no mesmo toque"
    continua valendo apos o rearme. A deteccao do flick guarda a ultima amostra fora da janela como referencia e mede
    o deslocamento contra ela: eventos espacados (FPS baixo, issue #48) ainda detectam o flick curto; gesto lento (24
    px em 2 s) continua fora do flick pela janela. Tap seco (toque sem deslocamento) nao faz nada.
  - **B — dois polegares, zonas invisiveis** (`scripts/TouchSchemeB.gd`): a metade esquerda dirige (deslocamento
    relativo ao contato, zona morta de 6 px, ancora que segue; o lado vale no chao e no ar) e a metade direita
    pula no press, sem limiar de tempo. O lado do dedo e decidido no press e fica fixo ate soltar
    (`x ==` metade `= direita`, `scripts/TouchClassifier.gd:10-11`); uma vaga por metade, dedo extra ignorado. A
    sensibilidade do A nao muda nada aqui.
- **Comportamento comum a todo modo:** pulo reto, pulo diagonal, correcao de direcao no ar e andar no chao sem
  pular; comeca a andar no press (sem o atraso de 200 ms do esquema antigo); acao ja pressionada por
  teclado/joypad nunca e assumida nem solta pela camada de toque; tela inteira como area, com zonas mortas
  respeitadas (botao de pausa, Pular do tutorial); o toque que inicia a partida no menu nao gera acao de jogo;
  pausa, perda de foco, derrota e cancelamento soltam tudo.
- **Tutorial e dica de toque por modo.** O card da 1a partida e a reabertura explicam o controle do modo ativo
  (A: arraste anda, flick pula, sensibilidade nas Opcoes; B: esquerda segura anda, direita toca pula, zonas
  invisiveis) e a dica mostra os blocos do modo ativo (B: dois blocos laterais e a linha divisoria; A: bloco central).
  Trocar de modo nao reabre o tutorial; "Ver tutorial" mostra o modo ativo.
- **Debug dos smokes:** `?toque=a|b` (`scripts/ModoToqueInicial.gd`, so em build debug) forca o modo da sessao sem
  gravar no store; em release o parametro e ignorado.
- **Esquema antigo removido.** O tap x segurar do [ADR 0003](0003-controle-de-um-polegar.md) sai do codigo
  (o `TouchClassifier` fica so com o `lado_de`, usado pelo esquema B); o 0003 fica superado por este ADR. O esquema C
  (metades + 2o toque) tambem sai: script, ramo do seletor, janela de simultaneo, textos, testes e roteiro de smoke.
- **Cobertura em 3 camadas** ([ADR 0006](0006-oraculo-de-jogo-em-3-camadas.md)): os testes GUT provam o
  deterministico (posicao e `velocity.x` do `Player` por ticks; rearme e FPS baixo com relogio injetado); a direcao,
  o diagonal e o flick reais sao provados por roteiro de smoke por modo em
  `test/smoke/toque-modo-{a,b}.smoke.json`, com `expect` em `player.x/y` (a ponte publica a posicao no export web de
  debug).

## Consequencias

- **Positivas:** o padrao e o favorito do dono no aparelho (B); so dois esquemas coexistem, com menos codigo, teste e
  texto por modo; o A ganhou sensibilidade ajustavel sem tocar na fisica; o flick do A nao repula no arrasto vertical
  longo nem falha com FPS baixo; todo esquema comeca a andar no press, sem o atraso de 200 ms, e anda no chao sem
  pular; trocar de esquema e uma opcao na tela de Opcoes, sem rebuild; teclado/joypad intocados.
- **Negativas / trade-offs:** a faixa e os valores da sensibilidade sao provisorios ate o dono julgar no aparelho; a
  janela do flick continua dependendo do relogio do frame (a deteccao e robusta a eventos espacados, mas nao a um
  gesto lento); trocar o modo rearma a dica de toque.
- **Riscos aceitos:**
  - O ponto (1) do playtest continua: no A e no B, depois de deslocar e parar com o dedo apoiado, o personagem segue
    andando (o lado so inverte, nao volta a parado sem soltar o dedo). O dono gostou do B assim ("parece joystick");
    fica sem correcao por enquanto.
  - Os valores de sensacao (zona morta, flick, rearme e faixa da sensibilidade) sao provisorios: ajustar e editar uma
    constante em `scripts/TouchTuning.gd`.

## O que ficou aberto

- **Faixa da sensibilidade do A:** 0,5x a 2x e provisoria; o dono ajusta nas Opcoes e calibra as constantes se
  precisar.
- **Ponto (1) do playtest:** mantido (A e B seguem andando com o dedo apoiado), como registrado nos riscos aceitos.
- **Roteiros de smoke por modo:** `test/smoke/toque-modo-{a,b}.smoke.json`, com `?toque=` e os limites de `expect`
  medidos no viewport de cada roteiro (so web de debug).

As issues #47 (modos de toque alternaveis) e #48 (flick curto do A com FPS baixo, corrigido junto com o repulo do
arrasto vertical longo) fecham no PR do epic.

## Alternativas consideradas

- **Manter o tap x segurar do ADR 0003 e ajustar o limiar:** reprovado no playtest (sem pulo reto, direcao
  travada ate o pouso e atraso de 200 ms para comecar a andar); o problema e o formato do gesto, nao o numero.
- **Manter o esquema C:** rejeitada no playtest. O C nao venceu e triplicava codigo, teste e texto
  por modo; o B foi o escolhido e o A ficou como alternativa.
- **A como padrao, B como alternativa:** rejeitada. O B foi o favorito do dono no aparelho; o A fica disponivel para
  quem prefere um polegar, agora com sensibilidade ajustavel.
- **Escolher um esquema sem prototipar:** rejeitada. A sensacao nao e julgavel pela maquina
  ([ADR 0006](0006-oraculo-de-jogo-em-3-camadas.md)); o dono preferiu comparar os tres no aparelho antes de podar.
- **Corrida automatica + toque para pular (estilo Leap Day):** um unico gesto, mas tira o controle de direcao
  (herdada de [ADR 0003](0003-controle-de-um-polegar.md)).
- **Botoes virtuais (setas + pulo):** familiar, mas exige duas maos e cobre parte da tela de 180 px (herdada de
  [ADR 0003](0003-controle-de-um-polegar.md)).
