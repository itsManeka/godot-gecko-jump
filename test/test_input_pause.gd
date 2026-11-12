extends GutTest

# Acao `pause` do InputMap (project.godot): Esc, P e joypad start. Nao reusa `ui_cancel`.
# Codigos em ordem alfabetica (o InputMap nao garante ordem de insercao).


func _codigos(acao: StringName) -> Array:
	var codigos: Array = []
	for ev in InputMap.action_get_events(acao):
		if ev is InputEventKey:
			codigos.append("key:%d" % (ev as InputEventKey).keycode)
		elif ev is InputEventJoypadButton:
			codigos.append("joy:%d" % (ev as InputEventJoypadButton).button_index)
		else:
			codigos.append("outro")
	codigos.sort()
	return codigos


func _esperado(codigos: Array) -> Array:
	codigos.sort()
	return codigos


func test_pause_tem_esc_p_e_start_e_nenhum_evento_a_mais() -> void:
	assert_true(InputMap.has_action("pause"), "acao pause deve existir no InputMap")
	var codigos := _codigos("pause")
	assert_true(codigos.has("key:%d" % KEY_ESCAPE), "pause deve ter a tecla Esc")
	assert_true(codigos.has("key:%d" % KEY_P), "pause deve ter a tecla P")
	assert_true(codigos.has("joy:%d" % JOY_BUTTON_START), "pause deve ter o botao start do joypad")
	assert_eq(codigos.size(), 3, "pause sem evento a mais")


func test_pause_nao_tem_eventos_duplicados() -> void:
	var codigos := _codigos("pause")
	var unicos: Array = []
	for c in codigos:
		if not unicos.has(c):
			unicos.append(c)
	assert_eq(unicos.size(), codigos.size(), "pause nao repete evento")
	assert_eq(codigos.size(), 3, "pause tem exatamente 3 eventos")


func test_pause_nao_reusa_ui_cancel() -> void:
	assert_ne(_codigos("pause"), _codigos("ui_cancel"), "pause nao pode ser a mesma lista de ui_cancel")
	assert_false(
		_codigos("pause").has("joy:%d" % JOY_BUTTON_B),
		"pause nao pode usar o botao B (ui_cancel do Godot)"
	)


func test_jump_ui_left_ui_right_continuam_com_os_mesmos_eventos() -> void:
	assert_eq(
		_codigos("jump"),
		_esperado(["key:%d" % KEY_SPACE, "key:%d" % KEY_UP, "key:%d" % KEY_W]),
		"jump inalterada"
	)
	assert_eq(
		_codigos("ui_left"),
		_esperado(["key:%d" % KEY_LEFT, "joy:%d" % JOY_BUTTON_DPAD_LEFT, "key:%d" % KEY_A]),
		"ui_left inalterada"
	)
	assert_eq(
		_codigos("ui_right"),
		_esperado(["key:%d" % KEY_RIGHT, "joy:%d" % JOY_BUTTON_DPAD_RIGHT, "key:%d" % KEY_D]),
		"ui_right inalterada"
	)
