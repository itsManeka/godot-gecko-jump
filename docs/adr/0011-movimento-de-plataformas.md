# 0011 — Movimento de plataformas: oscilacao como desvio de velocidade, sem inversao, so no eixo x

- **Status:** aceito
- **Data:** 2026-11-14
- **Decisores:** itsManeka + Claude

## Contexto

As plataformas moveis andam sempre na velocidade do estagio, constante enquanto a plataforma vive. A curva de
dificuldade ([ADR 0007](0007-curva-de-dificuldade-em-resource.md)) passa a ligar duas mecanicas de movimento: plataformas
que oscilam no caminho e linhas que andam em velocidades diferentes umas das outras. Os pontos abaixo ja sao
dependencias da jogabilidade e moldam a decisao:

- O `CheckGenerate` gera a proxima linha quando uma plataforma sai da sua area, e a distancia entre linhas assume
  velocidade constante. Um movimento que inverta o sentido pode fazer a plataforma entrar e sair da area de novo: duas
  saidas, duas linhas geradas, plataformas sobrepostas.
- A garantia de alcance de cor ([ADR 0010](0010-plataformas-cicladoras.md)) filtra candidatas por posicao em `y` e em `x`
  no instante do pouso. Oscilar em `y` quebra esse filtro e a previsao do tempo de pulo; oscilar em `x` nao muda cor
  nem ordem de criacao.
- A fisica do pulo e fixa e o `Player` nao conhece a curva. O movimento precisa continuar passando por
  `move_and_slide`, como hoje, para o corpo do gecko reagir a plataforma.
- No modo sem derrota ([ADR 0009](0009-modificadores-de-plataforma.md)) as plataformas moveis ficam paradas, para o
  roteiro de smoke seguir deterministico.

## Decisao

- **Oscilacao como desvio de velocidade.** A plataforma guarda um desvio horizontal de velocidade, somado a velocidade
  do estagio no `_physics_process` (`velocity = -speed + desvio`). Sem modificador o desvio e zero e o comportamento e o
  de antes.
- **Desvio de media zero.** Em um periodo completo a plataforma percorre a mesma distancia que o movimento uniforme. A
  oscilacao so desloca a posicao em torno desse movimento.
- **Seno e vai-e-vem.** O seno usa onda senoidal. O vai-e-vem usa onda triangular: a velocidade total alterna entre um
  valor acima e outro abaixo da velocidade do estagio. O vai-e-vem limita o desvio a uma fracao da velocidade do
  estagio, por construcao: a plataforma arranca e freia, nunca inverte. O seno nao tem esse limite no codigo: ele nao
  inverte enquanto a velocidade de pico da oscilacao ficar abaixo da velocidade do estagio (ver Consequencias).
- **So eixo horizontal.** A oscilacao nunca e vertical. Movimento vertical seria outra mecanica, decidida em separado.
- **Fase com a plataforma andando.** A fase de cada oscilante e sorteada por plataforma e so avanca enquanto a plataforma
  realmente anda. Antes da partida ou no modo sem derrota ela fica parada e o desvio e zero.
- **Velocidade por linha.** Cada linha movel sorteia, ao nascer, um fator em torno da velocidade do estagio, e a linha
  mantem o valor ate sair da tela. O espacamento das linhas segue a velocidade da propria linha. A linha e a unidade
  de velocidade: plataformas da mesma linha andam juntas.
- **Sorteio por plataforma.** Cada plataforma movel vira oscilante com uma probabilidade da curva, pelo gerador de
  numeros aleatorios da partida. Plataformas estaticas nunca oscilam. A linha inicial tem velocidade zero: nela o movimento fica inerte e a variacao
  de velocidade nao se aplica.
- **Parametros na curva.** Amplitude, periodo, proporcoes e variacao da velocidade ficam no `.tres` e interpolam como a
  largura. Os numeros nao aparecem neste ADR ([ADR 0007](0007-curva-de-dificuldade-em-resource.md)).
- **Modo sem derrota.** As mecanicas de movimento nao agem enquanto a velocidade do estagio e zero. O movimento e
  coberto por teste de cena e observado no bot sem o modo.

## Consequencias

- **Positivas:** o movimento novo e um modificador comum (ver [ADR 0009](0009-modificadores-de-plataforma.md)) mais um
  ponto de extensao de velocidade em `Platform`. Como a oscilacao e so em `x` e sem inversao, a garantia de alcance de
  cor e a contagem de saidas do gerador continuam valendo, e os testes de espacamento e de alcance cobrem o caso.
- **Negativas / trade-offs:** a velocidade de uma plataforma deixa de ser constante, entao a distancia entre vizinhas
  varia: duas plataformas oscilando fora de fase mudam a folga em ate duas vezes a amplitude. A amplitude precisa
  ficar abaixo da folga minima entre vizinhas, e a velocidade de pico precisa ficar abaixo da velocidade do estagio. A
  plataforma tambem pode entrar ou sair do filtro de `x` na borda por essa mesma amplitude.
- **Riscos aceitos:**
  - Se o gecko escorregar nos picos (o corpo do gecko pode nao acompanhar a velocidade extra), a saida e reduzir a
    amplitude ou propagar o desvio ao jogador. O teste de cena mede e decide.
  - Os valores de amplitude, periodo, proporcoes e variacao sao sensacao de jogo. O teste prova alcance e espacamento,
    nao gosto; a confirmacao vem do dono jogando os estagios com o parametro de progresso de debug.
- **Integracao:** `scripts/PlatformSineMotion.gd`, `scripts/PlatformPingPongMotion.gd` e `scripts/RowSpeedVariation.gd`
  sao modificadores sem cena, registrados em `PlatformModifiers.gd` e sorteados pelo gerador.

## Alternativas consideradas

- **Oscilacao vertical:** rejeitada. Quebra o filtro de linha da garantia de cor e a previsao do tempo de pulo; fica como
  mecanica propria, se for pedida.
- **Vai-e-vem com inversao real:** rejeitada. Inverter o sentido pode gerar duas saidas no `CheckGenerate` e linhas
  sobrepostas. Exigiria uma trava de geracao por linha, trabalho separado.
- **Mover a posicao direto, sem velocidade:** rejeitada. Pularia o `move_and_slide`, e o corpo do gecko nao receberia o
  movimento pelo caminho fisico que ja usa.
- **Velocidade sorteada por plataforma:** rejeitada. A linha e a unidade de espacamento do gerador; plataformas de uma
  mesma linha com velocidades diferentes desalinhariam a linha que o gerador preenche.
- **Modificador no `Platform` para tudo:** rejeitada. Seria o contrato de nos filhos da cena, que o
  [ADR 0009](0009-modificadores-de-plataforma.md) ja descartou.
