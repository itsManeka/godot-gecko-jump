# 0013 — Modos de toque alternaveis: tres esquemas selecionaveis, padrao provisorio

- **Status:** proposto (ate o playtest do dono)
- **Data:** 2026-11-17
- **Decisores:** itsManeka + Claude

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

## Decisao

- **Tres esquemas de toque por tras de um contrato.** `TouchScheme` (`scripts/TouchScheme.gd`) recebe
  `press`/`mover`/`release`/`cancelar`/`cancelar_tudo` e devolve `intencao(t_ms)` ->
  `{esquerda, direita, pulo}`: lateral e nivel, `pulo` e evento de pulso (nunca fica true com o dedo segurado).
  A base cuida de zona morta, dedos ativos e cancelamento; quem traduz intencao em acoes de input e a
  `TouchControls`, que mantem a posse das acoes, o pulso de 2 ticks (`TICKS_MINIMOS`,
  `scenes/TouchControls.gd:14`), a inercia fora de partida e o cancelamento de pausa/foco/derrota.
- **Modos e persistencia.** Enum `A/B/C` em `scripts/TouchMode.gd:9`, salvo no `OptionsStore` (secao `controle`,
  chave `toque_modo`, `scripts/TouchMode.gd:11-12`). Valor ausente, corrompido, de tipo errado, fracionario ou
  fora da faixa cai no padrao (`scripts/TouchMode.gd:23-33`). O seletor nas Opcoes e um botao "Toque: <nome>" que
  cicla A -> B -> C -> A, grava e aplica na hora: trocar de modo cancela o gesto em curso (solta toda acao da
  camada de toque) e rearma a dica de toque (nao o tutorial).
- **Valores de sensacao provisorios, um simbolo cada** (`scripts/TouchTuning.gd`): zona morta de
  `ZONA_MORTA_PX = 6.0` px logicos (`TouchTuning.gd:8`); flick de `FLICK_DY_MIN_PX = 24.0` px em
  `FLICK_JANELA_MS = 150` ms (`TouchTuning.gd:10-11`); janela de simultaneo do C de `JANELA_SIMULTANEO_MS = 80` ms
  (`TouchTuning.gd:13`). Ajustar no playtest e editar uma linha.
- **Regras por modo:**
  - **A — arrastar + flick, um polegar** (`scripts/TouchSchemeA.gd`): um dedo em qualquer lugar da tela. O lateral
    e relativo a uma ancora que acompanha o dedo: passou de 6 px para um lado = anda para ele; o lado inverte
    quando o dedo volta mais de 6 px contra a direcao, sem recuar ate o ponto de contato. Flick para cima
    (dy >= 24 px dentro de 150 ms) pede um pulo; o lateral do instante decide reto (dedo na zona morta) ou
    diagonal (dedo deslocado). Varios flicks no mesmo toque. Tap seco (toque sem deslocamento) nao faz nada.
  - **B — dois polegares, zonas invisiveis** (`scripts/TouchSchemeB.gd`): a metade esquerda dirige (deslocamento
    relativo ao contato, zona morta de 6 px, ancora que segue; o lado vale no chao e no ar) e a metade direita
    pula no press, sem limiar de tempo. O lado do dedo e decidido no press e fica fixo ate soltar
    (`x ==` metade `= direita`, `scripts/TouchClassifier.gd:10-11`); uma vaga por metade, dedo extra ignorado.
  - **C — metades + 2o toque** (`scripts/TouchSchemeC.gd`): segurar uma metade anda para o lado dela no press
    (sem atraso). Um 2o toque em qualquer ponto pede um pulso de pulo na direcao do dedo que anda. Dois toques em
    metades opostas com intervalo menor que 80 ms valem como simultaneos: cancela o lateral e pula reto. Depois
    de soltar um dos dois dedos, o outro so volta a andar com um novo press.
- **Comportamento comum a todo modo:** pulo reto, pulo diagonal, correcao de direcao no ar e andar no chao sem
  pular; comeca a andar no press (sem o atraso de 200 ms do esquema antigo); acao ja pressionada por
  teclado/joypad nunca e assumida nem solta pela camada de toque; tela inteira como area, com zonas mortas
  respeitadas (botao de pausa, Pular do tutorial); o toque que inicia a partida no menu nao gera acao de jogo;
  pausa, perda de foco, derrota e cancelamento soltam tudo.
- **Padrao provisorio: C** (`scripts/TouchMode.gd:18-19`), o mais proximo do esquema antigo. Trocar o padrao e
  mudar um simbolo. So o playtest do dono fixa o padrao.
- **Debug dos smokes:** `?toque=a|b|c` (`scripts/ModoToqueInicial.gd:17-28`, so em build debug) forca o modo da
  sessao sem gravar no store; em release o parametro e ignorado.
- **Esquema antigo removido.** O tap x segurar do [ADR 0003](0003-controle-de-um-polegar.md) sai do codigo
  (o `TouchClassifier` fica so com o `lado_de`, usado pelos esquemas B e C); o 0003 fica superado por este ADR.
- **Cobertura em 3 camadas** ([ADR 0006](0006-oraculo-de-jogo-em-3-camadas.md)): os testes GUT provam o
  deterministico (posicao e `velocity.x` do `Player` por ticks); a direcao, o diagonal, o flick e o multitoque
  reais sao provados por roteiro de smoke por modo em `test/smoke/toque-modo-{a,b,c}.smoke.json`, com `expect`
  em `player.x/y` (a ponte publica a posicao no export web de debug).

## Consequencias

- **Positivas:** pulo reto existe em todo modo (C: dois toques em metades opostas; A: flick com o dedo na zona
  morta; B: dedo direito sozinho); todo modo comeca a andar no press, sem o atraso de 200 ms, e anda no chao sem
  pular; trocar de esquema e uma opcao na tela de Opcoes, sem rebuild; fisica do `Player` e teclado/joypad
  intocados.
- **Negativas / trade-offs:** os valores de sensacao sao provisorios e os tres esquemas coexistem ate a poda;
  a janela do flick e a do simultaneo dependem do relogio do frame; trocar o modo rearma a dica de toque.
- **Riscos aceitos:**
  - O flick do modo A mede a janela de 150 ms no relogio do frame: com FPS baixo, um flick curto pode nao ser
    detectado. Registrado na issue #48; a correcao (relogio proprio em ms) fica para la.
  - O padrao C e provisorio: o dono escolhe o padrao jogando; a saida e trocar `TouchMode.padrao()`.

## O que ficou aberto

- **Issue #48:** flick curto do modo A nao pula com FPS baixo; a janela de 150 ms e medida no relogio do frame.
- **Roteiros de smoke por modo:** `test/smoke/toque-modo-{a,b,c}.smoke.json`, com `?toque=` e os limites de
  `expect` medidos no viewport de cada roteiro (so web de debug).
- **Padrao provisorio C** ate o playtest do dono; o resultado alimenta uma feature de fechamento (fixar padrao e
  podar os modos perdedores).
- **Pontos do playtest (decisao na feature `f495-fixar-padrao-de-toque-e-podar-modos`):** (1) nos modos A e B,
  depois de deslocar e parar com o dedo apoiado, o personagem segue andando (o lado so inverte, nao volta a parado
  sem soltar o dedo); (2) no modo A, arrasto vertical longo repula a cada ~24 px (pulso no pouso, comportamento do
  flick consumindo o historico).
- **Criterio de poda dos modos** (sugestao, nao decidida): manter o vencedor + no maximo 1 alternativa.
- **Status "Proposto"** ate o playtest validar a sensacao dos tres esquemas no aparelho.

## Alternativas consideradas

- **Manter o tap x segurar do ADR 0003 e ajustar o limiar:** reprovado no playtest (sem pulo reto, direcao
  travada ate o pouso e atraso de 200 ms para comecar a andar); o problema e o formato do gesto, nao o numero.
- **Escolher um esquema sem prototipar:** rejeitada. A sensacao nao e julgavel pela maquina
  ([ADR 0006](0006-oraculo-de-jogo-em-3-camadas.md)); o dono prefere comparar os tres no aparelho antes de podar.
- **Corrida automatica + toque para pular (estilo Leap Day):** um unico gesto, mas tira o controle de direcao
  (herdada de [ADR 0003](0003-controle-de-um-polegar.md)).
- **Botoes virtuais (setas + pulo):** familiar, mas exige duas maos e cobre parte da tela de 180 px (herdada de
  [ADR 0003](0003-controle-de-um-polegar.md)).
