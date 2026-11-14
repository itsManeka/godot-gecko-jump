# 0009 — Modificadores de plataforma por contrato, com largura por shape duplicado

- **Status:** aceito
- **Data:** 2026-11-13
- **Decisores:** itsManeka + Claude

## Contexto

A curva de dificuldade ([ADR 0007](0007-curva-de-dificuldade-em-resource.md)) passou a ligar mecanicas por estagio
pelo campo `mecanicas`. As duas primeiras mecanicas mudam a plataforma: uma nasce mais estreita e outra desmorona
pouco depois do pouso do gecko. O ADR 0007 deixou o contrato de modificador para a primeira mecanica real, porque sem
caso concreto ele seria chute. As mecanicas seguintes (cor, movimento, pisca) vao reaproveitar o mesmo contrato.

Restricoes que moldam a decisao:

- A cena `Platform.tscn` compartilha um unico `RectangleShape2D` entre todas as instancias: mudar o tamanho numa
  instancia mudaria todas.
- O `CollisionShape2D` vive no corpo fisico do `CharacterBody2D`; escalar esse corpo distorce a forma fisica.
- O `AreaCheck` da plataforma dispara o `area_exited` do gerador, e a distancia dele define o espacamento entre
  linhas. Mudar a largura da plataforma nao pode mudar esse espacamento.
- O pixel art usa filtro Nearest e escala inteira: nenhum sprite pode ser escalado de forma fracionaria.

## Decisao

- **Contrato `PlatformModifier`** (`scripts/PlatformModifier.gd`, `RefCounted`, sem cena e sem `Global`): tres hooks
  vazios, `ao_criar(plataforma, snapshot)`, `ao_pousar(plataforma, snapshot)` e `ao_processar(plataforma, delta)`.
  Um modificador sobrescreve so o hook que usa.
- **Registro `PlatformModifiers`** (`scripts/PlatformModifiers.gd`, estatico): `resolver(snapshot)` mapeia cada nome de
  `snapshot.get_mecanicas()` para um modificador, na mesma ordem do `.tres`. Os nomes sao constantes unicas do registro
  (`PLATAFORMAS_MENORES`, `PLATAFORMAS_QUE_CAEM`). Nome desconhecido gera aviso (`push_warning`) e e ignorado: um typo
  no `.tres` nunca derruba o jogo.
- **Quem despacha e a plataforma.** O gerador resolve a lista no nascimento da linha (mesmo ponto em que le velocidade
  e K) e entrega a lista a cada plataforma com `definir_modificadores(lista, snapshot)`, antes do `add_child`. A
  plataforma despacha `ao_criar` no proprio `_ready`, porque os filhos `@onready` so existem la. `ao_pousar` e
  `ao_processar` sao despachados pela plataforma em cada evento.
- **Linhas com `garantir_cor_inicial` nao recebem o modificador de desmoronar.** A linha inicial garante uma cor
  alcancavel no comeco da partida, entao nunca pode desaparecer. O gerador pergunta ao proprio modificador
  (`vale_em_linha_inicial()`, padrao `true`; o de desmoronar devolve `false`), sem conhecer a classe concreta.
- **Largura por shape duplicado.** `Platform.set_largura(w)` duplica o `RectangleShape2D` da instancia e ajusta so
  `size.x`; o sub-recurso da cena nao muda. O visual recorta o `Sprite2D` com `region_rect` centrado na largura
  (sem escala). **Nao** se usa `scale` no corpo fisico. `AreaCheck` e `VisibleOnScreenNotifier2D` ficam com o tamanho
  original, porque definem margens do gerador, nao a largura da plataforma.
- **Largura e atraso lidos no nascimento**, como velocidade: a linha mantem o valor enquanto estiver na tela.
  Mecanica liga e desliga na fronteira do estagio (ela nao interpola); largura e atraso interpolam como scroll e
  velocidade.
- **Gatilho do desmoronamento = pouso confirmado.** O `Player` chama `notificar_pouso()` da `actual_platform` no bloco
  `is_on_floor() and can_change_color`, antes de trocar a cor. Nenhum gatilho em `body_entered`, porque esse sinal
  dispara tambem quando o gecko atravessa a plataforma subindo. O hook valida a plataforma com `is_instance_valid`
  antes de usar.
- **Desmoronamento em tres etapas.** `iniciar_desmoronamento(atraso)` inicia a contagem uma unica vez: pouso repetido
  nao estende o prazo. Nos ultimos 0,3 s a plataforma treme no eixo X, sem som e sem asset novo (aviso que nao depende
  de cor). Ao fim, a colisao e desligada de vez, a flag `desmoronada` fica verdadeira e a plataforma sai da arvore.
  `player_color_changed` respeita a flag e nunca reativa a colisao de uma plataforma desmoronada.
- **Modificador com estado por instancia:** a partir da mecanica de cor, existe modificador que guarda estado
  proprio (sequencia e relogio). Ele nao entra na lista compartilhada da linha: o gerador cria uma instancia por
  plataforma cicladora. Os tres hooks e o despacho acima valem para os dois tipos. Ver
  [ADR 0010](0010-plataformas-cicladoras.md).
- **Modo `Global.sem_derrota`:** a largura aplica e o desmoronamento nao age. Isso mantem o smoke deterministico, e a
  mecanica e coberta por teste de cena. Nenhuma mecanica existente tratava `sem_derrota`; esse comportamento e novo.

## Consequencias

- **Positivas:** adicionar uma mecanica de plataforma e criar um script `PlatformModifier` e registrar o nome, sem
  mexer em gerador nem em `Platform`. Os numeros continuam no `.tres`. Largura e espacamento entre linhas sao
  independentes, e o teste do espacamento nao precisa mudar.
- **Negativas / trade-offs:** o registro e estatico e global; testes precisam de `limpar()` e `restaurar_padrao()`
  para usar fakes. A lista de modificadores e chamada a cada frame de fisica mesmo quando um modificador nao precisa
  dele (custo pequeno, aceito pela simplicidade). A largura e definida no nascimento da plataforma; quem quiser mudar
  a largura de uma plataforma ja em cena precisa chamar `set_largura` de novo.
- **Riscos aceitos:**
  - O pouso usa `actual_platform`, a ultima plataforma detectada pelo `body_entered`. Se o gecko sobrepoe duas
    plataformas da mesma cor no mesmo frame, a que desmorona pode nao ser a que sustenta. Se isso aparecer no
    teste de cena, o pouso passa a conferir o colisor do chao (`get_last_slide_collision`).
  - Sem arte de rachadura, o aviso e so o tremor. Se a legibilidade de "esta plataforma vai cair" for ruim, a
    decisao volta para o playtest do dono.
  - Os valores de largura e de atraso sao sensacao de jogo, a confirmar jogando os estagios com o parametro de
    progresso de debug. O teste de alcancabilidade garante o limite fisico, nao o gosto.

## Alternativas consideradas

- **Constantes no modificador:** rejeitado. Esconde o valor do inspector e quebra a regra de que os numeros ficam no
  `.tres` ([ADR 0007](0007-curva-de-dificuldade-em-resource.md)).
- **`scale` no `CharacterBody2D`:** rejeitado. Escala o corpo fisico e distorce a forma de colisao.
- **Shape compartilhado com `resource_local_to_scene`:** descartado em favor de duplicar o shape no `set_largura`. A
  duplicacao e explicita no codigo e nao depende de flag de cena.
- **Escalar so o `Sprite2D`:** rejeitado. Distorce o pixel art e deixa a colisao com a largura antiga.
- **9-slice para a plataforma estreita:** rejeitado nesta mecanica. Exige margem na arte, e o recorte centrado cobre o
  caso sem asset novo.
- **Gatilho em `body_entered`:** rejeitado. Dispara ao atravessar a plataforma subindo, o que desmontaria a plataforma
  sem o gecko ter pousado.
- **Aviso so por cor:** rejeitado. Cor nunca e a unica pista (acessibilidade); o tremor de movimento complementa.
- **Modificadores como nos filhos da cena:** rejeitado. Cada plataforma ganharia nos extras e o contrato dependeria
  da arvore; `RefCounted` mantem o contrato testavel sem cena e sem `Global`.
