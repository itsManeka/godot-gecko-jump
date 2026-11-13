class_name PlatformModifier
extends RefCounted

# Contrato base de modificador de plataforma (sem cena, sem Global). Subclasses sobrescrevem so o hook que usam.
# A Platform guarda a lista recebida e despacha os hooks; o gerador so entrega a lista.


func ao_criar(_plataforma: Platform, _snapshot: DifficultySnapshot) -> void:
	pass


func ao_pousar(_plataforma: Platform, _snapshot: DifficultySnapshot) -> void:
	pass


func ao_processar(_plataforma: Platform, _delta: float) -> void:
	pass
