# 0003 — Controle de toque de um polegar

- **Status:** aceito
- **Data:** 2026-11-08
- **Decisores:** itsManeka + Claude

## Contexto

Hoje so ha teclado (andar esquerda/direita + pular). Jogos verticais de toque bem avaliados usam uma mao so e a tela
inteira como area de toque (Leap Day, Tower Climb, Color Jump), sem botoes virtuais pequenos.

## Decisao

- **Toque rapido** na metade esquerda/direita da tela: pulo diagonal para aquele lado.
- **Segurar** na metade: anda para aquele lado (mantem o ajuste fino de posicao).
- Teclado e controle continuam como estao. Implementacao: issue #11.

### Como ficou (issue #11)

- **Limiar de 200 ms**, decidido no release: toque de ate 200 ms e pulo, a partir de 200 ms e segurar. O pulo sai ao
  soltar o dedo (latencia de ate 200 ms no tap) em troca de nunca pular por engano no comeco de um segurar.
- **Tap no ar e descartado**, como no teclado: nao ha buffer de pulo para o proximo pouso.
- **So toque**: mouse (real ou emulado a partir do toque) e ignorado pela camada de toque. Excecao fora do gesto de
  jogo: o botao de pausa e o overlay de pausa aceitam clique esquerdo de mouse real ([ADR 0008](0008-pausa-por-tree-paused.md)).
- **Lado decidido ao pressionar**: arrastar o dedo para a outra metade nao troca o lado. So o primeiro dedo vale
  enquanto estiver na tela; o meio exato da tela pertence a direita.
- Toque em qualquer ponto da tela inicia a partida; o toque que inicia nao vira pulo.
- **Dica de zonas**: na primeira partida em aparelho com tela de toque (ou depois do primeiro toque), uma dica discreta
  mostra as duas metades, "pula" e "segura: anda", e some com fade. Volta so ao recarregar a pagina (nada e salvo).
- O limiar e os comportamentos acima ficam cada um numa constante (`TouchClassifier`, `TouchControls`), para o
  ajuste do playtest ser de uma linha.

## Consequencias

- **Positivas:** jogavel com uma mao, polegar so na metade inferior; nenhuma UI cobrindo as plataformas.
- **Negativas / trade-offs:** distinguir toque de segurar exige um limiar de tempo afinado em playtest.
- **Riscos aceitos:** se o playtest reprovar, trocar pela alternativa abaixo, que muda a mecanica.

## Alternativas consideradas

- **Corrida automatica + toque para pular (estilo Leap Day):** um unico gesto, mas tira o controle de direcao.
- **Botoes virtuais (setas + pulo):** familiar, mas exige duas maos e cobre parte da tela de 180 px.
- **Inclinar o aparelho (acelerometro):** impreciso e nao funciona no navegador do desktop.
