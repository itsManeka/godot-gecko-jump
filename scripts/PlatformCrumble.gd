class_name PlatformCrumble
extends PlatformModifier

# Mecanica "plataformas que caem": o pouso inicia a contagem do desmoronamento (a Platform ignora pouso repetido).
# Com Global.sem_derrota (modo de teste/smoke) a mecanica nao age.


# Linha inicial nunca desmorona: e o chao garantido do comeco da partida.
func vale_em_linha_inicial() -> bool:
	return false


func ao_pousar(plataforma: Platform, snapshot: DifficultySnapshot) -> void:
	if Global.sem_derrota:
		return
	plataforma.iniciar_desmoronamento(snapshot.get_atraso_desmoronar())
