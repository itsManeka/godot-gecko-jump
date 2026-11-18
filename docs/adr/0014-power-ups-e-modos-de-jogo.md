# 0014 — Power-ups e modos de jogo: 3 power-ups e 5 modos no seletor, seed do Desafio diario por data UTC

- **Status:** aceito
- **Data:** 2026-11-18
- **Decisores:** itsManeka + Claude

## Contexto

O epic E4 entrega power-ups (#16) e modos de jogo (#17), mas a lista, as regras de aparecimento e de acumulo, a seed do
Desafio diario e o recorde de cada modo estavam em aberto: sem elas as features f521 a f524 nao tem criterio testavel. O
dono aprovou lista e regras no brainstorming de 2026-11-18 (feature f516); este ADR registra o aprovado, e os GUT das
features seguintes citam as frases daqui.

Restricoes que moldam a decisao:

- O jogo tem um so modo de partida, o infinito: plataformas geradas por `scenes/RunningPlatforms.gd`, com a cor das
  moveis sorteada a partir da cor do gecko (`scenes/RunningPlatforms.gd:156-169`) e recorde em `user://best_score.cfg`
  (`scripts/BestScoreStore.gd:9-11`). Os modos novos convivem com esse gerador.
- A pausa e `get_tree().paused` ([ADR 0008](0008-pausa-por-tree-paused.md)): nenhum no pausavel anda nem conta tempo,
  entao os contadores dos power-ups congelam junto, sem codigo novo de pausa.
- "Modo de toque" ja nomeia o esquema A/B das Opcoes ([ADR 0013](0013-modos-de-toque-alternaveis.md)): o vocabulario do
  seletor novo tem de distinguir "modo de jogo" de "modo de toque".
- A dificuldade e regida por estagio (`DifficultyState`, injetada em `scenes/RunningPlatforms.gd:24-25`): nenhum modo
  rebalanceia a curva.

## Decisao

- **Tres power-ups entram; o "Escolha de cor" fica fora.** Tipo, efeito e valor inicial de cada um:

| Power-up       | Tipo                   | Efeito                                                                       | Valor inicial (em `.tres`, rebalanceavel)           |
| -------------- | ---------------------- | ---------------------------------------------------------------------------- | --------------------------------------------------- |
| Camaleao       | temporizado            | o gecko pisa em plataforma de qualquer cor                                   | 5 s                                                 |
| Desacelera     | temporizado            | scroll forcado reduzido                                                      | 5 s, fator 0,5 (proposta; rebalanceavel em `.tres`) |
| Segunda chance | carga unica, sem tempo | salva de uma queda: o gecko reaparece na plataforma mais proxima da cor dele | 1 carga, maximo 1 guardada                          |

- **Aparecimento.** Icone sobre uma plataforma sorteada; coleta ao pousar nela. Sem toque extra.
- **Raridade.** Cerca de 1 a cada 25 plataformas (4%), configuravel por estagio no `.tres`; Segunda chance com metade da
  chance dos outros (proposta: 1,6% Camaleao, 1,6% Desacelera, 0,8% Segunda chance; rebalanceavel em `.tres`). Nunca nas
  linhas iniciais.
- **Acumulacao.** 1 temporizado + 1 carga. Coletar um temporizado com outro ativo substitui o ativo; coletar o mesmo
  reinicia o tempo. A Segunda chance fica guardada a parte (maximo 1; coletar com 1 guardada nao soma).
- **Pausa.** `tree.paused` congela o contador dos temporizados ([ADR 0008](0008-pausa-por-tree-paused.md)). Partida nova
  zera tudo.
- **Cinco modos de jogo no seletor** (o Classico e o infinito atual; 4 modos novos). Regra, power-ups e recorde:

| Modo           | Regra                                                                                                                                          | Power-ups | Recorde                                                                        |
| -------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ------------------------------------------------------------------------------ |
| Classico       | infinito atual (geracao `scenes/RunningPlatforms.gd:60-82`)                                                                                    | sim       | herda `user://best_score.cfg` (`score.best`; `scripts/BestScoreStore.gd:9-11`) |
| Puro           | infinito atual, identico ao Classico de hoje (geracao `scenes/RunningPlatforms.gd:60-82`, cor das moveis `scenes/RunningPlatforms.gd:156-169`) | nao       | proprio, comeca em 0                                                           |
| Desafio diario | seed = data UTC (secao da seed abaixo); uma tentativa por dia                                                                                  | nao       | resultado do dia                                                               |
| Zen            | sem scroll forcado; ao cair, o gecko volta a ultima plataforma segura e a partida nao encerra; sai pela pausa                                  | nao       | nao grava (mostra so os pontos da sessao)                                      |
| Contra o tempo | 60 s de relogio (proposta; rebalanceavel em `.tres`); cair encerra a partida ("errou, acabou"); fim tambem quando o relogio zera               | sim       | proprio (pontos em ate 60 s)                                                   |

- **Seed do Desafio diario: data UTC.** A seed do modo e a data (UTC) do dia: duas geracoes com a mesma data produzem as
  mesmas plataformas normais (posicao, tipo, mecanica e cor das estaticas) e datas diferentes divergem. A cor das moveis
  nao entra na seed: a cor das moveis segue o gecko (`scenes/RunningPlatforms.gd:156-169`). **Uma tentativa por dia**,
  gasta ao iniciar a partida. A tentativa e local ate o E5 e burlavel (trocar a data ou apagar o save libera de novo);
  aceito pelo dono. Depois do ranking online (E5, issue #29), o Desafio diario aparece so com o jogador conectado.
- **Vocabulario.** "Modo de jogo" e o seletor deste ADR; "modo de toque" e o esquema A/B das Opcoes
  ([ADR 0013](0013-modos-de-toque-alternaveis.md), renomeado na f520). O botao do menu e o titulo da tela usam
  "Modo"/"Modos" so para modo de jogo.
- **Dificuldade por estagio.** A curva de dificuldade por estagio vale igual em todos os modos: nenhum modo acelera nem
  atrasa a progressao.
- **Regras testaveis em GUT (uma frase cada).** As frases abaixo sao o criterio dos GUT das f521 a f524:
  - **Camaleao:** com o power-up ativo, pousar em plataforma de cor diferente da do gecko conta como pouso valido e
    pontua; 5 s de tempo de jogo depois, a regra de cor volta.
  - **Desacelera:** com o power-up ativo, o deslocamento do scroll por frame e o do estagio vezes 0,5; ao expirar volta
    ao do estagio; o relogio do Contra o tempo nao desacelera.
  - **Segunda chance:** ao cruzar a linha de derrota com 1 carga, a partida nao termina, a carga vai a 0 e o gecko fica
    sobre a plataforma visivel mais proxima da cor dele; sem carga, o cruzamento encerra a partida (derrota padrao).
  - **Aparecimento:** com raridade 0 nenhum icone nasce e com 1 toda plataforma elegivel tem icone (seed fixa); a linha
    inicial nunca tem; o tipo sorteado respeita os pesos.
  - **Acumulo:** coletar B com A ativo deixa so B ativo com duracao cheia; coletar A com A ativo reinicia a duracao; a
    carga nao passa de 1 e nao e afetada por temporizados.
  - **Puro, Zen e Desafio diario:** nenhum icone nasce, com qualquer raridade.
  - **Classico (recorde):** com `best_score.cfg` valendo N, o Best do Classico e N; Puro, Contra o tempo e Diario
    comecam em 0; gravar num modo nao altera o outro.
  - **Desafio diario:** duas geracoes com a mesma data UTC produzem as mesmas plataformas normais; datas diferentes
    divergem; com o dia (UTC) ja jogado, o modo nao inicia partida; a virada do dia UTC libera de novo e zera o
    resultado do dia.
  - **Zen:** o scroll forcado e 0; cruzar a linha de queda reposiciona o gecko na ultima plataforma pisada sem
    encerrar a partida; nenhum recorde e gravado.
  - **Contra o tempo:** a partida termina quando o relogio chega a 0 ou na queda, o que vier antes; o recorde do modo
    e o maior total de pontos; a pausa congela o relogio.

## Consequencias

- **Positivas:** cada power-up, modo e regra ganha uma frase observavel, e os GUT das f521 a f524 citam este ADR em vez
  de redecidir regra; o Classico preserva o recorde existente em `user://best_score.cfg`
  (`scripts/BestScoreStore.gd:9-11`) e o Puro assume a regua sem power-ups a partir de 0; a seed por data UTC da o mesmo
  desafio a todos os jogadores no mesmo dia, sem servidor; a pausa existente
  ([ADR 0008](0008-pausa-por-tree-paused.md)) congela os contadores sem codigo novo.
- **Negativas / trade-offs:** a tentativa unica do Desafio diario e local e burlavel (troca de data ou apagamento do
  save) ate o E5 — aceito pelo dono; os valores de proposta (fator 0,5, pesos 1,6/1,6/0,8, 60 s) pedem rebalanceamento
  em `.tres` apos o playtest; o Classico ganha power-ups e o recorde herdado muda de sentido (o Puro guarda a regua sem
  power-ups a partir de 0).
- **Riscos aceitos:** Camaleao e Desacelera podem quebrar a garantia de alcancabilidade das plataformas (GUT de
  alcancabilidade com power-up ativo na f521); Segunda chance sem plataforma da cor visivel: regra de fallback na f522
  (proposta: plataforma mais proxima, o gecko assume a cor dela); o Desafio diario aparece so conectado depois do E5
  (item na issue #29).

### Consequencias para o epic

Agrupamento do epic: 3 power-ups e 4 modos novos (5 no seletor com o Classico); a f522 entrega os power-ups em
2 blocos (A: Camaleao + Desacelera; B: Segunda chance) e a f524 entrega os modos em 3 blocos (A: Puro + Contra o
tempo; B: Zen; C: Desafio diario, depende da f517).

## O que ficou aberto

- **Tentativa unica do Desafio diario:** local e burlavel; a issue #29 (ranking online do E5) ganha o item que fecha a
  brecha (troca de data/apagamento do save) e restringe o modo a jogadores conectados depois do E5.
- **Arte provisoria:** icone de power-up 16x16 e imagem de modo 64x64 (placeholder); o E6 (issue #18) faz a arte final.
- **Fallback da Segunda chance:** sem plataforma da cor do gecko visivel, a f522 define a regra (proposta: plataforma
  mais proxima, o gecko assume a cor dela).

## Alternativas consideradas

- **"Escolha de cor" como quarto power-up:** fora; o dono manteve os 3 aprovados (feature f516).
- **Fixar a cor das moveis na seed:** rejeitada; a cor das moveis segue o gecko (`scenes/RunningPlatforms.gd:156-169`);
  a seed fixa so as plataformas normais.
- **Tentativa unica do Desafio diario validada no servidor desde ja:** rejeitada por enquanto; a validacao local e
  burlavel e aceita ate o ranking online (E5, issue #29).
- **Puro herdando o recorde do Classico:** rejeitada; com o Classico ganhando power-ups, o recorde herdado muda de
  sentido, e o Puro comeca em 0 para guardar a regua sem power-ups.
