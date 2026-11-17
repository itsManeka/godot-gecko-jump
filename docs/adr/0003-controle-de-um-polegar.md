# 0003 — Controle de toque de um polegar

- **Status:** superado por [0013](0013-modos-de-toque-alternaveis.md) (o esquema tap x segurar foi removido na #47; a
  ideia de um polegar sobrevive no modo A)
- **Data:** 2026-11-08
- **Decisores:** itsManeka + Claude

## Contexto

Hoje so ha teclado (andar esquerda/direita + pular). Jogos verticais de toque bem avaliados usam uma mao so e a tela
inteira como area de toque (Leap Day, Tower Climb, Color Jump), sem botoes virtuais pequenos.

## Decisao

- **Toque rapido** na metade esquerda/direita da tela: pulo diagonal para aquele lado.
- **Segurar** na metade: anda para aquele lado (mantem o ajuste fino de posicao).
- Teclado e controle continuam como estao. Implementacao: issue #11.

### Como ficou (issues #11 e #44)

- **Limiar de 200 ms**, decidido no release: toque de ate 200 ms e pulo, a partir de 200 ms e segurar. O pulo sai ao
  soltar o dedo (latencia de ate 200 ms no tap) em troca de nunca pular por engano no comeco de um segurar.
- **Tap = pulo diagonal** (#44): ao soltar um tap, a camada pressiona o lateral da metade tocada junto com o `jump`; o
  Player le as duas acoes e o voo sai diagonal para aquele lado.
- **O lateral do tap segue ate o pouso** (#44): depois do tap ele fica pressionado — como uma seta mantida no teclado —
  ate o `Player.on_ground` voltar a verdadeiro depois de ter saido do chao. A 80 px/s e ~50 ticks de voo, o
  deslocamento fica em ~67 px, com wrap nas bordas da tela. Antes o lateral saia em 2 ticks e o tap deslocava ~12 px,
  quase so vertical (defeito que motivou a #44).
- **O `jump` e so um pulso** (`TICKS_MINIMOS`): segurar o pulo ate o pouso faria o gecko pular de novo sozinho ao
  encostar no chao. So o lateral fica sustentado; o `jump` solta no fim do pulso, mesmo com o lateral ainda ativo.
- **Teto de seguranca** (`TICKS_TETO_LATERAL_TAP`, 120 ticks ~ 2 s): se o tap nunca decolar (pulo descartado no ar),
  o lateral nao pode ficar preso para sempre. Pausa, derrota (fim de partida), perda de foco da janela e saida da
  arvore soltam o lateral na hora, sem esperar o teto.
- **Tap no ar**: nao pula, como no teclado — nao ha buffer de pulo para o proximo pouso. O lateral, porem, troca para o
  lado tocado (ou se estende) e segue ate o pouso: com um polegar so, o jogador corrige a rota no meio do voo.
- **Hold no meio do voo** assume a posse do lateral: solta o lateral do tap (de qualquer lado), anda enquanto o dedo
  esta na tela e o solta no release do dedo. O pouso nao devolve o lateral ao tap.
- **Modo pulo ao pressionar** (`PULO_NO_PRESSIONAR = true`, opcional, fora do default): o lateral do pulo segue so o
  pulso curto de `TICKS_MINIMOS`; o lateral sustentado ate o pouso vale so para o tap no release.
- **Acao ja pressionada por outro** (teclado, joypad) nunca e assumida nem solta pela camada de toque.
- **Atraso do hold** (#44): como tap x hold so e decidido no release, o hold so comeca a andar ~200 ms (~12 ticks,
  ~16 px) depois de tocar. A velocidade depois disso e a mesma do teclado (80 px/s, mesma acao); o atraso fica
  registrado como trade-off do limiar, a julgar no playtest.
- **So toque**: mouse (real ou emulado a partir do toque) e ignorado pela camada de toque. Excecao fora do gesto de
  jogo: o botao de pausa e o overlay de pausa aceitam clique esquerdo de mouse real ([ADR 0008](0008-pausa-por-tree-paused.md)).
- **Lado decidido ao pressionar**: arrastar o dedo para a outra metade nao troca o lado. So o primeiro dedo vale
  enquanto estiver na tela; o meio exato da tela pertence a direita.
- Toque em qualquer ponto da tela inicia a partida; o toque que inicia nao vira pulo.
- **Dica de zonas**: na primeira partida em aparelho com tela de toque (ou depois do primeiro toque), uma dica discreta
  mostra as duas metades, "pula" e "segura: anda", e some com fade. Volta so ao recarregar a pagina (nada e salvo).
- O limiar, o teto do lateral e os comportamentos acima ficam cada um numa constante (`TouchClassifier`,
  `TouchControls`), para o ajuste do playtest ser de uma linha.

## Consequencias

- **Positivas:** jogavel com uma mao, polegar so na metade inferior; nenhuma UI cobrindo as plataformas.
- **Negativas / trade-offs:** distinguir toque de segurar exige um limiar de tempo afinado em playtest; enquanto isso,
  o hold so comeca a andar ~200 ms (~12 ticks) depois do toque.
- **Riscos aceitos:** se o playtest reprovar, trocar pela alternativa abaixo, que muda a mecanica.

## Alternativas consideradas

- **Corrida automatica + toque para pular (estilo Leap Day):** um unico gesto, mas tira o controle de direcao.
- **Botoes virtuais (setas + pulo):** familiar, mas exige duas maos e cobre parte da tela de 180 px.
- **Inclinar o aparelho (acelerometro):** impreciso e nao funciona no navegador do desktop.
