class_name TutorialFlag
extends RefCounted

# Flag "tutorial ja visto" (secao `tutorial`, chave `visto` do OptionsStore). Store injetado (producao: Global.opcoes).
# So `bool` true conta como visto; ausente, arquivo corrompido ou outro tipo/valor = nao visto (o card aparece).
# marcar() tambem liga o espelho em memoria (Global.tutorial_visto_espelho): se a escrita falhar em silencio
# (OptionsStore.save_value), o card nao reaparece na mesma sessao.

const SECTION := "tutorial"
const KEY := "visto"

var _store: OptionsStore

func _init(store: OptionsStore) -> void:
	_store = store

func visto() -> bool:
	if Global.tutorial_visto_espelho:
		return true
	var value: Variant = _store.load_value(SECTION, KEY, false)
	return typeof(value) == TYPE_BOOL and value

func marcar() -> void:
	Global.tutorial_visto_espelho = true
	_store.save_value(SECTION, KEY, true)
