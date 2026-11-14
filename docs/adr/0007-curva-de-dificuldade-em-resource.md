# 0007 — Curva de dificuldade progressiva em Resource `.tres`

- **Status:** aceito
- **Data:** 2026-11-12
- **Decisores:** itsManeka + Claude

## Contexto

A dificuldade era constante: scroll, velocidade das plataformas moveis, K da garantia de cor e proporcao de
plataformas estaticas eram literais espalhados pelos scripts. No QA do E2 o jogo ficou facil demais com a garantia de
cor (#10). Faltava uma forma de a dificuldade subir com a partida, ajustavel sem editar codigo e coberta por teste.

## Decisao

- **Curva em Resource:** `ressources/curva_dificuldade.tres`, um `DifficultyCurve` com um array de `DifficultyStage`.
  Esse arquivo e a fonte unica dos valores: o inspector edita, e os testes carregam o mesmo `.tres` de producao.
- **Estagios com interpolacao:** entre dois estagios, scroll, velocidade e proporcao de estaticas interpolam de forma
  continua. K e inteiro: piso (`floor`) do valor interpolado, com piso no K do estagio 0.
- **Progresso:** `max(pontos / N_pontos, segundos / N_segundos)`, saturado em 1. Os dois N ficam no proprio `.tres`.
  Em 1 a curva fica no teto (plato), que e calibrado para cerca de 3 minutos de partida.
- **Estado por partida:** `DifficultyState`, criado pelo `Stage` (nao e autoload). Zera ao recarregar a cena e so
  acumula tempo com a partida em andamento. Entrega um snapshot imutavel; consumidor sem estado injetado usa o estagio 0.
- **Injecao:** o `Stage` cria o estado; o `ScrollLevel` recebe o snapshot e repassa a cada linha. Scroll e lido a cada
  frame; velocidade e K sao lidos quando a plataforma nasce, para a linha manter a velocidade ate sair da tela.
- **Mecanicas:** cada estagio tem `mecanicas: Array[StringName]`, que liga mecanicas de forma discreta na fronteira do
  estagio. As plataformas menores e que caem estao no [ADR 0009](0009-modificadores-de-plataforma.md). A que muda de
  cor ([ADR 0010](0010-plataformas-cicladoras.md)) usa `proporcao_cicladoras` e `periodo_ciclo`, campos por estagio que
  interpolam como a largura. As proximas mecanicas ganham ADR proprio quando forem implementadas.
- Os numeros ficam no `.tres`, nao neste ADR.

## Consequencias

- **Positivas:** ajustar a dificuldade e editar o `.tres`, sem tocar codigo. Teste e jogo leem o mesmo arquivo, entao
  nao divergem. A alcancabilidade da garantia de cor e testada em cada estagio e no teto.
- **Negativas / trade-offs:** o `.tres` e mais um recurso que pode quebrar no import ou no export; o valor de cada
  parametro nao aparece lendo o script.
- **Riscos aceitos:** o teto pode ficar injusto. A calibracao final depende do playtest do dono no QA do epic.

## Alternativas consideradas

- **Curva em `const` GDScript (plano B):** mesma logica e mesma interface de avaliacao, sem Resource. Fica como saida
  se o `.tres` atrapalhar o GUT ou o export web: a curva vira `const` no `DifficultyCurve.gd` e o `.tres` e removido.
- **Contrato `PlatformModifier` por estagio:** cobriria as mecanicas futuras agora, mas sem caso real o contrato seria
  chute. Foi desenhado na primeira mecanica real ([ADR 0009](0009-modificadores-de-plataforma.md)).
- **Autoload guardando o estado:** sobrevive ao reload da cena e exige zerar a mao a cada partida. Rejeitado: o estado
  pertence a partida, nao ao jogo.
