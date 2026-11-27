extends GutTest

# f521 T3: icone de power-up na plataforma e sorteio no gerador. O sorteio usa rng dedicado (derivado do rng da
# linha por XOR), entao o layout da seed (tipo da linha, x, cor, mecanicas) nao muda com a raridade. So as linhas
# criadas por ScrollLevel.create_new_running_platform (indice >= 1) sao elegiveis; as 5 do .tscn e as extras nao.

const NIVEL_SCENE := "res://scenes/ScrollLevel.tscn"
const GERADOR_SCENE := "res://scenes/RunningPlatforms.tscn"
const SEMENTE := 20260
const LINHAS_CRIADAS := 6
const TIPO_A: StringName = &"teste"
const TIPO_B: StringName = &"outro"

# Sequencia literal (golden) com a SEMENTE e o estado de _estado(), sem o sorteio de power-up. Regenerada quando a
# mistura da seed em RowSeed passou a ser aritmetica int64 propria (estavel entre plataformas): mesma seed, outro layout.
# f565 T7: regenerado pela producao 360x640 (estaticas em 10/180/350, spawns 420 e -60, speed 120 do estagio 0).
# Uma string por linha: tipo|speed|x:cor:mecanicas por plataforma.
const LAYOUT_HEAD: Array[String] = [
	"1|120.00|262.0:2:,104.0:3:,-54.0:3:,420.0:2:",
	"1|120.00|262.0:2:,104.0:1:,-54.0:0:,420.0:2:",
	"0|120.00|10.0:1:,180.0:2:,350.0:0:",
	"2|-120.00|98.0:2:,256.0:3:,414.0:1:,-60.0:2:",
	"0|120.00|10.0:0:,180.0:1:,350.0:0:",
	"2|-120.00|98.0:2:,256.0:3:,414.0:1:,-60.0:2:",
	"1|120.00|262.0:2:,104.0:0:,-54.0:0:,420.0:2:",
	"2|-83.75|86.6:2:PlatformSineMotion,233.1:3:PlatformSineMotion,379.7:0:PlatformColorCycle+PlatformSineMotion,-60.0:2:PlatformColorCycle",
	"0|80.00|10.0:2:PlatformColorCycle,180.0:0:PlatformColorCycle,350.0:0:",
	"0|80.00|10.0:3:,180.0:2:,350.0:3:PlatformColorCycle",
	"0|80.00|10.0:1:,180.0:1:PlatformColorCycle,350.0:1:",
	"2|-81.68|85.7:2:PlatformColorCycle+PlatformSineMotion,231.3:3:PlatformColorCycle,377.0:0:PlatformSineMotion,-60.0:2:PlatformColorCycle+PlatformSineMotion",
	"0|80.00|10.0:1:PlatformBlink,180.0:3:PlatformColorCycle,350.0:2:PlatformColorCycle",
]

var _cor_original: Enums.COLOR


func before_each() -> void:
	PlatformModifiers.restaurar_padrao()
	PowerUps.limpar()
	PowerUps.registrar(TIPO_A, PowerUpDeTeste)
	PowerUps.registrar(TIPO_B, PowerUpDeTeste)
	_cor_original = Global.cor_gecko
	Global.cor_gecko = Enums.COLOR.AZUL
	Global.platforms = []
	Global.iniciado = false
	Global.sem_derrota = false


func after_each() -> void:
	PlatformModifiers.restaurar_padrao()
	PowerUps.restaurar_padrao()
	Global.cor_gecko = _cor_original
	Global.platforms = []
	Global.iniciado = false
	Global.sem_derrota = false


func _estagio(inicio: float, mecanicas: Array[StringName], raridade: float) -> DifficultyStage:
	var estagio := DifficultyStage.new()
	estagio.progresso_inicio = inicio
	estagio.mecanicas = mecanicas
	estagio.speed_moveis = 80.0
	estagio.variacao_speed_linha = 0.25
	estagio.proporcao_cicladoras = 0.5
	estagio.proporcao_oscilantes = 0.5
	estagio.proporcao_piscantes = 0.5
	estagio.proporcao_estaticas = 0.5
	estagio.raridade_power_up = raridade
	estagio.pesos_power_ups = {TIPO_A: 1.0, TIPO_B: 1.0}
	return estagio


func _estado(raridade: float) -> DifficultyState:
	var vazio: Array[StringName] = []
	var ligadas: Array[StringName] = [
		PlatformModifiers.PLATAFORMAS_QUE_MUDAM_DE_COR,
		PlatformModifiers.MOVIMENTO_SENO,
		PlatformModifiers.PLATAFORMAS_QUE_PISCAM,
		PlatformModifiers.SPEED_POR_LINHA,
	]
	var curva := DifficultyCurve.new()
	curva.estagios = [_estagio(0.0, vazio, raridade), _estagio(0.5, ligadas, raridade)]
	var estado := DifficultyState.new(curva)
	estado.progresso_inicial = 1.0
	return estado


# Nivel com a seed da partida; as linhas do .tscn recebem o estado (raridade) se `estado_nas_iniciais`, para provar que
# so a flag (nao a raridade) as deixa sem icone. As linhas criadas (indice >= 1) sempre recebem o estado.
func _nivel(raridade: float, estado_nas_iniciais: bool = false) -> ScrollLevel:
	var nivel: ScrollLevel = load(NIVEL_SCENE).instantiate()
	var estado := _estado(raridade)
	nivel.semente = SEMENTE
	nivel.dificuldade = estado
	if estado_nas_iniciais:
		for linha in nivel.get_node("RunningPlatforms").get_children():
			linha.dificuldade = estado
	Global.set_iniciado(false)
	add_child_autofree(nivel)
	for k in LINHAS_CRIADAS:
		nivel.create_new_running_platform(InitialRows.Y_TOPO - InitialRows.ESPACAMENTO * (k + 1))
	await wait_physics_frames(3)
	return nivel


func _plataformas(linha: Node) -> Array:
	var filhas: Array = []
	for filha in linha.get_children():
		if filha is Platform:
			filhas.append(filha)
	return filhas


func _tem_icone(plataforma) -> bool:
	return plataforma.tipo_power_up != &"" and is_instance_valid(plataforma.icone_power_up)


func _layout(nivel: ScrollLevel) -> Array[String]:
	var saida: Array[String] = []
	for linha in nivel.running_platforms.get_children():
		var partes := PackedStringArray()
		for p in _plataformas(linha):
			var mecanicas := PackedStringArray()
			for m in p._modificadores:
				mecanicas.append(String(m.get_script().get_global_name()))
			partes.append("%.1f:%d:%s" % [p.position.x, p.color, "+".join(mecanicas)])
		saida.append("%d|%.2f|%s" % [int(linha.platform_type), linha.speed, ",".join(partes)])
	return saida


# Indices das linhas que diferem do esperado (mensagem curta, sem dump do array)
func _divergentes(atual: Array[String], esperado: Array[String]) -> Array[int]:
	var indices: Array[int] = []
	for i in maxi(atual.size(), esperado.size()):
		if i >= atual.size() or i >= esperado.size() or atual[i] != esperado[i]:
			indices.append(i)
	return indices


# Mapa "indice da linha/indice da plataforma" -> tipo de power-up (so quem tem icone)
func _icones(nivel: ScrollLevel) -> Dictionary:
	var mapa: Dictionary = {}
	var i: int = 0
	for linha in nivel.running_platforms.get_children():
		var j: int = 0
		for p in _plataformas(linha):
			if _tem_icone(p):
				mapa["%d/%d" % [i, j]] = p.tipo_power_up
			j += 1
		i += 1
	return mapa


func _layout_com(raridade: float, registrar: bool) -> Array[String]:
	if not registrar:
		PowerUps.limpar()
	var nivel: ScrollLevel = await _nivel(raridade)
	return _layout(nivel)


func test_c546_layout_da_seed_identico_ao_head_com_raridade_0_raridade_1_e_sem_sorteio() -> void:
	var rotulos: Array[String] = ["raridade 0", "raridade 1", "raridade 1 sem tipo registrado"]
	var layouts: Array = []
	layouts.append(await _layout_com(0.0, true))
	layouts.append(await _layout_com(1.0, true))
	layouts.append(await _layout_com(1.0, false))
	for n in layouts.size():
		var atual: Array[String] = layouts[n]
		assert_eq(
			atual.size(),
			LAYOUT_HEAD.size(),
			"linhas geradas (%s) difere do HEAD; ATUAL=%s" % [rotulos[n], " ## ".join(atual)]
		)
		assert_eq(
			_divergentes(atual, LAYOUT_HEAD).size(),
			0,
			"layout (%s) divergiu do HEAD nas linhas %s" % [rotulos[n], _divergentes(atual, LAYOUT_HEAD)]
		)


func test_c547_raridade_1_so_linhas_de_fluxo_tem_icone_e_flag_so_no_create_new_running_platform() -> void:
	var nivel: ScrollLevel = await _nivel(1.0, true)
	var linhas: Array = nivel.running_platforms.get_children()
	var iniciais: int = linhas.size() - LINHAS_CRIADAS
	assert_gte(iniciais, 5, "as 5 linhas do .tscn (mais as extras) existem antes das criadas")
	for i in linhas.size():
		var linha: Node = linhas[i]
		var plataformas := _plataformas(linha)
		assert_gt(plataformas.size(), 0, "linha %d tem plataformas" % i)
		if i < iniciais:
			assert_false(linha.power_ups_elegivel, "linha inicial %d nunca e elegivel" % i)
		else:
			assert_true(linha.power_ups_elegivel, "linha de fluxo %d e elegivel" % i)
		for p in plataformas:
			assert_eq(_tem_icone(p), i >= iniciais, "icone na linha %d (inicial = sem, fluxo = com)" % i)


func test_c548_mesma_seed_duas_vezes_mesmos_icones_e_tipos() -> void:
	var primeiro: ScrollLevel = await _nivel(1.0)
	var a: Dictionary = _icones(primeiro)
	primeiro.queue_free()
	await wait_physics_frames(2)
	Global.platforms = []
	var segundo: ScrollLevel = await _nivel(1.0)
	var b: Dictionary = _icones(segundo)
	assert_gt(a.size(), 10, "raridade 1 gera icones em varias plataformas")
	var tipos: Dictionary = {}
	for chave in a:
		tipos[a[chave]] = true
	assert_eq(tipos.size(), 2, "os dois tipos registrados aparecem no sorteio")
	assert_eq(a.size(), b.size(), "mesma seed: mesma quantidade de icones")
	var divergentes: Array = []
	for chave in a:
		if not b.has(chave) or b[chave] != a[chave]:
			divergentes.append(chave)
	assert_eq(divergentes.size(), 0, "mesma seed: icone/tipo diferente em %s" % [divergentes])


func test_c549_sem_derrota_com_raridade_1_nenhum_icone_nasce() -> void:
	Global.sem_derrota = true
	var nivel: ScrollLevel = await _nivel(1.0)
	var com_icone: int = 0
	var total: int = 0
	for linha in nivel.running_platforms.get_children():
		for p in _plataformas(linha):
			total += 1
			if _tem_icone(p):
				com_icone += 1
	assert_gt(total, 10, "a partida gerou plataformas")
	assert_eq(com_icone, 0, "sem_derrota: nenhum icone nasce (D5)")


func test_c550_icone_node2d_sem_colisao_16x16_centrado_base_2px_acima_e_global_platforms_igual() -> void:
	var sem: ScrollLevel = await _nivel(0.0)
	var contagem_sem: int = Global.platforms.size()
	sem.queue_free()
	await wait_physics_frames(2)
	Global.platforms = []
	var com: ScrollLevel = await _nivel(1.0)
	assert_eq(Global.platforms.size(), contagem_sem, "icone nao entra em Global.platforms")
	var verificadas: int = 0
	for linha in com.running_platforms.get_children():
		for p in _plataformas(linha):
			if not _tem_icone(p):
				continue
			var icone: Node2D = p.icone_power_up
			assert_false(icone is CollisionObject2D, "icone nao e corpo de colisao")
			assert_eq(icone.get_children().size(), 0, "icone sem filhos (sem CollisionShape2D)")
			assert_eq(icone.position.x, 0.0, "icone centrado no x da plataforma")
			var topo: float = p.topo_visual()
			assert_eq(topo, -16.0, "topo do visual = topo do NinePatchRect (-16)")
			assert_eq(icone.position.y + 16.0, topo - 4.0, "base do icone 4 px (2 px em 1x) acima do topo da plataforma")
			assert_eq(icone.get("tamanho"), Vector2(32, 32), "icone 32x32 (16x16 em 1x)")
			verificadas += 1
	assert_gt(verificadas, 0, "ao menos um icone verificado")


func test_c551_sem_rng_na_linha_sorteia_pelo_ramo_aleatorio_proprio() -> void:
	var gerador: Node2D = load(GERADOR_SCENE).instantiate()
	gerador.platform_type = Enums.PLATFORM_TYPE.STATIC
	gerador.dificuldade = _estado(1.0)
	gerador.power_ups_elegivel = true
	gerador.position = Vector2(0, 100)
	add_child_autofree(gerador)
	var plataformas := _plataformas(gerador)
	assert_eq(plataformas.size(), 3, "linha estatica sem rng gera 3 plataformas")
	for p in plataformas:
		assert_true(_tem_icone(p), "sem rng e raridade 1: toda plataforma elegivel tem icone")
