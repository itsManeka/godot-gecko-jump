# 0010 — Plataformas cicladoras: cor prevista no tempo, com trava e aviso visivel

- **Status:** aceito
- **Data:** 2026-11-14
- **Decisores:** itsManeka + Claude

## Contexto

O gecko so pisa nas plataformas da sua cor, e a garantia de alcance ([ADR 0007](0007-curva-de-dificuldade-em-resource.md))
hoje considera so a cor estatica da plataforma no instante do pouso. A mecanica nova faz a cor de algumas plataformas
mudar sozinha no tempo. Sem tratar o tempo, a garantia quebra: uma plataforma que vale a cor do gecko no pouso pode
ter outra cor quando o gecko pular, ou durante a espera dele na linha.

Restricoes que moldam a decisao:

- A mecanica so existe no ultimo estagio da curva (`progresso_inicio = 1.0`). Os estagios anteriores nao mudam.
- O `Player` nao conhece a curva de dificuldade. A injecao vem do `Stage`, como ja acontece com o scroll.
- A fisica do pulo e fixa (`Player.GRAVITY`, `Player.JUMP_POWER`); o tempo ate a linha de cima alcancar o gecko
  depende do scroll vigente.
- O pixel art usa filtro Nearest e a cor nunca e a unica pista (acessibilidade, ver `.claude/CLAUDE.md` do ecossistema).

## Decisao

- **Parametros por estagio, no `.tres`.** `proporcao_cicladoras` (fracao de plataformas moveis que ciclam; `0.0` por
  padrao) e `periodo_ciclo` (segundos por cor; `3.0` por padrao). Os dois interpolam como a largura. A mecanica
  `plataformas_que_mudam_de_cor` liga na fronteira do estagio, sem interpolar. No estagio final a proporcao e `0.3`
  e o periodo e `3.0 s`.
- **Modificador com estado por instancia.** `PlatformColorCycle` (`extends PlatformModifier`) guarda sequencia,
  relogio e trava. Cada plataforma cicladora recebe a sua propria instancia. A lista compartilhada da linha continua
  so com os modificadores sem estado (ver [ADR 0009](0009-modificadores-de-plataforma.md)).
- **Sequencia pre-sorteada.** No nascimento, a cicladora sorteia `CORES_NA_SEQUENCIA = 8` cores, cada uma diferente
  da anterior, pelo `rng` do gerador (deterministico em teste). Depois da ultima, a cor se mantem. A sequencia passa
  por `ReachableColors.forcar_cor_cicladora`, que garante a cor atual do gecko em pelo menos um periodo da sequencia.
  Assim, uma cicladora conta na janela de cores de K plataformas, como as estaticas.
- **Previsao `cor_em(dt)`.** Devolve a cor que a plataforma tera daqui a `dt` segundos, contando a fase atual e
  ignorando a trava. O preditor do pouso (`ReachableColors`) usa essa funcao.
- **Janela de chegada e espera maxima.** O pouso e previsto para `tempo_de_pulo(scroll)`: simulacao tick a tick da
  fisica do pulo ate a linha de cima alcancar o gecko. O gecko pode esperar ate `ESPERA_MAXIMA_S = 0.6 s` na linha
  de cima. Uma cicladora so entra como candidata se a cor for a mesma em toda a janela `[chegada, chegada + espera]`.
  Quem demorar mais que a espera maxima pode ficar sem a garantia.
- **Trava enquanto o gecko esta na plataforma.** `Global.player_color_changed` informa a plataforma de pouso. Essa
  plataforma congela o relogio do ciclo e nao troca de cor. As demais continuam ciclando, e por isso a espera do gecko
  e coberta pela janela acima. Quando o gecko sai, o ciclo retoma de onde parou.
- **Troca adiada com o gecko dentro.** Se a troca tornaria a plataforma solida e o corpo do gecko ainda a sobrepoe,
  a troca fica pendente ate ele sair. Sem isso, o gecko ficaria preso dentro da colisao.
- **Aviso visivel sem icone.** Nos ultimos `AVISO_TROCA_S = 0.6 s` antes da troca, o sprite alterna entre a cor atual
  e a proxima a cada 1/12 s (ciclo de piscar de cerca de 6 Hz). Na fase da proxima cor o alfa cai para `0.55`; na da
  atual fica em `1.0`. O brilho pulsa, e essa pista nao depende de matiz. Fora do aviso, a cicladora e visualmente
  igual a uma plataforma comum. Plataforma travada nao entra em aviso.
- **Linha inicial sem ciclo.** A linha que garante a cor inicial da partida nunca recebe a mecanica, porque e o chao
  garantido do comeco.
- **Modo sem derrota.** Com `Global.sem_derrota`, as plataformas moveis e as estaticas usam a cor `COR_INICIAL` no
  nascimento, e as cicladoras seguem o mesmo ciclo. O smoke aceita a perda por queda nesse modo, porque as
  plataformas ficam atravessaveis em parte do tempo.

## Consequencias

- **Positivas:** a garantia de alcance continua valendo com a mecanica ligada, testada por simulacao com tempo. O
  aviso nao depende de cor nem de icone. Os numeros ficam no `.tres`, e as constantes de comportamento ficam no
  script da mecanica.
- **Negativas / trade-offs:** o preditor depende da fisica do pulo. Se `Player.GRAVITY` ou `Player.JUMP_POWER` mudarem,
  `tempo_de_pulo` acompanha, mas a tolerancia do teste precisa ser revista. A cor da plataforma passa a mudar em
  runtime, e cada cicladora guarda estado proprio (sequencia e relogio) que vive enquanto a plataforma existir.
- **Riscos aceitos:**
  - A legibilidade da troca e do piscar e sensacao. So o jogo com o dono confirma se a pista e clara.
  - A espera maxima de `0.6 s` e um valor de sensacao. Subir o valor restringe a geracao; baixar enfraquece a promessa.
  - Com a mecanica ligada, a queda pela borda pode acontecer no modo sem derrota. O roteiro de smoke aceita isso.
  - A plataforma que ciclou pode ficar na cor do gecko e nao ser a que ele pousa, se o gecko sobrepuser duas
    plataformas no mesmo frame. Herda o risco ja aceito no [ADR 0009](0009-modificadores-de-plataforma.md).

## Alternativas consideradas

- **Icone fixo sobre a cicladora:** rejeitado. Adiciona um elemento visual a uma plataforma que precisa parecer
  comum fora do aviso, e nao resolve a legibilidade sozinho. O aviso com brilho e alternancia de cor cobre a pista.
- **Garantia so pela cor do instante do pouso:** rejeitada. Com a mecanica ligada, o gecko pode pular no ato e cair
  em uma plataforma que ja trocou, ou esperar e encontrar a cor errada.
- **Cor do gecko seguindo a cicladora apenas no smoke:** mantida como saida de contingencia, nao adotada. Mudaria o
  comportamento que o smoke testa, e o modo sem derrota ja usa a cor unica.
- **Troca imediata mesmo com o gecko dentro:** rejeitada. Torna a plataforma solida sobre o corpo do gecko e pode
  prende-lo dentro da colisao.
- **Ciclo como parte da lista de modificadores da linha:** rejeitada. A lista e compartilhada por todas as plataformas
  da linha, e o ciclo precisa de sequencia e relogio proprios.
