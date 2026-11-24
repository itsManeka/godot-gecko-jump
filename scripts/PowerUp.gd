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


# Efeitos que chegam ao mundo sem acoplar este RefCounted a cenas (f522 T1): o PowerUpState agrega o valor
# do temporizado ativo e a Stage espelha o agregado onde o efeito e lido. Padrao neutro: herdeiro que nao
# sobrescreve nao muda nada (PowerUpDeTeste e fakes da f521 seguem neutros sem edicao).
# Verdadeiro = o gecko pisa em plataforma de qualquer cor (Camaleao; f522 T3 le Global.cor_livre).
func ignora_cor() -> bool:
	return false


# Multiplicador do deslocamento do scroll da curva (Desacelera, f522 T4); 1.0 = sem efeito.
func fator_scroll() -> float:
	return 1.0
