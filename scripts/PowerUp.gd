class_name PowerUp
extends RefCounted

# Contrato de power-up (sem cena). Cada power-up real herda e sobrescreve os hooks.
# `duracao` em segundos; 0 = carga unica, sem tempo (guardada a parte pelo PowerUpState).
# A raridade nao mora aqui: vem da curva de dificuldade (por estagio).
# Hooks: com `duracao` > 0, `ao_ativar` roda ao ativar e `ao_encerrar` ao expirar ou ser substituido.
# Com `duracao` == 0 (carga unica), `ao_ativar` roda ao GUARDAR a carga (coleta) e `ao_encerrar` ao
# CONSUMI-LA (uso); quem precisa de efeito so no uso (Segunda chance, f526) trata isso em `ao_encerrar`.
var nome: StringName = &""
var duracao: float = 0.0


func ao_ativar() -> void:
	pass


func ao_encerrar() -> void:
	pass
