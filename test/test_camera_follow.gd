extends GutTest

# T1 de f489-camera-acompanha-gecko-no-alto-46: funcoes puras do limite da camera (CameraFollow).
# Valores esperados vem do criterio de aceite do 01 (T1), nunca copiados da implementacao.

const CameraFollowScript := preload("res://scripts/CameraFollow.gd")


# C429: limite_y(320) == 128 (fracao 0,40 da altura visivel)
func test_limite_y_altura_320_e_128() -> void:
	assert_almost_eq(CameraFollowScript.limite_y(320.0), 128.0, 0.0001)


# C430: limite_y(400) == 160 (proporcional, altura de test_scroll_level_altura.gd)
func test_limite_y_altura_400_e_160() -> void:
	assert_almost_eq(CameraFollowScript.limite_y(400.0), 160.0, 0.0001)


# C431: limite_y(462) == 184.8 (fracao 0,40, comparado com tolerancia)
func test_limite_y_altura_462_e_184_8() -> void:
	assert_almost_eq(CameraFollowScript.limite_y(462.0), 184.8, 0.0001)


# C427: acima do limite devolve 28; acima do topo com y negativo devolve 163.4
func test_excesso_gecko_acima_do_limite_e_do_topo_y_negativo() -> void:
	assert_eq(CameraFollowScript.excesso(100.0, 128.0), 28.0)
	assert_almost_eq(CameraFollowScript.excesso(-35.4, 128.0), 163.4, 0.0001)


# C428: no limite e abaixo do limite nunca e negativo
func test_excesso_no_limite_e_abaixo_nunca_negativo() -> void:
	assert_eq(CameraFollowScript.excesso(128.0, 128.0), 0.0)
	assert_eq(CameraFollowScript.excesso(200.0, 128.0), 0.0)
