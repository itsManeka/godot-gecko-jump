# 0012 — Plataformas que piscam: somem e voltam em ritmo fixo, com aviso e trava

- **Status:** aceito
- **Data:** 2026-11-15
- **Decisores:** itsManeka + Claude

## Contexto

As mecanicas de plataforma da curva ([ADR 0007](0007-curva-de-dificuldade-em-resource.md)) ja mudam a cor
([ADR 0010](0010-plataformas-cicladoras.md)) e o movimento ([ADR 0011](0011-movimento-de-plataformas.md)). A nova
mecanica faz a plataforma sumir (sem colisao) e voltar em ritmo fixo. Isso quebra duas garantias do jogo:

- A garantia de alcance de cor precisa considerar que a plataforma pode nao estar solida no instante do pouso ou
  durante a espera do gecko na linha de cima. Uma candidata invisivel nao e apoio.
- O gecko nunca pode ficar preso dentro de uma plataforma que reaparece sobre o corpo dele.

Restricoes que moldam a decisao:

- A mecanica so existe no ultimo estagio da curva. Os estagios anteriores nao mudam.
- O `Player` nao conhece a curva de dificuldade. A injecao vem do gerador, como nas mecanicas irmas.
- O relogio da plataforma precisa parar com o jogo: menu, pausa ([ADR 0008](0008-pausa-por-tree-paused.md)) e derrota
  nao avancam a fase.
- A cor nunca e a unica pista (ecossistema, decisao de acessibilidade). O aviso de sumico precisa ser distinguivel do
  aviso da cicladora, que ja ocupa o canal de cor e alfa.

## Decisao

- **Parametros por estagio, no `.tres`.** `proporcao_piscantes` (fracao das plataformas nao cicladoras que piscam;
  `0.0` por padrao), `duracao_visivel` (segundos visivel e solida, contando o aviso), `duracao_invisivel` (segundos
  sem colisao) e `aviso_pisca` (segundos finais da janela visivel em que a plataforma avisa). A mecanica
  `plataformas_que_piscam` liga na fronteira do estagio. Os numeros de sensacao ficam no `.tres`, nao neste ADR.
- **Modificador com estado por instancia.** `PlatformBlink` (`extends PlatformModifier`, sem cena e sem `Global`)
  guarda fase e relogio. Cada plataforma piscante recebe a sua propria instancia. A lista compartilhada da linha nunca
  carrega o piscar ([ADR 0009](0009-modificadores-de-plataforma.md)).
- **Fase sorteada, relogio so por `delta`.** A fase inicial e sorteada pelo rng dedicado do piscar, derivado da
  semente do gerador e sem consumir o rng do gerador. Mesma semente, mesma fase. O relogio avanca so pelo `delta`
  recebido, entao pausa e menu herdam o congelamento sem codigo proprio (nao se usa `Time` nem `OS`).
- **Relogio congelado com a trava.** Enquanto a plataforma esta travada (gecko em cima, ver abaixo) o relogio nao
  avanca. Os demais modificadores continuam, por isso a espera do gecko e coberta pela janela de previsao.
- **Trava x queda (gecko em cima).** A plataforma travada nunca some e nao entra em aviso. Quando o gecko sai, ela
  retoma o ciclo de onde parou. Uma plataforma em que o gecko esta em cima nao pode sumir debaixo dele, porque a
  queda seria punicao sem aviso previsivel.
- **Previsao na janela de chegada.** `ReachableColors` so conta uma entrada com `"pisca"` se a plataforma esta
  visivel em toda a janela `[chegada, chegada + espera]`, com `ESPERA_MAXIMA_S` e o tempo de pulo ja existentes. Uma
  candidata que some dentro da janela nao conta. Com a garantia de cor, o gerador so sorteia uma cor livre quando a
  lista de candidatas fica vazia, e a ancora abaixo impede isso na geracao real.
- **Piso do ritmo.** O tempo visivel precisa cobrir a espera maxima e o aviso. Esse piso e um criterio tecnico do
  `.tres`, verificado por teste, nao um numero de sensacao.
- **Ancora por linha.** Em cada linha estatica, pelo menos uma plataforma nao pisca. Entre as moveis, nunca ha duas
  piscantes consecutivas na ordem de criacao, e uma piscante nao vem logo depois de cicladora. Se uma linha estatica
  ficaria sem nenhuma plataforma plana, a ultima piscante vira inerte (sempre visivel e solida). Assim toda linha tem
  apoio garantido na janela de chegada. Da mesma forma, a piscante movel que vem logo antes de uma cicladora vira
  inerte (sempre visivel e solida), para o par nao ficar sem apoio garantido.
- **Invisivel vence a regra de cor.** Enquanto a plataforma esta invisivel, a colisao fica desligada, mesmo quando
  `player_color_changed` ou a troca de cor tentariam reabilita-la. Plataforma desmoronada nunca volta a ficar solida.
- **Reaparecer com o gecko dentro espera.** Se a plataforma volta com a cor do gecko e o corpo dele a sobrepoe, a
  colisao fica desligada e liga no frame em que ele sai. E a mesma regra da troca de cor com o gecko dentro
  ([ADR 0010](0010-plataformas-cicladoras.md)), aplicada tambem ao reaparecer.
- **Fantasma, nao sumico total.** Invisivel = fantasma: alfa baixo no proprio no da plataforma, sem colisao. Ela
  continua no lugar, para o jogador saber onde volta. O alfa fica no no, nao em `sprite.modulate`, que e o canal de
  cor e aviso da cicladora.
- **Aviso sem trocar de matiz.** Nos ultimos `aviso_pisca` segundos do visivel, o alfa alterna entre dois niveis em
  cadencia mais rapida que a da cicladora, mantendo a cor. O aviso nao depende de cor para ser lido e nao se confunde
  com a troca de cor da cicladora. Sem icone.
- **Linha inicial sem piscar.** A linha que garante a cor inicial da partida nunca recebe a mecanica, como nas demais.
- **Exclusao com a cicladora.** Uma plataforma nao pisca e cicla ao mesmo tempo. Os dois avisos disputam a mesma
  aparencia e a previsao combinaria duas janelas. Piscar combina com plataformas menores, que caem (desmoronar vence:
  o estado e permanente) e com os movimentos de oscilacao em `x` ([ADR 0011](0011-movimento-de-plataformas.md)).
- **Modo sem derrota inerte.** Com `Global.sem_derrota`, nenhuma plataforma sorteia o piscar, e as que ja tem o
  modificador ficam sempre visiveis e solidas. O smoke deterministico (roteiro com o progresso de debug e o modo sem
  derrota) nao depende da fase do piscar. Por isso o piscar so e observado no jogo sem o modo, pelo bot nativo ou
  jogando.

## Consequencias

- **Positivas:** a garantia de alcance de cor continua valendo com a mecanica ligada, testada com tempo. O aviso nao
  depende de cor. O gecko nunca fica preso dentro da colisao. O relogio herda pausa e menu sem codigo especial.
- **Negativas / trade-offs:** o preditor depende da janela de visibilidade, que depende do `ESPERA_MAXIMA_S` e do
  tempo de pulo. Mudar qualquer um deles muda a previsao. A trava faz o jogo ficar mais facil onde o gecko para em
  cima de uma plataforma piscante. A ancora reduz a quantidade de piscantes em cada linha.
- **Riscos aceitos:**
  - A legibilidade do aviso e o ritmo (visivel e invisivel) sao sensacao. So o dono confirma no jogo.
  - Se a trava deixar o jogo facil demais, a saida e ajustar o `.tres` ou revisar a regra, nao o criterio de alcance.
  - No modo sem derrota o piscar nao age, entao o smoke nao exercita a mecanica. A cobertura vem dos testes de
    geracao, de comportamento e do bot nativo.

## Alternativas consideradas

- **Sumir totalmente (alfa zero):** rejeitada. O jogador perde a referencia de onde a plataforma volta. O fantasma
  mantem a posicao legivel sem colisao.
- **Aviso com troca de matiz:** rejeitada. Ficaria parecido com o aviso da cicladora, que ja troca de cor.
- **Icone fixo sobre a plataforma piscante:** rejeitada. Adiciona um elemento visual a uma plataforma que precisa
  parecer comum fora do aviso.
- **Queda quando o gecko esta em cima:** rejeitada. A plataforma some sem aviso previsivel, o que pune o jogador sem
  chance de reagir. A trava mantem a promessa de espera da janela de previsao.
- **Relogio por `Time` ou `OS.get_ticks_*`:** rejeitada. Nao para com a pausa nem com o menu, e quebra o teste
  deterministico. O relogio por `delta` herda o congelamento do jogo.
- **Piscar e ciclar na mesma plataforma:** rejeitada. Os dois avisos disputariam a mesma aparencia, e a previsao
  teria que combinar duas janelas. A exclusao mantem cada previsao simples.
- **Piscar no modo sem derrota:** rejeitada. Tornaria o smoke nao deterministico (queda por invisibilidade). O modo
  sem derrota segue a mesma regra das demais mecanicas de plataforma: inerte.
