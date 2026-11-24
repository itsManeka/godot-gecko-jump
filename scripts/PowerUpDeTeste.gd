class_name PowerUpDeTeste
extends PowerUp

# Power-up de teste (duracao curta, contadores observaveis). Nunca registrado em PowerUps de
# producao; so o parametro so-debug `?powerup=` e os GUT o usam.
const NOME_PADRAO: StringName = &"teste"
const DURACAO_PADRAO: float = 2.0

var ativacoes: int = 0
var encerramentos: int = 0


func _init(nome_: StringName = NOME_PADRAO, duracao_: float = DURACAO_PADRAO) -> void:
	nome = nome_
	duracao = duracao_


func ao_ativar() -> void:
	ativacoes += 1


func ao_encerrar() -> void:
	encerramentos += 1
