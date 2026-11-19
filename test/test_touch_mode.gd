extends GutTest

# TouchMode (enum, validacao) e persistencia do modo de toque via Global/OptionsStore.
# Todo cenario usa TEMP_PATH injetado; nenhum escreve em OptionsStore.DEFAULT_PATH.

const TEMP_PATH := "user://options_test_touch_mode.cfg"

var _store_original: OptionsStore


func before_each() -> void:
	_store_original = Global.opcoes
	_limpar()


func after_each() -> void:
	Global.usar_options_store(_store_original)
	_limpar()


func _limpar() -> void:
	for p in [TEMP_PATH, TEMP_PATH + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)


func _escrever_modo(valor: Variant) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(TouchMode.SECTION, TouchMode.KEY, valor)
	cfg.save(TEMP_PATH)


func test_c370_chave_ausente_devolve_padrao() -> void:
	assert_eq(TouchMode.de_valor(null), TouchMode.padrao(), "C370: null vale o padrao")
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", 0.5)
	cfg.save(TEMP_PATH)
	Global.usar_options_store(OptionsStore.new(TEMP_PATH))
	assert_eq(Global.get_touch_mode(), TouchMode.padrao(), "C370: cfg sem controle/toque_modo vale o padrao")
	assert_eq(TouchMode.padrao(), TouchMode.Modo.B, "C370: padrao e B")


func test_c442_padrao_e_b() -> void:
	assert_eq(TouchMode.padrao(), TouchMode.Modo.B, "C442: padrao() = B")


func test_c443_null_devolve_b() -> void:
	assert_eq(TouchMode.de_valor(null), TouchMode.Modo.B, "C443: null = B")


func test_c444_valor_do_antigo_c_devolve_b() -> void:
	assert_eq(TouchMode.de_valor(2), TouchMode.Modo.B, "C444: 2 (antigo C) = B")


func test_c445_sem_valor_devolve_b() -> void:
	assert_eq(TouchMode.de_valor(TouchMode.SEM_VALOR), TouchMode.Modo.B, "C445: -1 (SEM_VALOR) = B")


func test_c446_string_devolve_b() -> void:
	assert_eq(TouchMode.de_valor("x"), TouchMode.Modo.B, "C446: string = B")
	assert_eq(TouchMode.de_valor("B"), TouchMode.Modo.B, "C446: string com rotulo = B")


func test_c447_fracionario_devolve_b() -> void:
	assert_eq(TouchMode.de_valor(1.5), TouchMode.Modo.B, "C447: fracionario = B")


func test_c448_valores_validos_inalterados() -> void:
	assert_eq(TouchMode.de_valor(0), TouchMode.Modo.A, "C448: 0 = A")
	assert_eq(TouchMode.de_valor(1), TouchMode.Modo.B, "C448: 1 = B")


func test_c449_store_sem_chave_usa_b() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", 0.5)
	cfg.save(TEMP_PATH)
	Global.usar_options_store(OptionsStore.new(TEMP_PATH))
	assert_eq(Global.get_touch_mode(), TouchMode.Modo.B, "C449: store sem controle/toque_modo = B")


func test_c450_store_com_valor_antigo_do_c_usa_b_e_zero_usa_a() -> void:
	_escrever_modo(2)
	Global.usar_options_store(OptionsStore.new(TEMP_PATH))
	assert_eq(Global.get_touch_mode(), TouchMode.Modo.B, "C450: toque_modo = 2 (antigo C) = B")
	_escrever_modo(0)
	Global.usar_options_store(OptionsStore.new(TEMP_PATH))
	assert_eq(Global.get_touch_mode(), TouchMode.Modo.A, "C450: toque_modo = 0 (save antigo em A) = A")


func test_c425_string_ou_fracionario_devolve_padrao() -> void:
	var padrao := TouchMode.padrao()
	assert_eq(TouchMode.de_valor("A"), padrao, "C425: string")
	assert_eq(TouchMode.de_valor("1"), padrao, "C425: string numerica")
	assert_eq(TouchMode.de_valor(0.5), padrao, "C425: float fracionario 0.5")
	assert_eq(TouchMode.de_valor(1.5), padrao, "C425: float fracionario 1.5")
	assert_eq(TouchMode.de_valor(true), padrao, "C425: bool")
	_escrever_modo("B")
	Global.usar_options_store(OptionsStore.new(TEMP_PATH))
	assert_eq(Global.get_touch_mode(), padrao, "C425: string no cfg vale o padrao")
	_escrever_modo(0.5)
	Global.usar_options_store(OptionsStore.new(TEMP_PATH))
	assert_eq(Global.get_touch_mode(), padrao, "C425: float no cfg vale o padrao")


func test_c426_negativo_ou_fora_da_faixa_devolve_padrao_e_validos_voltam_iguais() -> void:
	var padrao := TouchMode.padrao()
	assert_eq(TouchMode.de_valor(-1), padrao, "C426: negativo")
	assert_eq(TouchMode.de_valor(3), padrao, "C426: acima do ultimo modo")
	assert_eq(TouchMode.de_valor(99), padrao, "C426: muito acima")
	assert_eq(TouchMode.de_valor(NAN), padrao, "C426: NaN")
	assert_eq(TouchMode.de_valor(0), TouchMode.Modo.A, "C426: 0 = A")
	assert_eq(TouchMode.de_valor(1), TouchMode.Modo.B, "C426: 1 = B")
	assert_eq(TouchMode.de_valor(2), padrao, "C426: 2 (antigo C) cai no padrao")
	_escrever_modo(0)
	Global.usar_options_store(OptionsStore.new(TEMP_PATH))
	assert_eq(Global.get_touch_mode(), TouchMode.Modo.A, "C426: A salvo volta como A")
	_escrever_modo(1)
	Global.usar_options_store(OptionsStore.new(TEMP_PATH))
	assert_eq(Global.get_touch_mode(), TouchMode.Modo.B, "C426: B salvo volta como B")
	_escrever_modo(7)
	Global.usar_options_store(OptionsStore.new(TEMP_PATH))
	assert_eq(Global.get_touch_mode(), padrao, "C426: 7 no cfg vale o padrao")


func test_c371_gravar_modo_preserva_audio_e_volume_preserva_modo() -> void:
	var seed_store := OptionsStore.new(TEMP_PATH)
	seed_store.save_music(0.5)
	seed_store.save_sfx(0.25)
	Global.usar_options_store(OptionsStore.new(TEMP_PATH))
	Global.set_touch_mode(TouchMode.Modo.A, true)
	var lido := OptionsStore.new(TEMP_PATH)
	assert_eq(lido.load_music(), 0.5, "C371: modo nao apaga music")
	assert_eq(lido.load_sfx(), 0.25, "C371: modo nao apaga sfx")
	assert_eq(TouchMode.de_valor(lido.load_value(TouchMode.SECTION, TouchMode.KEY, TouchMode.SEM_VALOR)), TouchMode.Modo.A, "C371: modo gravado")
	Global.set_volume_music(0.75)
	Global.set_volume_sfx(0.1)
	var depois := OptionsStore.new(TEMP_PATH)
	assert_eq(depois.load_music(), 0.75, "C371: volume atualizado")
	assert_eq(TouchMode.de_valor(depois.load_value(TouchMode.SECTION, TouchMode.KEY, TouchMode.SEM_VALOR)), TouchMode.Modo.A, "C371: volume preserva o modo")


func test_c372_cfg_corrompido_cai_no_padrao_sem_erro() -> void:
	var f := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	f.store_string("@@ nao e cfg")
	f.close()
	Global.usar_options_store(OptionsStore.new(TEMP_PATH))
	assert_eq(Global.get_touch_mode(), TouchMode.padrao(), "C372: cfg corrompido vale o padrao")
	var ausente := OptionsStore.new(TEMP_PATH + ".naoexiste")
	Global.usar_options_store(ausente)
	assert_eq(Global.get_touch_mode(), TouchMode.padrao(), "C372: cfg ausente vale o padrao")


func test_c373_set_touch_mode_so_grava_com_persistir() -> void:
	Global.usar_options_store(OptionsStore.new(TEMP_PATH))
	Global.set_touch_mode(TouchMode.Modo.B, false)
	assert_eq(Global.get_touch_mode(), TouchMode.Modo.B, "C373: aplica em memoria sem persistir")
	assert_false(FileAccess.file_exists(TEMP_PATH), "C373: persistir=false nao grava o store")
	Global.set_touch_mode(TouchMode.Modo.A, true)
	assert_true(FileAccess.file_exists(TEMP_PATH), "C373: persistir=true grava o store")
	var novo := OptionsStore.new(TEMP_PATH)
	assert_eq(TouchMode.de_valor(novo.load_value(TouchMode.SECTION, TouchMode.KEY, TouchMode.SEM_VALOR)), TouchMode.Modo.A, "C373: novo store le o mesmo modo")
	Global.usar_options_store(OptionsStore.new(TEMP_PATH))
	assert_eq(Global.get_touch_mode(), TouchMode.Modo.A, "C373: recarga do Global traz o modo salvo")


func test_c374_options_cfg_real_nao_muda() -> void:
	assert_ne(_store_original.path, OptionsStore.DEFAULT_PATH, "C374: store do Global na suite e temporario")
	var existia := FileAccess.file_exists(OptionsStore.DEFAULT_PATH)
	var mtime := FileAccess.get_modified_time(OptionsStore.DEFAULT_PATH) if existia else 0
	Global.usar_options_store(_store_original)
	Global.set_touch_mode(TouchMode.Modo.A, true)
	Global.set_touch_mode(TouchMode.Modo.B, true)
	assert_eq(FileAccess.file_exists(OptionsStore.DEFAULT_PATH), existia, "C374: options.cfg real nao criado/removido")
	if existia:
		assert_eq(FileAccess.get_modified_time(OptionsStore.DEFAULT_PATH), mtime, "C374: options.cfg real nao mudou")


func test_c512_nome_e_rotulo_dos_modos_sao_os_aprovados() -> void:
	assert_eq(TouchMode.nome(TouchMode.Modo.A), "Flick", "C512: nome A = Flick")
	assert_eq(TouchMode.nome(TouchMode.Modo.B), "Joy invisivel", "C512: nome B = Joy invisivel")
	assert_eq(TouchMode.rotulo(TouchMode.Modo.A), "Toque: Flick", "C512: rotulo A")
	assert_eq(TouchMode.rotulo(TouchMode.Modo.B), "Toque: Joy invisivel", "C512: rotulo B")


func test_c513_nome_fora_da_faixa_cai_no_nome_do_padrao() -> void:
	assert_eq(TouchMode.nome(-1), "Joy invisivel", "C513: -1 cai no nome do padrao (B)")
	assert_eq(TouchMode.nome(2), "Joy invisivel", "C513: 2 cai no nome do padrao (B)")
	assert_eq(TouchMode.nome(99), "Joy invisivel", "C513: 99 cai no nome do padrao (B)")
	assert_eq(TouchMode.rotulo(99), "Toque: Joy invisivel", "C513: rotulo fora da faixa usa o padrao")


func test_c514_de_valor_segue_int_e_nao_aceita_o_nome() -> void:
	assert_eq(TouchMode.de_valor(0), TouchMode.Modo.A, "C514: 0 (save antigo) = A")
	assert_eq(TouchMode.de_valor(1), TouchMode.Modo.B, "C514: 1 (save antigo) = B")
	assert_eq(TouchMode.de_valor("Flick"), TouchMode.padrao(), "C514: nome novo do A como string cai no padrao")
	assert_eq(TouchMode.de_valor("Joy invisivel"), TouchMode.padrao(), "C514: nome novo do B como string cai no padrao")


# Fontes de texto visivel do toque: nomes, blocos da dica (A e B, todos os lados), linhas do card (A e B) e o seletor
# de Opcoes (A e B). 2 + 6 + 6 + 2 = 16 fontes.
func _fontes_texto_toque() -> Array[String]:
	var fontes: Array[String] = []
	fontes.append_array(TouchMode.NOMES)
	for modo in [TouchMode.Modo.A, TouchMode.Modo.B]:
		for lado in [TouchHint.Lado.ESQUERDA, TouchHint.Lado.DIREITA, TouchHint.Lado.CENTRO]:
			fontes.append_array(TouchHint.textos_bloco(modo, lado))
		fontes.append_array(TutorialCard.linhas_controle_toque(modo))
	var tela := OptionsScreen.new()
	add_child_autofree(tela)
	for modo in [TouchMode.Modo.A, TouchMode.Modo.B]:
		Global.set_touch_mode(modo, false)
		fontes.append(tela.texto_toque())
	Global.set_touch_mode(TouchMode.padrao(), false)
	return fontes


# Token A ou B isolado (nao substring): "Arraste" e "Flick" nao casam.
func _re_ab() -> RegEx:
	return RegEx.create_from_string("(?<![A-Za-z0-9])[AB](?![A-Za-z0-9])")


func _checar_sem_ab(fontes: Array[String]) -> void:
	var re := _re_ab()
	for texto in fontes:
		assert_null(re.search(texto), "fonte de texto visivel diz A/B isolado: '%s'" % texto)


func test_c517_nenhuma_fonte_do_toque_e_a_ou_b_isolado() -> void:
	_checar_sem_ab(_fontes_texto_toque())


func test_c518_guarda_nao_e_vacua_tem_fontes_nao_vazias_e_pega_a_ou_b() -> void:
	var fontes := _fontes_texto_toque()
	assert_eq(fontes.size(), 16, "C518: 16 fontes coletadas (nomes, dica, card, seletor nos 2 modos)")
	for texto in fontes:
		assert_ne(texto, "", "C518: nenhuma fonte vazia")
	assert_not_null(_re_ab().search("Toque: A"), "C518: a regex pega A isolado")
	assert_null(_re_ab().search("Arraste anda, Flick pula"), "C518: a regex nao pega Arraste nem Flick")
	_checar_sem_ab(fontes)


func test_c519_nomes_tem_dois_itens_nao_vazios_e_distintos() -> void:
	assert_eq(TouchMode.NOMES.size(), 2, "C519: NOMES tem 2 itens")
	assert_ne(TouchMode.NOMES[0], "", "C519: nome do A nao vazio")
	assert_ne(TouchMode.NOMES[1], "", "C519: nome do B nao vazio")
	assert_ne(TouchMode.NOMES[0], TouchMode.NOMES[1], "C519: nomes distintos entre si")
