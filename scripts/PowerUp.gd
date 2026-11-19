class_name PowerUp
extends RefCounted

# Contrato de power-up (sem cena). Cada power-up real herda e sobrescreve os hooks.
# `duracao` em segundos; 0 = carga unica, sem tempo (guardada a parte pelo PowerUpState).
# A raridade nao mora aqui: vem da curva de dificuldade (por estagio).
var nome: StringName = &""
var duracao: float = 0.0


func ao_ativar() -> void:
	pass


func ao_encerrar() -> void:
	pass
