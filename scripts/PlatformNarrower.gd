class_name PlatformNarrower
extends PlatformModifier

# Mecanica "plataformas menores": a plataforma nasce com a largura do snapshot de dificuldade.


func ao_criar(plataforma: Platform, snapshot: DifficultySnapshot) -> void:
	plataforma.set_largura(snapshot.get_largura_plataforma())
