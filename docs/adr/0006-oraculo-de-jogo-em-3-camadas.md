# 0006 — Oraculo de jogo em 3 camadas; o dono joga so o que a maquina nao julga

- **Status:** aceito
- **Data:** 2026-11-10
- **Decisores:** itsManeka + Claude
- **Supera:** o trecho `Gate de "pronto" de mudanca jogavel: o dono joga` do
  [ADR 0005](0005-desenvolvimento-headless-e-mcp-isolado.md). O resto do 0005 continua valendo.

## Contexto

O ADR 0005 deixou o dono como unico gate de mudanca jogavel, porque o `.verify.mjs` roda o jogo sem input e nao
exercita gameplay. Na pratica toda mudanca esperava uma partida manual, e a partida era gasta conferindo o que uma
maquina mede (crash, pontuacao, cor, reinicio) em vez do que so quem joga percebe.

Desde entao o projeto ganhou o que faltava para jogar sem o dono: testes GUT da logica, roteiros de input em
`test/smoke/*.smoke.json`, um smoke que joga o export web num navegador headless, um bot que joga o mesmo roteiro no
Godot nativo em duas versoes e um agente que le os prints.

## Decisao

Todo criterio de aceite de mudanca no jogo e classificado, e cada classe tem a camada que a julga:

| Classe | O que e | Quem julga |
|---|---|---|
| (a) | Sem efeito jogavel: rename, refactor, build, documentacao | Camada 1 |
| (b) | Comportamento deterministico: fisica, cor, pontuacao, spawn, save, reinicio, tela de derrota | Camada 1 (regra) e camada 2 (tela) |
| (c) | Sensacao, dificuldade, legibilidade, audio, toque no aparelho | Camada 3 |

- **Camada 1 — GUT.** Testes em `test/`, dentro do oraculo `node .verify.mjs <wave>` e do job `verify` do CI. Cobre a
  classe (a) e a regra por tras de cada criterio (b). E a unica camada exigida quando nada muda na tela.
- **Camada 2 — o jogo jogado por maquina.** Mudanca jogavel = roteiro novo ou atualizado em `test/smoke/`.
  - `game-smoke`: joga cada roteiro no export web, em navegador headless, na verificacao final da mudanca
    (`verify-wave final` do dev-workspace). Reprova erro de pagina, `SCRIPT ERROR`, recurso faltando e tela congelada.
  - `game-bot`: joga o mesmo roteiro no Godot nativo, na versao atual e na referencia (branch base da mudanca), e
    guarda os prints lado a lado.
  - Agente `game-tester`: na revisao de mudanca jogavel, classifica os criterios, estende o roteiro ate cada criterio
    (b), roda o smoke e o bot e le os prints. Criterio (b) so e aprovado com um print que o mostre.
- **Camada 3 — o dono joga.** So a classe (c), e sempre depois da camada 2 verde. Os agentes listam os itens (c) sem
  julga-los; eles chegam ao dono como pendencia manual na entrega.

Criterio "o dono joga" que cabe em (a) ou (b) esta mal classificado: vira teste GUT ou passo de roteiro. Partida do
dono nao compensa camada vermelha.

## Consequencias

- **Positivas:** o dono joga menos vezes e so para o que depende dele; crash e travamento do export web aparecem
  antes da partida; a verificacao e reproduzivel por qualquer chat limpo.
- **Negativas / trade-offs:** os roteiros de smoke viram codigo a manter (mudou input, fluxo de inicio/derrota ou
  tempos, ajuste-os). A camada 2 depende de scripts e de um agente que vivem no dev-workspace, fora deste repo. O bot
  nativo abre janela, entao nao roda no CI.
- **Riscos aceitos:** o jogo tem sorteio, entao a comparacao atual x referencia e por estrutura (cena, HUD, objetos),
  nunca por pixel ou hash. Toque real no aparelho e audio nao tem camada automatica: ficam na classe (c).

## Alternativas consideradas

- **Manter o dono como gate unico (ADR 0005):** nenhuma ferramenta a manter, mas cada mudanca espera uma partida e o
  dono confere a mao o que um teste mede melhor.
- **So GUT, sem a camada 2:** o GUT roda headless e nao ve erro que so existe no export web (recurso faltando, crash
  do wasm) nem o que aparece na tela.
- **Comparar prints por pixel ou hash contra uma imagem de referencia fixa:** com sorteio de plataformas e cores,
  toda partida difere e o teste reprovaria sem defeito.
