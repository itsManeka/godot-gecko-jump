extends GutTest

# f559 T7: particulas ambientais do Fundo. Fundo avulso com a tabela real (4 biomas); a deriva e dirigida a mao por
# avancar_particulas(delta) (tempo determinista); a seed do layout e constante (nenhum sorteio global).
const LARGURA := 360
const ALTURA := 640
var _sv: SubViewport
var _fundo: Fundo


func before_each() -> void:
	Global.platforms = []
	Global.iniciado = false


func after_each() -> void:
	get_tree().paused = false
	Global.platforms = []
	Global.iniciado = false


func _spawn_fundo() -> Fundo:
	var sv := SubViewport.new()
	sv.size = Vector2i(LARGURA, ALTURA)
	add_child_autofree(sv)
	var fundo := Fundo.new()
	sv.add_child(fundo)
	await wait_process_frames(1)
	_sv = sv
	_fundo = fundo
	return fundo


func _posicoes(fundo: Fundo) -> Array[Vector2]:
	var lista: Array[Vector2] = []
	for g in range(FundoBiomas.QUANTIDADE):
		for sprite: Sprite2D in fundo.particulas(g):
			lista.append(sprite.position)
	return lista


# Quantas posicoes diferem entre duas leituras (mesma ordem)
func _movidas(antes: Array[Vector2], depois: Array[Vector2]) -> int:
	var n: int = 0
	for i in range(antes.size()):
		if depois[i] != antes[i]:
			n += 1
	return n


func _total_de_particulas(fundo: Fundo) -> int:
	var total: int = 0
	for g in range(FundoBiomas.QUANTIDADE):
		total += fundo.particulas(g).size()
	return total


# --- C912 ---


func test_contagem_de_particulas_por_bioma_na_faixa_da_tabela() -> void:
	var fundo := await _spawn_fundo()
	for g in range(FundoBiomas.QUANTIDADE):
		var n: int = fundo.particulas(g).size()
		var minimo: int = 10 if g == 3 else 8
		var maximo: int = 14 if g == 3 else 10
		assert_between(n, minimo, maximo, "C912: bioma %d tem %d particulas (faixa %d-%d)" % [g, n, minimo, maximo])


# --- C913 ---


func test_particulas_nao_andam_no_menu_nem_pausadas_e_andam_com_partida_ativa_e_no_zen() -> void:
	var fundo := await _spawn_fundo()
	var inicio := _posicoes(fundo)
	Global.iniciado = false
	fundo.avancar_particulas(1.0)
	assert_eq(_movidas(inicio, _posicoes(fundo)), 0, "C913: no menu (partida nao iniciada) as particulas ficam paradas")
	Global.iniciado = true
	get_tree().paused = true
	fundo.avancar_particulas(1.0)
	assert_eq(_movidas(inicio, _posicoes(fundo)), 0, "C913: com a arvore pausada as particulas ficam paradas")
	get_tree().paused = false
	fundo.avancar_particulas(1.0)
	var andou: int = _movidas(inicio, _posicoes(fundo))
	assert_eq(andou, inicio.size(), "C913: com a partida ativa todas as particulas derivam (andaram %d de %d)" % [andou, inicio.size()])
	# Zen: scroll forcado a 0 nao para a deriva
	var scroll := ScrollLevel.new()
	autofree(scroll)
	scroll.fator_forcado = 0.0
	fundo.scroll_level = scroll
	var antes_zen := _posicoes(fundo)
	fundo.avancar_particulas(1.0)
	assert_gt(_movidas(antes_zen, _posicoes(fundo)), 0, "C913: no Zen (scroll forcado a 0) as particulas derivam")


# --- C914 ---


func test_mesma_seed_gera_as_mesmas_posicoes_e_outra_seed_gera_outras() -> void:
	var a := await _spawn_fundo()
	var posicoes_a := _posicoes(a)
	var b := await _spawn_fundo()
	assert_eq(_posicoes(b), posicoes_a, "C914: 2 Fundo com a mesma seed geram as mesmas posicoes iniciais")
	var sv := SubViewport.new()
	sv.size = Vector2i(LARGURA, ALTURA)
	add_child_autofree(sv)
	var c := Fundo.new()
	c.semente_particulas = Fundo.SEMENTE_PARTICULAS + 1
	sv.add_child(c)
	await wait_process_frames(1)
	assert_ne(_posicoes(c), posicoes_a, "C914: outra seed gera outro layout (a seed e a fonte das posicoes)")


# --- C915 ---


func test_particulas_sem_colisao_abaixo_do_jogo_e_troca_de_bioma_nao_acumula() -> void:
	var fundo := await _spawn_fundo()
	assert_lt(fundo.layer, 0, "C915: o fundo (e suas particulas) fica numa camada abaixo do jogo")
	for no: Node in fundo.find_children("*", "", true, false):
		assert_false(no is CollisionObject2D, "C915: nenhum CollisionObject2D/Area2D no fundo (%s)" % no.name)
	for g in range(FundoBiomas.QUANTIDADE):
		for sprite: Sprite2D in fundo.particulas(g):
			assert_eq(sprite.get_parent(), fundo, "C915: a particula do grupo %d e filha do fundo (camada abaixo do jogo)" % g)
			assert_lte(sprite.z_index, 0, "C915: z_index da particula nao passa do jogo")
	var total: int = _total_de_particulas(fundo)
	var filhos: int = fundo.get_child_count()
	fundo.trocar_bioma(2)
	fundo.avancar_crossfade(2.0)
	fundo.reconstruir()
	await wait_process_frames(1)
	assert_eq(_total_de_particulas(fundo), total, "C915: a troca de bioma recria o conjunto (mesmo total, sem acumular)")
	assert_eq(fundo.get_child_count(), filhos, "C915: nenhum sprite acumulado como filho apos recriar")
	assert_eq(fundo.particulas().size(), 9, "C915: o bioma 2 ativo tem as proprias particulas")
