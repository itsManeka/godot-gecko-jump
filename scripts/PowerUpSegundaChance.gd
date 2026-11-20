class_name PowerUpSegundaChance
extends PowerUp

# Segunda chance: power-up de carga (duracao 0, nunca temporizado, maximo 1 guardada).
# O efeito de mundo (salvar a partida na linha de derrota e reposicionar o gecko) e da Stage,
# nao deste RefCounted: os hooks ficam neutros e o PowerUpState so guarda a carga.


func _init() -> void:
	nome = &"segunda_chance"
	duracao = 0.0


func ao_ativar() -> void:
	pass


func ao_encerrar() -> void:
	pass
