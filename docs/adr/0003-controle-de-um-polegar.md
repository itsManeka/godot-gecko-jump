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

## Consequencias

- **Positivas:** jogavel com uma mao, polegar so na metade inferior; nenhuma UI cobrindo as plataformas.
- **Negativas / trade-offs:** distinguir toque de segurar exige um limiar de tempo afinado em playtest.
- **Riscos aceitos:** se o playtest reprovar, trocar pela alternativa abaixo, que muda a mecanica.

## Alternativas consideradas

- **Corrida automatica + toque para pular (estilo Leap Day):** um unico gesto, mas tira o controle de direcao.
- **Botoes virtuais (setas + pulo):** familiar, mas exige duas maos e cobre parte da tela de 180 px.
- **Inclinar o aparelho (acelerometro):** impreciso e nao funciona no navegador do desktop.
