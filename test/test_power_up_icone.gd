extends GutTest

# f522 T5: icone unico (PowerUpDesenho) para a plataforma (PowerUpIcone) e o HUD (PowerUpHud). Cenarios C614-C616.

const BRANCO := Color(1, 1, 1, 1)
const PRETO := Color(0, 0, 0, 1)


class FakeSemForma:
	extends PowerUp

	func _init() -> void:
		nome = &"fake_icone_sem_forma"
		duracao = 5.0


func _icone(tipo: StringName) -> PowerUpIcone:
	var icone := PowerUpIcone.new()
	icone.tipo = tipo
	return add_child_autofree(icone)


func _brancos(lista: Array, forma: StringName) -> int:
	var n: int = 0
	for c in lista:
		if c["forma"] == forma and c["cor"] == BRANCO:
			n += 1
	return n


# C614 [mutacao]: para cada tipo registrado, o desenho do icone da plataforma e o do HUD saem da mesma fonte
func test_icone_da_plataforma_e_hud_tem_comandos_identicos_por_tipo() -> void:
	var nomes: Array[StringName] = PowerUps.nomes()
	assert_gte(nomes.size(), 2, "fixture: camaleao e desacelera registrados")
	var divergentes: Array[StringName] = []
	for nome in nomes:
		if _icone(nome).comandos() != PowerUpHud.comandos_do_tipo(nome):
			divergentes.append(nome)
	assert_eq(divergentes.size(), 0, "icone da plataforma difere do HUD em %s" % [divergentes])
	assert_ne(
		_icone(&"camaleao").comandos(), _icone(&"desacelera").comandos(), "camaleao e desacelera tem formas distintas"
	)


# C615: tipo sem forma propria usa glifo derivado do nome, estavel; HUD so em branco e preto
func test_tipo_sem_forma_propria_tem_glifo_estavel_e_so_branco_e_preto() -> void:
	var tipo: StringName = FakeSemForma.new().nome
	var primeiro: Array = PowerUpDesenho.comandos(tipo)
	assert_eq(PowerUpDesenho.comandos(tipo), primeiro, "glifo estavel entre chamadas")
	assert_gt(primeiro.size(), 1, "o glifo tem desenho alem do fundo")
	assert_ne(primeiro, PowerUpDesenho.comandos(&"fake_icone_outro"), "glifo deriva do nome")
	for nome in [tipo, &"camaleao", &"desacelera", &"segunda_chance", &""]:
		for c in PowerUpHud.comandos_do_tipo(nome):
			var cor: Color = c["cor"]
			assert_true(cor == BRANCO or cor == PRETO, "so branco ou preto (%s): %s" % [nome, cor])


# C616: camaleao = 4 quadrantes, desacelera = ampulheta (2 triangulos); icone 32x32 centrado na origem
func test_formas_do_camaleao_e_desacelera_e_icone_16x16_centrado() -> void:
	var camaleao: Array = PowerUpDesenho.comandos(&"camaleao")
	assert_eq(_brancos(camaleao, &"rect"), 4, "camaleao: 4 quadrantes brancos")
	assert_eq(_brancos(camaleao, &"poly"), 0, "camaleao: sem poligonos")
	var desacelera: Array = PowerUpDesenho.comandos(&"desacelera")
	assert_eq(_brancos(desacelera, &"poly"), 2, "desacelera: 2 triangulos brancos")
	for c in desacelera:
		if c["forma"] == &"poly":
			assert_eq(c["pontos"].size(), 3, "cada metade da ampulheta e um triangulo")
	var icone := _icone(&"camaleao")
	assert_eq(icone.tamanho, Vector2(32, 32), "icone 32x32")
	assert_eq(icone.retangulo_local().get_center(), Vector2.ZERO, "icone centrado na origem")
	assert_eq(camaleao[0]["rect"], Rect2(0.0, 0.0, 32.0, 32.0), "o fundo cobre os 32x32 do icone")
