# ADRs — Gecko Jump

Architecture Decision Records. Numeracao sequencial, nunca reutilizada. Superar um ADR = criar um novo e marcar o
antigo como "superado por".

| #                                                      | Decisao                                                                           | Status                                                     |
| ------------------------------------------------------ | --------------------------------------------------------------------------------- | ---------------------------------------------------------- |
| [0001](0001-migrar-para-godot-4.md)                    | Migrar de Godot 3.6 para Godot 4.7                                                | aceito                                                     |
| [0002](0002-tela-mobile-largura-180.md)                | Tela mobile: largura logica 180 px, altura expandida, escala inteira              | aceito; evoluido por 0015                                  |
| [0003](0003-controle-de-um-polegar.md)                 | Controle de toque de um polegar (toque = pulo diagonal, segurar = andar)          | aceito; superado (esquema tap x segurar de toque) por 0013 |
| [0004](0004-arte-no-aseprite-com-rascunho-por-ia.md)   | Arte no Aseprite compilado do fork pessoal, rascunho por IA                       | aceito; rascunho por IA evoluido por 0015                  |
| [0005](0005-desenvolvimento-headless-e-mcp-isolado.md) | Desenvolvimento pela CLI headless; MCPs de jogo so em agentes dedicados           | aceito; superado (trecho do gate de "pronto") por 0006     |
| [0006](0006-oraculo-de-jogo-em-3-camadas.md)           | Oraculo de jogo em 3 camadas; o dono joga so o que a maquina nao julga            | aceito                                                     |
| [0007](0007-curva-de-dificuldade-em-resource.md)       | Curva de dificuldade progressiva em Resource `.tres`, avaliada por pontos e tempo | aceito                                                     |
| [0008](0008-pausa-por-tree-paused.md)                  | Pausa por `get_tree().paused`, nao por `Global.iniciado`                          | aceito                                                     |
| [0009](0009-modificadores-de-plataforma.md)            | Modificadores de plataforma por contrato; largura por shape duplicado             | aceito                                                     |
| [0010](0010-plataformas-cicladoras.md)                 | Plataformas cicladoras: cor prevista no tempo, com trava e aviso visivel          | aceito                                                     |
| [0011](0011-movimento-de-plataformas.md)               | Movimento de plataformas: oscilacao como desvio de velocidade, sem inversao, so x | aceito                                                     |
| [0012](0012-plataformas-que-piscam.md)                 | Plataformas que piscam: somem e voltam em ritmo fixo, com aviso e trava           | aceito                                                     |
| [0013](0013-modos-de-toque-alternaveis.md)             | Modos de toque alternaveis: A e B selecionaveis, B padrao                         | aceito                                                     |
| [0014](0014-power-ups-e-modos-de-jogo.md)              | 3 power-ups e 5 modos de jogo no seletor; seed do Desafio diario por data UTC     | aceito                                                     |
| [0015](0015-direcao-de-arte-fonte-comercial-e-audio-dinamico.md) | Direcao de arte, fonte comercial livre (`m5x7`), menu remodelado e audio dinamico | aceito                                                     |
