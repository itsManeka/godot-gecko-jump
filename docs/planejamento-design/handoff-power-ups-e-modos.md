# Handoff de design: power-ups e modos de jogo (mockups em 180 px)

Design provisorio dos 3 mockups do E4: icone de power-up sobre a plataforma, duracao no HUD e seletor de modo
(issues #16 e #17). As regras de jogo (efeito, raridade, acumulo, seed, recorde por modo) estao no
[ADR 0014](../adr/0014-power-ups-e-modos-de-jogo.md); este documento fixa so onde cada elemento desenha, em 180 px.
A arte final e outra entrega (E6, issue #18); aqui os icones e as imagens de modo sao provisorios, medidos e com
pista de forma, nao de cor. Legibilidade no aparelho fica para a f525 (QA final do epic), nao aqui.

Pre-requisito ausente: nao ha icone de power-up, imagem de modo nem slot de HUD para duracao no repo. Este
documento define os 3 mockups; nada deles esta implementado.

Base: largura logica fixa de 180 px, altura visivel minima 320, expandida em aparelho alto (1080x2400 mostra
180x400), so retrato ([ADR 0002](../adr/0002-tela-mobile-largura-180.md)). Valem as classes de ancoragem, a safe
area e as zonas ocupadas do [handoff de telas novas](handoff-telas-novas.md) (secoes 4 e 5); as zonas do menu
(Play y 147-173, Last/Best) sao as mesmas daquele handoff.

## 1. Base, fontes e paleta

### 1.1 Fontes: 16/32 (o handoff anterior esta defasado)

- Fonte: `res://fonts/alterebro-pixel-font.ttf`, a unica do projeto (`scripts/UiHelpers.gd:9`).
- Tamanhos deste handoff: **16** (texto, segundos, nome, descricao) e **32** (titulo/placar), os multiplos inteiros
  do tamanho nativo de 16 px por em (`docs/fonte-pixel-tamanho-nativo.md`; `scripts/UiHelpers.gd:9-23`).
- O [handoff de telas novas](handoff-telas-novas.md) secao 2 usa **36/26/20** e esta defasado nisso: nenhum valor
  deste handoff usa 36, 26 ou 20 como tamanho de fonte.
- Contorno preto: 2 px no tamanho 32, 1 px no tamanho 16 (`scripts/UiHelpers.gd:11`, `scenes/Stage.tscn`).

### 1.2 Paleta, botao e alvo minimo

Todo valor de cor vem de `scripts/Enums.gd` ou e o fundo de botao `#5b8a4a` (`ressources/Button.tres:8`). Nenhuma
cor nova.

| Uso               | Valor     | Origem                     |
| ----------------- | --------- | -------------------------- |
| Amarelo           | `#f6db61` | `scripts/Enums.gd:26`      |
| Verde             | `#79cf5a` | `scripts/Enums.gd:28`      |
| Azul              | `#5987e9` | `scripts/Enums.gd:30`      |
| Vermelho          | `#ec4848` | `scripts/Enums.gd:32`      |
| Branco (fallback) | `#ffffff` | `scripts/Enums.gd:33`      |
| Fundo de botao    | `#5b8a4a` | `ressources/Button.tres:8` |
| Preto (contorno)  | preto     | `scripts/UiHelpers.gd:11`  |

Botao: estilo `ressources/Button.tres` (raio 4, borda 1 px, fundo `#5b8a4a`). Alvo minimo de toque 24x24 com folga
de 2 px entre alvos vizinhos (handoff de telas novas secao 3). Cor nunca e a unica pista: as plataformas hoje se
distinguem so por cor (issue #41), e nada deste handoff assume a cor de plataforma como pista — os icones se
distinguem por forma/borda (quadrado partido, ampulheta, "+") e a barra de duracao esvazia por extensao, nao por
cor.

## 2. Mockup 1: icone de power-up sobre a plataforma

Icone 16x16 sobre uma plataforma sorteada (coleta ao pousar nela, sem toque extra; aparecimento e raridade no
[ADR 0014](../adr/0014-power-ups-e-modos-de-jogo.md)). Branco com contorno preto de 1 px; a pista e a forma, nao a
cor. Nao e alvo de toque (a coleta e o pouso), entao o minimo de 24x24 da secao 1.2 nao se aplica a ele.

| Item             | Medida                             | Detalhe                                          | Origem                                                                                                    |
| ---------------- | ---------------------------------- | ------------------------------------------------ | --------------------------------------------------------------------------------------------------------- |
| Icone (desenho)  | 16x16, centrado no x da plataforma | base 2 px acima do topo da plataforma            | `token ausente: tamanho de icone 16x16` (16 e o nativo, `scripts/UiHelpers.gd:17`); base 2 px: spec f516   |
| Fundo do icone   | branco com contorno preto de 1 px  | legivel sobre qualquer plataforma                | branco `scripts/Enums.gd:33`; contorno `scripts/UiHelpers.gd:11`                                           |
| Camaleao         | quadrado partido nas 4 cores       | 4 quadrantes: amarelo, verde, azul, vermelho     | `scripts/Enums.gd:26,28,30,32`                                                                            |
| Desacelera       | ampulheta                          | forma de ampulheta (duas piramides)              | spec f516 (arte provisoria, E6 refaz)                                                                      |
| Segunda chance   | "+"                                | sinal de mais                                    | spec f516 (arte provisoria, E6 refaz)                                                                      |

Ancoragem: o icone acompanha a plataforma (gerador de plataformas do jogo), nao a safe area. A posicao e relativa ao
topo da plataforma, entao e a mesma em 180x320 e 180x400 (a altura so muda quantas plataformas ficam visiveis).
Nunca nas linhas iniciais (raridade no [ADR 0014](../adr/0014-power-ups-e-modos-de-jogo.md)).

```
 escala aproximada: 1 coluna = 2 px; vale a tabela, nao o desenho
        ..................
        :  +---+-------+  :   icone 16x16 centrado no x da plataforma
        :  |  A |  V   |  :   Camaleao: quadrado partido nas 4 cores
        :  +---+-------+  :   (Desacelera: ampulheta; Segunda chance: "+")
        :  | Az |  Vm  |  :   base 2 px acima do topo da plataforma
        :  +---+-------+  :
        ====================   topo da plataforma
```

## 3. Mockup 2: duracao no HUD

Linha sob a pausa, y 30-46, com o icone do temporizado ativo, a barra de duracao, os segundos, a carga de Segunda
chance e o relogio do Contra o tempo. Classe **topo** (cola no topo, como Pontos e pausa): mesma medida em 180x320 e
180x400.

| Elemento                    | Retangulo          | Detalhe                                                              | Origem                                                               |
| --------------------------- | ------------------ | -------------------------------------------------------------------- | -------------------------------------------------------------------- |
| Linha (faixa)               | x 0-180, y 30-46   | sob a pausa, mesma altura do placar                                   | spec f516 (y 30-46)                                                   |
| Icone do temporizado ativo  | x 2-18, y 30-46    | mesmo desenho do mockup 1 (16x16)                                     | `token ausente: tamanho de icone 16x16`                               |
| Barra de duracao            | x 22-62, y 36-40   | 40x4; branca, moldura preta 1 px; esvazia da direita para a esquerda | branco `scripts/Enums.gd:33`; moldura `scripts/UiHelpers.gd:11`      |
| Segundos restantes          | x 66-82, y 30-46   | fonte 16, contorno 1, inteiro arredondado para cima                   | fonte `scripts/UiHelpers.gd:23`; contorno `scripts/UiHelpers.gd:11`  |
| Carga de Segunda chance     | x 90-106, y 30-46  | icone "+" 16x16; ausente sem carga                                    | icone: spec f516; posicao x: proposta do orchestrator (f516)         |
| Relogio (so Contra o tempo) | x 138-178, y 30-46 | `m:ss`, fonte 16, contorno 1, alinhado a direita                      | posicao x: proposta do orchestrator (f516); fonte `scripts/UiHelpers.gd:23` |

Ancoragem: topo, offset `o` = 30. Formula `y0 = s_top + 30`; com `s_top` = 0 fica y 30-46 em 180x320 e em 180x400
(mesma medida nas duas alturas, como o placar e a pausa).

Visibilidade (quando cada elemento some):

| Elemento                | Some quando                              |
| ----------------------- | ---------------------------------------- |
| Icone, barra e segundos | sem power-up temporizado ativo           |
| Carga                   | sem carga de Segunda chance guardada     |
| Relogio                 | fora do Contra o tempo (so nesse modo)   |

Cor nunca e a unica pista: forma do icone + barra (extensao) + numero dos segundos; a barra esvazia da direita para
a esquerda, entao a leitura nao depende so de cor.

```
 escala aproximada: 1 coluna = 5 px; mostra 180x320 (mesmo em 180x400); vale a tabela
 +------------------------------------+
 |[||]                      127       |  y 0-30   pausa (24x24, handoff telas novas secao 7.1); Pontos 32
 |[C]=====----  5     [+]       0:42  |  y 30-46  linha de duracao (mockup 2)
 +------------------------------------+
```

## 4. Mockup 3: seletor de modo

Botao `Modo: <nome>` no menu abre a tela Modos (carrossel, um modo por vez). Cinco modos no seletor (Classico +
4 novos; regras no [ADR 0014](../adr/0014-power-ups-e-modos-de-jogo.md)).

### 4.1 Botao do menu

Classe **topo** (cola no topo), offset `o` = 113. Mesma medida em 180x320 e 180x400. Estilo do `OpcoesBotao`
(`scenes/OpcoesBotao.gd`), fundo `#5b8a4a` (`ressources/Button.tres:8`).

| Item                 | Medida                       | Detalhe                                                  | Origem                                          |
| -------------------- | ---------------------------- | -------------------------------------------------------- | ----------------------------------------------- |
| Botao `Modo: <nome>` | x 34-146, y 113-137 (112x24) | fonte 16, contorno 1; 10 px acima do Play (y 147-173)    | Play: `scenes/Stage.gd:15-17`; posicao y: spec f516 |

Rotulos curtos (para caber em 112 px, proposta do orchestrator — spec f516): "Tempo" para Contra o tempo e "Diario"
para Desafio diario. O botao nao sobrepoe Play nem Opcoes (folga de 10 px entre o fim do botao e o Play) e a pausa
nao existe no menu.

O Best do menu mostra o recorde do modo escolhido; no Zen a linha Best some; no Diario mostra o resultado do dia e,
ja jogado, o Play fica desabilitado com o texto do dia (texto exato: f524).

```
 recorte do menu, y 113 a 173; vale a tabela
 +------------------------------------+
 |        [ Modo: Classico ]          |  y 113-137 (112x24)
 |                                    |
 |            [  Play  ]              |  y 147-173 (10 px abaixo do botao Modo)
 +------------------------------------+
```

### 4.2 Tela Modos (carrossel)

Bloco de **229 px** centrado na altura util (classe centro, como Pausa e Opcoes); y relativo ao topo do bloco.
Formula `y0 = s_top + (U - 229) / 2`: em 180x320 o bloco comeca em y0 = 45,5 e em 180x400 em y0 = 85,5 (o
implementador arredonda para o pixel inteiro da grade).

| Elemento                | Retangulo                            | Detalhe                                                          | Origem                                                                 |
| ----------------------- | ------------------------------------ | ---------------------------------------------------------------- | ---------------------------------------------------------------------- |
| Titulo `Modos`          | x 0-180, y 0-30                      | fonte 32, contorno 2 (padrao Pausa/Opcoes)                        | fonte `scripts/UiHelpers.gd:21`; contorno 2                              |
| Imagem do modo          | x 58-122, y 42-106 (64x64)           | placeholder: moldura branca 1 px sobre `#5b8a4a`; arte final no E6 (issue #18) | `token ausente: imagem de modo 64x64`                         |
| Setas anterior/proximo  | x 4-28 e x 152-176, y 62-86 (24x24)  | estilo do botao de pausa (`scenes/PauseBotao.gd`); ciclo (do ultimo volta ao primeiro) | 24x24: alvo minimo (handoff telas novas secao 3)      |
| Nome do modo            | x 0-180, y 114-131                   | fonte 16, contorno 1, centralizado                                | fonte `scripts/UiHelpers.gd:23`                                         |
| Descricao               | x 8-172, y 135-169                   | 2 linhas de fonte 16, centralizada                                | fonte `scripts/UiHelpers.gd:23`                                         |
| Indicador de posicao    | centrado, y 177-185                  | 5 marcas de 4x4 com folga 4; a atual tem 8x4 (forma, nao so cor)  | `token ausente: marca do indicador 4x4/8x4`                             |
| Botao `OK`              | x 34-146, y 197-229 (112x32)         | volta ao menu com o modo exibido selecionado                      | fundo `#5b8a4a` (`ressources/Button.tres:8`)                            |

Troca de modo: toque nas setas ou arrasto horizontal de pelo menos 16 px sobre a faixa da imagem/nome/descricao
(`token ausente: limiar de arrasto 16 px`; limiar: proposta do orchestrator). O modo exibido ja e o selecionado; `OK`
so fecha (proposta do orchestrator). As imagens sao placeholder neste epic; o epic de arte (E6, issue #18) ganha a
feature das imagens dos modos.

```
 escala aproximada: 1 coluna = 5 px; mostra a tela Modos (bloco de 229 px); vale a tabela
 +------------------------------------+
 |             Modos                 |  titulo 32, y 0-30
 |                                   |
 |   [<]  +--------------+  [>]      |  setas y 62-86 (24x24); imagem 64x64 y 42-106
 |        |    icone     |           |
 |        +--------------+           |
 |            Classico              |  nome 16, y 114-131
 |         Infinito com             |  descricao, 2 linhas de 16, y 135-169
 |          power-ups               |
 |           - = - - -              |  indicador, y 177-185
 |        [     OK     ]            |  y 197-229 (112x32)
 +------------------------------------+
```
